import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/notilus_colors.dart';

/// Monogramme stylisé reutilisable pour la marque Notilus.
class NotilusMonogram extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool showFrame;
  final Color primary;
  final Color secondary;

  const NotilusMonogram({
    super.key,
    this.size = 36,
    this.showGlow = true,
    this.showFrame = true,
    this.primary = NotilusColors.neonRed,
    this.secondary = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final double strokeHeight = size * 0.72;
    final double strokeWidth = size * 0.12;

    final Widget monogram = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -math.pi / 7,
            child: Container(
              width: strokeWidth,
              height: strokeHeight,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(strokeWidth),
              ),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 7,
            child: Container(
              width: strokeWidth,
              height: strokeHeight,
              decoration: BoxDecoration(
                color: secondary,
                borderRadius: BorderRadius.circular(strokeWidth),
              ),
            ),
          ),
        ],
      ),
    );

    if (!showFrame) return monogram;

    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((size + 6) * 0.3),
        border: Border.all(
          color: primary,
          width: 1.3,
        ),
        gradient: LinearGradient(
          colors: [
            NotilusColors.chromeLight,
            NotilusColors.chromeDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Center(child: monogram),
    );
  }
}

