import 'dart:async';
import 'package:flutter/foundation.dart';

/// Métriques de performance pour un onglet
class PerformanceMetrics {
  final Duration loadTime;
  final DateTime loadTimestamp;
  final int? memoryUsageMB;
  
  PerformanceMetrics({
    required this.loadTime,
    required this.loadTimestamp,
    this.memoryUsageMB,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'loadTime': loadTime.inMilliseconds,
      'loadTimestamp': loadTimestamp.toIso8601String(),
      'memoryUsageMB': memoryUsageMB,
    };
  }
}

/// Moniteur de performance pour tracker les métriques et alerter sur la mémoire
class PerformanceMonitor {
  final Map<String, PerformanceMetrics> _metrics = {};
  Timer? _memoryCheckTimer;
  
  // Seuil d'alerte mémoire (80%)
  static const double _memoryAlertThreshold = 0.8;
  
  // Callback pour les alertes
  Function(String message)? onMemoryAlert;
  Function(String tabId, PerformanceMetrics metrics)? onTabLoadTracked;
  
  PerformanceMonitor() {
    _startMemoryMonitoring();
  }
  
  /// Track le temps de chargement d'un onglet
  void trackTabLoad(String tabId, Duration loadTime, {int? memoryUsageMB}) {
    final metrics = PerformanceMetrics(
      loadTime: loadTime,
      loadTimestamp: DateTime.now(),
      memoryUsageMB: memoryUsageMB,
    );
    
    _metrics[tabId] = metrics;
    onTabLoadTracked?.call(tabId, metrics);
    
    debugPrint('📊 Performance tracked: Tab $tabId loaded in ${loadTime.inMilliseconds}ms');
  }
  
  /// Récupère les métriques d'un onglet
  PerformanceMetrics? getMetrics(String tabId) {
    return _metrics[tabId];
  }
  
  /// Récupère toutes les métriques
  Map<String, PerformanceMetrics> get allMetrics => Map.unmodifiable(_metrics);
  
  /// Vérifie la pression mémoire et déclenche des alertes
  void checkMemoryPressure() {
    // Estimation basée sur le nombre d'onglets et leur utilisation mémoire
    final totalMemory = _estimateTotalMemory();
    final memoryUsage = totalMemory / _estimateAvailableMemory();
    
    if (memoryUsage > _memoryAlertThreshold) {
      final message = '⚠️ Utilisation mémoire élevée: ${(memoryUsage * 100).toStringAsFixed(1)}%';
      debugPrint(message);
      onMemoryAlert?.call(message);
      
      // Suggérer un nettoyage
      _suggestMemoryCleanup();
    }
  }
  
  /// Estime la mémoire totale utilisée (en MB)
  int _estimateTotalMemory() {
    int total = 0;
    for (final metrics in _metrics.values) {
      total += metrics.memoryUsageMB ?? 50; // 50MB par défaut par onglet
    }
    return total;
  }
  
  /// Estime la mémoire disponible (en MB)
  /// Pour Windows, estimation basée sur 8GB par défaut
  int _estimateAvailableMemory() {
    // TODO: Utiliser un package pour obtenir la RAM réelle
    return 8192; // 8GB en MB
  }
  
  /// Suggère un nettoyage de mémoire
  void _suggestMemoryCleanup() {
    debugPrint('💡 Suggestion: Fermer les onglets inactifs ou vider le cache');
  }
  
  /// Démarre le monitoring de la mémoire
  void _startMemoryMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkMemoryPressure();
    });
  }
  
  /// Retire les métriques d'un onglet
  void removeMetrics(String tabId) {
    _metrics.remove(tabId);
  }
  
  /// Nettoie toutes les métriques
  void clearMetrics() {
    _metrics.clear();
  }
  
  /// Retourne les statistiques de performance
  Map<String, dynamic> getStatistics() {
    if (_metrics.isEmpty) {
      return {
        'totalTabs': 0,
        'averageLoadTime': 0,
        'totalMemoryMB': 0,
      };
    }
    
    final loadTimes = _metrics.values.map((m) => m.loadTime.inMilliseconds).toList();
    final averageLoadTime = loadTimes.reduce((a, b) => a + b) / loadTimes.length;
    final totalMemory = _estimateTotalMemory();
    
    return {
      'totalTabs': _metrics.length,
      'averageLoadTime': averageLoadTime.round(),
      'totalMemoryMB': totalMemory,
      'memoryUsagePercent': (totalMemory / _estimateAvailableMemory() * 100).toStringAsFixed(1),
    };
  }
  
  /// Dispose les ressources
  void dispose() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
    _metrics.clear();
  }
}

