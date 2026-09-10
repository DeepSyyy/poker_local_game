import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/poker_player.dart';
import 'package:belajar_flutter/core/constants/app_colors.dart';

class PlayerSeatWidget extends StatelessWidget {
  final PokerPlayer player;
  final bool isCurrentTurn;
  final VoidCallback? onTap;

  const PlayerSeatWidget({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFolded = player.status == PlayerStatus.folded;
    final isAllIn = player.status == PlayerStatus.allIn;
    final isOut = player.status == PlayerStatus.out;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isFolded || isOut ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isCurrentTurn
                ? AppColors.cardSurfaceElevated
                : AppColors.cardSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrentTurn
                  ? AppColors.primary
                  : (isAllIn ? AppColors.allInButton : AppColors.borderSubtle),
              width: isCurrentTurn ? 2.5 : 1.2,
            ),
            boxShadow: [
              if (isCurrentTurn)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              else
                const BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                  // Avatar & Role Badges
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: player.avatarColor,
                        child: Text(
                          player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (player.isDealer)
                        Positioned(
                          right: -5,
                          bottom: -5,
                          child: _buildRoleBadge('D', Colors.white, Colors.black),
                        )
                      else if (player.isSmallBlind)
                        Positioned(
                          right: -5,
                          bottom: -5,
                          child: _buildRoleBadge('SB', Colors.blueAccent, Colors.white),
                        )
                      else if (player.isBigBlind)
                        Positioned(
                          right: -5,
                          bottom: -5,
                          child: _buildRoleBadge('BB', AppColors.gold, Colors.black),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // Player Info (Name, Chips, Status)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              player.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCurrentTurn ? AppColors.primary : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFolded) ...[
                            const SizedBox(width: 4),
                            _buildStatusTag('FOLD', Colors.redAccent),
                          ] else if (isAllIn) ...[
                            const SizedBox(width: 4),
                            _buildStatusTag('ALL-IN', AppColors.allInButton),
                          ] else if (isOut) ...[
                            const SizedBox(width: 4),
                            _buildStatusTag('OUT', Colors.grey),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.toll, size: 12, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            '${player.chips}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                          if (player.currentRoundBet > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.gold, width: 0.8),
                              ),
                              child: Text(
                                'Bet: ${player.currentRoundBet}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildRoleBadge(String label, Color bgColor, Color textColor) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 2),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length > 1 ? 8 : 9,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
