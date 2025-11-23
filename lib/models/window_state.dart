import 'tab_model.dart';
import 'tab_group_model.dart';

class WindowState {
  final List<TabModel> tabs;
  final List<TabGroupModel> groups;
  final String? activeTabId;
  final bool isDevToolsOpen;
  final bool isSplitScreenMode;
  final List<String> splitScreenTabIds;

  WindowState({
    List<TabModel>? tabs,
    List<TabGroupModel>? groups,
    this.activeTabId,
    this.isDevToolsOpen = false,
    this.isSplitScreenMode = false,
    List<String>? splitScreenTabIds,
  })  : tabs = tabs ?? [],
        groups = groups ?? [],
        splitScreenTabIds = splitScreenTabIds ?? [];

  WindowState copyWith({
    List<TabModel>? tabs,
    List<TabGroupModel>? groups,
    String? activeTabId,
    bool? isDevToolsOpen,
    bool? isSplitScreenMode,
    List<String>? splitScreenTabIds,
  }) {
    return WindowState(
      tabs: tabs ?? this.tabs,
      groups: groups ?? this.groups,
      activeTabId: activeTabId ?? this.activeTabId,
      isDevToolsOpen: isDevToolsOpen ?? this.isDevToolsOpen,
      isSplitScreenMode: isSplitScreenMode ?? this.isSplitScreenMode,
      splitScreenTabIds: splitScreenTabIds ?? this.splitScreenTabIds,
    );
  }
}

