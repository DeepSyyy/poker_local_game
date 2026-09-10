import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/models/poker_game_state.dart';
import 'package:poker_local_game/screens/poker/widgets/casino_card_widget.dart';
import 'package:poker_local_game/screens/poker/widgets/community_cards_widget.dart';
import 'package:poker_local_game/screens/poker/widgets/player_seat_widget.dart';
import 'package:poker_local_game/screens/poker/widgets/rebuy_dialog.dart';
import 'package:poker_local_game/screens/poker/widgets/table_center_widget.dart';
import 'package:poker_local_game/screens/poker/widgets/raise_dialog.dart';

class NativeCompanionScreen extends StatefulWidget {
  final String serverUrl; // e.g. "192.168.1.34:8080"

  const NativeCompanionScreen({super.key, required this.serverUrl});

  @override
  State<NativeCompanionScreen> createState() => _NativeCompanionScreenState();
}

class _NativeCompanionScreenState extends State<NativeCompanionScreen> {
  WebSocket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _errorMessage;
  String _customServerUrl = '';
  String get _currentServerUrl =>
      _customServerUrl.isNotEmpty ? _customServerUrl : widget.serverUrl;
  Map<String, dynamic>? _gameState;
  String _selectedPlayerId = '';
  bool _isPlayerLocked = false;
  bool _isEditingPlayer = false;
  bool _cardsFaceUp = true;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isConnected && !_isConnecting && mounted) {
        _connectWebSocket();
      }
    });
  }

  Future<void> _connectWebSocket() async {
    if (_isConnected || _isConnecting) return;

    if (mounted) {
      setState(() {
        _isConnecting = true;
        _errorMessage = null;
      });
    }

    final cleanUrl = _currentServerUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/ws', '');

    final parts = cleanUrl.split(':');
    final host = parts[0];
    final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 8080) : 8080;
    final wsUri = Uri.parse('ws://$host:$port/ws');

    // Fast TCP probe to avoid 30s native OS timeout freeze
    try {
      final probe = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 1200),
      );
      await probe.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _errorMessage = 'Gagal ke $host:$port (Cek Wi-Fi Host)';
        });
      }
      return;
    }

    try {
      final socket = await WebSocket.connect(
        wsUri.toString(),
      ).timeout(const Duration(seconds: 3));
      _socket = socket;
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _errorMessage = null;
        });
        if (_selectedPlayerId.isNotEmpty) {
          _socket!.add(
            jsonEncode({
              'type': 'select_player',
              'playerId': _selectedPlayerId,
            }),
          );
        }
      }

      _socket!.listen(
        (data) {
          try {
            final Map<String, dynamic> msg = jsonDecode(data.toString());
            if (msg['type'] == 'state' && mounted) {
              setState(() {
                _gameState = msg['state'];
              });
            }
          } catch (e) {
            debugPrint('WS decode error: $e');
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _isConnecting = false;
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _isConnecting = false;
              _errorMessage = 'Koneksi terputus';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
          _errorMessage = 'Gagal hubungkan socket';
        });
      }
    }
  }

  void _showEditIpDialog() {
    final controller = TextEditingController(text: _currentServerUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Ubah IP Host Server',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Contoh: 192.168.1.10:8080',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final newIp = controller.text.trim();
              if (newIp.isNotEmpty) {
                Navigator.pop(context);
                _socket?.close();
                setState(() {
                  _customServerUrl = newIp;
                  _isConnected = false;
                  _isConnecting = false;
                });
                _connectWebSocket();
              }
            },
            child: const Text(
              'Simpan & Connect',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRebuyDialog() {
    final rawPlayers = (_gameState?['players'] as List?) ?? [];
    final players = rawPlayers
        .map((p) => _mapJsonToPlayer(p as Map<String, dynamic>))
        .toList();

    if (players.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => RebuyDialog(
        players: players,
        onAddChips: (targetId, amount) {
          if (_socket != null && _isConnected) {
            _socket!.add(
              jsonEncode({
                'type': 'add_chips',
                'targetPlayerId': targetId,
                'amount': amount,
              }),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _socket?.close();
    super.dispose();
  }

  void _sendAction(String actionType, [int? amount]) {
    if (_socket == null || !_isConnected || _selectedPlayerId.isEmpty) return;
    _socket!.add(
      jsonEncode({
        'type': 'action',
        'playerId': _selectedPlayerId,
        'action': actionType,
        if (amount != null) 'amount': amount,
      }),
    );
  }

  void _onPlayerSelected(String? id) {
    if (id == null) return;
    setState(() {
      _selectedPlayerId = id;
      _isEditingPlayer = false;
      _isPlayerLocked = true;
    });
    if (_socket != null && _isConnected) {
      _socket!.add(jsonEncode({'type': 'select_player', 'playerId': id}));
    }
  }

  PlayingCard? _parseCard(Map<String, dynamic>? json) {
    if (json == null) return null;
    final suitStr = json['suit'] as String?;
    final rankStr = json['rank'] as String?;
    if (suitStr == null || rankStr == null) return null;

    final isUnknown = suitStr == '?' || rankStr == '?';

    final suit = CardSuit.values.firstWhere(
      (s) => s.symbol == suitStr,
      orElse: () => CardSuit.spades,
    );
    final rank = CardRank.values.firstWhere(
      (r) => r.label == rankStr,
      orElse: () => CardRank.ace,
    );
    final isFaceUp = isUnknown ? false : (json['isFaceUp'] as bool? ?? true);
    return PlayingCard(suit: suit, rank: rank, isFaceUp: isFaceUp);
  }

  BettingStreet _parseStreet(String? name) {
    switch (name) {
      case 'lobby':
        return BettingStreet.lobby;
      case 'preFlop':
        return BettingStreet.preFlop;
      case 'flop':
        return BettingStreet.flop;
      case 'turn':
        return BettingStreet.turn;
      case 'river':
        return BettingStreet.river;
      case 'showdown':
        return BettingStreet.showdown;
      case 'handEnded':
        return BettingStreet.handEnded;
      default:
        return BettingStreet.preFlop;
    }
  }

  PokerPlayer _mapJsonToPlayer(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '0';
    final name = json['name'] as String? ?? 'Player';
    final chips = (json['chips'] as num?)?.toInt() ?? 0;
    final currentRoundBet = (json['currentRoundBet'] as num?)?.toInt() ?? 0;
    final statusStr = json['status'] as String? ?? 'active';
    final isDealer = json['isDealer'] as bool? ?? false;
    final isSmallBlind = json['isSmallBlind'] as bool? ?? false;
    final isBigBlind = json['isBigBlind'] as bool? ?? false;

    PlayerStatus status = PlayerStatus.active;
    if (statusStr == 'folded') status = PlayerStatus.folded;
    if (statusStr == 'allIn') status = PlayerStatus.allIn;
    if (statusStr == 'out') status = PlayerStatus.out;

    final cardsRaw = (json['holeCards'] as List?) ?? [];
    final holeCards = cardsRaw
        .map((c) => _parseCard(c as Map<String, dynamic>))
        .whereType<PlayingCard>()
        .toList();

    // Reveal face-up for MY player cards OR during Showdown
    final isMe = id == _selectedPlayerId;
    final isShowdown =
        _gameState?['street'] == 'showdown' ||
        _gameState?['street'] == 'handEnded';

    if (isMe) {
      for (var card in holeCards) {
        card.isFaceUp = _cardsFaceUp;
      }
    } else if (isShowdown) {
      for (var card in holeCards) {
        card.isFaceUp = true;
      }
    } else {
      for (var card in holeCards) {
        card.isFaceUp = false;
      }
    }

    final colors = [
      const Color(0xFFEF5350), // Red
      const Color(0xFF42A5F5), // Blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF26A69A), // Teal
      const Color(0xFFFF7043), // Deep Orange
      const Color(0xFF8D6E63), // Brown
    ];
    final int index = int.tryParse(id.replaceAll('p_', '')) ?? 1;

    return PokerPlayer(
      id: id,
      name: name,
      chips: chips,
      avatarColor: colors[(index - 1) % colors.length],
      status: status,
      currentRoundBet: currentRoundBet,
      isDealer: isDealer,
      isSmallBlind: isSmallBlind,
      isBigBlind: isBigBlind,
      holeCards: holeCards,
    );
  }

  Alignment _getSeatAlignment(int index, int total) {
    switch (total) {
      case 2:
        return index == 0
            ? const Alignment(-0.84, 0.0)
            : const Alignment(0.84, 0.0);
      case 3:
        const positions = [
          Alignment(-0.84, 0.15),
          Alignment(0.0, -0.80),
          Alignment(0.84, 0.15),
        ];
        return positions[index % positions.length];
      case 4:
        const positions = [
          Alignment(-0.84, 0.0),
          Alignment(0.0, -0.80),
          Alignment(0.84, 0.0),
          Alignment(0.0, 0.80),
        ];
        return positions[index % positions.length];
      case 5:
        const positions = [
          Alignment(-0.84, 0.12),
          Alignment(-0.48, -0.80),
          Alignment(0.48, -0.80),
          Alignment(0.84, 0.12),
          Alignment(0.0, 0.80),
        ];
        return positions[index % positions.length];
      case 6:
        const positions = [
          Alignment(-0.84, 0.0),
          Alignment(-0.48, -0.80),
          Alignment(0.48, -0.80),
          Alignment(0.84, 0.0),
          Alignment(0.48, 0.80),
          Alignment(-0.48, 0.80),
        ];
        return positions[index % positions.length];
      default:
        final angle = (pi / 2) + (index * 2 * pi / max(1, total));
        return Alignment(0.84 * cos(angle), 0.80 * sin(angle));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawPlayers = (_gameState?['players'] as List?) ?? [];
    final players = rawPlayers
        .map((p) => _mapJsonToPlayer(p as Map<String, dynamic>))
        .toList();

    final me = _selectedPlayerId == 'host'
        ? PokerPlayer(
            id: 'host',
            name: 'Bandar / Host',
            chips: 0,
            avatarColor: AppColors.gold,
          )
        : players.firstWhere(
            (p) => p.id == _selectedPlayerId,
            orElse: () => PokerPlayer(
              id: '',
              name: 'Player',
              chips: 0,
              avatarColor: Colors.grey,
            ),
          );
    final hasSelectedMe = me.id.isNotEmpty;

    final currentTurnId = _gameState?['currentTurnPlayerId'] as String?;
    final isMyTurn = hasSelectedMe && currentTurnId == me.id;
    final currentBet = (_gameState?['currentBet'] as num?)?.toInt() ?? 0;
    final myCurrentBet = me.currentRoundBet;
    final callAmount = (_gameState?['callAmount'] as num?)?.toInt() ?? 0;
    final pot = (_gameState?['pot'] as num?)?.toInt() ?? 0;
    final street = _parseStreet(_gameState?['street'] as String?);

    final commCardsRaw = (_gameState?['communityCards'] as List?) ?? [];
    final commCards = commCardsRaw
        .map((c) => _parseCard(c as Map<String, dynamic>))
        .whereType<PlayingCard>()
        .toList();

    List<PlayingCard> myHoleCards = [];
    if (me.id.isNotEmpty) {
      myHoleCards = me.holeCards;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: Row(
          children: [
            _isConnected
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  )
                : (_errorMessage != null
                      ? const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 16,
                        )
                      : const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        )),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isConnected
                    ? 'Terhubung ($_currentServerUrl)'
                    : (_errorMessage ??
                          (_isConnecting
                              ? 'Menghubungkan $_currentServerUrl...'
                              : 'Mencoba terhubung $_currentServerUrl...')),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isConnected
                      ? Colors.white
                      : (_errorMessage != null
                            ? Colors.redAccent
                            : AppColors.gold),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded, color: AppColors.gold),
            onPressed: _showRebuyDialog,
            tooltip: 'Top-Up / Tambah Chip Pemain',
          ),
          IconButton(
            icon: Icon(
              _cardsFaceUp
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: AppColors.gold,
            ),
            onPressed: () => setState(() => _cardsFaceUp = !_cardsFaceUp),
            tooltip: _cardsFaceUp
                ? 'Sembunyikan Kartu Saku'
                : 'Buka Kartu Saku',
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
            onPressed: _showEditIpDialog,
            tooltip: 'Ubah IP Host',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
            onPressed: () {
              _socket?.close();
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
              _connectWebSocket();
            },
            tooltip: 'Hubungkan Ulang',
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout(
              context: context,
              players: players,
              rawPlayers: rawPlayers,
              me: me,
              hasSelectedMe: hasSelectedMe,
              isMyTurn: isMyTurn,
              currentBet: currentBet,
              myCurrentBet: myCurrentBet,
              callAmount: callAmount,
              pot: pot,
              street: street,
              commCards: commCards,
              myHoleCards: myHoleCards,
            );
          } else {
            return _buildLandscapeLayout(
              context: context,
              players: players,
              rawPlayers: rawPlayers,
              me: me,
              hasSelectedMe: hasSelectedMe,
              isMyTurn: isMyTurn,
              currentBet: currentBet,
              myCurrentBet: myCurrentBet,
              callAmount: callAmount,
              pot: pot,
              street: street,
              commCards: commCards,
              myHoleCards: myHoleCards,
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // PORTRAIT LAYOUT (CASUAL 1-HANDED MODE)
  // ==========================================
  Widget _buildPortraitLayout({
    required BuildContext context,
    required List<PokerPlayer> players,
    required List<dynamic> rawPlayers,
    required PokerPlayer me,
    required bool hasSelectedMe,
    required bool isMyTurn,
    required int currentBet,
    required int myCurrentBet,
    required int callAmount,
    required int pot,
    required BettingStreet street,
    required List<PlayingCard> commCards,
    required List<PlayingCard> myHoleCards,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Player Selector Bar (Collapses into Profile Header once selected)
            _buildPlayerSelector(rawPlayers, me),
            const SizedBox(height: 10),

            // 2. Chips & Pot Header
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    label: 'CHIP SAYA',
                    value: '${me.chips}',
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    label: 'TOTAL POT',
                    value: '$pot',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. Mini Casino Table (Community Cards & Opponents Row)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [AppColors.tableFelt, AppColors.tableFeltDark],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tableBorder, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          street.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CommunityCardsWidget(cards: commCards),
                  ),
                  if (players.length > 1) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 8),
                    // Opponents Quick Status Bar
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: players.where((p) => p.id != me.id).map((opp) {
                        final isTurn =
                            _gameState?['currentTurnPlayerId'] == opp.id;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isTurn
                                ? AppColors.cardSurfaceElevated
                                : Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isTurn
                                  ? AppColors.primary
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                opp.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isTurn
                                      ? AppColors.primary
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${opp.chips}c',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. Hero Secret Hole Cards Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isMyTurn ? AppColors.primary : AppColors.borderSubtle,
                  width: isMyTurn ? 2 : 1,
                ),
                boxShadow: [
                  if (isMyTurn)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'KARTU SAKU ${hasSelectedMe ? me.name.toUpperCase() : 'SAYA'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () =>
                            setState(() => _cardsFaceUp = !_cardsFaceUp),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.gold,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            _cardsFaceUp
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cardsFaceUp
                        ? 'Peran: ${me.id.isNotEmpty ? me.name : 'Pemain'} (Kartu Terbuka)'
                        : 'Tekan & Tahan / Sentuh untuk Mengintip Kartu Saku',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),

                  // Hole Cards Big Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CasinoCardWidget(
                        card: myHoleCards.isNotEmpty ? myHoleCards[0] : null,
                        isFaceUp: _cardsFaceUp,
                        allowPeek: true,
                        width: 72,
                        height: 104,
                      ),
                      const SizedBox(width: 14),
                      CasinoCardWidget(
                        card: myHoleCards.length > 1 ? myHoleCards[1] : null,
                        isFaceUp: _cardsFaceUp,
                        allowPeek: true,
                        width: 72,
                        height: 104,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 5. Turn / Winner Announcement Banner
            _buildTurnBanner(street: street, isMyTurn: isMyTurn),
            const SizedBox(height: 10),

            // 6. Action Dock
            _buildPortraitActionButtons(
              isMyTurn: isMyTurn,
              callAmount: callAmount,
              myCurrentBet: myCurrentBet,
              currentBet: currentBet,
              me: me,
              pot: pot,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LANDSCAPE LAYOUT (IMMERSIVE FULL TABLE MODE)
  // ==========================================
  Widget _buildLandscapeLayout({
    required BuildContext context,
    required List<PokerPlayer> players,
    required List<dynamic> rawPlayers,
    required PokerPlayer me,
    required bool hasSelectedMe,
    required bool isMyTurn,
    required int currentBet,
    required int myCurrentBet,
    required int callAmount,
    required int pot,
    required BettingStreet street,
    required List<PlayingCard> commCards,
    required List<PlayingCard> myHoleCards,
  }) {
    final count = players.length;
    final currentTurnId = _gameState?['currentTurnPlayerId'] as String?;
    final activeTurnIndex = players.indexWhere((p) => p.id == currentTurnId);

    return Stack(
      children: [
        // 1. FULL-SCREEN CASINO GREEN FELT TABLE & SEATING AREA
        Positioned.fill(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Green Felt Oval Table
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment.center,
                        radius: 0.85,
                        colors: [AppColors.tableFelt, AppColors.tableFeltDark],
                      ),
                      borderRadius: BorderRadius.circular(160),
                      border: Border.all(
                        color: AppColors.tableBorder,
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tableRim.withValues(alpha: 0.9),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(150),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Center Table Info (Pot, Community Cards, Street Pill)
              TableCenterWidget(
                pot: pot,
                pots: const [],
                street: street,
                currentBet: currentBet,
                communityCards: commCards,
              ),

              // Positioned Player Seats around the Table Perimeter
              ...List.generate(count, (i) {
                final align = _getSeatAlignment(i, count);
                final player = players[i];
                final isTurn =
                    activeTurnIndex == i &&
                    street != BettingStreet.showdown &&
                    street != BettingStreet.handEnded &&
                    street != BettingStreet.lobby;
                final isMe = player.id == _selectedPlayerId;

                return Align(
                  alignment: align,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: PlayerSeatWidget(
                      player: player,
                      isCurrentTurn: isTurn,
                      isOnline: true,
                      isLobbyMode: street == BettingStreet.lobby,
                      onTap: isMe
                          ? () => setState(() => _cardsFaceUp = !_cardsFaceUp)
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // 2. FLOATING TOP PLAYER SELECTOR BAR (Collapses into Compact Top-Left Pill in Landscape)
        if (_selectedPlayerId.isEmpty || _isEditingPlayer)
          Positioned(
            top: 6,
            left: 12,
            right: 12,
            child: _buildPlayerSelector(rawPlayers, me, isLandscape: true),
          )
        else
          Positioned(
            top: 6,
            left: 12,
            child: _buildPlayerSelector(rawPlayers, me, isLandscape: true),
          ),

        // 3. FLOATING ACTION DOCK AT THE BOTTOM
        Positioned(
          bottom: 4,
          left: 10,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTurnBanner(
                street: street,
                isMyTurn: isMyTurn,
                isLandscape: true,
              ),
              if (_selectedPlayerId != 'host' &&
                  street != BettingStreet.lobby) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isMyTurn ? () => _sendAction('fold') : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.foldButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'FOLD',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isMyTurn
                            ? () {
                                if (callAmount == 0 ||
                                    myCurrentBet == currentBet) {
                                  _sendAction('check');
                                } else {
                                  _sendAction('call');
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (callAmount == 0 || myCurrentBet == currentBet)
                              ? AppColors.checkButton
                              : AppColors.callButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          (callAmount == 0 || myCurrentBet == currentBet)
                              ? 'CHECK'
                              : 'CALL $callAmount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isMyTurn
                            ? () {
                                final minR =
                                    (_gameState?['minRaise'] as num?)
                                        ?.toInt() ??
                                    20;
                                final maxR =
                                    (_gameState?['maxRaise'] as num?)
                                        ?.toInt() ??
                                    100;
                                showDialog(
                                  context: context,
                                  builder: (context) => RaiseDialog(
                                    player: me,
                                    currentBet: currentBet,
                                    minRaise: minR,
                                    maxRaise: maxR,
                                    pot: pot,
                                    onConfirm: (amt) =>
                                        _sendAction('raise', amt),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.raiseButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'RAISE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isMyTurn ? () => _sendAction('allIn') : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.allInButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'ALL-IN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildPlayerSelector(
    List<dynamic> rawPlayers,
    PokerPlayer me, {
    bool isLandscape = false,
  }) {
    final street = _parseStreet(_gameState?['street'] as String?);
    final isLobby = street == BettingStreet.lobby;
    final canEditRole = isLobby || _selectedPlayerId == 'host';
    final showDropdown =
        _selectedPlayerId.isEmpty || (_isEditingPlayer && canEditRole);

    if (!showDropdown) {
      return Container(
        constraints: isLandscape ? const BoxConstraints(maxWidth: 240) : null,
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 8 : 12,
          vertical: isLandscape ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(isLandscape ? 10 : 14),
          border: Border.all(
            color: _isPlayerLocked ? AppColors.gold : AppColors.primary,
            width: isLandscape ? 1 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: canEditRole
              ? () {
                  setState(() {
                    _isEditingPlayer = true;
                    _isPlayerLocked = false;
                  });
                }
              : null,
          child: Row(
            mainAxisSize: isLandscape ? MainAxisSize.min : MainAxisSize.max,
            children: [
              CircleAvatar(
                radius: isLandscape ? 10 : 12,
                backgroundColor: me.avatarColor,
                child: Text(
                  me.name.isNotEmpty ? me.name[0].toUpperCase() : 'P',
                  style: TextStyle(
                    fontSize: isLandscape ? 9 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: isLandscape ? 6 : 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedPlayerId == 'host'
                          ? '👑 BANDAR / HOST (SPECTATOR)'
                          : (isLandscape
                                ? '${me.name.toUpperCase()} (${me.chips})'
                                : 'PERAN: ${me.name.toUpperCase()} (${me.chips} Chip)'),
                      style: TextStyle(
                        fontSize: isLandscape ? 10 : 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedPlayerId == 'host'
                          ? 'Spectator (Memantau Meja)'
                          : (me.isDealer
                                ? 'Dealer'
                                : (me.isSmallBlind
                                      ? 'Small Blind'
                                      : (me.isBigBlind
                                            ? 'Big Blind'
                                            : 'Player'))),
                      style: TextStyle(
                        fontSize: isLandscape ? 8 : 9,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isLandscape ? 2 : 4),
              if (canEditRole)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isEditingPlayer = true;
                      _isPlayerLocked = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.edit_rounded,
                      color: AppColors.gold,
                      size: isLandscape ? 14 : 18,
                    ),
                  ),
                )
              else
                const Icon(Icons.lock_rounded, color: AppColors.gold, size: 14),
            ],
          ),
        ),
      );
    }

    final availablePlayers = [
      {
        'id': 'host',
        'name': '👑 Bandar / Host Game (Spectator)',
        'chips': 0,
        'roleLabel': 'Spectator',
      },
      ...rawPlayers.where((pRaw) {
        final p = pRaw as Map<String, dynamic>;
        final id = p['id'] as String?;
        final isTakenByOther = p['isTakenByOther'] as bool? ?? false;
        return !isTakenByOther || id == _selectedPlayerId;
      }),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isPlayerLocked ? AppColors.gold : AppColors.primary,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlayerId.isNotEmpty ? _selectedPlayerId : null,
                hint: const Text(
                  '-- Pilih Pemain Anda --',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                dropdownColor: AppColors.cardSurfaceElevated,
                isExpanded: true,
                onChanged: _isPlayerLocked
                    ? null
                    : (id) {
                        _onPlayerSelected(id);
                        setState(() {
                          _isEditingPlayer = false;
                        });
                      },
                items: availablePlayers.map<DropdownMenuItem<String>>((pRaw) {
                  final p = pRaw as Map<String, dynamic>;
                  final role = p['roleLabel'] as String? ?? 'Player';
                  return DropdownMenuItem<String>(
                    value: p['id'] as String,
                    child: Text(
                      '${p['name']} (${p['chips']} Chip) - $role',
                      style: TextStyle(
                        color: _isPlayerLocked ? AppColors.gold : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_selectedPlayerId.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              tooltip: 'Selesai Pilih',
              onPressed: () {
                setState(() {
                  _isEditingPlayer = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTurnBanner({
    required BettingStreet street,
    required bool isMyTurn,
    bool isLandscape = false,
  }) {
    final isLobby = street == BettingStreet.lobby;
    final isShowdownOrEnded =
        street == BettingStreet.showdown || street == BettingStreet.handEnded;
    final lastLog = _gameState?['lastLog'] as String?;

    if (isShowdownOrEnded) {
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: isLandscape ? 4 : 8,
          horizontal: isLandscape ? 10 : 14,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9A3412), Color(0xFFD97706), Color(0xFF9A3412)],
          ),
          borderRadius: BorderRadius.circular(isLandscape ? 10 : 14),
          border: Border.all(
            color: AppColors.gold,
            width: isLandscape ? 1.2 : 1.8,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.amber, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: isLandscape ? 16 : 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '🏆 HASIL SHOWDOWN & PEMENANG RONDE!',
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            if (lastLog != null && lastLog.isNotEmpty) ...[
              SizedBox(height: isLandscape ? 2 : 4),
              Text(
                lastLog,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isLandscape ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    String bannerText =
        'Menunggu giliran ${_gameState?['currentTurnPlayerName'] ?? ''}...';
    if (isLobby) {
      bannerText = '⏳ HP TERHUBUNG! Menunggu Host Memulai Game...';
    } else if (isMyTurn) {
      bannerText = '🔴 GILIRAN ANDA BEAKSI!';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 3 : 6,
        horizontal: isLandscape ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: isMyTurn
            ? AppColors.primary.withValues(alpha: 0.9)
            : (isLobby
                  ? AppColors.gold.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(isLandscape ? 8 : 10),
        border: Border.all(
          color: isMyTurn
              ? AppColors.primary
              : (isLobby ? AppColors.gold : AppColors.borderSubtle),
        ),
      ),
      child: Text(
        bannerText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isLandscape ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: isMyTurn
              ? Colors.white
              : (isLobby ? Colors.black : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPortraitActionButtons({
    required bool isMyTurn,
    required int callAmount,
    required int myCurrentBet,
    required int currentBet,
    required PokerPlayer me,
    required int pot,
  }) {
    if (_selectedPlayerId == 'host') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_rounded, color: AppColors.gold, size: 18),
                SizedBox(width: 8),
                Text(
                  'Mode Bandar / Host Game (Spectator)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showRebuyDialog,
              icon: const Icon(Icons.add_card_rounded, size: 16),
              label: const Text(
                'Top-Up / Tambah Chip Pemain',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isMyTurn ? () => _sendAction('fold') : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.foldButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'FOLD',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: isMyTurn
                    ? () {
                        if (callAmount == 0 || myCurrentBet == currentBet) {
                          _sendAction('check');
                        } else {
                          _sendAction('call');
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (callAmount == 0 || myCurrentBet == currentBet)
                      ? AppColors.checkButton
                      : AppColors.callButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  (callAmount == 0 || myCurrentBet == currentBet)
                      ? 'CHECK'
                      : 'CALL $callAmount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isMyTurn
                    ? () {
                        final minR =
                            (_gameState?['minRaise'] as num?)?.toInt() ?? 20;
                        final maxR =
                            (_gameState?['maxRaise'] as num?)?.toInt() ?? 100;
                        showDialog(
                          context: context,
                          builder: (context) => RaiseDialog(
                            player: me,
                            currentBet: currentBet,
                            minRaise: minR,
                            maxRaise: maxR,
                            pot: pot,
                            onConfirm: (amt) => _sendAction('raise', amt),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.raiseButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'RAISE / BET',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: isMyTurn ? () => _sendAction('allIn') : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.allInButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'ALL-IN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
