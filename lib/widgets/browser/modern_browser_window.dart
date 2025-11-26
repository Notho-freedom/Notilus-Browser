import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart' show TabWebViewManager;
import '../../services/devtools_service.dart';
import '../../services/system_metrics_service.dart';
import '../../services/update_service.dart';
import '../../core/animations/notilus_animations.dart';
import 'gx_address_bar.dart';
import 'gx_tab_bar.dart';
import 'gx_sidebar.dart';
import 'web_content_view.dart';
import 'home_pages/home_page_factory.dart';
import 'modern_history_panel.dart';
import 'modern_bookmarks_panel.dart';
import 'modern_downloads_panel.dart';
import 'modern_settings_panel.dart';
import 'webview_service_panel.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';
import '../../widgets/terminal/native_terminal_panel.dart';
import '../../widgets/dev_tools/notilus_devtools.dart';
import '../../widgets/documentation/documentation_panel.dart';
import '../../widgets/mosaic/mosaic_container.dart';
import '../../services/mosaic_service.dart';
import '../../widgets/studio/studio_panel.dart';
import '../../widgets/lighthouse/lighthouse_panel.dart';

// Intent pour les raccourcis clavier
class _ToggleMosaicIntent extends Intent {}
class _OpenDevToolsIntent extends Intent {}

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
  double _sideMenuWidth = 380.0;
  bool _isResizing = false;
  bool _isDevToolsOpen = false; // État du panneau DevTools en bas

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

  bool get _isPanelVisible => _currentSection != SidebarSection.home;

  void _closePanel() {
    if (_currentSection != SidebarSection.home) {
      setState(() {
        _currentSection = SidebarSection.home;
      });
    }
  }

  void _handleOpenDevTools() {
    // Ouvrir les DevTools en bas de l'écran (via F12)
    _openNativeDevTools();
    debugPrint('DevTools ${_isDevToolsOpen ? "opened" : "closed"} via F12');
  }

  void _openNativeDevTools() {
    // Toggle le panneau DevTools Notilus en bas de l'écran
    setState(() {
      _isDevToolsOpen = !_isDevToolsOpen;
    });
    
    // Attacher le moteur au DevToolsService si ouvert
    if (_isDevToolsOpen) {
      try {
        final tabManager = Provider.of<TabManager>(context, listen: false);
        final tabWebviewManager = Provider.of<TabWebViewManager>(context, listen: false);
        final devToolsService = Provider.of<DevToolsService>(context, listen: false);
        final activeTab = tabManager.activeTab;
        
        if (activeTab != null) {
          final engine = tabWebviewManager.getEngineForTab(activeTab.id);
          if (engine != null) {
            devToolsService.attachEngine(engine);
            devToolsService.enable();
          }
        }
      } catch (e) {
        debugPrint('Erreur configuration DevTools: $e');
      }
    }
  }

  void _closeDevTools() {
    setState(() {
      _isDevToolsOpen = false;
    });
  }
  
  /// Construit le widget de page d'accueil en fonction du paramètre choisi
  Widget _buildHomePageWidget() {
    final settings = SettingsService();
    
    return HomePageFactory.create(
      style: settings.homePageStyle,
      onTerminalSelected: () {
        setState(() {
          _currentSection = SidebarSection.terminal;
        });
      },
      onDevToolsSelected: _openNativeDevTools,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.f12): _OpenDevToolsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyI): _OpenDevToolsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyM): _ToggleMosaicIntent(),
      },
      child: Actions(
        actions: {
          _OpenDevToolsIntent: CallbackAction<_OpenDevToolsIntent>(
            onInvoke: (_) {
              _handleOpenDevTools();
              return null;
            },
          ),
          _ToggleMosaicIntent: CallbackAction<_ToggleMosaicIntent>(
            onInvoke: (_) {
              final mosaicService = Provider.of<NotilusMosaicService>(context, listen: false);
              final tabManager = Provider.of<TabManager>(context, listen: false);
              mosaicService.toggle(activeTabId: tabManager.activeTab?.id);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gxRed,
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0B0B0E),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.02),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            // Sidebar moderne
            AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                return Container(
                  width: _sidebarAnimation.value * 48,
                  child: _sidebarAnimation.value > 0
                      ? GXSidebar(
                          onClose: _toggleSidebar,
                          onSectionSelected: (section) {
                            // DevTools natif - ouvre les DevTools du WebView
                            if (section == SidebarSection.nativeDevtools) {
                              _openNativeDevTools();
                              return;
                            }
                            setState(() {
                              _currentSection = section;
                            });
                          },
                        )
                      : null,
                );
              },
            ),

          // Zone principale avec sidemenu en position absolue
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    GXTabBar(
                      onMenuTap: _toggleSidebar,
                      onGroupsPressed: () {
                        setState(() {
                          _currentSection = SidebarSection.favorites; // Les groupes sont dans favorites pour l'instant
                          _isSidebarVisible = true;
                        });
                      },
                      isSidebarVisible: _isSidebarVisible,
                    ),
                    GXAddressBar(
                      onWidgetsPressed: () {
                        setState(() {
                          _currentSection = SidebarSection.widgets;
                          _isSidebarVisible = true;
                        });
                      },
                      onDownloadsPressed: () {
                        setState(() {
                          _currentSection = SidebarSection.downloads;
                          _isSidebarVisible = true;
                        });
                      },
                    ),
                    Expanded(
                      child: RepaintBoundary(
                        child: Selector2<NotilusMosaicService, TabManager, ({bool isMosaicActive, String? activeTabId, String? activeTabUrl})>(
                          selector: (_, mosaic, tabs) => (
                            isMosaicActive: mosaic.isMosaicActive,
                            activeTabId: tabs.activeTab?.id,
                            activeTabUrl: tabs.activeTab?.url,
                          ),
                          builder: (context, data, _) {
                            // Priorité 1: Mosaïque si active
                            if (data.isMosaicActive) {
                              return const MosaicContainer();
                            }
                            
                            // Priorité 2: Contenu normal
                            final tabManager = context.read<TabManager>();
                            final activeTab = tabManager.activeTab;
                            if (activeTab == null) {
                              return _buildHomePageWidget();
                            }
                            
                            // Onglets web uniquement (terminal géré via sidebar)
                            if (activeTab.url == null ||
                                activeTab.url!.isEmpty ||
                                activeTab.url == 'about:blank' ||
                                activeTab.url == 'about:newtab') {
                              return _buildHomePageWidget();
                            }
                            return WebContentView(tab: activeTab);
                          },
                        ),
                      ),
                    ),
                    // DevTools Panel en bas - optimisé avec RepaintBoundary
                    if (_isDevToolsOpen)
                      RepaintBoundary(
                        child: Builder(
                          builder: (context) {
                            final tabWebViewManager = context.read<TabWebViewManager>();
                            final tabManager = context.read<TabManager>();
                            final activeTab = tabManager.activeTab;
                            final engine = activeTab != null 
                                ? tabWebViewManager.getEngineForTab(activeTab.id)
                                : null;
                            return NotilusDevTools(
                              engine: engine,
                              onClose: _closeDevTools,
                              initialHeight: 300,
                            );
                          },
                        ),
                      ),
                  ],
                ),
                // Menu latéral en position absolue à droite de la sidebar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    offset: _isPanelVisible ? Offset.zero : const Offset(-1, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isPanelVisible ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_isPanelVisible,
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: _sideMenuWidth,
                              child: _buildSideMenu(context),
                            ),
                            // Drag handle pour redimensionner
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onPanStart: (_) {
                                  setState(() {
                                    _isResizing = true;
                                  });
                                },
                                onPanUpdate: (details) {
                                  setState(() {
                                    _sideMenuWidth = (_sideMenuWidth + details.delta.dx).clamp(200.0, 800.0);
                                  });
                                },
                                onPanEnd: (_) {
                                  setState(() {
                                    _isResizing = false;
                                  });
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: Container(
                                    width: 4,
                                    color: _isResizing
                                        ? gxRed.withValues(alpha: 0.8)
                                        : Colors.transparent,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: gxRed.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    final config = _panelConfigForSection();
    if (config == null) return const SizedBox.shrink();
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;

    return Container(
      decoration: BoxDecoration(
        color: colorThemeManager.nativeBackgroundColor,
        border: Border(
          right: BorderSide(
            color: gxRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header du menu
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorThemeManager.nativeBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: gxRed.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(config.icon, color: gxRed, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    config.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _closePanel,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenu du menu
          Expanded(
            child: Container(
              color: Colors.black.withValues(alpha: 0.05),
              child: config.child,
            ),
          ),
        ],
      ),
    );
  }

  _SidebarPanelConfig? _panelConfigForSection() {
    switch (_currentSection) {
      case SidebarSection.favorites:
        return _SidebarPanelConfig(
          title: 'Favoris',
          icon: CupertinoIcons.bookmark,
          child: ModernBookmarksPanel(),
        );
      case SidebarSection.history:
        return _SidebarPanelConfig(
          title: 'Historique',
          icon: CupertinoIcons.time,
          child: ModernHistoryPanel(),
        );
      case SidebarSection.downloads:
        return _SidebarPanelConfig(
          title: 'Téléchargements',
          icon: CupertinoIcons.arrow_down_to_line,
          child: ModernDownloadsPanel(),
        );
      case SidebarSection.widgets:
        return _SidebarPanelConfig(
          title: 'Widgets dynamiques',
          icon: CupertinoIcons.layers_alt,
          child: const _NotilusWidgetsPanel(),
        );
      case SidebarSection.ai:
        return _SidebarPanelConfig(
          title: 'Hyper Assistant',
          icon: CupertinoIcons.sparkles,
          child: const _NotilusAiPanel(),
        );
      case SidebarSection.settings:
        return _SidebarPanelConfig(
          title: 'Paramètres rapides',
          icon: CupertinoIcons.gear_alt,
          child: ModernSettingsPanel(),
        );
      case SidebarSection.updates:
        return _SidebarPanelConfig(
          title: 'Mises à jour',
          icon: CupertinoIcons.arrow_up_circle,
          child: const _NotilusUpdatesPanel(),
        );
      case SidebarSection.terminal:
        return _SidebarPanelConfig(
          title: 'Terminal',
          icon: CupertinoIcons.square_list,
          child: const NativeTerminalPanel(),
        );
      case SidebarSection.youtubeMusic:
        return _SidebarPanelConfig(
          title: 'YouTube Music',
          icon: CupertinoIcons.music_note,
          child: WebViewServicePanel(
            url: 'https://music.youtube.com',
            title: 'YouTube Music',
            icon: CupertinoIcons.music_note,
            color: const Color(0xFFFF0000),
          ),
        );
      case SidebarSection.youtube:
        return _SidebarPanelConfig(
          title: 'YouTube',
          icon: CupertinoIcons.play_circle,
          child: WebViewServicePanel(
            url: 'https://www.youtube.com',
            title: 'YouTube',
            icon: CupertinoIcons.play_circle,
            color: const Color(0xFFFF0000),
          ),
        );
      case SidebarSection.chatgpt:
        return _SidebarPanelConfig(
          title: 'ChatGPT',
          icon: CupertinoIcons.chat_bubble_2,
          child: WebViewServicePanel(
            url: 'https://chat.openai.com',
            title: 'ChatGPT',
            icon: CupertinoIcons.chat_bubble_2,
            color: const Color(0xFF10A37F),
          ),
        );
      case SidebarSection.deepseek:
        return _SidebarPanelConfig(
          title: 'DeepSeek',
          icon: CupertinoIcons.sparkles,
          child: WebViewServicePanel(
            url: 'https://chat.deepseek.com',
            title: 'DeepSeek',
            icon: CupertinoIcons.sparkles,
            color: const Color(0xFF00A8FF),
          ),
        );
      case SidebarSection.whatsapp:
        return _SidebarPanelConfig(
          title: 'WhatsApp',
          icon: CupertinoIcons.chat_bubble_text,
          child: WebViewServicePanel(
            url: 'https://web.whatsapp.com',
            title: 'WhatsApp',
            icon: CupertinoIcons.chat_bubble_text,
            color: const Color(0xFF25D366),
          ),
        );
      case SidebarSection.telegram:
        return _SidebarPanelConfig(
          title: 'Telegram',
          icon: CupertinoIcons.paperplane,
          child: WebViewServicePanel(
            url: 'https://web.telegram.org',
            title: 'Telegram',
            icon: CupertinoIcons.paperplane,
            color: const Color(0xFF0088CC),
          ),
        );
      case SidebarSection.home:
      case SidebarSection.nativeDevtools:
      case SidebarSection.mosaic:
        return null;
      case SidebarSection.studio:
        return _SidebarPanelConfig(
          title: 'Notilus Studio',
          icon: CupertinoIcons.paintbrush,
          child: const StudioPanel(),
        );
      case SidebarSection.lighthouse:
        return _SidebarPanelConfig(
          title: 'Notilus Lighthouse',
          icon: CupertinoIcons.gauge,
          child: const LighthousePanel(),
        );
      case SidebarSection.docs:
        return _SidebarPanelConfig(
          title: 'Documentation',
          icon: CupertinoIcons.book,
          child: const DocumentationPanel(),
        );
    }
  }
}

class _SidebarPanelConfig {
  final String title;
  final IconData icon;
  final Widget child;

  const _SidebarPanelConfig({
    required this.title,
    required this.icon,
    required this.child,
  });
}

class _NotilusWidgetsPanel extends StatelessWidget {
  const _NotilusWidgetsPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;
    
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(context.watch<WallpaperManager>().current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Widgets système',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<SystemMetricsService>(
                builder: (context, metrics, _) {
                  final tabManager = Provider.of<TabManager>(context);
                  metrics.updateTabCount(tabManager.tabs.length);
                  
                  final widgets = [
                    _WidgetData('CPU', '${metrics.cpuUsage.toStringAsFixed(0)}%', 'Utilisation processeur', CupertinoIcons.gauge, _getUsageColor(metrics.cpuUsage)),
                    _WidgetData('RAM', '${metrics.ramUsage.toStringAsFixed(0)}%', 'Mémoire utilisée', Icons.memory, _getUsageColor(metrics.ramUsage)),
                    _WidgetData('GPU', '${metrics.gpuTemp.toStringAsFixed(0)}°C', 'Température graphique', CupertinoIcons.speedometer, _getTempColor(metrics.gpuTemp)),
                    _WidgetData('Réseau', metrics.networkStatus, 'État connexion', CupertinoIcons.waveform_path, Colors.green),
                    _WidgetData('Onglets', '${metrics.tabCount}', 'Onglets actifs', CupertinoIcons.square_grid_2x2, gxRed),
                    _WidgetData('Session', metrics.formatActiveTime(), 'Temps actif', CupertinoIcons.time, gxRed),
                    _WidgetData('Pages', '${metrics.pagesVisited}', 'Pages visitées', CupertinoIcons.doc_text, gxRed),
                    _WidgetData('Données', '${metrics.dataUsed.toStringAsFixed(2)} GB', 'Données transférées', CupertinoIcons.arrow_up_arrow_down, gxRed),
                  ];
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: widgets.length,
                    itemBuilder: (context, index) {
                      final widget = widgets[index];
                      return _SystemWidgetTile(widget: widget, accentColor: gxRed);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getUsageColor(double usage) {
    if (usage < 50) return Colors.green;
    if (usage < 80) return Colors.orange;
    return Colors.red;
  }

  static Color _getTempColor(double temp) {
    if (temp < 60) return Colors.green;
    if (temp < 80) return Colors.orange;
    return Colors.red;
  }
}

class _SystemWidgetTile extends StatelessWidget {
  final _WidgetData widget;
  final Color accentColor;

  const _SystemWidgetTile({required this.widget, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.valueColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: widget.valueColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.valueColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.value,
              style: TextStyle(
                color: widget.valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color valueColor;

  const _WidgetData(this.title, this.value, this.subtitle, this.icon, [this.valueColor = Colors.white]);
}

class _NotilusAiPanel extends StatefulWidget {
  const _NotilusAiPanel();

  @override
  State<_NotilusAiPanel> createState() => _NotilusAiPanelState();
}

class _NotilusAiPanelState extends State<_NotilusAiPanel> {
  final TextEditingController _promptController = TextEditingController();
  final SettingsService _settings = SettingsService();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;
    final gxRedDark = Provider.of<ColorThemeManager>(context).primaryDarkColor;
    
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(context.watch<WallpaperManager>().current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(CupertinoIcons.sparkles, color: gxRed, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Hyper Assistant',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gxRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'BETA',
                      style: TextStyle(
                        color: gxRed,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _settings,
                builder: (context, _) {
                  return ListView(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _AiToggleTile(
                        title: 'Assistant contextuel',
                        subtitle: 'Analyse la page et propose des actions rapides',
                        value: _settings.aiContextualEnabled,
                        icon: CupertinoIcons.lightbulb,
                        onChanged: (v) => _settings.setAiContextualEnabled(v),
                      ),
                      const SizedBox(height: 8),
                      _AiToggleTile(
                        title: 'Résumé instantané',
                        subtitle: 'Synthétise les articles longs en un clic',
                        value: _settings.aiSummaryEnabled,
                        icon: CupertinoIcons.doc_text,
                        onChanged: (v) => _settings.setAiSummaryEnabled(v),
                      ),
                      const SizedBox(height: 8),
                      _AiToggleTile(
                        title: 'Protection intelligente',
                        subtitle: 'Bloque les scripts suspects en arrière plan',
                        value: _settings.aiProtectionEnabled,
                        icon: CupertinoIcons.shield,
                        onChanged: (v) => _settings.setAiProtectionEnabled(v),
                      ),
                      const SizedBox(height: 16),
                      // Zone de prompt
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              gxRed.withValues(alpha: 0.15),
                              gxRedDark.withValues(alpha: 0.15),
                            ],
                          ),
                          border: Border.all(
                            color: gxRed.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(CupertinoIcons.text_cursor, color: gxRed, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Hyper Prompt',
                                  style: TextStyle(
                                    color: gxRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _promptController,
                              maxLines: 3,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Décrivez ce que vous voulez faire...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Ex: "Résume cette page", "Trouve des alternatives"',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    if (_promptController.text.isNotEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Fonctionnalité AI en développement'),
                                          backgroundColor: gxRed,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: gxRed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'Envoyer',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quick actions
                      Text(
                        'Actions rapides',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickActionChip(label: 'Résumer', icon: CupertinoIcons.doc_text, color: gxRed),
                          _QuickActionChip(label: 'Traduire', icon: CupertinoIcons.globe, color: gxRed),
                          _QuickActionChip(label: 'Expliquer', icon: CupertinoIcons.question_circle, color: gxRed),
                          _QuickActionChip(label: 'Simplifier', icon: CupertinoIcons.wand_stars, color: gxRed),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _QuickActionChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label: fonctionnalité AI en développement'),
            backgroundColor: color,
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _AiToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: value 
            ? gxRed.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: value 
              ? gxRed.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value 
                  ? gxRed.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: value ? gxRed : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: value ? Colors.white : Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: gxRed.withValues(alpha: 0.5),
            activeColor: gxRed,
          ),
        ],
      ),
    );
  }
}

class _NotilusUpdatesPanel extends StatefulWidget {
  const _NotilusUpdatesPanel();

  @override
  State<_NotilusUpdatesPanel> createState() => _NotilusUpdatesPanelState();
}

class _NotilusUpdatesPanelState extends State<_NotilusUpdatesPanel> {
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    // Charger les mises à jour au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_updateService.recentUpdates.isEmpty) {
        _updateService.checkForUpdates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;
    
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(context.watch<WallpaperManager>().current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(CupertinoIcons.arrow_up_circle, color: gxRed, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Mises à jour',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'v${_updateService.version}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton vérifier les mises à jour
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListenableBuilder(
                listenable: _updateService,
                builder: (context, _) {
                  return InkWell(
                    onTap: _updateService.isChecking ? null : () => _updateService.checkForUpdates(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gxRed.withValues(alpha: 0.2),
                            gxRed.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: gxRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_updateService.isChecking)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(gxRed),
                              ),
                            )
                          else
                            Icon(CupertinoIcons.arrow_clockwise, color: gxRed, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            _updateService.isChecking 
                                ? 'Vérification en cours...' 
                                : 'Vérifier les mises à jour',
                            style: TextStyle(
                              color: gxRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_updateService.lastCheck != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Dernière vérification: ${_updateService.formatRelativeDate(_updateService.lastCheck!)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Changements récents',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListenableBuilder(
                listenable: _updateService,
                builder: (context, _) {
                  final updates = _updateService.recentUpdates;
                  
                  if (updates.isEmpty && !_updateService.isChecking) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Vous êtes à jour!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Notilus v${_updateService.version}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: updates.length,
                    itemBuilder: (context, index) {
                      final update = updates[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _UpdateCard(
                          title: update.title,
                          description: update.description,
                          date: _updateService.formatRelativeDate(update.date),
                          isNew: update.isNew,
                          category: update.category,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final bool isNew;
  final UpdateCategory category;

  const _UpdateCard({
    required this.title,
    required this.description,
    required this.date,
    required this.isNew,
    this.category = UpdateCategory.feature,
  });

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: isNew
              ? gxRed.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
              if (isNew) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gxRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NOUVEAU',
                    style: TextStyle(
                      color: gxRed,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

