import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/poker_game_state.dart';
import 'package:belajar_flutter/core/constants/app_colors.dart';
import 'package:belajar_flutter/screens/poker/widgets/poker_chip_badge.dart';

class TableCenterWidget extends StatelessWidget {
  final int pot;
  final List<Pot> pots;
  final BettingStreet street;
  final int currentBet;
  final VoidCallback? onShowdownTap;
  final VoidCallback? onNextHandTap;

  const TableCenterWidget({
    super.key,
    required this.pot,
    required this.pots,
    required this.street,
    required this.currentBet,
    this.onShowdownTap,
    this.onNextHandTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Street Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                street.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Pot Display
        PokerChipBadge(
          amount: pot,
          label: 'TOTAL POT',
          chipColor: AppColors.gold,
          size: 24,
        ),

        // Side Pots if any
        if (pots.length > 1) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: pots.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 0.8),
                ),
                child: Text(
                  '${p.name}: ${p.amount}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 4),
        // Current Bet Info
        if (street != BettingStreet.showdown && street != BettingStreet.handEnded) ...[
          Text(
            currentBet > 0 ? 'Bet to Match: $currentBet chip' : 'Belum ada bet (Check)',
            style: TextStyle(
              color: currentBet > 0 ? AppColors.gold : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        // Showdown or Next Hand CTA Button
        if (street == BettingStreet.showdown) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onShowdownTap,
            icon: const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.black87),
            label: const Text('Pilih Pemenang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ] else if (street == BettingStreet.handEnded) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onNextHandTap,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Next Hand'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}
