import 'package:poker_local_game/models/playing_card.dart';

enum HandRank {
  highCard(1, 'High Card'),
  onePair(2, 'One Pair'),
  twoPair(3, 'Two Pair'),
  threeOfAKind(4, 'Three of a Kind'),
  straight(5, 'Straight'),
  flush(6, 'Flush'),
  fullHouse(7, 'Full House'),
  fourOfAKind(8, 'Four of a Kind'),
  straightFlush(9, 'Straight Flush'),
  royalFlush(10, 'Royal Flush');

  final int value;
  final String label;

  const HandRank(this.value, this.label);
}

class HandEvaluation implements Comparable<HandEvaluation> {
  final HandRank rank;
  final List<int> scoreVector;
  final String description;
  final List<PlayingCard> bestFiveCards;

  HandEvaluation({
    required this.rank,
    required this.scoreVector,
    required this.description,
    required this.bestFiveCards,
  });

  @override
  int compareTo(HandEvaluation other) {
    for (
      int i = 0;
      i < scoreVector.length && i < other.scoreVector.length;
      i++
    ) {
      if (scoreVector[i] != other.scoreVector[i]) {
        return scoreVector[i].compareTo(other.scoreVector[i]);
      }
    }
    return scoreVector.length.compareTo(other.scoreVector.length);
  }
}

class HandEvaluator {
  /// Evaluates 5..7 cards and returns the best 5-card HandEvaluation.
  static HandEvaluation evaluate(List<PlayingCard> cards) {
    if (cards.length < 5) {
      throw ArgumentError('At least 5 cards are required for evaluation.');
    }

    final combos = _generate5CardCombinations(cards);
    HandEvaluation? bestEval;

    for (var combo in combos) {
      final eval = _evaluate5Cards(combo);
      if (bestEval == null || eval.compareTo(bestEval) > 0) {
        bestEval = eval;
      }
    }

    return bestEval!;
  }

  static List<List<PlayingCard>> _generate5CardCombinations(
    List<PlayingCard> cards,
  ) {
    final results = <List<PlayingCard>>[];
    final n = cards.length;

    for (int i = 0; i < n - 4; i++) {
      for (int j = i + 1; j < n - 3; j++) {
        for (int k = j + 1; k < n - 2; k++) {
          for (int l = k + 1; l < n - 1; l++) {
            for (int m = l + 1; m < n; m++) {
              results.add([cards[i], cards[j], cards[k], cards[l], cards[m]]);
            }
          }
        }
      }
    }
    return results;
  }

