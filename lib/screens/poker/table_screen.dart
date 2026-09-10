import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poker_local_game/screens/poker/setup_screen.dart';
import 'package:poker_local_game/screens/poker/widgets/qr_connect_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/controllers/poker_game_controller.dart';
import 'package:poker_local_game/models/poker_game_state.dart';

import 'package:poker_local_game/screens/poker/widgets/player_seat_widget.dart';
import 'package:poker_local_game/screens/poker/widgets/table_center_widget.dart';
import 'package:poker_local_game/screens/poker/widgets/poker_action_bar.dart';
import 'package:poker_local_game/screens/poker/widgets/raise_dialog.dart';
import 'package:poker_local_game/screens/poker/widgets/showdown_dialog.dart';
import 'package:poker_local_game/screens/poker/widgets/rebuy_dialog.dart';
import 'package:poker_local_game/screens/poker/widgets/action_history_sheet.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/screens/poker/widgets/card_picker_dialog.dart';
import 'package:poker_local_game/screens/poker/widgets/winner_dialog.dart';
import 'package:poker_local_game/models/playing_card.dart';

class TableScreen extends StatefulWidget {
  final PokerGameController controller;

  const TableScreen({super.key, required this.controller});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  PokerGameController get _c => widget.controller;
  BettingStreet? _previousStreet;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    final currentStreet = _c.street;
    if (currentStreet == BettingStreet.handEnded &&
        _previousStreet != BettingStreet.handEnded) {
      _showWinnerDialog();
    }
    _previousStreet = currentStreet;
    setState(() {});
  }

  void _showWinnerDialog() {
    final activePlayers = _c.players
        .where((p) => p.status != PlayerStatus.out)
        .toList();
    if (activePlayers.isEmpty) return;

    final inHand = activePlayers
        .where((p) => p.status != PlayerStatus.folded)
        .toList();

    List<PokerPlayer> winners = [];
    String? handDesc;

    if (inHand.length == 1) {
      winners = [inHand.first];
      handDesc = 'Pemain Lain Fold';
    } else if (inHand.isNotEmpty) {
      inHand.sort((a, b) {
        if (a.evaluation == null && b.evaluation == null) return 0;
        if (a.evaluation == null) return 1;
        if (b.evaluation == null) return -1;
        return b.evaluation!.compareTo(a.evaluation!);
      });
      final topEval = inHand.first.evaluation;
      if (topEval != null) {
        winners = inHand
            .where((p) => p.evaluation?.compareTo(topEval) == 0)
            .toList();
        handDesc = topEval.description;
      } else {
        winners = [inHand.first];
      }
    }

    if (winners.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => WinnerDialog(
          winners: winners,
          potAmount: _c.pot,
          handDescription: handDesc,
          autoDismissSeconds: 3,
        ),
      );
    }
  }

  void _openRaiseDialog() {
    final active = _c.currentTurnPlayer;
    if (active == null) return;

    showDialog(
      context: context,
      builder: (context) => RaiseDialog(
        player: active,
        currentBet: _c.currentBet,
        minRaise: _c.minRaiseAmount,
        maxRaise: _c.maxRaiseAmount,
        pot: _c.pot,
        onConfirm: (amount) => _c.raiseTo(amount),
      ),
    );
  }

  void _openShowdownDialog() {
    if (_c.pots.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShowdownDialog(
        currentPot: _c.pots.first,
        allPlayers: _c.players,
        onConfirmWinners: (winnerIds) {
          _c.awardPot(_c.pots.first, winnerIds);
          // Jika masih ada side pot berikutnya, buka dialog lagi
          if (_c.pots.isNotEmpty) {
            Future.microtask(() => _openShowdownDialog());
          }
        },
      ),
    );
  }

  void _openCardPickerDialog(PokerPlayer player) {
    showDialog(
      context: context,
      builder: (context) => CardPickerDialog(
        title: 'Input Kartu Fisik: ${player.name}',
        initialSelection: player.holeCards,
        unavailableCards: _c.usedCards
            .where((c) => !player.holeCards.contains(c))
            .toList(),
        maxSelection: 2,
        onConfirm: (selected) {
          _c.setPlayerHoleCards(player.id, selected);
        },
      ),
    );
  }

  void _openQrConnectDialog() {
    if (_c.server == null) {
      _c.startServer();
    }
    showDialog(
      context: context,
      builder: (context) => QrConnectDialog(server: _c.server!),
    );
  }

  void _openRebuyDialog() {
    showDialog(
      context: context,
      builder: (context) => RebuyDialog(
        players: _c.players,
        onAddChips: (playerId, amount) => _c.addChipsToPlayer(playerId, amount),
      ),
    );
  }

  void _openHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: ActionHistorySheet(logs: _c.logs),
      ),
    );
  }

  void _confirmNewGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text(
          'Reset Permainan?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda ingin kembali ke menu setup pemain? Permainan saat ini akan direset.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.foldButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SetupScreen(controller: _c),
                ),
              );
            },
            child: const Text(
              'Reset ke Setup',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _c.players.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. FULL-SCREEN TABLE FELT & SEATING AREA
          Positioned.fill(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Green Felt Oval Table (Meja Poker Full Screen)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [
                            AppColors.tableFelt,
                            AppColors.tableFeltDark,
                          ],
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

                // Center Table Info (Pot, Street, Community Cards, Next Hand CTA or Lobby UI)
                if (_c.street == BettingStreet.lobby)
                  _buildLobbyCenterWidget()
                else ...[
                  Builder(
                    builder: (context) {
                      List<PlayingCard> winningCards = [];
                      if (_c.street == BettingStreet.showdown ||
                          _c.street == BettingStreet.handEnded) {
                        final inHand = _c.players
                            .where(
                              (p) =>
                                  p.status != PlayerStatus.folded &&
                                  p.evaluation != null,
                            )
                            .toList();
                        if (inHand.isNotEmpty) {
                          inHand.sort(
                            (a, b) => b.evaluation!.compareTo(a.evaluation!),
                          );
                          winningCards = inHand.first.evaluation!.bestFiveCards;
                        }
                      }

                      return TableCenterWidget(
                        pot: _c.pot,
                        pots: _c.pots,
                        street: _c.street,
                        currentBet: _c.currentBet,
                        communityCards: _c.communityCards,
                        winningCards: winningCards,
                        onShowdownTap: _openShowdownDialog,
                        onNextHandTap: _c.startNewHand,
                      );
                    },
                  ),
                ],

                // Positioned Player Seats around the Table Perimeter
                ...List.generate(count, (i) {
                  final align = _getSeatAlignment(i, count);
                  final player = _c.players[i];
                  final isTurn =
                      _c.currentTurnIndex == i &&
                      _c.street != BettingStreet.showdown &&
                      _c.street != BettingStreet.handEnded &&
                      _c.street != BettingStreet.lobby;
                  final isOnline = _c.isPlayerOnline(player.id);

                  return Align(
                    alignment: align,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: PlayerSeatWidget(
                        player: player,
                        isCurrentTurn: isTurn,
                        isOnline: isOnline,
                        isLobbyMode: _c.street == BettingStreet.lobby,
                        onTap: () => _openCardPickerDialog(player),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 2. FLOATING TOP CONTROLS (Pojok Kiri & Kanan Mengambang)
          Positioned(
            top: 8,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left badge: Blinds & Compact Server IP
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.casino_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _c.blindsEnabled
                            ? 'Blinds: ${_c.smallBlind}/${_c.bigBlind}'
                            : 'Casual Poker',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      if (_c.server != null) ...[
                        const SizedBox(width: 8),
                        Container(width: 1, height: 10, color: Colors.white24),
                        const SizedBox(width: 8),
                        Text(
                          _c.server!.serverUrl,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Right actions: Floating buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingIconButton(
                      icon: Icons.qr_code_2_rounded,
                      tooltip: 'Sambung HP Pemain (QR Code)',
                      accentColor: AppColors.primary,
                      onTap: _openQrConnectDialog,
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingIconButton(
                      icon: Icons.history_rounded,
                      tooltip: 'Log Aksi',
                      onTap: _openHistorySheet,
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingIconButton(
                      icon: Icons.add_card_rounded,
                      tooltip: 'Rebuy / Top-up',
                      accentColor: AppColors.gold,
                      onTap: _openRebuyDialog,
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingIconButton(
                      icon: Icons.settings_backup_restore_rounded,
                      tooltip: 'Reset / Setup Baru',
                      onTap: _confirmNewGame,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. FLOATING ACTION DOCK AT THE BOTTOM (Ramping & Mengambang di Bawah)
          if (_c.street != BettingStreet.lobby &&
              _c.street != BettingStreet.showdown &&
              _c.street != BettingStreet.handEnded) ...[
            Positioned(
              bottom: 8,
              left: 20,
              right: 20,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: PokerActionBar(
                    activePlayer: _c.currentTurnPlayer,
                    isOnline:
                        _c.currentTurnPlayer != null &&
                        _c.isPlayerOnline(_c.currentTurnPlayer!.id),
                    canCheck: _c.canCheck,
                    callAmount: _c.callAmount,
                    canRaise: _c.canRaiseAmount,
                    onFold: _c.fold,
                    onCheck: _c.check,
                    onCall: _c.call,
                    onRaiseTap: _openRaiseDialog,
                    onAllIn: _c.allIn,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accentColor?.withValues(alpha: 0.4) ?? Colors.white12,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(
            icon,
            size: 16,
            color: accentColor ?? AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Menghitung posisi relatif (x, y) kursi pemain di sekeliling meja oval
  Alignment _getSeatAlignment(int index, int total) {
    switch (total) {
      case 2:
        // 2 Pemain (Heads-Up): Kiri & Kanan berhadapan
        return index == 0
            ? const Alignment(-0.84, 0.0)
            : const Alignment(0.84, 0.0);

      case 3:
        // 3 Pemain: Kiri, Atas, Kanan
        const positions = [
          Alignment(-0.84, 0.15),
          Alignment(0.0, -0.80),
          Alignment(0.84, 0.15),
        ];
        return positions[index % positions.length];

      case 4:
        // 4 Pemain: Kiri, Atas, Kanan, Bawah
        const positions = [
          Alignment(-0.84, 0.0),
          Alignment(0.0, -0.80),
          Alignment(0.84, 0.0),
          Alignment(0.0, 0.80),
        ];
        return positions[index % positions.length];

      case 5:
        // 5 Pemain: Kiri, Atas-Kiri, Atas-Kanan, Kanan, Bawah
        const positions = [
          Alignment(-0.84, 0.12),
          Alignment(-0.48, -0.80),
          Alignment(0.48, -0.80),
          Alignment(0.84, 0.12),
          Alignment(0.0, 0.80),
        ];
        return positions[index % positions.length];

      case 6:
        // 6 Pemain: Kiri, Atas-Kiri, Atas-Kanan, Kanan, Bawah-Kanan, Bawah-Kiri
        const positions = [
          Alignment(-0.84, 0.0),
          Alignment(-0.48, -0.80),
          Alignment(0.48, -0.80),
          Alignment(0.84, 0.0),
          Alignment(0.48, 0.80),
          Alignment(-0.48, 0.80),
        ];
        return positions[index % positions.length];

      case 7:
        // 7 Pemain
        const positions = [
          Alignment(-0.84, 0.08),
          Alignment(-0.52, -0.80),
          Alignment(0.0, -0.80),
          Alignment(0.52, -0.80),
          Alignment(0.84, 0.08),
          Alignment(0.45, 0.80),
          Alignment(-0.45, 0.80),
        ];
        return positions[index % positions.length];

      case 8:
        // 8 Pemain
        const positions = [
          Alignment(-0.84, 0.0),
          Alignment(-0.54, -0.80),
          Alignment(0.0, -0.80),
          Alignment(0.54, -0.80),
          Alignment(0.84, 0.0),
          Alignment(0.54, 0.80),
          Alignment(0.0, 0.80),
          Alignment(-0.54, 0.80),
        ];
        return positions[index % positions.length];

      default:
        final angle = (pi / 2) + (index * 2 * pi / max(1, total));
        return Alignment(0.84 * cos(angle), 0.80 * sin(angle));
    }
  }

  Widget _buildLobbyCenterWidget() {
    final url = _c.server?.serverUrl ?? 'http://192.168.1.34:8080';
    final onlineCount = _c.players.where((p) => _c.isPlayerOnline(p.id)).length;
    final totalCount = _c.players.length;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 15, spreadRadius: 3),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact QR Code Image on Left
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 85.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            // Information & Start Game Button Column on Right
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOBBY: MENUNGGU PEMAIN JOIN',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scan QR atau buka IP: $url',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  'HP Terhubung: $onlineCount / $totalCount Perangkat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: onlineCount > 0
                        ? AppColors.primary
                        : Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _c.startGameFromLobby(),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('MULAI GAME & BAGIKAN KARTU'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension PokerGameControllerExt on PokerGameController {
  bool get canRaiseAmount {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return false;
    final toCall = currentBet - p.currentRoundBet;
    return p.chips > toCall;
  }
}
