/// Section futuriste Notilus GX - Pour les sections de contenu
/// Section avec contours géométriques et transparence
library gx_futuristic_section;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/services/color_theme_manager.dart';
import 'gx_futuristic_container.dart';

/// Section futuriste pour le contenu
class GxFuturisticSection extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GxFuturisticSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NotilusColors.getSecondaryColor(context);
    
    return GxFuturisticContainer(
      accentColor: accent,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || icon != null)
            Row(
              children: [
                if (icon != null) ...[
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
                      icon,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: NotilusFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: NotilusFonts.rajdhani(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          if (title != null || icon != null) const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

