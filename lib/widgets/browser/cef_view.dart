import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:notilus_cef/notilus_cef.dart';

/// Widget Flutter pour afficher du contenu web via CEF offscreen
/// 
/// Permet des transformations 3D, shaders, blur et animations
/// sans latence grâce au rendu dans une texture native.
class CefView extends StatefulWidget {
  /// URL initiale à charger
  final String initialUrl;
  
  /// Largeur de la texture (défaut: 1280)
  final int width;
  
  /// Hauteur de la texture (défaut: 720)
  final int height;
  
  /// Transformation 3D à appliquer
  final Matrix4? transform;
  
  /// Callback appelé quand l'URL change
  final ValueChanged<String>? onUrlChanged;
  
  /// Callback appelé quand le titre change
  final ValueChanged<String>? onTitleChanged;
  
  /// Callback appelé quand la page commence à charger
  final VoidCallback? onLoadStart;
  
  /// Callback appelé quand la page finit de charger
  final VoidCallback? onLoadEnd;
  
  /// Callback appelé en cas d'erreur de chargement
  final ValueChanged<String>? onLoadError;
  
  /// Widget à afficher pendant le chargement
  final Widget? loadingWidget;
  
  /// Widget à afficher en cas d'erreur
  final Widget? errorWidget;

  const CefView({
    Key? key,
    this.initialUrl = "https://flutter.dev",
    this.width = 1280,
    this.height = 720,
    this.transform,
    this.onUrlChanged,
    this.onTitleChanged,
    this.onLoadStart,
    this.onLoadEnd,
    this.onLoadError,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<CefView> createState() => _CefViewState();
}

class _CefViewState extends State<CefView> {
  int? _textureId;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _currentUrl;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _initCEF();
  }

  Future<void> _initCEF() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      _textureId = await NotilusCEF.init(
        width: widget.width,
        height: widget.height,
        initialUrl: widget.initialUrl,
      );

      _currentUrl = widget.initialUrl;

      setState(() {
        _isInitializing = false;
      });

      // Polling pour l'URL (à améliorer avec des callbacks natifs si nécessaire)
      _pollUrl();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      if (widget.onLoadError != null) {
        widget.onLoadError!(_errorMessage!);
      }
    }
  }

  void _pollUrl() async {
    while (mounted && _textureId != null) {
      try {
        final url = await NotilusCEF.getCurrentUrl();
        if (url != null && url != _currentUrl) {
          setState(() {
            _currentUrl = url;
          });
          if (widget.onUrlChanged != null) {
            widget.onUrlChanged!(url);
          }
        }
      } catch (e) {
        // Ignorer les erreurs de polling
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    if (_textureId != null) {
      NotilusCEF.dispose();
    }
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_textureId == null) return;
    
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;
    
    NotilusCEF.sendMouseClick(x: x, y: y, button: 0, down: true);
    NotilusCEF.sendMouseClick(x: x, y: y, button: 0, down: false);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_textureId == null) return;
    
    NotilusCEF.sendMouseMove(
      x: details.localPosition.dx,
      y: details.localPosition.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return widget.loadingWidget ?? 
        const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return widget.errorWidget ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur CEF: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initCEF,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
    }

    if (_textureId == null) {
      return widget.loadingWidget ??
        const Center(child: CircularProgressIndicator());
    }

    Widget textureWidget = GestureDetector(
      onTapDown: _handleTapDown,
      onPanUpdate: _handlePanUpdate,
      child: Texture(textureId: _textureId!),
    );

    // Appliquer la transformation 3D si fournie
    if (widget.transform != null) {
      textureWidget = Transform(
        alignment: Alignment.center,
        transform: widget.transform!,
        child: textureWidget,
      );
    }

    return textureWidget;
  }
}

/// Widget CefView avec effets visuels avancés
class AdvancedCefView extends StatelessWidget {
  final String initialUrl;
  final int width;
  final int height;
  final double rotationX;
  final double rotationY;
  final double perspective;
  final double blurSigma;
  final BorderRadius? borderRadius;

  const AdvancedCefView({
    Key? key,
    this.initialUrl = "https://flutter.dev",
    this.width = 1280,
    this.height = 720,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.perspective = 0.001,
    this.blurSigma = 0.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transform = Matrix4.identity()
      ..rotateX(rotationX)
      ..rotateY(rotationY)
      ..setEntry(3, 2, perspective);

    Widget view = CefView(
      initialUrl: initialUrl,
      width: width,
      height: height,
      transform: transform,
    );

    // Appliquer le blur si nécessaire
    if (blurSigma > 0.0) {
      view = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: view,
      );
    }

    // Appliquer le border radius si nécessaire
    if (borderRadius != null) {
      view = ClipRRect(
        borderRadius: borderRadius!,
        child: view,
      );
    }

    return view;
  }
}

/// Exemple d'utilisation avec coverflow 3D
class CoverflowCefView extends StatefulWidget {
  final List<String> urls;
  final int currentIndex;

  const CoverflowCefView({
    Key? key,
    required this.urls,
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  State<CoverflowCefView> createState() => _CoverflowCefViewState();
}

class _CoverflowCefViewState extends State<CoverflowCefView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: widget.urls.length,
      controller: PageController(
        initialPage: widget.currentIndex,
        viewportFraction: 0.8,
      ),
      itemBuilder: (context, index) {
        final offset = (index - widget.currentIndex).toDouble();
        final rotation = offset * 0.3;
        final scale = 1.0 - (offset.abs() * 0.2).clamp(0.0, 0.5);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateY(rotation)
            ..scale(scale),
          child: AdvancedCefView(
            initialUrl: widget.urls[index],
            width: 1280,
            height: 720,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}

