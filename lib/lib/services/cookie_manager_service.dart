import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'webview2_browser_engine.dart';
import 'tab_webview_manager.dart';
import 'tab_manager.dart';
import '../models/tab_model.dart';

/// Modèle pour représenter un cookie
class CookieInfo {
  final String name;
  final String value;
  final String domain;
  final String? path;
  final DateTime? expires;
  final bool httpOnly;
  final bool secure;
  final bool sameSite;

  CookieInfo({
    required this.name,
    required this.value,
    required this.domain,
    this.path,
    this.expires,
    this.httpOnly = false,
    this.secure = false,
    this.sameSite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'domain': domain,
      'path': path,
      'expires': expires?.toIso8601String(),
      'httpOnly': httpOnly,
      'secure': secure,
      'sameSite': sameSite,
    };
  }

  factory CookieInfo.fromJson(Map<String, dynamic> json) {
    return CookieInfo(
      name: json['name'] as String,
      value: json['value'] as String,
      domain: json['domain'] as String,
      path: json['path'] as String?,
      expires: json['expires'] != null ? DateTime.parse(json['expires']) : null,
      httpOnly: json['httpOnly'] as bool? ?? false,
      secure: json['secure'] as bool? ?? false,
      sameSite: json['sameSite'] as bool? ?? false,
    );
  }
}

/// Service de gestion des cookies pour Notilus
class CookieManagerService extends ChangeNotifier {
  final TabWebViewManager? _webViewManager;
  final TabManager? _tabManager;

  CookieManagerService({
    TabWebViewManager? webViewManager,
    TabManager? tabManager,
  })  : _webViewManager = webViewManager,
        _tabManager = tabManager;

  /// Obtient tous les cookies pour l'onglet actif
  Future<List<CookieInfo>> getCookiesForActiveTab() async {
    if (_tabManager?.activeTab == null || _webViewManager == null) {
      return [];
    }

    final activeTab = _tabManager!.activeTab!;
    if (activeTab.isPrivate) {
      // Les onglets privés n'ont pas de cookies persistants
      return [];
    }

    return getCookiesForTab(activeTab.id);
  }

  /// Obtient tous les cookies pour un onglet spécifique
  Future<List<CookieInfo>> getCookiesForTab(String tabId) async {
    if (_webViewManager == null) return [];

    try {
      final engine = _webViewManager!.getEngineForTab(tabId);
      if (engine == null || engine is! WebView2BrowserEngine) {
        return [];
      }

      // Récupérer les cookies via JavaScript
      final result = await engine.executeJavaScript('''
        (function() {
          var cookies = document.cookie.split(';');
          var result = [];
          for (var i = 0; i < cookies.length; i++) {
            var cookie = cookies[i].trim();
            if (cookie) {
              var parts = cookie.split('=');
              if (parts.length >= 2) {
                result.push({
                  name: parts[0],
                  value: parts.slice(1).join('='),
                  domain: window.location.hostname,
                  path: '/',
                });
              }
            }
          }
          return JSON.stringify(result);
        })();
      ''');

      if (result == null || result.isEmpty) {
        return [];
      }

      try {
        final List<dynamic> cookiesJson = 
            (result as String).startsWith('[') 
                ? jsonDecode(result) as List<dynamic>
                : [];
        
        return cookiesJson
            .map((json) => CookieInfo.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Erreur parsing cookies: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Erreur récupération cookies: $e');
      return [];
    }
  }

  /// Supprime un cookie spécifique
  Future<bool> deleteCookie(String tabId, String cookieName, {String? domain, String? path}) async {
    if (_webViewManager == null) return false;

    try {
      final engine = _webViewManager!.getEngineForTab(tabId);
      if (engine == null || engine is! WebView2BrowserEngine) {
        return false;
      }

      final domainStr = domain ?? 'window.location.hostname';
      final pathStr = path ?? '/';

      await engine.executeJavaScript('''
        (function() {
          var domain = $domainStr;
          var path = '$pathStr';
          document.cookie = '$cookieName=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=' + path + '; domain=' + domain + ';';
          document.cookie = '$cookieName=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=' + path + ';';
        })();
      ''');

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur suppression cookie: $e');
      return false;
    }
  }

  /// Supprime tous les cookies pour un onglet
  Future<bool> clearCookiesForTab(String tabId) async {
    if (_webViewManager == null) return false;

    try {
      final engine = _webViewManager!.getEngineForTab(tabId);
      if (engine == null || engine is! WebView2BrowserEngine) {
        return false;
      }

      await engine.clearCookies();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur effacement cookies: $e');
      return false;
    }
  }

  /// Supprime tous les cookies pour tous les onglets
  Future<void> clearAllCookies() async {
    if (_tabManager == null || _webViewManager == null) return;

    try {
      for (final tab in _tabManager!.tabs) {
        if (!tab.isPrivate) {
          await clearCookiesForTab(tab.id);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur effacement tous les cookies: $e');
    }
  }

  /// Obtient le nombre de cookies pour l'onglet actif
  Future<int> getCookieCountForActiveTab() async {
    final cookies = await getCookiesForActiveTab();
    return cookies.length;
  }
}

