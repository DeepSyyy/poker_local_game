import 'package:flutter_test/flutter_test.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/models/hand_evaluator.dart';

void main() {
  group('HandEvaluator Tests', () {
    test('Royal Flush evaluation', () {
      final cards = [
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.king),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.queen),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.jack),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ten),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.two),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.three),
      ];

      final eval = HandEvaluator.evaluate(cards);
      expect(eval.rank, HandRank.royalFlush);
      expect(eval.description, contains('Royal Flush'));
    });

    test('Full House evaluation', () {
      final cards = [
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.diamonds, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.king),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.king),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.two),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.five),
      ];

      final eval = HandEvaluator.evaluate(cards);
      expect(eval.rank, HandRank.fullHouse);
      expect(eval.description, contains('Full House'));
    });

    test('Flush vs Straight ranking comparison', () {
      final flushCards = [
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.ten),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.eight),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.six),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.four),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.two),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.three),
      ];

      final straightCards = [
        PlayingCard(suit: CardSuit.spades, rank: CardRank.nine),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.eight),
        PlayingCard(suit: CardSuit.diamonds, rank: CardRank.seven),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.six),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.five),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.two),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.three),
      ];

      final flushEval = HandEvaluator.evaluate(flushCards);
      final straightEval = HandEvaluator.evaluate(straightCards);

      expect(flushEval.rank, HandRank.flush);
      expect(straightEval.rank, HandRank.straight);
      expect(flushEval.compareTo(straightEval), greaterThan(0));
    });

    test('Ace-low straight (Wheel straight A-2-3-4-5)', () {
      final cards = [
        PlayingCard(suit: CardSuit.spades, rank: CardRank.ace),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.two),
        PlayingCard(suit: CardSuit.diamonds, rank: CardRank.three),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.four),
        PlayingCard(suit: CardSuit.spades, rank: CardRank.five),
        PlayingCard(suit: CardSuit.hearts, rank: CardRank.jack),
        PlayingCard(suit: CardSuit.clubs, rank: CardRank.king),
      ];

      final eval = HandEvaluator.evaluate(cards);
      expect(eval.rank, HandRank.straight);
      expect(eval.scoreVector[1], 5); // 5 High
    });
  });
}
