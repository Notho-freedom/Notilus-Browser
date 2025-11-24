import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
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

  bool get _isPanelVisible => _currentSection != SidebarSection.home;

  void _closePanel() {
    if (_currentSection != SidebarSection.home) {
      setState(() {
        _currentSection = SidebarSection.home;
      });
    }
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
                      child: Consumer<TabManager>(
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
                    ),
                  ],
                ),
                // Menu latéral en position absolue à droite de la sidebar
                if (_isPanelVisible)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: 380,
                      child: _buildSideMenu(context),
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

  Widget _buildSideMenu(BuildContext context) {
    final config = _panelConfigForSection();
    if (config == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: NotilusColors.chromeDark,
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
                      fontSize: 14,
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
    final cards = const [
      _WidgetCardData('Température GPU', '58°C', CupertinoIcons.speedometer),
      _WidgetCardData('Réseau', '1.1 Gbps', CupertinoIcons.waveform_path),
      _WidgetCardData('Veille onglets', 'Auto', CupertinoIcons.moon),
      _WidgetCardData('Mode Focus', 'Actif', CupertinoIcons.scope),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
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
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
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
