/// Service principal Notilus Lighthouse
/// Analyse complète des performances, accessibilité, SEO et sécurité
library lighthouse_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../browser_engine.dart';
import '../../models/lighthouse/audit_models.dart';
import 'performance_analyzer.dart';
import 'accessibility_checker.dart';
import 'seo_analyzer.dart';
import 'security_scanner.dart';
import 'issue_detector.dart';
import 'audit_history_service.dart';
import 'ai_advisor_service.dart';

/// Service principal de Notilus Lighthouse
class LighthouseService extends ChangeNotifier {
  BrowserEngine? _engine;
  String? _currentUrl;
  bool _isEnabled = false;

  // Services d'analyse
  late final PerformanceAnalyzer performanceAnalyzer;
  late final AccessibilityChecker accessibilityChecker;
  late final SEOAnalyzer seoAnalyzer;
  late final SecurityScanner securityScanner;
  late final IssueDetector issueDetector;
  late final AuditHistoryService _historyService;
  late final AIAdvisorService _aiAdvisor;

  // État
  bool _isAnalyzing = false;
  double _analysisProgress = 0;
  String _analysisStep = '';
  AuditResult? _lastResult;
  String? _lastError;

  // Historique
  final List<AuditHistoryEntry> _history = [];
  static const int _maxHistorySize = 100;

  // Configuration
  bool _analyzePerformance = true;
  bool _analyzeAccessibility = true;
  bool _analyzeSEO = true;
  bool _analyzeSecurity = true;
  bool _analyzeBestPractices = true;
  bool _simulateMobile = false;
  bool _throttleNetwork = false;

  LighthouseService() {
    performanceAnalyzer = PerformanceAnalyzer(this);
    accessibilityChecker = AccessibilityChecker(this);
    seoAnalyzer = SEOAnalyzer(this);
    securityScanner = SecurityScanner(this);
    issueDetector = IssueDetector(this);
    _historyService = AuditHistoryService();
    _aiAdvisor = AIAdvisorService(this);
  }

  // Getters
  BrowserEngine? get engine => _engine;
  String? get currentUrl => _currentUrl;
  bool get isEnabled => _isEnabled;
  bool get isAnalyzing => _isAnalyzing;
  double get analysisProgress => _analysisProgress;
  String get analysisStep => _analysisStep;
  AuditResult? get lastResult => _lastResult;
  String? get lastError => _lastError;
  List<AuditHistoryEntry> get history => List.unmodifiable(_history);
  AuditHistoryService get historyService => _historyService;
  AIAdvisorService get aiAdvisorService => _aiAdvisor;
  
  /// Alias pour isAnalyzing (compatibilité UI)
  bool get isRunning => _isAnalyzing;
  
  /// Alias pour analysisProgress (compatibilité UI)
  double get progress => _analysisProgress;
  
  /// Alias pour analysisStep (compatibilité UI)
  String? get currentStep => _analysisStep.isEmpty ? null : _analysisStep;
  
  bool _isCancelled = false;

  // Configuration getters
  bool get analyzePerformance => _analyzePerformance;
  bool get analyzeAccessibility => _analyzeAccessibility;
  bool get analyzeSEO => _analyzeSEO;
  bool get analyzeSecurity => _analyzeSecurity;
  bool get analyzeBestPractices => _analyzeBestPractices;
  bool get simulateMobile => _simulateMobile;
  bool get throttleNetwork => _throttleNetwork;

