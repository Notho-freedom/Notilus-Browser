import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../services/settings_service.dart';
import '../../services/cloudinary_cache_service.dart';

/// Service pour gérer les vidéos de fond avec media_kit (ultra-robuste)
class VideoBackgroundService extends ChangeNotifier {
  static final VideoBackgroundService _instance = VideoBackgroundService._internal();
  factory VideoBackgroundService() {
    _instance._initialize();
    return _instance;
  }
  VideoBackgroundService._internal();

  final SettingsService _settings = SettingsService();
  Player? _player;
  VideoController? _controller;
  String? _currentVideoUrl;
  bool _isPlaying = false;
  bool _isMuted = false;
  double _volume = 1.0;
  bool _hasAudio = false; // Si la vidéo a du son activé
  StreamSubscription<bool>? _playingSubscription;

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  bool get hasAudio => _hasAudio;
  String? get currentVideoUrl => _currentVideoUrl;
  VideoController? get controller => _controller;

  void _initialize() {
    _settings.addListener(_onSettingsChanged);
    _loadVideo();
  }

  void _onSettingsChanged() {
    // Ne recharger que si les vidéos sélectionnées ont vraiment changé
    final selectedVideos = _settings.selectedVideos;
    final selectedBackgrounds = _settings.selectedBackgrounds;
    
    // Si une image est sélectionnée, arrêter la vidéo (les images ont la priorité)
    if (selectedBackgrounds.isNotEmpty) {
      if (_currentVideoUrl != null) {
        stop(); // Ne pas await ici car c'est une méthode synchrone
      }
      return;
    }
    
    // Si aucune image n'est sélectionnée, charger la vidéo si disponible
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final selectedVideos = _settings.selectedVideos;
    final selectedBackgrounds = _settings.selectedBackgrounds;
    
    // Si une image est sélectionnée, ne pas charger la vidéo (les images ont la priorité)
    if (selectedBackgrounds.isNotEmpty) {
      if (_currentVideoUrl != null) {
        await stop();
      }
      return;
    }
    
    // Utiliser la première vidéo sélectionnée
    final newVideoUrl = selectedVideos.isNotEmpty ? selectedVideos.first : null;
    
    // Si aucune vidéo n'est sélectionnée, arrêter la vidéo actuelle
    if (newVideoUrl == null) {
      if (_currentVideoUrl != null) {
        await stop();
      }
      return;
    }
    
    // Ne recharger que si l'URL a vraiment changé ou si le player n'existe pas
    if (newVideoUrl != _currentVideoUrl || _player == null) {
      // Si on passe d'une vidéo à une autre ou de vidéo à rien
      if (_currentVideoUrl != null && _currentVideoUrl != newVideoUrl) {
        await stop();
      }
      
      _currentVideoUrl = newVideoUrl;
      
      // Si une nouvelle vidéo est sélectionnée, la jouer
      if (newVideoUrl.isNotEmpty) {
        await play(newVideoUrl);
      }
      
      notifyListeners();
    }
  }

