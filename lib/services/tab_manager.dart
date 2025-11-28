import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/tab_model.dart';
import '../models/tab_group_model.dart';
import 'storage_service.dart';
import 'tab_performance_manager.dart';
import 'tab_grouping_service.dart';

class TabManager extends ChangeNotifier {
  final List<TabModel> _tabs = [];
  final List<TabGroupModel> _groups = [];
  String? _activeTabId;
  final StorageService _storage = StorageService();
  final TabPerformanceManager _performanceManager = TabPerformanceManager();
  bool _isInitialized = false;

  List<TabModel> get tabs => List.unmodifiable(_tabs);
  List<TabGroupModel> get groups => List.unmodifiable(_groups);
  String? get activeTabId => _activeTabId;
  TabModel? get activeTab {
    if (_tabs.isEmpty) return null;
    if (_activeTabId == null) {
      return _tabs.first;
    }
    try {
      return _tabs.firstWhere((tab) => tab.id == _activeTabId);
    } catch (_) {
      return _tabs.first;
    }
  }

  TabManager() {
    // Initialiser de manière asynchrone après le premier frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
    // Configurer les callbacks de performance
    _performanceManager.onSuspendTab = (tabId, suspend) {
      // Le TabWebViewManager gérera la suspension
    };
    _performanceManager.onPreloadTab = (tabId) {
      // Le TabWebViewManager gérera le préchargement
    };
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    // Load saved data
    final savedTabs = await _storage.loadTabs();
    final savedGroups = await _storage.loadGroups();
    final savedActiveTab = await _storage.loadActiveTab();

    if (savedTabs.isNotEmpty) {
      _tabs.addAll(savedTabs);
      // Précharger uniquement l'onglet actif au démarrage
      if (savedActiveTab != null && _tabs.any((t) => t.id == savedActiveTab)) {
        _activeTabId = savedActiveTab;
        // Sélectionner sans sauvegarder immédiatement (évite les I/O au démarrage)
        _selectTabWithoutSave(savedActiveTab);
      } else if (_tabs.isNotEmpty) {
        _selectTabWithoutSave(_tabs.first.id);
      }
    } else {
      // Create initial tab with home page if no saved data
      _createNewTab(url: 'about:newtab');
      if (_tabs.isNotEmpty) {
        _activeTabId = _tabs.first.id;
        _selectTabWithoutSave(_tabs.first.id);
      }
    }

    if (savedGroups.isNotEmpty) {
      _groups.addAll(savedGroups);
    }

    _isInitialized = true;
    notifyListeners();
    
    // Sauvegarder après un délai pour éviter les I/O au démarrage
    Future.delayed(const Duration(seconds: 2), () {
      _save();
    });
  }
  
