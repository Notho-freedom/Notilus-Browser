import 'package:flutter/foundation.dart';
import 'package:webview_win_floating/webview.dart';
import 'browser_engine.dart';
import '../models/tab_model.dart';

/// Implémentation réelle du moteur de rendu avec WebView Windows Floating
class WinFloatingBrowserEngine extends BrowserEngine {
  WebView? _webView;
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

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _webView = WebView();
      _isInitialized = true;
    } catch (e) {
      debugPrint('WebView initialization error: $e');
    }
  }

  @override
  Future<void> navigate(String url) async {
    if (_webView == null) {
      await initialize();
    }
    
    if (_webView != null) {
      onStateChanged?.call(TabState.loading);
      onUrlChanged?.call(url);
      
      try {
        await _webView!.loadUrl(url);
        _currentUrl = url;
        
        // La récupération du titre se fait via les callbacks du WebView
        // Pour l'instant, on utilise le domaine
        _currentTitle = _extractDomain(url) ?? url;
        _canGoBack = true;
        _canGoForward = false;
        
        // Simuler le chargement terminé après un court délai
        Future.delayed(const Duration(milliseconds: 500), () {
          onStateChanged?.call(TabState.loaded);
          onTitleChanged?.call(_currentTitle ?? url);
          onCanGoBackChanged?.call(_canGoBack);
          onCanGoForwardChanged?.call(_canGoForward);
        });
      } catch (e) {
        debugPrint('Navigation error: $e');
        onStateChanged?.call(TabState.error);
      }
    }
  }

  @override
  Future<void> goBack() async {
    if (_webView != null && await canGoBack()) {
      await _webView!.goBack();
      _updateNavigationState();
    }
  }

  @override
  Future<void> goForward() async {
    if (_webView != null && await canGoForward()) {
      await _webView!.goForward();
      _updateNavigationState();
    }
  }

  @override
  Future<void> reload() async {
    if (_webView != null) {
      await _webView!.reload();
    }
  }

  @override
  Future<void> stop() async {
    if (_webView != null) {
      await _webView!.stop();
    }
  }

  @override
  Future<bool> canGoBack() async {
    if (_webView == null) return _canGoBack;
    try {
      _canGoBack = await _webView!.canGoBack();
      return _canGoBack;
    } catch (e) {
      return _canGoBack;
    }
  }

  @override
  Future<bool> canGoForward() async {
    if (_webView == null) return _canGoForward;
    try {
      _canGoForward = await _webView!.canGoForward();
      return _canGoForward;
    } catch (e) {
      return _canGoForward;
    }
  }

  @override
  Future<String?> getCurrentUrl() async {
    // WebView Windows ne supporte pas directement currentUrl de manière asynchrone
    return _currentUrl;
  }

  @override
  Future<String?> getTitle() async {
    // WebView Windows ne supporte pas directement getTitle
    return _currentTitle;
  }

  @override
  Future<String?> executeJavaScript(String script) async {
    if (_webView == null) return null;
    try {
      await _webView!.evaluateJavaScript(script);
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
      final result = await _webView!.evaluateJavaScript(script);
      return result;
    } catch (e) {
      debugPrint('JavaScript evaluation error: $e');
      return null;
    }
  }

  @override
  Future<dynamic> getController() async {
    if (_webView == null) {
      await initialize();
    }
    return _webView;
  }

  Future<void> _updateNavigationState() async {
    if (_webView != null) {
      _canGoBack = await _webView!.canGoBack();
      _canGoForward = await _webView!.canGoForward();
      onCanGoBackChanged?.call(_canGoBack);
      onCanGoForwardChanged?.call(_canGoForward);
    }
  }

  String? _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _webView?.dispose();
    _webView = null;
  }
}