  Future<void> play(String url) async {
    try {
      // Réutiliser le player existant si disponible, sinon en créer un nouveau
      if (_player == null) {
        // Créer le player avec configuration optimisée
        _player = Player(
          configuration: const PlayerConfiguration(
            bufferSize: 500 * 1024 * 1024, // 500MB – anti freeze
          ),
        );
        
        _controller = VideoController(_player!);
        
        // #region agent log
        try {
          final logData = {
            'sessionId': 'debug-session',
            'runId': 'run3',
            'hypothesisId': 'E',
            'location': 'video_background_service.dart:109',
            'message': 'VideoController created',
            'data': {
              'url': url.length > 100 ? '${url.substring(0, 100)}...' : url,
              'controllerIsNull': _controller == null,
            },
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
          logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion

        // Annuler l'ancienne subscription si elle existe
        _playingSubscription?.cancel();
        
        // Écouter les changements d'état
        _playingSubscription = _player!.stream.playing.listen((playing) {
          _isPlaying = playing;
          // Si la lecture s'arrête inopinément, la reprendre (sauf si c'est un stop() explicite)
          if (!playing && _currentVideoUrl != null && _currentVideoUrl == url) {
            // Attendre un peu avant de reprendre (peut être une pause temporaire)
            Future.delayed(const Duration(seconds: 1), () {
              if (_player != null && _currentVideoUrl == url && !_isPlaying) {
                _player!.play();
              }
            });
          }
          notifyListeners();
        });
      } else {
        // Si le player existe déjà, juste arrêter la lecture actuelle
        try {
          await _player!.stop();
        } catch (e) {
          // Ignorer les erreurs si le player est déjà arrêté
        }
      }

      // Vérifier d'abord si la vidéo est en cache
      final cacheService = CloudinaryCacheService();
      await cacheService.initialize();
      final cachedFile = await cacheService.getCachedFile(url);
      
      // Utiliser le fichier en cache s'il existe, sinon utiliser l'URL
      final mediaSource = cachedFile != null 
          ? Media(cachedFile.path)
          : Media(url);
      
      // Ouvrir la vidéo
      await _player!.open(mediaSource, play: true);
      
      // Si pas en cache, démarrer le cache en arrière-plan
      if (cachedFile == null) {
        cacheService.cacheFileStreaming(
          url,
          onProgress: (progress) {
            if (progress >= 1.0) {
              debugPrint('✅ Vidéo de fond mise en cache: $url');
            }
          },
        );
      }
      
      // Configurer le volume et le mute (media_kit n'a pas setMuted, utiliser setVolume)
      await _player!.setVolume(_isMuted ? 0.0 : _volume);
      await _player!.setPlaylistMode(PlaylistMode.loop);
      
      _isPlaying = true;
      _hasAudio = !_isMuted && _volume > 0;
      _currentVideoUrl = url;
      
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run3',
          'hypothesisId': 'E',
          'location': 'video_background_service.dart:162',
          'message': 'Video play completed, notifying listeners',
          'data': {
            'url': url.length > 100 ? '${url.substring(0, 100)}...' : url,
            'controllerIsNull': _controller == null,
            'playerIsNull': _player == null,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
        logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      notifyListeners();
      debugPrint('✅ Vidéo de fond démarrée (media_kit): $url');
    } catch (e) {
      debugPrint('❌ Erreur lors de la lecture de la vidéo de fond: $e');
      // Nettoyer le player en cas d'erreur
      try {
        await _player?.dispose();
      } catch (_) {}
      _player = null;
      _controller = null;
      _isPlaying = false;
      _hasAudio = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    // Annuler la subscription avant de disposer le player
    _playingSubscription?.cancel();
    _playingSubscription = null;
    
    if (_player != null) {
      final playerToDispose = _player;
      _player = null;
      _controller = null;
      
      try {
        await playerToDispose!.stop();
      } catch (e) {
        // Le player peut déjà être arrêté ou disposé - ignorer silencieusement
        // Ne pas logger car c'est un comportement attendu
      }
      
      try {
        await playerToDispose?.dispose();
      } catch (e) {
        // Le player peut déjà être disposé automatiquement par media_kit - ignorer silencieusement
        // Ne pas logger car c'est un comportement attendu (assertion "[Player] has been disposed")
      }
    }
    _currentVideoUrl = null;
    _isPlaying = false;
    _hasAudio = false;
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_player != null) {
      await _player!.setVolume(_isMuted ? 0.0 : _volume);
      _hasAudio = !_isMuted && _volume > 0;
      notifyListeners();
    }
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    if (_player != null) {
      // media_kit n'a pas setMuted, utiliser setVolume
      await _player!.setVolume(muted ? 0.0 : _volume);
      _hasAudio = !muted && _volume > 0;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_player != null && _isPlaying) {
      await _player!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_player != null && !_isPlaying) {
      await _player!.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    // Annuler la subscription
    _playingSubscription?.cancel();
    _playingSubscription = null;
    stop();
    super.dispose();
  }
}
