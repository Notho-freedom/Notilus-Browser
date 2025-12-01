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
  final bool autofocus;

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
    this.autofocus = false,
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
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          validator: widget.validator,
          autofocus: widget.autofocus,
          style: NotilusFonts.rajdhani(
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: widget.hint,
            labelStyle: NotilusFonts.rajdhani(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            hintText: widget.hint,
            hintStyle: NotilusFonts.rajdhani(
              fontSize: 14,
              color: Colors.white.withOpacity(0.4),
            ),
            filled: true,
            fillColor: Colors.transparent,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: Colors.white.withOpacity(0.5),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.24)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.24)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
          height: height ?? 2,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: accent.withOpacity(0.2),
              width: 0.5,
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
                        accent.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
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

// ============================================================================
// GX Futuristic Label
// ============================================================================

/// Label futuriste avec style Notilus GX
class GxFuturisticLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final bool required;
  final IconData? icon;

  const GxFuturisticLabel({
    super.key,
    required this.text,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.required = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = NotilusColors.getSecondaryColor(context);
    final labelColor = color ?? Colors.white.withOpacity(0.9);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: (fontSize ?? 14) * 0.9, color: accent),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: NotilusFonts.rajdhani(
              fontSize: fontSize ?? 14,
              fontWeight: fontWeight ?? FontWeight.w600,
              color: labelColor,
            ),
            textAlign: textAlign,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: NotilusFonts.rajdhani(
              fontSize: (fontSize ?? 14) * 0.9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF453A),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// GX Futuristic List
// ============================================================================

/// Liste futuriste avec items stylisés
class GxFuturisticList extends StatelessWidget {
  final List<Widget> items;
  final EdgeInsets? padding;
  final Color? accentColor;
  final bool showDividers;

  const GxFuturisticList({
    super.key,
    required this.items,
    this.padding,
    this.accentColor,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (context, index) {
        return showDividers
            ? Padding(
                padding: padding ?? EdgeInsets.zero,
                child: GxFuturisticDivider(
                  accentColor: accent,
                  height: 0.5,
                ),
              )
            : const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        return items[index];
      },
    );
  }
}

/// Item de liste futuriste
class GxFuturisticListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accentColor;

  const GxFuturisticListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: NotilusFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  child: title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style: NotilusFonts.rajdhani(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return RepaintBoundary(
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: accent.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: content,
          ),
        ),
      );
    }

    return RepaintBoundary(child: content);
  }
}

// ============================================================================
// GX Futuristic Table
// ============================================================================

