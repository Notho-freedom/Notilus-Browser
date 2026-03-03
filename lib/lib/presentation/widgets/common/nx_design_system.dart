/// Notilus Design System
/// Composants réutilisables pour une UI cohérente et performante
library nx_design_system;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================

/// Tokens de design centralisés
class NxTokens {
  NxTokens._();

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border Radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 999.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // Curves
  static const Curve curveDefault = Curves.easeInOutCubic;
  static const Curve curveSnappy = Curves.easeOutBack;
  static const Curve curveSmooth = Curves.easeInOut;

  // Elevation/Shadows
  static List<BoxShadow> shadowSm(Color color) => [
    BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
  ];
  
  static List<BoxShadow> shadowMd(Color color) => [
    BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
  ];
  
  static List<BoxShadow> shadowLg(Color color) => [
    BoxShadow(color: color.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  // Glass effect
  static const double glassBlur = 10.0;
  static const double glassOpacity = 0.1;
}

// =============================================================================
// NX GLASS CONTAINER - Conteneur avec effet glassmorphism
// =============================================================================

class NxGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final List<BoxShadow>? shadows;

  const NxGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = NxTokens.radiusMd,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blur = NxTokens.glassBlur,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface.withOpacity(NxTokens.glassOpacity);
    final border = borderColor ?? theme.colorScheme.outline.withOpacity(0.2);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: borderWidth),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

// =============================================================================
// NX ICON BUTTON - Bouton icône avec animations
// =============================================================================

class NxIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;
  final Color? hoverColor;
  final Color? backgroundColor;
  final Color? hoverBackgroundColor;
  final bool isActive;
  final EdgeInsetsGeometry padding;

  const NxIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 20.0,
    this.color,
    this.hoverColor,
    this.backgroundColor,
    this.hoverBackgroundColor,
    this.isActive = false,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<NxIconButton> createState() => _NxIconButtonState();
}

class _NxIconButtonState extends State<NxIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = widget.color ?? theme.colorScheme.onSurface.withOpacity(0.7);
    final activeColor = widget.hoverColor ?? theme.colorScheme.primary;
    
    final iconColor = widget.isActive || _isHovered ? activeColor : defaultColor;
    final bgColor = _isHovered 
        ? (widget.hoverBackgroundColor ?? theme.colorScheme.primary.withOpacity(0.1))
        : (widget.backgroundColor ?? Colors.transparent);

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: NxTokens.durationFast,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(NxTokens.radiusSm),
          ),
          child: AnimatedScale(
            scale: _isHovered ? 1.1 : 1.0,
            duration: NxTokens.durationFast,
            child: Icon(
              widget.icon,
              size: widget.size,
              color: iconColor,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }
}

// =============================================================================
// NX TEXT BUTTON - Bouton texte avec animations
// =============================================================================

class NxTextButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? color;
  final Color? hoverColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  const NxTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.color,
    this.hoverColor,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  State<NxTextButton> createState() => _NxTextButtonState();
}

class _NxTextButtonState extends State<NxTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = widget.color ?? theme.colorScheme.onSurface.withOpacity(0.7);
    final hoverColor = widget.hoverColor ?? theme.colorScheme.primary;
    final color = _isHovered ? hoverColor : defaultColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: NxTokens.durationFast,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(NxTokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(widget.leadingIcon, size: 16, color: color),
                const SizedBox(width: NxTokens.spacingSm),
              ],
              Text(
                widget.text,
                style: (widget.textStyle ?? theme.textTheme.bodyMedium)?.copyWith(color: color),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: NxTokens.spacingSm),
                Icon(widget.trailingIcon, size: 16, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// NX SEARCH FIELD - Champ de recherche stylisé
// =============================================================================

class NxSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const NxSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = NxTokens.radiusMd,
  });

  @override
  State<NxSearchField> createState() => _NxSearchFieldState();
}

class _NxSearchFieldState extends State<NxSearchField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.surface.withOpacity(0.5);
    final borderColor = _isFocused 
        ? (widget.borderColor ?? theme.colorScheme.primary)
        : theme.colorScheme.outline.withOpacity(0.3);

    return AnimatedContainer(
      duration: NxTokens.durationFast,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: borderColor, width: _isFocused ? 2 : 1),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Rechercher...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

// =============================================================================
// NX PANEL - Panneau latéral standardisé
// =============================================================================

class NxPanel extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final Color? backgroundColor;
  final double? width;
  final EdgeInsetsGeometry padding;

  const NxPanel({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.actions,
    this.onClose,
    this.backgroundColor,
    this.width,
    this.padding = const EdgeInsets.all(NxTokens.spacingMd),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      color: backgroundColor ?? theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(NxTokens.spacingMd),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: NxTokens.spacingSm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
                if (onClose != null)
                  NxIconButton(
                    icon: Icons.close,
                    onPressed: onClose,
                    tooltip: 'Fermer',
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// NX LOADING - Indicateur de chargement
// =============================================================================

class NxLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const NxLoading({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// =============================================================================
// NX TOOLTIP - Tooltip stylisé
// =============================================================================

class NxTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Duration waitDuration;

  const NxTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(NxTokens.radiusSm),
      ),
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onInverseSurface,
      ),
      child: child,
    );
  }
}

// =============================================================================
// NX DIVIDER - Séparateur stylisé
// =============================================================================

class NxDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const NxDivider({
    super.key,
    this.height = 1,
    this.thickness = 1,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      color: color ?? Theme.of(context).colorScheme.outline.withOpacity(0.2),
    );
  }
}

