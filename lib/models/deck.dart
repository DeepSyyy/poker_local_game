import 'dart:math';
import 'package:poker_local_game/models/playing_card.dart';

class Deck {
  final List<PlayingCard> _cards = [];
  final Random _random = Random.secure();

  Deck() {
    reset();
  }

  void reset() {
    _cards.clear();
    for (var suit in CardSuit.values) {
      for (var rank in CardRank.values) {
        _cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    shuffle();
  }

  void shuffle() {
    // Fisher-Yates shuffle with Random.secure()
    for (int i = _cards.length - 1; i > 0; i--) {
      int j = _random.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }

  PlayingCard dealCard({bool isFaceUp = true}) {
    if (_cards.isEmpty) {
      throw StateError('Cannot deal from an empty deck');
    }
    final card = _cards.removeLast();
    card.isFaceUp = isFaceUp;
    return card;
  }

  List<PlayingCard> dealCards(int count, {bool isFaceUp = true}) {
    final dealt = <PlayingCard>[];
    for (int i = 0; i < count; i++) {
      dealt.add(dealCard(isFaceUp: isFaceUp));
    }
    return dealt;
  }

  int get remainingCards => _cards.length;
}