/// Tableau futuriste
class GxFuturisticTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final Color? accentColor;
  final bool striped;
  final bool hoverable;

  const GxFuturisticTable({
    super.key,
    required this.headers,
    required this.rows,
    this.accentColor,
    this.striped = true,
    this.hoverable = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
        border: Border.all(
          color: accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: headers.asMap().entries.map((entry) {
                final index = entry.key;
                final header = entry.value;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: index < headers.length - 1
                        ? BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: accent.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                          )
                        : null,
                    child: Text(
                      header,
                      style: NotilusFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Rows
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return _GxFuturisticTableRow(
              cells: row,
              isEven: striped && index % 2 == 0,
              accent: accent,
              hoverable: hoverable,
              isLast: index == rows.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _GxFuturisticTableRow extends StatefulWidget {
  final List<Widget> cells;
  final bool isEven;
  final Color accent;
  final bool hoverable;
  final bool isLast;

  const _GxFuturisticTableRow({
    required this.cells,
    required this.isEven,
    required this.accent,
    required this.hoverable,
    required this.isLast,
  });

  @override
  State<_GxFuturisticTableRow> createState() => _GxFuturisticTableRowState();
}

class _GxFuturisticTableRowState extends State<_GxFuturisticTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    Color rowColor = bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0));
    if (widget.isEven) {
      rowColor = Colors.white.withOpacity(0.02);
    }
    if (widget.hoverable && _isHovered) {
      rowColor = widget.accent.withOpacity(0.1);
    }

    return MouseRegion(
      onEnter: widget.hoverable ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.hoverable ? (_) => setState(() => _isHovered = false) : null,
      child: Container(
        decoration: BoxDecoration(
          color: rowColor,
          border: !widget.isLast
              ? Border(
                  bottom: BorderSide(
                    color: widget.accent.withOpacity(0.1),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: Row(
          children: widget.cells.asMap().entries.map((entry) {
            final index = entry.key;
            final cell = entry.value;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: index < widget.cells.length - 1
                    ? BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: widget.accent.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                      )
                    : null,
                child: DefaultTextStyle(
                  style: NotilusFonts.rajdhani(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  child: cell,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Button
// ============================================================================

/// Bouton futuriste
enum GxFuturisticButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

class GxFuturisticButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GxFuturisticButtonVariant variant;
  final Color? accentColor;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const GxFuturisticButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = GxFuturisticButtonVariant.primary,
    this.accentColor,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    double borderWidth = 1;

    switch (variant) {
      case GxFuturisticButtonVariant.primary:
        backgroundColor = accent;
        textColor = Colors.white;
        borderColor = accent;
        break;
      case GxFuturisticButtonVariant.secondary:
        backgroundColor = accent.withOpacity(0.2);
        textColor = accent;
        borderColor = accent.withOpacity(0.3);
        break;
      case GxFuturisticButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = accent;
        borderColor = accent;
        borderWidth = 1.5;
        break;
      case GxFuturisticButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = Colors.white.withOpacity(0.8);
        borderColor = Colors.transparent;
        break;
      case GxFuturisticButtonVariant.danger:
        backgroundColor = const Color(0xFFFF453A);
        textColor = Colors.white;
        borderColor = const Color(0xFFFF453A);
        break;
    }

    Widget button = Container(
      width: width,
      height: height ?? 40,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: variant == GxFuturisticButtonVariant.primary
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
            if (label.isNotEmpty) const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            if (label.isNotEmpty) const SizedBox(width: 8),
          ],
          if (label.isNotEmpty)
            Text(
              label,
              style: NotilusFonts.rajdhani(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
        ],
      ),
    );

    if (onPressed != null && !isLoading) {
      return InkWell(
        onTap: onPressed,
        child: button,
      );
    }

    return Opacity(
      opacity: onPressed == null || isLoading ? 0.5 : 1.0,
      child: button,
    );
  }
}

// ============================================================================
// GX Futuristic Chip
// ============================================================================

/// Chip/Tag futuriste
class GxFuturisticChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onDelete;
  final Color? accentColor;
  final bool selected;

  const GxFuturisticChip({
    super.key,
    required this.label,
    this.icon,
    this.onDelete,
    this.accentColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? accent.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        border: Border.all(
          color: selected ? accent : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: selected ? accent : Colors.white.withOpacity(0.7)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: NotilusFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? accent : Colors.white.withOpacity(0.8),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onDelete,
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: selected ? accent : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Tooltip
// ============================================================================

/// Tooltip futuriste avec contours géométriques
class GxFuturisticTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Color? accentColor;
  final Duration waitDuration;
  final Duration showDuration;

  const GxFuturisticTooltip({
    super.key,
    required this.message,
    required this.child,
    this.accentColor,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(seconds: 2),
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Tooltip(
      message: message,
      preferBelow: false,
      waitDuration: waitDuration,
      showDuration: showDuration,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
        border: Border.all(
          color: accent.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      textStyle: NotilusFonts.rajdhani(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      child: child,
    );
  }
}

/// Tooltip futuriste personnalisé avec overlay (plus de contrôle)
class GxFuturisticTooltipOverlay extends StatefulWidget {
  final String message;
  final Widget child;
  final Color? accentColor;
  final Duration delay;
  final TooltipPosition position;

  const GxFuturisticTooltipOverlay({
    super.key,
    required this.message,
    required this.child,
    this.accentColor,
    this.delay = const Duration(milliseconds: 500),
    this.position = TooltipPosition.bottom,
  });

  @override
  State<GxFuturisticTooltipOverlay> createState() => _GxFuturisticTooltipOverlayState();
}

enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}

class _GxFuturisticTooltipOverlayState extends State<GxFuturisticTooltipOverlay>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (_isVisible) return;
    _isVisible = true;

    final accent = widget.accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _GxFuturisticTooltipWidget(
        message: widget.message,
        position: widget.position,
        childPosition: offset,
        childSize: size,
        accentColor: accent,
        bgColor: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
        fadeAnimation: _fadeAnimation,
        scaleAnimation: _scaleAnimation,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  void _hideTooltip() {
    if (!_isVisible) return;
    _controller.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => Future.delayed(widget.delay, _showTooltip),
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }
}

class _GxFuturisticTooltipWidget extends StatelessWidget {
  final String message;
  final TooltipPosition position;
  final Offset childPosition;
  final Size childSize;
  final Color accentColor;
  final Color bgColor;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const _GxFuturisticTooltipWidget({
    required this.message,
    required this.position,
    required this.childPosition,
    required this.childSize,
    required this.accentColor,
    required this.bgColor,
    required this.fadeAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const tooltipPadding = 8.0;
    const arrowSize = 8.0;
    const spacing = 4.0;

    // Calculer la position du tooltip
    double tooltipX = 0;
    double tooltipY = 0;
    Offset arrowOffset = Offset.zero;

    switch (position) {
      case TooltipPosition.top:
        tooltipX = childPosition.dx + (childSize.width / 2);
        tooltipY = childPosition.dy - spacing;
        arrowOffset = Offset(0, arrowSize);
        break;
      case TooltipPosition.bottom:
        tooltipX = childPosition.dx + (childSize.width / 2);
        tooltipY = childPosition.dy + childSize.height + spacing;
        arrowOffset = Offset(0, -arrowSize);
        break;
      case TooltipPosition.left:
        tooltipX = childPosition.dx - spacing;
        tooltipY = childPosition.dy + (childSize.height / 2);
        arrowOffset = Offset(arrowSize, 0);
        break;
      case TooltipPosition.right:
        tooltipX = childPosition.dx + childSize.width + spacing;
        tooltipY = childPosition.dy + (childSize.height / 2);
        arrowOffset = Offset(-arrowSize, 0);
        break;
    }

    return Positioned(
      left: tooltipX,
      top: tooltipY,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: CustomPaint(
              painter: _GxFuturisticTooltipPainter(
                accentColor: accentColor,
                bgColor: bgColor,
                position: position,
                arrowOffset: arrowOffset,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                constraints: BoxConstraints(
                  maxWidth: screenSize.width * 0.3,
                ),
                child: Text(
                  message,
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GxFuturisticTooltipPainter extends CustomPainter {
  final Color accentColor;
  final Color bgColor;
  final TooltipPosition position;
  final Offset arrowOffset;

  _GxFuturisticTooltipPainter({
    required this.accentColor,
    required this.bgColor,
    required this.position,
    required this.arrowOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    // Dessiner le fond
    final path = Path();
    const cornerSize = 4.0;
    const arrowSize = 8.0;

    // Calculer la position de la flèche
    Offset arrowStart = Offset.zero;
    Offset arrowEnd = Offset.zero;
    Offset arrowTip = Offset.zero;

    switch (position) {
      case TooltipPosition.top:
        arrowStart = Offset(size.width / 2 - arrowSize, size.height);
        arrowEnd = Offset(size.width / 2 + arrowSize, size.height);
        arrowTip = Offset(size.width / 2, size.height + arrowSize);
        break;
      case TooltipPosition.bottom:
        arrowStart = Offset(size.width / 2 - arrowSize, 0);
        arrowEnd = Offset(size.width / 2 + arrowSize, 0);
        arrowTip = Offset(size.width / 2, -arrowSize);
        break;
      case TooltipPosition.left:
        arrowStart = Offset(size.width, size.height / 2 - arrowSize);
        arrowEnd = Offset(size.width, size.height / 2 + arrowSize);
        arrowTip = Offset(size.width + arrowSize, size.height / 2);
        break;
      case TooltipPosition.right:
        arrowStart = Offset(0, size.height / 2 - arrowSize);
        arrowEnd = Offset(0, size.height / 2 + arrowSize);
        arrowTip = Offset(-arrowSize, size.height / 2);
        break;
    }

    // Dessiner le rectangle avec coins arrondis
    if (position == TooltipPosition.bottom) {
      path.moveTo(cornerSize, 0);
      path.lineTo(arrowStart.dx, 0);
      path.lineTo(arrowTip.dx, arrowTip.dy);
      path.lineTo(arrowEnd.dx, 0);
      path.lineTo(size.width - cornerSize, 0);
      path.quadraticBezierTo(size.width, 0, size.width, cornerSize);
      path.lineTo(size.width, size.height - cornerSize);
      path.quadraticBezierTo(size.width, size.height, size.width - cornerSize, size.height);
      path.lineTo(cornerSize, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerSize);
      path.lineTo(0, cornerSize);
      path.quadraticBezierTo(0, 0, cornerSize, 0);
    } else if (position == TooltipPosition.top) {
      path.moveTo(cornerSize, size.height);
      path.lineTo(arrowStart.dx, size.height);
      path.lineTo(arrowTip.dx, arrowTip.dy);
      path.lineTo(arrowEnd.dx, size.height);
      path.lineTo(size.width - cornerSize, size.height);
      path.quadraticBezierTo(size.width, size.height, size.width, size.height - cornerSize);
      path.lineTo(size.width, cornerSize);
      path.quadraticBezierTo(size.width, 0, size.width - cornerSize, 0);
      path.lineTo(cornerSize, 0);
      path.quadraticBezierTo(0, 0, 0, cornerSize);
      path.lineTo(0, size.height - cornerSize);
      path.quadraticBezierTo(0, size.height, cornerSize, size.height);
    } else {
      // Pour left et right, on simplifie sans flèche pour l'instant
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(cornerSize),
      ));
    }

    canvas.drawPath(path, bgPaint);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Contours géométriques aux coins
    const lineLength = 8.0;
    paint.strokeWidth = 1;

    // Coin supérieur gauche
    canvas.drawLine(Offset(0, cornerSize), Offset(0, cornerSize + lineLength), paint);
    canvas.drawLine(Offset(cornerSize, 0), Offset(cornerSize + lineLength, 0), paint);

    // Coin supérieur droit
    canvas.drawLine(Offset(size.width, cornerSize), Offset(size.width, cornerSize + lineLength), paint);
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width - cornerSize - lineLength, 0), paint);

    // Coin inférieur gauche
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height - cornerSize - lineLength), paint);
    canvas.drawLine(Offset(cornerSize, size.height), Offset(cornerSize + lineLength, size.height), paint);

    // Coin inférieur droit
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height - cornerSize - lineLength), paint);
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width - cornerSize - lineLength, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// GX Futuristic Dropdown
// ============================================================================

/// Menu déroulant futuriste
class GxFuturisticDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? label;
  final Color? accentColor;
  final bool isExpanded;

  const GxFuturisticDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.label,
    this.accentColor,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    Widget dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.24),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: hint != null
              ? Text(
                  hint!,
                  style: NotilusFonts.rajdhani(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          isExpanded: true, // Force l'expansion pour éviter le débordement
          icon: Icon(Icons.arrow_drop_down_rounded, color: accent),
          iconSize: 24,
          dropdownColor: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
          style: NotilusFonts.rajdhani(
            fontSize: 14,
            color: Colors.white,
          ),
          selectedItemBuilder: (context) {
            return items.map((item) {
              Widget child = item.child;
              // Si c'est un Text, ajouter overflow
              if (child is Text) {
                child = Text(
                  child.data ?? '',
                  style: child.style ?? NotilusFonts.rajdhani(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              }
              return Container(
                alignment: Alignment.centerLeft,
                child: DefaultTextStyle(
                  style: NotilusFonts.rajdhani(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  child: child,
                ),
              );
            }).toList();
          },
        ),
      ),
    );

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GxFuturisticLabel(text: label!),
          const SizedBox(height: 8),
          dropdown,
        ],
      );
    }

    return dropdown;
  }
}

// ============================================================================
// GX Futuristic Slider
// ============================================================================

/// Slider futuriste
class GxFuturisticSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final String? label;
  final Color? accentColor;
  final int? divisions;
  final String Function(double)? labelBuilder;

  const GxFuturisticSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 100.0,
    this.onChanged,
    this.label,
    this.accentColor,
    this.divisions,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    Widget slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 2,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );

    if (label != null || labelBuilder != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            GxFuturisticLabel(text: label!),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: slider),
              const SizedBox(width: 12),
              Text(
                labelBuilder != null ? labelBuilder!(value) : value.toStringAsFixed(0),
                style: NotilusFonts.rajdhani(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return slider;
  }
}

// ============================================================================
// GX Futuristic Checkbox
// ============================================================================

/// Case à cocher futuriste
class GxFuturisticCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final Color? accentColor;

  const GxFuturisticCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    Widget checkbox = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? accent : Colors.transparent,
        border: Border.all(
          color: value ? accent : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: value
          ? Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );

    if (label != null) {
      return InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            checkbox,
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label!,
                style: NotilusFonts.rajdhani(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: checkbox,
    );
  }
}

// ============================================================================
// GX Futuristic Radio
// ============================================================================

/// Bouton radio futuriste
class GxFuturisticRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final Color? accentColor;

  const GxFuturisticRadio({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final isSelected = value == groupValue;

    Widget radio = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accent : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
            )
          : null,
    );

    if (label != null) {
      return InkWell(
        onTap: onChanged != null ? () => onChanged!(value) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            radio,
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label!,
                style: NotilusFonts.rajdhani(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onChanged != null ? () => onChanged!(value) : null,
      child: radio,
    );
  }
}

// ============================================================================
// GX Futuristic Tabs
// ============================================================================

/// Onglets futuristes
class GxFuturisticTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTap;
  final Color? accentColor;

  const GxFuturisticTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    return Row(
      children: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        final isSelected = index == selectedIndex;

        return Expanded(
          child: InkWell(
            onTap: onTap != null ? () => onTap!(index) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withOpacity(0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: NotilusFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? accent : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// GX Futuristic Accordion
// ============================================================================

/// Accordéon futuriste
class GxFuturisticAccordion extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Color? accentColor;
  final IconData? icon;

  const GxFuturisticAccordion({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.accentColor,
    this.icon,
  });

  @override
  State<GxFuturisticAccordion> createState() => _GxFuturisticAccordionState();
}

class _GxFuturisticAccordionState extends State<GxFuturisticAccordion>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
        border: Border.all(
          color: accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: accent),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: NotilusFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: SizeTransition(
              sizeFactor: _controller,
              axisAlignment: -1.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: accent.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Skeleton
// ============================================================================

/// Skeleton loader futuriste
class GxFuturisticSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? accentColor;

  const GxFuturisticSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.accentColor,
  });

  @override
  State<GxFuturisticSkeleton> createState() => _GxFuturisticSkeletonState();
}

class _GxFuturisticSkeletonState extends State<GxFuturisticSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? NotilusColors.getSecondaryColor(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment(_animation.value - 1, 0),
                end: Alignment(_animation.value, 0),
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Avatar
// ============================================================================

/// Avatar futuriste
class GxFuturisticAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final IconData? icon;
  final double size;
  final Color? accentColor;
  final Color? backgroundColor;

  const GxFuturisticAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.icon,
    this.size = 40,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final bgColor = backgroundColor ?? accent.withOpacity(0.2);

    Widget content;
    if (imageUrl != null) {
      content = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(accent, bgColor);
          },
        ),
      );
    } else if (initials != null) {
      content = _buildFallback(accent, bgColor);
    } else if (icon != null) {
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(
            color: accent,
            width: 2,
          ),
        ),
        child: Icon(icon, size: size * 0.5, color: accent),
      );
    } else {
      content = _buildFallback(accent, bgColor);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: content,
    );
  }

  Widget _buildFallback(Color accent, Color bgColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Center(
        child: initials != null
            ? Text(
                initials!,
                style: NotilusFonts.rajdhani(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              )
            : Icon(Icons.person_rounded, size: size * 0.5, color: accent),
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Separator
// ============================================================================

/// Séparateur futuriste (amélioration du Divider)
class GxFuturisticSeparator extends StatelessWidget {
  final String? label;
  final Color? accentColor;
  final double height;
  final EdgeInsets? margin;

  const GxFuturisticSeparator({
    super.key,
    this.label,
    this.accentColor,
    this.height = 1,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    if (label != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accent.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label!,
                style: NotilusFonts.rajdhani(
                  fontSize: 12,
                  color: accent.withOpacity(0.7),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              accent.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GX Futuristic TextArea
// ============================================================================

/// Zone de texte multiligne futuriste
class GxFuturisticTextArea extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final Color? accentColor;
  final String? Function(String?)? validator;

  const GxFuturisticTextArea({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.maxLines,
    this.minLines,
    this.onChanged,
    this.accentColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    Widget textArea = TextFormField(
      controller: controller,
      maxLines: maxLines ?? 5,
      minLines: minLines ?? 3,
      onChanged: onChanged,
      validator: validator,
      style: NotilusFonts.rajdhani(
        fontSize: 14,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: NotilusFonts.rajdhani(
          fontSize: 14,
          color: Colors.white.withOpacity(0.6),
        ),
        hintText: hint,
        hintStyle: NotilusFonts.rajdhani(
          fontSize: 14,
          color: Colors.white.withOpacity(0.4),
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.24)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GxFuturisticLabel(text: label!),
          const SizedBox(height: 8),
          textArea,
        ],
      );
    }

    return textArea;
  }
}

// ============================================================================
// GX Futuristic Alert
// ============================================================================

/// Alerte futuriste
enum GxFuturisticAlertType {
  success,
  error,
  warning,
  info,
}

class GxFuturisticAlert extends StatelessWidget {
  final String title;
  final String? message;
  final GxFuturisticAlertType type;
  final VoidCallback? onClose;
  final Color? accentColor;

  const GxFuturisticAlert({
    super.key,
    required this.title,
    this.message,
    this.type = GxFuturisticAlertType.info,
    this.onClose,
    this.accentColor,
  });

  Color _getColor() {
    switch (type) {
      case GxFuturisticAlertType.success:
        return const Color(0xFF22C55E);
      case GxFuturisticAlertType.error:
        return const Color(0xFFEF4444);
      case GxFuturisticAlertType.warning:
        return const Color(0xFFF59E0B);
      case GxFuturisticAlertType.info:
        return accentColor ?? const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (type) {
      case GxFuturisticAlertType.success:
        return Icons.check_circle_rounded;
      case GxFuturisticAlertType.error:
        return Icons.error_rounded;
      case GxFuturisticAlertType.warning:
        return Icons.warning_rounded;
      case GxFuturisticAlertType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
          top: BorderSide(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
          right: BorderSide(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
          bottom: BorderSide(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: NotilusFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: NotilusFonts.rajdhani(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            InkWell(
              onTap: onClose,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// GX Futuristic Spinner
// ============================================================================

/// Spinner de chargement futuriste
class GxFuturisticSpinner extends StatelessWidget {
  final double size;
  final Color? accentColor;
  final String? message;

  const GxFuturisticSpinner({
    super.key,
    this.size = 40,
    this.accentColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);

    Widget spinner = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          const SizedBox(height: 16),
          Text(
            message!,
            style: NotilusFonts.rajdhani(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      );
    }

    return spinner;
  }
}

