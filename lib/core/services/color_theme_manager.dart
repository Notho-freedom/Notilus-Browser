import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/notilus_colors.dart';

/// Gestionnaire de thèmes de couleur pour Notilus
/// Permet de changer la couleur principale (rouge, bleu, vert, etc.)
class ColorThemeManager extends ChangeNotifier {
  static const _prefsKey = 'notilus_color_theme';
  
  /// Thèmes de couleur disponibles
  static const List<ColorTheme> availableThemes = [
    ColorTheme(
      id: 'red',
      name: 'Rouge Notilus',
      primary: NotilusColors.neonRed,
      primaryDark: NotilusColors.neonRedDark,
    ),
    ColorTheme(
      id: 'blue',
      name: 'Bleu Cyber',
      primary: Color(0xFF007AFF),
      primaryDark: Color(0xFF0051D5),
    ),
    ColorTheme(
      id: 'green',
      name: 'Vert Matrix',
      primary: Color(0xFF34C759),
      primaryDark: Color(0xFF248A3D),
    ),
    ColorTheme(
      id: 'purple',
      name: 'Violet Neon',
      primary: Color(0xFF5856D6),
      primaryDark: Color(0xFF3D3BA8),
    ),
    ColorTheme(
      id: 'orange',
      name: 'Orange Fire',
      primary: Color(0xFFFF9500),
      primaryDark: Color(0xFFCC7700),
    ),
    ColorTheme(
      id: 'pink',
      name: 'Rose Cyber',
      primary: Color(0xFFFF2D92),
      primaryDark: Color(0xFFCC2474),
    ),
  ];

  ColorTheme _currentTheme = availableThemes.first;
  ColorTheme get currentTheme => _currentTheme;

  ColorThemeManager() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeId = prefs.getString(_prefsKey) ?? 'red';
      final theme = availableThemes.firstWhere(
        (t) => t.id == themeId,
        orElse: () => availableThemes.first,
      );
      _currentTheme = theme;
      notifyListeners();
    } catch (_) {
      // Ignorer les erreurs, utiliser le thème par défaut
    }
  }

  Future<void> setTheme(String themeId) async {
    final theme = availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => availableThemes.first,
    );
    _currentTheme = theme;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, themeId);
    } catch (_) {
      // Ignorer les erreurs d'écriture
    }
  }

  Color get primaryColor => _currentTheme.primary;
  Color get primaryDarkColor => _currentTheme.primaryDark;
}

/// Représente un thème de couleur
class ColorTheme {
  final String id;
  final String name;
  final Color primary;
  final Color primaryDark;

  const ColorTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
  });
}

