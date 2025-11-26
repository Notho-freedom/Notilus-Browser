/// Modèles d'audit pour Notilus Lighthouse
/// Définit les structures de données pour l'analyse de performance
library audit_models;

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Catégories d'audit
enum AuditCategory {
  performance,
  accessibility,
  bestPractices,
  seo,
  security,
  pwa,
  carbon,
}

extension AuditCategoryExtension on AuditCategory {
  String get displayName {
    switch (this) {
      case AuditCategory.performance:
        return 'Performance';
      case AuditCategory.accessibility:
        return 'Accessibilité';
      case AuditCategory.bestPractices:
        return 'Bonnes Pratiques';
      case AuditCategory.seo:
        return 'SEO';
      case AuditCategory.security:
        return 'Sécurité';
      case AuditCategory.pwa:
        return 'PWA';
      case AuditCategory.carbon:
        return 'Empreinte Carbone';
    }
  }

  IconData get icon {
    switch (this) {
      case AuditCategory.performance:
        return Icons.speed;
      case AuditCategory.accessibility:
        return Icons.accessibility_new;
      case AuditCategory.bestPractices:
        return Icons.check_circle;
      case AuditCategory.seo:
        return Icons.search;
      case AuditCategory.security:
        return Icons.security;
      case AuditCategory.pwa:
        return Icons.install_mobile;
      case AuditCategory.carbon:
        return Icons.eco;
    }
  }

  Color get color {
    switch (this) {
      case AuditCategory.performance:
        return const Color(0xFF4CAF50);
      case AuditCategory.accessibility:
        return const Color(0xFF2196F3);
      case AuditCategory.bestPractices:
        return const Color(0xFF9C27B0);
      case AuditCategory.seo:
        return const Color(0xFFFF9800);
      case AuditCategory.security:
        return const Color(0xFFF44336);
      case AuditCategory.pwa:
        return const Color(0xFF00BCD4);
      case AuditCategory.carbon:
        return const Color(0xFF8BC34A);
    }
  }

  double get weight {
    switch (this) {
      case AuditCategory.performance:
        return 0.25;
      case AuditCategory.accessibility:
        return 0.20;
      case AuditCategory.bestPractices:
        return 0.15;
      case AuditCategory.seo:
        return 0.15;
      case AuditCategory.security:
        return 0.15;
      case AuditCategory.pwa:
        return 0.05;
      case AuditCategory.carbon:
        return 0.05;
    }
  }
}

/// Sévérité des problèmes
enum IssueSeverity {
  critical,
  warning,
  info,
  passed,
}

extension IssueSeverityExtension on IssueSeverity {
  String get displayName {
    switch (this) {
      case IssueSeverity.critical:
        return 'Critique';
      case IssueSeverity.warning:
        return 'Avertissement';
      case IssueSeverity.info:
        return 'Information';
      case IssueSeverity.passed:
        return 'Réussi';
    }
  }

  IconData get icon {
    switch (this) {
      case IssueSeverity.critical:
        return Icons.error;
      case IssueSeverity.warning:
        return Icons.warning_amber;
      case IssueSeverity.info:
        return Icons.info_outline;
      case IssueSeverity.passed:
        return Icons.check_circle;
    }
  }

  Color get color {
    switch (this) {
      case IssueSeverity.critical:
        return const Color(0xFFF44336);
      case IssueSeverity.warning:
        return const Color(0xFFFF9800);
      case IssueSeverity.info:
        return const Color(0xFF2196F3);
      case IssueSeverity.passed:
        return const Color(0xFF4CAF50);
    }
  }

  int get sortOrder {
    switch (this) {
      case IssueSeverity.critical:
        return 0;
      case IssueSeverity.warning:
        return 1;
      case IssueSeverity.info:
        return 2;
      case IssueSeverity.passed:
        return 3;
    }
  }
}

/// Priorité des recommandations
enum RecommendationPriority {
  high,
  medium,
  low,
}

extension RecommendationPriorityExtension on RecommendationPriority {
  String get displayName {
    switch (this) {
      case RecommendationPriority.high:
        return 'Haute priorité';
      case RecommendationPriority.medium:
        return 'Priorité moyenne';
      case RecommendationPriority.low:
        return 'Faible priorité';
    }
  }

  Color get color {
    switch (this) {
      case RecommendationPriority.high:
        return const Color(0xFFF44336);
      case RecommendationPriority.medium:
        return const Color(0xFFFF9800);
      case RecommendationPriority.low:
        return const Color(0xFF4CAF50);
    }
  }
}

