import 'dart:math';
import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/poker_player.dart';
import 'package:belajar_flutter/models/poker_game_state.dart';

class PokerGameController extends ChangeNotifier {
  List<PokerPlayer> _players = [];
  int _smallBlind = 10;
  int _bigBlind = 20;
  bool _blindsEnabled = true;

  int _dealerIndex = 0;
  int _currentTurnIndex = 0;
  BettingStreet _street = BettingStreet.preFlop;

  int _currentBet = 0;
  int _lastRaiseSize = 0;
  int _pot = 0;
  final List<Pot> _pots = [];

  final List<PokerActionLog> _logs = [];

  // Getters
  List<PokerPlayer> get players => _players;
  int get smallBlind => _smallBlind;
  int get bigBlind => _bigBlind;
  bool get blindsEnabled => _blindsEnabled;
  int get dealerIndex => _dealerIndex;
  int get currentTurnIndex => _currentTurnIndex;
  BettingStreet get street => _street;
  int get currentBet => _currentBet;
  int get lastRaiseSize => _lastRaiseSize;
  int get pot => _pot;
  List<Pot> get pots => _pots;
  List<PokerActionLog> get logs => List.unmodifiable(_logs.reversed);

  PokerPlayer? get currentTurnPlayer {
    if (_players.isEmpty || _currentTurnIndex < 0 || _currentTurnIndex >= _players.length) {
      return null;
    }
    return _players[_currentTurnIndex];
  }

  List<PokerPlayer> get activePlayers => _players.where((p) => p.canAct).toList();
  List<PokerPlayer> get playersInHand => _players.where((p) => p.isInHand).toList();

  /// Inisialisasi game baru dari Setup Screen
  void initializeGame({
    required List<String> playerNames,
    required int initialChips,
    required int smallBlind,
    required int bigBlind,
    bool blindsEnabled = true,
  }) {
    _smallBlind = smallBlind;
    _bigBlind = bigBlind;
    _blindsEnabled = blindsEnabled;
    _logs.clear();

    final colors = [
      const Color(0xFFEF5350), // Red
      const Color(0xFF42A5F5), // Blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF26C6DA), // Cyan
      const Color(0xFFFFEE58), // Yellow
      const Color(0xFFEC407A), // Pink
    ];

    _players = List.generate(playerNames.length, (index) {
      return PokerPlayer(
        id: 'p_$index',
        name: playerNames[index].trim().isEmpty ? 'Player ${index + 1}' : playerNames[index].trim(),
        chips: initialChips,
        avatarColor: colors[index % colors.length],
      );
    });

    _dealerIndex = 0;
    _startHandInternal();
    notifyListeners();
  }

  /// Memulai ronde hand baru
  void startNewHand() {
    // Pindahkan Dealer ke pemain berikutnya yang masih punya chip
    _dealerIndex = _getNextActivePlayerIndex(_dealerIndex);
    _startHandInternal();
    notifyListeners();
  }

