import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// Polices Notilus - Gaming/Sci-Fi
class NotilusFonts {
  /// Orbitron - Pour les titres et éléments principaux
  /// Style : Police futuriste/sci-fi parfaite pour le gaming
  static TextStyle orbitron({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.orbitron(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
    );
  }

  /// Rajdhani - Pour le texte de corps et descriptions
  /// Style : Police moderne et lisible avec un aspect gaming
  static TextStyle rajdhani({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.rajdhani(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
    );
  }

  /// Titres principaux (Orbitron)
  static TextStyle title({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    return orbitron(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Sous-titres (Orbitron)
  static TextStyle subtitle({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return orbitron(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Corps de texte (Rajdhani)
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return rajdhani(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Texte de code/terminal (Rajdhani monospace)
  static TextStyle code({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return rajdhani(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

