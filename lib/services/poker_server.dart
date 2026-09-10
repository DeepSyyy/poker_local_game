import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:poker_local_game/controllers/poker_game_controller.dart';
import 'package:poker_local_game/models/poker_game_state.dart';
import 'package:poker_local_game/services/companion_web_app.dart';

class PokerServer {
  final PokerGameController controller;
  final int port;

  HttpServer? _server;
  final Set<WebSocket> _sockets = {};
  final Map<WebSocket, String> _socketPlayerMap = {};
  String? _localIp;
  bool _isListening = false;
  late int _boundPort;

  PokerServer({required this.controller, this.port = 8080}) {
    _boundPort = port;
    controller.addListener(_broadcastState);
  }

  bool get isRunning => _server != null && _isListening;
  String? get localIp => _localIp;
  int get actualPort => _boundPort;
  String get serverUrl => _localIp != null
      ? 'http://$_localIp:$_boundPort'
      : 'http://localhost:$_boundPort';
  int get connectedSocketsCount => _sockets.length;
  Set<String> get connectedPlayerIds => _socketPlayerMap.values.toSet();

  Future<void> start() async {
    if (_isListening) return;

    _localIp = await _findLocalIp();
    int targetPort = port;

    for (int attempts = 0; attempts < 10; attempts++) {
      try {
        _server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          targetPort,
          shared: true,
        );
        _boundPort = targetPort;
        _isListening = true;

        _server!.listen((HttpRequest request) async {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final socket = await WebSocketTransformer.upgrade(request);
            _handleWebSocket(socket);
          } else {
            _handleHttpRequest(request);
          }
        });

        if (kDebugMode) {
          print('PokerServer running on $serverUrl');
        }
        break;
      } catch (e) {
        if (kDebugMode) {
          print('Port $targetPort in use, trying next...');
        }
        targetPort++;
      }
    }
  }

  Future<void> stop() async {
    _isListening = false;
    for (var socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
    _socketPlayerMap.clear();
    await _server?.close(force: true);
    _server = null;
  }

  Future<String?> _findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            return addr.address;
          }
        }
      }
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error getting IP: $e');
    }
    return '127.0.0.1';
  }

  void _handleHttpRequest(HttpRequest request) {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      request.response.close();
      return;
    }

    request.response.headers.contentType = ContentType.html;
    request.response.write(CompanionWebApp.htmlContent);
    request.response.close();
  }

  void _handleWebSocket(WebSocket socket) {
    _sockets.add(socket);
    _sendStateToSocket(socket);

    socket.listen(
      (data) {
        try {
          final Map<String, dynamic> msg = jsonDecode(data.toString());
          _handleClientMessage(socket, msg);
        } catch (e) {
          if (kDebugMode) print('Invalid WS message: $e');
        }
      },
      onDone: () {
        _sockets.remove(socket);
        _socketPlayerMap.remove(socket);
        controller.notifyStateChanged();
      },
      onError: (err) {
        _sockets.remove(socket);
        _socketPlayerMap.remove(socket);
        controller.notifyStateChanged();
      },
    );
  }

  void _handleClientMessage(WebSocket socket, Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final playerId = msg['playerId'] as String?;

    if (type == 'add_chips') {
      final targetPlayerId = (msg['targetPlayerId'] as String?) ?? playerId;
      final amount = (msg['amount'] as num?)?.toInt() ?? 0;
      if (targetPlayerId != null && targetPlayerId.isNotEmpty && amount > 0) {
        controller.addChipsToPlayer(targetPlayerId, amount);
      }
      return;
    }

    if (type == 'select_player') {
      if (playerId != null && playerId.isNotEmpty) {
        _socketPlayerMap[socket] = playerId;
      } else {
        _socketPlayerMap.remove(socket);
      }
      _sendStateToSocket(socket);
      _broadcastState();
      controller.notifyStateChanged();
      return;
    }

    if (type == 'action' && playerId != null) {
      final active = controller.currentTurnPlayer;
      if (active == null || active.id != playerId) {
        return; // Reject out-of-turn action
      }

      final action = msg['action'] as String?;
      if (action == 'fold') {
        controller.fold();
      } else if (action == 'check') {
        controller.check();
      } else if (action == 'call') {
        controller.call();
      } else if (action == 'raise') {
        final amount =
            (msg['amount'] as num?)?.toInt() ?? controller.minRaiseAmount;
        controller.raiseTo(amount);
      } else if (action == 'allIn') {
        controller.allIn();
      }
    }
  }

  void _broadcastState() {
    if (_sockets.isEmpty) return;

    for (var socket in List.from(_sockets)) {
      try {
        _sendStateToSocket(socket);
      } catch (e) {
        _sockets.remove(socket);
        _socketPlayerMap.remove(socket);
      }
    }
  }

  void _sendStateToSocket(WebSocket socket) {
    try {
      final playerId = _socketPlayerMap[socket];
      socket.add(
        jsonEncode({
          'type': 'state',
          'state': _buildStateMap(forPlayerId: playerId),
        }),
      );
    } catch (e) {
      _sockets.remove(socket);
      _socketPlayerMap.remove(socket);
    }
  }

  Map<String, dynamic> _buildStateMap({String? forPlayerId}) {
    final active = controller.currentTurnPlayer;
    final isShowdownOrEnded =
        controller.street == BettingStreet.showdown ||
        controller.street == BettingStreet.handEnded;

    final takenPlayerIds = _socketPlayerMap.values.toSet();

    return {
      'street': controller.street.name,
      'streetLabel': controller.street.label,
      'pot': controller.pot,
      'currentBet': controller.currentBet,
      'callAmount': controller.callAmount,
      'minRaise': controller.minRaiseAmount,
      'maxRaise': controller.maxRaiseAmount,
      'currentTurnPlayerId': active?.id,
      'currentTurnPlayerName': active?.name,
      'takenPlayerIds': takenPlayerIds.toList(),
      'communityCards': controller.communityCards
          .map(
            (c) => {
              'rank': c.rank.label,
              'suit': c.suit.symbol,
              'color': c.suit.color.value.toRadixString(16),
              'isFaceUp': c.isFaceUp,
            },
          )
          .toList(),
      'lastLog': controller.logs.isNotEmpty
          ? controller.logs.last.message
          : null,
      'players': controller.players.map((p) {
        final isMe = forPlayerId != null && p.id == forPlayerId;
        final revealHoleCards = isMe || isShowdownOrEnded;
        final isTaken = takenPlayerIds.contains(p.id);
        final isTakenByOther = isTaken && !isMe;

        String roleLabel = 'Player';
        if (p.isDealer) {
          roleLabel = 'Dealer (D)';
        } else if (p.isSmallBlind) {
          roleLabel = 'Small Blind (SB)';
        } else if (p.isBigBlind) {
          roleLabel = 'Big Blind (BB)';
        }

        return {
          'id': p.id,
          'name': p.name,
          'chips': p.chips,
          'currentRoundBet': p.currentRoundBet,
          'status': p.status.name,
          'isDealer': p.isDealer,
          'isSmallBlind': p.isSmallBlind,
          'isBigBlind': p.isBigBlind,
          'roleLabel': roleLabel,
          'handEvaluation': p.evaluation?.description,
          'evaluationRank': p.evaluation?.rank.label,
          'isOnline': isTaken,
          'isTaken': isTaken,
          'isTakenByOther': isTakenByOther,
          'holeCards': p.holeCards.map((c) {
            if (revealHoleCards) {
              return {
                'rank': c.rank.label,
                'suit': c.suit.symbol,
                'isFaceUp': c.isFaceUp,
              };
            } else {
              return {'rank': '?', 'suit': '?', 'isFaceUp': false};
            }
          }).toList(),
        };
      }).toList(),
    };
  }

  void dispose() {
    controller.removeListener(_broadcastState);
    stop();
  }
}
