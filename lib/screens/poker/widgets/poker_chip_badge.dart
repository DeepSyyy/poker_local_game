import 'package:flutter/material.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';

class PokerChipBadge extends StatelessWidget {
  final int amount;
  final String? label;
  final Color chipColor;
  final double size;

  const PokerChipBadge({
    super.key,
    required this.amount,
    this.label,
    this.chipColor = AppColors.gold,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: chipColor.withValues(alpha: 0.2),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chipColor,
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                )
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.toll_rounded,
                size: 13,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (label != null) ...[
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Text(
            _formatAmount(amount),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 10000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
