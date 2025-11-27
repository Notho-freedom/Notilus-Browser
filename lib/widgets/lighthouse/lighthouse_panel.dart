/// Panneau principal Notilus Lighthouse
/// Analyse des performances et audit complet d'une page web
library lighthouse_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/lighthouse/lighthouse_service.dart';
import '../../services/lighthouse/report_generator.dart';
import '../../services/lighthouse/audit_history_service.dart';
import '../../models/lighthouse/audit_models.dart';
import '../../core/services/color_theme_manager.dart';
import 'package:flutter/services.dart';
import 'history_trends_panel.dart';
import 'ai_advisor_panel.dart';
import '../../core/animations/lighthouse_animations.dart';

/// Panneau principal Lighthouse
class LighthousePanel extends StatefulWidget {
  const LighthousePanel({super.key});

  @override
  State<LighthousePanel> createState() => _LighthousePanelState();
}

class _LighthousePanelState extends State<LighthousePanel>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<LighthouseService>(
      builder: (context, lighthouse, _) {
        return Column(
          children: [
            // Header with controls
            _buildHeader(lighthouse, accentColor),
            // Content
            Expanded(
              child: lighthouse.isRunning
                  ? _buildRunningState(lighthouse, accentColor)
                  : lighthouse.lastResult != null
                      ? _buildResultsContent(lighthouse, accentColor)
                      : _buildEmptyState(lighthouse, accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(LighthouseService lighthouse, Color accentColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tab selector
                if (lighthouse.lastResult != null) ...[
                  if (!isCompact) ...[
                    _TabButton(
                      label: 'Vue d\'ensemble',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _TabButton(
                    label: isCompact ? 'Problèmes' : 'Problèmes',
                    isSelected: _selectedTab == 1,
                    count: lighthouse.lastResult?.issueCount ?? 0,
                    onTap: () => setState(() => _selectedTab = 1),
                    accentColor: accentColor,
                    compact: isCompact,
                  ),
                  const SizedBox(width: 8),
                  if (!isCompact) ...[
                    _TabButton(
                      label: 'Recommandations',
                      isSelected: _selectedTab == 2,
                      onTap: () => setState(() => _selectedTab = 2),
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _TabButton(
                    label: isCompact ? 'Hist.' : 'Historique',
                    isSelected: _selectedTab == 3,
                    onTap: () => setState(() => _selectedTab = 3),
                    accentColor: accentColor,
                    compact: isCompact,
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: isCompact ? 'AI' : 'AI Advisor',
                    isSelected: _selectedTab == 4,
                    onTap: () => setState(() => _selectedTab = 4),
                    accentColor: accentColor,
                    compact: isCompact,
                  ),
                  const SizedBox(width: 12),
                ],
                // Export button
                if (lighthouse.lastResult != null) ...[
                  PopupMenuButton<ReportFormat>(
                    icon: Icon(CupertinoIcons.arrow_up_doc, size: 18, color: accentColor),
                    tooltip: 'Exporter le rapport',
                    onSelected: (format) => _exportReport(context, lighthouse.lastResult!, format, accentColor),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: ReportFormat.html,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.doc_text, size: 16, color: accentColor),
                            const SizedBox(width: 8),
                            const Text('HTML'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportFormat.json,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.doc, size: 16, color: accentColor),
                            const SizedBox(width: 8),
                            const Text('JSON'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportFormat.csv,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.table, size: 16, color: accentColor),
                            const SizedBox(width: 8),
                            const Text('CSV'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportFormat.markdown,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.textformat, size: 16, color: accentColor),
                            const SizedBox(width: 8),
                            const Text('Markdown'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                // Run button
                ElevatedButton.icon(
                  onPressed: lighthouse.isRunning ? null : lighthouse.runFullAudit,
                  icon: lighthouse.isRunning
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        )
                      : const Icon(CupertinoIcons.play_fill, size: 14),
                  label: Text(lighthouse.isRunning ? 'Analyse...' : isCompact ? 'Analyser' : 'Analyser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(LighthouseService lighthouse, Color accentColor) {
    return LighthouseSlideUp(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LighthousePulse(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.1),
                ),
                child: Icon(
                  CupertinoIcons.gauge,
                  size: 48,
                  color: accentColor.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LighthouseFadeIn(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Analysez votre page',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            LighthouseFadeIn(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'Lancez un audit complet pour obtenir un rapport détaillé\ndes performances, accessibilité, SEO et sécurité',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 32),
            LighthouseFadeIn(
              delay: const Duration(milliseconds: 400),
              child: ElevatedButton.icon(
                onPressed: lighthouse.runFullAudit,
                icon: const Icon(CupertinoIcons.play_fill),
                label: const Text('Lancer l\'analyse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LighthouseFadeIn(
              delay: const Duration(milliseconds: 500),
              child: Text(
                'Raccourci: Ctrl+Shift+R',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningState(LighthouseService lighthouse, Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated gauge
          LighthouseFadeIn(
            child: _AnimatedGauge(
              progress: lighthouse.progress,
              accentColor: accentColor,
            ),
          ),
          const SizedBox(height: 32),
          LighthouseFadeIn(
            delay: const Duration(milliseconds: 100),
            child: LighthouseRotatingIcon(
              icon: CupertinoIcons.arrow_2_circlepath,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          LighthouseFadeIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              lighthouse.currentStep ?? 'Initialisation...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LighthouseFadeIn(
            delay: const Duration(milliseconds: 300),
            child: Text(
              '${(lighthouse.progress * 100).round()}% complété',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          LighthouseFadeIn(
            delay: const Duration(milliseconds: 400),
            child: TextButton.icon(
              onPressed: lighthouse.cancelAudit,
              icon: const Icon(CupertinoIcons.xmark, size: 14),
              label: const Text('Annuler'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent(LighthouseService lighthouse, Color accentColor) {
    final result = lighthouse.lastResult!;

    switch (_selectedTab) {
      case 0:
        return _OverviewTab(result: result, accentColor: accentColor);
      case 1:
        return _IssuesTab(result: result, accentColor: accentColor);
      case 2:
        return _RecommendationsTab(result: result, accentColor: accentColor);
      case 3:
        return const HistoryTrendsPanel();
      case 4:
        return const AIAdvisorPanel();
      default:
        return const SizedBox();
    }
  }

  Future<void> _exportReport(
    BuildContext context,
    AuditResult result,
    ReportFormat format,
    Color accentColor,
  ) async {
    try {
      final filePath = await ReportGenerator.saveReport(result, format);
      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport exporté: ${filePath.split('/').last}'),
            backgroundColor: accentColor,
            action: SnackBarAction(
              label: 'Copier le chemin',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Chemin copié'), backgroundColor: accentColor),
                );
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de l\'export'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// =====================================================
// Sub-widgets
// =====================================================

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? count;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool compact;

  const _TabButton({
    required this.label,
    required this.isSelected,
    this.count,
    this.onTap,
    required this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? accentColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.6),
                fontSize: compact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: count! > 5 ? Colors.red : accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedGauge extends StatefulWidget {
  final double progress;
  final Color accentColor;

  const _AnimatedGauge({required this.progress, required this.accentColor});

  @override
  State<_AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<_AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring rotating
            Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      widget.accentColor.withOpacity(0),
                      widget.accentColor.withOpacity(0.3),
                      widget.accentColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            // Progress ring
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: widget.progress,
                strokeWidth: 6,
                backgroundColor: Colors.white.withOpacity(0.1),
                color: widget.accentColor,
              ),
            ),
            // Center icon
            Icon(
              CupertinoIcons.gauge,
              size: 36,
              color: widget.accentColor,
            ),
          ],
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final AuditResult result;
  final Color accentColor;

  const _OverviewTab({required this.result, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isVeryCompact = constraints.maxWidth < 400;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score cards
              isVeryCompact
                  ? Column(
                      children: [
                        _ScoreCard(
                          label: 'Performance',
                          score: result.performanceScore,
                          icon: CupertinoIcons.speedometer,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 12),
                        _ScoreCard(
                          label: 'Accessibilité',
                          score: result.accessibilityScore,
                          icon: CupertinoIcons.person_2,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 12),
                        _ScoreCard(
                          label: 'SEO',
                          score: result.seoScore,
                          icon: CupertinoIcons.search,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 12),
                        _ScoreCard(
                          label: 'Sécurité',
                          score: result.securityScore,
                          icon: CupertinoIcons.shield,
                          accentColor: accentColor,
                        ),
                      ],
                    )
                  : isCompact
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _ScoreCard(
                                label: 'Performance',
                                score: result.performanceScore,
                                icon: CupertinoIcons.speedometer,
                                accentColor: accentColor,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _ScoreCard(
                                label: 'Accessibilité',
                                score: result.accessibilityScore,
                                icon: CupertinoIcons.person_2,
                                accentColor: accentColor,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _ScoreCard(
                                label: 'SEO',
                                score: result.seoScore,
                                icon: CupertinoIcons.search,
                                accentColor: accentColor,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _ScoreCard(
                                label: 'Sécurité',
                                score: result.securityScore,
                                icon: CupertinoIcons.shield,
                                accentColor: accentColor,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _ScoreCard(
                                label: 'Performance',
                                score: result.performanceScore,
                                icon: CupertinoIcons.speedometer,
                                accentColor: accentColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ScoreCard(
                                label: 'Accessibilité',
                                score: result.accessibilityScore,
                                icon: CupertinoIcons.person_2,
                                accentColor: accentColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ScoreCard(
                                label: 'SEO',
                                score: result.seoScore,
                                icon: CupertinoIcons.search,
                                accentColor: accentColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ScoreCard(
                                label: 'Sécurité',
                                score: result.securityScore,
                                icon: CupertinoIcons.shield,
                                accentColor: accentColor,
                              ),
                            ),
                          ],
                        ),
              const SizedBox(height: 32),
              // Core Web Vitals
              Text(
                'CORE WEB VITALS',
                style: TextStyle(
                  color: accentColor.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              if (result.metrics != null) _buildWebVitals(result.metrics!, constraints.maxWidth),
              const SizedBox(height: 32),
              // Quick stats
              Text(
                'RÉSUMÉ',
                style: TextStyle(
                  color: accentColor.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              isCompact
                  ? Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _QuickStat(
                          icon: CupertinoIcons.exclamationmark_triangle,
                          label: 'Problèmes',
                          value: result.issueCount.toString(),
                          color: result.issueCount > 0 ? Colors.red : Colors.green,
                        ),
                        _QuickStat(
                          icon: CupertinoIcons.lightbulb,
                          label: 'Recommandations',
                          value: result.recommendationCount.toString(),
                          color: accentColor,
                        ),
                        _QuickStat(
                          icon: CupertinoIcons.clock,
                          label: 'Durée',
                          value: '${result.duration.inSeconds}s',
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _QuickStat(
                          icon: CupertinoIcons.exclamationmark_triangle,
                          label: 'Problèmes',
                          value: result.issueCount.toString(),
                          color: result.issueCount > 0 ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 24),
                        _QuickStat(
                          icon: CupertinoIcons.lightbulb,
                          label: 'Recommandations',
                          value: result.recommendationCount.toString(),
                          color: accentColor,
                        ),
                        const SizedBox(width: 24),
                        _QuickStat(
                          icon: CupertinoIcons.clock,
                          label: 'Durée d\'analyse',
                          value: '${result.duration.inSeconds}s',
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebVitals(PerformanceMetrics metrics, double maxWidth) {
    final isCompact = maxWidth < 600;
    final isVeryCompact = maxWidth < 400;
    
    if (isVeryCompact) {
      return Column(
        children: [
          _WebVitalCard(
            label: 'LCP',
            fullName: 'Largest Contentful Paint',
            value: metrics.formattedLCP,
            status: metrics.lcpStatus,
          ),
          const SizedBox(height: 12),
          _WebVitalCard(
            label: 'FID',
            fullName: 'First Input Delay',
            value: metrics.formattedFID,
            status: metrics.fidStatus,
          ),
          const SizedBox(height: 12),
          _WebVitalCard(
            label: 'CLS',
            fullName: 'Cumulative Layout Shift',
            value: metrics.formattedCLS,
            status: metrics.clsStatus,
          ),
          const SizedBox(height: 12),
          _WebVitalCard(
            label: 'TTFB',
            fullName: 'Time to First Byte',
            value: metrics.formattedTTFB,
            status: metrics.ttfbStatus,
          ),
          const SizedBox(height: 12),
          _WebVitalCard(
            label: 'TTI',
            fullName: 'Time to Interactive',
            value: metrics.formattedTTI,
            status: metrics.ttiStatus,
          ),
        ],
      );
    } else if (isCompact) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: (maxWidth - 12) / 2,
            child: _WebVitalCard(
              label: 'LCP',
              fullName: 'Largest Contentful Paint',
              value: metrics.formattedLCP,
              status: metrics.lcpStatus,
            ),
          ),
          SizedBox(
            width: (maxWidth - 12) / 2,
            child: _WebVitalCard(
              label: 'FID',
              fullName: 'First Input Delay',
              value: metrics.formattedFID,
              status: metrics.fidStatus,
            ),
          ),
          SizedBox(
            width: (maxWidth - 12) / 2,
            child: _WebVitalCard(
              label: 'CLS',
              fullName: 'Cumulative Layout Shift',
              value: metrics.formattedCLS,
              status: metrics.clsStatus,
            ),
          ),
          SizedBox(
            width: (maxWidth - 12) / 2,
            child: _WebVitalCard(
              label: 'TTFB',
              fullName: 'Time to First Byte',
              value: metrics.formattedTTFB,
              status: metrics.ttfbStatus,
            ),
          ),
          SizedBox(
            width: (maxWidth - 12) / 2,
            child: _WebVitalCard(
              label: 'TTI',
              fullName: 'Time to Interactive',
              value: metrics.formattedTTI,
              status: metrics.ttiStatus,
            ),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _WebVitalCard(
              label: 'LCP',
              fullName: 'Largest Contentful Paint',
              value: metrics.formattedLCP,
              status: metrics.lcpStatus,
            ),
            const SizedBox(width: 12),
            _WebVitalCard(
              label: 'FID',
              fullName: 'First Input Delay',
              value: metrics.formattedFID,
              status: metrics.fidStatus,
            ),
            const SizedBox(width: 12),
            _WebVitalCard(
              label: 'CLS',
              fullName: 'Cumulative Layout Shift',
              value: metrics.formattedCLS,
              status: metrics.clsStatus,
            ),
            const SizedBox(width: 12),
            _WebVitalCard(
              label: 'TTFB',
              fullName: 'Time to First Byte',
              value: metrics.formattedTTFB,
              status: metrics.ttfbStatus,
            ),
            const SizedBox(width: 12),
            _WebVitalCard(
              label: 'TTI',
              fullName: 'Time to Interactive',
              value: metrics.formattedTTI,
              status: metrics.ttiStatus,
            ),
          ],
        ),
      );
    }
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;
  final Color accentColor;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.icon,
    required this.accentColor,
  });

  Color get _scoreColor {
    if (score >= 90) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: _scoreColor,
                ),
              ),
              Text(
                score.toString(),
                style: TextStyle(
                  color: _scoreColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebVitalCard extends StatelessWidget {
  final String label;
  final String fullName;
  final String value;
  final MetricStatus status;

  const _WebVitalCard({
    required this.label,
    required this.fullName,
    required this.value,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case MetricStatus.good:
        return Colors.green;
      case MetricStatus.needsImprovement:
        return Colors.orange;
      case MetricStatus.poor:
        return Colors.red;
      case MetricStatus.unknown:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case MetricStatus.good:
        return CupertinoIcons.checkmark_circle_fill;
      case MetricStatus.needsImprovement:
        return CupertinoIcons.exclamationmark_circle_fill;
      case MetricStatus.poor:
        return CupertinoIcons.xmark_circle_fill;
      case MetricStatus.unknown:
        return CupertinoIcons.question_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, size: 14, color: _statusColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fullName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IssuesTab extends StatelessWidget {
  final AuditResult result;
  final Color accentColor;

  const _IssuesTab({required this.result, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final issues = result.issues;

    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 48,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun problème détecté',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre page ne présente aucun problème majeur',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return _IssueCard(issue: issue, accentColor: accentColor);
      },
    );
  }
}

class _IssueCard extends StatefulWidget {
  final Issue issue;
  final Color accentColor;

  const _IssueCard({required this.issue, required this.accentColor});

  @override
  State<_IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<_IssueCard> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.issue.severity) {
      case IssueSeverity.critical:
        return Colors.red;
      case IssueSeverity.high:
        return Colors.orange;
      case IssueSeverity.medium:
      case IssueSeverity.warning:
        return Colors.yellow;
      case IssueSeverity.low:
        return Colors.blue;
      case IssueSeverity.info:
        return Colors.grey;
      case IssueSeverity.passed:
        return Colors.green;
    }
  }

  IconData get _categoryIcon {
    switch (widget.issue.category) {
      case AuditCategory.performance:
        return CupertinoIcons.speedometer;
      case AuditCategory.accessibility:
        return CupertinoIcons.person_2;
      case AuditCategory.seo:
        return CupertinoIcons.search;
      case AuditCategory.security:
        return CupertinoIcons.shield;
      case AuditCategory.bestPractices:
      case AuditCategory.pwa:
      case AuditCategory.carbon:
        return CupertinoIcons.checkmark_seal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _expanded ? widget.accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Severity indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _severityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(_categoryIcon, size: 14, color: widget.accentColor),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.issue.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.issue.category.displayName} • ${widget.issue.severity.displayName}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand icon
                  Icon(
                    _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 14,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
          // Details
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),
                  Text(
                    widget.issue.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (widget.issue.element != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.issue.element!,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: widget.accentColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                  if (widget.issue.suggestion != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb,
                          size: 14,
                          color: Colors.green.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.issue.suggestion!,
                            style: TextStyle(
                              color: Colors.green.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationsTab extends StatelessWidget {
  final AuditResult result;
  final Color accentColor;

  const _RecommendationsTab({required this.result, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final recommendations = result.recommendations;

    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.star_fill,
              size: 48,
              color: Colors.yellow.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Parfait !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune recommandation supplémentaire',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final rec = recommendations[index];
        return _RecommendationCard(recommendation: rec, accentColor: accentColor);
      },
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final Recommendation recommendation;
  final Color accentColor;

  const _RecommendationCard({required this.recommendation, required this.accentColor});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;

  Color get _impactColor {
    switch (widget.recommendation.impact) {
      case ImpactLevel.high:
        return Colors.green;
      case ImpactLevel.medium:
        return Colors.orange;
      case ImpactLevel.low:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _expanded ? widget.accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Impact indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _impactColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _impactColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.recommendation.impact.displayName,
                      style: TextStyle(
                        color: _impactColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recommendation.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        if (widget.recommendation.estimatedSavings != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Économie potentielle: ${widget.recommendation.estimatedSavings}',
                            style: TextStyle(
                              color: Colors.green.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Expand icon
                  Icon(
                    _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 14,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
          // Details
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 16),
                  Text(
                    widget.recommendation.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (widget.recommendation.steps.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'ÉTAPES À SUIVRE',
                      style: TextStyle(
                        color: widget.accentColor.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.recommendation.steps.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: widget.accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (widget.recommendation.codeExample != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.recommendation.codeExample!,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: widget.accentColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

