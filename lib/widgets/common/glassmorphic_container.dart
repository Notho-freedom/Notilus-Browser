import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool showNeonBorder;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showNeonBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).brightness == Brightness.dark
        ? _getThemeFromContext(context)
        : null;
    
    if (theme == null) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? Colors.grey,
            width: borderWidth,
          ),
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: showNeonBorder
            ? Border.all(
                color: theme.primary,
                width: borderWidth,
              )
            : Border.all(
                color: borderColor ?? theme.border,
                width: borderWidth,
              ),
        boxShadow: showNeonBorder
            ? [
                BoxShadow(
                  color: theme.primary.withOpacity(0.5),
                  blurRadius: AppConstants.neonBlur,
                  spreadRadius: AppConstants.neonSpread,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppConstants.glassBlur,
            sigmaY: AppConstants.glassBlur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: theme.glassBackground,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  AppTheme _getThemeFromContext(BuildContext context) {
    // Try to get theme from ThemeManager if available
    // For now, return a default dark red theme
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

