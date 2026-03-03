/// Widget autonome pour afficher des liens rapides
library quick_links_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour un lien rapide
class QuickLink {
  final String name;
  final String url;
  final IconData icon;

  const QuickLink({
    required this.name,
    required this.url,
    required this.icon,
  });
}

/// Widget autonome pour afficher des liens rapides
class QuickLinksWidget extends StatelessWidget {
  final List<QuickLink> links;
  final Color? accentColor;
  final double transparency;

  const QuickLinksWidget({
    super.key,
    required this.links,
    this.accentColor,
    this.transparency = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: links.asMap().entries.map((entry) {
        if (entry.key > 0) {
          return Row(
            children: [
              const SizedBox(width: 24),
              _buildMinimalLink(context, entry.value, entry.key),
            ],
          );
        }
        return _buildMinimalLink(context, entry.value, entry.key);
      }).toList(),
    );
  }

  Widget _buildMinimalLink(BuildContext context, QuickLink link, int index) {
    return GestureDetector(
      onTap: () {
        final tabManager = Provider.of<TabManager>(context, listen: false);
        tabManager.addTab(url: link.url);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity((0.06 * (1 - transparency)).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                link.icon,
                size: 22,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              link.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

