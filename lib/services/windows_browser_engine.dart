import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'browser_engine.dart';
import '../models/tab_model.dart';

/// Implémentation pour Windows utilisant le navigateur par défaut
/// Note: webview_flutter ne supporte pas Windows Desktop
/// Cette implémentation ouvre les URLs dans le navigateur par défaut
/// Pour un vrai moteur intégré, il faudra utiliser CEF
class WindowsBrowserEngine extends BrowserEngine {
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
  Future<void> initialize() async {
    // Initialisation
  }

  @override
  Future<void> navigate(String url) async {
    _currentUrl = url;
    onStateChanged?.call(TabState.loading);
    onUrlChanged?.call(url);
    
    // Ouvrir dans le navigateur par défaut
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Simuler le chargement
      Future.delayed(const Duration(seconds: 1), () {
        _currentTitle = _extractDomain(url) ?? url;
        onStateChanged?.call(TabState.loaded);
        onTitleChanged?.call(_currentTitle ?? url);
      });
    } else {
      onStateChanged?.call(TabState.error);
    }
  }

  @override
  Future<void> goBack() async {
    // Non supporté avec url_launcher
    _canGoBack = false;
    onCanGoBackChanged?.call(false);
  }

  @override
  Future<void> goForward() async {
    // Non supporté avec url_launcher
    _canGoForward = false;
    onCanGoForwardChanged?.call(false);
  }

  @override
  Future<void> reload() async {
    if (_currentUrl != null) {
      await navigate(_currentUrl!);
    }
  }

  @override
  Future<void> stop() async {
    // Non supporté avec url_launcher
  }

  @override
  Future<bool> canGoBack() async => _canGoBack;

  @override
  Future<bool> canGoForward() async => _canGoForward;

  @override
  Future<String?> getCurrentUrl() async => _currentUrl;

  @override
  Future<String?> getTitle() async => _currentTitle;

  @override
  Future<String?> executeJavaScript(String script) async {
    // Non supporté avec url_launcher
    return null;
  }

  @override
  Future<dynamic> evaluateJavaScript(String script) async {
    // Non supporté avec url_launcher
    return null;
  }

  @override
  Future<dynamic> getController() async => null;

  String? _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }
}

