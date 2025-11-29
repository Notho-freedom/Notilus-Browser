/// Helper pour appliquer les paramètres de transparence dynamique
library transparency_helper;

import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/settings_service.dart';

/// Extension pour faciliter l'application de la transparence
extension TransparencyExtension on BuildContext {
  /// Obtient la transparence des widgets depuis SettingsService
  double get widgetTransparency {
    final settings = SettingsService();
    return settings.widgetTransparency;
  }

  /// Obtient la transparence des panneaux depuis SettingsService
  double get panelTransparency {
    final settings = SettingsService();
    return settings.panelTransparency;
  }

  /// Obtient la transparence des overlays depuis SettingsService
  double get overlayTransparency {
    final settings = SettingsService();
    return settings.overlayTransparency;
  }

  /// Obtient l'intensité du flou glassmorphism depuis SettingsService
  double get glassBlurIntensity {
    final settings = SettingsService();
    return settings.glassBlurIntensity;
  }

  /// Calcule l'opacité d'un widget en fonction de la transparence configurée
  /// baseOpacity: opacité de base (0.0 - 1.0)
  /// retourne: opacité ajustée selon widgetTransparency
  double getWidgetOpacity(double baseOpacity) {
    final transparency = widgetTransparency;
    // Plus la transparence est élevée, plus l'opacité est réduite
    return baseOpacity * (1.0 - transparency);
  }

  /// Calcule l'opacité d'un panneau en fonction de la transparence configurée
  double getPanelOpacity(double baseOpacity) {
    final transparency = panelTransparency;
    return baseOpacity * (1.0 - transparency);
  }

  /// Calcule l'opacité d'un overlay en fonction de la transparence configurée
  double getOverlayOpacity(double baseOpacity) {
    final transparency = overlayTransparency;
    return baseOpacity * (1.0 - transparency);
  }
}

/// Widget helper pour appliquer la transparence aux widgets
class TransparentWidget extends StatelessWidget {
  final Widget child;
  final double baseOpacity;
  final TransparencyType type;

  const TransparentWidget({
    super.key,
    required this.child,
    this.baseOpacity = 0.95,
    this.type = TransparencyType.widget,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    double opacity;
    
    switch (type) {
      case TransparencyType.widget:
        opacity = context.getWidgetOpacity(baseOpacity);
        break;
      case TransparencyType.panel:
        opacity = context.getPanelOpacity(baseOpacity);
        break;
      case TransparencyType.overlay:
        opacity = context.getOverlayOpacity(baseOpacity);
        break;
    }

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: child,
    );
  }
}

enum TransparencyType {
  widget,
  panel,
  overlay,
}

/// Widget helper pour appliquer le glassmorphism avec transparence
class GlassmorphicWidget extends StatelessWidget {
  final Widget child;
  final double? baseOpacity;
  final TransparencyType type;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  const GlassmorphicWidget({
    super.key,
    required this.child,
    this.baseOpacity,
    this.type = TransparencyType.widget,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final blurIntensity = settings.glassBlurIntensity;
    
    double opacity;
    switch (type) {
      case TransparencyType.widget:
        opacity = baseOpacity != null 
            ? context.getWidgetOpacity(baseOpacity!)
            : (1.0 - settings.widgetTransparency);
        break;
      case TransparencyType.panel:
        opacity = baseOpacity != null 
            ? context.getPanelOpacity(baseOpacity!)
            : (1.0 - settings.panelTransparency);
        break;
      case TransparencyType.overlay:
        opacity = baseOpacity != null 
            ? context.getOverlayOpacity(baseOpacity!)
            : (1.0 - settings.overlayTransparency);
        break;
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(opacity.clamp(0.0, 1.0)),
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

