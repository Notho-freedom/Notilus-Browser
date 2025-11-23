import 'package:flutter/foundation.dart';
import '../models/tab_model.dart';
import '../models/tab_group_model.dart';
import 'storage_service.dart';
import 'tab_performance_manager.dart';

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
  TabModel? get activeTab => _tabs.firstWhere(
        (tab) => tab.id == _activeTabId,
        orElse: () => TabModel(),
      );

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
      // Create initial blank tab if no saved data
      _createNewTab();
    }

    if (savedGroups.isNotEmpty) {
      _groups.addAll(savedGroups);
    }

    _isInitialized = true;
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
    final tab = TabModel(
      url: url,
      groupId: groupId,
      state: url != null ? TabState.loading : TabState.blank,
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
    notifyListeners();
    _save();
    return _tabs[index];
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
        _createNewTab();
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
    }
  }
}

