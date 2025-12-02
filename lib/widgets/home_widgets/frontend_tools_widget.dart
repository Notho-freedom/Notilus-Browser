/// Widget autonome pour afficher les outils frontend par catégorie
library frontend_tools_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour un outil de développement
class DevTool {
  final String name;
  final String url;
  final Color color;

  const DevTool({
    required this.name,
    required this.url,
    required this.color,
  });
}

/// Modèle pour une catégorie d'outils
class ToolCategory {
  final String name;
  final IconData icon;
  final List<DevTool> tools;

  const ToolCategory({
    required this.name,
    required this.icon,
    required this.tools,
  });
}

/// Widget autonome pour afficher les outils frontend par catégorie
class FrontendToolsWidget extends StatelessWidget {
  final List<ToolCategory> categories;
  final Color? accentColor;
  final double transparency;

  const FrontendToolsWidget({
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
      children: categories.asMap().entries.map((entry) {
        return _buildToolCategorySection(context, entry.value, entry.key);
      }).toList(),
    );
  }

  Widget _buildToolCategorySection(BuildContext context, ToolCategory category, int index) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 16, color: gxRed),
              const SizedBox(width: 8),
              Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: category.tools.map((tool) {
              return _buildToolChip(context, tool);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolChip(BuildContext context, DevTool tool) {
    return GestureDetector(
      onTap: () {
        final tabManager = Provider.of<TabManager>(context, listen: false);
        tabManager.addTab(url: tool.url);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity((1 - transparency).clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tool.color.withOpacity(0.4),
              width: 1,
            ),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

