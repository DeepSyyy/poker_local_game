import 'package:flutter/material.dart';
import 'package:poker_local_game/models/poker_game_state.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/screens/poker/widgets/poker_chip_badge.dart';
import 'package:poker_local_game/screens/poker/widgets/community_cards_widget.dart';

class TableCenterWidget extends StatelessWidget {
  final int pot;
  final List<Pot> pots;
  final BettingStreet street;
  final int currentBet;
  final List<PlayingCard> communityCards;
  final List<PlayingCard> winningCards;
  final VoidCallback? onShowdownTap;
  final VoidCallback? onNextHandTap;

  const TableCenterWidget({
    super.key,
    required this.pot,
    required this.pots,
    required this.street,
    required this.currentBet,
    required this.communityCards,
    this.winningCards = const [],
    this.onShowdownTap,
    this.onNextHandTap,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Street Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
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
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Community Cards Slot Area
          CommunityCardsWidget(
            cards: communityCards,
            winningCards: winningCards,
          ),

          const SizedBox(height: 6),

          // Pot Display
          PokerChipBadge(
            amount: pot,
            label: 'TOTAL POT',
            chipColor: AppColors.gold,
            size: 22,
          ),

          // Side Pots if any
          if (pots.length > 1) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: pots.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
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
          if (street != BettingStreet.showdown &&
              street != BettingStreet.handEnded) ...[
            Text(
              currentBet > 0
                  ? 'Bet to Match: $currentBet chip'
                  : 'Belum ada bet (Check)',
              style: TextStyle(
                color: currentBet > 0
                    ? AppColors.gold
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Showdown or Next Hand CTA Button
          if (street == BettingStreet.showdown ||
              street == BettingStreet.handEnded) ...[
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: onNextHandTap,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Ronde Berikutnya (Next Hand)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                elevation: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
