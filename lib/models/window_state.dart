import 'tab_model.dart';
import 'tab_group_model.dart';

class WindowState {
  final List<TabModel> tabs;
  final List<TabGroupModel> groups;
  final String? activeTabId;
  final bool isDevToolsOpen;

  WindowState({
    List<TabModel>? tabs,
    List<TabGroupModel>? groups,
    this.activeTabId,
    this.isDevToolsOpen = false,
  })  : tabs = tabs ?? [],
        groups = groups ?? [];

  WindowState copyWith({
    List<TabModel>? tabs,
    List<TabGroupModel>? groups,
    String? activeTabId,
    bool? isDevToolsOpen,
  }) {
    return WindowState(
      tabs: tabs ?? this.tabs,
      groups: groups ?? this.groups,
      activeTabId: activeTabId ?? this.activeTabId,
      isDevToolsOpen: isDevToolsOpen ?? this.isDevToolsOpen,
    );
  }
}

