import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/settings_service.dart';

/// Service pour gérer la musique de fond
class BackgroundMusicService extends ChangeNotifier {
  static final BackgroundMusicService _instance = BackgroundMusicService._internal();
  factory BackgroundMusicService() {
    _instance._initialize();
    return _instance;
  }
  BackgroundMusicService._internal();

  final SettingsService _settings = SettingsService();
  AudioPlayer? _audioPlayer;
  String? _currentMusicUrl;
  bool _isPlaying = false;
  bool _isEnabled = true;

  bool get isPlaying => _isPlaying;
  bool get isEnabled => _isEnabled;
  String? get currentMusicUrl => _currentMusicUrl;

  void _initialize() {
    // Écouter les changements de paramètres
    _settings.addListener(_onSettingsChanged);
    
    // Charger la musique initiale
    _loadMusic();
  }

  void _onSettingsChanged() {
    _loadMusic();
  }

  Future<void> _loadMusic() async {
    final selectedMusic = _settings.selectedMusic;
    
    // Si la musique a changé ou n'est plus sélectionnée
    if (selectedMusic != _currentMusicUrl) {
      // Arrêter la musique actuelle
      await stop();
      
      _currentMusicUrl = selectedMusic;
      
      // Si une nouvelle musique est sélectionnée, la jouer
      if (selectedMusic != null && selectedMusic.isNotEmpty && _isEnabled) {
        await play(selectedMusic);
      }
      
      notifyListeners();
    }
  }

  Future<void> play(String url) async {
    try {
      // Arrêter la musique actuelle si elle existe
      await stop();
      
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setReleaseMode(ReleaseMode.loop); // Boucle infinie
      
      await _audioPlayer!.setSource(UrlSource(url));
      await _audioPlayer!.resume();
      
      _isPlaying = true;
      _currentMusicUrl = url;
      
      notifyListeners();
      
      debugPrint('Musique de fond démarrée: $url');
    } catch (e) {
      debugPrint('Erreur lors de la lecture de la musique de fond: $e');
      _isPlaying = false;
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
    _settings.removeListener(_onSettingsChanged);
    stop();
    super.dispose();
  }
}

