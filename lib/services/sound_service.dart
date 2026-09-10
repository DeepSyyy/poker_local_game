import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service untuk memutar efek suara permainan poker (Deal, Flip, Win)
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool soundEnabled = true;
  AudioPlayer? _audioPlayer;
  bool _audioPlayerFailed = false;

  Future<AudioPlayer?> _getOrCreatePlayer() async {
    if (_audioPlayerFailed) return null;
    if (_audioPlayer != null) return _audioPlayer;

    try {
      // Return null in unit tests where Flutter binding is not bound to a binary messenger
      ServicesBinding.instance;
    } catch (_) {
      _audioPlayerFailed = true;
      return null;
    }

    try {
      final p = AudioPlayer();
      _audioPlayer = p;
      return p;
    } on MissingPluginException {
      _audioPlayerFailed = true;
      return null;
    } catch (e) {
      _audioPlayerFailed = true;
      return null;
    }
  }


  // Offline sound asset sources (.mp3 format for native macOS, iOS, Android, Web compatibility)
  static const String _dealAsset = 'sounds/card_deal.mp3';
  static const String _flipAsset = 'sounds/card_flip.mp3';
  static const String _winAsset = 'sounds/win_fanfare.mp3';

  /// Suara pembagian kartu (Deal Card)
  Future<void> playDealCard() async {
    if (!soundEnabled) return;
    try {
      await HapticFeedback.lightImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}

    try {
      final p = await _getOrCreatePlayer();
      await p?.play(AssetSource(_dealAsset), volume: 0.8);
    } on MissingPluginException {
      _audioPlayerFailed = true;
    } catch (_) {}
  }

  /// Suara pembukaan / balik kartu (Flip Card)
  Future<void> playFlipCard() async {
    if (!soundEnabled) return;
    try {
      await HapticFeedback.selectionClick();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}

    try {
      final p = await _getOrCreatePlayer();
      await p?.play(AssetSource(_flipAsset), volume: 0.9);
    } on MissingPluginException {
      _audioPlayerFailed = true;
    } catch (_) {}
  }

  /// Suara aksi taruhan / Raise / Bet / Call (Chip Sound)
  Future<void> playBet() async {
    if (!soundEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}

    try {
      final p = await _getOrCreatePlayer();
      await p?.play(AssetSource(_dealAsset), volume: 0.9);
    } on MissingPluginException {
      _audioPlayerFailed = true;
    } catch (_) {}
  }

  /// Suara khusus Raise
  Future<void> playRaise() async {
    await playBet();
  }

  /// Suara selebrasi kemenangan (Victory / Pot Awarded)
  Future<void> playWinFanfare() async {
    if (!soundEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    try {
      final p = await _getOrCreatePlayer();
      await p?.play(AssetSource(_winAsset), volume: 1.0);
    } on MissingPluginException {
      _audioPlayerFailed = true;
    } catch (_) {}
  }
}
