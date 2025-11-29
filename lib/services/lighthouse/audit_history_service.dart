/// Service de gestion de l'historique des audits Lighthouse
/// Gère la persistance et la détection de régressions
library audit_history_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/lighthouse/audit_models.dart';

/// Service de gestion de l'historique des audits
class AuditHistoryService extends ChangeNotifier {
  static const String _historyKey = 'lighthouse_audit_history';
  static const int _maxHistorySize = 500; // Limite d'historique

  List<AuditHistoryEntry> _history = [];
  bool _isLoading = false;

  AuditHistoryService() {
    _loadHistory();
  }

  // Getters
  List<AuditHistoryEntry> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  /// Charge l'historique depuis le stockage local
  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonString = prefs.getString(_historyKey);

      if (historyJsonString != null) {
        final List<dynamic> historyJson = jsonDecode(historyJsonString);
        _history = historyJson
            .map((json) => AuditHistoryEntry.fromJson(json as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Plus récent en premier
      }
    } catch (e) {
      debugPrint('Error loading audit history: $e');
      _history = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sauvegarde l'historique dans le stockage local
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _history.map((entry) => entry.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
    } catch (e) {
      debugPrint('Error saving audit history: $e');
    }
  }

  /// Ajoute une entrée à l'historique
  Future<void> addEntry(AuditHistoryEntry entry) async {
    // Supprimer les entrées existantes pour la même URL et le même timestamp (éviter doublons)
    _history.removeWhere((e) => e.id == entry.id);

    // Ajouter au début
    _history.insert(0, entry);

    // Limiter la taille
    if (_history.length > _maxHistorySize) {
      _history = _history.take(_maxHistorySize).toList();
    }

    await _saveHistory();
    notifyListeners();
  }

  /// Récupère l'historique pour une URL spécifique
  List<AuditHistoryEntry> getHistoryForUrl(String url) {
    return _history.where((entry) => entry.url == url).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Récupère l'historique pour une période
  List<AuditHistoryEntry> getHistoryForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = _history;

    if (startDate != null) {
      filtered = filtered.where((e) => e.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      filtered = filtered.where((e) => e.timestamp.isBefore(endDate)).toList();
    }

    return filtered;
  }

  /// Détecte les régressions pour une URL
  List<Regression> detectRegressions(String url) {
    final urlHistory = getHistoryForUrl(url);
    if (urlHistory.length < 2) return [];

    final regressions = <Regression>[];

    for (var i = 1; i < urlHistory.length; i++) {
      final previous = urlHistory[i - 1];
      final current = urlHistory[i];

      // Régression de score (baisse de plus de 5 points)
      if (current.score < previous.score - 5) {
        regressions.add(Regression(
          id: 'regression_${current.id}_score',
          type: RegressionType.score,
          severity: _calculateRegressionSeverity(
            previous.score.toDouble(),
            current.score.toDouble(),
            5.0,
          ),
          previousValue: previous.score.toDouble(),
          currentValue: current.score.toDouble(),
          timestamp: current.timestamp,
          url: url,
          description: 'Score global en baisse de ${previous.score} à ${current.score}',
        ));
      }

      // Régression LCP (augmentation de plus de 500ms)
      if (current.webVitals.lcp != null &&
          previous.webVitals.lcp != null &&
          current.webVitals.lcp! > previous.webVitals.lcp! + 500) {
        regressions.add(Regression(
          id: 'regression_${current.id}_lcp',
          type: RegressionType.lcp,
          severity: _calculateRegressionSeverity(
            previous.webVitals.lcp!,
            current.webVitals.lcp!,
            500,
          ),
          previousValue: previous.webVitals.lcp!,
          currentValue: current.webVitals.lcp!,
          timestamp: current.timestamp,
          url: url,
          description:
              'LCP en hausse de ${previous.webVitals.lcp!.toStringAsFixed(0)}ms à ${current.webVitals.lcp!.toStringAsFixed(0)}ms',
        ));
      }

      // Régression CLS (augmentation de plus de 0.1)
      if (current.webVitals.cls != null &&
          previous.webVitals.cls != null &&
          current.webVitals.cls! > previous.webVitals.cls! + 0.1) {
        regressions.add(Regression(
          id: 'regression_${current.id}_cls',
          type: RegressionType.cls,
          severity: _calculateRegressionSeverity(
            previous.webVitals.cls!,
            current.webVitals.cls!,
            0.1,
          ),
          previousValue: previous.webVitals.cls!,
          currentValue: current.webVitals.cls!,
          timestamp: current.timestamp,
          url: url,
          description:
              'CLS en hausse de ${previous.webVitals.cls!.toStringAsFixed(3)} à ${current.webVitals.cls!.toStringAsFixed(3)}',
        ));
      }

      // Régression du nombre d'issues (augmentation de plus de 3)
      if (current.issueCount > previous.issueCount + 3) {
        regressions.add(Regression(
          id: 'regression_${current.id}_issues',
          type: RegressionType.issues,
          severity: _calculateRegressionSeverity(
            previous.issueCount.toDouble(),
            current.issueCount.toDouble(),
            3.0,
          ),
          previousValue: previous.issueCount.toDouble(),
          currentValue: current.issueCount.toDouble(),
          timestamp: current.timestamp,
          url: url,
          description:
              'Nombre d\'issues en hausse de ${previous.issueCount} à ${current.issueCount}',
        ));
      }
    }

    return regressions;
  }

  /// Calcule la sévérité d'une régression
  RegressionSeverity _calculateRegressionSeverity(
    double previous,
    double current,
    double threshold,
  ) {
    final diff = (current - previous).abs();
    final ratio = diff / threshold;

    if (ratio >= 2.0) return RegressionSeverity.critical;
    if (ratio >= 1.5) return RegressionSeverity.high;
    if (ratio >= 1.0) return RegressionSeverity.medium;
    return RegressionSeverity.low;
  }

  /// Récupère les statistiques de tendances pour une URL
  TrendStats getTrendStats(String url) {
    final urlHistory = getHistoryForUrl(url);
    if (urlHistory.isEmpty) {
      return TrendStats(
        url: url,
        totalAudits: 0,
        averageScore: 0,
        scoreTrend: TrendDirection.stable,
        lcpTrend: TrendDirection.stable,
        clsTrend: TrendDirection.stable,
        issuesTrend: TrendDirection.stable,
      );
    }

    // Calculer la moyenne des scores
    final averageScore = urlHistory.map((e) => e.score).reduce((a, b) => a + b) /
        urlHistory.length;

    // Calculer les tendances
    final scoreTrend = _calculateTrend(
      urlHistory.map((e) => e.score.toDouble()).toList(),
    );
    final lcpTrend = _calculateTrend(
      urlHistory
          .where((e) => e.webVitals.lcp != null)
          .map((e) => e.webVitals.lcp!)
          .toList(),
      isLowerBetter: true,
    );
    final clsTrend = _calculateTrend(
      urlHistory
          .where((e) => e.webVitals.cls != null)
          .map((e) => e.webVitals.cls!)
          .toList(),
      isLowerBetter: true,
    );
    final issuesTrend = _calculateTrend(
      urlHistory.map((e) => e.issueCount.toDouble()).toList(),
      isLowerBetter: true,
    );

    return TrendStats(
      url: url,
      totalAudits: urlHistory.length,
      averageScore: averageScore.round(),
      scoreTrend: scoreTrend,
      lcpTrend: lcpTrend,
      clsTrend: clsTrend,
      issuesTrend: issuesTrend,
    );
  }

  /// Calcule la tendance d'une série de valeurs
  TrendDirection _calculateTrend(
    List<double> values, {
    bool isLowerBetter = false,
  }) {
    if (values.length < 2) return TrendDirection.stable;

    // Prendre les 30% premiers et derniers pour comparer
    final startCount = (values.length * 0.3).ceil();
    final endCount = (values.length * 0.3).ceil();

    final startValues = values.take(startCount);
    final endValues = values.skip(values.length - endCount);

    final startAvg = startValues.reduce((a, b) => a + b) / startValues.length;
    final endAvg = endValues.reduce((a, b) => a + b) / endValues.length;

    final diff = endAvg - startAvg;
    final threshold = (startAvg * 0.05).abs(); // 5% de variation

    if (diff.abs() < threshold) return TrendDirection.stable;

    if (isLowerBetter) {
      return diff < 0 ? TrendDirection.improving : TrendDirection.degrading;
    } else {
      return diff > 0 ? TrendDirection.improving : TrendDirection.degrading;
    }
  }

  /// Supprime l'historique pour une URL
  Future<void> clearHistoryForUrl(String url) async {
    _history.removeWhere((e) => e.url == url);
    await _saveHistory();
    notifyListeners();
  }

  /// Vide tout l'historique
  Future<void> clearAllHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  /// Exporte l'historique en JSON
  String exportHistoryAsJson() {
    return jsonEncode(_history.map((e) => e.toJson()).toList());
  }

  /// Importe l'historique depuis JSON
  Future<void> importHistoryFromJson(String jsonString) async {
    try {
      final List<dynamic> historyJson = jsonDecode(jsonString);
      final imported = historyJson
          .map((json) => AuditHistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      _history.addAll(imported);
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (_history.length > _maxHistorySize) {
        _history = _history.take(_maxHistorySize).toList();
      }

      await _saveHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing audit history: $e');
    }
  }
}

/// Type de régression
enum RegressionType {
  score,
  lcp,
  cls,
  issues,
}

/// Sévérité de régression
enum RegressionSeverity {
  low,
  medium,
  high,
  critical,
}

/// Direction de tendance
enum TrendDirection {
  improving,
  stable,
  degrading,
}

/// Régression détectée
class Regression {
  final String id;
  final RegressionType type;
  final RegressionSeverity severity;
  final double previousValue;
  final double currentValue;
  final DateTime timestamp;
  final String url;
  final String description;

  Regression({
    required this.id,
    required this.type,
    required this.severity,
    required this.previousValue,
    required this.currentValue,
    required this.timestamp,
    required this.url,
    required this.description,
  });
}

/// Statistiques de tendances
class TrendStats {
  final String url;
  final int totalAudits;
  final int averageScore;
  final TrendDirection scoreTrend;
  final TrendDirection lcpTrend;
  final TrendDirection clsTrend;
  final TrendDirection issuesTrend;

  TrendStats({
    required this.url,
    required this.totalAudits,
    required this.averageScore,
    required this.scoreTrend,
    required this.lcpTrend,
    required this.clsTrend,
    required this.issuesTrend,
  });
}

