import 'dart:collection';
import '../models/tab_model.dart';

/// Gestionnaire de performance pour optimiser les onglets
/// Implémente le lazy loading et la gestion mémoire
class TabPerformanceManager {
  // Cache des onglets actifs (max 10 onglets en mémoire)
  static const int _maxActiveTabs = 10;
  
  // Queue pour gérer les onglets récemment utilisés (LRU)
  final LinkedHashMap<String, TabModel> _activeTabsCache = LinkedHashMap();
  
  /// Marque un onglet comme actif (utilisé récemment)
  void markTabAsActive(String tabId, TabModel tab) {
    // Retirer de la cache si déjà présent
    _activeTabsCache.remove(tabId);
    
    // Ajouter au début
    _activeTabsCache[tabId] = tab;
    
    // Limiter la taille du cache
    if (_activeTabsCache.length > _maxActiveTabs) {
      // Supprimer le plus ancien (dernier dans la LinkedHashMap)
      final oldestKey = _activeTabsCache.keys.first;
      _activeTabsCache.remove(oldestKey);
    }
  }
  
  /// Retire un onglet du cache actif
  void removeTabFromCache(String tabId) {
    _activeTabsCache.remove(tabId);
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
    if (totalTabs > 50) {
      // Si beaucoup d'onglets, réduire le cache
      if (_activeTabsCache.length > 5) {
        clearInactiveTabs();
      }
    } else if (totalTabs > 20) {
      // Si nombre moyen d'onglets, garder un cache modéré
      if (_activeTabsCache.length > 8) {
        clearInactiveTabs();
      }
    }
    // Sinon, garder le cache normal
  }
}

