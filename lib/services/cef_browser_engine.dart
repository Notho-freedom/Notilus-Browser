import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:webview_cef/webview_cef.dart';
import 'browser_engine.dart';
import '../models/tab_model.dart';

/// Implémentation réelle du moteur de rendu avec CEF (Chromium Embedded Framework)
class CEFBrowserEngine extends BrowserEngine {
  WebViewCefController? _controller;
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
  Function(TabState)? onStateChanged;

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // CEF s'initialise automatiquement avec webview_cef
      _isInitialized = true;
    } catch (e) {
      debugPrint('CEF initialization error: $e');
    }
  }

  Future<WebViewCefController> _getController() async {
    if (_controller == null) {
      await initialize();
      
      _controller = WebViewCefController(
        onLoadStart: (String url) {
          _currentUrl = url;
          onStateChanged?.call(TabState.loading);
          onUrlChanged?.call(url);
        },
        onLoadEnd: (String url) async {
          _currentUrl = url;
          try {
            _currentTitle = await _controller?.getTitle() ?? url;
            _canGoBack = await _controller?.canGoBack() ?? false;
            _canGoForward = await _controller?.canGoForward() ?? false;
          } catch (e) {
            _currentTitle = url;
            _canGoBack = false;
            _canGoForward = false;
          }
          
          onStateChanged?.call(TabState.loaded);
          onTitleChanged?.call(_currentTitle ?? url);
          onCanGoBackChanged?.call(_canGoBack);
          onCanGoForwardChanged?.call(_canGoForward);
        },
        onLoadError: (String url, int errorCode, String errorDescription) {
          onStateChanged?.call(TabState.error);
        },
      );
    }
    return _controller!;
  }

  @override
  Future<void> navigate(String url) async {
    final controller = await _getController();
    await controller.loadUrl(url);
    _currentUrl = url;
    _canGoBack = false;
    _canGoForward = false;
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
      final url = await _controller!.getUrl();
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
      await _controller!.evaluateJavaScript(script);
      return 'executed';
    } catch (e) {
      return null;
    }
  }

  @override
  Future<dynamic> evaluateJavaScript(String script) async {
    if (_controller == null) return null;
    try {
      final result = await _controller!.evaluateJavaScript(script);
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

