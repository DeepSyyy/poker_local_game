import 'package:flutter_test/flutter_test.dart';
import 'package:poker_local_game/controllers/poker_game_controller.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/models/poker_game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PokerGameController Tests', () {
    late PokerGameController controller;

    setUp(() {
      controller = PokerGameController();
      controller.initializeGame(
        playerNames: ['Alice', 'Bob', 'Charlie'],
        initialChips: 1000,
        smallBlind: 10,
        bigBlind: 20,
        initialDealerIndex: 0,
        startImmediately: true,
      );
    });

    test('Initializes with blinds and correct turn for 3 players', () {
      // 3 players: Dealer=0(Alice), SB=1(Bob), BB=2(Charlie), UTG=0(Alice)
      expect(controller.players.length, 3);
      expect(controller.pot, 30); // 10 SB + 20 BB
      expect(controller.street, BettingStreet.preFlop);

      final bob = controller.players[1];
      final charlie = controller.players[2];
      expect(bob.chips, 990);
      expect(bob.currentRoundBet, 10);
      expect(charlie.chips, 980);
      expect(charlie.currentRoundBet, 20);

      // Alice is first to act (UTG in 3 players)
      expect(controller.currentTurnPlayer?.name, 'Alice');
      expect(controller.canCheck, false); // Current bet is 20, Alice bet 0
      expect(controller.callAmount, 20);
    });

    test('Pre-flop betting round flow: Call, Call, Check on BB', () {
      // Alice calls 20
      controller.call();
      expect(controller.players[0].chips, 980);
      expect(controller.players[0].currentRoundBet, 20);

      // Now Bob's turn (SB, has 10 in pot, needs 10 to call)
      expect(controller.currentTurnPlayer?.name, 'Bob');
      expect(controller.callAmount, 10);
      controller.call();
      expect(controller.players[1].chips, 980);

      // Now Charlie's turn (BB, already bet 20, can check!)
      expect(controller.currentTurnPlayer?.name, 'Charlie');
      expect(controller.canCheck, true);
      controller.check();

      // Betting round should be complete, advanced to Flop!
      expect(controller.street, BettingStreet.flop);
      expect(controller.pot, 60);
      expect(controller.currentBet, 0);
      expect(controller.players.every((p) => p.currentRoundBet == 0), true);
    });

    test('Folding until only 1 player remains awards pot automatically', () {
      // Alice folds
      controller.fold();
      expect(controller.players[0].status, PlayerStatus.folded);

      // Bob folds
      controller.fold();
      expect(controller.players[1].status, PlayerStatus.folded);

      // Charlie automatically wins pot
      expect(controller.street, BettingStreet.handEnded);
      expect(controller.pot, 0);
      expect(controller.players[2].chips, 1010); // 980 + 30 pot = 1010
    });

    test('Raise reopens action for other players', () {
      // Alice raises to 60
      controller.raiseTo(60);
      expect(controller.currentBet, 60);
      expect(controller.players[0].currentRoundBet, 60);
      expect(controller.players[0].chips, 940);

      // Bob folds
      controller.fold();

      // Charlie calls 60 (already had 20, pays 40 more)
      expect(controller.callAmount, 40);
      controller.call();

      // Round should advance to Flop
      expect(controller.street, BettingStreet.flop);
      expect(controller.pot, 130); // Alice 60 + Bob 10 + Charlie 60
    });

    test('All-in and Side Pot calculation', () {
      final potController = PokerGameController();
      potController.initializeGame(
        playerNames: ['P1', 'P2', 'P3'],
        initialChips: 100, // Small stack
        smallBlind: 10,
        bigBlind: 20,
        autoDealCards: true,
        initialDealerIndex: 0,
        startImmediately: true,
      );

      // Pre-flop: P1 all in (100)
      potController.allIn();
      expect(potController.players[0].status, PlayerStatus.allIn);
      expect(potController.currentBet, 100);

      // P2 calls all-in 100
      potController.call();
      expect(potController.players[1].status, PlayerStatus.allIn);

      // P3 calls all-in 100
      potController.call();
      expect(potController.players[2].status, PlayerStatus.allIn);

      // Everyone is All-In, bandar automatically deals remaining community cards and awards pot
      expect(potController.street, BettingStreet.handEnded);
      expect(potController.communityCards.length, 5);
      final totalChipsInPlay = potController.players.fold(
        0,
        (sum, p) => sum + p.chips,
      );
      expect(totalChipsInPlay, 300); // 300 total chips intact
    });
  });
}