  void _startHandInternal() {
    // Reset status tiap pemain
    for (var p in _players) {
      p.resetForNewHand();
    }

    _pot = 0;
    _currentBet = 0;
    _lastRaiseSize = _bigBlind;
    _street = BettingStreet.preFlop;
    _pots.clear();

    final eligiblePlayers = _players.where((p) => p.status != PlayerStatus.out).toList();
    if (eligiblePlayers.length < 2) {
      _addLog('System', ActionType.blind, 'Tidak cukup pemain untuk memulai hand.');
      return;
    }

    // Tentukan posisi Dealer
    _players[_dealerIndex].isDealer = true;

    if (_blindsEnabled) {
      if (eligiblePlayers.length == 2) {
        // Heads-up: Dealer is Small Blind, other player is Big Blind
        final sbIndex = _dealerIndex;
        final bbIndex = _getNextActivePlayerIndex(_dealerIndex);

        _players[sbIndex].isSmallBlind = true;
        _players[bbIndex].isBigBlind = true;

        _postBlind(_players[sbIndex], _smallBlind, 'Small Blind');
        _postBlind(_players[bbIndex], _bigBlind, 'Big Blind');

        _currentBet = _bigBlind;
        _lastRaiseSize = _bigBlind;

        // Pre-flop heads up: Dealer (SB) jalan pertama
        _currentTurnIndex = sbIndex;
      } else {
        // 3+ Players
        final sbIndex = _getNextActivePlayerIndex(_dealerIndex);
        final bbIndex = _getNextActivePlayerIndex(sbIndex);
        final utgIndex = _getNextActivePlayerIndex(bbIndex);

        _players[sbIndex].isSmallBlind = true;
        _players[bbIndex].isBigBlind = true;

        _postBlind(_players[sbIndex], _smallBlind, 'Small Blind');
        _postBlind(_players[bbIndex], _bigBlind, 'Big Blind');

        _currentBet = _bigBlind;
        _lastRaiseSize = _bigBlind;

        // Pre-flop: UTG jalan pertama
        _currentTurnIndex = utgIndex;
      }
    } else {
      // Tanpa blind: mulai dari sebelah kiri dealer
      _currentBet = 0;
      _lastRaiseSize = _bigBlind;
      _currentTurnIndex = _getNextActivePlayerIndex(_dealerIndex);
    }

    _addLog('System', ActionType.blind, 'Hand baru dimulai. Dealer: ${_players[_dealerIndex].name}');
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

  /// Apakah pemain aktif saat ini bisa Check?
  bool get canCheck {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return false;
    return p.currentRoundBet == _currentBet;
  }

  /// Berapa chip yang dibutuhkan untuk Call?
  int get callAmount {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return 0;
    final diff = _currentBet - p.currentRoundBet;
    return min(diff, p.chips);
  }

  /// Minimum Raise to amount (total bet di ronde ini)
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

  /// Maksimum Raise to amount (All-in)
  int get maxRaiseAmount {
    final p = currentTurnPlayer;
    if (p == null) return 0;
    return p.chips + p.currentRoundBet;
  }

  /// Aksi: Fold
  void fold() {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct) return;

    p.status = PlayerStatus.folded;
    _addLog(p.name, ActionType.fold, 'FOLD kartu');

    // Cek jika hanya tersisa 1 pemain aktif di hand
    final remaining = playersInHand;
    if (remaining.length == 1) {
      _awardPotToSingleWinner(remaining.first);
      notifyListeners();
      return;
    }

    _advanceTurnOrStreet();
    notifyListeners();
  }

  /// Aksi: Check
  void check() {
    final p = currentTurnPlayer;
    if (p == null || !p.canAct || !canCheck) return;

    p.hasActedThisRound = true;
    _addLog(p.name, ActionType.check, 'CHECK');

    _advanceTurnOrStreet();
    notifyListeners();
  }

  /// Aksi: Call
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

  /// Aksi: Raise ke jumlah tertentu (total bet ronde ini)
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
      // Kenaikan taruhan membuka kembali giliran untuk pemain lain
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

  /// Aksi: All-In
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

