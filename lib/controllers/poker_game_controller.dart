import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/models/poker_game_state.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/models/deck.dart';
import 'package:poker_local_game/models/hand_evaluator.dart';
import 'package:poker_local_game/services/poker_server.dart';

class PokerGameController extends ChangeNotifier {
  List<PokerPlayer> _players = [];
  int _smallBlind = 10;
  int _bigBlind = 20;
  bool _blindsEnabled = true;
  bool _autoDealCards = true; // Default: Auto-deal virtual cards

  int _dealerIndex = 0;
  int _currentTurnIndex = 0;
  BettingStreet _street = BettingStreet.preFlop;

  int _currentBet = 0;
  int _lastRaiseSize = 0;
  int _pot = 0;
  final List<Pot> _pots = [];

  final List<PokerActionLog> _logs = [];

  // Card & Bandar System
  final Deck _deck = Deck();
  final List<PlayingCard> _communityCards = [];
  PokerServer? _server;
  Timer? _autoNextHandTimer;

  // Getters
  List<PokerPlayer> get players => _players;
  int get smallBlind => _smallBlind;
  int get bigBlind => _bigBlind;
  bool get blindsEnabled => _blindsEnabled;
  bool get autoDealCards => _autoDealCards;
  int get dealerIndex => _dealerIndex;
  int get currentTurnIndex => _currentTurnIndex;
  BettingStreet get street => _street;
  int get currentBet => _currentBet;
  int get lastRaiseSize => _lastRaiseSize;
  int get pot => _pot;
  List<Pot> get pots => _pots;
  List<PokerActionLog> get logs => List.unmodifiable(_logs.reversed);
  List<PlayingCard> get communityCards => List.unmodifiable(_communityCards);
  PokerServer? get server => _server;

  void startServer({int port = 8080}) {
    _server ??= PokerServer(controller: this, port: port);
    _server!.start();
  }

  void stopServer() {
    _server?.stop();
    _server = null;
  }

  void notifyStateChanged() {
    notifyListeners();
  }

  PokerPlayer? get currentTurnPlayer {
    if (_players.isEmpty ||
        _currentTurnIndex < 0 ||
        _currentTurnIndex >= _players.length) {
      return null;
    }
    return _players[_currentTurnIndex];
  }

  List<PokerPlayer> get activePlayers =>
      _players.where((p) => p.canAct).toList();
  List<PokerPlayer> get playersInHand =>
      _players.where((p) => p.isInHand).toList();

  /// Collect all cards currently picked by any player or on community board
  List<PlayingCard> get usedCards {
    final list = <PlayingCard>[..._communityCards];
    for (var p in _players) {
      list.addAll(p.holeCards);
    }
    return list;
  }

  /// Toggle antara mode kartu fisik manual dan auto-deal virtual
  void setAutoDealCards(bool enable) {
    _autoDealCards = enable;
    notifyListeners();
  }

  /// Set kartu saku pemain secara manual
  void setPlayerHoleCards(String playerId, List<PlayingCard> cards) {
    final player = _players.firstWhere((p) => p.id == playerId);
    player.holeCards = List.from(cards);
    _addLog(
      player.name,
      ActionType.check,
      'Input kartu saku manual: ${cards.map((c) => c.shortCode).join(' ')}',
    );
    notifyListeners();
  }

  /// Inisialisasi game baru dari Setup Screen
  void initializeGame({
    required List<String> playerNames,
    required int initialChips,
    required int smallBlind,
    required int bigBlind,
    bool blindsEnabled = true,
    bool autoDealCards = true,
    int? initialDealerIndex,
    bool startImmediately = false,
  }) {
    _smallBlind = smallBlind;
    _bigBlind = bigBlind;
    _blindsEnabled = blindsEnabled;
    _autoDealCards = autoDealCards;
    _logs.clear();

    final colors = [
      const Color(0xFFEF5350), // Red
      const Color(0xFF42A5F5), // Blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF26A69A), // Teal
      const Color(0xFFFF7043), // Deep Orange
      const Color(0xFF8D6E63), // Brown
    ];

    _players = List.generate(playerNames.length, (index) {
      return PokerPlayer(
        id: 'p_${index + 1}',
        name: playerNames[index].trim().isEmpty
            ? 'Player ${index + 1}'
            : playerNames[index].trim(),
        chips: initialChips,
        avatarColor: colors[index % colors.length],
      );
    });

    _dealerIndex = initialDealerIndex ?? Random().nextInt(_players.length);
    _street = BettingStreet.lobby;
    startServer();
    if (startImmediately) {
      _startHandInternal();
    }
    notifyListeners();
  }

