/// Container futuriste Notilus GX - Style OS Science-Fiction
/// Contours géométriques avec transparence et effets de lumière
library gx_futuristic_container;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';

/// Container futuriste avec contours géométriques façon OS SF
class GxFuturisticContainer extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool showBorders;
  final Border? border;

  const GxFuturisticContainer({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.showBorders = true,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
              border: border ??
                  (showBorders
                      ? Border.all(
                          color: accent.withOpacity(0.4),
                          width: 1.5,
                        )
                      : null),
            ),
            child: Stack(
              children: [
                // Contours géométriques
                if (showBorders)
                  _GeometricBorders(accentColor: accent),
                
                // Contenu
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contours géométriques aux angles
class _GeometricBorders extends StatelessWidget {
  final Color accentColor;

  const _GeometricBorders({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GeometricBordersPainter(accentColor: accentColor),
      ),
    );
  }
}

class _GeometricBordersPainter extends CustomPainter {
  final Color accentColor;

  _GeometricBordersPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const cornerSize = 20.0;
    const lineLength = 30.0;

    // Coin supérieur gauche
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, 0),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerSize, 0),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerSize, 0),
      paint,
    );
    canvas.drawLine(
      Offset(cornerSize, 0),
      Offset(cornerSize + lineLength, 0),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, cornerSize + lineLength),
      paint..strokeWidth = 1,
    );

    // Coin supérieur droit
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize - lineLength, 0),
      Offset(size.width - cornerSize, 0),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(size.width, cornerSize),
      Offset(size.width, cornerSize + lineLength),
      paint..strokeWidth = 1,
    );

    // Coin inférieur gauche
    canvas.drawLine(
      Offset(0, size.height - cornerSize),
      Offset(0, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerSize, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, size.height - cornerSize),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerSize, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height - cornerSize - lineLength),
      Offset(0, size.height - cornerSize),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(cornerSize, size.height),
      Offset(cornerSize + lineLength, size.height),
      paint..strokeWidth = 1,
    );

    // Coin inférieur droit
    canvas.drawLine(
      Offset(size.width - cornerSize, size.height),
      Offset(size.width, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize),
      Offset(size.width, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize - lineLength, size.height),
      Offset(size.width - cornerSize, size.height),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize - lineLength),
      Offset(size.width, size.height - cornerSize),
      paint..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

