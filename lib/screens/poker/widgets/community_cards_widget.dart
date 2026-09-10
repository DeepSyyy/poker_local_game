import 'package:flutter/material.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/screens/poker/widgets/casino_card_widget.dart';

class CommunityCardsWidget extends StatelessWidget {
  final List<PlayingCard> cards;
  final List<PlayingCard> winningCards;

  const CommunityCardsWidget({
    super.key,
    required this.cards,
    this.winningCards = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final card = index < cards.length ? cards[index] : null;
          final isWin = card != null && winningCards.contains(card);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: CasinoCardWidget(
              card: card,
              isFaceUp: card != null,
              width: 38,
              height: 54,
              isWinningCard: isWin,
            ),
          );
        }),
      ),
    );
  }
}
