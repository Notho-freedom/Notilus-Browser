import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
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
import '../../core/constants/notilus_colors.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/split_screen_service.dart';
import '../../widgets/splitscreen/advanced_split_view.dart';
import '../../widgets/terminal/terminal_panel.dart';
import '../../widgets/terminal/gx_terminal_view.dart';
import '../../models/tab_model.dart' show TabType;

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

  void _handleOpenDevTools() async {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
    final activeTab = tabManager.activeTab;
    
    if (activeTab != null && activeTab.url != null && activeTab.url!.isNotEmpty) {
      final engine = webViewManager.getEngineForTab(activeTab.id, url: activeTab.url);
      await engine.openDevTools();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF2D55),
                  Color(0x00FF2D55),
                ],
              ),
            ),
            child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0B0B0E),
          border: Border.all(
            color: Colors.white.withOpacity(0.02),
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
                          
                          // Gérer les différents types d'onglets
                          if (activeTab.type == TabType.terminal) {
                            return GXTerminalView(tab: activeTab);
                          }
                          
                          // Onglets web
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
                                    ? const Color(0xFFFF2D55).withOpacity(0.8)
                                    : Colors.transparent,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2D55).withOpacity(0.3),
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

    return Container(
      decoration: BoxDecoration(
        color: NotilusColors.chrome,
        border: Border(
          right: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.3),
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
              color: NotilusColors.chrome,
              border: Border(
                bottom: BorderSide(
                  color: NotilusColors.neonRed.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(config.icon, color: NotilusColors.neonRed, size: 18),
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
                      color: Colors.white.withOpacity(0.7),
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
              color: Colors.black.withOpacity(0.05),
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
          child: const TerminalPanel(),
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
        return null;
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
            Colors.black.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
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
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: NotilusColors.neonRed, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          widget.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
            Colors.black.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
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
                  _AiToggleTile(
                    title: 'Assistant contextuel',
                    subtitle: 'Analyse la page et propose des actions rapides',
                    value: true,
                  ),
                  const SizedBox(height: 8),
                  _AiToggleTile(
                    title: 'Résumé instantané',
                    subtitle: 'Synthétise les articles longs en un clic',
                    value: false,
                  ),
                  const SizedBox(height: 8),
                  _AiToggleTile(
                    title: 'Protection intelligente',
                    subtitle: 'Bloque les scripts suspects en arrière plan',
                    value: true,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          NotilusColors.neonRed.withOpacity(0.15),
                          NotilusColors.neonRedDark.withOpacity(0.15),
                        ],
                      ),
                      border: Border.all(
                        color: NotilusColors.neonRed.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
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
                        const SizedBox(height: 6),
                        Text(
                          'Glissez-déposez une URL ou un texte ici pour générer des commandes Notilus.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
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
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) {},
            activeColor: NotilusColors.neonRed,
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
            Colors.black.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
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
                children: [
                  _UpdateCard(
                    title: 'Nouvelle intégration: Speed Dial',
                    description: 'Ajout de la section Speed Dial avec grilles personnalisables',
                    date: 'Aujourd\'hui',
                    isNew: true,
                  ),
                  const SizedBox(height: 8),
                  _UpdateCard(
                    title: 'Amélioration: Sidemenus',
                    description: 'Nouveaux menus latéraux avec animations fluides',
                    date: 'Hier',
                    isNew: false,
                  ),
                  const SizedBox(height: 8),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isNew
              ? NotilusColors.neonRed.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: NotilusColors.neonRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NOUVEAU',
                    style: TextStyle(
                      color: NotilusColors.neonRed,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isNew) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
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
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
