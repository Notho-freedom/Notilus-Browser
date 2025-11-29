/// Service de comparaison de maquettes pour Notilus Studio
/// Compare des images de maquette avec le site réel
library mockup_comparator_service;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../browser_engine.dart';
import '../../models/studio/studio_models.dart';
import 'studio_service.dart';
import 'screenshot_service.dart';

/// Service de comparaison de maquettes
class MockupComparatorService extends ChangeNotifier {
  final StudioService _studioService;
  BrowserEngine? _engine;

  // État
  Uint8List? _mockupImage;
  Uint8List? _siteImage;
  ComparisonMode _comparisonMode = ComparisonMode.split;
  double _overlayOpacity = 0.5;
  double _slidePosition = 0.5;
  MockupComparisonResult? _lastResult;
  bool _isComparing = false;

  // Historique
  final List<MockupComparisonResult> _history = [];
  static const int _maxHistorySize = 20;

  MockupComparatorService(this._studioService);

  // Getters
  Uint8List? get mockupImage => _mockupImage;
  Uint8List? get siteImage => _siteImage;
  ComparisonMode get comparisonMode => _comparisonMode;
  double get overlayOpacity => _overlayOpacity;
  double get slidePosition => _slidePosition;
  MockupComparisonResult? get lastResult => _lastResult;
  bool get isComparing => _isComparing;
  List<MockupComparisonResult> get history => List.unmodifiable(_history);

  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    notifyListeners();
  }

  void detachEngine() {
    _engine = null;
    notifyListeners();
  }

  /// Charge une image de maquette depuis un fichier
  Future<bool> loadMockupImage(Uint8List imageData) async {
    try {
      _mockupImage = imageData;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading mockup image: $e');
      return false;
    }
  }

  /// Capture l'image du site actuel
  Future<bool> captureSiteImage() async {
    if (_engine == null) return false;

    try {
      _isComparing = true;
      notifyListeners();

      final screenshot = await _studioService.screenshot.captureViewport();
      if (screenshot != null) {
        _siteImage = screenshot.data;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error capturing site image: $e');
      return false;
    } finally {
      _isComparing = false;
      notifyListeners();
    }
  }

  /// Change le mode de comparaison
  void setComparisonMode(ComparisonMode mode) {
    _comparisonMode = mode;
    notifyListeners();
  }

  /// Change l'opacité de superposition
  void setOverlayOpacity(double opacity) {
    _overlayOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Change la position du curseur (mode slide)
  void setSlidePosition(double position) {
    _slidePosition = position.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Compare la maquette avec le site
  Future<MockupComparisonResult?> compare() async {
    if (_mockupImage == null || _siteImage == null) return null;

    try {
      _isComparing = true;
      notifyListeners();

      // Décoder les images
      final mockupImg = img.decodeImage(_mockupImage!);
      final siteImg = img.decodeImage(_siteImage!);

      if (mockupImg == null || siteImg == null) return null;

      // Redimensionner si nécessaire pour avoir la même taille
      final targetWidth = mockupImg.width > siteImg.width ? mockupImg.width : siteImg.width;
      final targetHeight = mockupImg.height > siteImg.height ? mockupImg.height : siteImg.height;

      final normalizedMockup = img.copyResize(mockupImg, width: targetWidth, height: targetHeight);
      final normalizedSite = img.copyResize(siteImg, width: targetWidth, height: targetHeight);

      // Détecter les différences
      final differences = _detectDifferences(normalizedMockup, normalizedSite);

      // Calculer la similarité globale
      final similarity = _calculateSimilarity(normalizedMockup, normalizedSite);

      // Générer l'image de différence
      final diffImage = _generateDiffImage(normalizedMockup, normalizedSite);

      final result = MockupComparisonResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        mockupSource: 'Imported',
        siteUrl: _studioService.currentUrl ?? '',
        differences: differences,
        overallSimilarity: similarity,
        diffImage: diffImage,
      );

      _lastResult = result;
      _addToHistory(result);

      return result;
    } catch (e) {
      debugPrint('Error comparing mockup: $e');
      return null;
    } finally {
      _isComparing = false;
      notifyListeners();
    }
  }

  /// Détecte les différences entre deux images
  List<MockupDifference> _detectDifferences(img.Image mockup, img.Image site) {
    final differences = <MockupDifference>[];

    // Comparaison pixel par pixel simplifiée
    // En production, utiliser une bibliothèque d'analyse d'image plus avancée
    final width = mockup.width < site.width ? mockup.width : site.width;
    final height = mockup.height < site.height ? mockup.height : site.height;

    int diffCount = 0;
    final threshold = 30; // Seuil de différence de couleur

    for (var y = 0; y < height; y += 10) {
      for (var x = 0; x < width; x += 10) {
        final mockupPixel = mockup.getPixel(x, y);
        final sitePixel = site.getPixel(x, y);

        final mockupR = mockupPixel.r;
        final mockupG = mockupPixel.g;
        final mockupB = mockupPixel.b;

        final siteR = sitePixel.r;
        final siteG = sitePixel.g;
        final siteB = sitePixel.b;

        final diff = ((mockupR - siteR).abs() +
                (mockupG - siteG).abs() +
                (mockupB - siteB).abs()) /
            3;

        if (diff > threshold) {
          diffCount++;
        }
      }
    }

    // Créer une différence globale si le nombre de pixels différents est significatif
    if (diffCount > 100) {
      differences.add(MockupDifference(
        id: 'diff_global',
        property: 'Visual Similarity',
        expectedValue: 'Mockup',
        actualValue: 'Site',
        severity: (diffCount / ((width * height) / 100)).clamp(0.0, 1.0),
      ));
    }

    return differences;
  }

  /// Calcule la similarité globale entre deux images
  double _calculateSimilarity(img.Image mockup, img.Image site) {
    final width = mockup.width < site.width ? mockup.width : site.width;
    final height = mockup.height < site.height ? mockup.height : site.height;

    if (width == 0 || height == 0) return 0.0;

    int matchingPixels = 0;
    int totalPixels = 0;
    final threshold = 30;

    for (var y = 0; y < height; y += 5) {
      for (var x = 0; x < width; x += 5) {
        totalPixels++;

        final mockupPixel = mockup.getPixel(x, y);
        final sitePixel = site.getPixel(x, y);

        final mockupR = mockupPixel.r;
        final mockupG = mockupPixel.g;
        final mockupB = mockupPixel.b;

        final siteR = sitePixel.r;
        final siteG = sitePixel.g;
        final siteB = sitePixel.b;

        final diff = ((mockupR - siteR).abs() +
                (mockupG - siteG).abs() +
                (mockupB - siteB).abs()) /
            3;

        if (diff <= threshold) {
          matchingPixels++;
        }
      }
    }

    return totalPixels > 0 ? matchingPixels / totalPixels : 0.0;
  }

  /// Génère une image de différence
  Uint8List? _generateDiffImage(img.Image mockup, img.Image site) {
    try {
      final width = mockup.width < site.width ? mockup.width : site.width;
      final height = mockup.height < site.height ? mockup.height : site.height;

      final diffImg = img.Image(width: width, height: height);

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final mockupPixel = mockup.getPixel(x, y);
          final sitePixel = site.getPixel(x, y);

          final mockupR = mockupPixel.r;
          final mockupG = mockupPixel.g;
          final mockupB = mockupPixel.b;

          final siteR = sitePixel.r;
          final siteG = sitePixel.g;
          final siteB = sitePixel.b;

          // Différence absolue
          final diffR = ((mockupR - siteR).abs()).round().clamp(0, 255);
          final diffG = ((mockupG - siteG).abs()).round().clamp(0, 255);
          final diffB = ((mockupB - siteB).abs()).round().clamp(0, 255);

          diffImg.setPixel(x, y, img.ColorRgb8(diffR, diffG, diffB));
        }
      }

      return Uint8List.fromList(img.encodePng(diffImg));
    } catch (e) {
      debugPrint('Error generating diff image: $e');
      return null;
    }
  }

  /// Ajoute un résultat à l'historique
  void _addToHistory(MockupComparisonResult result) {
    _history.insert(0, result);

    if (_history.length > _maxHistorySize) {
      _history.removeLast();
    }
  }

  /// Efface les images chargées
  void clear() {
    _mockupImage = null;
    _siteImage = null;
    _lastResult = null;
    notifyListeners();
  }

  /// Efface l'historique
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

