/// Widget autonome pour afficher les ressources frontend
library frontend_resources_widget;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour une ressource frontend
class FrontendResource {
  final String name;
  final String url;
  final String emoji;
  final Color color;

  const FrontendResource({
    required this.name,
    required this.url,
    required this.emoji,
    required this.color,
  });
}

/// Widget autonome pour afficher les ressources frontend
class FrontendResourcesWidget extends StatelessWidget {
  final List<FrontendResource> resources;
  final Color? accentColor;
  final double transparency;
  final String? title;

  const FrontendResourcesWidget({
    super.key,
    required this.resources,
    this.accentColor,
    this.transparency = 0.0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (resources.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF61DAFB), const Color(0xFF42B883)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title ?? 'FRAMEWORKS & LIBRARIES',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF42B883), const Color(0xFF61DAFB)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: resources.asMap().entries.map((entry) {
            return _buildFrameworkCard(context, entry.value, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrameworkCard(BuildContext context, FrontendResource resource, int index) {
    return GestureDetector(
      onTap: () {
        final tabManager = Provider.of<TabManager>(context, listen: false);
        tabManager.addTab(url: resource.url);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity((1 - transparency).clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: resource.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                resource.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                resource.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: resource.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