  /// Memulai game dari Lobby setelah pemain terhubung
  void startGameFromLobby() {
    _startHandInternal();
    notifyListeners();
  }

  /// Mengecek apakah pemain sedang online (terhubung via HP/Web)
  bool isPlayerOnline(String playerId) {
    return _server?.connectedPlayerIds.contains(playerId) ?? false;
  }

  /// Memulai ronde hand baru
  void startNewHand() {
    _autoNextHandTimer?.cancel();
    _dealerIndex = _getNextActivePlayerIndex(_dealerIndex);
    _startHandInternal();
    notifyListeners();
  }

  void _scheduleAutoNextHand() {
    _autoNextHandTimer?.cancel();
    _autoNextHandTimer = Timer(const Duration(seconds: 4), () {
      if (_street == BettingStreet.handEnded) {
        startNewHand();
      }
    });
  }



  void _startHandInternal() {
    for (var p in _players) {
      p.resetForNewHand();
    }

    _pot = 0;
    _currentBet = 0;
    _lastRaiseSize = _bigBlind;
    _street = BettingStreet.preFlop;
    _pots.clear();
    _communityCards.clear();

    _deck.reset();

    final eligiblePlayers = _players
        .where((p) => p.status != PlayerStatus.out)
        .toList();
    if (eligiblePlayers.length < 2) {
      _addLog(
        'System',
        ActionType.blind,
        'Tidak cukup pemain untuk memulai hand.',
      );
      return;
    }

    _players[_dealerIndex].isDealer = true;

    // Jika mode autoDealCards aktif, bagikan 2 kartu saku virtual. Jika manual, biarkan kosong untuk kartu fisik.
    if (_autoDealCards) {
      for (var p in eligiblePlayers) {
        p.holeCards = [
          _deck.dealCard(isFaceUp: false),
          _deck.dealCard(isFaceUp: false),
        ];
      }
      _addLog(
        'Bandar',
        ActionType.check,
        'Mengocok dek dan membagikan 2 kartu saku virtual.',
      );
    } else {
      _addLog(
        'System',
        ActionType.check,
        'Pemain memegang kartu fisik masing-masing. Tap kursi untuk menginput kartu jika diperlukan.',
      );
    }

    if (_blindsEnabled) {
      if (eligiblePlayers.length == 2) {
        final sbIndex = _dealerIndex;
        final bbIndex = _getNextActivePlayerIndex(_dealerIndex);

        _players[sbIndex].isSmallBlind = true;
        _players[bbIndex].isBigBlind = true;

        _postBlind(_players[sbIndex], _smallBlind, 'Small Blind');
        _postBlind(_players[bbIndex], _bigBlind, 'Big Blind');

        _currentBet = _bigBlind;
        _lastRaiseSize = _bigBlind;
        _currentTurnIndex = sbIndex;
      } else {
        final sbIndex = _getNextActivePlayerIndex(_dealerIndex);
        final bbIndex = _getNextActivePlayerIndex(sbIndex);
        final utgIndex = _getNextActivePlayerIndex(bbIndex);

        _players[sbIndex].isSmallBlind = true;
        _players[bbIndex].isBigBlind = true;

        _postBlind(_players[sbIndex], _smallBlind, 'Small Blind');
        _postBlind(_players[bbIndex], _bigBlind, 'Big Blind');

        _currentBet = _bigBlind;
        _lastRaiseSize = _bigBlind;
        _currentTurnIndex = utgIndex;
      }
    } else {
      _currentBet = 0;
      _lastRaiseSize = _bigBlind;
      _currentTurnIndex = _getNextActivePlayerIndex(_dealerIndex);
    }

    _addLog(
      'System',
      ActionType.blind,
      'Hand baru dimulai. Dealer: ${_players[_dealerIndex].name}',
    );
    _calculatePots();
  }

