import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'webview_scripts.dart';

/// Gestionnaire d'événements unifié pour le WebView
/// Centralise la gestion des événements au lieu d'utiliser plusieurs timers de polling
class WebViewEventHandler {
  /// Callback pour exécuter du JavaScript
  final Future<dynamic> Function(String script)? executeScript;
  
  /// Callbacks pour les différents événements
  Function(String url)? onNewWindowRequest;
  Function(String text, Offset position)? onTextSelected;
  Function(ContextMenuData data)? onContextMenuRequest;
  Function(String url, String? fileName)? onDownloadRequest;
  Function(int count)? onAdsBlocked;
  
  /// État d'injection des scripts
  bool _newWindowScriptInjected = false;
  bool _textSelectionScriptInjected = false;
  bool _contextMenuScriptInjected = false;
  bool _downloadScriptInjected = false;
  
  /// Timer unique pour le polling combiné
  Timer? _pollingTimer;
  
  /// Intervalle de polling (plus long car combiné)
  static const Duration _pollingInterval = Duration(milliseconds: 300);
  
  /// État actif/inactif
  bool _isActive = true;
  
  WebViewEventHandler({this.executeScript});
  
  /// Injecte tous les scripts nécessaires
  Future<void> injectAllScripts() async {
    if (executeScript == null) return;
    
    await Future.wait([
      _injectNewWindowScript(),
      _injectTextSelectionScript(),
      _injectContextMenuScript(),
      _injectDownloadScript(),
    ]);
    
    // Démarrer le polling combiné après injection
    _startCombinedPolling();
  }
  
  /// Injecte le script de nouvelle fenêtre
  Future<void> _injectNewWindowScript() async {
    if (_newWindowScriptInjected || onNewWindowRequest == null) return;
    
    try {
      await executeScript!(NewWindowScripts.interceptScript);
      _newWindowScriptInjected = true;
      debugPrint('✅ Script nouvelle fenêtre injecté');
    } catch (e) {
      debugPrint('❌ Erreur injection script nouvelle fenêtre: $e');
    }
  }
  
  /// Injecte le script de sélection de texte
  Future<void> _injectTextSelectionScript() async {
    if (_textSelectionScriptInjected || onTextSelected == null) return;
    
    try {
      await executeScript!(TextSelectionScripts.installScript);
      _textSelectionScriptInjected = true;
      debugPrint('✅ Script sélection de texte injecté');
    } catch (e) {
      debugPrint('❌ Erreur injection script sélection: $e');
    }
  }
  
  /// Injecte le script de menu contextuel
  Future<void> _injectContextMenuScript() async {
    if (_contextMenuScriptInjected || onContextMenuRequest == null) return;
    
    try {
      await executeScript!(ContextMenuScripts.installScript);
      _contextMenuScriptInjected = true;
      debugPrint('✅ Script menu contextuel injecté');
    } catch (e) {
      debugPrint('❌ Erreur injection script menu contextuel: $e');
    }
  }
  
  /// Injecte le script d'interception des téléchargements
  Future<void> _injectDownloadScript() async {
    if (_downloadScriptInjected || onDownloadRequest == null) return;
    
    try {
      await executeScript!(DownloadScripts.installScript);
      _downloadScriptInjected = true;
      debugPrint('✅ Script téléchargement injecté');
    } catch (e) {
      debugPrint('❌ Erreur injection script téléchargement: $e');
    }
  }
  
