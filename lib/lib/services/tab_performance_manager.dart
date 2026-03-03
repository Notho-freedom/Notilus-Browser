import 'dart:collection';
import 'dart:async';
import '../models/tab_model.dart';

/// Gestionnaire de performance pour optimiser les onglets
/// Implémente le lazy loading et la gestion mémoire
class TabPerformanceManager {
  // Cache des onglets actifs (max 10 onglets en mémoire)
  static const int _maxActiveTabs = 10;
  
  // Queue pour gérer les onglets récemment utilisés (LRU)
  final LinkedHashMap<String, TabModel> _activeTabsCache = LinkedHashMap();
  
  // Poids mémoire estimés par onglet (en MB approximatifs)
  final Map<String, int> _tabMemoryWeights = {};
  
  // Timestamps de dernière utilisation pour dispose automatique
  final Map<String, DateTime> _tabLastUsed = {};
  
  // Timer pour le dispose automatique
  Timer? _cleanupTimer;
  
  // Callback pour suspendre/reprendre les WebViews
  Function(String tabId, bool suspend)? onSuspendTab;
  
  // Callback pour précharger un onglet
  Function(String tabId)? onPreloadTab;
  
  TabPerformanceManager() {
    // Démarrer le timer de nettoyage automatique
    _startCleanupTimer();
  }
  
  /// Marque un onglet comme actif (utilisé récemment)
  void markTabAsActive(String tabId, TabModel tab) {
    // Retirer de la cache si déjà présent
    _activeTabsCache.remove(tabId);
    
    // Ajouter au début (le plus récent)
    _activeTabsCache[tabId] = tab;
    
    // Mettre à jour le timestamp
    _tabLastUsed[tabId] = DateTime.now();
    
    // Estimer le poids mémoire basé sur l'URL et le type
    _tabMemoryWeights[tabId] = _estimateMemoryWeight(tab);
    
    // Reprendre le WebView si suspendu
    onSuspendTab?.call(tabId, false);
    
    // Limiter la taille du cache avec gestion intelligente des poids
    _enforceCacheLimit();
  }
  
  /// Estime le poids mémoire d'un onglet (en MB approximatifs)
  int _estimateMemoryWeight(TabModel tab) {
    int baseWeight = 10; // Base pour un WebView vide
    
    // Ajouter du poids selon le type
    if (tab.type == TabType.web) {
      baseWeight += 20; // WebView avec page chargée
      
      // Plus de poids pour les pages complexes
      if (tab.url != null && tab.url!.isNotEmpty) {
        if (tab.url!.contains('youtube.com') || 
            tab.url!.contains('netflix.com') ||
            tab.url!.contains('twitch.tv')) {
          baseWeight += 50; // Vidéos = beaucoup de mémoire
        } else if (tab.url!.contains('github.com') ||
                   tab.url!.contains('stackoverflow.com')) {
          baseWeight += 15; // Pages avec beaucoup de contenu
        }
      }
    } else if (tab.type == TabType.terminal) {
      baseWeight += 5; // Terminal = moins de mémoire
    }
    
    return baseWeight;
  }
  
  /// Applique la limite de cache avec gestion intelligente des poids
  void _enforceCacheLimit() {
    if (_activeTabsCache.length <= _maxActiveTabs) {
      return;
    }
    
    // Calculer le poids total
    int totalWeight = _tabMemoryWeights.values.fold(0, (a, b) => a + b);
    
    // Si le poids total est acceptable, garder les onglets
    // Sinon, supprimer les plus anciens jusqu'à ce que le poids soit acceptable
    while (_activeTabsCache.length > _maxActiveTabs || totalWeight > 200) {
      // Supprimer le plus ancien (premier dans LinkedHashMap = le moins récent)
      if (_activeTabsCache.isEmpty) break;
      
      final oldestKey = _activeTabsCache.keys.first;
      final weight = _tabMemoryWeights.remove(oldestKey) ?? 0;
      totalWeight -= weight;
      _activeTabsCache.remove(oldestKey);
      _tabLastUsed.remove(oldestKey);
      
      // Suspendre le WebView au lieu de le détruire
      onSuspendTab?.call(oldestKey, true);
    }
  }
  
