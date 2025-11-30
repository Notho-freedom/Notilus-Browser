/// Menu contextuel futuriste Notilus GX - Style OS Science-Fiction
library gx_context_menu;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';
import '../../services/sound_effects_service.dart';

class GxContextMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const GxContextMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

class GxContextMenu {
  /// Affiche un menu contextuel futuriste
  static void show({
    required BuildContext context,
    required List<GxContextMenuAction> actions,
    required Offset position,
  }) {
    // Jouer le son d'ouverture
    SoundEffectsService().playPopOpen();
    
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;
    
    // Ajuster la position pour rester dans l'écran
    double x = position.dx;
    double y = position.dy;
    const double menuWidth = 220.0;
    const double menuItemHeight = 48.0;
    final double menuHeight = actions.length * menuItemHeight;
    
    if (x + menuWidth > screenSize.width) {
      x = screenSize.width - menuWidth - 8;
    }
    if (y + menuHeight > screenSize.height) {
      y = screenSize.height - menuHeight - 8;
    }
    if (x < 8) x = 8;
    if (y < 8) y = 8;
    
    final offset = Offset(x, y);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _GxContextMenuOverlay(
        actions: actions,
        position: offset,
        overlayEntry: overlayEntry, // Passer la référence
      ),
    );
    
    overlay.insert(overlayEntry);
  }
}

class _GxContextMenuOverlay extends StatefulWidget {
  final List<GxContextMenuAction> actions;
  final Offset position;
  final OverlayEntry overlayEntry;

  const _GxContextMenuOverlay({
    required this.actions,
    required this.position,
    required this.overlayEntry,
  });

  @override
  State<_GxContextMenuOverlay> createState() => _GxContextMenuOverlayState();
}

class _GxContextMenuOverlayState extends State<_GxContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    SoundEffectsService().playPopClose();
    _controller.reverse().then((_) {
      // Supprimer directement l'OverlayEntry au lieu d'utiliser Navigator.pop()
      widget.overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final primaryColor = themeManager.primaryColor;
    final secondaryColor = themeManager.nativeSecondaryColor;
    final settings = SettingsService();
    final contextMenuOpacity = settings.contextMenuOpacity;

    return GestureDetector(
      onTap: _close,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              left: widget.position.dx,
              top: widget.position.dy,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(contextMenuOpacity),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: secondaryColor.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: secondaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.actions.asMap().entries.map<Widget>((entry) {
                            final index = entry.key;
                            final action = entry.value;
                            final isLast = index == widget.actions.length - 1;
                            
                            return _GxContextMenuItem(
                              action: action,
                              isLast: isLast,
                              onTap: () {
                                _close();
                                action.onTap();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GxContextMenuItem extends StatefulWidget {
  final GxContextMenuAction action;
  final bool isLast;
  final VoidCallback onTap;

  const _GxContextMenuItem({
    required this.action,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_GxContextMenuItem> createState() => _GxContextMenuItemState();
}

class _GxContextMenuItemState extends State<_GxContextMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final secondaryColor = themeManager.nativeSecondaryColor;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? secondaryColor.withOpacity(0.15)
                : Colors.transparent,
            border: widget.isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: secondaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.action.icon,
                size: 18,
                color: widget.action.isDestructive
                    ? NotilusColors.neonRed
                    : secondaryColor,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.action.label,
                  style: NotilusFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.action.isDestructive
                        ? NotilusColors.neonRed
                        : secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

