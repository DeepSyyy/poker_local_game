import 'dart:math';
import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/poker_player.dart';
import 'package:belajar_flutter/models/poker_game_state.dart';
import 'package:belajar_flutter/core/constants/app_colors.dart';

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
        width: min(480, MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 24),
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
                        'Total: ${widget.currentPot.amount} chip (Pilih pemain dengan kartu terbaik)',
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
              constraints: const BoxConstraints(maxHeight: 200),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.borderSubtle,
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isSelected ? AppColors.gold : Colors.white,
                                  ),
                                ),
                                Text(
                                  'Saldo saat ini: ${player.chips} chip',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
            const SizedBox(height: 14),

            if (_selectedWinnerIds.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'SERAHKAN CHIP POT KE PEMENANG',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
