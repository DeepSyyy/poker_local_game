import 'package:flutter/material.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';

class PokerActionBar extends StatelessWidget {
  final PokerPlayer? activePlayer;
  final bool isOnline;
  final bool canCheck;
  final int callAmount;
  final bool canRaise;
  final VoidCallback onFold;
  final VoidCallback onCheck;
  final VoidCallback onCall;
  final VoidCallback onRaiseTap;
  final VoidCallback onAllIn;

  const PokerActionBar({
    super.key,
    required this.activePlayer,
    this.isOnline = false,
    required this.canCheck,
    required this.callAmount,
    required this.canRaise,
    required this.onFold,
    required this.onCheck,
    required this.onCall,
    required this.onRaiseTap,
    required this.onAllIn,
  });

  @override
  Widget build(BuildContext context) {
    if (activePlayer == null || !activePlayer!.canAct) {
      return const SizedBox.shrink();
    }

    final p = activePlayer!;
    final isCallAllIn = callAmount >= p.chips;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Active Player Turn Badge (Compact Capsule)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.avatarColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.avatarColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: p.avatarColor,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${p.chips} chip',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action Buttons Group
          Expanded(
            child: Row(
              children: [
                // FOLD
                Expanded(
                  child: _buildActionButton(
                    label: 'FOLD',
                    color: AppColors.foldButton,
                    icon: Icons.close_rounded,
                    onPressed: onFold,
                  ),
                ),
                const SizedBox(width: 6),

                // CHECK or CALL
                if (canCheck) ...[
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      label: 'CHECK',
                      color: AppColors.checkButton,
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: onCheck,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      label: isCallAllIn ? 'CALL ALL-IN' : 'CALL $callAmount',
                      color: AppColors.callButton,
                      icon: Icons.arrow_upward_rounded,
                      onPressed: onCall,
                    ),
                  ),
                ],
                const SizedBox(width: 6),

                // RAISE
                if (canRaise) ...[
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      label: 'RAISE...',
                      color: AppColors.raiseButton,
                      icon: Icons.trending_up_rounded,
                      onPressed: onRaiseTap,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // ALL-IN
                Expanded(
                  child: _buildActionButton(
                    label: 'ALL-IN',
                    color: AppColors.allInButton,
                    icon: Icons.bolt_rounded,
                    onPressed: onAllIn,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
