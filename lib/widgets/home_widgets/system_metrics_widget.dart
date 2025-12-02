/// Widget autonome pour afficher les métriques système
library system_metrics_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/system_metrics_service.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour une métrique système
class SystemMetric {
  final String label;
  final String value;
  final double progress;

  const SystemMetric({
    required this.label,
    required this.value,
    required this.progress,
  });
}

/// Modèle pour une info système
class SystemInfo {
  final String label;
  final String value;

  const SystemInfo({
    required this.label,
    required this.value,
  });
}

/// Widget autonome pour afficher les métriques système
class SystemMetricsWidget extends StatefulWidget {
  final Color? accentColor;
  final double transparency;
  final List<SystemMetric>? customMetrics;
  final List<SystemInfo>? customInfos;

  const SystemMetricsWidget({
    super.key,
    this.accentColor,
    this.transparency = 0.0,
    this.customMetrics,
    this.customInfos,
  });

  @override
  State<SystemMetricsWidget> createState() => _SystemMetricsWidgetState();
}

class _SystemMetricsWidgetState extends State<SystemMetricsWidget> {
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
    final gxRed = widget.accentColor ?? colorTheme.nativeSecondaryColor;
    
    final metrics = widget.customMetrics ?? [
      SystemMetric(
        label: 'CPU',
        value: '${_metricsService.cpuUsage.toInt()}%',
        progress: _metricsService.cpuUsage / 100,
      ),
      SystemMetric(
        label: 'RAM',
        value: '${_metricsService.ramUsage.toInt()}%',
        progress: _metricsService.ramUsage / 100,
      ),
      SystemMetric(
        label: 'DISK',
        value: '67%',
        progress: 0.67,
      ),
      SystemMetric(
        label: 'NET',
        value: _metricsService.networkStatus,
        progress: 0.85,
      ),
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - widget.transparency * 0.5).clamp(0.0, 1.0)),
        border: Border(
          right: BorderSide(color: gxRed.withOpacity(0.15)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.gauge,
                  size: 14,
                  color: gxRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'SYSTEM METRICS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: gxRed,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...metrics.map((metric) => _buildMetricRow(metric, gxRed)),
                if (widget.customInfos != null && widget.customInfos!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ...widget.customInfos!.map((info) => _buildInfoRow(info, gxRed)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(SystemMetric metric, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              metric.label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              metric.value,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: metric.progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(SystemInfo info, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            info.label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Text(
            info.value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: accentColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

