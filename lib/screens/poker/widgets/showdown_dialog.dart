import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/models/poker_game_state.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/screens/poker/widgets/casino_card_widget.dart';

class ShowdownDialog extends StatefulWidget {
  final Pot currentPot;
  final List<PokerPlayer> allPlayers;
  final Function(List<String> winnerIds) onConfirmWinners;

  const ShowdownDialog({
    super.key,
    required this.currentPot,
    required this.allPlayers,
    required this.onConfirmWinners,
  });

  @override
  State<ShowdownDialog> createState() => _ShowdownDialogState();
}

class _ShowdownDialogState extends State<ShowdownDialog> {
  final Set<String> _selectedWinnerIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-select top auto-evaluated winner(s)
    final eligible = widget.allPlayers
        .where(
          (p) =>
              widget.currentPot.eligiblePlayerIds.contains(p.id) &&
              p.evaluation != null,
        )
        .toList();
    if (eligible.isNotEmpty) {
      eligible.sort((a, b) => b.evaluation!.compareTo(a.evaluation!));
      final bestEval = eligible.first.evaluation!;
      for (var p in eligible) {
        if (p.evaluation!.compareTo(bestEval) == 0) {
          _selectedWinnerIds.add(p.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligiblePlayers = widget.allPlayers
        .where((p) => widget.currentPot.eligiblePlayerIds.contains(p.id))
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      child: Container(
        width: min(520, MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Showdown: ${widget.currentPot.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Total Pot: ${widget.currentPot.amount} chip • Evaluasi Bandar Otomatis',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Eligible Players List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: eligiblePlayers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final player = eligiblePlayers[index];
                  final isSelected = _selectedWinnerIds.contains(player.id);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedWinnerIds.remove(player.id);
                        } else {
                          _selectedWinnerIds.add(player.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.borderSubtle,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: player.avatarColor,
                            child: Text(
                              player.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      player.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected
                                            ? AppColors.gold
                                            : Colors.white,
                                      ),
                                    ),
                                    if (player.evaluation != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          player.evaluation!.rank.label,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  player.evaluation != null
                                      ? player.evaluation!.description
                                      : 'Saldo: ${player.chips} chip',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Cards Preview
                          if (player.holeCards.length == 2) ...[
                            Row(
                              children: [
                                CasinoCardWidget(
                                  card: player.holeCards[0],
                                  isFaceUp: true,
                                  width: 24,
                                  height: 34,
                                ),
                                const SizedBox(width: 2),
                                CasinoCardWidget(
                                  card: player.holeCards[1],
                                  isFaceUp: true,
                                  width: 24,
                                  height: 34,
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                          ],

                          Checkbox(
                            value: isSelected,
                            activeColor: AppColors.gold,
                            checkColor: Colors.black,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedWinnerIds.add(player.id);
                                } else {
                                  _selectedWinnerIds.remove(player.id);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedWinnerIds.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Split Pot: ${widget.currentPot.amount ~/ _selectedWinnerIds.length} chip per pemenang (${_selectedWinnerIds.length} orang)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // Confirm Button
            ElevatedButton(
              onPressed: _selectedWinnerIds.isEmpty
                  ? null
                  : () {
                      widget.onConfirmWinners(_selectedWinnerIds.toList());
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'KONFIRMASI PEMENANG & BAGIKAN CHIP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
