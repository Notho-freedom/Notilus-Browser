import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:webview_windows/webview_windows.dart';
import '../../services/side_webview_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/webview2_browser_engine.dart';

class WebViewServicePanel extends StatefulWidget {
  final String url;
  final String title;
  final IconData icon;
  final Color color;

  const WebViewServicePanel({
    super.key,
    required this.url,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  State<WebViewServicePanel> createState() => _WebViewServicePanelState();
}

class _WebViewServicePanelState extends State<WebViewServicePanel> with AutomaticKeepAliveClientMixin {
  // IMPORTANT: Keep alive pour garder le state même quand le widget n'est pas visible
  @override
  bool get wantKeepAlive => true;

  WebviewController? _webView;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _panelId;

  @override
  void initState() {
    super.initState();
    // ID unique basé sur l'URL pour garantir la persistance
    _panelId = 'side_panel_${widget.url}';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _initializeWebView();
      }
    });
  }

  Future<void> _initializeWebView() async {
    if (!Platform.isWindows || _isDisposed) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final sideWebViewManager = Provider.of<SideWebViewManager>(context, listen: false);
      
      // Récupérer ou créer l'engine pour ce panel
      // Le manager garde l'engine en mémoire même quand le panel est fermé
      final engine = sideWebViewManager.getOrCreatePersistentEngine(_panelId!, widget.url) as WebView2BrowserEngine;
      
      // Attendre l'initialisation
      await engine.waitForInitialization();
      
      if (_isDisposed || !mounted) return;
      
      // Récupérer le controller
      final controller = await engine.getController();
      
      if (_isDisposed || !mounted) return;
      
      if (controller != null && controller is WebviewController) {
        setState(() {
          _webView = controller;
          _isLoading = false;
        });
        
        // Vérifier si on doit naviguer
        final currentUrl = await engine.getCurrentUrl();
        if (currentUrl == null || currentUrl.isEmpty || currentUrl == 'about:blank') {
          debugPrint('🚀 Navigation initiale vers: ${widget.url}');
          await engine.navigate(widget.url);
        } else {
          debugPrint('✅ Session restaurée: $currentUrl');
        }
        
        // Réactiver le panel (audio, etc.)
        engine.setActive(true);
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation panel: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // NE PAS détruire l'engine, juste le mettre en pause
    if (_panelId != null) {
      try {
        final sideWebViewManager = Provider.of<SideWebViewManager>(context, listen: false);
        final engine = sideWebViewManager.getEngine(_panelId!) as WebView2BrowserEngine?;
        
        if (engine != null) {
          // Mettre le panel en pause mais garder la session
          engine.setActive(false);
          debugPrint('⏸️  Panel mis en pause: $_panelId');
        }
      } catch (e) {
        debugPrint('Erreur lors de la mise en pause: $e');
      }
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // IMPORTANT pour AutomaticKeepAliveClientMixin
    
    final theme = Theme.of(context);
    final wallpaperManager = context.watch<WallpaperManager>();
    final wallpaperUrl = wallpaperManager.currentImageUrl;

    return Container(
      decoration: BoxDecoration(
        image: wallpaperUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(wallpaperUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.85),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : (!Platform.isWindows || _webView == null)
                ? Center(
                    child: Text(
                      'WebView2 non supporté sur cette plateforme',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : Webview(_webView!),
      ),
    );
  }
}
