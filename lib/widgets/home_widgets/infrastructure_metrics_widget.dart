/// Widget autonome pour afficher les métriques d'infrastructure
library infrastructure_metrics_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/system_metrics_service.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour une métrique d'infrastructure
class InfrastructureMetric {
  final String label;
  final String value;
  final IconData icon;

  const InfrastructureMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// Widget autonome pour afficher les métriques d'infrastructure
class InfrastructureMetricsWidget extends StatefulWidget {
  final Color? accentColor;
  final double transparency;
  final List<InfrastructureMetric>? customMetrics;

  const InfrastructureMetricsWidget({
    super.key,
    this.accentColor,
    this.transparency = 0.0,
    this.customMetrics,
  });

  @override
  State<InfrastructureMetricsWidget> createState() => _InfrastructureMetricsWidgetState();
}

class _InfrastructureMetricsWidgetState extends State<InfrastructureMetricsWidget> {
  late SystemMetricsService _metricsService;

  @override
  void initState() {
    super.initState();
    _metricsService = SystemMetricsService();
    _metricsService.addListener(_onMetricsUpdate);
  }

  @override
  void dispose() {
    _metricsService.removeListener(_onMetricsUpdate);
    super.dispose();
  }

  void _onMetricsUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = widget.accentColor ?? colorTheme.nativeSecondaryColor;
    
    final metrics = widget.customMetrics ?? [
      InfrastructureMetric(
        label: 'CPU Usage',
        value: '${_metricsService.cpuUsage.toInt()}%',
        icon: CupertinoIcons.gauge,
      ),
      InfrastructureMetric(
        label: 'Memory',
        value: '${_metricsService.ramUsage.toInt()}%',
        icon: Icons.memory,
      ),
      InfrastructureMetric(
        label: 'Network I/O',
        value: _metricsService.networkStatus,
        icon: CupertinoIcons.arrow_up_arrow_down,
      ),
      InfrastructureMetric(
        label: 'Pods Active',
        value: '47/50',
        icon: CupertinoIcons.cube_box,
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFRASTRUCTURE METRICS',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: accentColor.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: metrics.asMap().entries.map((entry) {
            if (entry.key > 0) {
              return Row(
                children: [
                  const SizedBox(width: 12),
                  _buildMetricCard(entry.value, entry.key),
                ],
              );
            }
            return _buildMetricCard(entry.value, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard(InfrastructureMetric metric, int index) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = widget.accentColor ?? colorTheme.nativeSecondaryColor;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity((1 - widget.transparency).clamp(0.0, 1.0)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metric.icon, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  metric.label,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              metric.value,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

