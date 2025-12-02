/// Widget autonome pour afficher les langages backend
library backend_languages_widget;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour un langage backend
class BackendLanguage {
  final String name;
  final String url;
  final String emoji;
  final Color color;

  const BackendLanguage({
    required this.name,
    required this.url,
    required this.emoji,
    required this.color,
  });
}

/// Widget autonome pour afficher les langages backend
class BackendLanguagesWidget extends StatelessWidget {
  final List<BackendLanguage> languages;
  final Color? accentColor;
  final double transparency;
  final String? title;

  const BackendLanguagesWidget({
    super.key,
    required this.languages,
    this.accentColor,
    this.transparency = 0.0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? '// Languages & Runtimes',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            color: const Color(0xFF339933).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: languages.asMap().entries.map((entry) {
            return _buildLanguageCard(context, entry.value, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(BuildContext context, BackendLanguage lang, int index) {
    return GestureDetector(
      onTap: () {
        final tabManager = Provider.of<TabManager>(context, listen: false);
        tabManager.addTab(url: lang.url);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity((1 - transparency).clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: lang.color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(lang.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                lang.name,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: lang.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