    // Cek apakah betting round ini sudah selesai
    if (_isBettingRoundComplete()) {
      _advanceStreet();
    } else {
      _currentTurnIndex = _getNextTurnIndex(_currentTurnIndex);
    }
  }

  bool _isBettingRoundComplete() {
    final inHand = playersInHand;
    if (inHand.length <= 1) return true;

    // Pemain yang masih bisa beraksi (tidak all-in, tidak fold)
    final canStillAct = _players.where((p) => p.canAct).toList();

    // Jika 0 atau 1 pemain yang masih bisa bet, dan pemain tersebut sudah menyamakan currentBet
    if (canStillAct.isEmpty) return true;
    if (canStillAct.length == 1 && canStillAct.first.hasActedThisRound && canStillAct.first.currentRoundBet == _currentBet) {
      return true;
    }

    // Ronde selesai jika semua pemain yang canAct sudah bertindak dan taruhannya sama dengan currentBet
    for (var p in canStillAct) {
      if (!p.hasActedThisRound || p.currentRoundBet != _currentBet) {
        return false;
      }
    }
    return true;
  }

  void _advanceStreet() {
    // Reset round bets
    for (var p in _players) {
      p.resetForNewStreet();
    }
    _currentBet = 0;
    _lastRaiseSize = _bigBlind;

    // Cek berapa pemain yang masih bisa bertaruh
    final canStillAct = _players.where((p) => p.canAct).toList();

    if (_street == BettingStreet.preFlop) {
      _street = BettingStreet.flop;
      _addLog('Table', ActionType.check, '--- FLOP (3 Kartu Meja) ---');
    } else if (_street == BettingStreet.flop) {
      _street = BettingStreet.turn;
      _addLog('Table', ActionType.check, '--- TURN (Kartu ke-4) ---');
    } else if (_street == BettingStreet.turn) {
      _street = BettingStreet.river;
      _addLog('Table', ActionType.check, '--- RIVER (Kartu ke-5) ---');
    } else if (_street == BettingStreet.river) {
      _street = BettingStreet.showdown;
      _addLog('Table', ActionType.check, '=== SHOWDOWN ===');
      _calculatePots();
      return;
    }

    // Jika tidak ada pemain yang bisa bertaruh lagi (semua all-in atau all-in kecuali 1),
    // kita bisa langsung lompat ke showdown bertahap atau langsung ke showdown
    if (canStillAct.length <= 1) {
      _addLog('Table', ActionType.check, 'Semua pemain All-In, langsung ke Showdown.');
      _street = BettingStreet.showdown;
      _calculatePots();
      return;
    }

    // Posisi pertama jalan post-flop: pemain aktif pertama sebelah kiri Dealer
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
  // PERHITUNGAN POT & SIDE POT
  // ======================

  void _calculatePots() {
    _pots.clear();
    final contributors = _players.where((p) => p.totalHandBet > 0).toList();
    if (contributors.isEmpty) return;

    // Dapatkan semua level taruhan unik dari pemain
    final betLevels = contributors.map((p) => p.totalHandBet).toSet().toList()..sort();

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
        _pots.add(Pot(
          name: potName,
          amount: potAmount,
          eligiblePlayerIds: eligiblePlayerIds,
        ));
      }
      prevLevel = level;
    }
  }

  // ======================
  // PEMBAGIAN POT (WINNERS)
  // ======================

  void _awardPotToSingleWinner(PokerPlayer winner) {
    winner.chips += _pot;
    _addLog(winner.name, ActionType.win, 'Menang pot $_pot chip (lawan fold)!');
    _pot = 0;
    _pots.clear();
    _street = BettingStreet.handEnded;
  }

  /// Bagikan Pot tertentu (Main Pot atau Side Pot) ke pemenang terpilih (bisa split)
  void awardPot(Pot pot, List<String> winnerIds) {
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
      winnerNames.add(winner.name);
    }

    _addLog(
      winnerNames.join(', '),
      ActionType.win,
      'Mendapatkan ${pot.name} sebesar ${pot.amount} chip!',
    );

    _pot -= pot.amount;
    if (_pot < 0) _pot = 0;
    _pots.removeWhere((p) => p.name == pot.name);

    if (_pots.isEmpty || _pot == 0) {
      _street = BettingStreet.handEnded;
    }

    notifyListeners();
  }

  // ======================
  // REBUY / TOP UP
  // ======================

  void addChipsToPlayer(String playerId, int amount) {
    final player = _players.firstWhere((p) => p.id == playerId);
    player.chips += amount;
    if (player.status == PlayerStatus.out && player.chips > 0) {
      player.status = PlayerStatus.active;
    }
    _addLog(player.name, ActionType.blind, 'Top-up/Rebuy +$amount chip (Total: ${player.chips})');
    notifyListeners();
  }

  void _addLog(String playerName, ActionType actionType, String message) {
    _logs.add(PokerActionLog(
      playerName: playerName,
      actionType: actionType,
      message: message,
    ));
  }
}