  void _postBlind(PokerPlayer player, int amount, String label) {
    final pay = min(amount, player.chips);
    player.chips -= pay;
    player.currentRoundBet += pay;
    player.totalHandBet += pay;
    _pot += pay;

    if (player.chips == 0) {
      player.status = PlayerStatus.allIn;
    }

    _addLog(player.name, ActionType.blind, 'bayar $label: $pay chip');
  }

  // ======================
  // AKSI TARUHAN (ACTIONS)
  // ======================

  bool get canCheck {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return false;
    return p.currentRoundBet == _currentBet;
  }

  int get callAmount {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return 0;
    final diff = _currentBet - p.currentRoundBet;
    return min(diff, p.chips);
  }

  int get minRaiseAmount {
    final p = currentTurnPlayer;
    if (p == null) return _bigBlind;

    if (_currentBet == 0) {
      return min(_bigBlind, p.chips);
    }
    final minIncrement = max(_lastRaiseSize, _bigBlind);
    final target = _currentBet + minIncrement;
    return min(target, p.chips + p.currentRoundBet);
  }

  int get maxRaiseAmount {
    final p = currentTurnPlayer;
    if (p == null) return 0;
    return p.chips + p.currentRoundBet;
  }

  void fold() {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return;

    p.status = PlayerStatus.folded;
    _addLog(p.name, ActionType.fold, 'FOLD kartu');

    final remaining = playersInHand;
    if (remaining.length == 1) {
      _awardPotToSingleWinner(remaining.first);
      notifyListeners();
      return;
    }

    _advanceTurnOrStreet();
    notifyListeners();
  }

  void check() {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct || !canCheck) return;

    p.hasActedThisRound = true;
    _addLog(p.name, ActionType.check, 'CHECK');

