import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'browser_engine.dart';
import 'webview2_browser_engine.dart';
import 'windows_browser_engine.dart';
import '../models/tab_model.dart';
import 'download_service.dart';
import 'studio/studio_service.dart';
import 'lighthouse/lighthouse_service.dart';

/// Gestionnaire qui associe chaque onglet à son moteur de rendu
/// Optimisé pour conserver les sessions et éviter les rechargements
class TabWebViewManager extends ChangeNotifier {
  DownloadService? _downloadService;
  StudioService? _studioService;
  LighthouseService? _lighthouseService;
  
  void setDownloadService(DownloadService service) {
    _downloadService = service;
  }
  
  void setStudioService(StudioService service) {
    _studioService = service;
  }
  
  void setLighthouseService(LighthouseService service) {
    _lighthouseService = service;
  }
  // Engines actifs (associés à des onglets ouverts)
  final Map<String, BrowserEngine> _activeEngines = {};
  
  // Cache d'engines (conservés même après fermeture d'onglet)
  // Clé: URL, Valeur: Engine avec cette URL chargée
  final Map<String, BrowserEngine> _cachedEngines = {};
  
  // Association tabId -> URL pour le cache
  final Map<String, String> _tabUrlMap = {};
  
  // Maximum d'engines en cache (pour limiter la mémoire)
  static const int _maxCachedEngines = 10;
  
  /// Récupère ou crée le moteur pour un onglet
  /// Réutilise un engine en cache si l'URL correspond
  BrowserEngine getEngineForTab(String tabId, {String? url}) {
    // Si l'onglet a déjà un engine actif, le retourner
    if (_activeEngines.containsKey(tabId)) {
      final engine = _activeEngines[tabId]!;
      // Si l'URL est fournie et différente, naviguer sans recréer
      if (url != null && url != _tabUrlMap[tabId]) {
        _tabUrlMap[tabId] = url;
        engine.navigate(url);
      }
      // S'assurer que les services sont attachés (au cas où ils n'étaient pas attachés avant)
      if (_studioService != null && _studioService!.engine != engine) {
        _studioService!.attachEngine(engine);
        final currentUrl = url ?? _tabUrlMap[tabId];
        if (currentUrl != null) {
          _studioService!.updateUrl(currentUrl);
        }
      }
      if (_lighthouseService != null && _lighthouseService!.engine != engine) {
        _lighthouseService!.attachEngine(engine);
        final currentUrl = url ?? _tabUrlMap[tabId];
        if (currentUrl != null) {
          _lighthouseService!.updateUrl(currentUrl);
        }
      }
      return engine;
    }
    
    BrowserEngine? engine;
    
    // Chercher dans le cache si une URL est fournie
    if (url != null && _cachedEngines.containsKey(url)) {
      engine = _cachedEngines[url];
      // Retirer du cache et mettre dans les actifs
      _cachedEngines.remove(url);
      _activeEngines[tabId] = engine!;
      _tabUrlMap[tabId] = url;
      debugPrint('✅ Réutilisation d\'un engine en cache pour $url');
      // Attacher les services
      if (_studioService != null) {
        _studioService!.attachEngine(engine);
        _studioService!.updateUrl(url);
      }
      if (_lighthouseService != null) {
        _lighthouseService!.attachEngine(engine);
        _lighthouseService!.updateUrl(url);
      }
      return engine;
    }
    
    // Créer un nouvel engine
    if (Platform.isWindows) {
      engine = WebView2BrowserEngine();
    } else {
      engine = BrowserEngineFactory.create();
    }
    
    _activeEngines[tabId] = engine;
    if (url != null) {
      _tabUrlMap[tabId] = url;
    }
    
    // Attacher les services Studio et Lighthouse au moteur
    if (_studioService != null) {
      _studioService!.attachEngine(engine);
      if (url != null) {
        _studioService!.updateUrl(url);
      }
    }
    if (_lighthouseService != null) {
      _lighthouseService!.attachEngine(engine);
      if (url != null) {
        _lighthouseService!.updateUrl(url);
      }
    }
    
    // Configurer les callbacks
    engine.onUrlChanged = (newUrl) {
      _tabUrlMap[tabId] = newUrl;
      // Mettre à jour les services Studio et Lighthouse
      if (_studioService != null) {
        _studioService!.updateUrl(newUrl);
      }
      if (_lighthouseService != null) {
        _lighthouseService!.updateUrl(newUrl);
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
    
    // Configurer l'interception des téléchargements et DevTools
    if (engine is WebView2BrowserEngine) {
      if (_downloadService != null) {
        engine.onDownloadRequested = (url, fileName) {
          debugPrint('📥 Téléchargement détecté: $url (${fileName ?? "sans nom"})');
          _downloadService!.addDownload(url, fileName: fileName);
        };
      }
      
    }
    
    return engine;
  }
  
  /// Supprime le moteur d'un onglet mais le conserve en cache
  void removeEngineForTab(String tabId, {bool keepInCache = true}) {
    final engine = _activeEngines.remove(tabId);
    final url = _tabUrlMap.remove(tabId);
    
    if (engine != null && url != null && keepInCache) {
      // Mettre en cache au lieu de supprimer
      _addToCache(url, engine);
      debugPrint('💾 Engine mis en cache pour $url');
    }
    
    notifyListeners();
  }
  
  /// Ajoute un engine au cache (avec limite de taille)
  void _addToCache(String url, BrowserEngine engine) {
    // Si le cache est plein, supprimer le plus ancien
    if (_cachedEngines.length >= _maxCachedEngines) {
      final firstKey = _cachedEngines.keys.first;
      _cachedEngines.remove(firstKey);
      debugPrint('🗑️ Engine retiré du cache (limite atteinte): $firstKey');
    }
    
    _cachedEngines[url] = engine;
  }
  
  /// Récupère le moteur d'un onglet (peut être null)
  BrowserEngine? getEngine(String tabId) {
    return _activeEngines[tabId];
  }
  
  /// Nettoie tous les moteurs (actifs et cache)
  void clearAll() {
    _activeEngines.clear();
    _cachedEngines.clear();
    _tabUrlMap.clear();
    notifyListeners();
  }
  
  /// Nettoie uniquement le cache (garde les engines actifs)
  void clearCache() {
    _cachedEngines.clear();
    notifyListeners();
  }
  
  /// Retourne le nombre d'engines en cache
  int get cacheSize => _cachedEngines.length;
  
  /// Retourne le nombre d'engines actifs
  int get activeEnginesCount => _activeEngines.length;

  /// Efface tous les cookies de tous les engines
  Future<void> clearAllCookies() async {
    for (final engine in _activeEngines.values) {
      if (engine is WebView2BrowserEngine) {
        await engine.clearCookies();
      }
    }
    for (final engine in _cachedEngines.values) {
      if (engine is WebView2BrowserEngine) {
        await engine.clearCookies();
      }
    }
  }

  /// Efface le cache de tous les engines
  Future<void> clearAllCache() async {
    for (final engine in _activeEngines.values) {
      if (engine is WebView2BrowserEngine) {
        await engine.clearCache();
      }
    }
    for (final engine in _cachedEngines.values) {
      if (engine is WebView2BrowserEngine) {
        await engine.clearCache();
      }
    }
    clearCache();
  }
}
