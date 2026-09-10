import 'package:flutter_test/flutter_test.dart';
import 'package:poker_local_game/controllers/poker_game_controller.dart';
import 'package:poker_local_game/services/poker_server.dart';

void main() {
  group('PokerServer Tests', () {
    late PokerGameController controller;
    late PokerServer server;

    setUp(() {
      controller = PokerGameController();
      controller.initializeGame(
        playerNames: ['Alice', 'Bob'],
        initialChips: 1000,
        smallBlind: 10,
        bigBlind: 20,
        autoDealCards: true,
      );
      server = PokerServer(controller: controller, port: 8089);
    });

    tearDown(() async {
      await server.stop();
    });

    test('PokerServer starts and exposes local serverUrl', () async {
      await server.start();
      expect(server.isRunning, isTrue);
      expect(server.serverUrl, contains('http://'));
      expect(server.serverUrl, contains('8089'));
    });
  });
}
