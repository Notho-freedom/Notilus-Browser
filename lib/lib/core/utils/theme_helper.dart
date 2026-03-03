import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../theme/app_theme.dart';
import '../theme/dark_red_theme.dart';

/// Helper class pour accéder facilement au thème depuis n'importe quel widget
class ThemeHelper {
  /// Récupère le thème actuel depuis le contexte
  static AppTheme getTheme(BuildContext context) {
    try {
      final themeManager = Provider.of<ThemeManager>(context, listen: false);
      return themeManager.currentTheme;
    } catch (e) {
      // Fallback vers le thème par défaut si Provider n'est pas disponible
      return DarkRedTheme();
    }
  }

  /// Récupère le thème actuel en écoutant les changements
  static AppTheme watchTheme(BuildContext context) {
    try {
      final themeManager = Provider.of<ThemeManager>(context);
      return themeManager.currentTheme;
    } catch (e) {
      return DarkRedTheme();
    }
  }
}

