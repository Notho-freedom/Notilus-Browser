import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les effets sonores de l'application
class SoundEffectsService {
  static final SoundEffectsService _instance = SoundEffectsService._internal();
  factory SoundEffectsService() => _instance;
  SoundEffectsService._internal();

  final Map<String, List<AudioPlayer>> _playerPools = {};
  final Map<String, int> _playerIndex = {};
  bool _isEnabled = true;
  double _volume = 0.5;
  final int _poolSize = 3; // Nombre de players par fichier

  bool get isEnabled => _isEnabled;
  double get volume => _volume;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Initialise une pool de players pour un fichier audio
  Future<void> _initializePool(String assetPath) async {
    if (_playerPools.containsKey(assetPath)) {
      return;
    }

    final players = <AudioPlayer>[];
    
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_volume);
        players.add(player);
      } catch (e) {
        debugPrint('Erreur d\'initialisation du player $i pour $assetPath: $e');
        await player.dispose();
      }
    }
    
    if (players.isNotEmpty) {
      _playerPools[assetPath] = players;
      _playerIndex[assetPath] = 0;
    }
  }

  /// Nettoie une pool de players
  Future<void> _cleanupPool(String assetPath) async {
    final players = _playerPools[assetPath];
    if (players != null) {
      for (final player in players) {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {
          // Ignorer les erreurs
        }
      }
      _playerPools.remove(assetPath);
      _playerIndex.remove(assetPath);
    }
  }

  /// Obtient le prochain player disponible dans la pool (round-robin)
  AudioPlayer? _getNextPlayer(String assetPath) {
    final players = _playerPools[assetPath];
    if (players == null || players.isEmpty) return null;
    
    final currentIndex = _playerIndex[assetPath] ?? 0;
    final player = players[currentIndex];
    
    // Mettre à jour l'index pour la prochaine fois
    final nextIndex = (currentIndex + 1) % players.length;
    _playerIndex[assetPath] = nextIndex;
    
    return player;
  }

  /// Joue un effet sonore
  Future<void> play(String assetPath, {double? volume}) async {
    if (!_isEnabled) return;

    try {
      // Initialiser la pool si nécessaire
      await _initializePool(assetPath);
      
      final player = _getNextPlayer(assetPath);
      if (player == null) {
        debugPrint('Aucun player disponible pour $assetPath');
        return;
      }

      // Vérifier l'état du player
      final state = player.state;
      if (state == PlayerState.playing) {
        // Si le player est en cours, on arrête et on attend un peu
        try {
          await player.stop();
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (_) {
          // Ignorer
        }
      }

      // Configurer le volume
      if (volume != null) {
        await player.setVolume(volume);
      }

      // Jouer le son
      await player.play(AssetSource(assetPath));

      // Réinitialiser le volume après la lecture
      if (volume != null) {
        await Future.delayed(const Duration(milliseconds: 10));
        await player.setVolume(_volume);
      }

    } catch (e) {
      debugPrint('Erreur lors de la lecture de $assetPath: $e');
      
      // En cas d'erreur, nettoyer la pool et réessayer plus tard
      await _cleanupPool(assetPath);
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

  /// Arrête tous les sons
  Future<void> stopAll() async {
    for (final players in _playerPools.values) {
      for (final player in players) {
        try {
          await player.stop();
        } catch (_) {
          // Ignorer
        }
      }
    }
  }

  Future<void> dispose() async {
    // Nettoyer toutes les pools
    for (final assetPath in _playerPools.keys.toList()) {
      await _cleanupPool(assetPath);
    }
    _playerPools.clear();
    _playerIndex.clear();
  }
}