/// Niveau d'effort requis
enum EffortLevel {
  minimal,
  moderate,
  significant,
}

extension EffortLevelExtension on EffortLevel {
  String get displayName {
    switch (this) {
      case EffortLevel.minimal:
        return 'Effort minimal';
      case EffortLevel.moderate:
        return 'Effort modéré';
      case EffortLevel.significant:
        return 'Effort significatif';
    }
  }

  String get duration {
    switch (this) {
      case EffortLevel.minimal:
        return '< 30 min';
      case EffortLevel.moderate:
        return '1-4 heures';
      case EffortLevel.significant:
        return '> 1 jour';
    }
  }
}

/// Grade de score
enum ScoreGrade {
  aPLus,
  a,
  b,
  c,
  d,
  f,
}

extension ScoreGradeExtension on ScoreGrade {
  String get letter {
    switch (this) {
      case ScoreGrade.aPLus:
        return 'A+';
      case ScoreGrade.a:
        return 'A';
      case ScoreGrade.b:
        return 'B';
      case ScoreGrade.c:
        return 'C';
      case ScoreGrade.d:
        return 'D';
      case ScoreGrade.f:
        return 'F';
    }
  }

  String get label {
    switch (this) {
      case ScoreGrade.aPLus:
        return 'Excellent';
      case ScoreGrade.a:
        return 'Très bien';
      case ScoreGrade.b:
        return 'Bien';
      case ScoreGrade.c:
        return 'Correct';
      case ScoreGrade.d:
        return 'À améliorer';
      case ScoreGrade.f:
        return 'Critique';
    }
  }

  Color get color {
    switch (this) {
      case ScoreGrade.aPLus:
      case ScoreGrade.a:
        return const Color(0xFF4CAF50);
      case ScoreGrade.b:
        return const Color(0xFF8BC34A);
      case ScoreGrade.c:
        return const Color(0xFFFF9800);
      case ScoreGrade.d:
        return const Color(0xFFFF5722);
      case ScoreGrade.f:
        return const Color(0xFFF44336);
    }
  }