  static HandEvaluation _evaluate5Cards(List<PlayingCard> fiveCards) {
    final sorted = List<PlayingCard>.from(fiveCards)
      ..sort((a, b) => b.rank.value.compareTo(a.rank.value));

    final isFlush = sorted.every((c) => c.suit == sorted.first.suit);

    // Check straight
    bool isStraight = false;
    int straightTopRank = 0;

    final ranks = sorted.map((c) => c.rank.value).toList();
    if (ranks[0] - ranks[1] == 1 &&
        ranks[1] - ranks[2] == 1 &&
        ranks[2] - ranks[3] == 1 &&
        ranks[3] - ranks[4] == 1) {
      isStraight = true;
      straightTopRank = ranks[0];
    } else if (ranks[0] == 14 &&
        ranks[1] == 5 &&
        ranks[2] == 4 &&
        ranks[3] == 3 &&
        ranks[4] == 2) {
      // Ace-low straight (A-2-3-4-5)
      isStraight = true;
      straightTopRank = 5;
    }

    // Straight Flush & Royal Flush
    if (isFlush && isStraight) {
      if (straightTopRank == 14) {
        return HandEvaluation(
          rank: HandRank.royalFlush,
          scoreVector: [10, 14],
          description: 'Royal Flush (${sorted.first.suit.nameLabel})',
          bestFiveCards: sorted,
        );
      }
      final topRankLabel = _rankLabelFromValue(straightTopRank);
      return HandEvaluation(
        rank: HandRank.straightFlush,
        scoreVector: [9, straightTopRank],
        description: 'Straight Flush, $topRankLabel High',
        bestFiveCards: sorted,
      );
    }

    // Group frequencies
    final freqMap = <int, int>{};
    for (var r in ranks) {
      freqMap[r] = (freqMap[r] ?? 0) + 1;
    }

    final counts = freqMap.entries.toList()
      ..sort((a, b) {
        if (a.value != b.value) {
          return b.value.compareTo(a.value);
        }
        return b.key.compareTo(a.key);
      });

    // Four of a Kind
    if (counts[0].value == 4) {
      final quadRank = counts[0].key;
      final kickerRank = counts[1].key;
      return HandEvaluation(
        rank: HandRank.fourOfAKind,
        scoreVector: [8, quadRank, kickerRank],
        description: 'Four of a Kind, ${_rankLabelFromValue(quadRank)}s',
        bestFiveCards: sorted,
      );
    }

    // Full House
    if (counts[0].value == 3 && counts[1].value == 2) {
      final tripRank = counts[0].key;
      final pairRank = counts[1].key;
      return HandEvaluation(
        rank: HandRank.fullHouse,
        scoreVector: [7, tripRank, pairRank],
        description:
            'Full House, ${_rankLabelFromValue(tripRank)}s full of ${_rankLabelFromValue(pairRank)}s',
        bestFiveCards: sorted,
      );
    }

    // Flush
    if (isFlush) {
      return HandEvaluation(
        rank: HandRank.flush,
        scoreVector: [6, ...ranks],
        description: 'Flush, ${_rankLabelFromValue(ranks[0])} High',
        bestFiveCards: sorted,
      );
    }

    // Straight
    if (isStraight) {
      return HandEvaluation(
        rank: HandRank.straight,
        scoreVector: [5, straightTopRank],
        description: 'Straight, ${_rankLabelFromValue(straightTopRank)} High',
        bestFiveCards: sorted,
      );
    }

    // Three of a Kind
    if (counts[0].value == 3) {
      final tripRank = counts[0].key;
      final kickers = [counts[1].key, counts[2].key];
      return HandEvaluation(
        rank: HandRank.threeOfAKind,
        scoreVector: [4, tripRank, ...kickers],
        description: 'Three of a Kind, ${_rankLabelFromValue(tripRank)}s',
        bestFiveCards: sorted,
      );
    }

    // Two Pair
    if (counts[0].value == 2 && counts[1].value == 2) {
      final highPair = counts[0].key;
      final lowPair = counts[1].key;
      final kicker = counts[2].key;
      return HandEvaluation(
        rank: HandRank.twoPair,
        scoreVector: [3, highPair, lowPair, kicker],
        description:
            'Two Pair, ${_rankLabelFromValue(highPair)}s and ${_rankLabelFromValue(lowPair)}s',
        bestFiveCards: sorted,
      );
    }

    // One Pair
    if (counts[0].value == 2) {
      final pairRank = counts[0].key;
      final kickers = [counts[1].key, counts[2].key, counts[3].key];
      return HandEvaluation(
        rank: HandRank.onePair,
        scoreVector: [2, pairRank, ...kickers],
        description: 'One Pair of ${_rankLabelFromValue(pairRank)}s',
        bestFiveCards: sorted,
      );
    }

    // High Card
    return HandEvaluation(
      rank: HandRank.highCard,
      scoreVector: [1, ...ranks],
      description: 'High Card, ${_rankLabelFromValue(ranks[0])}',
      bestFiveCards: sorted,
    );
  }

  static String _rankLabelFromValue(int value) {
    switch (value) {
      case 14:
        return 'Ace';
      case 13:
        return 'King';
      case 12:
        return 'Queen';
      case 11:
        return 'Jack';
      case 10:
        return '10';
      default:
        return value.toString();
    }
  }
}
