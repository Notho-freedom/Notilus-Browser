import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'dark_red_theme.dart';
import 'themes/dark_blue_theme.dart';
import 'themes/cyberpunk_theme.dart';
import 'themes/matrix_theme.dart';
import 'themes/dracula_theme.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  AppTheme _currentTheme = DarkRedTheme();
  final List<AppTheme> _availableThemes = [
    DarkRedTheme(),
    DarkBlueTheme(),
    CyberpunkTheme(),
    MatrixTheme(),
    DraculaTheme(),
  ];

  AppTheme get currentTheme => _currentTheme;
  List<AppTheme> get availableThemes => _availableThemes;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);
      if (themeName != null) {
        final theme = _availableThemes.firstWhere(
          (t) => t.name == themeName,
          orElse: () => DarkRedTheme(),
        );
        _currentTheme = theme;
        notifyListeners();
      }
    } catch (e) {
      // Use default theme if loading fails
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> setThemeByName(String themeName) async {
    final theme = _availableThemes.firstWhere(
      (t) => t.name == themeName,
      orElse: () => DarkRedTheme(),
    );
    await setTheme(theme);
  }
}

