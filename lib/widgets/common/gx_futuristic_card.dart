/// Card futuriste Notilus GX - Style OS Science-Fiction
/// Card avec contours géométriques et transparence
library gx_futuristic_card;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';
import 'gx_futuristic_container.dart';

/// Card futuriste avec contours géométriques
class GxFuturisticCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
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
    
    return GxFuturisticContainer(
      accentColor: accent,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      showBorders: showBorders,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || titleIcon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(
                        titleIcon,
                        size: 18,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: NotilusFonts.orbitron(
                            fontSize: 14,
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
    );
  }
}

