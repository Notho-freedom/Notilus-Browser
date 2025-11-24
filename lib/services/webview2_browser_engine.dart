import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:webview_windows/webview_windows.dart';
import 'browser_engine.dart';
import '../models/tab_model.dart';

/// Implémentation réelle du moteur de rendu avec WebView2 (Option #1 - Production-ready)
/// WebView2 est le moteur moderne de Microsoft basé sur Chromium
/// 
/// API mise à jour pour webview_windows 0.2.2+
class WebView2BrowserEngine extends BrowserEngine {
  WebviewController? _webView;
  String? _currentUrl;
  String? _currentTitle;
  bool _canGoBack = false;
  bool _canGoForward = false;
  
  @override
  Function(String)? onUrlChanged;
  
  @override
  Function(String)? onTitleChanged;
  
  @override
  Function(bool)? onCanGoBackChanged;
  
  @override
  Function(bool)? onCanGoForwardChanged;
  
  @override
  Function(dynamic)? onStateChanged; // TabState
  
  @override
  Function(String)? onNewWindowRequest;

  bool _isInitialized = false;
  Timer? _newWindowPollingTimer;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _webView = WebviewController();
      await _webView!.initialize();
      _isInitialized = true;
      
      // Configurer les callbacks WebView2 via les streams
      _webView!.url.listen((url) {
        _currentUrl = url;
        onStateChanged?.call(TabState.loaded);
        onUrlChanged?.call(url);
        
        // Injecter le handler pour les nouvelles fenêtres après chaque navigation
        if (onNewWindowRequest != null && url.isNotEmpty && url != 'about:blank') {
          Future.delayed(const Duration(milliseconds: 1500), () async {
            try {
              await _webView!.executeScript('''
                (function() {
                  // Intercepter les clics sur les liens target="_blank"
                  var handler = function(e) {
                    var target = e.target;
                    while (target && target.tagName !== 'A') {
                      target = target.parentElement;
                    }
                    if (target && (target.target === '_blank' || target.getAttribute('target') === '_blank')) {
                      e.preventDefault();
                      e.stopPropagation();
                      // Stocker l'URL dans un attribut data pour récupération
                      if (document.body) {
                        document.body.setAttribute('data-new-window-url', target.href);
                      }
                      return false;
                    }
                  };
                  // Supprimer l'ancien handler s'il existe
                  if (window._flutterNewWindowHandler) {
                    document.removeEventListener('click', window._flutterNewWindowHandler, true);
                  }
                  window._flutterNewWindowHandler = handler;
                  document.addEventListener('click', handler, true);
                })();
              ''');
              
              // Démarrer le polling pour détecter les nouvelles fenêtres
              _startNewWindowPolling();
            } catch (e) {
              debugPrint('Error injecting new window handler: $e');
            }
          });
        }
      });
      
      _webView!.title.listen((title) {
        if (title.isNotEmpty) {
          _currentTitle = title;
          onTitleChanged?.call(title);
        }
      });
      
      // Gérer les états de chargement
      _webView!.loadingState.listen((state) {
        if (state == LoadingState.loading) {
          onStateChanged?.call(TabState.loading);
        } else if (state == LoadingState.navigationCompleted) {
          onStateChanged?.call(TabState.loaded);
        }
      });
      
      // Gérer l'historique (API moderne)
      _webView!.historyChanged.listen((history) {
        _canGoBack = history.canGoBack;
        _canGoForward = history.canGoForward;
        onCanGoBackChanged?.call(_canGoBack);
        onCanGoForwardChanged?.call(_canGoForward);
      });
      
      // Gérer les erreurs de chargement
      _webView!.onLoadError.listen((error) {
        onStateChanged?.call(TabState.error);
      });
      
