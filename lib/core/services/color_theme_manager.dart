import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/notilus_colors.dart';
import '../../services/settings_service.dart';

/// Gestionnaire de thèmes de couleur pour Notilus
/// Permet de changer la couleur principale (rouge, bleu, vert, etc.)
/// et de personnaliser les couleurs natives (background et secondary)
class ColorThemeManager extends ChangeNotifier {
  static const _prefsKey = 'notilus_color_theme';
  static const _prefsKeyNativeBg = 'notilus_native_background_color';
  static const _prefsKeyNativeSecondary = 'notilus_native_secondary_color';
  
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
  
  // Couleurs personnalisées
  Color _nativeBackgroundColor = NotilusColors.nativeBackground;
  // La secondary color = le rouge natif de Notilus (couleur principale)
  Color _nativeSecondaryColor = NotilusColors.neonRed;
  
  Color get nativeBackgroundColor => _nativeBackgroundColor;
  Color get nativeSecondaryColor => _nativeSecondaryColor;

  ColorThemeManager() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger le thème
      final themeId = prefs.getString(_prefsKey) ?? 'red';
      final theme = availableThemes.firstWhere(
        (t) => t.id == themeId,
        orElse: () => availableThemes.first,
      );
      _currentTheme = theme;
      
      // Charger les couleurs personnalisées
      final nativeBgValue = prefs.getInt(_prefsKeyNativeBg);
      if (nativeBgValue != null) {
        _nativeBackgroundColor = Color(nativeBgValue);
      }
      
      // Charger la couleur secondaire (rouge) personnalisée, sinon utiliser celle du thème
      final nativeSecondaryValue = prefs.getInt(_prefsKeyNativeSecondary);
      if (nativeSecondaryValue != null) {
        _nativeSecondaryColor = Color(nativeSecondaryValue);
      } else {
        // Si pas de couleur personnalisée, utiliser la couleur du thème sélectionné
        _nativeSecondaryColor = theme.primary;
      }
      
      notifyListeners();
    } catch (_) {
      // Ignorer les erreurs, utiliser les valeurs par défaut
    }
  }

  Future<void> setTheme(String themeId) async {
    final theme = availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => availableThemes.first,
    );
    _currentTheme = theme;
    
    // Appliquer la couleur du thème à la secondary color (rouge Notilus)
    _nativeSecondaryColor = theme.primary;
    
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, themeId);
      // Sauvegarder aussi la couleur secondaire pour persistance
      await prefs.setInt(_prefsKeyNativeSecondary, theme.primary.toARGB32());
    } catch (_) {
      // Ignorer les erreurs d'écriture
    }
  }

  Color get primaryColor => _currentTheme.primary;
  Color get primaryDarkColor => _currentTheme.primaryDark;
  
  /// Définit la couleur de fond native personnalisée
  Future<void> setNativeBackgroundColor(Color color) async {
    _nativeBackgroundColor = color;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyNativeBg, color.toARGB32());
    } catch (_) {
      // Ignorer les erreurs d'écriture
    }
  }
  
  /// Définit la couleur secondaire native personnalisée
  Future<void> setNativeSecondaryColor(Color color) async {
    _nativeSecondaryColor = color;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyNativeSecondary, color.toARGB32());
    } catch (_) {
      // Ignorer les erreurs d'écriture
    }
  }
  
  /// Réinitialise les couleurs personnalisées aux valeurs par défaut
  Future<void> resetCustomColors() async {
    _nativeBackgroundColor = NotilusColors.nativeBackground;
    // Réinitialiser la secondary color à la couleur du thème actuel
    _nativeSecondaryColor = _currentTheme.primary;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyNativeBg);
      await prefs.remove(_prefsKeyNativeSecondary);
      // Ne pas réinitialiser le thème, seulement les couleurs personnalisées
    } catch (_) {
      // Ignorer les erreurs
    }
  }
  
  /// Obtient la couleur des icônes (personnalisée si activée, sinon secondary)
  Color getIconColor() {
    final settings = SettingsService();
    if (settings.iconColorCustomEnabled) {
      return Color(settings.iconColorCustom);
    }
    return nativeSecondaryColor;
  }
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

