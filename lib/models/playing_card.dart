import 'package:flutter/material.dart';

enum CardSuit {
  spades,
  hearts,
  diamonds,
  clubs;

  String get symbol {
    switch (this) {
      case CardSuit.spades:
        return '♠';
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
    }
  }

  String get nameLabel {
    switch (this) {
      case CardSuit.spades:
        return 'Spades';
      case CardSuit.hearts:
        return 'Hearts';
      case CardSuit.diamonds:
        return 'Diamonds';
      case CardSuit.clubs:
        return 'Clubs';
    }
  }

  Color get color {
    switch (this) {
      case CardSuit.spades:
      case CardSuit.clubs:
        return const Color(
          0xFF1E293B,
        ); // Dark slate blue-black for crisp visibility
      case CardSuit.hearts:
      case CardSuit.diamonds:
        return const Color(0xFFDC2626); // Vibrant Casino Red
    }
  }

  bool get isRed => this == CardSuit.hearts || this == CardSuit.diamonds;
}

enum CardRank {
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, '10'),
  jack(11, 'J'),
  queen(12, 'Q'),
  king(13, 'K'),
  ace(14, 'A');

  final int value;
  final String label;

  const CardRank(this.value, this.label);

  String get fullName {
    switch (this) {
      case CardRank.jack:
        return 'Jack';
      case CardRank.queen:
        return 'Queen';
      case CardRank.king:
        return 'King';
      case CardRank.ace:
        return 'Ace';
      default:
        return label;
    }
  }
}

class PlayingCard {
  final CardSuit suit;
  final CardRank rank;
  bool isFaceUp;

  PlayingCard({required this.suit, required this.rank, this.isFaceUp = true});

  String get name => '${rank.fullName} of ${suit.nameLabel}';
  String get shortCode => '${rank.label}${suit.symbol}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => shortCode;
}
