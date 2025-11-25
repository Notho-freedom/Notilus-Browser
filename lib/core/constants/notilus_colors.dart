import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/color_theme_manager.dart';

/// Couleurs partagées pour la couche chrome de Notilus.
class NotilusColors {
  static const Color neonRed = Color(0xFFFF2D55); // Rouge Notilus (par défaut)
  static const Color neonRedDark = Color(0xFFB1165A); // Version plus sombre (par défaut)
  static const Color chrome = Color(0xFF101018);
  static const Color chromeDark = Color(0xFF0B0B11);
  static const Color chromeLight = Color(0xFF181824);
  static const Color tooltipBackground = Color(0xFF1C1C28);
  
  /// Background color pour les zones natives (sidebar, topbars, etc.)
  static const Color nativeBackground = Color(0xFF09080D);
  
  /// Obtient la couleur primaire du thème actuel (si ColorThemeManager est disponible)
  static Color getPrimaryColor(BuildContext? context) {
    if (context != null) {
      try {
        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
        return colorThemeManager.primaryColor;
      } catch (_) {
        // Si ColorThemeManager n'est pas disponible, utiliser la couleur par défaut
      }
    }
    return neonRed;
  }
  
  /// Obtient la couleur primaire sombre du thème actuel (si ColorThemeManager est disponible)
  static Color getPrimaryDarkColor(BuildContext? context) {
    if (context != null) {
      try {
        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
        return colorThemeManager.primaryDarkColor;
      } catch (_) {
        // Si ColorThemeManager n'est pas disponible, utiliser la couleur par défaut
      }
    }
    return neonRedDark;
  }
}

