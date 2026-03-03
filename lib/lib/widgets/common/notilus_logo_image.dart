import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Logo Notilus basé sur le nouveau design
/// Reproduit le logo "N" avec gradients rouge/rose/blanc dans un cercle
class NotilusLogoImage extends StatelessWidget {
  final double size;
  final bool showGlow;
  final Color? glowColor;
  final BoxFit fit;

  const NotilusLogoImage({
    super.key,
    this.size = 120,
    this.showGlow = false,
    this.glowColor,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: _NotilusLogoPainter(),
    );

    if (showGlow && glowColor != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor!.withOpacity(0.4),
              blurRadius: size * 0.3,
              spreadRadius: size * 0.1,
            ),
          ],
        ),
        child: logo,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: logo,
    );
  }
}

/// Painter pour le nouveau logo Notilus
class _NotilusLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Cercle extérieur rouge
    final outerRedPaint = Paint()
      ..color = const Color(0xFFFF0040)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, outerRedPaint);

    // Cercle intérieur sombre (fond)
    final innerBgPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 0.9,
        [
          const Color(0xFF1A0A1A), // Rouge-violet foncé
          const Color(0xFF0D050D), // Presque noir
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.9, innerBgPaint);

    // Cercle intérieur décoratif (bordure sombre)
    final innerBorderPaint = Paint()
      ..color = const Color(0xFF2A1A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.85, innerBorderPaint);

    // Le "N" avec gradients
    final nSize = size.width * 0.55;
    final nCenter = center;
    final barWidth = nSize * 0.12;
    final barHeight = nSize * 0.75;

    // Barre verticale gauche (rouge -> rose)
    final leftBarPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(nCenter.dx - nSize * 0.2, nCenter.dy - barHeight / 2),
        Offset(nCenter.dx - nSize * 0.2, nCenter.dy + barHeight / 2),
        [
          const Color(0xFFFF3366), // Rose clair (haut)
          const Color(0xFFFF0040), // Rouge (bas)
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;
    
    final leftBarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(nCenter.dx - nSize * 0.2, nCenter.dy),
        width: barWidth,
        height: barHeight,
      ),
      Radius.circular(barWidth / 2),
    );
    canvas.drawRRect(leftBarRect, leftBarPaint);

    // Barre diagonale et verticale droite combinées (rose -> blanc/gris)
    final diagonalPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(nCenter.dx - nSize * 0.2, nCenter.dy - barHeight / 2),
        Offset(nCenter.dx + nSize * 0.2, nCenter.dy + barHeight / 2),
        [
          const Color(0xFFFF3366), // Rose (haut gauche)
          const Color(0xFFFF6699), // Rose clair (milieu)
          const Color(0xFFE0E0E0), // Gris clair/blanc (bas droit)
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth * 0.9
      ..strokeCap = StrokeCap.round;
    
    // Diagonale
    canvas.drawLine(
      Offset(nCenter.dx - nSize * 0.2, nCenter.dy - barHeight / 2),
      Offset(nCenter.dx + nSize * 0.2, nCenter.dy + barHeight / 2),
      diagonalPaint,
    );

    // Barre verticale droite (gris clair) - partie supérieure
    final rightBarTopPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(nCenter.dx + nSize * 0.2, nCenter.dy - barHeight / 2),
        Offset(nCenter.dx + nSize * 0.2, nCenter.dy),
        [
          const Color(0xFFC0C0C0), // Gris (haut)
          const Color(0xFFE0E0E0), // Gris clair (milieu)
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;
    
    // Barre verticale droite - partie inférieure (continue depuis la diagonale)
    final rightBarBottomPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(nCenter.dx + nSize * 0.2, nCenter.dy),
        Offset(nCenter.dx + nSize * 0.2, nCenter.dy + barHeight / 2),
        [
          const Color(0xFFE0E0E0), // Gris clair (milieu)
          const Color(0xFFE0E0E0), // Gris clair (bas)
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;
    
    // Dessiner la partie supérieure de la barre droite
    canvas.drawLine(
      Offset(nCenter.dx + nSize * 0.2, nCenter.dy - barHeight / 2),
      Offset(nCenter.dx + nSize * 0.2, nCenter.dy),
      rightBarTopPaint,
    );
    
    // Dessiner la partie inférieure de la barre droite (continue depuis la diagonale)
    canvas.drawLine(
      Offset(nCenter.dx + nSize * 0.2, nCenter.dy),
      Offset(nCenter.dx + nSize * 0.2, nCenter.dy + barHeight / 2),
      rightBarBottomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Version compacte du logo pour les petites tailles
class NotilusLogoImageCompact extends StatelessWidget {
  final double size;
  final bool showGlow;
  final Color? glowColor;

  const NotilusLogoImageCompact({
    super.key,
    this.size = 32,
    this.showGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return NotilusLogoImage(
      size: size,
      showGlow: showGlow,
      glowColor: glowColor,
    );
  }
}

/// Monogramme basé sur l'image (version très compacte)
class NotilusMonogramImage extends StatelessWidget {
  final double size;
  final bool showFrame;
  final bool showGlow;
  final Color? glowColor;

  const NotilusMonogramImage({
    super.key,
    this.size = 36,
    this.showFrame = true,
    this.showGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return NotilusLogoImage(
      size: size,
      showGlow: showGlow,
      glowColor: glowColor,
    );
  }
}
