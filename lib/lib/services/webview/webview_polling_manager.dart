import 'dart:async';
import 'package:flutter/foundation.dart';

/// Gestionnaire de polling centralisé pour le WebView
/// Gère les différents timers de polling avec des intervalles configurables
class WebViewPollingManager {
  final Map<String, Timer> _timers = {};
  final Map<String, int> _tickCounts = {};
  bool _isActive = true;
  
  /// Intervalles par défaut (en millisecondes)
  static const int defaultTextSelectionInterval = 200;
  static const int defaultContextMenuInterval = 200;
  static const int defaultDownloadInterval = 500;
  static const int defaultNewWindowInterval = 500;
  static const int defaultAdBlockerInterval = 2000;
  
  /// Intervalles en mode inactif (plus lents pour économiser les ressources)
  static const int inactiveIntervalMultiplier = 5;
  
  /// Limite maximale de ticks avant arrêt automatique
  static const int maxTicksBeforeTimeout = 3000; // ~10 minutes à 200ms
  
  /// Démarre un timer de polling
  void startPolling({
    required String key,
    required Duration interval,
    required Future<void> Function() callback,
    int? maxTicks,
  }) {
    stopPolling(key);
    
    _tickCounts[key] = 0;
    final effectiveMaxTicks = maxTicks ?? maxTicksBeforeTimeout;
    
    _timers[key] = Timer.periodic(
      _isActive ? interval : interval * inactiveIntervalMultiplier,
      (timer) async {
        _tickCounts[key] = (_tickCounts[key] ?? 0) + 1;
        
        // Vérifier le timeout
        if (_tickCounts[key]! >= effectiveMaxTicks) {
          debugPrint('⏱️ Polling "$key" arrêté après timeout');
          stopPolling(key);
          return;
        }
        
        try {
          await callback();
        } catch (e) {
          debugPrint('❌ Erreur dans le polling "$key": $e');
        }
      },
    );
    
    debugPrint('▶️ Polling "$key" démarré (intervalle: ${interval.inMilliseconds}ms)');
  }
  
  /// Arrête un timer de polling spécifique
  void stopPolling(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
    _tickCounts.remove(key);
  }
  
  /// Arrête tous les timers de polling
  void stopAllPolling() {
    for (final key in _timers.keys.toList()) {
      stopPolling(key);
    }
    debugPrint('⏹️ Tous les pollings arrêtés');
  }
  
  /// Définit l'état actif/inactif (ralentit les pollings en mode inactif)
  void setActive(bool isActive) {
    if (_isActive == isActive) return;
    _isActive = isActive;
    
    // Redémarrer les timers avec le nouvel intervalle
    // Note: Les callbacks actuels seront perdus, donc cette méthode
    // devrait être appelée avec précaution
    debugPrint('🔄 Mode polling changé: ${isActive ? "actif" : "inactif"}');
  }
  
  /// Vérifie si un polling est actif
  bool isPollingActive(String key) => _timers.containsKey(key);
  
  /// Obtient le nombre de ticks pour un polling
  int getTickCount(String key) => _tickCounts[key] ?? 0;
  
  /// Réinitialise le compteur de ticks pour un polling
  void resetTickCount(String key) {
    _tickCounts[key] = 0;
  }
  
  /// Dispose de toutes les ressources
  void dispose() {
    stopAllPolling();
  }
}

/// Clés de polling prédéfinies
class PollingKeys {
  static const String textSelection = 'text_selection';
  static const String contextMenu = 'context_menu';
  static const String downloads = 'downloads';
  static const String newWindow = 'new_window';
  static const String adBlocker = 'ad_blocker';
}

