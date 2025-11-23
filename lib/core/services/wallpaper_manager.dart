import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants/wallpapers.dart';

/// Gestionnaire global du fond d'écran (même wallpaper pour toutes les vues,
/// avec rotation automatique dans le temps).
class WallpaperManager extends ChangeNotifier {
  final List<String> _wallpapers = NotilusWallpapers.all;
  final Random _random = Random();

  late String _current;
  Timer? _timer;

  WallpaperManager() {
    _current = _pickRandom();
    // Rotation automatique toutes les 2 minutes (ajustable plus tard).
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      _current = _pickRandom(exclude: _current);
      notifyListeners();
    });
  }

  String get current => _current;

  String _pickRandom({String? exclude}) {
    if (_wallpapers.isEmpty) return '';
    if (_wallpapers.length == 1) return _wallpapers.first;
    String candidate;
    do {
      candidate = _wallpapers[_random.nextInt(_wallpapers.length)];
    } while (exclude != null && candidate == exclude);
    return candidate;
  }

  /// Permet de forcer le changement de fond d'écran depuis l'UI.
  void next() {
    _current = _pickRandom(exclude: _current);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}