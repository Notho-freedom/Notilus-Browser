import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart' show TabWebViewManager;
import '../../services/notilus_devtools_service.dart';
import 'gx_address_bar.dart';
import 'gx_tab_bar.dart';
import 'gx_sidebar.dart';
import 'web_content_view.dart';
import 'modern_home_page.dart';
import 'modern_history_panel.dart';
import 'modern_bookmarks_panel.dart';
import 'modern_downloads_panel.dart';
import 'modern_settings_panel.dart';
import 'webview_service_panel.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/split_screen_service.dart';
import '../../widgets/splitscreen/advanced_split_view.dart';
import '../../widgets/terminal/native_terminal_panel.dart';
import '../../widgets/dev_tools/notilus_devtools_panel.dart';

// Intent pour les raccourcis clavier
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
    // Ouvrir les DevTools natifs de Notilus
    setState(() {
      if (_currentSection == SidebarSection.devtools) {
        // Si déjà ouvert, fermer
        _currentSection = SidebarSection.home;
      } else {
        // Ouvrir le panneau DevTools
        _currentSection = SidebarSection.devtools;
      }
    });
    
    // Logger l'action dans les DevTools
    try {
      final devTools = Provider.of<NotilusDevToolsService>(context, listen: false);
      devTools.logInfo('DevTools ${_currentSection == SidebarSection.devtools ? "opened" : "closed"} via F12', source: 'Keyboard');
    } catch (_) {}
  }

  void _openNativeDevTools() {
    // Ouvrir les DevTools natifs du WebView (Chrome DevTools)
    try {
      final tabManager = Provider.of<TabManager>(context, listen: false);
      final tabWebviewManager = Provider.of<TabWebViewManager>(context, listen: false);
      final activeTab = tabManager.activeTab;
      
      if (activeTab != null) {
        final engine = tabWebviewManager.getEngineForTab(activeTab.id);
        if (engine != null) {
          engine.openDevTools();
          
          // Logger l'action
          final devTools = Provider.of<NotilusDevToolsService>(context, listen: false);
          devTools.logInfo('Native DevTools opened for tab: ${activeTab.title ?? activeTab.url}', source: 'Sidebar');
        }
      }
    } catch (e) {
      debugPrint('Erreur ouverture DevTools natifs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.f12): _OpenDevToolsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyI): _OpenDevToolsIntent(),
      },
      child: Actions(
        actions: {
          _OpenDevToolsIntent: CallbackAction<_OpenDevToolsIntent>(
            onInvoke: (_) {
              _handleOpenDevTools();
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
                      isSidebarVisible: _isSidebarVisible,
                    ),
                    const GXAddressBar(),
                    Expanded(
                      child: Consumer2<SplitScreenService, TabManager>(
                        builder: (context, splitService, tabManager, _) {
                          // Si split-screen est actif ET visible, afficher la vue split
                          if (splitService.isActive && splitService.isVisible) {
                            return const AdvancedSplitView();
                          }
                          
                          // Sinon, afficher la vue normale
                          final activeTab = tabManager.activeTab;
                          if (activeTab == null) {
                            return ModernHomePage(
                              onTerminalSelected: () {
                                setState(() {
                                  _currentSection = SidebarSection.terminal;
                                });
                              },
                            );
                          }
                          
                          // Onglets web uniquement (terminal géré via sidebar)
                          if (activeTab.url == null ||
                              activeTab.url!.isEmpty ||
                              activeTab.url == 'about:blank' ||
                              activeTab.url == 'about:newtab') {
                            return ModernHomePage(
                              onTerminalSelected: () {
                                setState(() {
                                  _currentSection = SidebarSection.terminal;
                                });
                              },
                            );
                          }
                          return WebContentView(tab: activeTab);
                        },
                      ),
                    ),
                  ],
                ),
                // Menu latéral en position absolue à droite de la sidebar
                if (_isPanelVisible)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
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
      case SidebarSection.devtools:
        return _SidebarPanelConfig(
          title: 'DevTools',
          icon: CupertinoIcons.wrench_fill,
          child: const NotilusDevToolsPanel(),
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
        return null;
      case SidebarSection.docs:
        return _SidebarPanelConfig(
          title: 'Documentation',
          icon: CupertinoIcons.book,
          child: const _NotilusDocsPanel(),
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
              child: Text(
                'Widgets système',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _widgets.length,
                itemBuilder: (context, index) {
                  final widget = _widgets[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Builder(
                      builder: (context) {
                        final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
                        return Row(
                          children: [
                            Icon(widget.icon, color: gxRed, size: 18),
                            const SizedBox(width: 10),
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
                            Text(
                              widget.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _widgets = [
    _WidgetData('CPU', '32%', 'Utilisation processeur', CupertinoIcons.gauge),
    _WidgetData('RAM', '45%', 'Mémoire utilisée', Icons.memory),
    _WidgetData('GPU', '58°C', 'Température graphique', CupertinoIcons.speedometer),
    _WidgetData('Réseau', '1.1 Gbps', 'Bande passante', CupertinoIcons.waveform_path),
    _WidgetData('Onglets', '12', 'Onglets actifs', CupertinoIcons.square_grid_2x2),
    _WidgetData('Veille', 'Auto', 'Mode économie', CupertinoIcons.moon),
  ];
}

class _WidgetData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _WidgetData(this.title, this.value, this.subtitle, this.icon);
}

class _NotilusAiPanel extends StatelessWidget {
  const _NotilusAiPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: Text(
                'Hyper Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  const _AiToggleTile(
                    title: 'Assistant contextuel',
                    subtitle: 'Analyse la page et propose des actions rapides',
                    value: true,
                  ),
                  const SizedBox(height: 8),
                  const _AiToggleTile(
                    title: 'Résumé instantané',
                    subtitle: 'Synthétise les articles longs en un clic',
                    value: false,
                  ),
                  const SizedBox(height: 8),
                  const _AiToggleTile(
                    title: 'Protection intelligente',
                    subtitle: 'Bloque les scripts suspects en arrière plan',
                    value: true,
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
                      final gxRedDark = Provider.of<ColorThemeManager>(context, listen: true).primaryDarkColor;
                      return Container(
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
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hyper prompts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Glissez-déposez une URL ou un texte ici pour générer des commandes Notilus.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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

  const _AiToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
              return Switch(
                value: value,
                onChanged: (_) {},
                activeTrackColor: gxRed.withValues(alpha: 0.5),
                activeThumbColor: gxRed,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotilusUpdatesPanel extends StatelessWidget {
  const _NotilusUpdatesPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: Text(
                'Mises à jour',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: const [
                  _UpdateCard(
                    title: 'Nouvelle intégration: Speed Dial',
                    description: 'Ajout de la section Speed Dial avec grilles personnalisables',
                    date: 'Aujourd\'hui',
                    isNew: true,
                  ),
                  SizedBox(height: 8),
                  _UpdateCard(
                    title: 'Amélioration: Sidemenus',
                    description: 'Nouveaux menus latéraux avec animations fluides',
                    date: 'Hier',
                    isNew: false,
                  ),
                  SizedBox(height: 8),
                  _UpdateCard(
                    title: 'Optimisation: Performance',
                    description: 'Réduction de la consommation mémoire de 15%',
                    date: 'Il y a 3 jours',
                    isNew: false,
                  ),
                ],
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

  const _UpdateCard({
    required this.title,
    required this.description,
    required this.date,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
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
              if (isNew)
                Builder(
                  builder: (context) {
                    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
                    return Container(
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
                    );
                  },
                ),
              if (isNew) const SizedBox(width: 8),
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
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panneau de documentation de l'application
class _NotilusDocsPanel extends StatelessWidget {
  const _NotilusDocsPanel();

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: true);
    final accentColor = colorTheme.nativeSecondaryColor;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.2),
                  accentColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.book_fill, size: 32, color: accentColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notilus Browser',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Documentation v3.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // DevTools Section
          _DocsSection(
            title: '🔧 DevTools Notilus',
            accentColor: accentColor,
            items: const [
              _DocsItem(
                title: 'Console',
                description: 'Visualisez les logs de l\'application Flutter et des WebViews. Filtrez par niveau (info, warn, error, debug).',
                shortcut: 'Ctrl+Shift+I',
              ),
              _DocsItem(
                title: 'Network',
                description: 'Surveillez toutes les requêtes HTTP/HTTPS de Flutter et des WebViews. Voir headers, body, timing.',
              ),
              _DocsItem(
                title: 'Performance',
                description: 'Métriques temps réel: FPS, mémoire (ProcessInfo), CPU estimé, render time, nombre de widgets.',
              ),
              _DocsItem(
                title: 'Alerts',
                description: 'Alertes intelligentes automatiques: chute FPS, mémoire élevée, requêtes lentes, rafales d\'erreurs.',
                isNew: true,
              ),
              _DocsItem(
                title: 'Security',
                description: 'Audit de sécurité automatique: détection HTTP, clés API exposées, données sensibles.',
                isNew: true,
              ),
              _DocsItem(
                title: 'Widget Tree',
                description: 'Inspecteur d\'arbre Flutter: visualisez la hiérarchie des widgets, propriétés, bounds de rendu.',
                isNew: true,
              ),
              _DocsItem(
                title: 'Analytics',
                description: 'Statistiques par onglet, enregistrement de sessions, bookmarks, export de rapports JSON.',
                isNew: true,
              ),
              _DocsItem(
                title: 'Storage',
                description: 'Gérez les SharedPreferences: voir, modifier, supprimer les entrées de stockage local.',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Commandes REPL
          _DocsSection(
            title: '💻 Commandes Console REPL',
            accentColor: accentColor,
            items: const [
              _DocsItem(
                title: 'Console',
                description: 'help, clear, logs, echo <msg>',
              ),
              _DocsItem(
                title: 'Réseau',
                description: 'requests, fetch <url>',
              ),
              _DocsItem(
                title: 'Performance',
                description: 'perf, widgets',
              ),
              _DocsItem(
                title: 'Analytics',
                description: 'analytics, alerts, security',
                isNew: true,
              ),
              _DocsItem(
                title: 'Session',
                description: 'record [start|stop], sessions',
                isNew: true,
              ),
              _DocsItem(
                title: 'Storage',
                description: 'storage, get <key>, set <k> <v>, del <key>',
              ),
              _DocsItem(
                title: 'Utilitaires',
                description: 'bookmark <t>, export, monitor, env, time, json <str>, version',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Navigation
          _DocsSection(
            title: '🧭 Navigation',
            accentColor: accentColor,
            items: const [
              _DocsItem(
                title: 'Sidebar',
                description: 'Accès rapide: Accueil, Favoris, Historique, Téléchargements, Widgets, AI, Paramètres, Terminal, DevTools, Documentation.',
              ),
              _DocsItem(
                title: 'Onglets',
                description: 'Glissez pour réorganiser, clic molette pour fermer, double-clic pour renommer.',
              ),
              _DocsItem(
                title: 'Split Screen',
                description: 'Divisez l\'écran pour afficher plusieurs pages simultanément.',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Raccourcis
          _DocsSection(
            title: '⌨️ Raccourcis clavier',
            accentColor: accentColor,
            items: const [
              _DocsItem(
                title: 'F12',
                description: 'Ouvrir/fermer les DevTools Notilus',
              ),
              _DocsItem(
                title: 'Ctrl+Shift+I',
                description: 'Ouvrir/fermer les DevTools Notilus (alternatif)',
              ),
              _DocsItem(
                title: 'Ctrl+T',
                description: 'Nouvel onglet',
              ),
              _DocsItem(
                title: 'Ctrl+W',
                description: 'Fermer l\'onglet actif',
              ),
              _DocsItem(
                title: 'Ctrl+R',
                description: 'Recharger la page',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Services intégrés
          _DocsSection(
            title: '🌐 Services intégrés',
            accentColor: accentColor,
            items: const [
              _DocsItem(
                title: 'YouTube Music',
                description: 'Écoutez de la musique en arrière-plan via la sidebar.',
              ),
              _DocsItem(
                title: 'YouTube',
                description: 'Regardez des vidéos dans un panneau dédié.',
              ),
              _DocsItem(
                title: 'ChatGPT',
                description: 'Accès rapide à l\'assistant IA d\'OpenAI.',
              ),
              _DocsItem(
                title: 'DeepSeek',
                description: 'Assistant IA alternatif.',
              ),
              _DocsItem(
                title: 'WhatsApp / Telegram',
                description: 'Messageries intégrées dans la sidebar.',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Version info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.info, size: 16, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notilus Browser v3.0.0 • DevTools Advanced Edition\nMis à jour: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocsSection extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<_DocsItem> items;

  const _DocsSection({
    required this.title,
    required this.accentColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.map((item) => _buildDocItem(item, accentColor)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem(_DocsItem item, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: item.isNew
            ? Border.all(color: accentColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: item.isNew ? accentColor : Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (item.shortcut != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.shortcut!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocsItem {
  final String title;
  final String description;
  final String? shortcut;
  final bool isNew;

  const _DocsItem({
    required this.title,
    required this.description,
    this.shortcut,
    this.isNew = false,
  });
}
