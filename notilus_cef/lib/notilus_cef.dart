// notilus_cef.dart
// API Dart moderne avec Streams pour le Quantum CEF Engine

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Événements CEF
class CefEvent {
  final String type;
  final dynamic data;

  const CefEvent._(this.type, [this.data]);

  static const engineReady = CefEvent._('ENGINE_READY');
  static const pageLoaded = CefEvent._('PAGE_LOADED');
  static const textureUpdated = CefEvent._('TEXTURE_UPDATED');
  static const loadError = CefEvent._('LOAD_ERROR');
}

/// Texture CEF avec métadonnées
class CefTexture {
  final int id;
  final int width;
  final int height;
  final DateTime timestamp;

  const CefTexture({
    required this.id,
    required this.width,
    required this.height,
    required this.timestamp,
  });
}

/// Bouton de souris
enum CefMouseButton {
  left,
  middle,
  right;

  /// Retourne l'index CEF du bouton
  int get cefIndex {
    switch (this) {
      case CefMouseButton.left:
        return 0;
      case CefMouseButton.middle:
        return 1;
      case CefMouseButton.right:
        return 2;
    }
  }
}

/// Moteur CEF Quantum
class CefEngine {
  static const _channel = MethodChannel('notilus_cef');
  static final _instance = CefEngine._internal();

  final _textureStream = StreamController<CefTexture>.broadcast();
  final _eventStream = StreamController<CefEvent>.broadcast();

  int? _textureId;
  Size? _viewportSize;
  bool _initialized = false;

  factory CefEngine() => _instance;
  CefEngine._internal();

  /// Stream des textures mises à jour
  Stream<CefTexture> get textureStream => _textureStream.stream;

  /// Stream des événements CEF
  Stream<CefEvent> get eventStream => _eventStream.stream;

  /// ID de la texture actuelle
  int? get textureId => _textureId;

  /// Taille du viewport
  Size? get viewportSize => _viewportSize;

  /// Initialiser le moteur CEF
  Future<void> initialize({Size viewport = const Size(1280, 720)}) async {
    if (_initialized) {
      throw StateError('CEF Engine already initialized');
    }

    _viewportSize = viewport;

    try {
      _textureId = await _channel.invokeMethod<int>('init', {
        'width': viewport.width.toInt(),
        'height': viewport.height.toInt(),
      });

      if (_textureId == null) {
        throw Exception('Failed to initialize CEF engine');
      }

      _initialized = true;

      // Setup texture callback
      _setupTextureListener();

      // Envoyer la taille du viewport à CEF
      await _channel.invokeMethod('resize', {
        'width': viewport.width.toInt(),
        'height': viewport.height.toInt(),
      });

      _eventStream.add(CefEvent.engineReady);
    } catch (e) {
      _eventStream.add(CefEvent.loadError);
      rethrow;
    }
  }

  /// Charger une URL
  Future<void> loadUrl(String url) async {
    if (!_initialized) {
      throw StateError('CEF Engine not initialized');
    }

    await _channel.invokeMethod('loadUrl', {'url': url});
  }

  /// Envoyer un événement de clic de souris
  Future<void> sendMouseClick({
    required Offset position,
    required CefMouseButton button,
    required bool pressed,
  }) async {
    if (!_initialized) return;

    await _channel.invokeMethod('mouseClick', {
      'x': position.dx,
      'y': position.dy,
      'button': button.cefIndex,
      'down': pressed,
    });
  }

  /// Envoyer un événement de mouvement de souris
  Future<void> sendMouseMove(Offset position) async {
    if (!_initialized) return;

    await _channel.invokeMethod('mouseMove', {
      'x': position.dx,
      'y': position.dy,
    });
  }

  /// Envoyer un événement de touche
  Future<void> sendKeyEvent({
    required int keyCode,
    required bool pressed,
  }) async {
    if (!_initialized) return;

    await _channel.invokeMethod('keyEvent', {
      'keyCode': keyCode,
      'down': pressed,
    });
  }

  /// Envoyer du texte
  Future<void> sendText(String text) async {
    if (!_initialized) return;

    await _channel.invokeMethod('sendText', {'text': text});
  }

  /// Redimensionner le viewport
  Future<void> resize(Size size) async {
    if (!_initialized) return;

    _viewportSize = size;
    await _channel.invokeMethod('resize', {
      'width': size.width.toInt(),
      'height': size.height.toInt(),
    });
  }

  /// Configurer l'écouteur de texture
  void _setupTextureListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTextureUpdate') {
        final texture = CefTexture(
          id: _textureId!,
          width: call.arguments['width'] ?? _viewportSize?.width.toInt() ?? 1280,
          height: call.arguments['height'] ?? _viewportSize?.height.toInt() ?? 720,
          timestamp: DateTime.now(),
        );
        _textureStream.add(texture);
      } else if (call.method == 'onPageLoaded') {
        _eventStream.add(CefEvent.pageLoaded);
      }
    });
  }

  /// Libérer les ressources
  void dispose() {
    if (!_initialized) return;

    _channel.invokeMethod('dispose');
    _textureStream.close();
    _eventStream.close();
    _initialized = false;
    _textureId = null;
  }
}
