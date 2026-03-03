import 'package:flutter/material.dart';
import '../../core/constants/notilus_colors.dart';

/// Monogramme stylisé réutilisable pour la marque Notilus.
/// Design unifié avec le logo complet - Version compacte pour sidebar et UI
class NotilusMonogram extends StatefulWidget {
  final double size;
  final bool showGlow;
  final bool showFrame;
  final bool animated;
  final Color primary;
  final Color secondary;

  const NotilusMonogram({
    super.key,
    this.size = 36,
    this.showGlow = true,
    this.showFrame = true,
    this.animated = false,
    this.primary = NotilusColors.neonRed,
    this.secondary = Colors.white,
  });

  @override
  State<NotilusMonogram> createState() => _NotilusMonogramState();
}

class _NotilusMonogramState extends State<NotilusMonogram>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animated) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = widget.showFrame ? widget.size + 6 : widget.size;

    Widget content = Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(containerSize * 0.25),
        gradient: widget.showFrame
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A24),
                  const Color(0xFF0D0D14),
                ],
              )
            : null,
        border: widget.showFrame
            ? Border.all(
                color: widget.primary.withOpacity(0.5),
                width: 1.5,
              )
            : null,
        boxShadow: widget.showGlow && widget.showFrame
            ? [
                BoxShadow(
                  color: widget.primary.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(widget.size * 0.55, widget.size * 0.55),
          painter: _NotilusMonogramPainter(
            primary: widget.primary,
            secondary: widget.secondary,
            showGlow: widget.showGlow && !widget.showFrame,
          ),
        ),
      ),
    );

    if (widget.animated) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: content,
      );
    }

    return content;
  }
}

/// Painter personnalisé pour le "N" de Notilus - Design unifié
class _NotilusMonogramPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final bool showGlow;

  _NotilusMonogramPainter({
    required this.primary,
    required this.secondary,
    this.showGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.14;
    final barHeight = size.height * 0.75;

    // Peinture pour la barre gauche (rouge/primary)
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary,
          primary.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height))
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Peinture pour la barre droite (blanche/secondary)
    final rightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          secondary,
          secondary.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height))
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glow effet
    if (showGlow) {
      final glowPaint = Paint()
        ..color = primary.withOpacity(0.4)
        ..strokeWidth = strokeWidth * 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.8);

      canvas.drawLine(
        Offset(center.dx - size.width * 0.18, center.dy - barHeight / 2),
        Offset(center.dx - size.width * 0.18, center.dy + barHeight / 2),
        glowPaint,
      );
    }

    // Dessiner la barre verticale gauche
    canvas.drawLine(
      Offset(center.dx - size.width * 0.18, center.dy - barHeight / 2),
      Offset(center.dx - size.width * 0.18, center.dy + barHeight / 2),
      leftPaint,
    );

    // Dessiner la barre verticale droite
    canvas.drawLine(
      Offset(center.dx + size.width * 0.18, center.dy - barHeight / 2),
      Offset(center.dx + size.width * 0.18, center.dy + barHeight / 2),
      rightPaint,
    );

    // Dessiner la diagonale du N (du haut gauche au bas droit)
    final diagonalPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary,
          secondary,
        ],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height))
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - size.width * 0.18, center.dy - barHeight / 2),
      Offset(center.dx + size.width * 0.18, center.dy + barHeight / 2),
      diagonalPaint,
    );

    // Points décoratifs aux extrémités
    final dotPaint = Paint()..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - size.width * 0.18, center.dy - barHeight / 2),
      strokeWidth * 0.35,
      dotPaint..color = primary,
    );

    canvas.drawCircle(
      Offset(center.dx + size.width * 0.18, center.dy + barHeight / 2),
      strokeWidth * 0.35,
      dotPaint..color = secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _NotilusMonogramPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}

