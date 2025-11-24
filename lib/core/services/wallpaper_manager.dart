import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../constants/wallpapers.dart';

/// Gestionnaire global du fond d'écran (même wallpaper pour toutes les vues,
/// avec rotation automatique et pré-chargement).
class WallpaperManager extends ChangeNotifier {
  final List<String> _wallpapers = NotilusWallpapers.all;
  final Random _random = Random();

  late String _current;
  ImageProvider? _currentImage;
  Timer? _timer;

  WallpaperManager() {
    unawaited(_setCurrent(_pickRandom(), notify: false));
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      next();
    });
  }

  String get current => _current;
  ImageProvider? get currentImage => _currentImage;

  Future<void> _setCurrent(String url, {bool notify = true}) async {
    _current = url;
    final provider = NetworkImage(url);
    _currentImage = provider;
    try {
      final stream = provider.resolve(const ImageConfiguration());
      final completer = Completer<void>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, __) {
          completer.complete();
          stream.removeListener(listener);
        },
        onError: (_, __) {
          completer.complete();
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await completer.future;
    } catch (_) {
      // Ignore cache errors (network may fail, fallback to direct usage)
    }
    if (notify) {
      notifyListeners();
    }
  }

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
    unawaited(_setCurrent(_pickRandom(exclude: _current)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}