      // Gérer les nouvelles fenêtres (liens target="_blank")
      // webview_windows n'a pas onNewWindowRequest, on utilise une injection JavaScript
      // L'injection sera faite après chaque navigation dans la méthode navigate()
      
    } catch (e) {
      debugPrint('WebView2 initialization error: $e');
    }
  }

  @override
  Future<void> navigate(String url) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Optimisation : ne pas recharger si l'URL est déjà chargée
    if (_currentUrl == url && _webView != null) {
      debugPrint('✅ URL déjà chargée, pas de rechargement: $url');
      return;
    }
    
    if (_webView != null) {
      onStateChanged?.call(TabState.loading);
      onUrlChanged?.call(url);
      
      try {
        await _webView!.loadUrl(url);
      } catch (e) {
        debugPrint('Navigation error: $e');
        onStateChanged?.call(TabState.error);
      }
    }
  }

  @override
  Future<void> goBack() async {
    if (_webView != null) {
      try {
        // Vérifier si on peut revenir en arrière
        final canBack = await _getCanGoBack();
        if (canBack) {
          await _webView!.goBack();
        }
      } catch (e) {
        debugPrint('goBack error: $e');
      }
    }
  }

  @override
  Future<void> goForward() async {
    if (_webView != null) {
      try {
        // Vérifier si on peut avancer
        final canForward = await _getCanGoForward();
        if (canForward) {
          await _webView!.goForward();
        }
      } catch (e) {
        debugPrint('goForward error: $e');
      }
    }
  }

  @override
  Future<void> reload() async {
    if (_webView != null) {
      try {
        await _webView!.reload();
      } catch (e) {
        debugPrint('reload error: $e');
      }
    }
  }

  @override
  Future<void> stop() async {
    if (_webView != null) {
      try {
        await _webView!.stop();
      } catch (e) {
        debugPrint('stop error: $e');
      }
    }
  }

  @override
  Future<bool> canGoBack() async {
    return await _getCanGoBack();
  }

  @override
  Future<bool> canGoForward() async {
    return await _getCanGoForward();
  }

  /// Méthode helper pour récupérer canGoBack (API moderne)
  Future<bool> _getCanGoBack() async {
    if (_webView == null) return _canGoBack;
    // L'état est mis à jour via le stream historyChanged
    // On retourne la valeur courante
    return _canGoBack;
  }

  /// Méthode helper pour récupérer canGoForward (API moderne)
  Future<bool> _getCanGoForward() async {
    if (_webView == null) return _canGoForward;
    // L'état est mis à jour via le stream historyChanged
    // On retourne la valeur courante
    return _canGoForward;
  }

  @override
  Future<String?> getCurrentUrl() async {
    // L'URL est mise à jour via le stream url
    return _currentUrl;
  }

  @override
  Future<String?> getTitle() async {
    // Le titre est mis à jour via le stream title
    return _currentTitle;
  }

  @override
  Future<String?> executeJavaScript(String script) async {
    if (_webView == null) return null;
    try {
      // API webview_windows 0.2.2 : executeScript
      await _webView!.executeScript(script);
      return 'executed';
    } catch (e) {
      debugPrint('JavaScript execution error: $e');
      return null;
    }
  }

  @override
  Future<dynamic> evaluateJavaScript(String script) async {
    if (_webView == null) return null;
    try {
      // API webview_windows 0.2.2 : executeScript retourne le résultat
      final result = await _webView!.executeScript(script);
      return result;
    } catch (e) {
      debugPrint('JavaScript evaluation error: $e');
      return null;
    }
  }

  @override
  Future<dynamic> getController() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _webView;
  }

  /// Démarre le polling pour détecter les nouvelles fenêtres
  void _startNewWindowPolling() {
    _newWindowPollingTimer?.cancel();
    _newWindowPollingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkForNewWindowRequests();
    });
  }
  
  /// Arrête le polling
  void _stopNewWindowPolling() {
    _newWindowPollingTimer?.cancel();
    _newWindowPollingTimer = null;
  }
  
  /// Vérifie périodiquement si une nouvelle fenêtre a été demandée
  /// (utilisé comme fallback si onNewWindowRequest n'est pas disponible)
  Future<void> _checkForNewWindowRequests() async {
    if (_webView == null || onNewWindowRequest == null) return;
    
    try {
      // Vérifier si une URL a été stockée dans l'attribut data
      final result = await _webView!.executeScript('''
        (function() {
          if (!document.body) return null;
          var url = document.body.getAttribute('data-new-window-url');
          if (url) {
            document.body.removeAttribute('data-new-window-url');
            return url;
          }
          return null;
        })();
      ''');
      
      if (result != null && result is String && result.isNotEmpty) {
        debugPrint('Nouvelle fenêtre détectée via JavaScript: $result');
        onNewWindowRequest?.call(result);
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  void dispose() {
    _stopNewWindowPolling();
    _webView?.dispose();
    _webView = null;
  }
}
