/// Notilus Mosaic Service - Gestion avancée du workspace mosaïque
/// Permet de créer, modifier et sauvegarder des layouts dynamiques
library mosaic_service;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mosaic_models.dart';
import 'tab_manager.dart';

class NotilusMosaicService extends ChangeNotifier {
  static const String _prefsKey = 'notilus_mosaic_workspaces';
  static const String _activeWorkspaceKey = 'notilus_mosaic_active_workspace';

  bool _isActive = false;
  bool _isVisible = true;
  MosaicWorkspace? _activeWorkspace;
  List<MosaicWorkspace> _workspaces = [];
  String? _hoveredTileId;
  String? _focusedTileId;
  String? _dragOverTileId;
  DropZone? _dragOverZone;

  // Getters
  bool get isActive => _isActive;
  bool get isVisible => _isVisible;
  bool get isMosaicActive => _isActive && _isVisible;
  MosaicWorkspace? get activeWorkspace => _activeWorkspace;
  List<MosaicWorkspace> get workspaces => List.unmodifiable(_workspaces);
  String? get hoveredTileId => _hoveredTileId;
  String? get focusedTileId => _focusedTileId;
  String? get dragOverTileId => _dragOverTileId;
  DropZone? get dragOverZone => _dragOverZone;
  MosaicTile? get rootTile => _activeWorkspace?.rootTile;

  NotilusMosaicService() {
    _loadWorkspaces();
  }

  /// Charger les workspaces depuis le stockage
  Future<void> _loadWorkspaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workspacesJson = prefs.getString(_prefsKey);
      final activeId = prefs.getString(_activeWorkspaceKey);

      if (workspacesJson != null) {
        final List<dynamic> list = jsonDecode(workspacesJson);
        _workspaces = list.map((json) => MosaicWorkspace.fromJson(json)).toList();
        
        if (activeId != null) {
          _activeWorkspace = _workspaces.firstWhere(
            (w) => w.id == activeId,
            orElse: () => _workspaces.first,
          );
        }
      }

