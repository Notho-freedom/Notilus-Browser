/// Widget autonome pour afficher les outils DevOps par catégorie
library devops_tools_widget;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour un outil DevOps
class DevOpsTool {
  final String name;
  final String url;
  final Color color;

  const DevOpsTool({
    required this.name,
    required this.url,
    required this.color,
  });
}

/// Modèle pour une catégorie DevOps
class DevOpsCategory {
  final String name;
  final String emoji;
  final List<DevOpsTool> tools;

  const DevOpsCategory({
    required this.name,
    required this.emoji,
    required this.tools,
  });
}

/// Widget autonome pour afficher les outils DevOps par catégorie
class DevOpsToolsWidget extends StatelessWidget {
  final List<DevOpsCategory> categories;
  final Color? accentColor;
  final double transparency;

  const DevOpsToolsWidget({
    super.key,
    required this.categories,
    this.accentColor,
    this.transparency = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.asMap().entries.map((entry) {
        return _buildToolCategory(context, entry.value, entry.key);
      }).toList(),
    );
  }

  Widget _buildToolCategory(BuildContext context, DevOpsCategory category, int index) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: gxRed.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: category.tools.map((tool) {
              return _buildToolButton(context, tool);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, DevOpsTool tool) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    return GestureDetector(
      onTap: () {
        final tabManager = Provider.of<TabManager>(context, listen: false);
        tabManager.addTab(url: tool.url);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity((1 - transparency).clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tool.color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tool.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tool.name,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

