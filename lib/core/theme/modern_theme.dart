import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../constants/notilus_fonts.dart';

/// Thème moderne et épuré pour Notilus
class ModernTheme extends AppTheme {
  const ModernTheme()
      : super(
          name: 'Modern Light',
          background: const Color(0xFFFAFAFA),
          surface: const Color(0xFFFFFFFF),
          primary: const Color(0xFF5856D6),
          secondary: const Color(0xFF007AFF),
          accent: const Color(0xFF34C759),
          text: const Color(0xFF1C1C1E),
          textSecondary: const Color(0xFF8E8E93),
          error: const Color(0xFFFF3B30),
          success: const Color(0xFF34C759),
          warning: const Color(0xFFFF9500),
          border: const Color(0xFFE5E5EA),
          hover: const Color(0xFFF2F2F7),
          selected: const Color(0xFF5856D6),
        );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5856D6),
          secondary: Color(0xFF007AFF),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFFAFAFA),
          error: Color(0xFFFF3B30),
        ),
        textTheme: TextTheme(
          displayLarge: NotilusFonts.orbitron(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
          displayMedium: NotilusFonts.orbitron(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
          headlineLarge: NotilusFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
          bodyLarge: NotilusFonts.rajdhani(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1C1C1E),
          ),
          bodyMedium: NotilusFonts.rajdhani(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1C1C1E),
          ),
          labelLarge: NotilusFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF5856D6),
              width: 2,
            ),
          ),
        ),
      );
}

/// Thème sombre moderne
class ModernDarkTheme extends AppTheme {
  const ModernDarkTheme()
      : super(
          name: 'Modern Dark',
          background: const Color(0xFF000000),
          surface: const Color(0xFF1C1C1E),
          primary: const Color(0xFF5E5CE6),
          secondary: const Color(0xFF0A84FF),
          accent: const Color(0xFF30D158),
          text: const Color(0xFFFFFFFF),
          textSecondary: const Color(0xFF8E8E93),
          error: const Color(0xFFFF453A),
          success: const Color(0xFF30D158),
          warning: const Color(0xFFFF9F0A),
          border: const Color(0xFF38383A),
          hover: const Color(0xFF2C2C2E),
          selected: const Color(0xFF5E5CE6),
        );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5E5CE6),
          secondary: Color(0xFF0A84FF),
          surface: Color(0xFF1C1C1E),
          background: Color(0xFF000000),
          error: Color(0xFFFF453A),
        ),
        textTheme: TextTheme(
          displayLarge: NotilusFonts.orbitron(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          displayMedium: NotilusFonts.orbitron(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          headlineLarge: NotilusFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: NotilusFonts.rajdhani(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          bodyMedium: NotilusFonts.rajdhani(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          labelLarge: NotilusFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF5E5CE6),
              width: 2,
            ),
          ),
        ),
      );
}
