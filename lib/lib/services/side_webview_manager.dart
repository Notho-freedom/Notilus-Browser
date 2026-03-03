import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'webview2_browser_engine.dart';
import 'browser_engine.dart';

/// Gestionnaire isolé pour les WebViews des side panels
/// Optimisé pour conserver les sessions persistantes avec cache LRU
/// Les engines ne sont JAMAIS détruits sauf cleanup explicite
/// N'interfère pas avec les tabs
class SideWebViewManager extends ChangeNotifier {
  // Cache des engines PERSISTANTS (ne sont JAMAIS détruits sauf clear explicite)
  final Map<String, BrowserEngine> _persistentEngines = {};
  
  // Limite du nombre d'engines en cache (éviter fuite mémoire)
  static const int _maxPersistentEngines = 10;
  
  // Ordre d'utilisation pour LRU (Least Recently Used)
  final List<String> _accessOrder = [];
  
  // Association panelId -> URL (pour tracking)
  final Map<String, String> _panelUrlMap = {};
  
  /// Récupère ou crée un engine persistant pour un panel
  /// L'engine reste en mémoire même quand le panel est fermé
  /// Utilise un cache LRU pour limiter la mémoire
  BrowserEngine getOrCreatePersistentEngine(String panelId, String url) {
    if (!Platform.isWindows) {
      throw UnsupportedError('WebView2 uniquement supporté sur Windows');
    }
    
    // Si l'engine existe déjà pour ce panelId, le réutiliser
    if (_persistentEngines.containsKey(panelId)) {
      debugPrint('♻️  Réutilisation engine existant: $panelId');
      _updateAccessOrder(panelId);
      _panelUrlMap[panelId] = url;
      return _persistentEngines[panelId]!;
    }
    
    // Vérifier la limite du cache
    if (_persistentEngines.length >= _maxPersistentEngines) {
      _evictLeastRecentlyUsed();
    }
    
    // Créer un nouvel engine
    debugPrint('🆕 Création nouvel engine persistant: $panelId pour $url');
    final engine = WebView2BrowserEngine();
    
    _persistentEngines[panelId] = engine;
    _panelUrlMap[panelId] = url;
    _updateAccessOrder(panelId);
    
    // Configurer les callbacks
    engine.onUrlChanged = (newUrl) {
      _panelUrlMap[panelId] = newUrl;
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
    
    notifyListeners();
    return engine;
  }
  
  /// Récupère ou crée le moteur pour un side panel (méthode legacy, utilise getOrCreatePersistentEngine)
  /// Réutilise l'engine si l'URL existe déjà (évite les rechargements)
  BrowserEngine getEngineForPanel(String panelId, String url) {
    return getOrCreatePersistentEngine(panelId, url);
  }
  
  /// Récupère un engine existant (ou null)
  BrowserEngine? getEngine(String panelId) {
    if (_persistentEngines.containsKey(panelId)) {
      _updateAccessOrder(panelId);
    }
    return _persistentEngines[panelId];
  }
  
  /// Supprime un engine du cache (vraie destruction)
  Future<void> destroyEngine(String panelId) async {
    final engine = _persistentEngines.remove(panelId);
    _accessOrder.remove(panelId);
    _panelUrlMap.remove(panelId);
    
    if (engine != null) {
      try {
        engine.dispose();
        debugPrint('🗑️ Engine détruit: $panelId');
      } catch (e) {
        debugPrint('❌ Erreur destruction engine: $e');
      }
    }
    
    notifyListeners();
  }
  
  /// Supprime l'association panel -> engine mais conserve l'engine (legacy)
  /// L'engine reste disponible pour réutilisation
  void removeEngineForPanel(String panelId, {bool keepEngine = true}) {
    if (!keepEngine) {
      destroyEngine(panelId);
    } else {
      debugPrint('💾 Engine conservé pour réutilisation future: $panelId');
    }
  }
  
  /// Vide tout le cache (cleanup complet)
  Future<void> clearAllEngines() async {
    debugPrint('🧹 Nettoyage de tous les engines persistants (${_persistentEngines.length})');
    
    final engines = List<BrowserEngine>.from(_persistentEngines.values);
    _persistentEngines.clear();
    _accessOrder.clear();
    _panelUrlMap.clear();
    
    for (final engine in engines) {
      try {
        engine.dispose();
      } catch (e) {
        debugPrint('❌ Erreur destruction: $e');
      }
    }
    
    notifyListeners();
  }
  
  /// Nettoie tous les moteurs (alias pour clearAllEngines)
  void clearAll() {
    clearAllEngines();
  }
  
  /// Nettoie uniquement les engines non utilisés (non utilisé avec le nouveau système)
  void clearUnusedEngines() {
    // Avec le système LRU, tous les engines sont potentiellement utilisés
    // On évite automatiquement les moins récemment utilisés
    debugPrint('ℹ️ clearUnusedEngines: Utilisez clearAllEngines() pour nettoyer manuellement');
  }
  
  /// Met à jour l'ordre d'accès (LRU)
  void _updateAccessOrder(String panelId) {
    _accessOrder.remove(panelId);
    _accessOrder.add(panelId);
  }
  
  /// Supprime l'engine le moins récemment utilisé
  void _evictLeastRecentlyUsed() {
    if (_accessOrder.isEmpty) return;
    
    final lruPanelId = _accessOrder.first;
    debugPrint('🗑️  Éviction LRU: $lruPanelId');
    destroyEngine(lruPanelId);
  }
  
  /// Stats pour debug
  String getStats() {
    return '''
📊 Stats SideWebViewManager:
   - Engines actifs: ${_persistentEngines.length}/$_maxPersistentEngines
   - Ordre accès: ${_accessOrder.join(', ')}
''';
  }
  
  /// Retourne le nombre d'engines en cache
  int get cacheSize => _persistentEngines.length;
  
  /// Retourne le nombre d'engines actifs (alias pour cacheSize)
  int get activeEnginesCount => _persistentEngines.length;
  
  @override
  void dispose() {
    // Cleanup complet au dispose du manager
    for (final engine in _persistentEngines.values) {
      try {
        engine.dispose();
      } catch (e) {
        debugPrint('Erreur dispose engine: $e');
      }
    }
    _persistentEngines.clear();
    _accessOrder.clear();
    _panelUrlMap.clear();
    super.dispose();
  }
}

