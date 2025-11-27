/// Dialog futuriste Notilus GX - Style OS Science-Fiction
/// Contours géométriques avec effets de lumière et animations
library gx_futuristic_dialog;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';

/// Dialog futuriste avec contours géométriques façon OS SF
class GxFuturisticDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final List<Widget>? actions;
  final double? width;
  final double? height;
  final Color? accentColor;
  final bool showCloseButton;

  const GxFuturisticDialog({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.actions,
    this.width,
    this.height,
    this.accentColor,
    this.showCloseButton = true,
  });

  /// Affiche un dialog futuriste (méthode statique pour faciliter l'utilisation)
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    IconData? titleIcon,
    List<Widget>? actions,
    double? width,
    double? height,
    Color? accentColor,
    bool showCloseButton = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => GxFuturisticDialog(
        title: title,
        titleIcon: titleIcon,
        actions: actions,
        width: width,
        height: height,
        accentColor: accentColor,
        showCloseButton: showCloseButton,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.7 + (0.3 * Curves.easeOutBack.transform(value)),
            child: Opacity(
              opacity: Curves.easeOut.transform(value),
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: width ?? 500,
          height: height,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
                  border: Border.all(
                    color: accent.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Contours géométriques
                    _GeometricBorders(accentColor: accent),
                    
                    // Contenu
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header avec titre
                        if (title != null || titleIcon != null)
                          _DialogHeader(
                            title: title,
                            icon: titleIcon,
                            accentColor: accent,
                            showCloseButton: showCloseButton,
                            onClose: () => Navigator.of(context).pop(),
                          ),
                        
                        // Contenu principal
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              top: title != null ? 0 : 24,
                              left: 24,
                              right: 24,
                              bottom: actions != null ? 0 : 24,
                            ),
                            child: child,
                          ),
                        ),
                        
                        // Actions
                        if (actions != null)
                          _DialogActions(
                            actions: actions!,
                            accentColor: accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header du dialog avec titre et bouton de fermeture
class _DialogHeader extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Color accentColor;
  final bool showCloseButton;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.title,
    this.icon,
    required this.accentColor,
    required this.showCloseButton,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: NotilusFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          if (showCloseButton)
            _CloseButton(
              accentColor: accentColor,
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

/// Bouton de fermeture futuriste
class _CloseButton extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onPressed;

  const _CloseButton({
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.2)
                : Colors.transparent,
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor
                  : widget.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: _isHovered
                ? widget.accentColor
                : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

/// Actions du dialog
class _DialogActions extends StatelessWidget {
  final List<Widget> actions;
  final Color accentColor;

  const _DialogActions({
    required this.actions,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: action,
                ))
            .toList(),
      ),
    );
  }
}

/// Contours géométriques aux angles
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
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, 0),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerSize, 0),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerSize, 0),
      paint,
    );
    canvas.drawLine(
      Offset(cornerSize, 0),
      Offset(cornerSize + lineLength, 0),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, cornerSize + lineLength),
      paint..strokeWidth = 1,
    );

    // Coin supérieur droit
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize - lineLength, 0),
      Offset(size.width - cornerSize, 0),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(size.width, cornerSize),
      Offset(size.width, cornerSize + lineLength),
      paint..strokeWidth = 1,
    );

    // Coin inférieur gauche
    canvas.drawLine(
      Offset(0, size.height - cornerSize),
      Offset(0, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerSize, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, size.height - cornerSize),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerSize, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height - cornerSize - lineLength),
      Offset(0, size.height - cornerSize),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(cornerSize, size.height),
      Offset(cornerSize + lineLength, size.height),
      paint..strokeWidth = 1,
    );

    // Coin inférieur droit
    canvas.drawLine(
      Offset(size.width - cornerSize, size.height),
      Offset(size.width, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize),
      Offset(size.width, size.height),
      glowPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerSize - lineLength, size.height),
      Offset(size.width - cornerSize, size.height),
      paint..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize - lineLength),
      Offset(size.width, size.height - cornerSize),
      paint..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bouton futuriste pour les dialogs
class GxFuturisticButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GxFuturisticButtonVariant variant;
  final Color? accentColor;

  const GxFuturisticButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = GxFuturisticButtonVariant.primary,
    this.accentColor,
  });

  @override
  State<GxFuturisticButton> createState() => _GxFuturisticButtonState();
}

class _GxFuturisticButtonState extends State<GxFuturisticButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? NotilusColors.getSecondaryColor(context);
    final isPrimary = widget.variant == GxFuturisticButtonVariant.primary;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? (_isHovered ? accent : accent.withOpacity(0.15))
                : Colors.transparent,
            border: Border.all(
              color: isPrimary
                  ? accent
                  : accent.withOpacity(_isHovered ? 0.8 : 0.4),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered && isPrimary
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : 1.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: isPrimary ? Colors.white : accent,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: NotilusFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum GxFuturisticButtonVariant {
  primary,
  secondary,
}

