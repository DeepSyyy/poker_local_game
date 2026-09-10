import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/screens/poker/widgets/casino_card_widget.dart';
import 'package:poker_local_game/screens/poker/widgets/community_cards_widget.dart';
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
    setState(() => _selectedPlayerId = id);
    if (_socket != null && _isConnected) {
      _socket!.add(jsonEncode({'type': 'select_player', 'playerId': id}));
    }
  }

  PlayingCard? _parseCard(Map<String, dynamic>? json) {
    if (json == null) return null;
    final suitStr = json['suit'] as String?;
    final rankStr = json['rank'] as String?;
    if (suitStr == null || rankStr == null) return null;

    final suit = CardSuit.values.firstWhere(
      (s) => s.symbol == suitStr,
      orElse: () => CardSuit.spades,
    );
    final rank = CardRank.values.firstWhere(
      (r) => r.label == rankStr,
      orElse: () => CardRank.ace,
    );
    final isFaceUp = json['isFaceUp'] as bool? ?? true;
    return PlayingCard(suit: suit, rank: rank, isFaceUp: isFaceUp);
  }

  @override
  Widget build(BuildContext context) {
    final players = (_gameState?['players'] as List?) ?? [];
    final me = players.firstWhere(
      (p) => p['id'] == _selectedPlayerId,
      orElse: () => null,
    );

    final currentTurnId = _gameState?['currentTurnPlayerId'] as String?;
    final isMyTurn = me != null && currentTurnId == me['id'];
    final currentBet = (_gameState?['currentBet'] as num?)?.toInt() ?? 0;
    final myCurrentBet = (me?['currentRoundBet'] as num?)?.toInt() ?? 0;
    final callAmount = (_gameState?['callAmount'] as num?)?.toInt() ?? 0;
    final pot = (_gameState?['pot'] as num?)?.toInt() ?? 0;

    final commCardsRaw = (_gameState?['communityCards'] as List?) ?? [];
    final commCards = commCardsRaw
        .map((c) => _parseCard(c as Map<String, dynamic>))
        .whereType<PlayingCard>()
        .toList();

    List<PlayingCard> myHoleCards = [];
    if (me != null && me['holeCards'] != null) {
      myHoleCards = (me['holeCards'] as List)
          .map((c) => _parseCard(c as Map<String, dynamic>))
          .whereType<PlayingCard>()
          .toList();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Player Dropdown Selector with Lock Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPlayerLocked ? AppColors.gold : AppColors.primary,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPlayerId.isNotEmpty
                              ? _selectedPlayerId
                              : null,
                          hint: const Text(
                            '-- Pilih Pemain Anda --',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          dropdownColor: AppColors.cardSurfaceElevated,
                          isExpanded: true,
                          onChanged: _isPlayerLocked ? null : _onPlayerSelected,
                          items: players.map<DropdownMenuItem<String>>((p) {
                            final role = p['roleLabel'] as String? ?? 'Player';
                            return DropdownMenuItem<String>(
                              value: p['id'] as String,
                              child: Text(
                                '${p['name']} (${p['chips']} Chip) - $role',
                                style: TextStyle(
                                  color: _isPlayerLocked
                                      ? AppColors.gold
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (_selectedPlayerId.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          _isPlayerLocked
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: _isPlayerLocked
                              ? AppColors.gold
                              : Colors.white60,
                          size: 20,
                        ),
                        tooltip: _isPlayerLocked
                            ? 'Buka Kunci Peran'
                            : 'Kunci Peran Pemain Ini',
                        onPressed: () {
                          setState(() {
                            _isPlayerLocked = !_isPlayerLocked;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Chips & Pot Header
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      label: 'CHIP SAYA',
                      value: '${me?['chips'] ?? 0}',
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
              const SizedBox(height: 8),

              // Secret Cards Box (Casino Green Felt Background)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [AppColors.tableFelt, AppColors.tableFeltDark],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.tableBorder, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'KARTU SAKU ${me != null ? (me['name'] as String).toUpperCase() : 'SAYA'}',
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
                          ? 'Peran: ${me?['roleLabel'] ?? 'Player'} (Kartu Terbuka)'
                          : 'Peran: ${me?['roleLabel'] ?? 'Player'} (Tekan & Tahan untuk Mengintip)',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Hole Cards Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CasinoCardWidget(
                          card: myHoleCards.isNotEmpty ? myHoleCards[0] : null,
                          isFaceUp: _cardsFaceUp,
                          allowPeek: true,
                          width: 58,
                          height: 86,
                        ),
                        const SizedBox(width: 10),
                        CasinoCardWidget(
                          card: myHoleCards.length > 1 ? myHoleCards[1] : null,
                          isFaceUp: _cardsFaceUp,
                          allowPeek: true,
                          width: 58,
                          height: 86,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Community Cards Preview
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CommunityCardsWidget(cards: commCards),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Turn Notification Banner
              Builder(
                builder: (context) {
                  final isLobby = _gameState?['street'] == 'lobby';
                  String bannerText =
                      'Menunggu giliran ${_gameState?['currentTurnPlayerName'] ?? ''}...';
                  if (isLobby) {
                    bannerText =
                        '⏳ HP TERHUBUNG! Menunggu Host Memulai Game...';
                  } else if (isMyTurn) {
                    bannerText = '🔴 GILIRAN ANDA BEAKSI!';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isMyTurn
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : (isLobby
                                ? AppColors.gold.withValues(alpha: 0.15)
                                : AppColors.cardSurface),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMyTurn
                            ? AppColors.primary
                            : (isLobby
                                  ? AppColors.gold
                                  : AppColors.borderSubtle),
                      ),
                    ),
                    child: Text(
                      bannerText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMyTurn
                            ? AppColors.primary
                            : (isLobby
                                  ? AppColors.gold
                                  : AppColors.textSecondary),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Action Dock
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isMyTurn
                              ? () => _sendAction('fold')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.foldButton,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'FOLD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
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
                                      player: me != null
                                          ? PokerPlayer(
                                              id: me['id'],
                                              name: me['name'],
                                              chips: me['chips'],
                                              avatarColor: Colors.blue,
                                            )
                                          : PokerPlayer(
                                              id: '0',
                                              name: 'Player',
                                              chips: 100,
                                              avatarColor: Colors.blue,
                                            ),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'RAISE / BET',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isMyTurn
                              ? () => _sendAction('allIn')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.allInButton,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'ALL-IN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
