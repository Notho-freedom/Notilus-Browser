import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/wallpapers.dart';

/// Gestionnaire global du fond d'écran (même wallpaper pour toutes les vues,
/// avec rotation automatique dans le temps et cache).
class WallpaperManager extends ChangeNotifier {
  final List<String> _wallpapers = NotilusWallpapers.all;
  final Random _random = Random();
  final Map<String, CachedNetworkImageProvider> _imageCache = {};

  late String _current;
  String? _previous;
  Timer? _timer;

  WallpaperManager() {
    _current = _pickRandom();
    _preloadImage(_current);
    // Rotation automatique toutes les 2 minutes (ajustable plus tard).
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      _previous = _current;
      _current = _pickRandom(exclude: _current);
      _preloadImage(_current);
      notifyListeners();
    });
  }

  String get current => _current;
  String? get previous => _previous;

  String _pickRandom({String? exclude}) {
    if (_wallpapers.isEmpty) return '';
    if (_wallpapers.length == 1) return _wallpapers.first;
    String candidate;
    do {
      candidate = _wallpapers[_random.nextInt(_wallpapers.length)];
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
    _current = _pickRandom(exclude: _current);
    _preloadImage(_current);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imageCache.clear();
    super.dispose();
  }
}