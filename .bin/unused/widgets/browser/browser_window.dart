import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import 'address_bar.dart';
import 'tab_bar.dart' show BrowserTabBar;
import 'tab_groups_sidebar.dart';
import 'extensions_panel.dart';
import 'web_content_view.dart';
import '../dev_tools/dev_tools_panel.dart';

// Keyboard shortcuts intents
class _NewTabIntent extends Intent {}
class _CloseTabIntent extends Intent {}
class _NextTabIntent extends Intent {}
class _PreviousTabIntent extends Intent {}
class _ReloadIntent extends Intent {}
class _GoBackIntent extends Intent {}
class _GoForwardIntent extends Intent {}
class _FocusAddressBarIntent extends Intent {}
class _ToggleDevToolsIntent extends Intent {}

class BrowserWindow extends StatefulWidget {
  const BrowserWindow({super.key});

  @override
  State<BrowserWindow> createState() => _BrowserWindowState();
}

class _BrowserWindowState extends State<BrowserWindow> {
  bool _isDevToolsVisible = false;
  bool _isGroupsSidebarVisible = false;
  bool _isExtensionsVisible = false;
  final GlobalKey<AddressBarState> _addressBarKey = GlobalKey();

  void _toggleDevTools() {
    setState(() {
      _isDevToolsVisible = !_isDevToolsVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    // Setup keyboard shortcuts will be done in build
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider(create: (_) => TabWebViewManager()),
      ],
      child: Consumer<TabManager>(
        builder: (context, tabManager, _) {
          return Row(
            children: [
              // Groups Sidebar
              TabGroupsSidebar(
                isVisible: _isGroupsSidebarVisible,
                onClose: () {
                  setState(() {
                    _isGroupsSidebarVisible = false;
                  });
                },
              ),
              
              // Main content
              Expanded(
                child: Shortcuts(
                  shortcuts: {
                    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT): _NewTabIntent(),
                    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW): _CloseTabIntent(),
                    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.tab): _NextTabIntent(),
                    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): _PreviousTabIntent(),
                    LogicalKeySet(LogicalKeyboardKey.f5): _ReloadIntent(),
                    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): _ReloadIntent(),
                    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): _GoBackIntent(),
                    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): _GoForwardIntent(),
                    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL): _FocusAddressBarIntent(),
                    LogicalKeySet(LogicalKeyboardKey.f12): _ToggleDevToolsIntent(),
                    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyI): _ToggleDevToolsIntent(),
                  },
                  child: Actions(
                    actions: {
                      _NewTabIntent: CallbackAction<_NewTabIntent>(
                        onInvoke: (_) {
                          tabManager.createNewTab();
                          return null;
                        },
                      ),
                      _CloseTabIntent: CallbackAction<_CloseTabIntent>(
                        onInvoke: (_) {
                          final activeTab = tabManager.activeTab;
                          if (activeTab != null) {
                            final webViewManager = Provider.of<TabWebViewManager>(
                              context,
                              listen: false,
                            );
                            webViewManager.removeEngineForTab(activeTab.id);
                            tabManager.closeTab(activeTab.id);
                          }
                          return null;
                        },
                      ),
                      _NextTabIntent: CallbackAction<_NextTabIntent>(
                        onInvoke: (_) {
                          final tabs = tabManager.tabs;
                          if (tabs.length > 1) {
                            final currentIndex = tabs.indexWhere((t) => t.isSelected);
                            final nextIndex = (currentIndex + 1) % tabs.length;
                            tabManager.selectTab(tabs[nextIndex].id);
                          }
                          return null;
                        },
                      ),
                      _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
                        onInvoke: (_) {
                          final tabs = tabManager.tabs;
                          if (tabs.length > 1) {
                            final currentIndex = tabs.indexWhere((t) => t.isSelected);
                            final prevIndex = (currentIndex - 1 + tabs.length) % tabs.length;
                            tabManager.selectTab(tabs[prevIndex].id);
                          }
                          return null;
                        },
                      ),
                      _ReloadIntent: CallbackAction<_ReloadIntent>(
                        onInvoke: (_) {
                          final tabManager = Provider.of<TabManager>(context, listen: false);
                          final activeTab = tabManager.activeTab;
                          if (activeTab != null) {
                            final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
                            final engine = webViewManager.getEngine(activeTab.id);
                            engine?.reload();
                          }
                          return null;
                        },
                      ),
                      _GoBackIntent: CallbackAction<_GoBackIntent>(
                        onInvoke: (_) {
                          final tabManager = Provider.of<TabManager>(context, listen: false);
                          final activeTab = tabManager.activeTab;
                          if (activeTab != null) {
                            final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
                            final engine = webViewManager.getEngine(activeTab.id);
                            engine?.goBack();
                          }
                          return null;
                        },
                      ),
                      _GoForwardIntent: CallbackAction<_GoForwardIntent>(
                        onInvoke: (_) {
                          final tabManager = Provider.of<TabManager>(context, listen: false);
                          final activeTab = tabManager.activeTab;
                          if (activeTab != null) {
                            final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
                            final engine = webViewManager.getEngine(activeTab.id);
                            engine?.goForward();
                          }
                          return null;
                        },
                      ),
                      _FocusAddressBarIntent: CallbackAction<_FocusAddressBarIntent>(
                        onInvoke: (_) {
                          _addressBarKey.currentState?.focus();
                          return null;
                        },
                      ),
                      _ToggleDevToolsIntent: CallbackAction<_ToggleDevToolsIntent>(
                        onInvoke: (_) {
                          _toggleDevTools();
                          return null;
                        },
                      ),
                    },
                    child: Focus(
                      autofocus: true,
                      child: Column(
                        children: [
                          // Address Bar
                          AddressBar(
                            key: _addressBarKey,
                            onDevToolsToggle: _toggleDevTools,
                            onGroupsToggle: () {
                              setState(() {
                                _isGroupsSidebarVisible = !_isGroupsSidebarVisible;
                              });
                            },
                            onExtensionsToggle: () {
                              setState(() {
                                _isExtensionsVisible = !_isExtensionsVisible;
                              });
                            },
                            isDevToolsVisible: _isDevToolsVisible,
                            isGroupsVisible: _isGroupsSidebarVisible,
                            isExtensionsVisible: _isExtensionsVisible,
                          ),
                    
                    // Tab Bar
                    const BrowserTabBar(),
                    
                    // Content Area
                    Expanded(
                      child: Consumer<TabManager>(
                        builder: (context, tabManager, _) {
                          return WebContentView(tab: tabManager.activeTab);
                        },
                      ),
                    ),
                    
                    // DevTools Panel
                    DevToolsPanel(
                      isVisible: _isDevToolsVisible,
                      onClose: () {
                        setState(() {
                          _isDevToolsVisible = false;
                        });
                      },
                    ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Extensions Sidebar
              ExtensionsPanel(
                isVisible: _isExtensionsVisible,
                onClose: () {
                  setState(() {
                    _isExtensionsVisible = false;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

