/// Widget WebView pour un viewport spécifique
library viewport_webview;

import 'package:flutter/material.dart';
import '../../models/studio/viewport_preset.dart';
import '../../services/studio/viewport_webview_manager.dart';

/// Widget WebView pour un viewport
class ViewportWebView extends StatefulWidget {
  final String viewportId;
  final ViewportPreset preset;
  final String url;
  final ViewportWebViewManager manager;

  const ViewportWebView({
    super.key,
    required this.viewportId,
    required this.preset,
    required this.url,
    required this.manager,
  });

  @override
  State<ViewportWebView> createState() => _ViewportWebViewState();
}

class _ViewportWebViewState extends State<ViewportWebView> {
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      final engine = await widget.manager.getViewportWebView(
        widget.viewportId,
        widget.preset,
        widget.url,
      );

      if (engine != null && mounted) {
        // Obtenir le contrôleur WebView depuis l'engine
        // Note: WebView2BrowserEngine n'expose pas directement le contrôleur
        // On devra adapter selon l'implémentation réelle
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.manager.removeViewportWebView(widget.viewportId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        width: widget.preset.width.toDouble(),
        height: widget.preset.height.toDouble(),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Limite de 2 viewports atteinte',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Container(
        width: widget.preset.width.toDouble(),
        height: widget.preset.height.toDouble(),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Pour l'instant, on retourne un placeholder
    // L'implémentation complète nécessiterait d'exposer le WebViewController depuis WebView2BrowserEngine
    return Container(
      width: widget.preset.width.toDouble(),
      height: widget.preset.height.toDouble(),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          'WebView pour ${widget.preset.name}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

