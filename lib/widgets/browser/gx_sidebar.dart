import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/animations/notilus_animations.dart';
import 'package:flutter/services.dart';
import '../../services/tab_manager.dart';
import '../../services/settings_service.dart';
import '../../services/mosaic_service.dart';
import '../common/notilus_logo_image.dart';
import '../common/notilus_tooltip.dart';

// La couleur rouge est maintenant gérée par ColorThemeManager

enum SidebarSection {
  home,
  favorites,
  history,
  downloads,
  widgets,
  ai,
  settings,
  updates,
  extensions,
  terminal,
  nativeDevtools,
  mosaic,
  docs,
  studio,
  lighthouse,
  github,
  testPanel,
  youtubeMusic,
  youtube,
  chatgpt,
  deepseek,
  whatsapp,
  telegram,
}

class GXSidebar extends StatefulWidget {
  final VoidCallback? onClose;
  final ValueChanged<SidebarSection>? onSectionSelected;
  final SidebarSection? currentSection;
  
  const GXSidebar({
    super.key,
    this.onClose,
    this.onSectionSelected,
    this.currentSection,
  });

  @override
  State<GXSidebar> createState() => _GXSidebarState();
}

class _GXSidebarState extends State<GXSidebar> {
  int _selectedIndex = 0;
  int _hoveredIndex = -1;
  final SettingsService _settings = SettingsService();
  final List<_SidebarDestination> _destinations = const [
    _SidebarDestination(
      section: SidebarSection.home,
      icon: CupertinoIcons.square_grid_2x2,
      label: 'Accueil',
    ),
    _SidebarDestination(
      section: SidebarSection.favorites,
      icon: CupertinoIcons.bookmark,
      label: 'Favoris',
    ),
    _SidebarDestination(
      section: SidebarSection.history,
      icon: CupertinoIcons.time,
      label: 'Historique',
    ),
    _SidebarDestination(
      section: SidebarSection.downloads,
      icon: CupertinoIcons.arrow_down_to_line,
      label: 'Téléchargements',
    ),
    _SidebarDestination(
      section: SidebarSection.widgets,
      icon: CupertinoIcons.layers_alt,
      label: 'Widgets dynamiques',
    ),
    _SidebarDestination(
      section: SidebarSection.ai,
      icon: CupertinoIcons.sparkles,
      label: 'Hyper Assistant',
    ),
    _SidebarDestination(
      section: SidebarSection.settings,
      icon: CupertinoIcons.gear_alt,
      label: 'Paramètres',
    ),
    _SidebarDestination(
      section: SidebarSection.updates,
      icon: CupertinoIcons.arrow_up_circle,
      label: 'Mises à jour',
    ),
    _SidebarDestination(
      section: SidebarSection.terminal,
      icon: CupertinoIcons.square_list,
      label: 'Terminal',
    ),
    _SidebarDestination(
      section: SidebarSection.nativeDevtools,
      icon: CupertinoIcons.ant,
      label: 'DevTools (F12)',
    ),
    _SidebarDestination(
      section: SidebarSection.mosaic,
      icon: CupertinoIcons.square_grid_2x2_fill,
      label: 'Mosaïque',
    ),
    _SidebarDestination(
      section: SidebarSection.studio,
      icon: CupertinoIcons.paintbrush,
      label: 'Studio (Tests Front-End)',
    ),
    _SidebarDestination(
      section: SidebarSection.lighthouse,
      icon: CupertinoIcons.gauge,
      label: 'Lighthouse (Analyse)',
    ),
    _SidebarDestination(
      section: SidebarSection.github,
      icon: Icons.code,
      label: 'Mes Dépôts GitHub',
    ),
    _SidebarDestination(
      section: SidebarSection.docs,
      icon: CupertinoIcons.book,
      label: 'Documentation',
    ),
    _SidebarDestination(
      section: SidebarSection.testPanel,
      icon: CupertinoIcons.square_grid_2x2,
      label: 'Test Panel GX',
    ),
  ];