  /// Retire un onglet du cache actif
  void removeTabFromCache(String tabId) {
    _activeTabsCache.remove(tabId);
    _tabMemoryWeights.remove(tabId);
    _tabLastUsed.remove(tabId);
  }
  
  /// Vérifie si un onglet est dans le cache actif
  bool isTabActive(String tabId) {
    return _activeTabsCache.containsKey(tabId);
  }
  
  /// Nettoie le cache des onglets inactifs
  void clearInactiveTabs() {
    // Garder seulement les 5 onglets les plus récents
    if (_activeTabsCache.length > 5) {
      final keysToRemove = _activeTabsCache.keys.take(
        _activeTabsCache.length - 5
      ).toList();
      for (final key in keysToRemove) {
        _activeTabsCache.remove(key);
      }
    }
  }
  
  /// Retourne la liste des onglets actifs
  List<String> getActiveTabIds() {
    return _activeTabsCache.keys.toList();
  }
  
  /// Retourne le nombre d'onglets en cache
  int getCacheSize() {
    return _activeTabsCache.length;
  }
  
  /// Vide complètement le cache
  void clearCache() {
    _activeTabsCache.clear();
  }
  
  /// Optimise la mémoire en fonction du nombre d'onglets
  void optimizeMemory(int totalTabs) {
    // Ajuster la limite dynamiquement
    int maxCache;
    if (totalTabs > 50) {
      maxCache = 5;
    } else if (totalTabs > 20) {
      maxCache = 8;
    } else {
      maxCache = _maxActiveTabs;
    }
    
    // Réduire le cache si nécessaire
    while (_activeTabsCache.length > maxCache) {
      final oldestKey = _activeTabsCache.keys.first;
      final weight = _tabMemoryWeights.remove(oldestKey) ?? 0;
      _activeTabsCache.remove(oldestKey);
      _tabLastUsed.remove(oldestKey);
      onSuspendTab?.call(oldestKey, true);
    }
  }
  
  /// Suspend les onglets inactifs
  void suspendInactiveTabs(List<String> activeTabIds) {
    final inactiveTabs = _activeTabsCache.keys
        .where((id) => !activeTabIds.contains(id))
        .toList();
    
    for (final tabId in inactiveTabs) {
      onSuspendTab?.call(tabId, true);
    }
  }
  
  /// Précharge les onglets suivants dans l'historique
  void preloadNextTabs(String currentTabId, List<TabModel> tabs) {
    final currentIndex = tabs.indexWhere((t) => t.id == currentTabId);
    if (currentIndex == -1) return;
    
    // Précharger les 2-3 onglets suivants
    final preloadCount = 3;
    for (int i = 1; i <= preloadCount && currentIndex + i < tabs.length; i++) {
      final nextTab = tabs[currentIndex + i];
      if (!_activeTabsCache.containsKey(nextTab.id)) {
        onPreloadTab?.call(nextTab.id);
      }
    }
  }
  
  /// Démarre le timer de nettoyage automatique
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupInactiveTabs();
    });
  }
  
  /// Nettoie les onglets inactifs depuis plus de 5 minutes
  void _cleanupInactiveTabs() {
    final now = DateTime.now();
    final inactiveThreshold = const Duration(minutes: 5);
    
    final tabsToCleanup = _tabLastUsed.entries
        .where((entry) => now.difference(entry.value) > inactiveThreshold)
        .map((entry) => entry.key)
        .toList();
    
    for (final tabId in tabsToCleanup) {
      // Suspendre au lieu de supprimer complètement
      onSuspendTab?.call(tabId, true);
      
      // Retirer du cache actif mais garder les métadonnées
      _activeTabsCache.remove(tabId);
    }
  }
  
  /// Dispose les ressources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _activeTabsCache.clear();
    _tabMemoryWeights.clear();
    _tabLastUsed.clear();
  }
}

