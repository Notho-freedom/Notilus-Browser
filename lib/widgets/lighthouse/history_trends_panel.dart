/// Panneau History & Trends pour Notilus Lighthouse
/// Affiche l'historique des audits avec graphiques et détection de régressions
library history_trends_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/lighthouse/lighthouse_service.dart';
import '../../services/lighthouse/audit_history_service.dart';
import '../../models/lighthouse/audit_models.dart';
import '../../core/services/color_theme_manager.dart';

/// Panneau History & Trends
class HistoryTrendsPanel extends StatefulWidget {
  const HistoryTrendsPanel({super.key});

  @override
  State<HistoryTrendsPanel> createState() => _HistoryTrendsPanelState();
}

class _HistoryTrendsPanelState extends State<HistoryTrendsPanel> {
  String? _selectedUrl;
  int _selectedMetric = 0; // 0: Score, 1: LCP, 2: CLS, 3: Issues

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<LighthouseService>(
      builder: (context, lighthouse, _) {
        final historyService = lighthouse.historyService;
        final urls = _getUniqueUrls(historyService.history);
        final selectedUrl = _selectedUrl ?? (urls.isNotEmpty ? urls.first : null);

        return Row(
          children: [
            // Sidebar avec liste des URLs
            Container(
              width: 250,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: _buildUrlList(historyService, urls, selectedUrl, accentColor),
            ),
            // Contenu principal
            Expanded(
              child: selectedUrl != null
                  ? _buildMainContent(historyService, selectedUrl, accentColor)
                  : _buildEmptyState(accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUrlList(
    AuditHistoryService historyService,
    List<String> urls,
    String? selectedUrl,
    Color accentColor,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.clock, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Historique',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (historyService.history.isNotEmpty)
                IconButton(
                  icon: Icon(CupertinoIcons.trash, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: () => _showClearHistoryDialog(historyService),
                  tooltip: 'Effacer l\'historique',
                ),
            ],
          ),
        ),
        // URL list
        Expanded(
          child: urls.isEmpty
              ? Center(
                  child: Text(
                    'Aucun historique',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: urls.length,
                  itemBuilder: (context, index) {
                    final url = urls[index];
                    final urlHistory = historyService.getHistoryForUrl(url);
                    final isSelected = url == selectedUrl;

                    return InkWell(
                      onTap: () => setState(() => _selectedUrl = url),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withOpacity(0.1)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? accentColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatUrl(url),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.chart_bar,
                                  size: 10,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${urlHistory.length} audit${urlHistory.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 10,
                                  ),
                                ),
                                const Spacer(),
                                if (urlHistory.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(urlHistory.first.score)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${urlHistory.first.score}',
                                      style: TextStyle(
                                        color: _getScoreColor(urlHistory.first.score),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMainContent(
    AuditHistoryService historyService,
    String url,
    Color accentColor,
  ) {
    final urlHistory = historyService.getHistoryForUrl(url);
    final regressions = historyService.detectRegressions(url);
    final trendStats = historyService.getTrendStats(url);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec stats
          _buildStatsHeader(trendStats, urlHistory.length, accentColor),
          const SizedBox(height: 24),
          // Metric selector
          _buildMetricSelector(accentColor),
          const SizedBox(height: 24),
          // Graphique
          _buildChart(urlHistory, accentColor),
          const SizedBox(height: 24),
          // Régressions
          if (regressions.isNotEmpty) ...[
            _buildRegressionsSection(regressions, accentColor),
            const SizedBox(height: 24),
          ],
          // Tableau d'historique
          _buildHistoryTable(urlHistory, accentColor),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(TrendStats stats, int totalAudits, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Audits totaux',
              value: '$totalAudits',
              icon: CupertinoIcons.chart_bar,
              color: accentColor,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: _StatCard(
              label: 'Score moyen',
              value: '${stats.averageScore}',
              icon: CupertinoIcons.star,
              color: accentColor,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: _StatCard(
              label: 'Tendance score',
              value: _formatTrend(stats.scoreTrend),
              icon: _getTrendIcon(stats.scoreTrend),
              color: _getTrendColor(stats.scoreTrend),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector(Color accentColor) {
    final metrics = ['Score', 'LCP', 'CLS', 'Issues'];

    return Row(
      children: metrics.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = _selectedMetric == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < metrics.length - 1 ? 8 : 0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedMetric = index),
              selectedColor: accentColor.withOpacity(0.2),
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(List<AuditHistoryEntry> history, Color accentColor) {
    if (history.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            'Aucune donnée à afficher',
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: CustomPaint(
        painter: _ChartPainter(
          history: history,
          metric: _selectedMetric,
          accentColor: accentColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildRegressionsSection(
    List<Regression> regressions,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'RÉGRESSIONS DÉTECTÉES (${regressions.length})',
              style: TextStyle(
                color: Colors.red.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...regressions.map((regression) => _RegressionCard(
              regression: regression,
              accentColor: accentColor,
            )),
      ],
    );
  }

  Widget _buildHistoryTable(List<AuditHistoryEntry> history, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HISTORIQUE COMPLET',
          style: TextStyle(
            color: accentColor.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF15151E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                children: [
                  _TableHeaderCell('Date', accentColor),
                  _TableHeaderCell('Score', accentColor),
                  _TableHeaderCell('LCP', accentColor),
                  _TableHeaderCell('CLS', accentColor),
                  _TableHeaderCell('Issues', accentColor),
                ],
              ),
              // Rows
              ...history.map((entry) => TableRow(
                    children: [
                      _TableDataCell(
                        _formatDate(entry.timestamp),
                        Colors.white.withOpacity(0.7),
                      ),
                      _TableDataCell(
                        '${entry.score}',
                        _getScoreColor(entry.score),
                      ),
                      _TableDataCell(
                        entry.webVitals.lcp != null
                            ? '${entry.webVitals.lcp!.toStringAsFixed(0)}ms'
                            : '-',
                        Colors.white.withOpacity(0.6),
                      ),
                      _TableDataCell(
                        entry.webVitals.cls != null
                            ? entry.webVitals.cls!.toStringAsFixed(3)
                            : '-',
                        Colors.white.withOpacity(0.6),
                      ),
                      _TableDataCell(
                        '${entry.issueCount}',
                        Colors.white.withOpacity(0.6),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            size: 48,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun historique disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lancez des audits pour voir l\'historique',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueUrls(List<AuditHistoryEntry> history) {
    return history.map((e) => e.url).toSet().toList()..sort();
  }

  String _formatUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.host}${uri.path}';
    } catch (_) {
      return url.length > 40 ? '${url.substring(0, 40)}...' : url;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTrend(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return 'Amélioration';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.degrading:
        return 'Dégradation';
    }
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return CupertinoIcons.arrow_up;
      case TrendDirection.stable:
        return CupertinoIcons.minus;
      case TrendDirection.degrading:
        return CupertinoIcons.arrow_down;
    }
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return Colors.green;
      case TrendDirection.stable:
        return Colors.orange;
      case TrendDirection.degrading:
        return Colors.red;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  Future<void> _showClearHistoryDialog(AuditHistoryService historyService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text(
          'Êtes-vous sûr de vouloir effacer tout l\'historique des audits ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await historyService.clearAllHistory();
    }
  }
}

// Widgets helpers

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _RegressionCard extends StatelessWidget {
  final Regression regression;
  final Color accentColor;

  const _RegressionCard({
    required this.regression,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getSeverityColor(regression.severity).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTypeIcon(regression.type),
            size: 16,
            color: _getSeverityColor(regression.severity),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  regression.description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(regression.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${regression.previousValue.toStringAsFixed(1)} → ${regression.currentValue.toStringAsFixed(1)}',
                style: TextStyle(
                  color: _getSeverityColor(regression.severity),
                  fontSize: 11,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              Text(
                _getSeverityLabel(regression.severity),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(RegressionType type) {
    switch (type) {
      case RegressionType.score:
        return CupertinoIcons.star;
      case RegressionType.lcp:
        return CupertinoIcons.time;
      case RegressionType.cls:
        return CupertinoIcons.arrow_up_arrow_down;
      case RegressionType.issues:
        return CupertinoIcons.exclamationmark_circle;
      default:
        return CupertinoIcons.circle;
    }
  }

  Color _getSeverityColor(RegressionSeverity severity) {
    switch (severity) {
      case RegressionSeverity.low:
        return Colors.orange;
      case RegressionSeverity.medium:
        return Colors.deepOrange;
      case RegressionSeverity.high:
        return Colors.red;
      case RegressionSeverity.critical:
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityLabel(RegressionSeverity severity) {
    switch (severity) {
      case RegressionSeverity.low:
        return 'Faible';
      case RegressionSeverity.medium:
        return 'Moyenne';
      case RegressionSeverity.high:
        return 'Élevée';
      case RegressionSeverity.critical:
        return 'Critique';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _TableHeaderCell(this.text, this.accentColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          color: accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TableDataCell extends StatelessWidget {
  final String text;
  final Color color;

  const _TableDataCell(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}

// Custom painter pour le graphique

class _ChartPainter extends CustomPainter {
  final List<AuditHistoryEntry> history;
  final int metric;
  final Color accentColor;

  _ChartPainter({
    required this.history,
    required this.metric,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Calculer les valeurs min/max
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (final entry in history) {
      double value = 0;
      switch (metric) {
        case 0:
          value = entry.score.toDouble();
          break;
        case 1:
          value = entry.webVitals.lcp ?? 0;
          break;
        case 2:
          value = entry.webVitals.cls ?? 0;
          break;
        case 3:
          value = entry.issueCount.toDouble();
          break;
      }

      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    // Ajuster les limites pour avoir un peu de marge
    final range = maxValue - minValue;
    minValue = minValue - range * 0.1;
    maxValue = maxValue + range * 0.1;

    // Dessiner les lignes de grille
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (var i = 0; i <= 5; i++) {
      final y = padding + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Dessiner la ligne de données
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < history.length; i++) {
      final entry = history[i];
      double value = 0;
      switch (metric) {
        case 0:
          value = entry.score.toDouble();
          break;
        case 1:
          value = entry.webVitals.lcp ?? 0;
          break;
        case 2:
          value = entry.webVitals.cls ?? 0;
          break;
        case 3:
          value = entry.issueCount.toDouble();
          break;
      }

      final x = padding + (chartWidth / (history.length - 1)) * i;
      final y = padding +
          chartHeight -
          ((value - minValue) / (maxValue - minValue)) * chartHeight;

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    // Dessiner les points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Dessiner les labels
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.5),
      fontSize: 10,
    );

    // Labels Y
    for (var i = 0; i <= 5; i++) {
      final value = minValue + (maxValue - minValue) * (1 - i / 5);
      final y = padding + (chartHeight / 5) * i;
      final textSpan = TextSpan(
        text: value.toStringAsFixed(metric == 0 ? 0 : 1),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.metric != metric;
  }
}

