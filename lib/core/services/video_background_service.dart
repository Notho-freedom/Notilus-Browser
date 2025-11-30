import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../services/settings_service.dart';
import '../../services/cloudinary_cache_service.dart';
import 'dart:io';

/// Service pour gérer les vidéos de fond
class VideoBackgroundService extends ChangeNotifier {
  static final VideoBackgroundService _instance = VideoBackgroundService._internal();
  factory VideoBackgroundService() {
    _instance._initialize();
    return _instance;
  }
  VideoBackgroundService._internal();

  final SettingsService _settings = SettingsService();
  VideoPlayerController? _videoController;
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
  VideoPlayerController? get controller => _videoController;

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
      
      final cacheService = CloudinaryCacheService();
      await cacheService.initialize();
      
      File? cachedFile = await cacheService.getCachedFile(url);
      
      if (cachedFile != null) {
        _videoController = VideoPlayerController.file(cachedFile);
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
        // Cache en arrière-plan
        cacheService.cacheFileStreaming(url, onProgress: (_) {});
      }
      
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(_isMuted ? 0.0 : _volume);
      
      _videoController!.addListener(_onVideoStateChanged);
      
      await _videoController!.play();
      _isPlaying = true;
      _hasAudio = !_isMuted && _volume > 0;
      
      notifyListeners();
      debugPrint('Vidéo de fond démarrée: $url');
    } catch (e) {
      debugPrint('Erreur lors de la lecture de la vidéo de fond: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  void _onVideoStateChanged() {
    if (_videoController != null) {
      final wasPlaying = _isPlaying;
      _isPlaying = _videoController!.value.isPlaying;
      
      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoStateChanged);
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }
    _isPlaying = false;
    _hasAudio = false;
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_videoController != null) {
      await _videoController!.setVolume(_isMuted ? 0.0 : _volume);
      _hasAudio = !_isMuted && _volume > 0;
      notifyListeners();
    }
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    if (_videoController != null) {
      await _videoController!.setVolume(muted ? 0.0 : _volume);
      _hasAudio = !muted && _volume > 0;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_videoController != null && _isPlaying) {
      await _videoController!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_videoController != null && !_isPlaying) {
      await _videoController!.play();
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