  // Tous les services web disponibles
  static const List<_WebServiceConfig> _allWebServices = [
    _WebServiceConfig(
      id: 'youtubeMusic',
      url: 'https://music.youtube.com',
      icon: CupertinoIcons.music_note,
      label: 'YouTube Music',
      section: SidebarSection.youtubeMusic,
    ),
    _WebServiceConfig(
      id: 'youtube',
      url: 'https://www.youtube.com',
      icon: CupertinoIcons.play_circle,
      label: 'YouTube',
      section: SidebarSection.youtube,
    ),
    _WebServiceConfig(
      id: 'chatgpt',
      url: 'https://chat.openai.com',
      icon: CupertinoIcons.chat_bubble_2,
      label: 'ChatGPT',
      section: SidebarSection.chatgpt,
    ),
    _WebServiceConfig(
      id: 'deepseek',
      url: 'https://chat.deepseek.com',
      icon: CupertinoIcons.sparkles,
      label: 'DeepSeek',
      section: SidebarSection.deepseek,
    ),
    _WebServiceConfig(
      id: 'whatsapp',
      url: 'https://web.whatsapp.com',
      icon: CupertinoIcons.chat_bubble_text,
      label: 'WhatsApp',
      section: SidebarSection.whatsapp,
    ),
    _WebServiceConfig(
      id: 'telegram',
      url: 'https://web.telegram.org',
      icon: CupertinoIcons.paperplane,
      label: 'Telegram',
      section: SidebarSection.telegram,
    ),
  ];
  
