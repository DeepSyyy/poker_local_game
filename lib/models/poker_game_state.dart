enum BettingStreet {
  lobby,
  preFlop,
  flop,
  turn,
  river,
  showdown,
  handEnded;

  String get label {
    switch (this) {
      case BettingStreet.lobby:
        return 'Lobby (Menunggu Pemain)';
      case BettingStreet.preFlop:
        return 'Pre-Flop';
      case BettingStreet.flop:
        return 'Flop (3 Cards)';
      case BettingStreet.turn:
        return 'Turn (4th Card)';
      case BettingStreet.river:
        return 'River (5th Card)';
      case BettingStreet.showdown:
        return 'Showdown';
      case BettingStreet.handEnded:
        return 'Hand Ended';
    }
  }
}

class Pot {
  final String name;
  int amount;
  final List<String> eligiblePlayerIds;

  Pot({
    required this.name,
    required this.amount,
    required this.eligiblePlayerIds,
  });
}

enum ActionType { fold, check, call, raise, allIn, blind, win }

class PokerActionLog {
  final String playerName;
  final ActionType actionType;
  final String message;
  final DateTime timestamp;

  PokerActionLog({
    required this.playerName,
    required this.actionType,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
