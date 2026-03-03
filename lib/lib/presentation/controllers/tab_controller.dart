/// Tab Controller - Gestion des onglets avec Riverpod
/// Remplace progressivement TabManager pour une meilleure réactivité
library tab_controller;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tab_model.dart';
import '../../services/tab_manager.dart';
import '../../services/storage_service.dart';

/// Provider pour le TabManager (bridge vers l'ancien système)
final tabManagerProvider = ChangeNotifierProvider<TabManager>((ref) {
  return TabManager();
});

/// Provider pour la liste des tabs (réactif)
final tabsProvider = Provider<List<TabModel>>((ref) {
  final tabManager = ref.watch(tabManagerProvider);
  return tabManager.tabs;
});

/// Provider pour l'onglet actif
final activeTabProvider = Provider<TabModel?>((ref) {
  final tabManager = ref.watch(tabManagerProvider);
  return tabManager.activeTab;
});

/// Provider pour l'ID de l'onglet actif
final activeTabIdProvider = Provider<String?>((ref) {
  final tabManager = ref.watch(tabManagerProvider);
  return tabManager.activeTabId;
});

/// Provider pour le nombre d'onglets
final tabCountProvider = Provider<int>((ref) {
  final tabs = ref.watch(tabsProvider);
  return tabs.length;
});

/// Provider pour les onglets épinglés
final pinnedTabsProvider = Provider<List<TabModel>>((ref) {
  final tabs = ref.watch(tabsProvider);
  return tabs.where((t) => t.isPinned).toList();
});

/// Provider pour les onglets non épinglés
final unpinnedTabsProvider = Provider<List<TabModel>>((ref) {
  final tabs = ref.watch(tabsProvider);
  return tabs.where((t) => !t.isPinned).toList();
});

/// Provider pour vérifier si un onglet spécifique est actif
final isTabActiveProvider = Provider.family<bool, String>((ref, tabId) {
  final activeId = ref.watch(activeTabIdProvider);
  return activeId == tabId;
});

/// Notifier pour les actions sur les tabs
class TabActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  TabManager get _tabManager => ref.read(tabManagerProvider);

  /// Crée un nouvel onglet
  TabModel createTab({String? url, bool isPrivate = false}) {
    return _tabManager.createNewTab(url: url, isPrivate: isPrivate);
  }

  /// Ferme un onglet
  void closeTab(String tabId) {
    _tabManager.closeTab(tabId);
  }

  /// Sélectionne un onglet
  void selectTab(String tabId) {
    _tabManager.selectTab(tabId);
  }

  /// Épingle/désépingle un onglet
  void togglePin(String tabId) {
    _tabManager.pinTab(tabId);
  }

  /// Duplique un onglet
  TabModel? duplicateTab(String tabId) {
    return _tabManager.duplicateTab(tabId);
  }

  /// Met à jour un onglet
  void updateTab(String tabId, {String? url, String? title, TabState? state, String? favicon}) {
    _tabManager.updateTab(tabId, url: url, title: title, state: state, favicon: favicon);
  }

  /// Réordonne les onglets
  void reorderTab(int oldIndex, int newIndex) {
    _tabManager.reorderTab(oldIndex, newIndex);
  }

  /// Ferme tous les onglets sauf un
  void closeOtherTabs(String keepTabId) {
    _tabManager.closeOtherTabs(keepTabId);
  }

  /// Ferme les onglets à droite
  void closeTabsToRight(String tabId) {
    _tabManager.closeTabsToRight(tabId);
  }
}

final tabActionsProvider = NotifierProvider<TabActionsNotifier, void>(() {
  return TabActionsNotifier();
});

