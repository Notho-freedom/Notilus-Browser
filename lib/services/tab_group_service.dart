import 'dart:math';
import 'package:flutter/foundation.dart';
import 'tab_manager.dart';
import '../models/tab_model.dart';

/// Modèle pour un groupe d'onglets
class TabGroup {
  final String id;
  final String domain;
  final String displayName;
  final int colorCode; // Code couleur pour le domaine
  final List<String> tabIds;
  bool isExpanded;
  bool isPinned;

  TabGroup({
    required this.id,
    required this.domain,
    required this.displayName,
    required this.colorCode,
    List<String>? tabIds,
    this.isExpanded = true,
    this.isPinned = false,
  }) : tabIds = tabIds ?? [];

  int get tabCount => tabIds.length;

  TabGroup copyWith({
    String? id,
    String? domain,
    String? displayName,
    int? colorCode,
    List<String>? tabIds,
    bool? isExpanded,
    bool? isPinned,
  }) {
    return TabGroup(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      displayName: displayName ?? this.displayName,
      colorCode: colorCode ?? this.colorCode,
      tabIds: tabIds ?? List.from(this.tabIds),
      isExpanded: isExpanded ?? this.isExpanded,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

/// Service pour gérer les groupes d'onglets
class TabGroupService extends ChangeNotifier {
  final TabManager _tabManager;
  final Map<String, TabGroup> _groups = {};
  final Map<String, String> _tabToGroup = {}; // tabId -> groupId
  final List<String> _groupOrder = [];
  String? _selectedGroupId; // Groupe dont un onglet a été sélectionné
  
  // Couleurs prédéfinies pour les domaines
  static final List<int> _domainColors = [
    0xFF6366F1, // Indigo
    0xFF8B5CF6, // Violet
    0xFFEC4899, // Pink
    0xFFF59E0B, // Amber
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFFEF4444, // Red
    0xFF14B8A6, // Teal
    0xFFF97316, // Orange
    0xFF84CC16, // Lime
    0xFF06B6D4, // Cyan
    0xFFA855F7, // Purple
  ];
  
  final Map<String, int> _domainColorMap = {};
  int _nextColorIndex = 0;

  TabGroupService(this._tabManager) {
    _tabManager.addListener(_onTabsChanged);
    _onTabsChanged(); // Initialiser les groupes
  }

  Map<String, TabGroup> get groups => Map.unmodifiable(_groups);
  List<TabGroup> get orderedGroups => _groupOrder.map((id) => _groups[id]!).toList();
  
  /// Obtient le groupe d'un onglet
  TabGroup? getGroupForTab(String tabId) {
    final groupId = _tabToGroup[tabId];
    return groupId != null ? _groups[groupId] : null;
  }
  
  /// Obtient la couleur d'un domaine
  int getColorForDomain(String domain) {
    if (_domainColorMap.containsKey(domain)) {
      return _domainColorMap[domain]!;
    }
    
    // Assigner une nouvelle couleur
    final color = _domainColors[_nextColorIndex % _domainColors.length];
    _domainColorMap[domain] = color;
    _nextColorIndex++;
    return color;
  }
  
  /// Extrait le domaine d'une URL
  String _extractDomain(String? url) {
    if (url == null || url.isEmpty) {
      return 'local';
    }
    
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        // Retirer www. si présent
        return uri.host.replaceFirst(RegExp(r'^www\.'), '');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'extraction du domaine: $e');
    }
    
    // Pour les URLs spéciales (about:, file:, etc.)
    if (url.startsWith('about:')) {
      return 'about';
    } else if (url.startsWith('file:')) {
      return 'local';
    }
    
    return 'unknown';
  }
  
  /// Génère un nom d'affichage pour un domaine
  String _getDisplayName(String domain) {
    if (domain == 'local') {
      return 'Fichiers locaux';
    } else if (domain == 'about') {
      return 'Pages système';
    } else if (domain == 'unknown') {
      return 'Autres';
    }
    
    // Capitaliser la première lettre
    return domain.split('.').first[0].toUpperCase() + domain.split('.').first.substring(1);
  }
  
  /// Met à jour les groupes en fonction des onglets actuels
  void _onTabsChanged() {
    final tabs = _tabManager.tabs;
    final newGroups = <String, TabGroup>{};
    final newTabToGroup = <String, String>{};
    final newGroupOrder = <String>[];
    final processedTabs = <String>{};
    
    // Vérifier si l'onglet actif a changé de groupe
    final activeTab = _tabManager.activeTab;
    if (activeTab != null && _selectedGroupId != null) {
      final currentGroupId = _tabToGroup[activeTab.id];
      if (currentGroupId != _selectedGroupId) {
        // L'onglet actif n'est plus dans le groupe sélectionné, réinitialiser
        _selectedGroupId = null;
      }
    }
    
    // Grouper les onglets par domaine
    final domainGroups = <String, List<TabModel>>{};
    
    for (final tab in tabs) {
      final domain = _extractDomain(tab.url);
      domainGroups.putIfAbsent(domain, () => <TabModel>[]).add(tab);
    }
    
    // Créer ou mettre à jour les groupes
    for (final entry in domainGroups.entries) {
      final domain = entry.key;
      final domainTabs = entry.value;
      
      // Chercher un groupe existant pour ce domaine
      TabGroup? existingGroup;
      for (final group in _groups.values) {
        if (group.domain == domain) {
          existingGroup = group;
          break;
        }
      }
      
      final groupId = existingGroup?.id ?? 'group_${domain}_${DateTime.now().millisecondsSinceEpoch}';
      final colorCode = existingGroup?.colorCode ?? getColorForDomain(domain);
      
      final group = TabGroup(
        id: groupId,
        domain: domain,
        displayName: _getDisplayName(domain),
        colorCode: colorCode,
        tabIds: domainTabs.map<String>((t) => t.id).toList(),
        isExpanded: existingGroup?.isExpanded ?? true,
        isPinned: existingGroup?.isPinned ?? false,
      );
      
      newGroups[groupId] = group;
      newGroupOrder.add(groupId);
      
      // Mapper les onglets au groupe
      for (final tab in domainTabs) {
        newTabToGroup[tab.id] = groupId;
        processedTabs.add(tab.id);
      }
    }
    
    // Supprimer les groupes vides
    final groupsToRemove = <String>[];
    for (final groupId in _groupOrder) {
      if (!newGroups.containsKey(groupId)) {
        groupsToRemove.add(groupId);
      }
    }
    
    _groups.clear();
    _groups.addAll(newGroups);
    _tabToGroup.clear();
    _tabToGroup.addAll(newTabToGroup);
    _groupOrder.clear();
    _groupOrder.addAll(newGroupOrder);
    
    notifyListeners();
  }
  
  /// Basculer l'expansion d'un groupe
  void toggleGroup(String groupId) {
    final group = _groups[groupId];
    if (group != null) {
      final newExpanded = !group.isExpanded;
      
      // Si on expand un groupe, fermer tous les autres
      if (newExpanded) {
        for (final otherGroupId in _groups.keys) {
          if (otherGroupId != groupId && _groups[otherGroupId]!.isExpanded) {
            _groups[otherGroupId] = _groups[otherGroupId]!.copyWith(isExpanded: false);
          }
        }
        // Réinitialiser la sélection des autres groupes
        if (_selectedGroupId != null && _selectedGroupId != groupId) {
          _selectedGroupId = null;
        }
      }
      
      _groups[groupId] = group.copyWith(isExpanded: newExpanded);
      
      // Réinitialiser la sélection si on ferme le groupe
      if (!newExpanded && _selectedGroupId == groupId) {
        _selectedGroupId = null;
      }
      
      notifyListeners();
    }
  }
  
  /// Fermer un groupe (utilisé quand on sélectionne un onglet)
  void collapseGroup(String groupId) {
    final group = _groups[groupId];
    if (group != null && group.isExpanded) {
      _groups[groupId] = group.copyWith(isExpanded: false);
      if (_selectedGroupId == groupId) {
        _selectedGroupId = null;
      }
      notifyListeners();
    }
  }
  
  /// Marquer un groupe comme sélectionné (un de ses onglets a été choisi)
  void selectGroup(String groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
  }
  
  /// Vérifier si un groupe est sélectionné
  bool isGroupSelected(String groupId) {
    return _selectedGroupId == groupId;
  }
  
  /// Obtenir le groupe sélectionné
  String? get selectedGroupId => _selectedGroupId;
  
  /// Épingler/désépingler un groupe
  void togglePinGroup(String groupId) {
    final group = _groups[groupId];
    if (group != null) {
      _groups[groupId] = group.copyWith(isPinned: !group.isPinned);
      
      // Déplacer le groupe épinglé en haut
      if (group.isPinned) {
        _groupOrder.remove(groupId);
        _groupOrder.insert(0, groupId);
      } else {
        _groupOrder.remove(groupId);
        _groupOrder.add(groupId);
      }
      
      notifyListeners();
    }
  }
  
  /// Fermer tous les onglets d'un groupe
  void closeGroup(String groupId) {
    final group = _groups[groupId];
    if (group != null) {
      for (final tabId in group.tabIds) {
        _tabManager.closeTab(tabId);
      }
    }
  }
  
  /// Déplacer un onglet vers un autre groupe
  void moveTabToGroup(String tabId, String targetGroupId) {
    final currentGroupId = _tabToGroup[tabId];
    if (currentGroupId == null || currentGroupId == targetGroupId) {
      return;
    }
    
    final currentGroup = _groups[currentGroupId];
    final targetGroup = _groups[targetGroupId];
    
    if (currentGroup != null && targetGroup != null) {
      // Retirer de l'ancien groupe
      final newCurrentTabIds = List<String>.from(currentGroup.tabIds)..remove(tabId);
      _groups[currentGroupId] = currentGroup.copyWith(tabIds: newCurrentTabIds);
      
      // Ajouter au nouveau groupe
      final newTargetTabIds = List<String>.from(targetGroup.tabIds)..add(tabId);
      _groups[targetGroupId] = targetGroup.copyWith(tabIds: newTargetTabIds);
      
      _tabToGroup[tabId] = targetGroupId;
      
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _tabManager.removeListener(_onTabsChanged);
    super.dispose();
  }
}