  /// Démarre le polling combiné pour tous les événements
  void _startCombinedPolling() {
    _pollingTimer?.cancel();
    
    if (!_isActive) return;
    
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      if (!_isActive || executeScript == null) return;
      
      try {
        // Polling combiné avec un seul appel JavaScript
        final result = await executeScript!(_combinedPollingScript);
        
        if (result != null && result != 'null' && result.toString().isNotEmpty) {
          _processPollingResult(result.toString());
        }
      } catch (e) {
        // Ignorer les erreurs silencieusement
      }
    });
  }
  
  /// Script de polling combiné
  static const String _combinedPollingScript = '''
    (function() {
      var result = {};
      
      // Nouvelle fenêtre
      if (document.body) {
        var newWindowUrl = document.body.getAttribute('data-new-window-url');
        if (newWindowUrl) {
          document.body.removeAttribute('data-new-window-url');
          result.newWindow = newWindowUrl;
        }
        
        // Sélection de texte
        var selectedText = document.body.getAttribute('data-selected-text');
        var selX = document.body.getAttribute('data-selection-x');
        var selY = document.body.getAttribute('data-selection-y');
        if (selectedText && selX && selY) {
          document.body.removeAttribute('data-selected-text');
          document.body.removeAttribute('data-selection-x');
          document.body.removeAttribute('data-selection-y');
          result.textSelection = {
            text: decodeURIComponent(selectedText),
            x: parseInt(selX),
            y: parseInt(selY)
          };
        }
        
        // Menu contextuel
        var ctxType = document.body.getAttribute('data-context-type');
        var ctxX = document.body.getAttribute('data-context-x');
        var ctxY = document.body.getAttribute('data-context-y');
        if (ctxType && ctxX && ctxY) {
          var imageUrl = document.body.getAttribute('data-context-image-url');
          var linkUrl = document.body.getAttribute('data-context-link-url');
          var ctxText = document.body.getAttribute('data-context-text');
          
          document.body.removeAttribute('data-context-type');
          document.body.removeAttribute('data-context-x');
          document.body.removeAttribute('data-context-y');
          document.body.removeAttribute('data-context-image-url');
          document.body.removeAttribute('data-context-link-url');
          document.body.removeAttribute('data-context-text');
          
          result.contextMenu = {
            type: ctxType,
            x: parseInt(ctxX),
            y: parseInt(ctxY),
            imageUrl: imageUrl ? decodeURIComponent(imageUrl) : null,
            linkUrl: linkUrl ? decodeURIComponent(linkUrl) : null,
            text: ctxText ? decodeURIComponent(ctxText) : null
          };
        }
        
        // Téléchargements
        if (window._pendingDownloads && window._pendingDownloads.length > 0) {
          result.downloads = window._pendingDownloads;
          window._pendingDownloads = [];
        }
        
        // Ad blocker count
        var adBlockCount = document.body.getAttribute('data-adblock-count');
        if (adBlockCount) {
          result.adsBlocked = parseInt(adBlockCount);
        }
      }
      
      return Object.keys(result).length > 0 ? JSON.stringify(result) : null;
    })();
  ''';
  
  /// Traite le résultat du polling combiné
  void _processPollingResult(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // Nouvelle fenêtre
      if (data['newWindow'] != null) {
        onNewWindowRequest?.call(data['newWindow'] as String);
      }
      
      // Sélection de texte
      if (data['textSelection'] != null) {
        final sel = data['textSelection'] as Map<String, dynamic>;
        final text = sel['text'] as String?;
        final x = sel['x'] as int?;
        final y = sel['y'] as int?;
        
        if (text != null && text.isNotEmpty && x != null && y != null) {
          onTextSelected?.call(text, Offset(x.toDouble(), y.toDouble()));
        }
      }
      
      // Menu contextuel
      if (data['contextMenu'] != null) {
        final ctx = data['contextMenu'] as Map<String, dynamic>;
        onContextMenuRequest?.call(ContextMenuData(
          type: ctx['type'] as String,
          x: ctx['x'] as int,
          y: ctx['y'] as int,
          imageUrl: ctx['imageUrl'] as String?,
          linkUrl: ctx['linkUrl'] as String?,
          text: ctx['text'] as String?,
        ));
      }
      
      // Téléchargements
      if (data['downloads'] != null) {
        final downloads = data['downloads'] as List<dynamic>;
        for (final dl in downloads) {
          if (dl is Map) {
            final url = dl['url'] as String?;
            final fileName = dl['fileName'] as String?;
            if (url != null && url.isNotEmpty) {
              onDownloadRequest?.call(url, fileName);
            }
          }
        }
      }
      
      // Ads bloquées
      if (data['adsBlocked'] != null) {
        onAdsBlocked?.call(data['adsBlocked'] as int);
      }
    } catch (e) {
      debugPrint('❌ Erreur parsing résultat polling: $e');
    }
  }
  
  /// Active/désactive le handler
  void setActive(bool active) {
    _isActive = active;
    
    if (active) {
      _startCombinedPolling();
    } else {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }
  
  /// Réinitialise l'état d'injection (après navigation)
  void resetInjectionState() {
    _newWindowScriptInjected = false;
    _textSelectionScriptInjected = false;
    _contextMenuScriptInjected = false;
    _downloadScriptInjected = false;
  }
  
  /// Dispose des ressources
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}

/// Données du menu contextuel
class ContextMenuData {
  final String type;
  final int x;
  final int y;
  final String? imageUrl;
  final String? linkUrl;
  final String? text;
  
  ContextMenuData({
    required this.type,
    required this.x,
    required this.y,
    this.imageUrl,
    this.linkUrl,
    this.text,
  });
  
  Offset get position => Offset(x.toDouble(), y.toDouble());
}

