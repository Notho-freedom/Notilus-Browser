/// Overlay WebView DevTools pour Notilus
/// Charge le DevTools complet via un WebView2 supplémentaire
library notilus_devtools_overlay;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:webview_windows/webview_windows.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/tab_manager.dart';
import '../common/notilus_tooltip.dart';

/// Overlay DevTools avec WebView2 complet
class NotilusDevToolsOverlay extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isVisible;
  final Duration animationDuration;

  const NotilusDevToolsOverlay({
    super.key,
    this.onClose,
    this.isVisible = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<NotilusDevToolsOverlay> createState() => _NotilusDevToolsOverlayState();
}

class _NotilusDevToolsOverlayState extends State<NotilusDevToolsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  WebviewController? _devToolsWebView;
  bool _isWebViewInitialized = false;
  String? _devToolsUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // En bas
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isVisible) {
      _animationController.forward();
      _initializeDevToolsWebView();
    }
  }

  @override
  void didUpdateWidget(NotilusDevToolsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
        if (!_isWebViewInitialized) {
          _initializeDevToolsWebView();
        }
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _devToolsWebView?.dispose();
    super.dispose();
  }

  Future<void> _initializeDevToolsWebView() async {
    if (_isWebViewInitialized) return;

    try {
      // Créer un nouveau WebView pour DevTools
      _devToolsWebView = WebviewController();
      await _devToolsWebView!.initialize();
      
      // Pour l'instant, on charge une page de placeholder
      // TODO: Implémenter la connexion au DevTools réel via WebSocket
      // L'URL DevTools serait quelque chose comme :
      // http://localhost:9222/devtools/inspector.html?ws=127.0.0.1:9222/devtools/page/1
      
      // Pour l'instant, on charge une page simple qui explique comment utiliser DevTools
      final placeholderHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Notilus DevTools</title>
  <style>
    body {
      margin: 0;
      padding: 20px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #1e1e1e;
      color: #d4d4d4;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
    }
    h1 {
      color: #FF2D55;
      margin-top: 40px;
    }
    .info {
      background: #252526;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
      border-left: 4px solid #FF2D55;
    }
    .code {
      background: #1e1e1e;
      padding: 10px;
      border-radius: 4px;
      font-family: 'Consolas', monospace;
      color: #9cdcfe;
      margin: 10px 0;
    }
    .warning {
      background: #3f3f00;
      padding: 15px;
      border-radius: 8px;
      margin: 20px 0;
      border-left: 4px solid #ffd700;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🐙 Notilus DevTools Overlay</h1>
    
    <div class="info">
      <h2>📋 Instructions</h2>
      <p>Pour utiliser les DevTools complets :</p>
      <ol>
        <li>Ouvrez les DevTools natifs du WebView2 (F12 dans le WebView)</li>
        <li>Ou utilisez le Mini DevTools Panel (Ctrl+Shift+M)</li>
        <li>Ou utilisez le DevTools Dock natif (Ctrl+Shift+D)</li>
      </ol>
    </div>
    
    <div class="warning">
      <strong>⚠️ Note :</strong> L'overlay WebView DevTools nécessite une connexion WebSocket
      au processus WebView2. Cette fonctionnalité sera implémentée dans une prochaine version.
    </div>
    
    <div class="info">
      <h2>🔧 Fonctionnalités disponibles</h2>
      <ul>
        <li><strong>Mini DevTools Panel</strong> : Console et Network (Ctrl+Shift+M)</li>
        <li><strong>DevTools Dock</strong> : DevTools natifs dockés (Ctrl+Shift+D)</li>
        <li><strong>DevTools complets</strong> : Via F12 dans le WebView</li>
      </ul>
    </div>
    
    <div class="code">
      // Exemple : console.log dans la page web<br>
      console.log('Hello from Notilus!');
    </div>
  </div>
</body>
</html>
      ''';
      
      // Charger le HTML placeholder via data URI
      final dataUri = 'data:text/html;charset=utf-8,${Uri.encodeComponent(placeholderHtml)}';
      await _devToolsWebView!.loadUrl(dataUri);
      
      setState(() {
        _isWebViewInitialized = true;
      });
    } catch (e) {
      debugPrint('❌ Erreur initialisation DevTools WebView: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _animationController.value == 0) {
      return const SizedBox.shrink();
    }

    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Positioned.fill(
          child: Stack(
            children: [
              // Backdrop avec blur
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              // Panel DevTools
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gxRed.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(context, gxRed, bgColor),
                        // WebView content
                        Expanded(
                          child: _buildWebViewContent(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color gxRed, Color bgColor) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: gxRed.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.ant,
                  size: 18,
                  color: gxRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'DevTools Overlay',
                  style: TextStyle(
                    color: gxRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          NotilusTooltip(
            message: 'Fermer (Esc)',
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 18,
                  color: gxRed.withOpacity(0.8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildWebViewContent(BuildContext context) {
    if (!_isWebViewInitialized || _devToolsWebView == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement des DevTools...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Webview(_devToolsWebView!);
  }
}

