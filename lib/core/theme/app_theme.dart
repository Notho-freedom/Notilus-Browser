import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

class AppTheme {
  final String name;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color textSecondary;
  final Color error;
  final Color success;
  final Color warning;
  final Color border;
  final Color hover;
  final Color selected;

  const AppTheme({
    required this.name,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.textSecondary,
    required this.error,
    required this.success,
    required this.warning,
    required this.border,
    required this.hover,
    required this.selected,
  });

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: text,
        onBackground: text,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: border,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: text,
          fontFamily: 'Roboto Mono',
          fontSize: 24,
        ),
        displayMedium: TextStyle(
          color: text,
          fontFamily: 'Roboto Mono',
          fontSize: 20,
        ),
        displaySmall: TextStyle(
          color: text,
          fontFamily: 'Roboto Mono',
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          color: text,
          fontFamily: 'Roboto Mono',
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: text,
          fontFamily: 'Roboto Mono',
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontFamily: 'Roboto Mono',
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  Color get glassBackground => ColorUtils.withOpacity(surface, 0.3);
  Color get neonGlow => primary;
}

