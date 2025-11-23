import 'package:webview_flutter/webview_flutter.dart';
import 'browser_engine.dart';
import '../models/tab_model.dart';

/// Implémentation réelle du moteur de rendu avec WebView
class WebViewBrowserEngine extends BrowserEngine {
  WebViewController? _controller;
  String? _currentUrl;
  String? _currentTitle;
  bool _canGoBack = false;
  bool _canGoForward = false;
  Function(String)? onUrlChanged;
  Function(String)? onTitleChanged;
  Function(bool)? onCanGoBackChanged;
  Function(bool)? onCanGoForwardChanged;
  Function(TabState)? onStateChanged;

  @override
  Future<void> initialize() async {
    // Initialisation du WebView
    // Le contrôleur sera créé lors de la première navigation
  }

  Future<WebViewController> _getController() async {
    if (_controller == null) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              _currentUrl = url;
              onStateChanged?.call(TabState.loading);
              onUrlChanged?.call(url);
            },
            onPageFinished: (String url) async {
              _currentUrl = url;
              _currentTitle = await _controller?.getTitle() ?? url;
              _canGoBack = await _controller?.canGoBack() ?? false;
              _canGoForward = await _controller?.canGoForward() ?? false;
              
              onStateChanged?.call(TabState.loaded);
              onTitleChanged?.call(_currentTitle ?? url);
              onCanGoBackChanged?.call(_canGoBack);
              onCanGoForwardChanged?.call(_canGoForward);
            },
            onWebResourceError: (WebResourceError error) {
              onStateChanged?.call(TabState.error);
            },
          ),
        );
    }
    return _controller!;
  }

  @override
  Future<void> navigate(String url) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // TODO: Implémenter navigation WebView pour mobile
      _currentUrl = url;
      onStateChanged?.call(TabState.loading);
      onUrlChanged?.call(url);
      
      // Simuler le chargement
      Future.delayed(const Duration(seconds: 1), () {
        _currentTitle = url;
        _canGoBack = false;
        _canGoForward = false;
        onStateChanged?.call(TabState.loaded);
        onTitleChanged?.call(_currentTitle ?? url);
      });
    }
  }

  @override
  Future<void> goBack() async {
    // TODO: Implémenter pour mobile
  }

  @override
  Future<void> goForward() async {
    // TODO: Implémenter pour mobile
  }

  @override
  Future<void> reload() async {
    // TODO: Implémenter pour mobile
  }

  @override
  Future<void> stop() async {
    // TODO: Implémenter pour mobile
  }

  @override
  Future<bool> canGoBack() async {
    if (_controller == null) return false;
    _canGoBack = await _controller!.canGoBack();
    return _canGoBack;
  }

  @override
  Future<bool> canGoForward() async {
    if (_controller == null) return false;
    _canGoForward = await _controller!.canGoForward();
    return _canGoForward;
  }

  @override
  Future<String?> getCurrentUrl() async {
    if (_controller == null) return _currentUrl;
    try {
      final url = await _controller!.currentUrl();
      _currentUrl = url;
      return url;
    } catch (e) {
      return _currentUrl;
    }
  }

  @override
  Future<String?> getTitle() async {
    if (_controller == null) return _currentTitle;
    try {
      final title = await _controller!.getTitle();
      _currentTitle = title;
      return title;
    } catch (e) {
      return _currentTitle;
    }
  }

  @override
  Future<String?> executeJavaScript(String script) async {
    // TODO: Implémenter pour mobile
    return null;
  }

  @override
  Future<dynamic> evaluateJavaScript(String script) async {
    // TODO: Implémenter pour mobile
    return null;
  }

  /// Récupère le contrôleur WebView pour l'affichage
  Future<WebViewController?> getController() async {
    if (_controller == null) {
      await _getController();
    }
    return _controller;
  }
}

