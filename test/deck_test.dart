import 'package:flutter_test/flutter_test.dart';
import 'package:poker_local_game/models/deck.dart';
import 'package:poker_local_game/models/playing_card.dart';

void main() {
  group('Deck Tests', () {
    test('Deck initializes with 52 unique cards', () {
      final deck = Deck();
      expect(deck.remainingCards, 52);

      final cards = <PlayingCard>[];
      while (deck.remainingCards > 0) {
        cards.add(deck.dealCard());
      }
      expect(cards.length, 52);
      expect(cards.toSet().length, 52); // All cards must be unique
    });

    test('Deck shuffle changes card order', () {
      final deck1 = Deck();
      final deck2 = Deck();

      final list1 = deck1.dealCards(10);
      final list2 = deck2.dealCards(10);

      // Statistically, 10 dealt cards from 2 secure shuffles will not match completely
      bool allMatch = true;
      for (int i = 0; i < 10; i++) {
        if (list1[i] != list2[i]) {
          allMatch = false;
          break;
        }
      }
      expect(allMatch, isFalse);
    });
  });
}
