/// Reactive Studio Service - Previews temps réel avec Streams
/// Améliore la réactivité du système Studio
library reactive_studio_service;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../browser_engine.dart';
import '../../models/studio/viewport_preset.dart';

/// État d'un viewport de preview
class ViewportState {
  final String id;
  final ViewportPreset preset;
  final bool isLoading;
  final String? currentUrl;
  final DateTime lastUpdate;

  const ViewportState({
    required this.id,
    required this.preset,
    this.isLoading = false,
    this.currentUrl,
    required this.lastUpdate,
  });

  ViewportState copyWith({
    bool? isLoading,
    String? currentUrl,
    DateTime? lastUpdate,
  }) {
    return ViewportState(
      id: id,
      preset: preset,
      isLoading: isLoading ?? this.isLoading,
      currentUrl: currentUrl ?? this.currentUrl,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Service Studio réactif avec Streams
class ReactiveStudioService extends ChangeNotifier {
  BrowserEngine? _mainEngine;
  final Map<String, BrowserEngine> _viewportEngines = {};
  final Map<String, ViewportState> _viewportStates = {};
  
  // Streams pour la réactivité
  final _urlController = StreamController<String>.broadcast();
  final _cssController = StreamController<String>.broadcast();
  final _htmlController = StreamController<String>.broadcast();
  final _stateController = StreamController<Map<String, ViewportState>>.broadcast();
  
  // Debouncing pour éviter les mises à jour trop fréquentes
  Timer? _cssDebouncer;
  Timer? _htmlDebouncer;
  static const _debounceDelay = Duration(milliseconds: 150);
  
  String? _currentUrl;
  String? _injectedCss;
  String? _injectedHtml;
  bool _isEnabled = false;
  bool _isPanelVisible = false;

  // Streams publics
  Stream<String> get urlStream => _urlController.stream;
  Stream<String> get cssStream => _cssController.stream;
  Stream<String> get htmlStream => _htmlController.stream;
  Stream<Map<String, ViewportState>> get stateStream => _stateController.stream;

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isPanelVisible => _isPanelVisible;
  String? get currentUrl => _currentUrl;
  Map<String, ViewportState> get viewportStates => Map.unmodifiable(_viewportStates);

  /// Attache le moteur principal
  void attachMainEngine(BrowserEngine engine) {
    _mainEngine = engine;
    
    // Écouter les changements d'URL
    engine.onUrlChanged = (url) {
      _currentUrl = url;
      _urlController.add(url);
      _syncAllViewports();
    };
  }

  /// Active/désactive le service
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  /// Affiche/masque le panneau
  void setPanelVisible(bool visible) {
    _isPanelVisible = visible;
    notifyListeners();
    
    if (visible && _currentUrl != null) {
      _syncAllViewports();
    }
  }

  /// Ajoute un viewport de preview
  Future<void> addViewport(ViewportPreset preset) async {
    final id = 'viewport_${preset.width}x${preset.height}';
    
    if (_viewportStates.containsKey(id)) return;
    
    _viewportStates[id] = ViewportState(
      id: id,
      preset: preset,
      isLoading: true,
      lastUpdate: DateTime.now(),
    );
    
    _stateController.add(_viewportStates);
    notifyListeners();
    
    // Synchroniser avec l'URL actuelle
    if (_currentUrl != null) {
      await _loadViewportUrl(id, _currentUrl!);
    }
  }

  /// Supprime un viewport
  void removeViewport(String id) {
    _viewportEngines[id]?.dispose();
    _viewportEngines.remove(id);
    _viewportStates.remove(id);
    
    _stateController.add(_viewportStates);
    notifyListeners();
  }

  /// Injecte du CSS en temps réel
  void injectCss(String css) {
    _cssDebouncer?.cancel();
    _cssDebouncer = Timer(_debounceDelay, () {
      _injectedCss = css;
      _cssController.add(css);
      _applyInjections();
    });
  }

  /// Injecte du HTML en temps réel
  void injectHtml(String html) {
    _htmlDebouncer?.cancel();
    _htmlDebouncer = Timer(_debounceDelay, () {
      _injectedHtml = html;
      _htmlController.add(html);
      _applyInjections();
    });
  }

  /// Synchronise tous les viewports avec l'URL actuelle
  Future<void> _syncAllViewports() async {
    if (_currentUrl == null || !_isEnabled) return;
    
    for (final id in _viewportStates.keys) {
      await _loadViewportUrl(id, _currentUrl!);
    }
  }

  /// Charge une URL dans un viewport
  Future<void> _loadViewportUrl(String id, String url) async {
    final engine = _viewportEngines[id];
    if (engine == null) return;
    
    // Mettre à jour l'état
    _viewportStates[id] = _viewportStates[id]!.copyWith(
      isLoading: true,
      lastUpdate: DateTime.now(),
    );
    _stateController.add(_viewportStates);
    
    try {
      await engine.loadUrl(url);
      
      // Appliquer les injections après chargement
      await _applyInjectionsToViewport(id);
      
      _viewportStates[id] = _viewportStates[id]!.copyWith(
        isLoading: false,
        currentUrl: url,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Erreur chargement viewport $id: $e');
      _viewportStates[id] = _viewportStates[id]!.copyWith(
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
    }
    
    _stateController.add(_viewportStates);
  }

  /// Applique les injections CSS/HTML à tous les viewports
  Future<void> _applyInjections() async {
    for (final id in _viewportStates.keys) {
      await _applyInjectionsToViewport(id);
    }
    
    // Aussi sur le moteur principal
    if (_mainEngine != null) {
      await _applyInjectionsToEngine(_mainEngine!);
    }
  }

  /// Applique les injections à un viewport spécifique
  Future<void> _applyInjectionsToViewport(String id) async {
    final engine = _viewportEngines[id];
    if (engine == null) return;
    
    await _applyInjectionsToEngine(engine);
  }

  /// Applique les injections à un moteur
  Future<void> _applyInjectionsToEngine(BrowserEngine engine) async {
    try {
      // Injection CSS
      if (_injectedCss != null && _injectedCss!.isNotEmpty) {
        final cssScript = '''
          (function() {
            let style = document.getElementById('notilus-studio-css');
            if (!style) {
              style = document.createElement('style');
              style.id = 'notilus-studio-css';
              document.head.appendChild(style);
            }
            style.textContent = `${_injectedCss!.replaceAll('`', '\\`')}`;
          })();
        ''';
        await engine.executeScript(cssScript);
      }
      
      // Injection HTML
      if (_injectedHtml != null && _injectedHtml!.isNotEmpty) {
        final htmlScript = '''
          (function() {
            let container = document.getElementById('notilus-studio-html');
            if (!container) {
              container = document.createElement('div');
              container.id = 'notilus-studio-html';
              document.body.appendChild(container);
            }
            container.innerHTML = `${_injectedHtml!.replaceAll('`', '\\`')}`;
          })();
        ''';
        await engine.executeScript(htmlScript);
      }
    } catch (e) {
      debugPrint('❌ Erreur injection: $e');
    }
  }

  /// Rafraîchit tous les viewports
  Future<void> refreshAll() async {
    if (_currentUrl == null) return;
    
    for (final id in _viewportStates.keys.toList()) {
      await _loadViewportUrl(id, _currentUrl!);
    }
  }

  /// Prend une capture d'écran d'un viewport
  Future<List<int>?> captureViewport(String id) async {
    // TODO: Implémenter la capture d'écran via WebView2
    return null;
  }

  @override
  void dispose() {
    _cssDebouncer?.cancel();
    _htmlDebouncer?.cancel();
    _urlController.close();
    _cssController.close();
    _htmlController.close();
    _stateController.close();
    
    for (final engine in _viewportEngines.values) {
      engine.dispose();
    }
    
    super.dispose();
  }
}

