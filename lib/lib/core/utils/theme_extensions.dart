import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

extension ThemeExtensions on BuildContext {
  /// Récupère le thème personnalisé depuis le contexte
  AppTheme get customTheme {
    try {
      final themeManager = Provider.of<ThemeManager>(this, listen: false);
      return themeManager.currentTheme;
    } catch (e) {
      return const AppTheme(
        name: 'Default',
        background: Color(0xFF0D0D0D),
        surface: Color(0xFF1A1A1A),
        primary: Color(0xFFFF0040),
        secondary: Color(0xFFFF3366),
        accent: Color(0xFF00FF88),
        text: Color(0xFFE0E0E0),
        textSecondary: Color(0xFF888888),
        error: Color(0xFFFF0040),
        success: Color(0xFF00FF88),
        warning: Color(0xFFFFAA00),
        border: Color(0xFF333333),
        hover: Color(0xFF2A2A2A),
        selected: Color(0xFFFF0040),
      );
    }
  }
  
  /// Récupère la couleur de bordure
  Color get borderColor => customTheme.border;
  
  /// Récupère la couleur de texte secondaire
  Color get textSecondaryColor => customTheme.textSecondary;
  
  /// Récupère la couleur de succès
  Color get successColor => customTheme.success;
}

