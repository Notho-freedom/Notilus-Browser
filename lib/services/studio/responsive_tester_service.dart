/// Service de test responsive pour Notilus Studio
/// Gère les viewports multiples et l'analyse des breakpoints CSS
library responsive_tester_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../browser_engine.dart';
import '../../models/studio/viewport_preset.dart';
import '../../models/studio/studio_models.dart';
import 'studio_service.dart';

/// Service de test responsive
class ResponsiveTesterService extends ChangeNotifier {
  final StudioService _studioService;
  BrowserEngine? _engine;

  // Viewports actifs
  final List<ViewportPreset> _activeViewports = [];
  final Map<String, ViewportState> _viewportStates = {};

  // Configuration
  bool _syncScroll = true;
  bool _showBreakpoints = true;
  bool _highlightIssues = true;

  // Analyse
  List<CSSBreakpoint> _detectedBreakpoints = [];
  List<ResponsiveIssue> _detectedIssues = [];
  bool _isAnalyzing = false;

  // Scroll synchronisé
  double _syncScrollPosition = 0;
  final StreamController<double> _scrollController = StreamController.broadcast();

  ResponsiveTesterService(this._studioService);

  // Getters
  List<ViewportPreset> get activeViewports => List.unmodifiable(_activeViewports);
  Map<String, ViewportState> get viewportStates => Map.unmodifiable(_viewportStates);
  bool get syncScroll => _syncScroll;
  bool get showBreakpoints => _showBreakpoints;
  bool get highlightIssues => _highlightIssues;
  List<CSSBreakpoint> get detectedBreakpoints => List.unmodifiable(_detectedBreakpoints);
  List<ResponsiveIssue> get detectedIssues => List.unmodifiable(_detectedIssues);
  bool get isAnalyzing => _isAnalyzing;
  double get syncScrollPosition => _syncScrollPosition;
  Stream<double> get scrollStream => _scrollController.stream;

  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    notifyListeners();
  }

  void detachEngine() {
    _engine = null;
    notifyListeners();
  }

  void disable() {
    _activeViewports.clear();
    _viewportStates.clear();
    notifyListeners();
  }

  /// Ajoute un viewport à la grille (max 6)
  void addViewport(ViewportPreset preset) {
    if (_activeViewports.length >= 6) return;
    if (_activeViewports.any((v) => v.id == preset.id)) return;

    _activeViewports.add(preset);
    _viewportStates[preset.id] = ViewportState(
      preset: preset,
      isLoading: true,
      scrollPosition: _syncScrollPosition,
    );
    notifyListeners();
    // Forcer une mise à jour immédiate
    Future.microtask(() => notifyListeners());
  }

  /// Supprime un viewport
  void removeViewport(String presetId) {
    _activeViewports.removeWhere((v) => v.id == presetId);
    _viewportStates.remove(presetId);
    notifyListeners();
    // Forcer une mise à jour immédiate
    Future.microtask(() => notifyListeners());
  }

  /// Supprime tous les viewports
  void clearViewports() {
    _activeViewports.clear();
    _viewportStates.clear();
    notifyListeners();
    // Forcer une mise à jour immédiate
    Future.microtask(() => notifyListeners());
  }

  /// Ajoute les viewports par défaut
  void addDefaultViewports() {
    clearViewports();
    addViewport(DevicePresets.iPhone15Pro);
    addViewport(DevicePresets.iPadPro11);
    addViewport(DevicePresets.laptop15FHD);
    notifyListeners();
  }

  /// Ajoute des viewports de breakpoints courants
  void addBreakpointViewports() {
    clearViewports();
    addViewport(DevicePresets.mobileS);
    addViewport(DevicePresets.mobileM);
    addViewport(DevicePresets.tablet);
    addViewport(DevicePresets.laptopSmall);
    addViewport(DevicePresets.laptop15FHD);
    notifyListeners();
  }

  /// Fait pivoter un viewport
  void rotateViewport(String presetId) {
    final index = _activeViewports.indexWhere((v) => v.id == presetId);
    if (index == -1) return;

    final rotated = _activeViewports[index].rotated;
    _activeViewports[index] = rotated;
    _viewportStates[presetId] = _viewportStates[presetId]!.copyWith(preset: rotated);
    notifyListeners();
  }

  /// Active/désactive la synchronisation du scroll
  void setSyncScroll(bool enabled) {
    _syncScroll = enabled;
    notifyListeners();
  }

  /// Met à jour la position de scroll synchronisé
  void updateSyncScroll(double position) {
    if (!_syncScroll) return;
    _syncScrollPosition = position;
    _scrollController.add(position);
    notifyListeners();
  }

  /// Active/désactive l'affichage des breakpoints
  void setShowBreakpoints(bool show) {
    _showBreakpoints = show;
    notifyListeners();
  }

  /// Active/désactive la mise en évidence des problèmes
  void setHighlightIssues(bool highlight) {
    _highlightIssues = highlight;
    notifyListeners();
  }

  /// Met à jour l'état d'un viewport
  void updateViewportState(String presetId, ViewportState state) {
    _viewportStates[presetId] = state;
    notifyListeners();
  }

  /// Analyse les breakpoints CSS de la page
  Future<void> analyzeBreakpoints() async {
    if (_engine == null) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      final result = await _studioService.executeScript(_getBreakpointAnalysisScript());
      if (result != null) {
        final data = jsonDecode(result);
        _detectedBreakpoints = (data['breakpoints'] as List<dynamic>)
            .map((b) => CSSBreakpoint(
                  width: b['width'] as int,
                  mediaQuery: b['mediaQuery'] as String,
                  ruleCount: b['ruleCount'] as int? ?? 0,
                ))
            .toList();

        // Trier par largeur
        _detectedBreakpoints.sort((a, b) => a.width.compareTo(b.width));
      }
    } catch (e) {
      debugPrint('Error analyzing breakpoints: $e');
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  /// Analyse les problèmes responsive
  Future<void> analyzeResponsiveIssues() async {
    if (_engine == null) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      final result = await _studioService.executeScript(_getResponsiveIssuesScript());
      if (result != null) {
        final data = jsonDecode(result);
        _detectedIssues = (data['issues'] as List<dynamic>)
            .map((i) => ResponsiveIssue(
                  id: i['id'] as String,
                  description: i['description'] as String,
                  atWidth: i['atWidth'] as int?,
                  selector: i['selector'] as String?,
                  type: i['type'] as String,
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('Error analyzing responsive issues: $e');
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  /// Script d'analyse des breakpoints CSS
  String _getBreakpointAnalysisScript() => '''
    (function() {
      const breakpoints = new Map();
      
      // Parcourir toutes les feuilles de style
      for (const sheet of document.styleSheets) {
        try {
          for (const rule of sheet.cssRules || []) {
            if (rule instanceof CSSMediaRule) {
              const match = rule.conditionText.match(/\\((?:min|max)-width:\\s*(\\d+)(?:px)?\\)/);
              if (match) {
                const width = parseInt(match[1]);
                if (!breakpoints.has(width)) {
                  breakpoints.set(width, {
                    width: width,
                    mediaQuery: rule.conditionText,
                    ruleCount: 0
                  });
                }
                breakpoints.get(width).ruleCount += rule.cssRules.length;
              }
            }
          }
        } catch (e) {
          // CORS errors for external stylesheets
        }
      }
      
      return JSON.stringify({
        breakpoints: Array.from(breakpoints.values())
      });
    })();
  ''';

  /// Script de détection des problèmes responsive
  String _getResponsiveIssuesScript() => '''
    (function() {
      const issues = [];
      let issueId = 0;
      
      // Détecter les éléments qui débordent
      const body = document.body;
      const html = document.documentElement;
      const bodyWidth = Math.max(body.scrollWidth, body.offsetWidth);
      const windowWidth = window.innerWidth;
      
      if (bodyWidth > windowWidth) {
        issues.push({
          id: 'issue_' + (issueId++),
          type: 'overflow',
          description: 'Le contenu déborde horizontalement de ' + (bodyWidth - windowWidth) + 'px',
          atWidth: windowWidth
        });
      }
      
      // Détecter les images sans dimensions
      document.querySelectorAll('img:not([width]):not([height])').forEach((img, i) => {
        if (img.naturalWidth > 0) {
          issues.push({
            id: 'issue_' + (issueId++),
            type: 'image_no_dimensions',
            description: 'Image sans dimensions explicites (cause de CLS)',
            selector: img.tagName + (img.className ? '.' + img.className.split(' ')[0] : '')
          });
        }
      });
      
      // Détecter le texte trop petit sur mobile
      if (windowWidth < 768) {
        document.querySelectorAll('p, span, li, td').forEach((el, i) => {
          const fontSize = parseFloat(getComputedStyle(el).fontSize);
          if (fontSize < 14 && el.textContent.trim().length > 0) {
            issues.push({
              id: 'issue_' + (issueId++),
              type: 'small_text',
              description: 'Texte trop petit pour mobile (' + fontSize + 'px)',
              selector: el.tagName.toLowerCase(),
              atWidth: windowWidth
            });
          }
        });
      }
      
      // Détecter les éléments avec largeur fixe
      document.querySelectorAll('*').forEach((el, i) => {
        if (i > 500) return; // Limiter pour les performances
        const style = getComputedStyle(el);
        const width = parseFloat(style.width);
        if (style.width.includes('px') && width > windowWidth * 0.8) {
          issues.push({
            id: 'issue_' + (issueId++),
            type: 'fixed_width',
            description: 'Élément avec largeur fixe trop grande (' + width + 'px)',
            selector: el.tagName.toLowerCase() + (el.className ? '.' + el.className.split(' ')[0] : ''),
            atWidth: windowWidth
          });
        }
      });
      
      // Détecter les zones cliquables trop petites
      document.querySelectorAll('a, button, [onclick]').forEach((el, i) => {
        const rect = el.getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0 && (rect.width < 44 || rect.height < 44)) {
          issues.push({
            id: 'issue_' + (issueId++),
            type: 'small_tap_target',
            description: 'Zone cliquable trop petite (' + Math.round(rect.width) + 'x' + Math.round(rect.height) + 'px)',
            selector: el.tagName.toLowerCase() + (el.className ? '.' + el.className.split(' ')[0] : '')
          });
        }
      });
      
      return JSON.stringify({ issues: issues.slice(0, 50) });
    })();
  ''';

  @override
  void dispose() {
    _scrollController.close();
    super.dispose();
  }
}

/// État d'un viewport
class ViewportState {
  final ViewportPreset preset;
  final bool isLoading;
  final double scrollPosition;
  final bool hasError;
  final String? errorMessage;

  ViewportState({
    required this.preset,
    this.isLoading = false,
    this.scrollPosition = 0,
    this.hasError = false,
    this.errorMessage,
  });

  ViewportState copyWith({
    ViewportPreset? preset,
    bool? isLoading,
    double? scrollPosition,
    bool? hasError,
    String? errorMessage,
  }) {
    return ViewportState(
      preset: preset ?? this.preset,
      isLoading: isLoading ?? this.isLoading,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

