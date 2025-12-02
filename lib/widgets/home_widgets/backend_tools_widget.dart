/// Widget autonome pour afficher les outils backend par section
library backend_tools_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour un outil backend
class BackendTool {
  final String name;
  final String url;
  final Color color;

  const BackendTool({
    required this.name,
    required this.url,
    required this.color,
  });
}

/// Modèle pour une section d'outils
class ToolSection {
  final String name;
  final IconData icon;
  final List<BackendTool> tools;

  const ToolSection({
    required this.name,
    required this.icon,
    required this.tools,
  });
}

/// Widget autonome pour afficher les outils backend par section
class BackendToolsWidget extends StatelessWidget {
  final List<ToolSection> sections;
  final Color? accentColor;
  final double transparency;

  const BackendToolsWidget({
    super.key,
    required this.sections,
    this.accentColor,
    this.transparency = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: sections.asMap().entries.map((entry) {
        return _buildToolSection(context, entry.value, entry.key);
      }).toList(),
    );
  }

  Widget _buildToolSection(BuildContext context, ToolSection section, int index) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, size: 14, color: gxRed),
              const SizedBox(width: 8),
              Text(
                '// ${section.name}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: gxRed.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: section.tools.map((tool) => _buildToolChip(context, tool)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolChip(BuildContext context, BackendTool tool) {
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
                width: 6,
                height: 6,
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

