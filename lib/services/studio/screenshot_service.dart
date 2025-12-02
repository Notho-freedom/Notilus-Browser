/// Service de capture d'écran pour Notilus Studio
/// Capture viewport, page complète, éléments et zones personnalisées
library screenshot_service;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../browser_engine.dart';
import '../../models/studio/viewport_preset.dart';
import '../../models/studio/studio_models.dart';
import 'studio_service.dart';

/// Service de capture d'écran
class StudioScreenshotService extends ChangeNotifier {
  final StudioService _studioService;
  BrowserEngine? _engine;

  // Configuration par défaut
  ScreenshotConfig _config = const ScreenshotConfig();

  // Historique des captures
  final List<Screenshot> _captures = [];
  static const int _maxHistorySize = 50;

  // État
  bool _isCapturing = false;
  double _captureProgress = 0;
  String? _lastError;

  // File d'attente pour les captures batch
  final List<_BatchCaptureJob> _batchQueue = [];
  bool _isBatchProcessing = false;

  StudioScreenshotService(this._studioService);

  // Getters
  ScreenshotConfig get config => _config;
  List<Screenshot> get captures => List.unmodifiable(_captures);
  bool get isCapturing => _isCapturing;
  double get captureProgress => _captureProgress;
  String? get lastError => _lastError;
  bool get isBatchProcessing => _isBatchProcessing;
  int get batchQueueLength => _batchQueue.length;

  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    notifyListeners();
  }

  void detachEngine() {
    _engine = null;
    notifyListeners();
  }

  /// Met à jour la configuration
  void updateConfig(ScreenshotConfig config) {
    _config = config;
    notifyListeners();
  }

  /// Capture le viewport actuel
  Future<Screenshot?> captureViewport({ScreenshotConfig? config}) async {
    config ??= _config;
    return _capture(config.copyWith(type: CaptureType.viewport));
  }

  /// Capture la page complète (scroll)
  Future<Screenshot?> captureFullPage({ScreenshotConfig? config}) async {
    config ??= _config;
    return _capture(config.copyWith(type: CaptureType.fullPage));
  }

  /// Capture un élément spécifique
  Future<Screenshot?> captureElement(String selector, {ScreenshotConfig? config}) async {
    config ??= _config;
    return _capture(config.copyWith(type: CaptureType.element, selector: selector));
  }

  /// Capture une zone personnalisée
  Future<Screenshot?> captureArea(Rect area, {ScreenshotConfig? config}) async {
    config ??= _config;
    return _capture(config.copyWith(type: CaptureType.area, customArea: area));
  }

  /// Capture batch sur plusieurs viewports
  Future<Map<String, Screenshot>> captureBatch(List<ViewportPreset> presets, {ScreenshotConfig? config}) async {
    config ??= _config;
    final results = <String, Screenshot>{};

    _isBatchProcessing = true;
    notifyListeners();

    for (var i = 0; i < presets.length; i++) {
      _captureProgress = i / presets.length;
      notifyListeners();

      final preset = presets[i];
      // Simuler le changement de viewport et capturer
      final screenshot = await _captureWithViewport(preset, config);
      if (screenshot != null) {
        results[preset.id] = screenshot;
      }
    }

    _isBatchProcessing = false;
    _captureProgress = 0;
    notifyListeners();

    return results;
  }

  /// Ajoute une capture à la file d'attente batch
  void addToBatchQueue(ViewportPreset preset, {ScreenshotConfig? config}) {
    _batchQueue.add(_BatchCaptureJob(preset: preset, config: config ?? _config));
    notifyListeners();
  }

  /// Traite la file d'attente batch
  Future<Map<String, Screenshot>> processBatchQueue() async {
    final presets = _batchQueue.map((j) => j.preset).toList();
    final results = await captureBatch(presets);
    _batchQueue.clear();
    return results;
  }

  /// Vide la file d'attente
  void clearBatchQueue() {
    _batchQueue.clear();
    notifyListeners();
  }

  /// Supprime une capture de l'historique
  void removeCapture(String id) {
    _captures.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Vide l'historique
  void clearHistory() {
    _captures.clear();
    notifyListeners();
  }

  /// Capture interne
  Future<Screenshot?> _capture(ScreenshotConfig config) async {
    if (_engine == null) {
      _lastError = 'Aucun moteur de rendu attaché';
      return null;
    }

    _isCapturing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Appliquer les options pré-capture
      await _prepareForCapture(config);

      // Attendre si nécessaire
      if (config.delay > Duration.zero) {
        await Future.delayed(config.delay);
      }

      // Effectuer la capture selon le type
      Uint8List? imageData;
      int width = 0;
      int height = 0;

      switch (config.type) {
        case CaptureType.viewport:
          final result = await _captureViewportInternal(config);
          imageData = result?['data'] as Uint8List?;
          width = result?['width'] as int? ?? 0;
          height = result?['height'] as int? ?? 0;
          break;

        case CaptureType.fullPage:
          final result = await _captureFullPageInternal(config);
          imageData = result?['data'] as Uint8List?;
          width = result?['width'] as int? ?? 0;
          height = result?['height'] as int? ?? 0;
          break;

        case CaptureType.element:
          final result = await _captureElementInternal(config);
          imageData = result?['data'] as Uint8List?;
          width = result?['width'] as int? ?? 0;
          height = result?['height'] as int? ?? 0;
          break;

        case CaptureType.area:
          final result = await _captureAreaInternal(config);
          imageData = result?['data'] as Uint8List?;
          width = result?['width'] as int? ?? 0;
          height = result?['height'] as int? ?? 0;
          break;
      }

      // Restaurer après capture
      await _restoreAfterCapture(config);

      if (imageData == null) {
        _lastError = 'Échec de la capture';
        return null;
      }

      // Créer l'objet Screenshot
      final screenshot = Screenshot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        url: _studioService.currentUrl,
        type: config.type,
        width: width,
        height: height,
        format: config.format,
        data: imageData,
        metadata: {
          'scale': config.scale,
          'quality': config.quality.value,
        },
      );

      // Ajouter à l'historique
      _captures.insert(0, screenshot);
      if (_captures.length > _maxHistorySize) {
        _captures.removeLast();
      }

      return screenshot;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Screenshot error: $e');
      return null;
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }

  /// Capture avec un viewport spécifique
  Future<Screenshot?> _captureWithViewport(ViewportPreset preset, ScreenshotConfig config) async {
    // Simuler le changement de viewport via JavaScript
    await _studioService.executeScript('''
      (function() {
        // Sauvegarder les dimensions actuelles
        window.__notilusOriginalWidth = window.innerWidth;
        window.__notilusOriginalHeight = window.innerHeight;
        
        // Simuler le viewport (pour les media queries)
        Object.defineProperty(window, 'innerWidth', { value: ${preset.width}, writable: true });
        Object.defineProperty(window, 'innerHeight', { value: ${preset.height}, writable: true });
        window.dispatchEvent(new Event('resize'));
      })();
    ''');

    // Attendre la mise à jour du layout
    await Future.delayed(const Duration(milliseconds: 300));

    // Capturer
    final screenshot = await _capture(config);

    // Restaurer les dimensions
    await _studioService.executeScript('''
      (function() {
        if (window.__notilusOriginalWidth) {
          Object.defineProperty(window, 'innerWidth', { value: window.__notilusOriginalWidth, writable: true });
          Object.defineProperty(window, 'innerHeight', { value: window.__notilusOriginalHeight, writable: true });
          window.dispatchEvent(new Event('resize'));
        }
      })();
    ''');

    if (screenshot != null) {
      return Screenshot(
        id: screenshot.id,
        timestamp: screenshot.timestamp,
        url: screenshot.url,
        type: screenshot.type,
        width: preset.width,
        height: preset.height,
        format: screenshot.format,
        data: screenshot.data,
        deviceName: preset.name,
        metadata: screenshot.metadata,
      );
    }

    return null;
  }

  /// Prépare la page pour la capture
  Future<void> _prepareForCapture(ScreenshotConfig config) async {
    final preparations = <String>[];

    if (config.hideScrollbars) {
      preparations.add('''
        document.documentElement.style.overflow = 'hidden';
        document.body.style.overflow = 'hidden';
      ''');
    }

    if (config.removeStickyElements) {
      preparations.add('''
        document.querySelectorAll('[style*="position: fixed"], [style*="position: sticky"]').forEach(el => {
          el.dataset.notilusOriginalPosition = el.style.position;
          el.style.position = 'absolute';
        });
      ''');
    }

    if (config.simulateDarkMode) {
      preparations.add('''
        document.documentElement.classList.add('dark');
        document.body.classList.add('dark');
        document.documentElement.style.colorScheme = 'dark';
      ''');
    }

    if (config.waitForAnimations) {
      preparations.add('''
        await new Promise(resolve => {
          const animations = document.getAnimations();
          if (animations.length === 0) {
            resolve();
          } else {
            Promise.all(animations.map(a => a.finished)).then(resolve);
          }
        });
      ''');
    }

    if (preparations.isNotEmpty) {
      await _studioService.executeScript('(async function() { ${preparations.join('\n')} })();');
    }
  }

  /// Restaure la page après capture
  Future<void> _restoreAfterCapture(ScreenshotConfig config) async {
    final restorations = <String>[];

    if (config.hideScrollbars) {
      restorations.add('''
        document.documentElement.style.overflow = '';
        document.body.style.overflow = '';
      ''');
    }

    if (config.removeStickyElements) {
      restorations.add('''
        document.querySelectorAll('[data-notilus-original-position]').forEach(el => {
          el.style.position = el.dataset.notilusOriginalPosition;
          delete el.dataset.notilusOriginalPosition;
        });
      ''');
    }

    if (config.simulateDarkMode) {
      restorations.add('''
        document.documentElement.classList.remove('dark');
        document.body.classList.remove('dark');
        document.documentElement.style.colorScheme = '';
      ''');
    }

    if (restorations.isNotEmpty) {
      await _studioService.executeScript('(function() { ${restorations.join('\n')} })();');
    }
  }

  /// Capture viewport interne
  Future<Map<String, dynamic>?> _captureViewportInternal(ScreenshotConfig config) async {
    if (_engine == null) return null;
    
    try {
      // Utiliser la nouvelle méthode captureScreenshot de l'engine
      final result = await _engine!.captureScreenshot(fullPage: false);
      if (result == null) return null;
      
      // Convertir dataUrl en Uint8List
      final dataUrl = result['dataUrl'] as String?;
      if (dataUrl == null) return null;
      
      final base64 = dataUrl.split(',').length > 1 ? dataUrl.split(',')[1] : dataUrl;
      final bytes = base64Decode(base64);
      
      return {
        'data': bytes,
        'width': result['width'] as int? ?? 0,
        'height': result['height'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('Screenshot viewport error: $e');
      return null;
    }
  }
  

  /// Capture page complète interne
  Future<Map<String, dynamic>?> _captureFullPageInternal(ScreenshotConfig config) async {
    if (_engine == null) return null;
    
    try {
      // Utiliser la nouvelle méthode captureScreenshot de l'engine
      final result = await _engine!.captureScreenshot(fullPage: true);
      if (result == null) return null;
      
      // Convertir dataUrl en Uint8List
      final dataUrl = result['dataUrl'] as String?;
      if (dataUrl == null) return null;
      
      final base64 = dataUrl.split(',').length > 1 ? dataUrl.split(',')[1] : dataUrl;
      final bytes = base64Decode(base64);
      
      return {
        'data': bytes,
        'width': result['width'] as int? ?? 0,
        'height': result['height'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('Screenshot fullPage error: $e');
      return null;
    }
  }

  /// Capture élément interne
  Future<Map<String, dynamic>?> _captureElementInternal(ScreenshotConfig config) async {
    if (_engine == null || config.selector == null) return null;
    
    try {
      // Utiliser la nouvelle méthode captureScreenshot de l'engine
      final result = await _engine!.captureScreenshot(
        fullPage: false,
        selector: config.selector,
      );
      if (result == null) return null;
      
      // Convertir dataUrl en Uint8List
      final dataUrl = result['dataUrl'] as String?;
      if (dataUrl == null) return null;
      
      final base64 = dataUrl.split(',').length > 1 ? dataUrl.split(',')[1] : dataUrl;
      final bytes = base64Decode(base64);
      
      return {
        'data': bytes,
        'width': result['width'] as int? ?? 0,
        'height': result['height'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('Screenshot element error: $e');
      return null;
    }
  }

  /// Capture zone interne
  Future<Map<String, dynamic>?> _captureAreaInternal(ScreenshotConfig config) async {
    if (config.customArea == null) return null;

    return {
      'width': config.customArea!.width.round(),
      'height': config.customArea!.height.round(),
      'data': Uint8List(0), // Placeholder
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Job de capture batch
class _BatchCaptureJob {
  final ViewportPreset preset;
  final ScreenshotConfig config;

  _BatchCaptureJob({required this.preset, required this.config});
}

/// Templates de mockup
class MockupTemplates {
  MockupTemplates._();

  static const iPhoneFrame = MockupTemplate(
    id: 'iphone_frame',
    name: 'iPhone Frame',
    category: 'phone',
    assetPath: 'assets/mockups/iphone_frame.png',
    frameSize: Size(300, 620),
    screenArea: Rect.fromLTWH(18, 18, 264, 572),
    cornerRadius: 40,
  );

  static const macBookFrame = MockupTemplate(
    id: 'macbook_frame',
    name: 'MacBook Frame',
    category: 'laptop',
    assetPath: 'assets/mockups/macbook_frame.png',
    frameSize: Size(800, 500),
    screenArea: Rect.fromLTWH(95, 25, 610, 385),
    cornerRadius: 8,
  );

  static const browserFrame = MockupTemplate(
    id: 'browser_frame',
    name: 'Browser Frame',
    category: 'browser',
    assetPath: 'assets/mockups/browser_frame.png',
    frameSize: Size(800, 600),
    screenArea: Rect.fromLTWH(1, 40, 798, 559),
    cornerRadius: 0,
  );

  static const iPadFrame = MockupTemplate(
    id: 'ipad_frame',
    name: 'iPad Frame',
    category: 'tablet',
    assetPath: 'assets/mockups/ipad_frame.png',
    frameSize: Size(560, 760),
    screenArea: Rect.fromLTWH(30, 40, 500, 680),
    cornerRadius: 20,
  );

  static List<MockupTemplate> get all => [
    iPhoneFrame,
    macBookFrame,
    browserFrame,
    iPadFrame,
  ];

  static List<MockupTemplate> byCategory(String category) =>
      all.where((t) => t.category == category).toList();
}

