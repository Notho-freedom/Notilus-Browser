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
  
  /// Callback pour les téléchargements
  Function(String url, String? fileName)? onDownloadRequested;
  
  /// Callback pour les messages WebView (DevTools)
  Function(String message)? onWebMessage;
  
  /// ID du tab associé (pour DevTools)
  String? tabId;

  bool _isInitialized = false;
  Timer? _newWindowPollingTimer;
  Timer? _downloadPollingTimer;
  Timer? _loadingTimeoutTimer; // Timeout pour forcer l'arrêt du loader
  
  // État de visibilité pour adapter la fréquence du polling
  bool _isTabActive = true;
  bool _isPageLoaded = false;
  bool _isLoading = false; // État de chargement réel
  
  // StreamController pour rebroadcast loadingState (permet plusieurs listeners)
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
            // Utiliser getBoundingClientRect qui donne les coordonnées relatives à la viewport
            var x = Math.round(rect.left + rect.width / 2);
            var y = Math.round(rect.top);
            document.body.setAttribute('data-selected-text', encodeURIComponent(text));
            document.body.setAttribute('data-selection-x', x.toString());
            document.body.setAttribute('data-selection-y', y.toString());
            console.log('Notilus: Sélection détectée:', text.substring(0, 50), 'à', x, y);
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
  
  /// Service de blocage de publicités
  AdBlockerService? _adBlockerService;
  
  /// Définit le service de blocage de publicités
  void setAdBlockerService(AdBlockerService? service) {
    _adBlockerService = service;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // S'assurer qu'on ferme complètement l'ancien WebView s'il existe
    if (_webView != null) {
      await _cleanupWebView();
    }
    
    try {
      _webView = WebviewController();
      await _webView!.initialize();
      
      // Si l'initialisation réussit sans exception, on considère que c'est initialisé
      _isInitialized = true;
      
      // Configurer les listeners du WebView
      await _setupWebViewListeners();
      
    } catch (e) {
      debugPrint('WebView2 initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Future<void> navigate(String url) async {
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
    
    if (_webView != null) {
      // Réinitialiser le flag d'injection pour la nouvelle page
      _scriptInjected = false;
      _textSelectionScriptInjected = false;
      _isPageLoaded = false;
      
      // Forcer l'état de chargement immédiatement
      _isLoading = true;
      onStateChanged?.call(TabState.loading);
      onUrlChanged?.call(url);
      
      // Utiliser retry avec fallback gracieux
      try {
        await ErrorHandler.withRetry(
          fn: () => _webView!.loadUrl(url),
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 500),
          shouldRetry: (error) {
            // Réessayer seulement pour les erreurs réseau
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
        
        // Tentative de récupération : fermer complètement avant de recréer
        final recovered = await WebViewRecovery.recoverWebView(
          recreateWebView: () async {
            // Fermer complètement l'ancien WebView
            await _cleanupWebView();
            
            // Attendre un peu pour que les ressources soient libérées
            await Future.delayed(const Duration(milliseconds: 100));
            
            // Recréer le WebView
            _webView = WebviewController();
            await _webView!.initialize();
            
            // Réinitialiser les listeners
            await _setupWebViewListeners();
            
            // Naviguer vers l'URL
            await _webView!.loadUrl(url);
          },
        );
        
        if (!recovered) {
          onStateChanged?.call(TabState.error);
        }
      }
    }
  }
  
  /// Injecte le script une seule fois (évite la réinjection)
  Future<void> _injectScriptOnce() async {
    if (_scriptInjected || _webView == null || onNewWindowRequest == null) return;
    
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
  
  /// Obtient l'état de chargement réel du WebView (plus précis que TabState)
  bool get isLoading => _isLoading;
  
  /// Stream broadcast pour loadingState (permet plusieurs listeners)
  Stream<LoadingState> get loadingStateStream => 
      _loadingStateController?.stream ?? const Stream<LoadingState>.empty();

  /// Démarre le polling pour détecter les nouvelles fenêtres avec fréquence adaptative
  void _startNewWindowPolling() {
    _newWindowPollingTimer?.cancel();
    
    // Fréquence adaptative : plus lent si l'onglet est inactif
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
  /// Priorité absolue pour l'onglet actif
  void setTabActive(bool isActive) {
    if (_isTabActive != isActive) {
      _isTabActive = isActive;
      
      if (isActive) {
        // Onglet actif : priorité absolue
        // Réduire le polling des autres onglets (fait automatiquement)
        _startNewWindowPolling();
        
        // Le WebView2 gère automatiquement la priorité pour l'onglet actif
        // Pas besoin de forcer le focus, le navigate() le fait déjà
      } else {
        // Onglet inactif : réduire les ressources
        // Augmenter l'intervalle de polling
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
  /// (utilisé comme fallback si onNewWindowRequest n'est pas disponible)
  Future<void> _checkForNewWindowRequests() async {
    if (_webView == null || onNewWindowRequest == null || !_isTabActive) return;
    
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
        // Éviter les appels répétés pour la même URL
        if (result != _lastNewWindowUrl) {
          _lastNewWindowUrl = result;
          debugPrint('Nouvelle fenêtre détectée via JavaScript: $result');
          onNewWindowRequest?.call(result);
          // Réinitialiser le cache après un délai
          Future.delayed(const Duration(seconds: 1), () {
            _lastNewWindowUrl = null;
          });
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  @override
  Future<void> openDevTools() async {
    // webview_windows 0.2.0 ne supporte pas les DevTools nativement
    // On essaie d'utiliser les APIs WebView2 natives via une approche alternative
    if (_webView == null) return;
    
    try {
      // Méthode 1: Essayer d'ouvrir via JavaScript (ne fonctionne pas vraiment)
      // Méthode 2: Utiliser les APIs natives de WebView2 via FFI (nécessite un plugin custom)
      // Pour l'instant, on affiche un message informatif
      debugPrint('⚠️ DevTools non disponibles avec webview_windows 0.2.0');
      debugPrint('💡 Pour activer les DevTools, passez à webview2_wrapper ou créez un plugin custom');
      
      // Tentative d'ouverture via injection JavaScript (limité)
      await _webView!.executeScript('''
        (function() {
          console.warn('DevTools non disponibles avec webview_windows 0.2.0');
          console.warn('Pour activer les DevTools, utilisez un package qui supporte WebView2 DevTools');
        })();
      ''');
    } catch (e) {
      debugPrint('Erreur lors de la tentative d\'ouverture des DevTools: $e');
    }
  }
  
  /// Configure le listener pour les messages WebView (DevTools)
  void setupWebMessageListener() {
    if (_webView == null) return;
    
    // Note: webview_windows utilise webMessage stream pour les messages postMessage
    try {
      _webView!.webMessage.listen((message) {
        if (message != null && message.isNotEmpty) {
          // Transmettre au callback
          onWebMessage?.call(message);
        }
      });
    } catch (e) {
      debugPrint('Erreur setup webMessage listener: $e');
    }
  }
  
  /// Injecte le script de détection de sélection de texte
  Future<void> _injectTextSelectionScript() async {
    if (_textSelectionScriptInjected || _webView == null) return;
    
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
      if (_webView == null || !_isInitialized) {
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
              // Effacer les attributs après lecture
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
              debugPrint('📝 Sélection détectée: "$selectedText" à ($x, $y)');
              final selectionService = TextSelectionService();
              // Les coordonnées sont relatives à la page web avec scroll
              // On les utilise telles quelles, le widget TextSelectionMenu ajustera pour l'écran visible
              selectionService.showMenu(selectedText, Offset(x.toDouble(), y.toDouble()));
              debugPrint('✅ Menu affiché pour: "$selectedText"');
            }
          } catch (e) {
            debugPrint('Erreur parsing sélection texte: $e');
          }
        }
      } catch (e) {
        // Ignorer les erreurs silencieusement
      }
    });
  }
  
  /// Arrête le polling de sélection de texte
  void _stopTextSelectionPolling() {
    _textSelectionPollingTimer?.cancel();
    _textSelectionPollingTimer = null;
  }

  /// Configure l'interception des téléchargements
  void _setupDownloadInterceptor() {
    // Annuler le timer précédent s'il existe
    _downloadPollingTimer?.cancel();
    
    // Démarrer le polling pour les téléchargements
    _downloadPollingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_webView == null || !_isInitialized) {
        return; // Ne pas annuler, juste attendre
      }
      
      try {
        // Injecter le handler une seule fois et vérifier les téléchargements
        final result = await _webView!.executeScript('''
          (function() {
            // Installer le handler s'il n'est pas déjà installé
            if (!window._flutterDownloadHandlerInstalled) {
              window._flutterDownloadHandlerInstalled = true;
              window._pendingDownloads = [];
              
              // Extensions de fichiers téléchargeables
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
              
              // Fonction pour vérifier si c'est un téléchargement
              function isDownloadUrl(href) {
                if (!href) return false;
                var lowerHref = href.toLowerCase();
                
                // Vérifier les extensions
                for (var i = 0; i < downloadExtensions.length; i++) {
                  // Vérifier si l'extension est à la fin ou suivie de paramètres
                  var ext = downloadExtensions[i];
                  var idx = lowerHref.lastIndexOf(ext);
                  if (idx !== -1) {
                    var afterExt = lowerHref.substring(idx + ext.length);
                    if (afterExt === '' || afterExt.charAt(0) === '?' || afterExt.charAt(0) === '#') {
                      return true;
                    }
                  }
                }
                
                // Vérifier les patterns de téléchargement
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
              
              // Extraire le nom de fichier depuis l'URL
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
              
              // Intercepter les clics
              document.addEventListener('click', function(e) {
                var target = e.target;
                while (target && target.tagName !== 'A') {
                  target = target.parentElement;
                }
                
                if (target && target.tagName === 'A') {
                  var href = target.getAttribute('href');
                  var download = target.getAttribute('download');
                  
                  // Forcer le téléchargement si attribut download présent ou URL de téléchargement détectée
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
                      // URL invalide, utiliser tel quel
                      window._pendingDownloads.push({
                        url: href,
                        fileName: download || null
                      });
                    }
                    
                    return false;
                  }
                }
              }, true);
              
              // Intercepter aussi les formulaires de téléchargement
              document.addEventListener('submit', function(e) {
                var form = e.target;
                if (form && form.tagName === 'FORM') {
                  var action = form.getAttribute('action') || '';
                  if (isDownloadUrl(action)) {
                    // Ne pas empêcher le submit mais marquer comme téléchargement
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
            
            // Récupérer et vider les téléchargements en attente
            if (window._pendingDownloads && window._pendingDownloads.length > 0) {
              var downloads = JSON.stringify(window._pendingDownloads);
              window._pendingDownloads = [];
              return downloads;
            }
            
            return null;
          })();
        ''');
        
        // Traiter les téléchargements détectés
        if (result != null && result != 'null' && result.toString().isNotEmpty && result.toString() != 'undefined') {
          await _processDownloadResult(result.toString());
        }
      } catch (e) {
        // Ignorer les erreurs silencieusement (page en cours de chargement, etc.)
      }
    });
  }
  
  /// Traite le résultat du script de détection des téléchargements
  Future<void> _processDownloadResult(String jsonStr) async {
    try {
      // Le résultat est un tableau JSON de téléchargements
      if (!jsonStr.startsWith('[')) return;
      
      // Parser le JSON avec dart:convert
      final List<dynamic> downloads = jsonDecode(jsonStr);
      
      for (final download in downloads) {
        if (download is Map) {
          final url = download['url'] as String?;
          final fileName = download['fileName'] as String?;
          
          if (url != null && url.isNotEmpty && onDownloadRequested != null) {
            debugPrint('📥 Téléchargement intercepté: $url');
            onDownloadRequested?.call(url, fileName);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du parsing des téléchargements: $e');
      
      // Fallback: essayer de parser comme un objet unique
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
    if (_webView == null) return;
    
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
    if (_webView == null) return;
    
    try {
      await executeJavaScript('''
        if ('caches' in window) {
          caches.keys().then(function(names) {
            for (let name of names)
              caches.delete(name);
          });
        }
        // Clear localStorage and sessionStorage
        localStorage.clear();
        sessionStorage.clear();
      ''');
      debugPrint('💾 Cache effacé pour le WebView');
    } catch (e) {
      debugPrint('Erreur lors de l\'effacement du cache: $e');
    }
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
    _downloadPollingTimer?.cancel();
    _downloadPollingTimer = null;
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
    
    // Disposer le WebView
    try {
      await _webView?.dispose();
    } catch (e) {
      debugPrint('Erreur lors de la fermeture du WebView: $e');
    }
    _webView = null;
    
    // Réinitialiser les flags
    _isInitialized = false;
    _scriptInjected = false;
    _textSelectionScriptInjected = false;
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
              // Injecter le handler pour les nouvelles fenêtres (script minifié)
              if (onNewWindowRequest != null) {
                await _injectScriptOnce();
                // Démarrer le polling pour détecter les nouvelles fenêtres
                _startNewWindowPolling();
              }
              // Injecter le script de détection de sélection de texte
              await _injectTextSelectionScript();
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
      
      // Créer un StreamController pour rebroadcast loadingState (permet plusieurs listeners)
      _loadingStateController = StreamController<LoadingState>.broadcast();
      
      // Écouter le stream original et rebroadcast vers le controller
      _loadingStateSubscription = _webView!.loadingState.listen((state) {
        // Rebroadcast vers le controller (permet plusieurs listeners)
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
          // Forcer la mise à jour immédiate de l'état
          _isLoading = false;
          _isPageLoaded = true;
          onStateChanged?.call(TabState.loaded);
          // Ajuster la fréquence du polling après chargement
          _startNewWindowPolling();
          debugPrint('✅ Page chargée: $_currentUrl');
        }
        
        // Debug pour vérifier la synchronisation
        if (wasLoading != _isLoading) {
          debugPrint('🔄 Loading state changed: $_isLoading (${state.toString()})');
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
      debugPrint('Erreur lors de la configuration des listeners WebView: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Nettoyer de manière synchrone (les opérations async seront gérées en arrière-plan)
    _loadingStateSubscription?.cancel();
    _loadingStateSubscription = null;
    _loadingStateController?.close();
    _loadingStateController = null;
    _stopNewWindowPolling();
    _downloadPollingTimer?.cancel();
    _downloadPollingTimer = null;
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
    
    // Disposer le WebView (peut être async mais on ne peut pas attendre dans dispose)
    _webView?.dispose().catchError((e) {
      debugPrint('Erreur lors de la fermeture du WebView dans dispose: $e');
    });
    _webView = null;
    
    // Réinitialiser les flags
    _isInitialized = false;
    _scriptInjected = false;
    _isPageLoaded = false;
    _isLoading = false;
  }
}
