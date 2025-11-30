import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../services/settings_service.dart';
import '../../services/cloudinary_cache_service.dart';
import 'dart:io' show Platform, File;

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
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final selectedVideos = _settings.selectedVideos;
    
    // Utiliser la première vidéo sélectionnée
    final newVideoUrl = selectedVideos.isNotEmpty ? selectedVideos.first : null;
    
    if (newVideoUrl != _currentVideoUrl) {
      await stop();
      _currentVideoUrl = newVideoUrl;
      
      if (newVideoUrl != null && newVideoUrl.isNotEmpty) {
        await play(newVideoUrl);
      }
      
      notifyListeners();
    }
  }

  Future<void> play(String url) async {
    try {
      await stop();
      
      // Créer le player avec configuration optimisée
      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 500 * 1024 * 1024, // 500MB – anti freeze
        ),
      );
      
      _controller = VideoController(_player!);

      // Écouter les changements d'état
      _player!.stream.playing.listen((playing) {
        _isPlaying = playing;
        notifyListeners();
      });

      // Ouvrir la vidéo
      await _player!.open(Media(url), play: true);
      
      // Configurer le volume et le mute (media_kit n'a pas setMuted, utiliser setVolume)
      await _player!.setVolume(_isMuted ? 0.0 : _volume);
      await _player!.setPlaylistMode(PlaylistMode.loop);
      
      _isPlaying = true;
      _hasAudio = !_isMuted && _volume > 0;
      _currentVideoUrl = url;
      
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
    if (_player != null) {
      await _player!.stop();
      await _player!.dispose();
      _player = null;
      _controller = null;
    }
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
    stop();
    super.dispose();
  }
}