  // Services web filtrés par les paramètres
  List<_WebServiceDestination> _getWebServices(Color gxRed) {
    return _allWebServices
        .where((config) => _settings.isWebServiceEnabled(config.id))
        .map((config) => _WebServiceDestination(
              url: config.url,
              icon: config.icon,
              label: config.label,
              color: gxRed,
              section: config.section,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final webServices = _getWebServices(gxRed);
    
    return RepaintBoundary(
      child: Container(
        width: 50,
        color: colorThemeManager.nativeBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                const SizedBox(height: 10),
                const NotilusMonogramImage(
                  size: 24,
                  showGlow: false,
                  showFrame: true,
                ),
                const SizedBox(height: 18),
                // Zone scrollable pour les icônes
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < _destinations.length; i++) ...[
                          NotilusTooltip(
                            message: _destinations[i].label,
                            child: _GXSidebarIcon(
                              icon: _destinations[i].icon,
                              isSelected: widget.currentSection == _destinations[i].section,
                              isHovered: _hoveredIndex == i,
                              onTap: () {
                                // Si la section est déjà sélectionnée, fermer le panel
                                if (widget.currentSection == _destinations[i].section && _destinations[i].section != SidebarSection.home) {
                                  widget.onSectionSelected?.call(SidebarSection.home);
                                  return;
                                }
                                
                                setState(() {
                                  _selectedIndex = i;
                                });
                                if (_destinations[i].section == SidebarSection.home) {
                                  Provider.of<TabManager>(context, listen: false)
                                      .addTab(url: 'about:newtab');
                                } else if (_destinations[i].section == SidebarSection.mosaic) {
                                  final mosaicService = Provider.of<NotilusMosaicService>(context, listen: false);
                                  final tabManager = Provider.of<TabManager>(context, listen: false);
                                  final activeTabId = tabManager.activeTab?.id;
                                  
                                  // Si la mosaic est cachée, la réafficher
                                  if (!mosaicService.isVisible) {
                                    mosaicService.setVisible(true);
                                  }
                                  
                                  // Toggle l'état actif
                                  mosaicService.toggle(activeTabId: activeTabId);
                                  HapticFeedback.mediumImpact();
                                  return;
                                }
                                widget.onSectionSelected?.call(_destinations[i].section);
                              },
                              onHover: (hover) => setState(() => _hoveredIndex = hover ? i : -1),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 1,
                          color: gxRed.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        // Services web
                        for (int i = 0; i < webServices.length; i++) ...[
                          NotilusTooltip(
                            message: webServices[i].label,
                            child: _GXSidebarWebServiceIcon(
                              icon: webServices[i].icon,
                              color: webServices[i].color,
                              isHovered: _hoveredIndex == _destinations.length + i,
                              onTap: () {
                                // Si la section web service est déjà sélectionnée, fermer le panel
                                if (widget.currentSection == webServices[i].section) {
                                  widget.onSectionSelected?.call(SidebarSection.home);
                                  return;
                                }
                                
                                setState(() {
                                  _selectedIndex = -1;
                                });
                                widget.onSectionSelected?.call(webServices[i].section);
                              },
                              onHover: (hover) => setState(() => _hoveredIndex = hover ? _destinations.length + i : -1),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        const SizedBox(height: 20),
                        const _SidebarSignature(),
                      ],
                    ),
                  ),
                ),
                const _SidebarVerticalLabel(),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GXSidebarIcon extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _GXSidebarIcon({
    required this.icon,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_GXSidebarIcon> createState() => _GXSidebarIconState();
}

class _GXSidebarIconState extends State<_GXSidebarIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_GXSidebarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered && !oldWidget.isHovered) {
      _controller.forward();
    } else if (!widget.isHovered && oldWidget.isHovered && !_isPressed) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    if (!widget.isHovered) _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    if (!widget.isHovered) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = _isPressed ? _bounceAnimation.value : _scaleAnimation.value;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: SizedBox(
            width: 48,
            height: 40,
            child: Stack(
              children: [
                // Barre de sélection à gauche avec animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  top: widget.isSelected ? 8 : 18,
                  bottom: widget.isSelected ? 8 : 18,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: widget.isSelected ? 3 : 0,
                    decoration: BoxDecoration(
                      color: gxRed,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: gxRed.withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
                
                // Fond au hover/sélection avec animation de glow
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? gxRed.withValues(alpha: 0.18)
                          : (widget.isHovered
                              ? gxRed.withValues(alpha: 0.12)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: widget.isHovered || widget.isSelected
                          ? [
                              BoxShadow(
                                color: gxRed.withValues(alpha: widget.isSelected ? 0.3 : 0.15),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0.0,
                        end: widget.isSelected ? 1.0 : (widget.isHovered ? 0.9 : 0.65),
                      ),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, opacity, _) {
                        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
                        final iconColor = colorThemeManager.getIconColor();
                        return Icon(
                          widget.icon,
                          size: 20,
                          color: iconColor.withValues(alpha: opacity),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSignature extends StatelessWidget {
  const _SidebarSignature();

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    return Container(
      width: 32,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gxRed.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: gxRed,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: gxRed.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NX',
            style: TextStyle(
              color: gxRed.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'CORE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarDestination {
  final SidebarSection section;
  final IconData icon;
  final String label;

  const _SidebarDestination({
    required this.section,
    required this.icon,
    required this.label,
  });
}

class _WebServiceDestination {
  final String url;
  final IconData icon;
  final String label;
  final Color color;
  final SidebarSection section;

  const _WebServiceDestination({
    required this.url,
    required this.icon,
    required this.label,
    required this.color,
    required this.section,
  });
}

class _WebServiceConfig {
  final String id;
  final String url;
  final IconData icon;
  final String label;
  final SidebarSection section;

  const _WebServiceConfig({
    required this.id,
    required this.url,
    required this.icon,
    required this.label,
    required this.section,
  });
}

class _GXSidebarWebServiceIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _GXSidebarWebServiceIcon({
    required this.icon,
    required this.color,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_GXSidebarWebServiceIcon> createState() => _GXSidebarWebServiceIconState();
}

class _GXSidebarWebServiceIconState extends State<_GXSidebarWebServiceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_GXSidebarWebServiceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered && !oldWidget.isHovered) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: Transform.scale(
                scale: _isPressed ? 0.9 : (widget.isHovered ? 1.1 : 1.0),
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: 48,
            height: 40,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isHovered
                      ? widget.color.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: widget.isHovered
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0.0,
                    end: widget.isHovered ? 1.0 : 0.7,
                  ),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, opacity, _) {
                    return Icon(
                      widget.icon,
                      size: 18,
                      color: widget.color.withOpacity(opacity),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarVerticalLabel extends StatelessWidget {
  const _SidebarVerticalLabel();

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    return RotatedBox(
      quarterTurns: 3,
      child: Text(
        'NOTILUS BETA',
        style: TextStyle(
          color: gxRed.withValues(alpha: 0.7),
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