    _advanceTurnOrStreet();
    notifyListeners();
  }

  void call() {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return;

    final pay = callAmount;
    p.chips -= pay;
    p.currentRoundBet += pay;
    p.totalHandBet += pay;
    _pot += pay;
    p.hasActedThisRound = true;

    if (p.chips == 0) {
      p.status = PlayerStatus.allIn;
      _addLog(p.name, ActionType.allIn, 'CALL ALL-IN $pay chip');
    } else {
      _addLog(p.name, ActionType.call, 'CALL $pay chip');
    }

    _advanceTurnOrStreet();
    notifyListeners();
  }

  void raiseTo(int totalTargetBet) {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return;

    final currentTotal = p.currentRoundBet + p.chips;
    final target = min(totalTargetBet, currentTotal);
    final additionalChips = target - p.currentRoundBet;

    if (additionalChips <= 0) return;

    final raiseSize = target - _currentBet;
    if (raiseSize > 0) {
      _lastRaiseSize = raiseSize;
      _currentBet = target;
      for (var other in _players) {
        if (other.id != p.id && other.canAct) {
          other.hasActedThisRound = false;
        }
      }
    }

    p.chips -= additionalChips;
    p.currentRoundBet += additionalChips;
    p.totalHandBet += additionalChips;
    _pot += additionalChips;
    p.hasActedThisRound = true;

    if (p.chips == 0) {
      p.status = PlayerStatus.allIn;
      _addLog(p.name, ActionType.allIn, 'RAISE ALL-IN ke $target');
    } else {
      _addLog(p.name, ActionType.raise, 'RAISE ke $target');
    }

    _advanceTurnOrStreet();
    notifyListeners();
  }

  void allIn() {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return;

    raiseTo(p.chips + p.currentRoundBet);
  }

  // ======================
  // LOGIKA GILIRAN & RONDE
  // ======================

  void _advanceTurnOrStreet() {
    _calculatePots();

    if (_isBettingRoundComplete()) {
      _advanceStreet();
    } else {
      _currentTurnIndex = _getNextTurnIndex(_currentTurnIndex);
    }
  }

  bool _isBettingRoundComplete() {
    final inHand = playersInHand;
    if (inHand.length <= 1) return true;

    final canStillAct = _players.where((p) => p.canAct).toList();

    if (canStillAct.isEmpty) return true;
    if (canStillAct.length == 1 &&
        canStillAct.first.hasActedThisRound &&
        canStillAct.first.currentRoundBet == _currentBet) {
      return true;
    }

    for (var p in canStillAct) {
      if (!p.hasActedThisRound || p.currentRoundBet != _currentBet) {
        return false;
      }
    }
    return true;
  }

  void _advanceStreet() {
    for (var p in _players) {
      p.resetForNewStreet();
    }
    _currentBet = 0;
    _lastRaiseSize = _bigBlind;

    final canStillAct = _players.where((p) => p.canAct).toList();

    if (_street == BettingStreet.preFlop) {
      _street = BettingStreet.flop;
      if (_autoDealCards) {
        while (_communityCards.length < 3) {
          _communityCards.add(_deck.dealCard(isFaceUp: true));
        }
      }
      _addLog('Table', ActionType.check, '--- FLOP (3 Kartu Meja) ---');
    } else if (_street == BettingStreet.flop) {
      _street = BettingStreet.turn;
      if (_autoDealCards) {
        if (_communityCards.length < 4) {
          _communityCards.add(_deck.dealCard(isFaceUp: true));
        }
      }
      _addLog('Table', ActionType.check, '--- TURN (Kartu ke-4) ---');
    } else if (_street == BettingStreet.turn) {
      _street = BettingStreet.river;
      if (_autoDealCards) {
        if (_communityCards.length < 5) {
          _communityCards.add(_deck.dealCard(isFaceUp: true));
        }
      }
      _addLog('Table', ActionType.check, '--- RIVER (Kartu ke-5) ---');
    } else if (_street == BettingStreet.river) {
      _street = BettingStreet.showdown;
      _addLog('Table', ActionType.check, '=== SHOWDOWN ===');
      _calculatePots();
      _tryAutoEvaluateShowdown();
      return;
    }

    if (canStillAct.length <= 1) {
      _addLog(
        'Table',
        ActionType.check,
        'Semua pemain All-In! Membuka sisa kartu meja...',
      );
      if (_autoDealCards) {
        while (_communityCards.length < 5) {
          _communityCards.add(_deck.dealCard(isFaceUp: true));
        }
      }
      _street = BettingStreet.showdown;
      _calculatePots();
      _tryAutoEvaluateShowdown();
      return;
    }

    _currentTurnIndex = _getNextActivePlayerIndex(_dealerIndex);
  }

  int _getNextActivePlayerIndex(int fromIndex) {
    if (_players.isEmpty) return 0;
    for (int i = 1; i <= _players.length; i++) {
      final next = (fromIndex + i) % _players.length;
      if (_players[next].status != PlayerStatus.out) {
        return next;
      }
    }
    return fromIndex;
  }

  int _getNextTurnIndex(int fromIndex) {
    if (_players.isEmpty) return 0;
    for (int i = 1; i <= _players.length; i++) {
      final next = (fromIndex + i) % _players.length;
      if (_players[next].canAct) {
        return next;
      }
    }
    return fromIndex;
  }

  // ======================
  // EVALUASI & POT
  // ======================

  void _calculatePots() {
    _pots.clear();
    final contributors = _players.where((p) => p.totalHandBet > 0).toList();
    if (contributors.isEmpty) return;

    final betLevels = contributors.map((p) => p.totalHandBet).toSet().toList()
      ..sort();

    int prevLevel = 0;
    int potCounter = 1;

    for (var level in betLevels) {
      final potDelta = level - prevLevel;
      if (potDelta <= 0) continue;

      int potAmount = 0;
      final eligiblePlayerIds = <String>[];

      for (var p in contributors) {
        if (p.totalHandBet >= level) {
          potAmount += potDelta;
          if (p.status != PlayerStatus.folded) {
            eligiblePlayerIds.add(p.id);
          }
        } else if (p.totalHandBet > prevLevel) {
          potAmount += (p.totalHandBet - prevLevel);
        }
      }

      if (potAmount > 0 && eligiblePlayerIds.isNotEmpty) {
        final potName = _pots.isEmpty ? 'Main Pot' : 'Side Pot ${potCounter++}';
        _pots.add(
          Pot(
            name: potName,
            amount: potAmount,
            eligiblePlayerIds: eligiblePlayerIds,
          ),
        );
      }
      prevLevel = level;
    }
  }

  void _tryAutoEvaluateShowdown() {
    // Evaluasi jika semua pemain di hand memiliki 2 kartu saku dan ada 5 kartu meja
    final activeInHand = _players.where((p) => p.isInHand).toList();
    final allHaveCards = activeInHand.every((p) => p.holeCards.length == 2);

    if (allHaveCards &&
        _communityCards.length == 5 &&
        activeInHand.isNotEmpty) {
      for (var p in activeInHand) {
        final all7 = [...p.holeCards, ..._communityCards];
        p.evaluation = HandEvaluator.evaluate(all7);
        p.holeCards.forEach((c) => c.isFaceUp = true);
      }

      final potList = List<Pot>.from(_pots);
      for (var currentPot in potList) {
        final eligible = _players
            .where(
              (p) =>
                  currentPot.eligiblePlayerIds.contains(p.id) &&
                  p.evaluation != null,
            )
            .toList();
        if (eligible.isEmpty) continue;

        eligible.sort((a, b) => b.evaluation!.compareTo(a.evaluation!));
        final bestEval = eligible.first.evaluation!;

        final winners = eligible
            .where((p) => p.evaluation!.compareTo(bestEval) == 0)
            .toList();
        awardPot(
          currentPot,
          winners.map((w) => w.id).toList(),
          isAutoShowdown: true,
        );
      }
    }
  }

  void _awardPotToSingleWinner(PokerPlayer winner) {
    winner.chips += _pot;
    _addLog(winner.name, ActionType.win, 'Menang pot $_pot chip (lawan fold)!');
    _pot = 0;
    _pots.clear();
    _street = BettingStreet.handEnded;
    _scheduleAutoNextHand();
  }

  void awardPot(
    Pot pot,
    List<String> winnerIds, {
    bool isAutoShowdown = false,
  }) {
    if (winnerIds.isEmpty) return;

    final share = pot.amount ~/ winnerIds.length;
    int remainder = pot.amount % winnerIds.length;

    final winnerNames = <String>[];
    for (var id in winnerIds) {
      final winner = _players.firstWhere((p) => p.id == id);
      winner.chips += share;
      if (remainder > 0) {
        winner.chips += 1;
        remainder--;
      }
      final evalDesc = winner.evaluation != null
          ? ' (${winner.evaluation!.description})'
          : '';
      winnerNames.add('${winner.name}$evalDesc');
    }

    _addLog(
      winnerNames.join(', '),
      ActionType.win,
      'Menang ${pot.name} sebesar ${pot.amount} chip!',
    );

    _pot -= pot.amount;
    if (_pot < 0) _pot = 0;
    _pots.removeWhere((p) => p.name == pot.name);

    if (_pots.isEmpty || _pot == 0) {
      _street = BettingStreet.handEnded;
    }

    notifyListeners();
  }

  void addChipsToPlayer(String playerId, int amount) {
    final player = _players.firstWhere((p) => p.id == playerId);
    player.chips += amount;
    if (player.status == PlayerStatus.out && player.chips > 0) {
      player.status = PlayerStatus.active;
    }
    _addLog(
      player.name,
      ActionType.blind,
      'Top-up/Rebuy +$amount chip (Total: ${player.chips})',
    );
    notifyListeners();
  }

  void _addLog(String playerName, ActionType actionType, String message) {
    _logs.add(
      PokerActionLog(
        playerName: playerName,
        actionType: actionType,
        message: message,
      ),
    );
  }
}
