import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestion simple du ThemeMode (clair / sombre / système) pour Notilus.
class ThemeModeNotifier extends ChangeNotifier {
  static const _prefsKey = 'notilus_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeModeNotifier() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_prefsKey);
      switch (value) {
        case 'light':
          _mode = ThemeMode.light;
          break;
        case 'dark':
          _mode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _mode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {
      // Ignorer les erreurs, rester sur le mode par défaut
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_prefsKey, value);
    } catch (_) {
      // Ignorer les erreurs d'écriture
    }
  }
}


