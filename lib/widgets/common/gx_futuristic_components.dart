/// Composants futuristes Notilus GX réutilisables
/// Style OS Science-Fiction avec contours géométriques
library gx_futuristic_components;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';

// ============================================================================
// GX Futuristic Card
// ============================================================================

/// Carte futuriste avec contours géométriques
class GxFuturisticCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final Color? accentColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool showBorders;

  const GxFuturisticCard({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.accentColor,
    this.padding,
    this.margin,
    this.onTap,
    this.showBorders = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    Widget content = Container(
      margin: margin,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
              border: showBorders
                  ? Border.all(
                      color: accent.withOpacity(0.4),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (showBorders) _GeometricBorders(accentColor: accent),
                Padding(
                  padding: padding ?? const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null || titleIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              if (titleIcon != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.15),
                                    border: Border.all(
                                      color: accent.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    titleIcon,
                                    color: accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (title != null)
                                Expanded(
                                  child: Text(
                                    title!,
                                    style: NotilusFonts.orbitron(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

// ============================================================================
// GX Futuristic Input
// ============================================================================

/// Champ de saisie futuriste
class GxFuturisticInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Color? accentColor;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const GxFuturisticInput({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.accentColor,
    this.onChanged,
    this.validator,
  });

  @override
  State<GxFuturisticInput> createState() => _GxFuturisticInputState();
}

class _GxFuturisticInputState extends State<GxFuturisticInput> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? NotilusColors.getSecondaryColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: NotilusFonts.rajdhani(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        FocusScope(
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isFocused = hasFocus);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: _isFocused
                      ? accent
                      : Colors.white.withOpacity(0.2),
                  width: _isFocused ? 1.5 : 1,
                ),
              ),
              child: TextFormField(
                controller: widget.controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                onChanged: widget.onChanged,
                validator: widget.validator,
                style: NotilusFonts.rajdhani(
                  fontSize: 14,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: NotilusFonts.rajdhani(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? accent
                              : Colors.white.withOpacity(0.5),
                          size: 20,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? GestureDetector(
                          onTap: widget.onSuffixTap,
                          child: Icon(
                            widget.suffixIcon,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// GX Futuristic Badge
// ============================================================================

/// Badge futuriste
class GxFuturisticBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? accentColor;
  final bool glow;

  const GxFuturisticBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.accentColor,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final badgeColor = color ?? accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        border: Border.all(
          color: badgeColor.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: badgeColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: badgeColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: NotilusFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Divider
// ============================================================================

/// Séparateur futuriste
class GxFuturisticDivider extends StatelessWidget {
  final Color? accentColor;
  final double? height;

  const GxFuturisticDivider({
    super.key,
    this.accentColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    return Container(
      height: height ?? 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            accent.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Switch
// ============================================================================

/// Interrupteur futuriste
class GxFuturisticSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? accentColor;
  final String? label;

  const GxFuturisticSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.accentColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    Widget switchWidget = GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          color: value ? accent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: value ? accent : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? accent : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (label != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              label!,
              style: NotilusFonts.rajdhani(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          switchWidget,
        ],
      );
    }

    return switchWidget;
  }
}

// ============================================================================
// GX Futuristic Progress
// ============================================================================

/// Barre de progression futuriste
class GxFuturisticProgress extends StatelessWidget {
  final double value; // 0.0 à 1.0
  final Color? accentColor;
  final double? height;
  final String? label;

  const GxFuturisticProgress({
    super.key,
    required this.value,
    this.accentColor,
    this.height,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final progressValue = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  '${(progressValue * 100).toInt()}%',
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: height ?? 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: progressValue,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        accent.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Contours géométriques (réutilisé)
// ============================================================================

class _GeometricBorders extends StatelessWidget {
  final Color accentColor;

  const _GeometricBorders({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GeometricBordersPainter(accentColor: accentColor),
      ),
    );
  }
}

class _GeometricBordersPainter extends CustomPainter {
  final Color accentColor;

  _GeometricBordersPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const cornerSize = 20.0;
    const lineLength = 30.0;

    // Coin supérieur gauche
    canvas.drawLine(Offset(0, cornerSize), Offset(0, 0), glowPaint);
    canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), glowPaint);
    canvas.drawLine(Offset(0, cornerSize), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), paint);
    canvas.drawLine(Offset(cornerSize, 0), Offset(cornerSize + lineLength, 0), paint..strokeWidth = 1);
    canvas.drawLine(Offset(0, cornerSize), Offset(0, cornerSize + lineLength), paint..strokeWidth = 1);

    // Coin supérieur droit
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), glowPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), glowPaint);
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);
    canvas.drawLine(Offset(size.width - cornerSize - lineLength, 0), Offset(size.width - cornerSize, 0), paint..strokeWidth = 1);
    canvas.drawLine(Offset(size.width, cornerSize), Offset(size.width, cornerSize + lineLength), paint..strokeWidth = 1);

    // Coin inférieur gauche
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), glowPaint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), glowPaint);
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);
    canvas.drawLine(Offset(0, size.height - cornerSize - lineLength), Offset(0, size.height - cornerSize), paint..strokeWidth = 1);
    canvas.drawLine(Offset(cornerSize, size.height), Offset(cornerSize + lineLength, size.height), paint..strokeWidth = 1);

    // Coin inférieur droit
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), glowPaint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), glowPaint);
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width - cornerSize - lineLength, size.height), Offset(size.width - cornerSize, size.height), paint..strokeWidth = 1);
    canvas.drawLine(Offset(size.width, size.height - cornerSize - lineLength), Offset(size.width, size.height - cornerSize), paint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

