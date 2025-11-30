import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les effets sonores de l'application
class SoundEffectsService {
  static final SoundEffectsService _instance = SoundEffectsService._internal();
  factory SoundEffectsService() => _instance;
  SoundEffectsService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isEnabled = true;
  double _volume = 0.5;

  bool get isEnabled => _isEnabled;
  double get volume => _volume;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Joue un effet sonore
  Future<void> play(String assetPath, {double? volume}) async {
    if (!_isEnabled) return;

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.setVolume(volume ?? _volume);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Erreur lors de la lecture de l\'effet sonore $assetPath: $e');
    }
  }

  /// Pop dialog ouvert
  Future<void> playPopOpen() async {
    await play('soundeffects/tab_pop_open.wav');
  }

  /// Pop dialog fermé
  Future<void> playPopClose() async {
    await play('soundeffects/pop_close.wav');
  }

  /// Pop succès/info
  Future<void> playPopSuccess() async {
    await play('soundeffects/pop_succes_info.wav');
  }

  /// Pop erreur
  Future<void> playPopError() async {
    await play('soundeffects/pop_error.wav');
  }

  /// Notification générale
  Future<void> playNotify() async {
    await play('soundeffects/general notify.wav');
  }

  void dispose() {
    _player.dispose();
  }
}

