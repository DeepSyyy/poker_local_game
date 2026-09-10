import 'package:flutter/material.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/models/hand_evaluator.dart';

enum PlayerStatus {
  active,
  folded,
  allIn,
  out, // Kehabisan chip dan tidak rebuy
}

class PokerPlayer {
  final String id;
  String name;
  int chips;
  int currentRoundBet;
  int totalHandBet;
  PlayerStatus status;
  bool isDealer;
  bool isSmallBlind;
  bool isBigBlind;
  bool hasActedThisRound;
  final Color avatarColor;
  List<PlayingCard> holeCards;
  HandEvaluation? evaluation;

  PokerPlayer({
    required this.id,
    required this.name,
    required this.chips,
    this.currentRoundBet = 0,
    this.totalHandBet = 0,
    this.status = PlayerStatus.active,
    this.isDealer = false,
    this.isSmallBlind = false,
    this.isBigBlind = false,
    this.hasActedThisRound = false,
    required this.avatarColor,
    List<PlayingCard>? holeCards,
    this.evaluation,
  }) : holeCards = holeCards ?? [];

  bool get canAct => status == PlayerStatus.active && chips > 0;
  bool get isInHand =>
      status != PlayerStatus.folded && status != PlayerStatus.out;

  void resetForNewStreet() {
    currentRoundBet = 0;
    hasActedThisRound = false;
  }

  void resetForNewHand() {
    currentRoundBet = 0;
    totalHandBet = 0;
    hasActedThisRound = false;
    isDealer = false;
    isSmallBlind = false;
    isBigBlind = false;
    holeCards.clear();
    evaluation = null;
    if (chips > 0) {
      status = PlayerStatus.active;
    } else {
      status = PlayerStatus.out;
    }
  }

  PokerPlayer copyWith({
    String? id,
    String? name,
    int? chips,
    int? currentRoundBet,
    int? totalHandBet,
    PlayerStatus? status,
    bool? isDealer,
    bool? isSmallBlind,
    bool? isBigBlind,
    bool? hasActedThisRound,
    Color? avatarColor,
    List<PlayingCard>? holeCards,
    HandEvaluation? evaluation,
  }) {
    return PokerPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      chips: chips ?? this.chips,
      currentRoundBet: currentRoundBet ?? this.currentRoundBet,
      totalHandBet: totalHandBet ?? this.totalHandBet,
      status: status ?? this.status,
      isDealer: isDealer ?? this.isDealer,
      isSmallBlind: isSmallBlind ?? this.isSmallBlind,
      isBigBlind: isBigBlind ?? this.isBigBlind,
      hasActedThisRound: hasActedThisRound ?? this.hasActedThisRound,
      avatarColor: avatarColor ?? this.avatarColor,
      holeCards: holeCards ?? List.from(this.holeCards),
      evaluation: evaluation ?? this.evaluation,
    );
  }
}