  /// Attache le service à un moteur de rendu
  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    notifyListeners();
  }

  /// Détache le moteur
  void detachEngine() {
    _engine = null;
    notifyListeners();
  }

  /// Active/désactive Lighthouse
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  /// Met à jour l'URL courante
  void updateUrl(String url) {
    _currentUrl = url;
    notifyListeners();
  }

  // Configuration setters
  void setAnalyzePerformance(bool value) {
    _analyzePerformance = value;
    notifyListeners();
  }

  void setAnalyzeAccessibility(bool value) {
    _analyzeAccessibility = value;
    notifyListeners();
  }

  void setAnalyzeSEO(bool value) {
    _analyzeSEO = value;
    notifyListeners();
  }

  void setAnalyzeSecurity(bool value) {
    _analyzeSecurity = value;
    notifyListeners();
  }

  void setSimulateMobile(bool value) {
    _simulateMobile = value;
    notifyListeners();
  }

  void setThrottleNetwork(bool value) {
    _throttleNetwork = value;
    notifyListeners();
  }

  /// Annule l'audit en cours
  void cancelAudit() {
    if (!_isAnalyzing) return;
    
    _isCancelled = true;
    _isAnalyzing = false;
    _analysisProgress = 0;
    _analysisStep = '';
    notifyListeners();
  }

  /// Exécute un audit complet
  Future<AuditResult?> runFullAudit() async {
    if (_engine == null || _currentUrl == null) {
      _lastError = 'Aucun moteur ou URL disponible';
      return null;
    }

    _isAnalyzing = true;
    _analysisProgress = 0;
    _lastError = null;
    _isCancelled = false;
    notifyListeners();

    final startTime = DateTime.now();
    final allIssues = <Issue>[];
    final recommendations = <Recommendation>[];
    final categoryScores = <AuditCategory, CategoryScore>{};

    try {
      // 1. Collecte des métriques de performance
      if (_analyzePerformance) {
        _updateProgress(0.1, 'Analyse des performances...');
        final perfResult = await performanceAnalyzer.analyze();
        if (perfResult != null) {
          categoryScores[AuditCategory.performance] = perfResult.categoryScore;
          allIssues.addAll(perfResult.issues);
          recommendations.addAll(perfResult.recommendations);
        }
      }

      // 2. Vérification de l'accessibilité
      if (_analyzeAccessibility) {
        _updateProgress(0.3, 'Vérification de l\'accessibilité...');
        final a11yResult = await accessibilityChecker.analyze();
        if (a11yResult != null) {
          categoryScores[AuditCategory.accessibility] = a11yResult.categoryScore;
          allIssues.addAll(a11yResult.issues);
          recommendations.addAll(a11yResult.recommendations);
        }
      }

      // 3. Analyse SEO
      if (_analyzeSEO) {
        _updateProgress(0.5, 'Analyse SEO...');
        final seoResult = await seoAnalyzer.analyze();
        if (seoResult != null) {
          categoryScores[AuditCategory.seo] = seoResult.categoryScore;
          allIssues.addAll(seoResult.issues);
          recommendations.addAll(seoResult.recommendations);
        }
      }

      // 4. Scan de sécurité
      if (_analyzeSecurity) {
        _updateProgress(0.7, 'Scan de sécurité...');
        final secResult = await securityScanner.analyze();
        if (secResult != null) {
          categoryScores[AuditCategory.security] = secResult.categoryScore;
          allIssues.addAll(secResult.issues);
          recommendations.addAll(secResult.recommendations);
        }
      }

      // 5. Bonnes pratiques
      if (_analyzeBestPractices) {
        _updateProgress(0.85, 'Vérification des bonnes pratiques...');
        final bpResult = await _analyzeBestPracticesInternal();
        if (bpResult != null) {
          categoryScores[AuditCategory.bestPractices] = bpResult;
          allIssues.addAll(bpResult.issues);
        }
      }

      // 6. Calcul du score global
      _updateProgress(0.95, 'Calcul du score global...');
      final overallScore = _calculateOverallScore(categoryScores);

      // 7. Récupération des Core Web Vitals
      final webVitals = await performanceAnalyzer.getCoreWebVitals();

      // 8. Analyse des ressources
      final resources = await performanceAnalyzer.getResourceAnalysis();

      // Créer le résultat final
      final auditDuration = DateTime.now().difference(startTime);

      _lastResult = AuditResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: _currentUrl!,
        timestamp: DateTime.now(),
        overallScore: overallScore,
        categories: categoryScores,
        webVitals: webVitals ?? CoreWebVitals(),
        issues: allIssues,
        recommendations: recommendations,
        resources: resources ?? ResourceAnalysis(totalRequests: 0, totalSize: 0),
        auditDuration: auditDuration,
        isMobile: _simulateMobile,
      );

      // Ajouter à l'historique
      _addToHistory(_lastResult!);
      await _historyService.addEntry(AuditHistoryEntry.fromAuditResult(_lastResult!));

      // Analyser avec l'AI Advisor
      await _aiAdvisor.analyzeAuditResult(_lastResult!);

      _updateProgress(1.0, 'Audit terminé');

      return _lastResult;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Lighthouse audit error: $e');
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Exécute un audit rapide (performance uniquement)
  Future<AuditResult?> runQuickAudit() async {
    if (_engine == null || _currentUrl == null) return null;

    _isAnalyzing = true;
    _analysisProgress = 0;
    notifyListeners();

    try {
      _updateProgress(0.3, 'Analyse rapide des performances...');

      final webVitals = await performanceAnalyzer.getCoreWebVitals();
      final perfResult = await performanceAnalyzer.analyze();

      _updateProgress(1.0, 'Audit rapide terminé');

      if (perfResult != null && webVitals != null) {
        _lastResult = AuditResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: _currentUrl!,
          timestamp: DateTime.now(),
          overallScore: perfResult.categoryScore.score,
          categories: {AuditCategory.performance: perfResult.categoryScore},
          webVitals: webVitals,
          issues: perfResult.issues,
          recommendations: perfResult.recommendations,
          resources: ResourceAnalysis(totalRequests: 0, totalSize: 0),
          auditDuration: const Duration(seconds: 5),
          isMobile: _simulateMobile,
        );

        _addToHistory(_lastResult!);
        await _historyService.addEntry(AuditHistoryEntry.fromAuditResult(_lastResult!));
        return _lastResult;
      }

      return null;
    } catch (e) {
      _lastError = e.toString();
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Exécute du JavaScript dans le moteur
  Future<String?> executeScript(String script) async {
    if (_engine == null) return null;
    try {
      return await _engine!.evaluateJavaScript(script);
    } catch (e) {
      debugPrint('LighthouseService executeScript error: $e');
      return null;
    }
  }

  /// Analyse des bonnes pratiques
  Future<CategoryScore?> _analyzeBestPracticesInternal() async {
    final issues = <Issue>[];
    int passed = 0;
    int total = 0;

    // Vérifier HTTPS
    total++;
    if (_currentUrl?.startsWith('https://') == true) {
      passed++;
    } else {
      issues.add(Issue(
        id: 'bp_https',
        title: 'Site non sécurisé (HTTP)',
        description: 'Le site n\'utilise pas HTTPS, ce qui expose les données des utilisateurs.',
        severity: IssueSeverity.critical,
        category: AuditCategory.bestPractices,
        rootCause: 'Le serveur n\'a pas de certificat SSL valide ou la redirection HTTPS n\'est pas configurée.',
        suggestedFixes: [
          Fix(
            id: 'fix_https',
            title: 'Activer HTTPS',
            description: 'Obtenez un certificat SSL et configurez la redirection HTTPS.',
            effort: EffortLevel.moderate,
          ),
        ],
      ));
    }

    // Vérifier les erreurs console
    final consoleErrors = await executeScript('''
      (function() {
        // Compter les erreurs dans le window.onerror
        return JSON.stringify({ errorCount: window.__errorCount || 0 });
      })();
    ''');

    total++;
    if (consoleErrors != null) {
      final data = jsonDecode(consoleErrors);
      if ((data['errorCount'] as int? ?? 0) == 0) {
        passed++;
      } else {
        issues.add(Issue(
          id: 'bp_console_errors',
          title: 'Erreurs JavaScript détectées',
          description: 'Des erreurs JavaScript ont été détectées dans la console.',
          severity: IssueSeverity.warning,
          category: AuditCategory.bestPractices,
        ));
      }
    }

    // Vérifier les API obsolètes
    final deprecatedAPIs = await executeScript('''
      (function() {
        const deprecated = [];
        if (document.all) deprecated.push('document.all');
        if (document.write) deprecated.push('document.write potential');
        return JSON.stringify({ deprecated: deprecated });
      })();
    ''');

    total++;
    if (deprecatedAPIs != null) {
      final data = jsonDecode(deprecatedAPIs);
      final deprecatedList = data['deprecated'] as List<dynamic>? ?? [];
      if (deprecatedList.isEmpty) {
        passed++;
      } else {
        issues.add(Issue(
          id: 'bp_deprecated_apis',
          title: 'APIs obsolètes utilisées',
          description: 'Le site utilise des APIs JavaScript obsolètes.',
          severity: IssueSeverity.info,
          category: AuditCategory.bestPractices,
        ));
      }
    }

    // Vérifier le viewport
    final viewport = await executeScript('''
      (function() {
        const meta = document.querySelector('meta[name="viewport"]');
        return JSON.stringify({ hasViewport: !!meta, content: meta ? meta.content : null });
      })();
    ''');

    total++;
    if (viewport != null) {
      final data = jsonDecode(viewport);
      if (data['hasViewport'] == true) {
        passed++;
      } else {
        issues.add(Issue(
          id: 'bp_viewport',
          title: 'Meta viewport manquant',
          description: 'La balise meta viewport est absente.',
          severity: IssueSeverity.warning,
          category: AuditCategory.bestPractices,
          suggestedFixes: [
            Fix(
              id: 'fix_viewport',
              title: 'Ajouter la balise viewport',
              description: 'Ajoutez <meta name="viewport" content="width=device-width, initial-scale=1">',
              code: '<meta name="viewport" content="width=device-width, initial-scale=1">',
              effort: EffortLevel.minimal,
              canAutoFix: true,
            ),
          ],
        ));
      }
    }

    // Vérifier le doctype
    final doctype = await executeScript('''
      (function() {
        const doctype = document.doctype;
        return JSON.stringify({ 
          hasDoctype: !!doctype,
          name: doctype ? doctype.name : null
        });
      })();
    ''');

    total++;
    if (doctype != null) {
      final data = jsonDecode(doctype);
      if (data['hasDoctype'] == true && data['name'] == 'html') {
        passed++;
      } else {
        issues.add(Issue(
          id: 'bp_doctype',
          title: 'Doctype HTML5 manquant',
          description: 'Le document n\'a pas de doctype HTML5 correct.',
          severity: IssueSeverity.warning,
          category: AuditCategory.bestPractices,
        ));
      }
    }

    final score = total > 0 ? ((passed / total) * 100).round() : 0;

    return CategoryScore(
      category: AuditCategory.bestPractices,
      score: score,
      passedAudits: passed,
      totalAudits: total,
      issues: issues,
    );
  }

  /// Calcule le score global pondéré
  int _calculateOverallScore(Map<AuditCategory, CategoryScore> categoryScores) {
    if (categoryScores.isEmpty) return 0;

    double weightedSum = 0;
    double totalWeight = 0;

    for (final entry in categoryScores.entries) {
      final weight = entry.key.weight;
      weightedSum += entry.value.score * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? (weightedSum / totalWeight).round() : 0;
  }

  /// Met à jour la progression
  void _updateProgress(double progress, String step) {
    _analysisProgress = progress;
    _analysisStep = step;
    notifyListeners();
  }

  /// Ajoute un résultat à l'historique
  void _addToHistory(AuditResult result) {
    final entry = AuditHistoryEntry.fromAuditResult(result);
    _history.insert(0, entry);

    if (_history.length > _maxHistorySize) {
      _history.removeLast();
    }
  }

  /// Récupère l'historique pour une URL
  List<AuditHistoryEntry> getHistoryForUrl(String url) {
    return _history.where((h) => h.url == url).toList();
  }

  /// Vide l'historique
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Compare deux audits
  Map<String, dynamic> compareAudits(AuditResult a, AuditResult b) {
    return {
      'scoreDiff': b.overallScore - a.overallScore,
      'lcpDiff': (b.webVitals.lcp ?? 0) - (a.webVitals.lcp ?? 0),
      'fidDiff': (b.webVitals.fid ?? 0) - (a.webVitals.fid ?? 0),
      'clsDiff': (b.webVitals.cls ?? 0) - (a.webVitals.cls ?? 0),
      'issuesDiff': b.issues.length - a.issues.length,
      'timeDiff': b.timestamp.difference(a.timestamp),
    };
  }

  @override
  void dispose() {
    _historyService.dispose();
    _aiAdvisor.dispose();
    super.dispose();
  }
}

/// Résultat d'analyse d'une catégorie
class CategoryAnalysisResult {
  final CategoryScore categoryScore;
  final List<Issue> issues;
  final List<Recommendation> recommendations;

  CategoryAnalysisResult({
    required this.categoryScore,
    required this.issues,
    required this.recommendations,
  });
}

