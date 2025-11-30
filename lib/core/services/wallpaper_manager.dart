import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/wallpapers.dart';
import '../../services/settings_service.dart';

/// Type de wallpaper
enum WallpaperType {
  image,
  video,
}

/// Source du wallpaper
enum WallpaperSource {
  default_,
  cloudinary,
}

/// Gestionnaire global du fond d'écran (même wallpaper pour toutes les vues,
/// avec rotation automatique dans le temps et cache).
class WallpaperManager extends ChangeNotifier {
  final List<String> _defaultWallpapers = [];
  final List<String> _cloudinaryImages = [];
  final List<String> _cloudinaryVideos = [];
  final Random _random = Random();
  final Map<String, CachedNetworkImageProvider> _imageCache = {};
  final SettingsService _settings = SettingsService();

  late String _current;
  String? _previous;
  Timer? _timer;
  WallpaperType _currentType = WallpaperType.image;
  WallpaperSource _currentSource = WallpaperSource.default_;

  WallpaperManager() {
    // Initialiser avec les wallpapers par défaut (images uniquement)
    _defaultWallpapers.addAll(NotilusWallpapers.all);
    _current = _pickRandomFrom(_defaultWallpapers);
    _preloadImage(_current);
    _setupRotationTimer();
    
    // Écouter les changements de paramètres
    _settings.addListener(_onSettingsChanged);
    
    // Charger les wallpapers depuis Cloudinary si disponibles
    _loadCloudinaryWallpapers();
  }
  
  void _onSettingsChanged() {
    _setupRotationTimer();
    _loadCloudinaryWallpapers();
  }
  
  void _loadCloudinaryWallpapers() {
    final selectedBackgrounds = _settings.selectedBackgrounds;
    final selectedVideos = _settings.selectedVideos;
    
    final previousCloudinaryImages = List<String>.from(_cloudinaryImages);
    final previousCloudinaryVideos = List<String>.from(_cloudinaryVideos);
    
    _cloudinaryImages.clear();
    _cloudinaryImages.addAll(selectedBackgrounds);
    
    _cloudinaryVideos.clear();
    _cloudinaryVideos.addAll(selectedVideos);
    
    // Vérifier si les wallpapers ont changé
    final imagesChanged = _cloudinaryImages.length != previousCloudinaryImages.length ||
        !_cloudinaryImages.every((w) => previousCloudinaryImages.contains(w));
    final videosChanged = _cloudinaryVideos.length != previousCloudinaryVideos.length ||
        !_cloudinaryVideos.every((w) => previousCloudinaryVideos.contains(w));
    
    // Si aucune sélection Cloudinary, utiliser les images par défaut
    if (_cloudinaryImages.isEmpty && _cloudinaryVideos.isEmpty) {
      if (_currentSource != WallpaperSource.default_ || _currentType != WallpaperType.image) {
        _currentSource = WallpaperSource.default_;
        _currentType = WallpaperType.image;
        _current = _pickRandomFrom(_defaultWallpapers);
        _preloadImage(_current);
        notifyListeners();
      }
    } else {
      // Priorité : vidéos > images Cloudinary
      if (_cloudinaryVideos.isNotEmpty) {
        // Utiliser une vidéo Cloudinary
        if (_currentSource != WallpaperSource.cloudinary || 
            _currentType != WallpaperType.video ||
            !_cloudinaryVideos.contains(_current) ||
            videosChanged) {
          _currentSource = WallpaperSource.cloudinary;
          _currentType = WallpaperType.video;
          _current = _cloudinaryVideos.first; // Utiliser la première vidéo
          notifyListeners();
        }
      } else if (_cloudinaryImages.isNotEmpty) {
        // Utiliser une image Cloudinary
        if (_currentSource != WallpaperSource.cloudinary || 
            _currentType != WallpaperType.image ||
            !_cloudinaryImages.contains(_current) ||
            imagesChanged) {
          _currentSource = WallpaperSource.cloudinary;
          _currentType = WallpaperType.image;
          _current = _pickRandomFrom(_cloudinaryImages);
          _preloadImage(_current);
          notifyListeners();
        }
      }
    }
  }
  
  List<String> get _activeWallpapers {
    if (_cloudinaryImages.isNotEmpty || _cloudinaryVideos.isNotEmpty) {
      if (_cloudinaryVideos.isNotEmpty) {
        return _cloudinaryVideos;
      }
      return _cloudinaryImages;
    }
    return _defaultWallpapers;
  }
  
  void _setupRotationTimer() {
    _timer?.cancel();
    
    // Rotation uniquement pour les images, pas pour les vidéos
    if (_settings.wallpaperRotationEnabled && _currentType == WallpaperType.image) {
      final minutes = _settings.wallpaperIntervalMinutes;
      _timer = Timer.periodic(Duration(minutes: minutes), (_) {
        _previous = _current;
        final activeList = _currentSource == WallpaperSource.cloudinary 
            ? (_cloudinaryImages.isNotEmpty ? _cloudinaryImages : _defaultWallpapers)
            : _defaultWallpapers;
        _current = _pickRandomFrom(activeList, exclude: _current);
        if (_currentType == WallpaperType.image) {
          _preloadImage(_current);
        }
        notifyListeners();
      });
    }
  }

  String get current => _current;
  String? get previous => _previous;
  WallpaperType get currentType => _currentType;
  WallpaperSource get currentSource => _currentSource;
  bool get isVideo => _currentType == WallpaperType.video;
  bool get isCloudinary => _currentSource == WallpaperSource.cloudinary;

  String _pickRandomFrom(List<String> list, {String? exclude}) {
    if (list.isEmpty) return '';
    if (list.length == 1) return list.first;
    String candidate;
    do {
      candidate = list[_random.nextInt(list.length)];
    } while (exclude != null && candidate == exclude);
    return candidate;
  }

  void _preloadImage(String url) {
    if (!_imageCache.containsKey(url)) {
      try {
        _imageCache[url] = CachedNetworkImageProvider(url);
      } catch (e) {
        // Ignore preload errors
      }
    }
  }

  /// Permet de forcer le changement de fond d'écran depuis l'UI.
  void next() {
    _previous = _current;
    final activeList = _currentSource == WallpaperSource.cloudinary 
        ? (_cloudinaryImages.isNotEmpty ? _cloudinaryImages : _defaultWallpapers)
        : _defaultWallpapers;
    _current = _pickRandomFrom(activeList, exclude: _current);
    if (_currentType == WallpaperType.image) {
      _preloadImage(_current);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imageCache.clear();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}