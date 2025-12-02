// quantum_browser.dart
// Widget Flutter Quantum avec effets visuels pour le moteur CEF

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../notilus_cef.dart';

/// Widget Quantum Browser avec effets visuels
class QuantumBrowser extends StatefulWidget {
  final String initialUrl;
  final double perspective;
  final bool enableEffects;
  final Size? viewportSize;

  const QuantumBrowser({
    super.key,
    required this.initialUrl,
    this.perspective = 0.001,
    this.enableEffects = true,
    this.viewportSize,
  });

  @override
  State<QuantumBrowser> createState() => _QuantumBrowserState();
}

class _QuantumBrowserState extends State<QuantumBrowser>
    with SingleTickerProviderStateMixin {
  late final CefEngine _engine;
  late final TransformationController _transformController;
  late AnimationController _animationController;

  int? _textureId;
  bool _isReady = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _engine = CefEngine();
    _transformController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    try {
      await _engine.initialize(
        viewport: widget.viewportSize ?? const Size(1280, 720),
      );

      _engine.textureStream.listen((texture) {
        if (!_isReady) {
          setState(() {
            _textureId = texture.id;
            _isReady = true;
            _isLoading = false;
          });
          _engine.loadUrl(widget.initialUrl);
        }
      });

      _engine.eventStream.listen((event) {
        if (event.type == 'ENGINE_READY') {
          setState(() {
            _isLoading = false;
          });
        } else if (event.type == 'PAGE_LOADED') {
          // Page chargée
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'initialisation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (!_isReady || _textureId == null) {
      return _buildError();
    }

    return _buildBrowserView();
  }

  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.purple.shade900,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
            SizedBox(height: 20),
            Text(
              '⚡ Quantum Engine Booting...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Erreur de chargement',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBrowserView() {
    return GestureDetector(
      onTapDown: (details) {
        _engine.sendMouseClick(
          position: details.localPosition,
          button: CefMouseButton.left,
          pressed: true,
        );
      },
      onTapUp: (details) {
        _engine.sendMouseClick(
          position: details.localPosition,
          button: CefMouseButton.left,
          pressed: false,
        );
      },
      onPanUpdate: (details) {
        _engine.sendMouseMove(details.localPosition);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, widget.perspective)
              ..rotateX(_animationController.value * 0.1)
              ..rotateY(_animationController.value * 0.05),
            alignment: Alignment.center,
            child: Stack(
              children: [
                // Texture principale
                Positioned.fill(
                  child: Texture(
                    textureId: _textureId!,
                    filterQuality: FilterQuality.high,
                  ),
                ),

                // Effets overlay
                if (widget.enableEffects) ...[
                  _buildReflection(),
                  _buildGlowEffect(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReflection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 60,
      child: Transform(
        transform: Matrix4.identity()
          ..rotateX(math.pi)
          ..scale(1.0, -0.3),
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: 0.3,
          child: Texture(
            textureId: _textureId!,
            filterQuality: FilterQuality.low,
          ),
        ),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformController.dispose();
    _engine.dispose();
    super.dispose();
  }
}