  /// Sélectionne un onglet sans sauvegarder (pour le démarrage)
  void _selectTabWithoutSave(String tabId) {
    // Deselect all tabs
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].id != tabId) {
        _tabs[i] = _tabs[i].copyWith(isSelected: false);
      }
    }
    
    // Select the new tab
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(isSelected: true);
      _activeTabId = tabId;
      
      // Marquer comme actif pour la performance
      _performanceManager.markTabAsActive(tabId, _tabs[index]);
      _performanceManager.optimizeMemory(_tabs.length);
      
      notifyListeners();
      // Pas de _save() ici pour accélérer le démarrage
    }
  }

  Future<void> _save() async {
    // Utiliser les méthodes debounced pour optimiser les performances
    await Future.wait([
      _storage.saveTabsDebounced(_tabs),
      _storage.saveGroupsDebounced(_groups),
      _storage.saveActiveTabDebounced(_activeTabId),
    ]);
  }
  
  /// Sauvegarde immédiate (pour les cas critiques comme la fermeture de l'app)
  Future<void> saveImmediately() async {
    await Future.wait([
      _storage.saveTabs(_tabs),
      _storage.saveGroups(_groups),
      _storage.saveActiveTab(_activeTabId),
    ]);
  }

  TabModel _createNewTab({String? url, String? groupId, TabType? type}) {
    // Si pas d'URL, utiliser la page d'accueil
    final tabUrl = url ?? 'about:newtab';
    final tabType = type ?? TabType.web;
    final tab = TabModel(
      url: tabUrl,
      groupId: groupId,
      type: tabType,
      state: (tabType == TabType.terminal)
          ? TabState.loaded
          : (url != null && url != 'about:newtab' && url != 'about:blank') 
              ? TabState.loading 
              : TabState.blank,
    );
    _tabs.add(tab);
    notifyListeners();
    return tab;
  }

  TabModel createNewTab({String? url, String? groupId, TabType? type}) {
    // Deselect all tabs
    for (int i = 0; i < _tabs.length; i++) {
      _tabs[i] = _tabs[i].copyWith(isSelected: false);
    }
    
    final tab = _createNewTab(url: url, groupId: groupId, type: type);
    _activeTabId = tab.id;
    final index = _tabs.length - 1;
    _tabs[index] = _tabs[index].copyWith(isSelected: true);
    notifyListeners();
    _save();
    return _tabs[index];
  }

  /// Ajoute un nouvel onglet avec une URL (alias pour createNewTab)
  TabModel addTab({String? url, String? groupId}) {
    return createNewTab(url: url, groupId: groupId);
  }

  void selectTab(String tabId) {
    // Deselect all tabs
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].id != tabId) {
        _tabs[i] = _tabs[i].copyWith(isSelected: false);
      }
    }
    
    // Select the new tab
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(isSelected: true);
      _activeTabId = tabId;
      
      // Marquer comme actif pour la performance
      _performanceManager.markTabAsActive(tabId, _tabs[index]);
      _performanceManager.optimizeMemory(_tabs.length);
      
      notifyListeners();
      _save();
    }
  }

  void closeTab(String tabId) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      final wasActive = _tabs[index].isSelected;
      
      // Retirer du cache de performance
      _performanceManager.removeTabFromCache(tabId);
      
      _tabs.removeAt(index);
      
      // If we closed the active tab, select another one
      if (wasActive && _tabs.isNotEmpty) {
        final newIndex = index < _tabs.length ? index : _tabs.length - 1;
        selectTab(_tabs[newIndex].id);
      } else if (_tabs.isEmpty) {
        // Recréer un onglet d'accueil et le sélectionner
        final newTab = _createNewTab(url: 'about:newtab', type: TabType.web);
        _activeTabId = newTab.id;
        selectTab(newTab.id);
      }
      
      notifyListeners();
      _save();
    }
  }

  void updateTab(String tabId, {
    String? url,
    String? title,
    String? favicon,
    TabState? state,
  }) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(
        url: url,
        title: title,
        favicon: favicon,
        state: state,
      );
      notifyListeners();
      _save();
    }
  }

  void pinTab(String tabId) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(isPinned: !_tabs[index].isPinned);
      notifyListeners();
    }
  }

  TabModel? duplicateTab(String tabId) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      final originalTab = _tabs[index];
      final newTab = TabModel(
        url: originalTab.url,
        title: originalTab.title,
        favicon: originalTab.favicon,
        state: originalTab.state,
        groupId: originalTab.groupId,
      );
      _tabs.insert(index + 1, newTab);
      selectTab(newTab.id);
      notifyListeners();
      return newTab;
    }
    return null;
  }

  // Tab Groups
  TabGroupModel createGroup(String name, String color, {String? icon}) {
    final group = TabGroupModel(
      name: name,
      color: color,
      icon: icon,
    );
    _groups.add(group);
    notifyListeners();
    _save();
    return group;
  }

  void addTabToGroup(String tabId, String groupId) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    
    if (tabIndex != -1 && groupIndex != -1) {
      _tabs[tabIndex] = _tabs[tabIndex].copyWith(groupId: groupId);
      if (!_groups[groupIndex].tabIds.contains(tabId)) {
        _groups[groupIndex] = TabGroupModel(
          id: _groups[groupIndex].id,
          name: _groups[groupIndex].name,
          color: _groups[groupIndex].color,
          icon: _groups[groupIndex].icon,
          tabIds: [..._groups[groupIndex].tabIds, tabId],
          createdAt: _groups[groupIndex].createdAt,
          isCollapsed: _groups[groupIndex].isCollapsed,
        );
        notifyListeners();
      }
    }
  }

  void removeTabFromGroup(String tabId) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex != -1) {
      final groupId = _tabs[tabIndex].groupId;
      if (groupId != null) {
        _tabs[tabIndex] = _tabs[tabIndex].copyWith(groupId: null);
        final groupIndex = _groups.indexWhere((group) => group.id == groupId);
        if (groupIndex != -1) {
          _groups[groupIndex] = TabGroupModel(
            id: _groups[groupIndex].id,
            name: _groups[groupIndex].name,
            color: _groups[groupIndex].color,
            icon: _groups[groupIndex].icon,
            tabIds: _groups[groupIndex].tabIds.where((id) => id != tabId).toList(),
            createdAt: _groups[groupIndex].createdAt,
            isCollapsed: _groups[groupIndex].isCollapsed,
          );
          notifyListeners();
        }
      }
    }
  }

  void deleteGroup(String groupId) {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index != -1) {
      // Remove group from all tabs
      for (int i = 0; i < _tabs.length; i++) {
        if (_tabs[i].groupId == groupId) {
          _tabs[i] = _tabs[i].copyWith(groupId: null);
        }
      }
      _groups.removeAt(index);
      notifyListeners();
      _save();
    }
  }

  // Gestion automatique des groupes
  void autoGroupTabs() {
    // Utiliser la version synchrone pour compatibilité
    // Pour de grandes listes, utiliser autoGroupTabsAsync()
    final suggestions = TabGroupingService.suggestGroups(_tabs);
    _applyGroupSuggestions(suggestions);
  }
  
  /// Version asynchrone avec compute() pour grandes listes
  Future<void> autoGroupTabsAsync() async {
    if (_tabs.length < 50) {
      // Pour petites listes, utiliser la version synchrone
      autoGroupTabs();
      return;
    }
    
    // Pour grandes listes, utiliser compute() dans un isolate
    final suggestions = await TabGroupingService.suggestGroupsAsync(_tabs);
    _applyGroupSuggestions(suggestions);
  }
  
  /// Applique les suggestions de groupes
  void _applyGroupSuggestions(List<TabGroupSuggestion> suggestions) {
    for (final suggestion in suggestions) {
      // Vérifier si un groupe avec ce nom existe déjà
      var existingGroup = _groups.firstWhere(
        (g) => g.name == suggestion.name,
        orElse: () => TabGroupModel(name: '', color: '#FF2D55'),
      );
      
      if (existingGroup.name.isEmpty) {
        // Créer un nouveau groupe
        existingGroup = createGroup(
          suggestion.name,
          '#${suggestion.color.value.toRadixString(16).substring(2)}',
        );
      }
      
      // Ajouter les tabs au groupe
      for (final tabId in suggestion.tabIds) {
        if (!existingGroup.tabIds.contains(tabId)) {
          addTabToGroup(tabId, existingGroup.id);
        }
      }
    }
    
    notifyListeners();
  }

  // Détecter et gérer les doublons
  void handleDuplicates() {
    final duplicates = TabGroupingService.findDuplicates(_tabs);
    
    for (final dupGroup in duplicates) {
      if (dupGroup.length > 1) {
        // Garder le premier, fermer les autres
        for (int i = 1; i < dupGroup.length; i++) {
          closeTab(dupGroup[i].id);
        }
      }
    }
  }

  // Réorganiser les tabs (pour drag-and-drop)
  void reorderTab(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final tab = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, tab);
    notifyListeners();
    _save();
  }
}

