import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
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
    // Nettoyer le cache d'images des URLs vidéo qui pourraient s'y trouver
    _imageCache.removeWhere((key, value) => _isVideoUrl(key));
    
    // Initialiser avec les wallpapers par défaut (images uniquement)
    _defaultWallpapers.addAll(NotilusWallpapers.all);
    // Filtrer les URLs vidéo des wallpapers par défaut
    _defaultWallpapers.removeWhere((url) => _isVideoUrl(url));
    
    if (_defaultWallpapers.isEmpty) {
      debugPrint('⚠️ Aucun wallpaper par défaut valide trouvé');
      _current = '';
    } else {
      _current = _pickRandomFrom(_defaultWallpapers);
      // Vérifier que ce n'est pas une vidéo avant de précharger
      if (!_isVideoUrl(_current)) {
        _preloadImage(_current);
      } else {
        debugPrint('⚠️ Wallpaper par défaut sélectionné est une vidéo, sélection d\'un autre...');
        // Sélectionner un autre wallpaper qui n'est pas une vidéo
        final validWallpapers = _defaultWallpapers.where((url) => !_isVideoUrl(url)).toList();
        if (validWallpapers.isNotEmpty) {
          _current = validWallpapers.first;
          _preloadImage(_current);
        } else {
          _current = '';
        }
      }
    }
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
    
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run2',
        'hypothesisId': 'D',
        'location': 'wallpaper_manager.dart:81',
        'message': '_loadCloudinaryWallpapers called',
        'data': {
          'selectedBackgroundsCount': selectedBackgrounds.length,
          'selectedVideosCount': selectedVideos.length,
          'selectedBackgrounds': selectedBackgrounds.take(3).toList(),
          'selectedVideos': selectedVideos.take(3).toList(),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
      logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    final previousCloudinaryImages = List<String>.from(_cloudinaryImages);
    final previousCloudinaryVideos = List<String>.from(_cloudinaryVideos);
    
    _cloudinaryImages.clear();
    // Filtrer les URLs vidéo de selectedBackgrounds
    for (final url in selectedBackgrounds) {
      if (!_isVideoUrl(url)) {
        _cloudinaryImages.add(url);
      } else {
        debugPrint('⚠️ URL vidéo trouvée dans selectedBackgrounds, ignorée: $url');
      }
    }
    
    _cloudinaryVideos.clear();
    _cloudinaryVideos.addAll(selectedVideos);
    
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run2',
        'hypothesisId': 'D',
        'location': 'wallpaper_manager.dart:99',
        'message': '_loadCloudinaryWallpapers after filtering',
        'data': {
          '_cloudinaryImagesCount': _cloudinaryImages.length,
          '_cloudinaryVideosCount': _cloudinaryVideos.length,
          '_currentType': _currentType.toString(),
          '_currentSource': _currentSource.toString(),
          '_current': _current.length > 100 ? '${_current.substring(0, 100)}...' : _current,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
      logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
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
        final newImage = _pickRandomFrom(_defaultWallpapers);
        // Vérifier que ce n'est pas une vidéo avant de l'utiliser
        if (!_isVideoUrl(newImage)) {
          _current = newImage;
          _preloadImage(_current);
          notifyListeners();
        }
      }
    } else {
      // Priorité : images > vidéos Cloudinary (si l'utilisateur sélectionne une image, il veut voir une image)
      if (_cloudinaryImages.isNotEmpty) {
        // Utiliser une image Cloudinary
        if (_currentSource != WallpaperSource.cloudinary || 
            _currentType != WallpaperType.image ||
            !_cloudinaryImages.contains(_current) ||
            imagesChanged) {
          _currentSource = WallpaperSource.cloudinary;
          _currentType = WallpaperType.image;
          final newImage = _pickRandomFrom(_cloudinaryImages);
          // Double vérification : s'assurer que ce n'est pas une vidéo
          if (!_isVideoUrl(newImage)) {
            _current = newImage;
            _preloadImage(_current);
            // #region agent log
            try {
              final logData = {
                'sessionId': 'debug-session',
                'runId': 'run2',
                'hypothesisId': 'D',
                'location': 'wallpaper_manager.dart:187',
                'message': 'Setting new Cloudinary image',
                'data': {
                  'newImage': _current.length > 100 ? '${_current.substring(0, 100)}...' : _current,
                },
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              };
              final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
              logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
            } catch (_) {}
            // #endregion
            notifyListeners();
          }
        }
      } else if (_cloudinaryVideos.isNotEmpty) {
        // Utiliser une vidéo Cloudinary seulement si aucune image n'est sélectionnée
        if (_currentSource != WallpaperSource.cloudinary || 
            _currentType != WallpaperType.video ||
            !_cloudinaryVideos.contains(_current) ||
            videosChanged) {
          _currentSource = WallpaperSource.cloudinary;
          _currentType = WallpaperType.video;
          _current = _cloudinaryVideos.first; // Utiliser la première vidéo
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
        final newImage = _pickRandomFrom(activeList, exclude: _current);
        // Vérifier que ce n'est pas une vidéo avant de l'utiliser
        if (!_isVideoUrl(newImage) && _currentType == WallpaperType.image) {
          _current = newImage;
          _preloadImage(_current);
          notifyListeners();
        }
      });
    }
  }

  String get current {
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run2',
        'hypothesisId': 'D',
        'location': 'wallpaper_manager.dart:187',
        'message': 'current getter called',
        'data': {
          '_currentType': _currentType.toString(),
          '_current': _current.length > 100 ? '${_current.substring(0, 100)}...' : _current,
          'isVideoUrl': _isVideoUrl(_current),
          'isVideo': _currentType == WallpaperType.video,
          '_cloudinaryImagesCount': _cloudinaryImages.length,
          '_cloudinaryVideosCount': _cloudinaryVideos.length,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
      logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    // S'assurer que si c'est une image, on ne retourne jamais une URL vidéo
    if (_currentType == WallpaperType.image && _isVideoUrl(_current)) {
      debugPrint('⚠️ Erreur: _current est une vidéo mais _currentType est image. Correction...');
      // Retourner une image par défaut
      if (_defaultWallpapers.isNotEmpty) {
        final defaultImage = _defaultWallpapers.firstWhere(
          (url) => !_isVideoUrl(url),
          orElse: () => _defaultWallpapers.first,
        );
        _current = defaultImage;
        _currentType = WallpaperType.image;
        _currentSource = WallpaperSource.default_;
        _preloadImage(_current);
        notifyListeners();
      }
    }
    
    // Si c'est une vidéo, retourner une chaîne vide pour éviter qu'elle soit utilisée comme image
    final returnValue = _currentType == WallpaperType.video ? '' : _current;
    
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run2',
        'hypothesisId': 'D',
        'location': 'wallpaper_manager.dart:227',
        'message': 'current getter returning',
        'data': {
          'returnValue': returnValue.isEmpty ? 'EMPTY' : (returnValue.length > 100 ? '${returnValue.substring(0, 100)}...' : returnValue),
          '_currentType': _currentType.toString(),
          'willReturnVideo': _currentType == WallpaperType.video,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
      logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    return returnValue;
  }
  
  /// Retourne l'URL du wallpaper pour les images uniquement (retourne une chaîne vide pour les vidéos)
  String get currentImageUrl {
    if (_currentType == WallpaperType.video || _current.isEmpty) {
      return '';
    }
    return _current;
  }
  
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

  /// Vérifie si une URL est une vidéo
  static bool _isVideoUrl(String url) {
    return url.contains('.mp4') || 
           url.contains('video/upload') ||
           url.endsWith('.webm') ||
           url.endsWith('.mov') ||
           url.endsWith('.avi');
  }

  void _preloadImage(String url) {
    if (url.isEmpty) return;
    
    // Vérifier que ce n'est pas une URL vidéo
    if (_isVideoUrl(url)) {
      // Nettoyer le cache si cette URL vidéo y est présente
      _imageCache.remove(url);
      debugPrint('⚠️ Tentative de précharger une URL vidéo comme image: $url');
      return;
    }
    
    // Nettoyer le cache des URLs vidéo qui pourraient s'y trouver
    final videoUrls = _imageCache.keys.where((key) => _isVideoUrl(key)).toList();
    for (final videoUrl in videoUrls) {
      _imageCache.remove(videoUrl);
      debugPrint('🧹 Nettoyage du cache: URL vidéo supprimée: $videoUrl');
    }
    
    if (!_imageCache.containsKey(url)) {
      try {
        _imageCache[url] = CachedNetworkImageProvider(url);
      } catch (e) {
        debugPrint('Erreur preload image: $e');
        // Ignore preload errors
      }
    }
  }

  /// Permet de forcer le changement de fond d'écran depuis l'UI.
  void next() {
    // Ne changer que si c'est une image (pas de vidéo)
    if (_currentType == WallpaperType.image) {
      _previous = _current;
      final activeList = _currentSource == WallpaperSource.cloudinary 
          ? (_cloudinaryImages.isNotEmpty ? _cloudinaryImages : _defaultWallpapers)
          : _defaultWallpapers;
      final newImage = _pickRandomFrom(activeList, exclude: _current);
      // Vérifier que ce n'est pas une vidéo avant de l'utiliser
      if (!_isVideoUrl(newImage)) {
        _current = newImage;
        _preloadImage(_current);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imageCache.clear();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}