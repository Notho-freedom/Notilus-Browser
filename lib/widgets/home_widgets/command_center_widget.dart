/// Widget autonome pour un centre de commande avec recherche
library command_center_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import '../../core/services/color_theme_manager.dart';
import 'search_bar_widget.dart';

/// Widget autonome pour un centre de commande avec recherche
class CommandCenterWidget extends StatelessWidget {
  final Color? accentColor;
  final double transparency;
  final String? greeting;
  final String? subtitle;

  const CommandCenterWidget({
    super.key,
    this.accentColor,
    this.transparency = 0.0,
    this.greeting,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    final settings = SettingsService();
    final customGreeting = settings.customGreeting;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting ?? (customGreeting.isNotEmpty ? customGreeting : '// Infrastructure Control'),
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle ?? 'Monitor, deploy, and scale your infrastructure',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        SearchBarWidget(
          accentColor: gxRed,
          transparency: transparency,
          hintText: 'Search resources, logs, or documentation...',
        ),
      ],
    );
  }
}

