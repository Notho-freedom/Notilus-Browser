/// Gestionnaire des WebViews pour les viewports Studio
/// Limite à 2 WebViews actifs pour les performances
library viewport_webview_manager;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../webview2_browser_engine.dart';
import '../../models/studio/viewport_preset.dart';

/// Gestionnaire des WebViews de viewports
class ViewportWebViewManager extends ChangeNotifier {
  final Map<String, WebView2BrowserEngine> _viewports = {};
  final int _maxActiveViewports = 2;
  
  ViewportWebViewManager();

  /// Obtient ou crée un WebView pour un viewport
  Future<WebView2BrowserEngine?> getViewportWebView(
    String viewportId,
    ViewportPreset preset,
    String url,
  ) async {
    // Si on a déjà atteint la limite, retourner null
    if (_viewports.length >= _maxActiveViewports && !_viewports.containsKey(viewportId)) {
      return null;
    }

    // Si le viewport existe déjà, le retourner
    if (_viewports.containsKey(viewportId)) {
      return _viewports[viewportId];
    }

    // Créer un nouveau WebView pour ce viewport
    try {
      final engine = WebView2BrowserEngine();
      await engine.initialize();
      
      // Appliquer les dimensions du viewport
      // Note: WebView2 ne permet pas de redimensionner directement, 
      // on utilisera CSS viewport meta tag et zoom
      await engine.navigate(url);
      
      // Injecter le CSS pour simuler les dimensions du viewport
      final viewportScript = '''
        (function() {
          const meta = document.createElement('meta');
          meta.name = 'viewport';
          meta.content = 'width=${preset.width}, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
          document.head.appendChild(meta);
          
          // Appliquer les dimensions via CSS
          document.body.style.width = '${preset.width}px';
          document.body.style.maxWidth = '${preset.width}px';
          document.body.style.margin = '0 auto';
        })();
      ''';
      
      await engine.executeJavaScript(viewportScript);
      
      _viewports[viewportId] = engine;
      notifyListeners();
      
      return engine;
    } catch (e) {
      debugPrint('Erreur lors de la création du WebView pour le viewport $viewportId: $e');
      return null;
    }
  }

  /// Supprime un WebView de viewport
  void removeViewportWebView(String viewportId) {
    final engine = _viewports.remove(viewportId);
    if (engine != null) {
      engine.dispose();
      notifyListeners();
    }
  }

  /// Supprime tous les WebViews de viewports
  void clearAll() {
    for (final engine in _viewports.values) {
      engine.dispose();
    }
    _viewports.clear();
    notifyListeners();
  }

  /// Met à jour l'URL d'un viewport
  Future<void> updateViewportUrl(String viewportId, String url) async {
    final engine = _viewports[viewportId];
    if (engine != null) {
      await engine.navigate(url);
    }
  }

  /// Obtient le nombre de WebViews actifs
  int get activeViewportCount => _viewports.length;

  /// Vérifie si un viewport est actif
  bool isViewportActive(String viewportId) => _viewports.containsKey(viewportId);

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}