  static ScoreGrade fromScore(int score) {
    if (score >= 95) return ScoreGrade.aPLus;
    if (score >= 85) return ScoreGrade.a;
    if (score >= 70) return ScoreGrade.b;
    if (score >= 50) return ScoreGrade.c;
    if (score >= 30) return ScoreGrade.d;
    return ScoreGrade.f;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Métriques Core Web Vitals
class CoreWebVitals {
  /// Largest Contentful Paint (ms)
  final double? lcp;

  /// First Input Delay (ms)
  final double? fid;

  /// Cumulative Layout Shift
  final double? cls;

  /// Time to First Byte (ms)
  final double? ttfb;

  /// Time to Interactive (ms)
  final double? tti;

  /// Total Blocking Time (ms)
  final double? tbt;

  /// First Contentful Paint (ms)
  final double? fcp;

  /// Speed Index (ms)
  final double? speedIndex;

  CoreWebVitals({
    this.lcp,
    this.fid,
    this.cls,
    this.ttfb,
    this.tti,
    this.tbt,
    this.fcp,
    this.speedIndex,
  });

  /// Évalue le LCP (bon < 2.5s, moyen < 4s, mauvais >= 4s)
  IssueSeverity get lcpStatus {
    if (lcp == null) return IssueSeverity.info;
    if (lcp! < 2500) return IssueSeverity.passed;
    if (lcp! < 4000) return IssueSeverity.warning;
    return IssueSeverity.critical;
  }

  /// Évalue le FID (bon < 100ms, moyen < 300ms, mauvais >= 300ms)
  IssueSeverity get fidStatus {
    if (fid == null) return IssueSeverity.info;
    if (fid! < 100) return IssueSeverity.passed;
    if (fid! < 300) return IssueSeverity.warning;
    return IssueSeverity.critical;
  }

  /// Évalue le CLS (bon < 0.1, moyen < 0.25, mauvais >= 0.25)
  IssueSeverity get clsStatus {
    if (cls == null) return IssueSeverity.info;
    if (cls! < 0.1) return IssueSeverity.passed;
    if (cls! < 0.25) return IssueSeverity.warning;
    return IssueSeverity.critical;
  }

  /// Évalue le TTFB (bon < 800ms, moyen < 1800ms, mauvais >= 1800ms)
  IssueSeverity get ttfbStatus {
    if (ttfb == null) return IssueSeverity.info;
    if (ttfb! < 800) return IssueSeverity.passed;
    if (ttfb! < 1800) return IssueSeverity.warning;
    return IssueSeverity.critical;
  }

  String formatMs(double? value) {
    if (value == null) return '-';
    if (value < 1000) return '${value.round()}ms';
    return '${(value / 1000).toStringAsFixed(2)}s';
  }

  String formatCls(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(3);
  }

  factory CoreWebVitals.fromJson(Map<String, dynamic> json) {
    return CoreWebVitals(
      lcp: (json['lcp'] as num?)?.toDouble(),
      fid: (json['fid'] as num?)?.toDouble(),
      cls: (json['cls'] as num?)?.toDouble(),
      ttfb: (json['ttfb'] as num?)?.toDouble(),
      tti: (json['tti'] as num?)?.toDouble(),
      tbt: (json['tbt'] as num?)?.toDouble(),
      fcp: (json['fcp'] as num?)?.toDouble(),
      speedIndex: (json['speedIndex'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lcp': lcp,
        'fid': fid,
        'cls': cls,
        'ttfb': ttfb,
        'tti': tti,
        'tbt': tbt,
        'fcp': fcp,
        'speedIndex': speedIndex,
      };
}

/// Score d'une catégorie
class CategoryScore {
  final AuditCategory category;
  final int score;
  final int passedAudits;
  final int totalAudits;
  final List<Issue> issues;

  CategoryScore({
    required this.category,
    required this.score,
    required this.passedAudits,
    required this.totalAudits,
    this.issues = const [],
  });

  ScoreGrade get grade => ScoreGradeExtension.fromScore(score);

  double get passRate =>
      totalAudits > 0 ? passedAudits / totalAudits : 0;

  factory CategoryScore.fromJson(Map<String, dynamic> json) {
    return CategoryScore(
      category: AuditCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AuditCategory.performance,
      ),
      score: json['score'] as int? ?? 0,
      passedAudits: json['passedAudits'] as int? ?? 0,
      totalAudits: json['totalAudits'] as int? ?? 0,
      issues: (json['issues'] as List<dynamic>?)
              ?.map((i) => Issue.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'score': score,
        'passedAudits': passedAudits,
        'totalAudits': totalAudits,
        'issues': issues.map((i) => i.toJson()).toList(),
      };
}

/// Problème détecté
class Issue {
  final String id;
  final String title;
  final String description;
  final IssueSeverity severity;
  final AuditCategory category;
  final String? rootCause;
  final ImpactEstimate? impact;
  final List<Fix>? suggestedFixes;
  final String? codeSnippet;
  final String? affectedElement;
  final String? documentation;
  final Map<String, dynamic>? metadata;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    this.rootCause,
    this.impact,
    this.suggestedFixes,
    this.codeSnippet,
    this.affectedElement,
    this.documentation,
    this.metadata,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: IssueSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => IssueSeverity.info,
      ),
      category: AuditCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AuditCategory.performance,
      ),
      rootCause: json['rootCause'] as String?,
      impact: json['impact'] != null
          ? ImpactEstimate.fromJson(json['impact'] as Map<String, dynamic>)
          : null,
      suggestedFixes: (json['suggestedFixes'] as List<dynamic>?)
          ?.map((f) => Fix.fromJson(f as Map<String, dynamic>))
          .toList(),
      codeSnippet: json['codeSnippet'] as String?,
      affectedElement: json['affectedElement'] as String?,
      documentation: json['documentation'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity.name,
        'category': category.name,
        'rootCause': rootCause,
        'impact': impact?.toJson(),
        'suggestedFixes': suggestedFixes?.map((f) => f.toJson()).toList(),
        'codeSnippet': codeSnippet,
        'affectedElement': affectedElement,
        'documentation': documentation,
        'metadata': metadata,
      };
}

/// Estimation de l'impact d'un problème
class ImpactEstimate {
  final String metric;
  final String currentValue;
  final String? estimatedImprovement;
  final int? scoreImpact;

  ImpactEstimate({
    required this.metric,
    required this.currentValue,
    this.estimatedImprovement,
    this.scoreImpact,
  });

  factory ImpactEstimate.fromJson(Map<String, dynamic> json) {
    return ImpactEstimate(
      metric: json['metric'] as String,
      currentValue: json['currentValue'] as String,
      estimatedImprovement: json['estimatedImprovement'] as String?,
      scoreImpact: json['scoreImpact'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'currentValue': currentValue,
        'estimatedImprovement': estimatedImprovement,
        'scoreImpact': scoreImpact,
      };
}

/// Suggestion de correction
class Fix {
  final String id;
  final String title;
  final String description;
  final String? code;
  final bool canAutoFix;
  final EffortLevel effort;

  Fix({
    required this.id,
    required this.title,
    required this.description,
    this.code,
    this.canAutoFix = false,
    this.effort = EffortLevel.minimal,
  });

  factory Fix.fromJson(Map<String, dynamic> json) {
    return Fix(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      code: json['code'] as String?,
      canAutoFix: json['canAutoFix'] as bool? ?? false,
      effort: EffortLevel.values.firstWhere(
        (e) => e.name == json['effort'],
        orElse: () => EffortLevel.minimal,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'code': code,
        'canAutoFix': canAutoFix,
        'effort': effort.name,
      };
}

/// Recommandation IA
class Recommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final int estimatedImpact;
  final EffortLevel effort;
  final List<ActionStep> steps;
  final String? generatedCode;
  final AuditCategory category;

  Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedImpact,
    required this.effort,
    this.steps = const [],
    this.generatedCode,
    required this.category,
  });

  /// Score d'opportunité (impact / effort)
  double get opportunityScore {
    final effortMultiplier = effort == EffortLevel.minimal
        ? 3.0
        : effort == EffortLevel.moderate
            ? 2.0
            : 1.0;
    return estimatedImpact * effortMultiplier;
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: RecommendationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => RecommendationPriority.medium,
      ),
      estimatedImpact: json['estimatedImpact'] as int? ?? 0,
      effort: EffortLevel.values.firstWhere(
        (e) => e.name == json['effort'],
        orElse: () => EffortLevel.moderate,
      ),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => ActionStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      generatedCode: json['generatedCode'] as String?,
      category: AuditCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AuditCategory.performance,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.name,
        'estimatedImpact': estimatedImpact,
        'effort': effort.name,
        'steps': steps.map((s) => s.toJson()).toList(),
        'generatedCode': generatedCode,
        'category': category.name,
      };
}

/// Étape d'action pour une recommandation
class ActionStep {
  final int order;
  final String description;
  final String? code;
  final bool isCompleted;

  ActionStep({
    required this.order,
    required this.description,
    this.code,
    this.isCompleted = false,
  });

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    return ActionStep(
      order: json['order'] as int,
      description: json['description'] as String,
      code: json['code'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'description': description,
        'code': code,
        'isCompleted': isCompleted,
      };
}

/// Analyse des ressources
class ResourceAnalysis {
  final int totalRequests;
  final int totalSize;
  final int htmlSize;
  final int cssSize;
  final int jsSize;
  final int imageSize;
  final int fontSize;
  final int otherSize;
  final int thirdPartyRequests;
  final int thirdPartySize;
  final List<ResourceItem> largestResources;

  ResourceAnalysis({
    required this.totalRequests,
    required this.totalSize,
    this.htmlSize = 0,
    this.cssSize = 0,
    this.jsSize = 0,
    this.imageSize = 0,
    this.fontSize = 0,
    this.otherSize = 0,
    this.thirdPartyRequests = 0,
    this.thirdPartySize = 0,
    this.largestResources = const [],
  });

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  factory ResourceAnalysis.fromJson(Map<String, dynamic> json) {
    return ResourceAnalysis(
      totalRequests: json['totalRequests'] as int? ?? 0,
      totalSize: json['totalSize'] as int? ?? 0,
      htmlSize: json['htmlSize'] as int? ?? 0,
      cssSize: json['cssSize'] as int? ?? 0,
      jsSize: json['jsSize'] as int? ?? 0,
      imageSize: json['imageSize'] as int? ?? 0,
      fontSize: json['fontSize'] as int? ?? 0,
      otherSize: json['otherSize'] as int? ?? 0,
      thirdPartyRequests: json['thirdPartyRequests'] as int? ?? 0,
      thirdPartySize: json['thirdPartySize'] as int? ?? 0,
      largestResources: (json['largestResources'] as List<dynamic>?)
              ?.map((r) => ResourceItem.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'totalRequests': totalRequests,
        'totalSize': totalSize,
        'htmlSize': htmlSize,
        'cssSize': cssSize,
        'jsSize': jsSize,
        'imageSize': imageSize,
        'fontSize': fontSize,
        'otherSize': otherSize,
        'thirdPartyRequests': thirdPartyRequests,
        'thirdPartySize': thirdPartySize,
        'largestResources': largestResources.map((r) => r.toJson()).toList(),
      };
}

/// Élément de ressource
class ResourceItem {
  final String url;
  final String type;
  final int size;
  final double? loadTime;
  final bool isThirdParty;

  ResourceItem({
    required this.url,
    required this.type,
    required this.size,
    this.loadTime,
    this.isThirdParty = false,
  });

  String get fileName {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      return path.isEmpty || path == '/' ? uri.host : path.split('/').last;
    } catch (_) {
      return url;
    }
  }

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    return ResourceItem(
      url: json['url'] as String,
      type: json['type'] as String,
      size: json['size'] as int? ?? 0,
      loadTime: (json['loadTime'] as num?)?.toDouble(),
      isThirdParty: json['isThirdParty'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type,
        'size': size,
        'loadTime': loadTime,
        'isThirdParty': isThirdParty,
      };
}

/// Résultat complet d'un audit
class AuditResult {
  final String id;
  final String url;
  final DateTime timestamp;
  final int overallScore;
  final Map<AuditCategory, CategoryScore> categories;
  final CoreWebVitals webVitals;
  final List<Issue> issues;
  final List<Recommendation> recommendations;
  final ResourceAnalysis resources;
  final Duration auditDuration;
  final String? devicePreset;
  final bool isMobile;

  AuditResult({
    required this.id,
    required this.url,
    required this.timestamp,
    required this.overallScore,
    required this.categories,
    required this.webVitals,
    required this.issues,
    required this.recommendations,
    required this.resources,
    required this.auditDuration,
    this.devicePreset,
    this.isMobile = false,
  });

  ScoreGrade get grade => ScoreGradeExtension.fromScore(overallScore);

  int get criticalIssueCount =>
      issues.where((i) => i.severity == IssueSeverity.critical).length;

  int get warningIssueCount =>
      issues.where((i) => i.severity == IssueSeverity.warning).length;

  List<Issue> get sortedIssues => List.from(issues)
    ..sort((a, b) => a.severity.sortOrder.compareTo(b.severity.sortOrder));

  List<Recommendation> get sortedRecommendations => List.from(recommendations)
    ..sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));

  factory AuditResult.fromJson(Map<String, dynamic> json) {
    return AuditResult(
      id: json['id'] as String,
      url: json['url'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      overallScore: json['overallScore'] as int,
      categories: (json['categories'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          AuditCategory.values.firstWhere((c) => c.name == key),
          CategoryScore.fromJson(value as Map<String, dynamic>),
        ),
      ),
      webVitals: CoreWebVitals.fromJson(
          json['webVitals'] as Map<String, dynamic>),
      issues: (json['issues'] as List<dynamic>)
          .map((i) => Issue.fromJson(i as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((r) => Recommendation.fromJson(r as Map<String, dynamic>))
          .toList(),
      resources: ResourceAnalysis.fromJson(
          json['resources'] as Map<String, dynamic>),
      auditDuration: Duration(milliseconds: json['auditDuration'] as int),
      devicePreset: json['devicePreset'] as String?,
      isMobile: json['isMobile'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'timestamp': timestamp.toIso8601String(),
        'overallScore': overallScore,
        'categories': categories.map(
          (key, value) => MapEntry(key.name, value.toJson()),
        ),
        'webVitals': webVitals.toJson(),
        'issues': issues.map((i) => i.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'resources': resources.toJson(),
        'auditDuration': auditDuration.inMilliseconds,
        'devicePreset': devicePreset,
        'isMobile': isMobile,
      };
}

/// Entrée d'historique d'audit
class AuditHistoryEntry {
  final String id;
  final String url;
  final DateTime timestamp;
  final int score;
  final ScoreGrade grade;
  final CoreWebVitals webVitals;
  final int issueCount;

  AuditHistoryEntry({
    required this.id,
    required this.url,
    required this.timestamp,
    required this.score,
    required this.grade,
    required this.webVitals,
    required this.issueCount,
  });

  factory AuditHistoryEntry.fromAuditResult(AuditResult result) {
    return AuditHistoryEntry(
      id: result.id,
      url: result.url,
      timestamp: result.timestamp,
      score: result.overallScore,
      grade: result.grade,
      webVitals: result.webVitals,
      issueCount: result.issues.length,
    );
  }

  factory AuditHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AuditHistoryEntry(
      id: json['id'] as String,
      url: json['url'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      score: json['score'] as int,
      grade: ScoreGradeExtension.fromScore(json['score'] as int),
      webVitals: CoreWebVitals.fromJson(
          json['webVitals'] as Map<String, dynamic>),
      issueCount: json['issueCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'timestamp': timestamp.toIso8601String(),
        'score': score,
        'webVitals': webVitals.toJson(),
        'issueCount': issueCount,
      };
}

