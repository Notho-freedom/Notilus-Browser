import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/text_selection_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';

/// Menu flottant pour les sélections de texte
class TextSelectionMenu extends StatelessWidget {
  const TextSelectionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TextSelectionService>(
      builder: (context, selectionService, _) {
        if (!selectionService.isVisible || selectionService.selectionPosition == null) {
          return const SizedBox.shrink();
        }

        final position = selectionService.selectionPosition!;
        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
        final accentColor = colorThemeManager.nativeSecondaryColor;
        final bgColor = colorThemeManager.nativeBackgroundColor;

        // S'assurer que la position est dans les limites de l'écran
        final screenSize = MediaQuery.of(context).size;
        final menuWidth = 120.0;
        final menuHeight = 40.0;
        
        // Les coordonnées du WebView sont relatives à la page web, pas à l'écran
        // Pour l'instant, on les utilise telles quelles mais on les limite à l'écran visible
        // TODO: Obtenir la position réelle du WebView pour convertir correctement
        final adjustedX = position.dx.clamp(0.0, screenSize.width - menuWidth);
        // Limiter la position Y pour qu'elle soit visible (les coordonnées du WebView peuvent être très grandes avec le scroll)
        final adjustedY = (position.dy > screenSize.height ? screenSize.height - menuHeight - 20 : position.dy - 50).clamp(0.0, screenSize.height - menuHeight);
        
        final settings = SettingsService();
        final panelOpacity = 1.0 - settings.panelTransparency;
        
        return Positioned(
          left: adjustedX,
          top: adjustedY,
          child: Material(
            color: Colors.transparent,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Contours géométriques GX
                      _GXGeometricBorders(accentColor: accentColor),
                      // Contenu
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GXMenuButton(
                            icon: CupertinoIcons.doc_on_doc,
                            label: 'Copier',
                            onTap: () => selectionService.copyText(),
                            accentColor: accentColor,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: accentColor.withOpacity(0.2),
                          ),
                          _GXMenuButton(
                            icon: CupertinoIcons.search,
                            label: 'Rechercher',
                            onTap: () => selectionService.searchText(),
                            accentColor: accentColor,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: accentColor.withOpacity(0.2),
                          ),
                          _GXMenuButton(
                            icon: CupertinoIcons.xmark,
                            label: 'Fermer',
                            onTap: () => selectionService.hideMenu(),
                            accentColor: accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Contours géométriques GX pour le menu
class _GXGeometricBorders extends StatelessWidget {
  final Color accentColor;

  const _GXGeometricBorders({required this.accentColor});

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
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Coin supérieur gauche
    final cornerLength = 8.0;
    canvas.drawLine(Offset(0, cornerLength), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);

    // Coin supérieur droit
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Coin inférieur gauche
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Coin inférieur droit
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GXMenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  const _GXMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accentColor,
  });

  @override
  State<_GXMenuButton> createState() => _GXMenuButtonState();
}

class _GXMenuButtonState extends State<_GXMenuButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHoverChange(bool hover) {
    setState(() => _isHovered = hover);
    if (hover) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHoverChange(true),
      onExit: (_) => _handleHoverChange(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.accentColor.withOpacity(0.15)
                      : Colors.transparent,
                  border: _isHovered
                      ? Border.all(
                          color: widget.accentColor.withOpacity(0.4),
                          width: 1,
                        )
                      : null,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.3 * _glowAnimation.value),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: 14,
                      color: _isHovered
                          ? widget.accentColor
                          : widget.accentColor.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.label,
                      style: NotilusFonts.rajdhani(
                        fontSize: 11,
                        fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                        color: _isHovered
                            ? widget.accentColor
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

