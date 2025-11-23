import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import 'modern_address_bar.dart';
import 'modern_tab_bar.dart';
import 'modern_sidebar.dart';
import 'web_content_view.dart';
import 'modern_home_page.dart';

class ModernBrowserWindow extends StatefulWidget {
  const ModernBrowserWindow({super.key});

  @override
  State<ModernBrowserWindow> createState() => _ModernBrowserWindowState();
}

class _ModernBrowserWindowState extends State<ModernBrowserWindow>
    with SingleTickerProviderStateMixin {
  bool _isSidebarVisible = true;
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
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.background,
      child: Row(
        children: [
          // Sidebar moderne
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Container(
                width: _sidebarAnimation.value * 280,
                child: _sidebarAnimation.value > 0
                    ? ModernSidebar(
                        onClose: _toggleSidebar,
                      )
                    : null,
              );
            },
          ),
          
          // Zone principale
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_isSidebarVisible ? 16 : 0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_isSidebarVisible ? 16 : 0),
                ),
                child: Column(
                  children: [
                    // Barre d'outils moderne
                    Container(
                      // Laisser la hauteur s'adapter au contenu pour éviter les overflows
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.95),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Barre d'onglets
                          ModernTabBar(
                            onMenuTap: _toggleSidebar,
                            isSidebarVisible: _isSidebarVisible,
                          ),
                          // Barre d'adresse
                          ModernAddressBar(),
                        ],
                      ),
                    ),
                    
                    // Zone de contenu web
                    Expanded(
                      child: Consumer<TabManager>(
                        builder: (context, tabManager, _) {
                          final activeTab = tabManager.activeTab;
                          
                          // Afficher la page d'accueil si pas d'onglet ou URL vide
                          if (activeTab == null ||
                              activeTab.url == null ||
                              activeTab.url!.isEmpty ||
                              activeTab.url == 'about:blank' ||
                              activeTab.url == 'about:newtab') {
                            return ModernHomePage();
                          }
                          
                          return WebContentView(tab: activeTab);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
