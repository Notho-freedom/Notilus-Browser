/// Panel de widgets système futuriste Notilus GX
library gx_futuristic_widgets_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../../services/system_metrics_service.dart';
import '../../services/tab_manager.dart';
import '../common/gx_futuristic_components.dart';

class GxFuturisticWidgetsPanel extends StatelessWidget {
  const GxFuturisticWidgetsPanel({super.key});

  static Color _getUsageColor(double usage) {
    if (usage < 50) return const Color(0xFF22C55E);
    if (usage < 80) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static Color _getTempColor(double temp) {
    if (temp < 60) return const Color(0xFF22C55E);
    if (temp < 80) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    final wallpaperManager = context.watch<WallpaperManager>();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.layers_alt,
                    color: accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'WIDGETS SYSTÈME',
                    style: NotilusFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.3),
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
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: NotilusFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF22C55E),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Liste des widgets
            Expanded(
              child: Consumer<SystemMetricsService>(
                builder: (context, metrics, _) {
                  // Mettre à jour le nombre d'onglets sans déclencher de rebuild
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final tabManager = Provider.of<TabManager>(context, listen: false);
                    if (metrics.tabCount != tabManager.tabs.length) {
                      metrics.updateTabCount(tabManager.tabs.length);
                    }
                  });
                  
                  final widgets = [
                    _WidgetData('CPU', '${metrics.cpuUsage.toStringAsFixed(0)}%', 'Utilisation processeur', CupertinoIcons.gauge, _getUsageColor(metrics.cpuUsage)),
                    _WidgetData('RAM', '${metrics.ramUsage.toStringAsFixed(0)}%', 'Mémoire utilisée', Icons.memory, _getUsageColor(metrics.ramUsage)),
                    _WidgetData('GPU', '${metrics.gpuTemp.toStringAsFixed(0)}°C', 'Température graphique', CupertinoIcons.speedometer, _getTempColor(metrics.gpuTemp)),
                    _WidgetData('Réseau', metrics.networkStatus, 'État connexion', CupertinoIcons.waveform_path, const Color(0xFF22C55E)),
                    _WidgetData('Onglets', '${metrics.tabCount}', 'Onglets actifs', CupertinoIcons.square_grid_2x2, accentColor),
                    _WidgetData('Session', metrics.formatActiveTime(), 'Temps actif', CupertinoIcons.time, accentColor),
                    _WidgetData('Pages', '${metrics.pagesVisited}', 'Pages visitées', CupertinoIcons.doc_text, accentColor),
                    _WidgetData('Données', '${metrics.dataUsed.toStringAsFixed(2)} GB', 'Données transférées', CupertinoIcons.arrow_up_arrow_down, accentColor),
                  ];
                  
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: widgets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final widget = widgets[index];
                      return RepaintBoundary(
                        child: _SystemWidgetCard(
                          widget: widget,
                          accentColor: accentColor,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color valueColor;

  const _WidgetData(this.title, this.value, this.subtitle, this.icon, [this.valueColor = Colors.white]);
}

class _SystemWidgetCard extends StatelessWidget {
  final _WidgetData widget;
  final Color accentColor;

  const _SystemWidgetCard({
    required this.widget,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GxFuturisticCard(
      accentColor: widget.valueColor,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.valueColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.valueColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              widget.icon,
              color: widget.valueColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: NotilusFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: NotilusFonts.rajdhani(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GxFuturisticBadge(
            label: widget.value,
            color: widget.valueColor,
          ),
        ],
      ),
    );
  }
}

