import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/notilus_devtools_service.dart';
import '../../models/devtools_models.dart';

/// Onglet Sécurité pour l'audit des requêtes
class DevToolsSecurityTab extends StatelessWidget {
  const DevToolsSecurityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<NotilusDevToolsService>(
      builder: (context, devTools, _) {
        final issues = devTools.securityIssues;
        final activeIssues = issues.where((i) => !i.isResolved).toList();
        final resolvedIssues = issues.where((i) => i.isResolved).toList();

        return Column(
          children: [
            // Toolbar
            _buildToolbar(context, accentColor, devTools, activeIssues.length),

            // Security Score
            _buildSecurityScore(activeIssues, accentColor),

            // Issues list
            Expanded(
              child: activeIssues.isEmpty
                  ? _buildSecureState(accentColor)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: activeIssues.length,
                      itemBuilder: (context, index) {
                        final issue = activeIssues[index];
                        return _SecurityIssueCard(issue: issue, accentColor: accentColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, Color accentColor, NotilusDevToolsService devTools, int count) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Scanner status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: devTools.monitorConfig.securityScanEnabled
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  devTools.monitorConfig.securityScanEnabled
                      ? CupertinoIcons.shield_fill
                      : CupertinoIcons.shield_slash,
                  size: 12,
                  color: devTools.monitorConfig.securityScanEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  devTools.monitorConfig.securityScanEnabled ? 'Scanner actif' : 'Scanner inactif',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? const Color(0xFFFFB74D).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count problèmes',
              style: TextStyle(
                color: count > 0 ? const Color(0xFFFFB74D) : Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),

          const Spacer(),

          // Scan info
          Text(
            'Auto-scan réseau',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScore(List<SecurityIssue> issues, Color accentColor) {
    final criticalCount = issues.where((i) => i.severity == AlertSeverity.critical).length;
    final warningCount = issues.where((i) => i.severity == AlertSeverity.warning).length;
    
    // Score de 0 à 100
    int score = 100;
    score -= criticalCount * 20;
    score -= warningCount * 5;
    score = score.clamp(0, 100);

    Color scoreColor;
    String scoreLabel;
    if (score >= 90) {
      scoreColor = const Color(0xFF66BB6A);
      scoreLabel = 'Excellent';
    } else if (score >= 70) {
      scoreColor = const Color(0xFFFFB74D);
      scoreLabel = 'Attention';
    } else {
      scoreColor = const Color(0xFFEF5350);
      scoreLabel = 'Critique';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
              color: scoreColor.withOpacity(0.1),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      color: scoreColor.withOpacity(0.6),
                      fontSize: 9,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.lock_shield_fill, size: 16, color: scoreColor),
                    const SizedBox(width: 8),
                    Text(
                      'Security Score: $scoreLabel',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScoreBadge('Critiques', criticalCount, const Color(0xFFEF5350)),
                    const SizedBox(width: 8),
                    _buildScoreBadge('Warnings', warningCount, const Color(0xFFFFB74D)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecureState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.shield_lefthalf_fill,
            size: 48,
            color: const Color(0xFF66BB6A).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun problème détecté',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le scanner analyse automatiquement\ntoutes les requêtes réseau',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityIssueCard extends StatelessWidget {
  final SecurityIssue issue;
  final Color accentColor;

  const _SecurityIssueCard({required this.issue, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final devTools = context.read<NotilusDevToolsService>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: issue.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: issue.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(issue.icon, size: 16, color: issue.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    issue.title,
                    style: TextStyle(
                      color: issue.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
                // Severity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: issue.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.severity.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Resolve button
                GestureDetector(
                  onTap: () => devTools.resolveSecurityIssue(issue.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Résolu',
                      style: TextStyle(
                        color: const Color(0xFF66BB6A),
                        fontSize: 9,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                if (issue.url != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.link,
                          size: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issue.url!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontFamily: 'JetBrains Mono',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (issue.recommendation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF66BB6A).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_seal,
                          size: 12,
                          color: const Color(0xFF66BB6A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issue.recommendation!,
                            style: TextStyle(
                              color: const Color(0xFF66BB6A),
                              fontSize: 10,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ),
                      ],
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

