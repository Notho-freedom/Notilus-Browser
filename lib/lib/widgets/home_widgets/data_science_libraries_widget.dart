/// Widget autonome pour afficher les librairies data science
library data_science_libraries_widget;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour une librairie data science
class DataScienceLibrary {
  final String name;
  final String emoji;
  final String url;
  final Color color;

  const DataScienceLibrary({
    required this.name,
    required this.emoji,
    required this.url,
    required this.color,
  });
}

/// Widget autonome pour afficher les librairies data science
class DataScienceLibrariesWidget extends StatelessWidget {
  final List<DataScienceLibrary> libraries;
  final Color? accentColor;
  final double transparency;
  final String? title;

  const DataScienceLibrariesWidget({
    super.key,
    required this.libraries,
    this.accentColor,
    this.transparency = 0.0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (libraries.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF8B5CF6), const Color(0xFF3B82F6)],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title ?? 'ESSENTIAL LIBRARIES',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: libraries.asMap().entries.map((entry) {
            return _buildLibraryCard(context, entry.value, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLibraryCard(BuildContext context, DataScienceLibrary lib, int index) {
    return GestureDetector(
      onTap: () {
        final tabManager = Provider.of<TabManager>(context, listen: false);
        tabManager.addTab(url: lib.url);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity((1 - transparency).clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lib.color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(lib.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                lib.name,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: lib.color,
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

