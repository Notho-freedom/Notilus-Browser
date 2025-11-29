/// Panneau Performance du DevTools natif Notilus
/// Utilise la couleur secondaire du thème
library devtools_performance_panel;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/devtools_models.dart';
import '../../services/devtools_service.dart';
import '../../core/services/color_theme_manager.dart';

class DevToolsPerformancePanel extends StatefulWidget {
  const DevToolsPerformancePanel({super.key});

  @override
  State<DevToolsPerformancePanel> createState() =>
      _DevToolsPerformancePanelState();
}

class _DevToolsPerformancePanelState extends State<DevToolsPerformancePanel> {
  bool _isLoading = false;
  Timer? _refreshTimer;
  bool _autoRefresh = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    final devTools = context.read<DevToolsService>();
    await devTools.fetchPerformanceMetrics();

    setState(() => _isLoading = false);
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
      if (_autoRefresh) {
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 2),
          (_) => _loadMetrics(),
        );
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        final metrics = devTools.performanceMetrics;

        return Container(
          color: const Color(0xFF0D0D12),
          child: Column(
            children: [
              _buildToolbar(accentColor),
              Expanded(
                child: _isLoading && metrics == null
                    ? _buildLoadingState(accentColor)
                    : metrics == null
                        ? _buildEmptyState(accentColor)
                        : _buildMetricsContent(metrics, accentColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(Color accentColor) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.refresh,
            tooltip: 'Actualiser les métriques',
            accentColor: accentColor,
            onPressed: _loadMetrics,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: _autoRefresh ? Icons.pause : Icons.play_arrow,
            tooltip: _autoRefresh
                ? 'Arrêter l\'actualisation auto'
                : 'Actualisation automatique',
            isActive: _autoRefresh,
            accentColor: accentColor,
            onPressed: _toggleAutoRefresh,
          ),
          const Spacer(),
          if (_isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement des métriques...',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            'Aucune métrique disponible',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadMetrics,
            icon: Icon(Icons.refresh, size: 16, color: accentColor),
            label: Text(
              'Charger les métriques',
              style: TextStyle(color: accentColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsContent(PerformanceMetrics metrics, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Core Web Vitals', accentColor: accentColor),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                title: 'First Contentful Paint',
                subtitle: 'FCP',
                value: metrics.formatMs(metrics.firstContentfulPaint),
                icon: Icons.brush_outlined,
                color: _getVitalColor(metrics.firstContentfulPaint, good: 1800, needsImprovement: 3000),
                description: 'Temps jusqu\'au premier contenu visible',
              ),
              _MetricCard(
                title: 'Largest Contentful Paint',
                subtitle: 'LCP',
                value: metrics.formatMs(metrics.largestContentfulPaint),
                icon: Icons.image_outlined,
                color: _getVitalColor(metrics.largestContentfulPaint, good: 2500, needsImprovement: 4000),
                description: 'Temps jusqu\'au plus grand élément visible',
              ),
              _MetricCard(
                title: 'First Paint',
                subtitle: 'FP',
                value: metrics.formatMs(metrics.firstPaint),
                icon: Icons.palette_outlined,
                color: _getVitalColor(metrics.firstPaint, good: 1000, needsImprovement: 2500),
                description: 'Temps jusqu\'au premier pixel peint',
              ),
            ],
          ),

          const SizedBox(height: 24),
          _SectionTitle('Page Timing', accentColor: accentColor),
          const SizedBox(height: 12),
          _TimingBar(metrics: metrics, accentColor: accentColor),

          const SizedBox(height: 24),
          _SectionTitle('Ressources', accentColor: accentColor),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResourceCard(
                  title: 'DOM Nodes',
                  value: metrics.domNodes?.toString() ?? '-',
                  icon: Icons.account_tree_outlined,
                  color: _getResourceColor(metrics.domNodes, warning: 1500, danger: 3000),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResourceCard(
                  title: 'Resources',
                  value: metrics.resources?.toString() ?? '-',
                  icon: Icons.folder_outlined,
                  color: _getResourceColor(metrics.resources, warning: 100, danger: 200),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResourceCard(
                  title: 'Transfer Size',
                  value: metrics.transferSize != null
                      ? metrics.formatBytes(metrics.transferSize!.round())
                      : '-',
                  icon: Icons.download_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _SectionTitle('Mémoire JavaScript', accentColor: accentColor),
          const SizedBox(height: 12),
          _MemoryBar(metrics: metrics),

          const SizedBox(height: 24),
          _SectionTitle('Détails du chargement', accentColor: accentColor),
          const SizedBox(height: 12),
          _DetailedTimingList(metrics: metrics),
        ],
      ),
    );
  }

  Color _getVitalColor(double? value, {required double good, required double needsImprovement}) {
    if (value == null) return Colors.grey;
    if (value <= good) return const Color(0xFF4CAF50);
    if (value <= needsImprovement) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getResourceColor(int? value, {required int warning, required int danger}) {
    if (value == null) return Colors.grey;
    if (value <= warning) return const Color(0xFF4CAF50);
    if (value <= danger) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color accentColor;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.accentColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? accentColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? accentColor : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _SectionTitle(this.title, {required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: accentColor,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final String description;

  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color, fontFamily: 'JetBrains Mono'),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ResourceCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, fontFamily: 'JetBrains Mono')),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _TimingBar extends StatelessWidget {
  final PerformanceMetrics metrics;
  final Color accentColor;

  const _TimingBar({required this.metrics, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final pageLoad = metrics.pageLoadTime ?? 0;
    final domContent = metrics.domContentLoaded ?? 0;
    final interactive = metrics.timeToInteractive ?? 0;

    final maxTime = [pageLoad, domContent, interactive, 5000.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _TimingRow(label: 'DOM Content Loaded', value: metrics.formatMs(domContent), progress: domContent / maxTime, color: const Color(0xFF64B5F6)),
          const SizedBox(height: 12),
          _TimingRow(label: 'Time to Interactive', value: metrics.formatMs(interactive), progress: interactive / maxTime, color: const Color(0xFF81C784)),
          const SizedBox(height: 12),
          _TimingRow(label: 'Page Load', value: metrics.formatMs(pageLoad), progress: pageLoad / maxTime, color: accentColor),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _TimingRow({required this.label, required this.value, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'JetBrains Mono')),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemoryBar extends StatelessWidget {
  final PerformanceMetrics metrics;

  const _MemoryBar({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final used = metrics.usedJsHeapSize ?? 0;
    final total = metrics.jsHeapSize ?? 1;
    final percentage = total > 0 ? (used / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('JS Heap Used', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
              Text(
                '${metrics.formatBytes(used)} / ${metrics.formatBytes(total)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'JetBrains Mono'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 20,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: (percentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_getMemoryColor(percentage).withOpacity(0.7), _getMemoryColor(percentage)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Center(
                  child: Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMemoryColor(double percentage) {
    if (percentage < 50) return const Color(0xFF4CAF50);
    if (percentage < 80) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

class _DetailedTimingList extends StatelessWidget {
  final PerformanceMetrics metrics;

  const _DetailedTimingList({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _DetailRow('Page Load Time', metrics.formatMs(metrics.pageLoadTime)),
          _DetailRow('DOM Content Loaded', metrics.formatMs(metrics.domContentLoaded)),
          _DetailRow('First Paint', metrics.formatMs(metrics.firstPaint)),
          _DetailRow('First Contentful Paint', metrics.formatMs(metrics.firstContentfulPaint)),
          _DetailRow('Time to Interactive', metrics.formatMs(metrics.timeToInteractive)),
          _DetailRow('Total Blocking Time', metrics.formatMs(metrics.totalBlockingTime)),
          _DetailRow('Cumulative Layout Shift', metrics.cumulativeLayoutShift?.toStringAsFixed(3) ?? '-'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'JetBrains Mono')),
        ],
      ),
    );
  }
}
