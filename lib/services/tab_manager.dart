import 'package:flutter/foundation.dart';
import '../models/tab_model.dart';
import '../models/tab_group_model.dart';
import '../core/utils/url_validator.dart';
import 'storage_service.dart';
import 'tab_performance_manager.dart';

class TabManager extends ChangeNotifier {
  final List<TabModel> _tabs = [];
  final List<TabGroupModel> _groups = [];
  String? _activeTabId;
  final StorageService _storage = StorageService();
  final TabPerformanceManager _performanceManager = TabPerformanceManager();
  bool _isInitialized = false;
  final Map<String, String> _domainGroupMap = {};

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
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    // Load saved data
    final savedTabs = await _storage.loadTabs();
    final savedGroups = await _storage.loadGroups();
    final savedActiveTab = await _storage.loadActiveTab();

    if (savedTabs.isNotEmpty) {
      _tabs.addAll(savedTabs);
      if (savedActiveTab != null && _tabs.any((t) => t.id == savedActiveTab)) {
        _activeTabId = savedActiveTab;
        selectTab(savedActiveTab);
      } else if (_tabs.isNotEmpty) {
        selectTab(_tabs.first.id);
      }
    } else {
      // Create initial tab with home page if no saved data
      _createNewTab(url: 'about:newtab');
      if (_tabs.isNotEmpty) {
        _activeTabId = _tabs.first.id;
        selectTab(_tabs.first.id);
      }
    }

    if (savedGroups.isNotEmpty) {
      _groups.addAll(savedGroups);
    }

    _isInitialized = true;
    _autoGroupTabs();
    notifyListeners();
  }

  Future<void> _save() async {
    await Future.wait([
      _storage.saveTabs(_tabs),
      _storage.saveGroups(_groups),
      _storage.saveActiveTab(_activeTabId),
    ]);
  }

  TabModel _createNewTab({String? url, String? groupId}) {
    // Si pas d'URL, utiliser la page d'accueil
    final tabUrl = url ?? 'about:newtab';
    final tab = TabModel(
      url: tabUrl,
      groupId: groupId,
      state: (url != null && url != 'about:newtab' && url != 'about:blank') 
          ? TabState.loading 
          : TabState.blank,
    );
    _tabs.add(tab);
    notifyListeners();
    return tab;
  }

  TabModel createNewTab({String? url, String? groupId}) {
    // Deselect all tabs
    for (int i = 0; i < _tabs.length; i++) {
      _tabs[i] = _tabs[i].copyWith(isSelected: false);
    }
    
    final tab = _createNewTab(url: url, groupId: groupId);
    _activeTabId = tab.id;
    final index = _tabs.length - 1;
    _tabs[index] = _tabs[index].copyWith(isSelected: true);
    _autoGroupTabs();
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
        final newTab = _createNewTab(url: 'about:newtab');
        _activeTabId = newTab.id;
        selectTab(newTab.id);
      }
      
      _autoGroupTabs();
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
      _autoGroupTabs();
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
      _domainGroupMap.removeWhere((_, id) => id == groupId);
      notifyListeners();
    }
  }

  void _autoGroupTabs() {
    final Map<String, List<TabModel>> domainBuckets = {};
    for (final tab in _tabs) {
      final domain = UrlValidator.extractDomain(tab.url ?? '');
      if (domain == null || domain.isEmpty) continue;
      domainBuckets.putIfAbsent(domain, () => []).add(tab);
    }

    final Set<String> activeDomains = {};
    domainBuckets.forEach((domain, tabs) {
      if (tabs.length < 2) return;
      activeDomains.add(domain);
      final groupId = _domainGroupMap[domain] ?? _createDomainGroup(domain);
      _syncGroupAssignments(groupId, domain, tabs);
    });

    final List<String> domainsToRemove = [];
    _domainGroupMap.forEach((domain, groupId) {
      final tabs = domainBuckets[domain];
      if (tabs == null || tabs.length < 2) {
        _removeGroupAssignments(groupId);
        domainsToRemove.add(domain);
      }
    });

    for (final domain in domainsToRemove) {
      _domainGroupMap.remove(domain);
    }
  }

  String _createDomainGroup(String domain) {
    final group = TabGroupModel(
      name: _formatDomainName(domain),
      color: '#FF2D55',
    );
    _groups.add(group);
    _domainGroupMap[domain] = group.id;
    return group.id;
  }

  void _syncGroupAssignments(String groupId, String domain, List<TabModel> tabs) {
    final tabIds = tabs.map((t) => t.id).toList();
    final existingIndex = _groups.indexWhere((g) => g.id == groupId);
    final updatedGroup = existingIndex == -1
        ? TabGroupModel(
            id: groupId,
            name: _formatDomainName(domain),
            color: '#FF2D55',
            tabIds: tabIds,
          )
        : _groups[existingIndex].copyWith(
            tabIds: tabIds,
            name: _formatDomainName(domain),
          );

    if (existingIndex == -1) {
      _groups.add(updatedGroup);
    } else {
      _groups[existingIndex] = updatedGroup;
    }

    for (final tab in tabs) {
      final idx = _tabs.indexWhere((t) => t.id == tab.id);
      if (idx != -1) {
        _tabs[idx] = _tabs[idx].copyWith(groupId: groupId);
      }
    }
  }

  void _removeGroupAssignments(String groupId) {
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].groupId == groupId) {
        _tabs[i] = _tabs[i].copyWith(groupId: null);
      }
    }
    _groups.removeWhere((group) => group.id == groupId);
    _domainGroupMap.removeWhere((_, id) => id == groupId);
  }

  String _formatDomainName(String domain) {
    return domain.replaceFirst(RegExp(r'^www\.'), '');
  }
}

