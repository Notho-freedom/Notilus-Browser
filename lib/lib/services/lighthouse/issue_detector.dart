/// Détecteur de problèmes pour Notilus Lighthouse
/// Agrège et analyse tous les problèmes détectés
library issue_detector;

import 'package:flutter/foundation.dart';
import '../../models/lighthouse/audit_models.dart';
import 'lighthouse_service.dart';

/// Détecteur de problèmes
class IssueDetector {
  final LighthouseService _lighthouseService;

  IssueDetector(this._lighthouseService);

  /// Génère des recommandations IA basées sur les problèmes
  List<Recommendation> generateRecommendations(List<Issue> issues) {
    final recommendations = <Recommendation>[];
    final issuesByCategory = _groupByCategory(issues);

    // Recommandations pour les performances
    if (issuesByCategory[AuditCategory.performance]?.isNotEmpty == true) {
      final perfIssues = issuesByCategory[AuditCategory.performance]!;

      // Quick wins
      final quickWins = perfIssues.where((i) =>
          i.suggestedFixes?.any((f) => f.effort == EffortLevel.minimal) == true);

      if (quickWins.isNotEmpty) {
        recommendations.add(Recommendation(
          id: 'rec_quick_wins',
          title: 'Quick Wins Performance',
          description: '${quickWins.length} corrections rapides disponibles pour améliorer les performances.',
          priority: RecommendationPriority.high,
          estimatedImpact: quickWins.length * 3,
          effort: EffortLevel.minimal,
          category: AuditCategory.performance,
          actionSteps: quickWins.map((i) => ActionStep(
            order: 1,
            description: i.title,
          )).toList(),
        ));
      }

      // Optimisation images
      final imageIssues = perfIssues.where((i) => i.id.contains('img'));
      if (imageIssues.length >= 2) {
        recommendations.add(Recommendation(
          id: 'rec_images',
          title: 'Optimiser les images',
          description: 'Plusieurs problèmes d\'images détectés.',
          priority: RecommendationPriority.high,
          estimatedImpact: 8,
          effort: EffortLevel.moderate,
          category: AuditCategory.performance,
          actionSteps: [
            ActionStep(order: 1, description: 'Convertir les images en WebP'),
            ActionStep(order: 2, description: 'Ajouter width/height à toutes les images'),
            ActionStep(order: 3, description: 'Implémenter le lazy loading'),
            ActionStep(order: 4, description: 'Utiliser srcset pour les images responsives'),
          ],
        ));
      }

      // JavaScript
      final jsIssues = perfIssues.where((i) => i.id.contains('js') || i.id.contains('script'));
      if (jsIssues.isNotEmpty) {
        recommendations.add(Recommendation(
          id: 'rec_js',
          title: 'Optimiser le JavaScript',
          description: 'Le JavaScript impacte le temps de chargement.',
          priority: RecommendationPriority.high,
          estimatedImpact: 10,
          effort: EffortLevel.significant,
          category: AuditCategory.performance,
          actionSteps: [
            ActionStep(order: 1, description: 'Utiliser defer ou async pour les scripts'),
            ActionStep(order: 2, description: 'Implémenter le code-splitting'),
            ActionStep(order: 3, description: 'Minifier et compresser le JS'),
            ActionStep(order: 4, description: 'Supprimer le code inutilisé (tree-shaking)'),
          ],
        ));
      }
    }

    // Recommandations pour l'accessibilité
    if (issuesByCategory[AuditCategory.accessibility]?.isNotEmpty == true) {
      final a11yIssues = issuesByCategory[AuditCategory.accessibility]!;
      final criticalA11y = a11yIssues.where((i) => i.severity == IssueSeverity.critical);

      if (criticalA11y.isNotEmpty) {
        recommendations.add(Recommendation(
          id: 'rec_a11y_critical',
          title: 'Corriger les problèmes d\'accessibilité critiques',
          description: '${criticalA11y.length} problèmes critiques d\'accessibilité.',
          priority: RecommendationPriority.high,
          estimatedImpact: 15,
          effort: EffortLevel.moderate,
          category: AuditCategory.accessibility,
          actionSteps: criticalA11y.map((i) => ActionStep(
            order: 1,
            description: i.title,
          )).toList(),
        ));
      }
    }

    // Recommandations pour le SEO
    if (issuesByCategory[AuditCategory.seo]?.isNotEmpty == true) {
      final seoIssues = issuesByCategory[AuditCategory.seo]!;
      final hasNoTitle = seoIssues.any((i) => i.id.contains('title'));
      final hasNoDescription = seoIssues.any((i) => i.id.contains('description'));

      if (hasNoTitle || hasNoDescription) {
        recommendations.add(Recommendation(
          id: 'rec_seo_meta',
          title: 'Optimiser les meta tags',
          description: 'Les meta tags essentiels sont manquants ou incomplets.',
          priority: RecommendationPriority.high,
          estimatedImpact: 8,
          effort: EffortLevel.minimal,
          category: AuditCategory.seo,
          actionSteps: [
            if (hasNoTitle) ActionStep(order: 1, description: 'Ajouter un titre optimisé (50-60 caractères)'),
            if (hasNoDescription) ActionStep(order: 2, description: 'Ajouter une meta description (150-160 caractères)'),
            ActionStep(order: 3, description: 'Ajouter les balises Open Graph'),
          ],
        ));
      }
    }

    // Recommandations pour la sécurité
    if (issuesByCategory[AuditCategory.security]?.isNotEmpty == true) {
      final secIssues = issuesByCategory[AuditCategory.security]!;
      final criticalSec = secIssues.where((i) => i.severity == IssueSeverity.critical);

      if (criticalSec.isNotEmpty) {
        recommendations.add(Recommendation(
          id: 'rec_security',
          title: 'Corriger les vulnérabilités de sécurité',
          description: '${criticalSec.length} problèmes de sécurité critiques.',
          priority: RecommendationPriority.high,
          estimatedImpact: 20,
          effort: EffortLevel.moderate,
          category: AuditCategory.security,
          actionSteps: criticalSec.map((i) => ActionStep(
            order: 1,
            description: i.title,
          )).toList(),
        ));
      }
    }

    // Trier par opportunité (impact / effort)
    recommendations.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));

    return recommendations;
  }

  /// Calcule un score d'impact global pour les problèmes
  double calculateImpactScore(List<Issue> issues) {
    double score = 0;

    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.critical:
          score += 10;
          break;
        case IssueSeverity.high:
          score += 8;
          break;
        case IssueSeverity.medium:
        case IssueSeverity.warning:
          score += 5;
          break;
        case IssueSeverity.low:
        case IssueSeverity.info:
          score += 1;
          break;
        case IssueSeverity.passed:
          break;
      }
    }

    return score;
  }

  /// Identifie les quick wins (fort impact, faible effort)
  List<Issue> identifyQuickWins(List<Issue> issues) {
    return issues.where((issue) {
      // Un quick win a des corrections à faible effort
      final hasEasyFix = issue.suggestedFixes?.any((fix) =>
          fix.effort == EffortLevel.minimal && fix.canAutoFix) == true;

      // Et un impact significatif
      final hasHighImpact = issue.severity == IssueSeverity.critical ||
          issue.severity == IssueSeverity.warning;

      return hasEasyFix && hasHighImpact;
    }).toList();
  }

  /// Groupe les problèmes par catégorie
  Map<AuditCategory, List<Issue>> _groupByCategory(List<Issue> issues) {
    final grouped = <AuditCategory, List<Issue>>{};

    for (final issue in issues) {
      grouped.putIfAbsent(issue.category, () => []).add(issue);
    }

    return grouped;
  }

  /// Génère un résumé textuel des problèmes
  String generateSummary(AuditResult result) {
    final buffer = StringBuffer();

    // Score global
    buffer.writeln('## Résumé de l\'audit');
    buffer.writeln();
    buffer.writeln('**Score global: ${result.overallScore}/100** (${result.grade.letter})');
    buffer.writeln();

    // Core Web Vitals
    buffer.writeln('### Core Web Vitals');
    buffer.writeln('- LCP: ${result.webVitals.formatMs(result.webVitals.lcp)} ${_getStatus(result.webVitals.lcpStatus)}');
    buffer.writeln('- FID: ${result.webVitals.formatMs(result.webVitals.fid)} ${_getStatus(result.webVitals.fidStatus)}');
    buffer.writeln('- CLS: ${result.webVitals.formatCls(result.webVitals.cls)} ${_getStatus(result.webVitals.clsStatus)}');
    buffer.writeln();

    // Problèmes par catégorie
    final issuesByCategory = _groupByCategory(result.issues);
    buffer.writeln('### Problèmes détectés');
    buffer.writeln();

    for (final category in AuditCategory.values) {
      final issues = issuesByCategory[category] ?? [];
      if (issues.isNotEmpty) {
        buffer.writeln('**${category.displayName}** (${issues.length} problèmes)');
        for (final issue in issues.take(3)) {
          buffer.writeln('- ${issue.title}');
        }
        if (issues.length > 3) {
          buffer.writeln('- ... et ${issues.length - 3} autres');
        }
        buffer.writeln();
      }
    }

    // Top recommandations
    if (result.recommendations.isNotEmpty) {
      buffer.writeln('### Recommandations prioritaires');
      buffer.writeln();
      for (final rec in result.sortedRecommendations.take(3)) {
        buffer.writeln('1. **${rec.title}** (+${rec.estimatedImpact} points estimés)');
        buffer.writeln('   ${rec.description}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _getStatus(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.passed:
        return '✅';
      case IssueSeverity.warning:
      case IssueSeverity.medium:
        return '⚠️';
      case IssueSeverity.critical:
      case IssueSeverity.high:
        return '❌';
      case IssueSeverity.low:
      case IssueSeverity.info:
        return 'ℹ️';
    }
  }

  /// Génère un rapport de comparaison
  String generateComparisonReport(AuditResult current, AuditResult previous) {
    final buffer = StringBuffer();

    buffer.writeln('## Comparaison d\'audits');
    buffer.writeln();
    buffer.writeln('| Métrique | Avant | Après | Évolution |');
    buffer.writeln('|----------|-------|-------|-----------|');

    // Score global
    final scoreDiff = current.overallScore - previous.overallScore;
    buffer.writeln('| Score | ${previous.overallScore} | ${current.overallScore} | ${_formatDiff(scoreDiff)} |');

    // LCP
    if (current.webVitals.lcp != null && previous.webVitals.lcp != null) {
      final lcpDiff = current.webVitals.lcp! - previous.webVitals.lcp!;
      buffer.writeln('| LCP | ${previous.webVitals.formatMs(previous.webVitals.lcp)} | ${current.webVitals.formatMs(current.webVitals.lcp)} | ${_formatDiff(-lcpDiff.round(), suffix: 'ms')} |');
    }

    // Problèmes
    final issuesDiff = current.issues.length - previous.issues.length;
    buffer.writeln('| Problèmes | ${previous.issues.length} | ${current.issues.length} | ${_formatDiff(-issuesDiff)} |');

    return buffer.toString();
  }

  String _formatDiff(num diff, {String suffix = ''}) {
    if (diff > 0) {
      return '🟢 +$diff$suffix';
    } else if (diff < 0) {
      return '🔴 $diff$suffix';
    }
    return '⚪ 0$suffix';
  }
}

