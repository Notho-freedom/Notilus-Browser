import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';

class ContextMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const ContextMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

class ContextMenu extends StatelessWidget {
  final List<ContextMenuAction> actions;
  final Offset? position;

  const ContextMenu({
    super.key,
    required this.actions,
    this.position,
  });

  static void show({
    required BuildContext context,
    required List<ContextMenuAction> actions,
    Offset? position,
  }) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = position ?? (renderBox?.localToGlobal(Offset.zero) ?? Offset.zero);

    overlay.insert(
      OverlayEntry(
        builder: (context) => _ContextMenuOverlay(
          actions: actions,
          position: offset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _ContextMenuOverlay extends StatefulWidget {
  final List<ContextMenuAction> actions;
  final Offset position;

  const _ContextMenuOverlay({
    required this.actions,
    required this.position,
  });

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final primaryColor = themeManager.primaryColor;
    final secondaryColor = themeManager.nativeSecondaryColor;
    final settings = SettingsService();
    final contextMenuOpacity = settings.contextMenuOpacity;
    
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              left: widget.position.dx,
              top: widget.position.dy,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 200),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(contextMenuOpacity),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: secondaryColor.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.actions.map((action) {
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          action.onTap();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                action.icon,
                                size: 16,
                                color: action.isDestructive
                                    ? NotilusColors.neonRed
                                    : secondaryColor,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  action.label,
                                  style: TextStyle(
                                    color: action.isDestructive
                                        ? NotilusColors.neonRed
                                        : secondaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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

