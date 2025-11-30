import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/settings_service.dart';
import 'video_background_service.dart';

/// Service pour gérer la musique de fond
class BackgroundMusicService extends ChangeNotifier with WidgetsBindingObserver {
  static final BackgroundMusicService _instance = BackgroundMusicService._internal();
  factory BackgroundMusicService() {
    _instance._initialize();
    return _instance;
  }
  BackgroundMusicService._internal();

  final SettingsService _settings = SettingsService();
  final VideoBackgroundService _videoService = VideoBackgroundService();
  AudioPlayer? _audioPlayer;
  String? _currentMusicUrl;
  bool _isPlaying = false;
  bool _isEnabled = true;
  double _volume = 1.0;
  bool _isAppInForeground = true;
  Timer? _fadeTimer;

  bool get isPlaying => _isPlaying;
  bool get isEnabled => _isEnabled;
  String? get currentMusicUrl => _currentMusicUrl;
  double get volume => _volume;

  void _initialize() {
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_onSettingsChanged);
    _videoService.addListener(_onVideoChanged);
    _loadMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    
    if (_isAppInForeground) {
      _fadeIn();
    } else {
      _fadeOut();
    }
  }

  void _onVideoChanged() {
    // Si la vidéo a du son activé, ne pas jouer la musique de fond
    if (_videoService.hasAudio && _isPlaying) {
      pause();
    } else if (!_videoService.hasAudio && _currentMusicUrl != null && _isEnabled && !_isPlaying) {
      resume();
    }
  }

  void _onSettingsChanged() {
    _loadMusic();
  }

  Future<void> _loadMusic() async {
    final selectedMusic = _settings.selectedMusic;
    
    // Ne pas charger la musique si la vidéo a du son
    if (_videoService.hasAudio) {
      return;
    }
    
    // Si la musique a changé ou n'est plus sélectionnée
    if (selectedMusic != _currentMusicUrl) {
      // Arrêter la musique actuelle
      await stop();
      
      _currentMusicUrl = selectedMusic;
      
      // Si une nouvelle musique est sélectionnée, la jouer
      if (selectedMusic != null && selectedMusic.isNotEmpty && _isEnabled && !_videoService.hasAudio) {
        await play(selectedMusic);
      }
      
      notifyListeners();
    }
  }

  Future<void> _fadeIn() async {
    if (_audioPlayer != null && _currentMusicUrl != null && _isEnabled && !_videoService.hasAudio) {
      _fadeTimer?.cancel();
      const steps = 20;
      const duration = Duration(milliseconds: 500);
      final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
      
      for (int i = 0; i <= steps; i++) {
        await Future.delayed(stepDuration);
        if (_audioPlayer != null) {
          final targetVolume = (_volume * (i / steps)).clamp(0.0, _volume);
          await _audioPlayer!.setVolume(targetVolume);
        }
      }
      
      if (_audioPlayer != null && !_isPlaying) {
        await _audioPlayer!.resume();
        _isPlaying = true;
        notifyListeners();
      }
    }
  }

  Future<void> _fadeOut() async {
    if (_audioPlayer != null && _isPlaying) {
      _fadeTimer?.cancel();
      const steps = 20;
      const duration = Duration(milliseconds: 500);
      final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
      final startVolume = _audioPlayer!.volume;
      
      for (int i = steps; i >= 0; i--) {
        await Future.delayed(stepDuration);
        if (_audioPlayer != null) {
          final targetVolume = (startVolume * (i / steps)).clamp(0.0, startVolume);
          await _audioPlayer!.setVolume(targetVolume);
        }
      }
      
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> play(String url) async {
    // Ne pas jouer si la vidéo a du son
    if (_videoService.hasAudio) {
      return;
    }
    
    try {
      // Arrêter la musique actuelle si elle existe
      await stop();
      
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setReleaseMode(ReleaseMode.loop); // Boucle infinie
      _audioPlayer!.setVolume(_isAppInForeground ? _volume : 0.0);
      
      await _audioPlayer!.setSource(UrlSource(url));
      
      if (_isAppInForeground) {
        await _audioPlayer!.resume();
        _isPlaying = true;
      }
      
      _currentMusicUrl = url;
      
      notifyListeners();
      
      debugPrint('Musique de fond démarrée: $url');
    } catch (e) {
      debugPrint('Erreur lors de la lecture de la musique de fond: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }
  
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_isAppInForeground ? _volume : 0.0);
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    }
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> pause() async {
    if (_audioPlayer != null && _isPlaying) {
      await _audioPlayer!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_audioPlayer != null && !_isPlaying && _isEnabled) {
      await _audioPlayer!.resume();
      _isPlaying = true;
      notifyListeners();
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      pause();
    } else if (_currentMusicUrl != null) {
      play(_currentMusicUrl!);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _videoService.removeListener(_onVideoChanged);
    _fadeTimer?.cancel();
    stop();
    super.dispose();
  }
}

