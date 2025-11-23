import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'browser_engine.dart';
import 'webview2_browser_engine.dart';
import 'windows_browser_engine.dart';
import '../models/tab_model.dart';

/// Gestionnaire qui associe chaque onglet à son moteur de rendu
class TabWebViewManager extends ChangeNotifier {
  final Map<String, BrowserEngine> _engines = {};
  
  /// Récupère ou crée le moteur pour un onglet
  BrowserEngine getEngineForTab(String tabId) {
    if (!_engines.containsKey(tabId)) {
      BrowserEngine engine;
      
      // Sélectionner le moteur selon la plateforme
      if (Platform.isWindows) {
        // Utiliser WebView2 pour Windows (Option #1 - Production-ready)
        engine = WebView2BrowserEngine();
      } else {
        // Pour les autres plateformes, utiliser le factory
        engine = BrowserEngineFactory.create();
      }
      
      _engines[tabId] = engine;
      
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
    return _engines[tabId]!;
  }
  
  /// Supprime le moteur d'un onglet
  void removeEngineForTab(String tabId) {
    _engines.remove(tabId);
    notifyListeners();
  }
  
  /// Récupère le moteur d'un onglet (peut être null)
  BrowserEngine? getEngine(String tabId) {
    return _engines[tabId];
  }
  
  /// Nettoie tous les moteurs
  void clearAll() {
    _engines.clear();
    notifyListeners();
  }
}
