// Ce fichier est désactivé car le package webview_flutter n'est pas utilisé sur Windows
// Il sera réactivé lors du support mobile (Android/iOS)
// Pour l'instant, l'application utilise WebView2 sur Windows

/*
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
      final controller = await _getController();
      await controller.loadRequest(Uri.parse(url));
    }
  }

  @override
  Future<void> goBack() async {
    if (await canGoBack() && _controller != null) {
      await _controller!.goBack();
      _updateNavigationState();
    }
  }

  @override
  Future<void> goForward() async {
    if (await canGoForward() && _controller != null) {
      await _controller!.goForward();
      _updateNavigationState();
    }
  }

  @override
  Future<void> reload() async {
    if (_controller != null) {
      await _controller!.reload();
    }
  }

  @override
  Future<void> stop() async {
    if (_controller != null) {
      await _controller!.stopLoading();
    }
  }

  @override
  Future<bool> canGoBack() async {
    if (_controller == null) return _canGoBack;
    try {
      _canGoBack = await _controller!.canGoBack();
      return _canGoBack;
    } catch (e) {
      return _canGoBack;
    }
  }

  @override
  Future<bool> canGoForward() async {
    if (_controller == null) return _canGoForward;
    try {
      _canGoForward = await _controller!.canGoForward();
      return _canGoForward;
    } catch (e) {
      return _canGoForward;
    }
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
    if (_controller == null) return null;
    try {
      await _controller!.runJavaScript(script);
      return 'executed';
    } catch (e) {
      return null;
    }
  }

  @override
  Future<dynamic> evaluateJavaScript(String script) async {
    if (_controller == null) return null;
    try {
      final result = await _controller!.runJavaScriptReturningResult(script);
      return result;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<dynamic> getController() async {
    if (_controller == null) {
      await _getController();
    }
    return _controller;
  }

  Future<void> _updateNavigationState() async {
    if (_controller != null) {
      _canGoBack = await _controller!.canGoBack();
      _canGoForward = await _controller!.canGoForward();
      onCanGoBackChanged?.call(_canGoBack);
      onCanGoForwardChanged?.call(_canGoForward);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
*/
