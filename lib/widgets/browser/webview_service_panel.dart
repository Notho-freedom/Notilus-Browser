import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:webview_windows/webview_windows.dart';
import '../../services/side_webview_manager.dart';
import '../../core/services/wallpaper_manager.dart';

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

class _WebViewServicePanelState extends State<WebViewServicePanel> {
  WebviewController? _webView;
  bool _isLoading = true;
  String? _currentUrl;
  String? _currentTitle;
  String? _panelId;

  @override
  void initState() {
    super.initState();
    _panelId = 'side_panel_${widget.url.hashCode}';
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    if (!Platform.isWindows) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final sideWebViewManager = Provider.of<SideWebViewManager>(context, listen: false);
      
      // Utiliser le nouveau système de cache par URL
      final engine = sideWebViewManager.getEngineForPanel(_panelId!, widget.url);
      
      // Initialiser le moteur (la méthode initialize() vérifie déjà si déjà initialisé)
      await engine.initialize();
      
      // Récupérer le WebView2 controller
      final controller = await engine.getController();
      if (controller != null && controller is WebviewController) {
        setState(() {
          _webView = controller as WebviewController;
          _isLoading = false;
        });
        
        // Naviguer seulement si l'URL n'est pas déjà chargée
        final currentUrl = await engine.getCurrentUrl();
        if (currentUrl != widget.url) {
          await engine.navigate(widget.url);
        } else {
          debugPrint('✅ URL déjà chargée, pas de rechargement nécessaire: ${widget.url}');
        }
      }
    } catch (e) {
      debugPrint('Error initializing side webview: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_panelId != null) {
      final sideWebViewManager = Provider.of<SideWebViewManager>(context, listen: false);
      // Conserver l'engine en cache pour réutilisation future
      sideWebViewManager.removeEngineForPanel(_panelId!, keepEngine: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

