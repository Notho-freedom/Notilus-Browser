import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'webview2_browser_engine.dart';
import 'browser_engine.dart';

/// Gestionnaire isolé pour les WebViews des side panels
/// N'interfère pas avec les tabs
class SideWebViewManager extends ChangeNotifier {
  final Map<String, BrowserEngine> _engines = {};
  
  /// Récupère ou crée le moteur pour un side panel
  BrowserEngine getEngineForPanel(String panelId) {
    if (!_engines.containsKey(panelId)) {
      BrowserEngine engine;
      
      // Utiliser WebView2 pour Windows
      if (Platform.isWindows) {
        engine = WebView2BrowserEngine();
      } else {
        // Pour les autres plateformes, utiliser un placeholder
        engine = PlaceholderBrowserEngine();
      }
      
      _engines[panelId] = engine;
      
      // Configurer les callbacks
      engine.onUrlChanged = (url) {
        notifyListeners();
      };
      
      engine.onTitleChanged = (title) {
        notifyListeners();
      };
      
      engine.onStateChanged = (state) {
        notifyListeners();
      };
      
      engine.onCanGoBackChanged = (canGoBack) {
        notifyListeners();
      };
      
      engine.onCanGoForwardChanged = (canGoForward) {
        notifyListeners();
      };
    }
    return _engines[panelId]!;
  }
  
  /// Supprime le moteur d'un panel
  void removeEngineForPanel(String panelId) {
    _engines.remove(panelId);
    notifyListeners();
  }
  
  /// Récupère le moteur d'un panel (peut être null)
  BrowserEngine? getEngine(String panelId) {
    return _engines[panelId];
  }
  
  /// Nettoie tous les moteurs
  void clearAll() {
    _engines.clear();
    notifyListeners();
  }
}

