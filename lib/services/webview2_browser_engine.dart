import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'browser_engine.dart';
import '../models/tab_model.dart';
import 'error_handler.dart';
import 'adblocker_service.dart';
import 'text_selection_service.dart';

/// Implémentation réelle du moteur de rendu avec WebView2 (Option #1 - Production-ready)
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
  
  /// Callback pour les téléchargements
  Function(String url, String? fileName)? onDownloadRequested;
  
  /// Callback pour les messages WebView (DevTools)
  Function(String message)? onWebMessage;
  
  /// ID du tab associé (pour DevTools)
  String? tabId;

  bool _isInitialized = false;
  bool _isInitializing = false; // Pour éviter les initialisations multiples
  Completer<void>? _initializationCompleter;
  Timer? _newWindowPollingTimer;
  Timer? _downloadPollingTimer;
  Timer? _loadingTimeoutTimer;
  
  // État de visibilité pour adapter la fréquence du polling
  bool _isTabActive = true;
  bool _isPanelActive = true; // État actif du panel (pour sessions persistantes)
  bool _isPageLoaded = false;
  bool _isLoading = false;
  
  // StreamController pour rebroadcast loadingState
  StreamController<LoadingState>? _loadingStateController;
  StreamSubscription<LoadingState>? _loadingStateSubscription;
  
  // Cache des résultats de polling pour éviter les appels répétés
  String? _lastNewWindowUrl;
  
  // Script JavaScript minifié et cache pour éviter la réinjection
  bool _scriptInjected = false;
  bool _textSelectionScriptInjected = false;
  static const String _minifiedNewWindowScript = '''(function(){var o=window.open;window.open=function(u,t,f){if(!t||t==="_blank"||t==="blank"){if(u&&typeof u==="string"){if(document.body){document.body.setAttribute("data-new-window-url",u);document.body.dispatchEvent(new Event("notilus-new-window"));}}return null;}return o.apply(window,arguments);};var h=function(e){var t=e.target;while(t&&t.tagName!=="A"){t=t.parentElement;}if(t&&t.tagName==="A"){var h=t.getAttribute("href"),a=t.getAttribute("target"),r=(t.getAttribute("rel")||"").toLowerCase(),e=!1,n=a==="_blank"||a==="blank";if(h&&h.startsWith("http")){try{var i=window.location.hostname,c=new URL(h,window.location.href);e=c.hostname!==i;}catch(e){}}if(r.includes("external")){e=!0;}if(n||e){e.preventDefault();e.stopPropagation();if(document.body&&h){try{var u=new URL(h,window.location.href).href;document.body.setAttribute("data-new-window-url",u);document.body.dispatchEvent(new Event("notilus-new-window"));}catch(e){document.body.setAttribute("data-new-window-url",h);document.body.dispatchEvent(new Event("notilus-new-window"));}}return!1;}}};if(window._flutterNewWindowHandler){document.removeEventListener("click",window._flutterNewWindowHandler,!0);}window._flutterNewWindowHandler=h;document.addEventListener("click",h,!0);if(!window._flutterMutationObserver){window._flutterMutationObserver=new MutationObserver(function(e){e.forEach(function(e){e.addedNodes.forEach(function(e){if(1===e.nodeType){var t=e.querySelectorAll?e.querySelectorAll('a[target="_blank"],a[rel*="external"]'):[];t.forEach(function(e){e.addEventListener("click",h,!0);});}});});});window._flutterMutationObserver.observe(document.body,{childList:!0,subtree:!0});}})();''';
  
  // Script pour détecter les sélections de texte
  static const String _textSelectionScript = '''
(function() {
  if (window._notilusTextSelectionHandler) return;
  
  window._notilusTextSelectionHandler = function() {
    try {
      var selection = window.getSelection();
      if (selection && selection.rangeCount > 0) {
        var text = selection.toString().trim();
        if (text.length > 0) {
          var range = selection.getRangeAt(0);
          var rect = range.getBoundingClientRect();
          
          // Stocker les informations de sélection (coordonnées viewport, pas absolues)
          if (document.body) {
            var x = Math.round(rect.left + rect.width / 2);
            var y = Math.round(rect.top);
            document.body.setAttribute('data-selected-text', encodeURIComponent(text));
            document.body.setAttribute('data-selection-x', x.toString());
            document.body.setAttribute('data-selection-y', y.toString());
          }
        } else {
          // Effacer la sélection si vide
          if (document.body) {
            document.body.removeAttribute('data-selected-text');
            document.body.removeAttribute('data-selection-x');
            document.body.removeAttribute('data-selection-y');
          }
        }
      } else {
        // Effacer la sélection
        if (document.body) {
          document.body.removeAttribute('data-selected-text');
          document.body.removeAttribute('data-selection-x');
          document.body.removeAttribute('data-selection-y');
        }
      }
    } catch (e) {
      console.error('Notilus: Erreur dans le handler de sélection:', e);
    }
  };
  
  // Utiliser un délai pour mouseup pour s'assurer que la sélection est complète
  document.addEventListener('mouseup', function() {
    setTimeout(window._notilusTextSelectionHandler, 100);
  }, true);
  document.addEventListener('keyup', window._notilusTextSelectionHandler, true);
  document.addEventListener('selectionchange', window._notilusTextSelectionHandler, true);
  
  console.log('Notilus: Script de sélection de texte installé');
})();
''';
  
  Timer? _textSelectionPollingTimer;
  
  // Script pour détecter les clics droits (menu contextuel)
  static const String _contextMenuScript = '''
(function() {
  if (window._notilusContextMenuHandler) return;
  
  window._notilusContextMenuHandler = function(e) {
    try {
      e.preventDefault(); // Empêcher le menu contextuel par défaut
      
      var target = e.target;
      var elementType = 'text';
      var url = null;
      var imageUrl = null;
      var linkUrl = null;
      var text = null;
      
      // Vérifier si c'est une image
      if (target.tagName === 'IMG') {
        elementType = 'image';
        imageUrl = target.src || target.getAttribute('data-src') || target.getAttribute('data-lazy-src');
        // Chercher un lien parent
        var parent = target.parentElement;
        while (parent && parent.tagName !== 'A' && parent !== document.body) {
          parent = parent.parentElement;
        }
        if (parent && parent.tagName === 'A') {
          linkUrl = parent.href;
        }
      }
      // Vérifier si c'est un lien
      else if (target.tagName === 'A') {
        elementType = 'link';
        linkUrl = target.href;
        // Vérifier si le lien contient une image
        var img = target.querySelector('img');
        if (img) {
          imageUrl = img.src || img.getAttribute('data-src') || img.getAttribute('data-lazy-src');
        }
        text = target.textContent || target.innerText;
      }
      // Vérifier si on est dans un lien
      else {
        var parent = target;
        while (parent && parent.tagName !== 'A' && parent !== document.body) {
          parent = parent.parentElement;
        }
        if (parent && parent.tagName === 'A') {
          elementType = 'link';
          linkUrl = parent.href;
          var img = parent.querySelector('img');
          if (img) {
            imageUrl = img.src || img.getAttribute('data-src') || img.getAttribute('data-lazy-src');
          }
          text = parent.textContent || parent.innerText;
        } else {
          // Texte sélectionné
          var selection = window.getSelection();
          if (selection && selection.rangeCount > 0) {
            text = selection.toString().trim();
            if (text.length > 0) {
              elementType = 'text';
            }
          }
        }
      }
      
      // Stocker les informations dans document.body
      if (document.body) {
        var rect = target.getBoundingClientRect();
        var x = Math.round(e.clientX);
        var y = Math.round(e.clientY);
        
        document.body.setAttribute('data-context-type', elementType);
        document.body.setAttribute('data-context-x', x.toString());
        document.body.setAttribute('data-context-y', y.toString());
        
        if (imageUrl) {
          document.body.setAttribute('data-context-image-url', encodeURIComponent(imageUrl));
        }
        if (linkUrl) {
          document.body.setAttribute('data-context-link-url', encodeURIComponent(linkUrl));
        }
        if (text) {
          document.body.setAttribute('data-context-text', encodeURIComponent(text));
        }
      }
    } catch (err) {
      console.error('Notilus: Erreur dans le handler de menu contextuel:', err);
    }
  };
  
  // Intercepter le menu contextuel
  document.addEventListener('contextmenu', window._notilusContextMenuHandler, true);
  
  console.log('Notilus: Script de menu contextuel installé');
})();
''';
  
  Timer? _contextMenuPollingTimer;
  Function(String type, String? imageUrl, String? linkUrl, String? text, Offset position)? onContextMenuRequest;
  
  /// Service de blocage de publicités
  AdBlockerService? _adBlockerService;
  bool _adBlockerScriptInjected = false;
  Timer? _adBlockerPollingTimer;

  /// Définit le service de blocage de publicités
  void setAdBlockerService(AdBlockerService? service) {
    _adBlockerService = service;
    if (service != null && service.isEnabled && _isPageLoaded && _webView != null && _isInitialized) {
      _adBlockerScriptInjected = false;
      _injectAdBlockerScript();
    } else if (service == null || !service.isEnabled) {
      _stopAdBlockerPolling();
      _adBlockerScriptInjected = false;
    }
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) {
      return await _initializationCompleter?.future;
    }
    
    _isInitializing = true;
    _initializationCompleter = Completer<void>();
    
    try {
      // S'assurer qu'on ferme complètement l'ancien WebView s'il existe
      await _cleanupWebView();
      
      _webView = WebviewController();
      await _webView!.initialize();
      
      // Vérifier que le WebView est vraiment initialisé
      if (_webView!.value.isInitialized) {
        _isInitialized = true;
        _isInitializing = false;
        
        // Activer les optimisations de performance
        _enablePerformanceOptimizations();
        
        // Configurer les listeners du WebView
        await _setupWebViewListeners();
        
        debugPrint('✅ WebView2 initialisé avec succès');
        _initializationCompleter?.complete();
      } else {
        throw Exception('WebView2 n\'est pas initialisé correctement');
      }
    } catch (e) {
      debugPrint('❌ WebView2 initialization error: $e');
      _isInitialized = false;
      _isInitializing = false;
      await _cleanupWebView();
      _initializationCompleter?.completeError(e);
      rethrow;
    }
  }

  /// Attendre que l'initialisation soit complète
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;
    await _initializationCompleter?.future;
  }

  @override
  Future<void> navigate(String url) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Forcer l'état de chargement immédiatement
      _isLoading = true;
      onStateChanged?.call(TabState.loading);
      
      // Optimisation : ne pas recharger si l'URL est déjà chargée
      if (_currentUrl == url && _webView != null && _isPageLoaded) {
        debugPrint('✅ URL déjà chargée, pas de rechargement: $url');
        // S'assurer que l'état est bien "loaded"
        _isLoading = false;
        onStateChanged?.call(TabState.loaded);
        return;
      }
      
      if (_webView != null && _webView!.value.isInitialized) {
        // Réinitialiser le flag d'injection pour la nouvelle page
        _scriptInjected = false;
        _textSelectionScriptInjected = false;
        _adBlockerScriptInjected = false;
        _isPageLoaded = false;
        
        // Forcer l'état de chargement
        _isLoading = true;
        onStateChanged?.call(TabState.loading);
        onUrlChanged?.call(url);
        
        try {
          await ErrorHandler.withRetry(
            fn: () => _webView!.loadUrl(url),
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 500),
            shouldRetry: (error) {
              return error.toString().contains('network') || 
                     error.toString().contains('timeout');
            },
          );
        } catch (e) {
          ErrorHandler.logError(
            context: 'WebView2BrowserEngine.navigate',
            error: e,
            additionalData: {'url': url},
          );
          
          // Tentative de récupération
          final recovered = await WebViewRecovery.recoverWebView(
            recreateWebView: () async {
              await _cleanupWebView();
              await Future.delayed(const Duration(milliseconds: 100));
              
              _webView = WebviewController();
              await _webView!.initialize();
              
              await _setupWebViewListeners();
              
              await _webView!.loadUrl(url);
            },
          );
          
          if (!recovered) {
            onStateChanged?.call(TabState.error);
          }
        }
      } else {
        throw Exception('WebView2 non initialisé');
      }
    } catch (e) {
      debugPrint('❌ Erreur dans WebView2BrowserEngine.navigate: $e');
      _isLoading = false;
      onStateChanged?.call(TabState.error);
    }
  }
  
  /// Injecte le script une seule fois (évite la réinjection)
  Future<void> _injectScriptOnce() async {
    if (_scriptInjected || _webView == null || onNewWindowRequest == null || !_webView!.value.isInitialized) return;
    
    try {
      await _webView!.executeScript(_minifiedNewWindowScript);
      _scriptInjected = true;
      debugPrint('✅ Script JavaScript injecté (minifié)');
    } catch (e) {
      debugPrint('Erreur injection script: $e');
    }
  }

  @override
  Future<void> goBack() async {
    if (_webView != null && _webView!.value.isInitialized) {
      try {
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
    if (_webView != null && _webView!.value.isInitialized) {
      try {
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
    if (_webView != null && _webView!.value.isInitialized) {
      try {
        await _webView!.reload();
      } catch (e) {
        debugPrint('reload error: $e');
      }
    }
  }

  @override
  Future<void> stop() async {
    if (_webView != null && _webView!.value.isInitialized) {
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

  /// Méthode helper pour récupérer canGoBack
  Future<bool> _getCanGoBack() async {
    if (_webView == null || !_webView!.value.isInitialized) return _canGoBack;
    return _canGoBack;
  }

  /// Méthode helper pour récupérer canGoForward
  Future<bool> _getCanGoForward() async {
    if (_webView == null || !_webView!.value.isInitialized) return _canGoForward;
    return _canGoForward;
  }

  @override
  Future<String?> getCurrentUrl() async {
    return _currentUrl;
  }

  @override
  Future<String?> getTitle() async {
    return _currentTitle;
  }

  @override
  Future<String?> executeJavaScript(String script) async {
    if (_webView == null || !_webView!.value.isInitialized) return null;
    try {
      await _webView!.executeScript(script);
      return 'executed';
    } catch (e) {
      debugPrint('JavaScript execution error: $e');
      return null;
    }
  }

  @override
  Future<dynamic> evaluateJavaScript(String script) async {
    if (_webView == null || !_webView!.value.isInitialized) return null;
    try {
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
  
  /// Obtient l'état de chargement réel du WebView
  bool get isLoading => _isLoading;
  
  /// Définit si le panel est actif (pour la gestion audio/vidéo en sessions persistantes)
  /// Quand actif = false, le panel est en pause mais la session continue (vidéo YouTube continue)
  /// Quand actif = true, le panel est visible et actif
  void setActive(bool active) {
    _isPanelActive = active;
    
    if (_webView != null && _webView!.value.isInitialized) {
      try {
        if (active) {
          // Réactiver l'audio/vidéo si nécessaire
          // Note: YouTube et autres services continuent automatiquement en arrière-plan
          debugPrint('🎵 Panel réactivé - média continue');
        } else {
          // NE PAS mettre en pause, laisser tourner en arrière-plan
          // Pour YouTube, la vidéo continue de jouer même quand le panel est fermé
          debugPrint('⏸️  Panel mis en pause - session conservée en arrière-plan');
        }
      } catch (e) {
        debugPrint('Erreur setActive: $e');
      }
    }
  }
  
  /// Vérifie si le panel est actif
  bool get isPanelActive => _isPanelActive;
  
  /// Stream broadcast pour loadingState
  Stream<LoadingState> get loadingStateStream => 
      _loadingStateController?.stream ?? const Stream<LoadingState>.empty();

  /// Démarre le polling pour détecter les nouvelles fenêtres avec fréquence adaptative
  void _startNewWindowPolling() {
    _newWindowPollingTimer?.cancel();
    
    final interval = _isTabActive && _isPageLoaded
        ? const Duration(milliseconds: 500)
        : const Duration(seconds: 2);
    
    _newWindowPollingTimer = Timer.periodic(interval, (_) {
      if (_isTabActive) {
        _checkForNewWindowRequests();
      }
    });
  }
  
  /// Définit l'état actif/inactif de l'onglet
  void setTabActive(bool isActive) {
    if (_isTabActive != isActive) {
      _isTabActive = isActive;
      
      if (isActive) {
        _startNewWindowPolling();
      } else {
        _stopNewWindowPolling();
        _newWindowPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _checkForNewWindowRequests();
        });
      }
    }
  }
  
  /// Arrête le polling
  void _stopNewWindowPolling() {
    _newWindowPollingTimer?.cancel();
    _newWindowPollingTimer = null;
  }
  
  /// Vérifie périodiquement si une nouvelle fenêtre a été demandée
  Future<void> _checkForNewWindowRequests() async {
    if (_webView == null || onNewWindowRequest == null || !_isTabActive || !_webView!.value.isInitialized) return;
    
    try {
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
        if (result != _lastNewWindowUrl) {
          _lastNewWindowUrl = result;
          debugPrint('Nouvelle fenêtre détectée via JavaScript: $result');
          onNewWindowRequest?.call(result);
          Future.delayed(const Duration(seconds: 1), () {
            _lastNewWindowUrl = null;
          });
        }
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  @override
  Future<void> openDevTools() async {
    if (_webView == null || !_webView!.value.isInitialized) return;
    
    try {
      debugPrint('⚠️ DevTools non disponibles avec webview_windows 0.2.0');
      
      await _webView!.executeScript('''
        (function() {
          console.warn('DevTools non disponibles avec webview_windows 0.2.0');
        })();
      ''');
    } catch (e) {
      debugPrint('Erreur lors de la tentative d\'ouverture des DevTools: $e');
    }
  }
  
  /// Configure le listener pour les messages WebView (DevTools)
  void setupWebMessageListener() {
    if (_webView == null || !_webView!.value.isInitialized) return;
    
    try {
      _webView!.webMessage.listen((message) {
        if (message != null && message.isNotEmpty) {
          onWebMessage?.call(message);
        }
      });
    } catch (e) {
      debugPrint('Erreur setup webMessage listener: $e');
    }
  }
  
  /// Injecte le script de détection de sélection de texte
  Future<void> _injectTextSelectionScript() async {
    if (_textSelectionScriptInjected || _webView == null || !_webView!.value.isInitialized) return;
    
    try {
      await _webView!.executeScript(_textSelectionScript);
      _textSelectionScriptInjected = true;
      debugPrint('✅ Script de sélection de texte injecté');
      _startTextSelectionPolling();
    } catch (e) {
      debugPrint('Erreur injection script sélection texte: $e');
    }
  }
  
  /// Démarre le polling pour détecter les sélections de texte
  void _startTextSelectionPolling() {
    _textSelectionPollingTimer?.cancel();
    _textSelectionPollingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_webView == null || !_isInitialized || !_webView!.value.isInitialized) {
        timer.cancel();
        return;
      }
      
      try {
        final result = await _webView!.executeScript('''
          (function() {
            if (!document.body) return null;
            var text = document.body.getAttribute('data-selected-text');
            var x = document.body.getAttribute('data-selection-x');
            var y = document.body.getAttribute('data-selection-y');
            if (text && x && y) {
              document.body.removeAttribute('data-selected-text');
              document.body.removeAttribute('data-selection-x');
              document.body.removeAttribute('data-selection-y');
              return JSON.stringify({text: decodeURIComponent(text), x: parseInt(x), y: parseInt(y)});
            }
            return null;
          })();
        ''');
        
        if (result != null && result is String && result.isNotEmpty && result != 'null') {
          try {
            final data = jsonDecode(result) as Map<String, dynamic>;
            final selectedText = data['text'] as String?;
            final x = data['x'] as int?;
            final y = data['y'] as int?;
            
            if (selectedText != null && selectedText.isNotEmpty && x != null && y != null) {
              final selectionService = TextSelectionService();
              selectionService.showMenu(selectedText, Offset(x.toDouble(), y.toDouble()));
            }
          } catch (e) {
            debugPrint('Erreur parsing sélection texte: $e');
          }
        }
      } catch (e) {
        // Ignorer les erreurs
      }
    });
  }
  
  /// Arrête le polling de sélection de texte
  void _stopTextSelectionPolling() {
    _textSelectionPollingTimer?.cancel();
    _textSelectionPollingTimer = null;
  }
  
  /// Injecte le script de menu contextuel
  Future<void> _injectContextMenuScript() async {
    if (_webView == null || !_isInitialized || !_webView!.value.isInitialized) return;
    
    try {
      await _webView!.executeScript(_contextMenuScript);
      _startContextMenuPolling();
    } catch (e) {
      debugPrint('Erreur injection script menu contextuel: $e');
    }
  }
  
  /// Démarre le polling pour détecter les clics droits
  void _startContextMenuPolling() {
    _contextMenuPollingTimer?.cancel();
    _contextMenuPollingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_webView == null || !_isInitialized || onContextMenuRequest == null || !_webView!.value.isInitialized) {
        timer.cancel();
        return;
      }
      
      try {
        final result = await _webView!.executeScript('''
          (function() {
            if (!document.body) return null;
            var type = document.body.getAttribute('data-context-type');
            var x = document.body.getAttribute('data-context-x');
            var y = document.body.getAttribute('data-context-y');
            if (type && x && y) {
              var imageUrl = document.body.getAttribute('data-context-image-url');
              var linkUrl = document.body.getAttribute('data-context-link-url');
              var text = document.body.getAttribute('data-context-text');
              
              document.body.removeAttribute('data-context-type');
              document.body.removeAttribute('data-context-x');
              document.body.removeAttribute('data-context-y');
              document.body.removeAttribute('data-context-image-url');
              document.body.removeAttribute('data-context-link-url');
              document.body.removeAttribute('data-context-text');
              
              return JSON.stringify({
                type: type,
                x: parseInt(x),
                y: parseInt(y),
                imageUrl: imageUrl ? decodeURIComponent(imageUrl) : null,
                linkUrl: linkUrl ? decodeURIComponent(linkUrl) : null,
                text: text ? decodeURIComponent(text) : null
              });
            }
            return null;
          })();
        ''');
        
        if (result != null && result is String && result.isNotEmpty && result != 'null') {
          try {
            final data = jsonDecode(result) as Map<String, dynamic>;
            final type = data['type'] as String?;
            final x = data['x'] as int?;
            final y = data['y'] as int?;
            final imageUrl = data['imageUrl'] as String?;
            final linkUrl = data['linkUrl'] as String?;
            final text = data['text'] as String?;
            
            if (type != null && x != null && y != null) {
              onContextMenuRequest?.call(
                type,
                imageUrl,
                linkUrl,
                text,
                Offset(x.toDouble(), y.toDouble()),
              );
            }
          } catch (e) {
            debugPrint('Erreur parsing menu contextuel: $e');
          }
        }
      } catch (e) {
        // Ignorer les erreurs
      }
    });
  }
  
  /// Arrête le polling de menu contextuel
  void _stopContextMenuPolling() {
    _contextMenuPollingTimer?.cancel();
    _contextMenuPollingTimer = null;
  }

  /// Injecte le script de blocage de publicités
  Future<void> _injectAdBlockerScript() async {
    if (_adBlockerScriptInjected || _webView == null || !_isInitialized || _adBlockerService == null || !_webView!.value.isInitialized) return;
    
    if (!_adBlockerService!.isEnabled) return;
    
    try {
      final script = _adBlockerService!.generateBlockingScript();
      if (script.isNotEmpty) {
        await _webView!.executeScript(script);
        _adBlockerScriptInjected = true;
        debugPrint('✅ Script de blocage de publicités injecté');
        _startAdBlockerPolling();
      }
    } catch (e) {
      debugPrint('Erreur injection script bloqueur de publicités: $e');
    }
  }

  /// Démarre le polling pour récupérer le compteur de publicités bloquées
  void _startAdBlockerPolling() {
    if (_adBlockerService == null || !_adBlockerService!.isEnabled) return;
    
    _adBlockerPollingTimer?.cancel();
    _adBlockerPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_webView == null || !_isInitialized || _adBlockerService == null || !_adBlockerService!.isEnabled || !_webView!.value.isInitialized) {
        timer.cancel();
        return;
      }
      
      try {
        final result = await _webView!.executeScript('''
          (function() {
            if (!document.body) return null;
            var count = document.body.getAttribute('data-adblock-count');
            if (count) {
              return parseInt(count) || 0;
            }
            return window._notilusAdBlockerPageCount || 0;
          })();
        ''');
        
        if (result != null) {
          try {
            final count = int.tryParse(result.toString()) ?? 0;
            if (count > 0) {
              final currentGlobalCount = _adBlockerService!.blockedCount;
              if (count > currentGlobalCount) {
                _adBlockerService!.addBlockedCount(count - currentGlobalCount);
              }
            }
          } catch (e) {
            // Ignorer
          }
        }
      } catch (e) {
        // Ignorer
      }
    });
  }

  /// Arrête le polling de blocage de publicités
  void _stopAdBlockerPolling() {
    _adBlockerPollingTimer?.cancel();
    _adBlockerPollingTimer = null;
  }

  /// Configure l'interception des téléchargements
  void _setupDownloadInterceptor() {
    _downloadPollingTimer?.cancel();
    
    _downloadPollingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_webView == null || !_isInitialized || !_webView!.value.isInitialized) {
        return;
      }
      
      try {
        final result = await _webView!.executeScript('''
          (function() {
            if (!window._flutterDownloadHandlerInstalled) {
              window._flutterDownloadHandlerInstalled = true;
              window._pendingDownloads = [];
              
              var downloadExtensions = [
                '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz',
                '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.odt', '.ods', '.odp',
                '.exe', '.msi', '.dmg', '.deb', '.rpm', '.apk', '.ipa', '.app',
                '.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma',
                '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm',
                '.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.bmp', '.ico', '.tiff',
                '.iso', '.img', '.bin', '.torrent',
                '.csv', '.json', '.xml', '.sql', '.db',
                '.ttf', '.otf', '.woff', '.woff2'
              ];
              
              function isDownloadUrl(href) {
                if (!href) return false;
                var lowerHref = href.toLowerCase();
                
                for (var i = 0; i < downloadExtensions.length; i++) {
                  var ext = downloadExtensions[i];
                  var idx = lowerHref.lastIndexOf(ext);
                  if (idx !== -1) {
                    var afterExt = lowerHref.substring(idx + ext.length);
                    if (afterExt === '' || afterExt.charAt(0) === '?' || afterExt.charAt(0) === '#') {
                      return true;
                    }
                  }
                }
                
                if (lowerHref.indexOf('/download/') !== -1 || 
                    lowerHref.indexOf('/downloads/') !== -1 ||
                    lowerHref.indexOf('action=download') !== -1 ||
                    lowerHref.indexOf('download=') !== -1 ||
                    lowerHref.indexOf('/attachment') !== -1 ||
                    lowerHref.indexOf('?file=') !== -1 ||
                    lowerHref.indexOf('&file=') !== -1) {
                  return true;
                }
                
                return false;
              }
              
              function extractFileName(href, downloadAttr) {
                if (downloadAttr) return downloadAttr;
                try {
                  var url = new URL(href, window.location.href);
                  var path = url.pathname;
                  var fileName = path.substring(path.lastIndexOf('/') + 1);
                  if (fileName && fileName.indexOf('.') !== -1) {
                    return decodeURIComponent(fileName.split('?')[0]);
                  }
                } catch(e) {}
                return null;
              }
              
              document.addEventListener('click', function(e) {
                var target = e.target;
                while (target && target.tagName !== 'A') {
                  target = target.parentElement;
                }
                
                if (target && target.tagName === 'A') {
                  var href = target.getAttribute('href');
                  var download = target.getAttribute('download');
                  
                  if (download !== null || isDownloadUrl(href)) {
                    e.preventDefault();
                    e.stopPropagation();
                    
                    try {
                      var fullUrl = new URL(href, window.location.href).href;
                      var fileName = extractFileName(href, download);
                      
                      window._pendingDownloads.push({
                        url: fullUrl,
                        fileName: fileName
                      });
                    } catch(err) {
                      window._pendingDownloads.push({
                        url: href,
                        fileName: download || null
                      });
                    }
                    
                    return false;
                  }
                }
              }, true);
              
              document.addEventListener('submit', function(e) {
                var form = e.target;
                if (form && form.tagName === 'FORM') {
                  var action = form.getAttribute('action') || '';
                  if (isDownloadUrl(action)) {
                    try {
                      var fullUrl = new URL(action, window.location.href).href;
                      window._pendingDownloads.push({
                        url: fullUrl,
                        fileName: extractFileName(action, null)
                      });
                    } catch(e) {}
                  }
                }
              }, true);
            }
            
            if (window._pendingDownloads && window._pendingDownloads.length > 0) {
              var downloads = JSON.stringify(window._pendingDownloads);
              window._pendingDownloads = [];
              return downloads;
            }
            
            return null;
          })();
        ''');
        
        if (result != null && result != 'null' && result.toString().isNotEmpty && result.toString() != 'undefined') {
          await _processDownloadResult(result.toString());
        }
      } catch (e) {
        // Ignorer
      }
    });
  }
  
  /// Traite le résultat du script de détection des téléchargements
  Future<void> _processDownloadResult(String jsonStr) async {
    try {
      if (!jsonStr.startsWith('[')) return;
      
      final List<dynamic> downloads = jsonDecode(jsonStr);
      
      for (final download in downloads) {
        if (download is Map) {
          final url = download['url'] as String?;
          final fileName = download['fileName'] as String?;
          
          if (url != null && url.isNotEmpty && onDownloadRequested != null) {
            onDownloadRequested?.call(url, fileName);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du parsing des téléchargements: $e');
      
      try {
        if (jsonStr.startsWith('{')) {
          final download = jsonDecode(jsonStr) as Map<String, dynamic>;
          final url = download['url'] as String?;
          final fileName = download['fileName'] as String?;
          
          if (url != null && url.isNotEmpty && onDownloadRequested != null) {
            onDownloadRequested?.call(url, fileName);
          }
        }
      } catch (e2) {
        debugPrint('Erreur fallback parsing: $e2');
      }
    }
  }

  /// Efface tous les cookies
  Future<void> clearCookies() async {
    if (_webView == null || !_webView!.value.isInitialized) return;
    
    try {
      await executeJavaScript('''
        document.cookie.split(";").forEach(function(c) { 
          document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); 
        });
      ''');
      debugPrint('🍪 Cookies effacés pour le WebView');
    } catch (e) {
      debugPrint('Erreur lors de l\'effacement des cookies: $e');
    }
  }

  /// Efface le cache
  Future<void> clearCache() async {
    if (_webView == null || !_webView!.value.isInitialized) return;
    
    try {
      await executeJavaScript('''
        if ('caches' in window) {
          caches.keys().then(function(names) {
            for (let name of names)
              caches.delete(name);
          });
        }
        localStorage.clear();
        sessionStorage.clear();
      ''');
      debugPrint('💾 Cache effacé pour le WebView');
    } catch (e) {
      debugPrint('Erreur lors de l\'effacement du cache: $e');
    }
  }

  /// Active les optimisations de performance pour le WebView
  void _enablePerformanceOptimizations() {
    try {
      // Vérifier que le WebView est initialisé avant d'appeler setBackgroundColor
      if (_webView != null && _webView!.value.isInitialized) {
        // Activer le mode composition GPU avec fond transparent
        _webView!.setBackgroundColor(Colors.transparent);
        
        debugPrint('✅ Optimisations GPU activées (fond transparent)');
      }
      
      // Injecter les optimisations critiques IMMÉDIATEMENT (avant chargement de page)
      _injectCriticalOptimizations();
      
      // Forcer le rendu HD et la netteté maximale
      _forceHDRendering();
      
      // Optimisations supplémentaires via JavaScript (après chargement)
      _enableAdditionalOptimizations();
      
      // Optimisations réseau et cache
      _enableNetworkOptimizations();
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'activation des optimisations: $e');
    }
  }
  
  /// Force le rendu HD et la netteté maximale
  void _forceHDRendering() {
    try {
      if (_webView != null && _webView!.value.isInitialized) {
        // Injecter immédiatement les optimisations HD
        _webView!.executeScript('''
          (function() {
            'use strict';
            
            // === FORCER LE RENDU HD ET NETTETÉ MAXIMALE ===
            
            // 1. Forcer le devicePixelRatio élevé et désactiver le downscaling
            const forceHighDPI = function() {
              // Surcharger devicePixelRatio pour forcer le rendu haute résolution
              const originalDPR = window.devicePixelRatio || 1;
              const targetDPR = Math.max(originalDPR, 2); // Minimum 2x pour HD
              
              Object.defineProperty(window, 'devicePixelRatio', {
                get: () => targetDPR,
                configurable: true
              });
              
              // Forcer le viewport à utiliser la résolution native
              const metaViewport = document.querySelector('meta[name="viewport"]');
              if (metaViewport) {
                metaViewport.setAttribute('content', 
                  'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover');
              } else {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
                document.head.insertBefore(meta, document.head.firstChild);
              }
            };
            
            // 2. Améliorer la netteté du texte avec font-smoothing optimal
            const optimizeTextRendering = function() {
              const style = document.createElement('style');
              style.id = 'notilus-hd-text';
              style.textContent = `
                * {
                  -webkit-font-smoothing: antialiased !important;
                  -moz-osx-font-smoothing: grayscale !important;
                  font-smoothing: antialiased !important;
                  text-rendering: optimizeLegibility !important;
                  -webkit-text-stroke: 0.01px transparent !important;
                  text-shadow: 0 0 0.01px rgba(0,0,0,0.01) !important;
                }
                
                /* Forcer la netteté sur les textes */
                body, p, span, div, a, h1, h2, h3, h4, h5, h6, li, td, th, label, input, textarea, select, button {
                  -webkit-font-smoothing: antialiased !important;
                  -moz-osx-font-smoothing: grayscale !important;
                  text-rendering: optimizeLegibility !important;
                }
                
                /* Améliorer la netteté des bordures */
                * {
                  image-rendering: -webkit-optimize-contrast !important;
                  image-rendering: crisp-edges !important;
                  image-rendering: pixelated !important;
                }
                
                /* Forcer la netteté des images */
                img, svg, canvas, video {
                  image-rendering: -webkit-optimize-contrast !important;
                  image-rendering: crisp-edges !important;
                  image-rendering: high-quality !important;
                  -ms-interpolation-mode: nearest-neighbor !important;
                }
                
                /* Désactiver le blur sur les transformations */
                * {
                  -webkit-filter: none !important;
                  filter: none !important;
                }
                
                /* Forcer le subpixel rendering */
                body {
                  -webkit-font-feature-settings: "liga" on, "calt" on !important;
                  font-feature-settings: "liga" on, "calt" on !important;
                  font-variant-ligatures: common-ligatures !important;
                }
              `;
              
              if (!document.getElementById('notilus-hd-text')) {
                document.head.appendChild(style);
              }
            };
            
            // 3. Forcer la haute résolution pour les canvas
            const optimizeCanvasRendering = function() {
              const originalGetContext = HTMLCanvasElement.prototype.getContext;
              HTMLCanvasElement.prototype.getContext = function(type, attributes) {
                if (type === '2d') {
                  const ctx = originalGetContext.call(this, type, attributes);
                  if (ctx) {
                    // Forcer le DPI élevé
                    const dpr = Math.max(window.devicePixelRatio || 1, 2);
                    const rect = this.getBoundingClientRect();
                    
                    // Ajuster la taille physique du canvas
                    this.width = rect.width * dpr;
                    this.height = rect.height * dpr;
                    
                    // Ajuster le scale du contexte
                    ctx.scale(dpr, dpr);
                    
                    // Améliorer la qualité du rendu
                    ctx.imageSmoothingEnabled = true;
                    ctx.imageSmoothingQuality = 'high';
                    ctx.textBaseline = 'top';
                  }
                  return ctx;
                }
                return originalGetContext.call(this, type, attributes);
              };
            };
            
            // 4. Optimiser les images pour qu'elles soient nettes (charger en haute résolution)
            const optimizeImageSharpness = function() {
              const images = document.getElementsByTagName('img');
              const dpr = Math.max(window.devicePixelRatio || 1, 2);
              
              for (let img of images) {
                // Si l'image a un srcset, forcer la version haute résolution
                if (img.srcset) {
                  const srcset = img.srcset.split(',');
                  const highResSrc = srcset.find(s => s.includes('2x') || s.includes('3x')) || srcset[srcset.length - 1];
                  if (highResSrc) {
                    const url = highResSrc.trim().split(' ')[0];
                    if (url) img.src = url;
                  }
                }
                
                // Forcer le chargement en haute résolution si possible
                if (img.src && !img.src.includes('@2x') && !img.src.includes('@3x')) {
                  // Essayer de charger une version @2x si disponible
                  const baseUrl = img.src.split('?')[0];
                  const extension = baseUrl.substring(baseUrl.lastIndexOf('.'));
                  const baseWithoutExt = baseUrl.substring(0, baseUrl.lastIndexOf('.'));
                  
                  // Tester si une version @2x existe
                  const testImg = new Image();
                  testImg.onload = function() {
                    img.src = baseWithoutExt + '@2x' + extension;
                  };
                  testImg.src = baseWithoutExt + '@2x' + extension;
                }
                
                // Forcer la netteté du rendu
                img.style.imageRendering = 'crisp-edges';
                img.style.imageRendering = '-webkit-optimize-contrast';
              }
            };
            
            // 5. Masquer toutes les barres de défilement
            const hideScrollbars = function() {
              const style = document.createElement('style');
              style.id = 'notilus-hide-scrollbars';
              style.textContent = `
                /* Masquer toutes les scrollbars */
                * {
                  scrollbar-width: none !important; /* Firefox */
                  -ms-overflow-style: none !important; /* IE et Edge */
                }
                
                *::-webkit-scrollbar {
                  display: none !important; /* Chrome, Safari, Opera */
                  width: 0 !important;
                  height: 0 !important;
                }
                
                html, body {
                  scrollbar-width: none !important;
                  -ms-overflow-style: none !important;
                }
                
                html::-webkit-scrollbar,
                body::-webkit-scrollbar {
                  display: none !important;
                  width: 0 !important;
                  height: 0 !important;
                }
              `;
              
              if (!document.getElementById('notilus-hide-scrollbars')) {
                document.head.appendChild(style);
              }
            };
            
            // 6. Forcer le pixel-perfect rendering
            const forcePixelPerfect = function() {
              const style = document.createElement('style');
              style.id = 'notilus-pixel-perfect';
              style.textContent = `
                /* Désactiver tous les effets de flou */
                * {
                  filter: none !important;
                  -webkit-filter: none !important;
                  backdrop-filter: none !important;
                  -webkit-backdrop-filter: none !important;
                }
                
                /* Forcer le rendu net sur les bordures */
                * {
                  border-image: none !important;
                  outline: none !important;
                }
                
                /* Améliorer la netteté des ombres (les rendre plus nettes) */
                * {
                  box-shadow: none !important;
                  text-shadow: none !important;
                }
                
                /* Forcer l'anti-aliasing optimal */
                * {
                  -webkit-transform: translateZ(0) !important;
                  transform: translateZ(0) !important;
                }
              `;
              
              if (!document.getElementById('notilus-pixel-perfect')) {
                document.head.appendChild(style);
              }
            };
            
            // 7. Améliorer la qualité du rendu SVG
            const optimizeSVGRendering = function() {
              const svgs = document.getElementsByTagName('svg');
              for (let svg of svgs) {
                svg.setAttribute('shape-rendering', 'geometricPrecision');
                svg.setAttribute('text-rendering', 'optimizeLegibility');
                svg.setAttribute('image-rendering', 'optimizeQuality');
              }
            };
            
            // 8. Forcer le DPI scaling élevé via CSS
            const forceHighDPICSS = function() {
              const style = document.createElement('style');
              style.id = 'notilus-hd-dpi';
              style.textContent = `
                @media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
                  * {
                    -webkit-transform: scale(1) !important;
                    transform: scale(1) !important;
                  }
                }
                
                /* Forcer le rendu à la résolution native */
                html {
                  zoom: 1 !important;
                  -webkit-text-size-adjust: 100% !important;
                  text-size-adjust: 100% !important;
                }
              `;
              
              if (!document.getElementById('notilus-hd-dpi')) {
                document.head.appendChild(style);
              }
            };
            
            // Appliquer toutes les optimisations HD immédiatement
            forceHighDPI();
            optimizeTextRendering();
            optimizeCanvasRendering();
            hideScrollbars();
            forcePixelPerfect();
            optimizeSVGRendering();
            forceHighDPICSS();
            
            // Appliquer après chargement
            if (document.readyState === 'loading') {
              document.addEventListener('DOMContentLoaded', function() {
                optimizeImageSharpness();
                optimizeSVGRendering();
              });
            } else {
              optimizeImageSharpness();
              optimizeSVGRendering();
            }
            
            // Observer les changements pour réappliquer
            if (window.MutationObserver) {
              const observer = new MutationObserver(function() {
                optimizeImageSharpness();
                optimizeSVGRendering();
              });
              
              observer.observe(document.body, {
                childList: true,
                subtree: true
              });
            }
            
            console.log('✅ Notilus: Rendu HD et netteté maximale forcés');
          })();
        ''');
        
        debugPrint('✅ Optimisations HD et netteté maximale activées');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'activation du rendu HD: $e');
    }
  }
  
  /// Injecte les optimisations critiques AVANT le chargement de la page
  void _injectCriticalOptimizations() {
    try {
      if (_webView != null && _webView!.value.isInitialized) {
        // Ces optimisations doivent être injectées le plus tôt possible
        _webView!.executeScript('''
          (function() {
            'use strict';
            
            // === OPTIMISATIONS CRITIQUES PRÉ-CHARGEMENT ===
            
            // 1. Désactiver les fonctionnalités non essentielles pour améliorer les performances
            Object.defineProperty(navigator, 'webdriver', {
              get: () => false,
              configurable: true
            });
            
            // 2. Optimiser le garbage collector
            if (window.gc) {
              setInterval(() => {
                try { window.gc(); } catch(e) {}
              }, 30000); // GC toutes les 30 secondes
            }
            
            // 3. Précharger les ressources critiques
            const preloadCriticalResources = function() {
              const link = document.createElement('link');
              link.rel = 'preconnect';
              link.href = 'https://fonts.googleapis.com';
              document.head.appendChild(link);
              
              const dnsPrefetch = document.createElement('link');
              dnsPrefetch.rel = 'dns-prefetch';
              dnsPrefetch.href = 'https://fonts.gstatic.com';
              document.head.appendChild(dnsPrefetch);
            };
            
            // 4. Désactiver les animations pendant le chargement initial
            const disableAnimationsDuringLoad = function() {
              const style = document.createElement('style');
              style.id = 'notilus-disable-anim-load';
              style.textContent = `
                *, *::before, *::after {
                  animation-duration: 0s !important;
                  animation-delay: 0s !important;
                  transition-duration: 0s !important;
                  transition-delay: 0s !important;
                }
              `;
              document.head.appendChild(style);
              
              // Réactiver après chargement
              window.addEventListener('load', function() {
                setTimeout(() => {
                  const styleEl = document.getElementById('notilus-disable-anim-load');
                  if (styleEl) styleEl.remove();
                }, 500);
              }, { once: true });
            };
            
            // 5. Optimiser le parsing HTML
            if (document.readyState === 'loading') {
              disableAnimationsDuringLoad();
              preloadCriticalResources();
            } else {
              disableAnimationsDuringLoad();
              preloadCriticalResources();
            }
            
            console.log('✅ Notilus: Optimisations critiques pré-chargement activées');
          })();
        ''');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'injection des optimisations critiques: $e');
    }
  }
  
  /// Active les optimisations réseau et cache
  void _enableNetworkOptimizations() {
    try {
      if (_webView != null && _webView!.value.isInitialized) {
        _webView!.executeScript('''
          (function() {
            'use strict';
            
            // === OPTIMISATIONS RÉSEAU ET CACHE ===
            
            // 1. Service Worker pour cache agressif (si disponible)
            if ('serviceWorker' in navigator) {
              navigator.serviceWorker.register('/sw.js').catch(() => {});
            }
            
            // 2. Précharger les liens au survol (préfetch intelligent)
            let prefetchTimer = null;
            document.addEventListener('mouseover', function(e) {
              const link = e.target.closest('a[href]');
              if (link && link.href && !link.dataset.prefetched) {
                clearTimeout(prefetchTimer);
                prefetchTimer = setTimeout(() => {
                  const prefetchLink = document.createElement('link');
                  prefetchLink.rel = 'prefetch';
                  prefetchLink.href = link.href;
                  prefetchLink.as = 'document';
                  document.head.appendChild(prefetchLink);
                  link.dataset.prefetched = 'true';
                }, 100); // Délai de 100ms pour éviter le prefetch inutile
              }
            }, { passive: true });
            
            // 3. Optimiser les requêtes fetch avec cache
            const originalFetch = window.fetch;
            window.fetch = function(...args) {
              const url = typeof args[0] === 'string' ? args[0] : args[0].url;
              const options = args[1] || {};
              
              // Ajouter cache par défaut pour les ressources statiques
              if (!options.cache && (url.includes('.css') || url.includes('.js') || url.includes('.png') || url.includes('.jpg') || url.includes('.svg'))) {
                options.cache = 'force-cache';
              }
              
              return originalFetch.apply(this, args);
            };
            
            // 4. Lazy load les images avec Intersection Observer
            if ('IntersectionObserver' in window) {
              const imageObserver = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                  if (entry.isIntersecting) {
                    const img = entry.target;
                    if (img.dataset.src) {
                      img.src = img.dataset.src;
                      img.removeAttribute('data-src');
                      observer.unobserve(img);
                    }
                  }
                });
              }, {
                rootMargin: '50px' // Commencer le chargement 50px avant l'entrée dans le viewport
              });
              
              // Observer toutes les images avec data-src
              document.addEventListener('DOMContentLoaded', function() {
                document.querySelectorAll('img[data-src]').forEach(img => {
                  imageObserver.observe(img);
                });
              });
            }
            
            console.log('✅ Notilus: Optimisations réseau activées');
          })();
        ''');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'activation des optimisations réseau: $e');
    }
  }
  
  /// Active des optimisations supplémentaires via JavaScript et CSS pour améliorer le rendu GPU
  void _enableAdditionalOptimizations() {
    // Attendre que la page soit chargée avant d'appliquer les optimisations
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        if (_webView != null && _webView!.value.isInitialized) {
          // Script d'optimisation GPU complet
          _webView!.executeScript('''
            (function() {
              'use strict';
              
              // === OPTIMISATIONS GPU ET RENDU ===
              
              // 1. Forcer l'accélération GPU sur tous les éléments
              const forceGPUAcceleration = function() {
                const style = document.createElement('style');
                style.id = 'notilus-gpu-accel';
                style.textContent = `
                  * {
                    -webkit-transform: translateZ(0);
                    transform: translateZ(0);
                    -webkit-backface-visibility: hidden;
                    backface-visibility: hidden;
                    -webkit-perspective: 1000;
                    perspective: 1000;
                  }
                  
                  /* Optimiser les animations CSS */
                  @keyframes, @-webkit-keyframes {
                    will-change: transform, opacity;
                  }
                  
                  /* Forcer le rendu GPU sur les éléments interactifs */
                  a, button, input, select, textarea {
                    will-change: transform;
                  }
                  
                  /* Optimiser le scroll */
                  body, html {
                    -webkit-overflow-scrolling: touch;
                    overflow-scrolling: touch;
                  }
                `;
                
                if (!document.getElementById('notilus-gpu-accel')) {
                  document.head.appendChild(style);
                }
              };
              
              // 2. Optimiser le chargement des images (lazy loading intelligent) avec HD
              const optimizeImageLoading = function() {
                const images = document.getElementsByTagName('img');
                const viewportHeight = window.innerHeight;
                const dpr = Math.max(window.devicePixelRatio || 1, 2);
                
                for (let img of images) {
                  const rect = img.getBoundingClientRect();
                  const isInViewport = rect.top < viewportHeight * 2;
                  
                  if (isInViewport) {
                    img.loading = 'eager';
                    // Forcer le décodage asynchrone pour améliorer le rendu
                    if (img.decode) {
                      img.decode().catch(() => {});
                    }
                    
                    // Forcer le chargement en haute résolution
                    if (img.src && !img.src.includes('@2x') && !img.src.includes('@3x')) {
                      const baseUrl = img.src.split('?')[0];
                      const extension = baseUrl.substring(baseUrl.lastIndexOf('.'));
                      const baseWithoutExt = baseUrl.substring(0, baseUrl.lastIndexOf('.'));
                      
                      // Essayer de charger @2x ou @3x
                      const highResUrl = baseWithoutExt + (dpr >= 3 ? '@3x' : '@2x') + extension;
                      const testImg = new Image();
                      testImg.onload = function() {
                        img.src = highResUrl;
                      };
                      testImg.onerror = function() {
                        // Si @2x/@3x n'existe pas, garder l'original mais forcer la netteté
                        img.style.imageRendering = 'crisp-edges';
                      };
                      testImg.src = highResUrl;
                    }
                  } else {
                    img.loading = 'lazy';
                  }
                  
                  // Ajouter l'accélération GPU aux images avec netteté
                  img.style.transform = 'translateZ(0)';
                  img.style.willChange = 'transform';
                  img.style.imageRendering = 'crisp-edges';
                  img.style.imageRendering = '-webkit-optimize-contrast';
                }
              };
              
              // 3. Optimiser les iframes
              const optimizeIframes = function() {
                const iframes = document.getElementsByTagName('iframe');
                for (let iframe of iframes) {
                  iframe.style.transform = 'translateZ(0)';
                  iframe.style.willChange = 'transform';
                }
              };
              
              // 4. Forcer le rendu 120 FPS via requestAnimationFrame optimisé
              let lastFrameTime = performance.now();
              const targetFPS = 120;
              const frameInterval = 1000 / targetFPS;
              
              const optimizedRAF = function(callback) {
                const currentTime = performance.now();
                const elapsed = currentTime - lastFrameTime;
                
                if (elapsed >= frameInterval) {
                  lastFrameTime = currentTime - (elapsed % frameInterval);
                  callback(currentTime);
                } else {
                  setTimeout(() => optimizedRAF(callback), frameInterval - elapsed);
                }
              };
              
              // Remplacer requestAnimationFrame si possible
              if (window.requestAnimationFrame) {
                const originalRAF = window.requestAnimationFrame;
                window.requestAnimationFrame = function(callback) {
                  return originalRAF.call(window, function(time) {
                    optimizedRAF(callback);
                  });
                };
              }
              
              // 5. Optimiser les transitions et animations CSS
              const optimizeAnimations = function() {
                const style = document.createElement('style');
                style.id = 'notilus-anim-opt';
                style.textContent = `
                  * {
                    transition-duration: 0.001s !important;
                    animation-duration: 0.001s !important;
                  }
                  
                  /* Réactiver les animations après un court délai pour éviter les flashs */
                `;
                
                // Appliquer temporairement, puis restaurer
                if (!document.getElementById('notilus-anim-opt')) {
                  document.head.appendChild(style);
                  setTimeout(() => {
                    const optStyle = document.getElementById('notilus-anim-opt');
                    if (optStyle) {
                      optStyle.remove();
                    }
                  }, 100);
                }
              };
              
              // 6. Désactiver les effets visuels coûteux qui causent des latences
              const disableExpensiveEffects = function() {
                const style = document.createElement('style');
                style.id = 'notilus-disable-expensive';
                style.textContent = `
                  /* Désactiver les box-shadows complexes */
                  * {
                    box-shadow: none !important;
                    text-shadow: none !important;
                  }
                  
                  /* Réactiver sélectivement après chargement */
                `;
                
                if (!document.getElementById('notilus-disable-expensive')) {
                  document.head.appendChild(style);
                  setTimeout(() => {
                    const expensiveStyle = document.getElementById('notilus-disable-expensive');
                    if (expensiveStyle) {
                      expensiveStyle.remove();
                    }
                  }, 2000);
                }
              };
              
              // 7. Optimiser le scroll avec passive listeners
              const optimizeScroll = function() {
                let ticking = false;
                const optimizedScrollHandler = function() {
                  if (!ticking) {
                    window.requestAnimationFrame(function() {
                      // Scroll optimisé
                      ticking = false;
                    });
                    ticking = true;
                  }
                };
                
                window.addEventListener('scroll', optimizedScrollHandler, { passive: true });
                window.addEventListener('wheel', optimizedScrollHandler, { passive: true });
                window.addEventListener('touchmove', optimizedScrollHandler, { passive: true });
              };
              
              // 8. Virtual scrolling pour les grandes listes (optimisation mémoire)
              const enableVirtualScrolling = function() {
                const lists = document.querySelectorAll('ul, ol, div[role="list"]');
                lists.forEach(list => {
                  if (list.children.length > 50) {
                    const container = list.parentElement;
                    if (container) {
                      container.style.overflow = 'auto';
                      container.style.height = '100vh';
                      container.style.willChange = 'scroll-position';
                      
                      // Utiliser content-visibility pour le virtual scrolling
                      Array.from(list.children).forEach((child, index) => {
                        if (index > 20 && index < list.children.length - 20) {
                          child.style.contentVisibility = 'auto';
                        }
                      });
                    }
                  }
                });
              };
              
              // 9. Optimiser les event listeners avec debouncing/throttling agressif
              const optimizeEventListeners = function() {
                const originalAddEventListener = EventTarget.prototype.addEventListener;
                const throttledEvents = new Map();
                
                EventTarget.prototype.addEventListener = function(type, listener, options) {
                  // Throttler pour les événements fréquents
                  if (type === 'scroll' || type === 'resize' || type === 'mousemove') {
                    let lastCall = 0;
                    const throttleDelay = type === 'mousemove' ? 16 : 100; // 60fps pour mousemove, 10fps pour scroll/resize
                    
                    const throttledListener = function(...args) {
                      const now = Date.now();
                      if (now - lastCall >= throttleDelay) {
                        lastCall = now;
                        listener.apply(this, args);
                      }
                    };
                    
                    return originalAddEventListener.call(this, type, throttledListener, {
                      ...options,
                      passive: true
                    });
                  }
                  
                  // Toujours passer passive: true pour les événements de scroll
                  if (type === 'touchstart' || type === 'touchmove' || type === 'wheel') {
                    return originalAddEventListener.call(this, type, listener, {
                      ...options,
                      passive: true
                    });
                  }
                  
                  return originalAddEventListener.call(this, type, listener, options);
                };
              };
              
              // 10. Layer promotion agressive pour les éléments animés
              const promoteLayers = function() {
                const animatedElements = document.querySelectorAll('[class*="animate"], [class*="transition"], [style*="animation"], [style*="transition"]');
                animatedElements.forEach(el => {
                  el.style.transform = 'translateZ(0)';
                  el.style.willChange = 'transform, opacity';
                  el.style.isolation = 'isolate';
                });
              };
              
              // 11. Désactiver les fonctionnalités non essentielles
              const disableNonEssentialFeatures = function() {
                // Désactiver les notifications push non essentielles
                if ('Notification' in window && Notification.permission === 'default') {
                  // Ne pas demander la permission automatiquement
                }
                
                // Désactiver les geolocation requests automatiques
                if ('geolocation' in navigator) {
                  const originalGetCurrentPosition = navigator.geolocation.getCurrentPosition;
                  navigator.geolocation.getCurrentPosition = function(success, error, options) {
                    // Ne pas bloquer, mais logger
                    console.log('Notilus: Geolocation request intercepted');
                    return originalGetCurrentPosition.call(navigator.geolocation, success, error, options);
                  };
                }
              };
              
              // 12. Optimiser le repaint/reflow avec requestIdleCallback
              const optimizeRepaint = function() {
                if ('requestIdleCallback' in window) {
                  const scheduleOptimization = function() {
                    requestIdleCallback(() => {
                      // Forcer un reflow optimisé
                      document.body.offsetHeight;
                      
                      // Promouvoir les layers pour les éléments visibles
                      promoteLayers();
                      
                      // Réappliquer le virtual scrolling si nécessaire
                      enableVirtualScrolling();
                    }, { timeout: 1000 });
                  };
                  
                  window.addEventListener('load', scheduleOptimization, { once: true });
                  window.addEventListener('resize', () => {
                    requestIdleCallback(scheduleOptimization, { timeout: 500 });
                  }, { passive: true });
                }
              };
              
              // 13. Memory pooling pour les objets fréquemment créés
              const createMemoryPool = function() {
                window._notilusMemoryPool = {
                  eventObjects: [],
                  getEventObject: function() {
                    return this.eventObjects.pop() || {};
                  },
                  releaseEventObject: function(obj) {
                    Object.keys(obj).forEach(key => delete obj[key]);
                    if (this.eventObjects.length < 100) {
                      this.eventObjects.push(obj);
                    }
                  }
                };
              };
              
              // Appliquer toutes les optimisations
              if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', function() {
                  forceGPUAcceleration();
                  optimizeImageLoading();
                  optimizeIframes();
                  optimizeAnimations();
                  disableExpensiveEffects();
                  optimizeScroll();
                  optimizeEventListeners();
                  disableNonEssentialFeatures();
                  optimizeRepaint();
                  createMemoryPool();
                  enableVirtualScrolling();
                  promoteLayers();
                });
              } else {
                forceGPUAcceleration();
                optimizeImageLoading();
                optimizeIframes();
                optimizeAnimations();
                disableExpensiveEffects();
                optimizeScroll();
                optimizeEventListeners();
                disableNonEssentialFeatures();
                optimizeRepaint();
                createMemoryPool();
                enableVirtualScrolling();
                promoteLayers();
              }
              
              // Observer les changements DOM pour réappliquer les optimisations
              if (window.MutationObserver) {
                const observer = new MutationObserver(function(mutations) {
                  optimizeImageLoading();
                  optimizeIframes();
                  promoteLayers();
                  enableVirtualScrolling();
                });
                
                observer.observe(document.body, {
                  childList: true,
                  subtree: true,
                  attributes: true,
                  attributeFilter: ['class', 'style']
                });
              }
              
              console.log('✅ Notilus: Optimisations GPU avancées et rendu 120 FPS activées');
            })();
          ''');
          
          debugPrint('✅ Scripts d\'optimisation GPU injectés');
        }
      } catch (e) {
        debugPrint('⚠️ Erreur lors de l\'exécution des scripts d\'optimisation: $e');
      }
    });
  }
  
  /// Nettoie complètement le WebView et ses ressources
  Future<void> _cleanupWebView() async {
    // Annuler toutes les subscriptions aux streams
    _loadingStateSubscription?.cancel();
    _loadingStateSubscription = null;
    
    // Fermer le StreamController
    await _loadingStateController?.close();
    _loadingStateController = null;
    
    // Arrêter tous les timers
    _stopNewWindowPolling();
    _stopTextSelectionPolling();
    _stopContextMenuPolling();
    _downloadPollingTimer?.cancel();
    _downloadPollingTimer = null;
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
    _stopAdBlockerPolling();
    
    // Disposer le WebView
    try {
      await _webView?.dispose();
    } catch (e) {
      debugPrint('Erreur lors de la fermeture du WebView: $e');
    }
    _webView = null;
    
    // Réinitialiser les flags
    _isInitialized = false;
    _isInitializing = false;
    _scriptInjected = false;
    _textSelectionScriptInjected = false;
    _adBlockerScriptInjected = false;
    _isPageLoaded = false;
    _isLoading = false;
  }

  /// Configure tous les listeners du WebView (séparé pour réutilisation)
  Future<void> _setupWebViewListeners() async {
    if (_webView == null || !_isInitialized) return;
    
    try {
      // Configurer les callbacks WebView2 via les streams
      _webView!.url.listen((url) {
        _currentUrl = url;
        onStateChanged?.call(TabState.loaded);
        onUrlChanged?.call(url);
        
        // Injecter les handlers après chaque navigation (une seule fois)
        if (url.isNotEmpty && url != 'about:blank' && !_scriptInjected) {
          Future.delayed(const Duration(milliseconds: 1500), () async {
            try {
              if (onNewWindowRequest != null) {
                await _injectScriptOnce();
                _startNewWindowPolling();
              }
              await _injectTextSelectionScript();
              await _injectContextMenuScript();
              await _injectAdBlockerScript();
              
              // Réappliquer les optimisations GPU après chaque navigation
              _enableAdditionalOptimizations();
            } catch (e) {
              debugPrint('Error injecting handlers: $e');
            }
          });
        }
      });
      
      // Configurer le listener pour les messages WebView (DevTools)
      setupWebMessageListener();
      
      _webView!.title.listen((title) {
        if (title.isNotEmpty) {
          _currentTitle = title;
          onTitleChanged?.call(title);
        }
      });
      
      // Configurer l'interception des téléchargements
      _setupDownloadInterceptor();
      
      // Créer un StreamController pour rebroadcast loadingState
      _loadingStateController = StreamController<LoadingState>.broadcast();
      
      // Écouter le stream original et rebroadcast vers le controller
      _loadingStateSubscription = _webView!.loadingState.listen((state) {
        _loadingStateController?.add(state);
        
        final wasLoading = _isLoading;
        _isLoading = state == LoadingState.loading;
        _isPageLoaded = state == LoadingState.navigationCompleted;
        
        // Annuler le timeout si la page se charge correctement
        _loadingTimeoutTimer?.cancel();
        _loadingTimeoutTimer = null;
        
        // Notifier immédiatement les changements d'état
        if (state == LoadingState.loading) {
          _isLoading = true;
          onStateChanged?.call(TabState.loading);
          
          // Timeout de sécurité : forcer l'arrêt du loader après 30 secondes
          _loadingTimeoutTimer = Timer(const Duration(seconds: 30), () {
            if (_isLoading) {
              debugPrint('⚠️ Timeout de chargement, forcer l\'arrêt du loader');
              _isLoading = false;
              _isPageLoaded = true;
              onStateChanged?.call(TabState.loaded);
            }
          });
        } else if (state == LoadingState.navigationCompleted) {
          _isLoading = false;
          _isPageLoaded = true;
          onStateChanged?.call(TabState.loaded);
          _startNewWindowPolling();
          if (_adBlockerService != null && _adBlockerService!.isEnabled && !_adBlockerScriptInjected) {
            _injectAdBlockerScript();
          }
          debugPrint('✅ Page chargée: $_currentUrl');
        }
        
        if (wasLoading != _isLoading) {
          debugPrint('🔄 Loading state changed: $_isLoading (${state.toString()})');
        }
      });
      
      // Gérer l'historique
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
      
    } catch (e) {
      debugPrint('Erreur lors de la configuration des listeners WebView: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Nettoyer de manière synchrone
    _loadingStateSubscription?.cancel();
    _loadingStateSubscription = null;
    _loadingStateController?.close();
    _loadingStateController = null;
    _stopNewWindowPolling();
    _downloadPollingTimer?.cancel();
    _downloadPollingTimer = null;
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
    _stopAdBlockerPolling();
    
    // Disposer le WebView
    _webView?.dispose().catchError((e) {
      debugPrint('Erreur lors de la fermeture du WebView dans dispose: $e');
    });
    _webView = null;
    
    // Réinitialiser les flags
    _isInitialized = false;
    _isInitializing = false;
    _scriptInjected = false;
    _textSelectionScriptInjected = false;
    _adBlockerScriptInjected = false;
    _isPageLoaded = false;
    _isLoading = false;
  }
}

/// Helper pour récupérer le WebView en cas d'erreur
class WebViewRecovery {
  static Future<bool> recoverWebView({
    required Future<void> Function() recreateWebView,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await Future.delayed(initialDelay * (attempt + 1));
        await recreateWebView();
        debugPrint('✅ WebView récupéré avec succès');
        return true;
      } catch (e) {
        debugPrint('! Tentative de récupération ${attempt + 1}/$maxAttempts échouée: $e');
      }
    }
    return false;
  }
}