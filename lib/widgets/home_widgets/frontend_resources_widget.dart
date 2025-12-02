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
  final List<FrontendResource>? resources;
  final Color? accentColor;
  final double transparency;
  final String? title;

  const FrontendResourcesWidget({
    super.key,
    this.resources,
    this.accentColor,
    this.transparency = 0.0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    // Utiliser les ressources fournies ou les valeurs par défaut
    final currentResources = resources ?? [
      FrontendResource(name: 'React', url: 'https://react.dev', emoji: '⚛️', color: const Color(0xFF61DAFB)),
      FrontendResource(name: 'Vue.js', url: 'https://vuejs.org', emoji: '💚', color: const Color(0xFF42B883)),
      FrontendResource(name: 'Angular', url: 'https://angular.io', emoji: '🔺', color: const Color(0xFFDD0031)),
      FrontendResource(name: 'Svelte', url: 'https://svelte.dev', emoji: '🔥', color: const Color(0xFFFF3E00)),
      FrontendResource(name: 'Next.js', url: 'https://nextjs.org', emoji: '▲', color: const Color(0xFF000000)),
      FrontendResource(name: 'Tailwind', url: 'https://tailwindcss.com', emoji: '💨', color: const Color(0xFF06B6D4)),
      FrontendResource(name: 'TypeScript', url: 'https://typescriptlang.org', emoji: '📘', color: const Color(0xFF3178C6)),
      FrontendResource(name: 'Vite', url: 'https://vitejs.dev', emoji: '⚡', color: const Color(0xFFBD34FE)),
    ];
    
    if (currentResources.isEmpty) {
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
          children: currentResources.asMap().entries.map((entry) {
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

