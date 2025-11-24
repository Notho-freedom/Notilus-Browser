import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'webview2_browser_engine.dart';
import 'browser_engine.dart';

/// Gestionnaire isolé pour les WebViews des side panels
/// Optimisé pour conserver les sessions par URL (pas par panelId)
/// N'interfère pas avec les tabs
class SideWebViewManager extends ChangeNotifier {
  // Engines indexés par URL (pour réutilisation)
  final Map<String, BrowserEngine> _enginesByUrl = {};
  
  // Association panelId -> URL
  final Map<String, String> _panelUrlMap = {};
  
  // Engines actuellement utilisés par des panels
  final Map<String, BrowserEngine> _activeEngines = {};
  
  /// Récupère ou crée le moteur pour un side panel
  /// Réutilise l'engine si l'URL existe déjà (évite les rechargements)
  BrowserEngine getEngineForPanel(String panelId, String url) {
    // Si le panel a déjà un engine actif pour cette URL, le retourner
    if (_activeEngines.containsKey(panelId)) {
      final engine = _activeEngines[panelId]!;
      final currentUrl = _panelUrlMap[panelId];
      
      // Si l'URL est la même, ne pas recharger
      if (currentUrl == url) {
        debugPrint('✅ Réutilisation de l\'engine existant pour $url');
        return engine;
      }
      
      // Si l'URL change, naviguer sans recréer
      _panelUrlMap[panelId] = url;
      engine.navigate(url);
      return engine;
    }
    
    BrowserEngine engine;
    
    // Chercher si un engine existe déjà pour cette URL
    if (_enginesByUrl.containsKey(url)) {
      engine = _enginesByUrl[url]!;
      debugPrint('✅ Réutilisation d\'un engine en cache pour $url');
    } else {
      // Créer un nouvel engine
      if (Platform.isWindows) {
        engine = WebView2BrowserEngine();
      } else {
        engine = PlaceholderBrowserEngine();
      }
      
      _enginesByUrl[url] = engine;
      debugPrint('🆕 Nouvel engine créé pour $url');
      
      // Configurer les callbacks pour le nouvel engine
      engine.onUrlChanged = (newUrl) {
        // Mettre à jour la map si l'URL change
        if (_enginesByUrl.containsKey(url)) {
          _enginesByUrl.remove(url);
          _enginesByUrl[newUrl] = engine;
        }
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
    
    _activeEngines[panelId] = engine;
    _panelUrlMap[panelId] = url;
    
    return engine;
  }
  
  /// Supprime l'association panel -> engine mais conserve l'engine
  /// L'engine reste disponible pour réutilisation
  void removeEngineForPanel(String panelId, {bool keepEngine = true}) {
    final url = _panelUrlMap.remove(panelId);
    _activeEngines.remove(panelId);
    
    // L'engine reste dans _enginesByUrl pour réutilisation future
    // On ne le supprime que si keepEngine = false
    if (!keepEngine && url != null) {
      _enginesByUrl.remove(url);
      debugPrint('🗑️ Engine supprimé pour $url');
    } else if (url != null) {
      debugPrint('💾 Engine conservé pour réutilisation future: $url');
    }
    
    notifyListeners();
  }
  
  /// Récupère le moteur d'un panel (peut être null)
  BrowserEngine? getEngine(String panelId) {
    return _activeEngines[panelId];
  }
  
  /// Récupère un engine par URL (pour réutilisation)
  BrowserEngine? getEngineByUrl(String url) {
    return _enginesByUrl[url];
  }
  
  /// Nettoie tous les moteurs
  void clearAll() {
    _enginesByUrl.clear();
    _activeEngines.clear();
    _panelUrlMap.clear();
    notifyListeners();
  }
  
  /// Nettoie uniquement les engines non utilisés
  void clearUnusedEngines() {
    final usedUrls = _panelUrlMap.values.toSet();
    _enginesByUrl.removeWhere((url, engine) => !usedUrls.contains(url));
    notifyListeners();
  }
  
  /// Retourne le nombre d'engines en cache
  int get cacheSize => _enginesByUrl.length;
  
  /// Retourne le nombre d'engines actifs
  int get activeEnginesCount => _activeEngines.length;
}