      // Créer un workspace par défaut si aucun n'existe
      if (_workspaces.isEmpty) {
        final defaultWorkspace = MosaicWorkspace(
          name: 'Workspace par défaut',
          rootTile: MosaicTile.empty(),
          isDefault: true,
        );
        _workspaces.add(defaultWorkspace);
        _activeWorkspace = defaultWorkspace;
        await _saveWorkspaces();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement workspaces: $e');
      // Créer workspace par défaut en cas d'erreur
      final defaultWorkspace = MosaicWorkspace(
        name: 'Workspace par défaut',
        rootTile: MosaicTile.empty(),
        isDefault: true,
      );
      _workspaces = [defaultWorkspace];
      _activeWorkspace = defaultWorkspace;
    }
  }

  /// Sauvegarder les workspaces
  Future<void> _saveWorkspaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workspacesJson = jsonEncode(_workspaces.map((w) => w.toJson()).toList());
      await prefs.setString(_prefsKey, workspacesJson);
      
      if (_activeWorkspace != null) {
        await prefs.setString(_activeWorkspaceKey, _activeWorkspace!.id);
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde workspaces: $e');
    }
  }

  /// Activer/Désactiver le mode mosaïque
  void toggle({String? activeTabId}) {
    _isActive = !_isActive;
    
    if (_isActive && activeTabId != null) {
      // Initialiser avec l'onglet actif
      _setRootTileContent(MosaicTileType.web, tabId: activeTabId);
    }
    
    notifyListeners();
    _saveWorkspaces();
  }

  /// Activer le mode mosaïque
  void activate({String? activeTabId}) {
    if (!_isActive) {
      _isActive = true;
      if (activeTabId != null) {
        _setRootTileContent(MosaicTileType.web, tabId: activeTabId);
      }
      notifyListeners();
      _saveWorkspaces();
    }
  }

  /// Désactiver le mode mosaïque
  void deactivate() {
    if (_isActive) {
      _isActive = false;
      notifyListeners();
      _saveWorkspaces();
    }
  }

  /// Masquer/afficher sans désactiver
  void setVisible(bool visible) {
    _isVisible = visible;
    notifyListeners();
  }

  /// Créer un nouveau workspace
  MosaicWorkspace createWorkspace(String name, {MosaicTile? rootTile}) {
    final workspace = MosaicWorkspace(
      name: name,
      rootTile: rootTile ?? MosaicTile.empty(),
    );
    _workspaces.add(workspace);
    _saveWorkspaces();
    notifyListeners();
    return workspace;
  }

  /// Supprimer un workspace
  void deleteWorkspace(String workspaceId) {
    _workspaces.removeWhere((w) => w.id == workspaceId && !w.isDefault);
    if (_activeWorkspace?.id == workspaceId) {
      _activeWorkspace = _workspaces.firstWhere(
        (w) => w.isDefault,
        orElse: () => _workspaces.first,
      );
    }
    _saveWorkspaces();
    notifyListeners();
  }

  /// Changer de workspace actif
  void setActiveWorkspace(String workspaceId) {
    _activeWorkspace = _workspaces.firstWhere(
      (w) => w.id == workspaceId,
      orElse: () => _workspaces.first,
    );
    _saveWorkspaces();
    notifyListeners();
  }

  /// Appliquer un preset de layout
  void applyPreset(MosaicLayoutPreset preset) {
    if (_activeWorkspace != null) {
      _activeWorkspace = _activeWorkspace!.copyWith(
        rootTile: _cloneTile(preset.rootTile),
      );
      _updateWorkspaceInList();
      notifyListeners();
    }
  }

  /// Cloner une tile avec de nouveaux IDs
  MosaicTile _cloneTile(MosaicTile tile) {
    return MosaicTile(
      type: tile.type,
      flexFactor: tile.flexFactor,
      tabId: tile.tabId,
      serviceId: tile.serviceId,
      metadata: Map.from(tile.metadata),
      children: tile.children?.map((c) => _cloneTile(c)).toList(),
      splitDirection: tile.splitDirection,
      isLocked: tile.isLocked,
      isMinimized: tile.isMinimized,
    );
  }

  /// Mettre à jour le workspace dans la liste
  void _updateWorkspaceInList() {
    if (_activeWorkspace != null) {
      final index = _workspaces.indexWhere((w) => w.id == _activeWorkspace!.id);
      if (index >= 0) {
        _workspaces[index] = _activeWorkspace!;
      }
      _saveWorkspaces();
    }
  }

  /// Définir le contenu de la tile racine
  void _setRootTileContent(MosaicTileType type, {String? tabId, String? serviceId}) {
    if (_activeWorkspace != null) {
      final currentRoot = _activeWorkspace!.rootTile;
      _activeWorkspace = _activeWorkspace!.copyWith(
        rootTile: currentRoot.copyWith(
          type: type,
          tabId: tabId,
          serviceId: serviceId,
        ),
      );
      _updateWorkspaceInList();
    }
  }

  /// Trouver une tile par ID (récursif)
  MosaicTile? findTile(String tileId, [MosaicTile? startTile]) {
    final tile = startTile ?? _activeWorkspace?.rootTile;
    if (tile == null) return null;
    
    if (tile.id == tileId) return tile;
    
    if (tile.children != null) {
      for (final child in tile.children!) {
        final found = findTile(tileId, child);
        if (found != null) return found;
      }
    }
    
    return null;
  }

  /// Mettre à jour une tile
  void updateTile(String tileId, MosaicTile Function(MosaicTile) updater) {
    if (_activeWorkspace == null) return;
    
    final newRoot = _updateTileRecursive(_activeWorkspace!.rootTile, tileId, updater);
    _activeWorkspace = _activeWorkspace!.copyWith(rootTile: newRoot);
    _updateWorkspaceInList();
    notifyListeners();
  }

  MosaicTile _updateTileRecursive(
    MosaicTile tile,
    String tileId,
    MosaicTile Function(MosaicTile) updater,
  ) {
    if (tile.id == tileId) {
      return updater(tile);
    }
    
    if (tile.children != null) {
      return tile.copyWith(
        children: tile.children!.map((c) => _updateTileRecursive(c, tileId, updater)).toList(),
      );
    }
    
    return tile;
  }

  /// Définir le contenu d'une tile
  void setTileContent(String tileId, MosaicTileType type, {String? tabId, String? serviceId}) {
    updateTile(tileId, (tile) => tile.copyWith(
      type: type,
      tabId: tabId,
      serviceId: serviceId,
    ));
  }

  /// Définir l'onglet web d'une tile
  void setTileTab(String tileId, String tabId, {TabManager? tabManager}) {
    setTileContent(tileId, MosaicTileType.web, tabId: tabId);
  }

  /// Vider une tile
  void clearTile(String tileId) {
    updateTile(tileId, (tile) => tile.copyWith(
      type: MosaicTileType.empty,
      tabId: null,
      serviceId: null,
    ));
  }

  /// Splitter une tile
  void splitTile(String tileId, SplitDirection direction, {MosaicTileType newTileType = MosaicTileType.empty}) {
    if (_activeWorkspace == null) return;
    
    final tile = findTile(tileId);
    if (tile == null) return;

    // Créer la nouvelle tile
    final newTile = MosaicTile(type: newTileType);
    
    // Si la tile est déjà un conteneur avec la même direction, ajouter simplement
    if (tile.isContainer && tile.splitDirection == direction) {
      updateTile(tileId, (t) => t.copyWith(
        children: [...t.children!, newTile],
      ));
    } else {
      // Sinon, transformer en conteneur avec deux enfants
      final existingContent = tile.copyWith();
      updateTile(tileId, (t) => MosaicTile.split(
        direction: direction,
        children: [existingContent, newTile],
      ).copyWith(id: t.id));
    }
  }

  /// Fermer une tile
  void closeTile(String tileId) {
    if (_activeWorkspace == null) return;
    
    // Si c'est la tile racine, la vider simplement
    if (_activeWorkspace!.rootTile.id == tileId) {
      _activeWorkspace = _activeWorkspace!.copyWith(
        rootTile: MosaicTile.empty(),
      );
      _updateWorkspaceInList();
      notifyListeners();
      return;
    }

    // Sinon, trouver le parent et supprimer
    final newRoot = _removeTileRecursive(_activeWorkspace!.rootTile, tileId);
    if (newRoot != null) {
      _activeWorkspace = _activeWorkspace!.copyWith(rootTile: newRoot);
      _updateWorkspaceInList();
      notifyListeners();
    }
  }

  MosaicTile? _removeTileRecursive(MosaicTile tile, String tileIdToRemove) {
    if (tile.children == null) return tile;

    final newChildren = <MosaicTile>[];
    bool found = false;

    for (final child in tile.children!) {
      if (child.id == tileIdToRemove) {
        found = true;
        continue;
      }
      final updated = _removeTileRecursive(child, tileIdToRemove);
      if (updated != null) {
        newChildren.add(updated);
      }
    }

    // Si on a trouvé et supprimé, et qu'il ne reste qu'un enfant, 
    // remplacer le parent par cet enfant
    if (found && newChildren.length == 1) {
      return newChildren.first.copyWith(id: tile.id, flexFactor: tile.flexFactor);
    }

    // Si aucun enfant restant, retourner null
    if (newChildren.isEmpty) return null;

    return tile.copyWith(children: newChildren);
  }

  /// Échanger deux tiles
  void swapTiles(String tileId1, String tileId2) {
    final tile1 = findTile(tileId1);
    final tile2 = findTile(tileId2);
    
    if (tile1 == null || tile2 == null) return;

    // Échanger les contenus mais pas les positions/tailles
    updateTile(tileId1, (t) => t.copyWith(
      type: tile2.type,
      tabId: tile2.tabId,
      serviceId: tile2.serviceId,
      metadata: tile2.metadata,
    ));
    
    updateTile(tileId2, (t) => t.copyWith(
      type: tile1.type,
      tabId: tile1.tabId,
      serviceId: tile1.serviceId,
      metadata: tile1.metadata,
    ));
  }

  /// Redimensionner les tiles
  void resizeTiles(String parentId, int childIndex, double delta) {
    updateTile(parentId, (parent) {
      if (parent.children == null || childIndex >= parent.children!.length - 1) {
        return parent;
      }

      final minSize = 0.1;
      final maxSize = 0.9;
      
      final currentSize = parent.children![childIndex].flexFactor;
      final nextSize = parent.children![childIndex + 1].flexFactor;
      
      final newCurrentSize = (currentSize + delta).clamp(minSize, maxSize);
      final newNextSize = (nextSize - delta).clamp(minSize, maxSize);
      
      if (newCurrentSize + newNextSize > currentSize + nextSize + 0.01) return parent;

      final newChildren = List<MosaicTile>.from(parent.children!);
      newChildren[childIndex] = newChildren[childIndex].copyWith(flexFactor: newCurrentSize);
      newChildren[childIndex + 1] = newChildren[childIndex + 1].copyWith(flexFactor: newNextSize);

      return parent.copyWith(children: newChildren);
    });
  }

  /// Déplacer une tile vers une autre position
  void moveTile(String sourceTileId, String targetTileId, DropZone zone) {
    final sourceTile = findTile(sourceTileId);
    final targetTile = findTile(targetTileId);
    
    if (sourceTile == null || targetTile == null || sourceTileId == targetTileId) return;

    // Supprimer la tile source
    closeTile(sourceTileId);

    // Ajouter à la nouvelle position
    if (zone == DropZone.center) {
      // Remplacer le contenu de la target
      updateTile(targetTileId, (t) => t.copyWith(
        type: sourceTile.type,
        tabId: sourceTile.tabId,
        serviceId: sourceTile.serviceId,
        metadata: sourceTile.metadata,
      ));
    } else {
      // Splitter la target
      final direction = (zone == DropZone.left || zone == DropZone.right)
          ? SplitDirection.horizontal
          : SplitDirection.vertical;
      
      final sourceCopy = sourceTile.copyWith();
      final targetCopy = targetTile.copyWith();
      
      final children = (zone == DropZone.left || zone == DropZone.top)
          ? [sourceCopy, targetCopy]
          : [targetCopy, sourceCopy];

      updateTile(targetTileId, (t) => MosaicTile.split(
        direction: direction,
        children: children,
      ).copyWith(id: t.id, flexFactor: t.flexFactor));
    }
  }

  /// Définir l'état de survol
  void setHoveredTile(String? tileId) {
    if (_hoveredTileId != tileId) {
      _hoveredTileId = tileId;
      notifyListeners();
    }
  }

  /// Définir l'état de focus
  void setFocusedTile(String? tileId) {
    if (_focusedTileId != tileId) {
      _focusedTileId = tileId;
      notifyListeners();
    }
  }

  /// Définir l'état de drag over
  void setDragOver(String? tileId, DropZone? zone) {
    if (_dragOverTileId != tileId || _dragOverZone != zone) {
      _dragOverTileId = tileId;
      _dragOverZone = zone;
      notifyListeners();
    }
  }

  /// Toggle minimisation d'une tile
  void toggleMinimize(String tileId) {
    updateTile(tileId, (t) => t.copyWith(isMinimized: !t.isMinimized));
  }

  /// Toggle verrouillage d'une tile
  void toggleLock(String tileId) {
    updateTile(tileId, (t) => t.copyWith(isLocked: !t.isLocked));
  }

  /// Maximiser une tile (la rendre unique)
  void maximizeTile(String tileId) {
    final tile = findTile(tileId);
    if (tile != null && _activeWorkspace != null) {
      _activeWorkspace = _activeWorkspace!.copyWith(
        rootTile: tile.copyWith(flexFactor: 1.0, children: null),
      );
      _updateWorkspaceInList();
      notifyListeners();
    }
  }

  /// Compter les tiles actives (non-vides)
  int countActiveTiles([MosaicTile? tile]) {
    final t = tile ?? _activeWorkspace?.rootTile;
    if (t == null) return 0;
    
    if (t.isContainer) {
      return t.children!.fold(0, (sum, child) => sum + countActiveTiles(child));
    }
    
    return t.type != MosaicTileType.empty ? 1 : 0;
  }

  /// Obtenir toutes les tiles feuilles
  List<MosaicTile> getAllLeafTiles([MosaicTile? tile]) {
    final t = tile ?? _activeWorkspace?.rootTile;
    if (t == null) return [];
    
    if (t.isContainer) {
      return t.children!.expand((child) => getAllLeafTiles(child)).toList();
    }
    
    return [t];
  }
}
