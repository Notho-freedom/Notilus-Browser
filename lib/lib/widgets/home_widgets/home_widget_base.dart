/// Widget de base pour tous les widgets de la page d'accueil
library home_widget_base;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/home_widget_models.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';

/// Widget de base avec header et actions
class HomeWidgetBase extends StatelessWidget {
  final HomeWidget widget;
  final Widget child;
  final VoidCallback? onMinimize;
  final VoidCallback? onRemove;
  final VoidCallback? onSettings;
  final bool showHeader;

  const HomeWidgetBase({
    super.key,
    required this.widget,
    required this.child,
    this.onMinimize,
    this.onRemove,
    this.onSettings,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = colorTheme.nativeSecondaryColor;

    if (widget.isMinimized) {
      return _buildMinimized(context, accentColor);
    }

    return Container(
      decoration: BoxDecoration(
        color: NotilusColors.chromeDark.withOpacity(0.6),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeader) _buildHeader(context, accentColor),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accentColor) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.type.icon,
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.type.label,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (onSettings != null)
            IconButton(
              icon: const Icon(CupertinoIcons.settings, size: 14),
              color: Colors.white.withOpacity(0.6),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onSettings,
            ),
          if (onMinimize != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(CupertinoIcons.minus, size: 14),
              color: Colors.white.withOpacity(0.6),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onMinimize,
            ),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(CupertinoIcons.xmark, size: 14),
              color: Colors.white.withOpacity(0.6),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimized(BuildContext context, Color accentColor) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: NotilusColors.chromeDark.withOpacity(0.6),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            widget.type.icon,
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.type.label,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          if (onMinimize != null)
            IconButton(
              icon: const Icon(CupertinoIcons.plus, size: 14),
              color: Colors.white.withOpacity(0.6),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onMinimize,
            ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(CupertinoIcons.xmark, size: 14),
              color: Colors.white.withOpacity(0.6),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

