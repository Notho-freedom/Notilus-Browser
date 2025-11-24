import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import '../../core/constants/notilus_colors.dart';
import '../common/sidebar_panel_scope.dart';
import '../common/notilus_tooltip.dart';

class ModernBrowserWindow extends StatefulWidget {
  const ModernBrowserWindow({super.key});

  @override
  State<ModernBrowserWindow> createState() => _ModernBrowserWindowState();
}

class _ModernBrowserWindowState extends State<ModernBrowserWindow>
    with SingleTickerProviderStateMixin {
  bool _isSidebarVisible = true;
  SidebarSection _currentSection = SidebarSection.home;
  static const double _panelMinFactor = 0.25;
  static const double _panelMaxFactor = 0.5;
  double _panelWidthFactor = 0.36;
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

  bool get _isPanelVisible => _currentSection != SidebarSection.home;

  void _closePanel() {
    if (_currentSection != SidebarSection.home) {
      setState(() {
        _currentSection = SidebarSection.home;
      });
    }
  }

  void _handlePanelResize(double delta, double totalWidth) {
    final currentWidth = _panelWidthFactor * totalWidth;
    final desiredWidth = (currentWidth - delta)
        .clamp(totalWidth * _panelMinFactor, totalWidth * _panelMaxFactor);
    setState(() {
      _panelWidthFactor = desiredWidth / totalWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: SidebarPanelScope(
          openPanel: (section) {
            setState(() {
              if (!_isSidebarVisible) {
                _isSidebarVisible = true;
                _sidebarAnimationController.forward();
              }
              _currentSection = section;
            });
          },
          closePanel: _closePanel,
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

              // Zone principale
              Expanded(
                child: Column(
                  children: [
                    GXTabBar(
                      onMenuTap: _toggleSidebar,
                      isSidebarVisible: _isSidebarVisible,
                    ),
                    const GXAddressBar(),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Consumer<TabManager>(
                            builder: (context, tabManager, _) {
                              final activeTab = tabManager.activeTab;
                              if (activeTab == null ||
                                  activeTab.url == null ||
                                  activeTab.url!.isEmpty ||
                                  activeTab.url == 'about:blank' ||
                                  activeTab.url == 'about:newtab') {
                                return const ModernHomePage();
                              }
                              return WebContentView(tab: activeTab);
                            },
                          ),
                          _buildSidebarPanelOverlay(context),
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
    );
  }

  Widget _buildSidebarPanelOverlay(BuildContext context) {
    final config = _panelConfigForSection();
    if (config == null) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final double minWidth = media.size.width * _panelMinFactor;
    final double maxWidth = media.size.width * _panelMaxFactor;
    final double width =
        (media.size.width * _panelWidthFactor).clamp(minWidth, maxWidth);
    final bool visible = _isPanelVisible;
    const double toolbarHeight = 36 + 34;
    final double topOffset = toolbarHeight + 6;

    return IgnorePointer(
      ignoring: !visible,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: visible ? 0.15 : 0,
            child: GestureDetector(
              onTap: _closePanel,
              child: Container(color: Colors.black),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            top: topOffset,
            bottom: 16,
            left: visible ? 44 : -(width + 120),
            child: SizedBox(
              width: width,
              child: _SidebarFloatingPanel(
                title: config.title,
                icon: config.icon,
                onClose: _closePanel,
                onResize: (delta) => _handlePanelResize(delta, media.size.width),
                child: config.child,
              ),
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
      case SidebarSection.home:
      default:
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

class _SidebarFloatingPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onClose;
  final ValueChanged<double>? onResize;

  const _SidebarFloatingPanel({
    required this.title,
    required this.icon,
    required this.child,
    required this.onClose,
    this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                color: NotilusColors.chromeLight.withOpacity(0.96),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          NotilusColors.neonRed.withOpacity(0.85),
                          NotilusColors.neonRedDark.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        NotilusTooltip(
                          message: 'Replier le panneau',
                          child: IconButton(
                            onPressed: onClose,
                            icon: const Icon(
                              CupertinoIcons.xmark_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.black.withOpacity(0.08),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onResize != null)
            Positioned(
              left: -12,
              top: 72,
              bottom: 72,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) =>
                    onResize!(details.delta.dx),
                child: Container(
                  width: 18,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Center(
                    child: Container(
                      width: 2,
                      height: double.infinity,
                      color: NotilusColors.neonRed.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotilusWidgetsPanel extends StatelessWidget {
  const _NotilusWidgetsPanel();

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _WidgetCardData('Température GPU', '58°C', CupertinoIcons.speedometer),
      _WidgetCardData('Réseau', '1.1 Gbps', CupertinoIcons.waveform_path),
      _WidgetCardData('Veille onglets', 'Auto', CupertinoIcons.moon),
      _WidgetCardData('Mode Focus', 'Actif', CupertinoIcons.scope),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(card.icon, color: NotilusColors.neonRed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Statut en temps réel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                card.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotilusAiPanel extends StatelessWidget {
  const _NotilusAiPanel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _AiToggleTile(
          title: 'Assistant contextuel',
          subtitle: 'Analyse la page et propose des actions rapides',
          value: true,
        ),
        _AiToggleTile(
          title: 'Résumé instantané',
          subtitle: 'Synthétise les articles longs en un clic',
          value: false,
        ),
        _AiToggleTile(
          title: 'Protection intelligente',
          subtitle: 'Bloque les scripts suspects en arrière plan',
          value: true,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                NotilusColors.neonRed.withOpacity(0.2),
                NotilusColors.neonRedDark.withOpacity(0.2),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hyper prompts',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Glissez-déposez une URL ou un texte ici pour générer des commandes Notilus.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
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

class _WidgetCardData {
  final String title;
  final String value;
  final IconData icon;

  const _WidgetCardData(this.title, this.value, this.icon);
}
