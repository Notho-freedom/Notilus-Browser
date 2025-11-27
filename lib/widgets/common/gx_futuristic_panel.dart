/// Panel futuriste Notilus GX - Style OS Science-Fiction
/// Wrapper pour les panels avec contours géométriques
library gx_futuristic_panel;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';
import 'gx_futuristic_container.dart';

/// Panel futuriste avec contours géométriques
class GxFuturisticPanel extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final bool showBorders;

  const GxFuturisticPanel({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.border,
    this.showBorders = true,
  });

  @override
  Widget build(BuildContext context) {
    return GxFuturisticContainer(
      accentColor: accentColor,
      padding: padding,
      showBorders: showBorders,
      border: border,
      child: child,
    );
  }
}

