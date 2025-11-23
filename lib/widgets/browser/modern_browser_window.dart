import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import 'modern_address_bar.dart';
import 'modern_tab_bar.dart';
import 'modern_sidebar.dart';
import 'web_content_view.dart';
import 'modern_home_page.dart';
import 'modern_history_panel.dart';
import 'modern_bookmarks_panel.dart';
import 'modern_downloads_panel.dart';
import 'modern_settings_panel.dart';

class ModernBrowserWindow extends StatefulWidget {
  const ModernBrowserWindow({super.key});

  @override
  State<ModernBrowserWindow> createState() => _ModernBrowserWindowState();
}

class _ModernBrowserWindowState extends State<ModernBrowserWindow>
    with SingleTickerProviderStateMixin {
  bool _isSidebarVisible = true;
  SidebarSection _currentSection = SidebarSection.home;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _sidebarAnimationController.forward();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
      if (_isSidebarVisible) {
        _sidebarAnimationController.forward();
      } else {
        _sidebarAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0B0E),
      child: Row(
        children: [
          // Sidebar moderne
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Container(
                width: _sidebarAnimation.value * 48,
                child: _sidebarAnimation.value > 0
                    ? ModernSidebar(
                        onClose: _toggleSidebar,
                        onSectionSelected: (section) {
                          setState(() {
                            _currentSection = section;
                          });
                        },
                      )
                    : null,
              );
            },
          ),

          // Zone principale
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFFF2D55).withOpacity(0.3),
                    width: 2,
                  ),
                  left: BorderSide(
                    color: const Color(0xFFFF2D55).withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Barre d'outils moderne
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131317),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFFF2D55).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        ModernTabBar(
                          onMenuTap: _toggleSidebar,
                          isSidebarVisible: _isSidebarVisible,
                        ),
                        ModernAddressBar(),
                      ],
                    ),
                  ),

                  // Zone de contenu web
                  Expanded(
                    child: Consumer<TabManager>(
                      builder: (context, tabManager, _) {
                        final activeTab = tabManager.activeTab;

                        switch (_currentSection) {
                          case SidebarSection.favorites:
                            return const ModernBookmarksPanel();
                          case SidebarSection.history:
                            return const ModernHistoryPanel();
                          case SidebarSection.downloads:
                            return const ModernDownloadsPanel();
                          case SidebarSection.settings:
                            return const ModernSettingsPanel();
                          case SidebarSection.home:
                          default:
                            if (activeTab == null ||
                                activeTab.url == null ||
                                activeTab.url!.isEmpty ||
                                activeTab.url == 'about:blank' ||
                                activeTab.url == 'about:newtab') {
                              return const ModernHomePage();
                            }
                            return WebContentView(tab: activeTab);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
