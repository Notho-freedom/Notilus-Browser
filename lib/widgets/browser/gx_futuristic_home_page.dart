/// Écran d'accueil futuriste Notilus GX
/// Design ultra-précis avec contours géométriques façon OS Science-Fiction
library gx_futuristic_home_page;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/quick_access_service.dart';
import '../../services/history_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/system_metrics_service.dart';
import '../../services/settings_service.dart';
import '../../models/history_item.dart';
import '../../models/bookmark.dart';
import '../../services/favicon_service.dart';
import '../../core/utils/url_validator.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../common/notilus_monogram.dart';
import '../common/context_menu.dart';
import '../common/gx_futuristic_components.dart';
import '../common/gx_futuristic_dialog.dart';
import '../../services/gx_notification_service.dart';

class GxFuturisticHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  
  const GxFuturisticHomePage({
    super.key,
    this.onTerminalSelected,
  });

  @override
  State<GxFuturisticHomePage> createState() => _GxFuturisticHomePageState();
}

class _GxFuturisticHomePageState extends State<GxFuturisticHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final QuickAccessService _quickAccessService = QuickAccessService();
  final HistoryService _historyService = HistoryService();
  final SystemMetricsService _metricsService = SystemMetricsService();
  final SettingsService _settings = SettingsService();
  
  List<QuickAccessItem> _quickAccessItems = [];
  List<HistoryItem> _recentHistory = [];
  bool _leftColumnExpanded = false;
  bool _rightColumnExpanded = false;
  
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _scanlineController;
  
  @override
  void initState() {
    super.initState();
    _loadColumnStates();
    _loadQuickAccessItems();
    _loadRecentHistory();
    _metricsService.addListener(_onMetricsUpdate);
    _settings.addListener(_onSettingsChanged);
    
    // Contrôleurs d'animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanlineController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabManager = Provider.of<TabManager>(context, listen: false);
      _metricsService.updateTabCount(tabManager.tabs.length);
    });
  }
  
  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _leftColumnExpanded = _settings.leftColumnExpanded;
        _rightColumnExpanded = _settings.rightColumnExpanded;
      });
    }
  }
  
  void _loadColumnStates() {
    _leftColumnExpanded = _settings.leftColumnExpanded;
    _rightColumnExpanded = _settings.rightColumnExpanded;
  }
  
  void _saveColumnStates() {
    _settings.setLeftColumnExpanded(_leftColumnExpanded);
    _settings.setRightColumnExpanded(_rightColumnExpanded);
  }

  void _onMetricsUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _metricsService.removeListener(_onMetricsUpdate);
    _settings.removeListener(_onSettingsChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _scanlineController.dispose();
    super.dispose();
  }

  Future<void> _loadQuickAccessItems() async {
    final items = await _quickAccessService.getQuickAccessItems();
    if (items.isEmpty) {
      final defaultItems = [
        await _quickAccessService.extractSiteInfo('https://github.com'),
        await _quickAccessService.extractSiteInfo('https://google.com'),
        await _quickAccessService.extractSiteInfo('https://youtube.com'),
        await _quickAccessService.extractSiteInfo('https://stackoverflow.com'),
      ];
      for (final item in defaultItems) {
        if (item != null) {
          await _quickAccessService.addQuickAccessItem(item);
        }
      }
      await _loadQuickAccessItems();
    } else {
      setState(() {
        _quickAccessItems = items;
      });
    }
  }

  Future<void> _loadRecentHistory() async {
    final history = await _historyService.getHistory();
    setState(() {
      _recentHistory = history.take(5).toList();
    });
  }

  Future<void> _addQuickAccessSite() async {
    final controller = TextEditingController();
    final result = await GxFuturisticDialog.show<String>(
      context: context,
      title: 'Ajouter un site rapide',
      titleIcon: CupertinoIcons.add_circled,
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GxFuturisticInput(
            controller: controller,
            hint: 'https://example.com',
            label: 'URL du site',
            prefixIcon: CupertinoIcons.globe,
          ),
        ],
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GxFuturisticButton(
          label: 'Ajouter',
          icon: CupertinoIcons.check_mark,
          variant: GxFuturisticButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(controller.text),
        ),
      ],
    );

    if (result != null && result.isNotEmpty) {
      final url = UrlValidator.validateAndFormat(result) ?? result;
      final item = await _quickAccessService.extractSiteInfo(url);
      if (item != null) {
        await _quickAccessService.addQuickAccessItem(item);
        await _loadQuickAccessItems();
        if (mounted) {
          GxNotificationService().showSuccess(
            title: 'Site ajouté',
            message: 'Le site a été ajouté à vos sites rapides',
            context: context,
          );
        }
      }
    }
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    final tabManager = Provider.of<TabManager>(context, listen: false);
    String url = query.trim();
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      }
    }

    tabManager.addTab(url: url);
  }

  void _openQuickAccess(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  void _showQuickAccessContextMenu(QuickAccessItem item) {
    ContextMenu.show(
      context: context,
      actions: [
        ContextMenuAction(
          label: 'Ouvrir dans un nouvel onglet',
          icon: CupertinoIcons.add,
          onTap: () => _openQuickAccess(item.url),
        ),
        ContextMenuAction(
          label: 'Supprimer',
          icon: CupertinoIcons.delete,
          isDestructive: true,
          onTap: () async {
            await _quickAccessService.removeQuickAccessItem(item.id);
            await _loadQuickAccessItems();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final wallpaperManager = context.watch<WallpaperManager>();
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(wallpaperManager.current),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Particules animées en arrière-plan
            _ParticleBackground(
              controller: _particleController,
              accentColor: accentColor,
            ),
            
            // Scanlines animées
            _ScanlineOverlay(
              controller: _scanlineController,
              accentColor: accentColor,
            ),
            
            // Contenu principal
            SafeArea(
              child: Row(
                children: [
                  // Colonne gauche - Dev Tools
                  _buildLeftColumn(context, accentColor, bgColor, panelOpacity),
                  
                  // Contenu central
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              
                              // Logo avec effet de glow
                              _GlowLogo(
                                controller: _glowController,
                                accentColor: accentColor,
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack),
                              
                              const SizedBox(height: 40),
                              
                              // Titre principal
                              Text(
                                'NOTILUS GX',
                                style: NotilusFonts.orbitron(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 150.ms)
                                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                              
                              const SizedBox(height: 12),
                              
                              // Sous-titre
                              Text(
                                'SYSTEM INITIALIZED • READY FOR OPERATION',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor.withOpacity(0.8),
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 250.ms)
                                  .slideY(begin: 0.1, end: 0),
                              
                              const SizedBox(height: 60),
                              
                              // Barre de recherche futuriste
                              _FuturisticSearchBar(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                accentColor: accentColor,
                                bgColor: bgColor,
                                panelOpacity: panelOpacity,
                                onSubmitted: _handleSearch,
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 350.ms)
                                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                              
                              const SizedBox(height: 60),
                              
                              // Métriques système
                              if (_settings.showSystemWidgets) ...[
                                _SystemMetricsGrid(
                                  metricsService: _metricsService,
                                  accentColor: accentColor,
                                  bgColor: bgColor,
                                  panelOpacity: panelOpacity,
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms, delay: 450.ms)
                                    .slideY(begin: 0.1, end: 0),
                                const SizedBox(height: 50),
                              ],
                              
                              // Sites rapides
                              if (_settings.showQuickAccess) ...[
                                _SectionHeader(
                                  title: 'QUICK ACCESS',
                                  accentColor: accentColor,
                                  onAdd: _addQuickAccessSite,
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms, delay: 500.ms),
                                const SizedBox(height: 24),
                                _QuickAccessGrid(
                                  items: _quickAccessItems,
                                  accentColor: accentColor,
                                  bgColor: bgColor,
                                  panelOpacity: panelOpacity,
                                  onTap: _openQuickAccess,
                                  onLongPress: _showQuickAccessContextMenu,
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms, delay: 550.ms),
                                const SizedBox(height: 50),
                              ],
                              
                              // Historique récent
                              if (_settings.showRecentHistory && _recentHistory.isNotEmpty) ...[
                                _SectionHeader(
                                  title: 'RECENT HISTORY',
                                  accentColor: accentColor,
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms, delay: 600.ms),
                                const SizedBox(height: 24),
                                _HistoryGrid(
                                  items: _recentHistory,
                                  accentColor: accentColor,
                                  bgColor: bgColor,
                                  panelOpacity: panelOpacity,
                                  onTap: _openQuickAccess,
                                )
                                    .animate()
                                    .fadeIn(duration: 500.ms, delay: 650.ms),
                              ],
                              
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Colonne droite - Quick Actions
                  _buildRightColumn(context, accentColor, bgColor, panelOpacity),
                ],
              ),
            ),
            
            // Labels latéraux
            _buildSideLabels(context, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, Color accentColor, Color? bgColor, double panelOpacity) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        width: _leftColumnExpanded ? 280 : 0,
        decoration: BoxDecoration(
          color: bgColor?.withOpacity(panelOpacity.clamp(0.0, 1.0)),
          border: _leftColumnExpanded
              ? Border(
                  right: BorderSide(
                    color: accentColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                )
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: _leftColumnExpanded
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEV TOOLS',
                      style: NotilusFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DevToolCard(
                      icon: CupertinoIcons.doc_text,
                      title: 'Code Editor',
                      subtitle: 'VS Code',
                      accentColor: accentColor,
                      bgColor: bgColor,
                      panelOpacity: panelOpacity,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _DevToolCard(
                      icon: CupertinoIcons.square_list,
                      title: 'Terminal',
                      subtitle: 'Ouvrir le terminal',
                      accentColor: accentColor,
                      bgColor: bgColor,
                      panelOpacity: panelOpacity,
                      onTap: () => widget.onTerminalSelected?.call(),
                    ),
                    const SizedBox(height: 12),
                    _DevToolCard(
                      icon: CupertinoIcons.doc_text_search,
                      title: 'API Docs',
                      subtitle: 'REST Client',
                      accentColor: accentColor,
                      bgColor: bgColor,
                      panelOpacity: panelOpacity,
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    GxFuturisticCard(
                      accentColor: accentColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SYSTEM STATUS',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListenableBuilder(
                            listenable: _metricsService,
                            builder: (context, _) => _MetricRow(
                              label: 'CPU',
                              value: '${_metricsService.cpuUsage.toStringAsFixed(0)}%',
                              accentColor: accentColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ListenableBuilder(
                            listenable: _metricsService,
                            builder: (context, _) => _MetricRow(
                              label: 'RAM',
                              value: '${_metricsService.ramUsage.toStringAsFixed(0)}%',
                              accentColor: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context, Color accentColor, Color? bgColor, double panelOpacity) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        width: _rightColumnExpanded ? 280 : 0,
        decoration: BoxDecoration(
          color: bgColor?.withOpacity(panelOpacity.clamp(0.0, 1.0)),
          border: _rightColumnExpanded
              ? Border(
                  left: BorderSide(
                    color: accentColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                )
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: _rightColumnExpanded
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUICK ACTIONS',
                      style: NotilusFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DevToolCard(
                      icon: CupertinoIcons.cloud,
                      title: 'GitHub',
                      subtitle: 'Repositories',
                      accentColor: accentColor,
                      bgColor: bgColor,
                      panelOpacity: panelOpacity,
                      onTap: () => _openQuickAccess('https://github.com'),
                    ),
                    const SizedBox(height: 12),
                    _DevToolCard(
                      icon: CupertinoIcons.doc_on_doc,
                      title: 'Stack Overflow',
                      subtitle: 'Q&A',
                      accentColor: accentColor,
                      bgColor: bgColor,
                      panelOpacity: panelOpacity,
                      onTap: () => _openQuickAccess('https://stackoverflow.com'),
                    ),
                    const SizedBox(height: 12),
                    _DevToolCard(
                      icon: CupertinoIcons.book,
                      title: 'MDN Docs',
                      subtitle: 'Web Docs',
                      accentColor: accentColor,
                      bgColor: bgColor,
                      panelOpacity: panelOpacity,
                      onTap: () => _openQuickAccess('https://developer.mozilla.org'),
                    ),
                    const SizedBox(height: 20),
                    GxFuturisticCard(
                      accentColor: accentColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ACTIVE SESSION',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListenableBuilder(
                            listenable: _metricsService,
                            builder: (context, _) => _MetricRow(
                              label: 'TIME',
                              value: _metricsService.formatActiveTime(),
                              accentColor: accentColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ListenableBuilder(
                            listenable: _metricsService,
                            builder: (context, _) => _MetricRow(
                              label: 'TABS',
                              value: '${_metricsService.tabCount}',
                              accentColor: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSideLabels(BuildContext context, Color accentColor) {
    return Stack(
      children: [
        // Label gauche
        AnimatedPositioned(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          left: _leftColumnExpanded ? 280 : 0,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _leftColumnExpanded = !_leftColumnExpanded;
              });
              _saveColumnStates();
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  border: Border(
                    left: BorderSide(
                      color: accentColor.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'DEV TOOLS',
                      style: NotilusFonts.orbitron(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Label droit
        AnimatedPositioned(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          right: _rightColumnExpanded ? 280 : 0,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _rightColumnExpanded = !_rightColumnExpanded;
              });
              _saveColumnStates();
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  border: Border(
                    right: BorderSide(
                      color: accentColor.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'QUICK ACTIONS',
                      style: NotilusFonts.orbitron(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Composants spécialisés
// ============================================================================

/// Logo avec effet de glow animé
class _GlowLogo extends StatelessWidget {
  final AnimationController controller;
  final Color accentColor;

  const _GlowLogo({
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final glowIntensity = (controller.value * 0.3 + 0.7).clamp(0.7, 1.0);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3 * glowIntensity),
                blurRadius: 40 * glowIntensity,
                spreadRadius: 10 * glowIntensity,
              ),
              BoxShadow(
                color: accentColor.withOpacity(0.2 * glowIntensity),
                blurRadius: 60 * glowIntensity,
                spreadRadius: 20 * glowIntensity,
              ),
            ],
          ),
          child: const NotilusMonogram(size: 100),
        );
      },
    );
  }
}

/// Barre de recherche futuriste
class _FuturisticSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final ValueChanged<String> onSubmitted;

  const _FuturisticSearchBar({
    required this.controller,
    required this.focusNode,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.onSubmitted,
  });

  @override
  State<_FuturisticSearchBar> createState() => _FuturisticSearchBarState();
}

class _FuturisticSearchBarState extends State<_FuturisticSearchBar> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.bgColor ?? Colors.black;
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      height: 64,
      child: GxFuturisticCard(
        accentColor: widget.accentColor,
        showBorders: true,
        child: Container(
          decoration: BoxDecoration(
            gradient: _isFocused
                ? LinearGradient(
                    colors: [
                      widget.accentColor.withOpacity(0.1),
                      widget.accentColor.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Icon(
                CupertinoIcons.search,
                size: 22,
                color: _isFocused ? widget.accentColor : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  cursorColor: widget.accentColor,
                  style: NotilusFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher sur le web ou saisir une adresse',
                    hintStyle: NotilusFonts.rajdhani(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: widget.onSubmitted,
                ),
              ),
              const SizedBox(width: 12),
              GxFuturisticButton(
                label: 'GO',
                icon: CupertinoIcons.arrow_right,
                variant: GxFuturisticButtonVariant.primary,
                accentColor: widget.accentColor,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                onPressed: () => widget.onSubmitted(widget.controller.text),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grille de métriques système
class _SystemMetricsGrid extends StatelessWidget {
  final SystemMetricsService metricsService;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;

  const _SystemMetricsGrid({
    required this.metricsService,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: metricsService,
      builder: (context, _) => Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _MetricCard(
            icon: CupertinoIcons.gauge,
            label: 'CPU',
            value: '${metricsService.cpuUsage.toStringAsFixed(0)}%',
            accentColor: accentColor,
            bgColor: bgColor,
            panelOpacity: panelOpacity,
          ),
          _MetricCard(
            icon: Icons.memory,
            label: 'RAM',
            value: '${metricsService.ramUsage.toStringAsFixed(0)}%',
            accentColor: accentColor,
            bgColor: bgColor,
            panelOpacity: panelOpacity,
          ),
          _MetricCard(
            icon: CupertinoIcons.waveform_path,
            label: 'NETWORK',
            value: metricsService.networkStatus,
            accentColor: accentColor,
            bgColor: bgColor,
            panelOpacity: panelOpacity,
          ),
          _MetricCard(
            icon: CupertinoIcons.speedometer,
            label: 'GPU',
            value: '${metricsService.gpuTemp.toStringAsFixed(0)}°C',
            accentColor: accentColor,
            bgColor: bgColor,
            panelOpacity: panelOpacity,
          ),
          _MetricCard(
            icon: CupertinoIcons.battery_charging,
            label: 'BATTERY',
            value: '${metricsService.batteryLevel.toStringAsFixed(0)}%',
            accentColor: accentColor,
            bgColor: bgColor,
            panelOpacity: panelOpacity,
          ),
          _MetricCard(
            icon: CupertinoIcons.globe,
            label: 'TABS',
            value: '${metricsService.tabCount}',
            accentColor: accentColor,
            bgColor: bgColor,
            panelOpacity: panelOpacity,
          ),
        ],
      ),
    );
  }
}

/// Carte de métrique
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return GxFuturisticCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: NotilusFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: NotilusFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// En-tête de section
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;
  final VoidCallback? onAdd;

  const _SectionHeader({
    required this.title,
    required this.accentColor,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: NotilusFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.3),
                accentColor,
              ],
            ),
          ),
        ),
        if (onAdd != null) ...[
          const SizedBox(width: 16),
          GxFuturisticButton(
            label: '',
            icon: CupertinoIcons.add_circled,
            variant: GxFuturisticButtonVariant.ghost,
            accentColor: accentColor,
            width: 36,
            height: 36,
            padding: EdgeInsets.zero,
            onPressed: onAdd,
          ),
        ],
      ],
    );
  }
}

/// Grille d'accès rapide
class _QuickAccessGrid extends StatelessWidget {
  final List<QuickAccessItem> items;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final ValueChanged<String> onTap;
  final void Function(QuickAccessItem)? onLongPress;

  const _QuickAccessGrid({
    required this.items,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _QuickAccessCard(
          item: item,
          accentColor: accentColor,
          bgColor: bgColor,
          panelOpacity: panelOpacity,
          delay: (index * 80).ms,
          onTap: () => onTap(item.url),
          onLongPress: onLongPress != null ? (item) => onLongPress!(item) : null,
        );
      }).toList(),
    );
  }
}

/// Carte d'accès rapide futuriste
class _QuickAccessCard extends StatefulWidget {
  final QuickAccessItem item;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final Duration delay;
  final VoidCallback onTap;
  final void Function(QuickAccessItem)? onLongPress;

  const _QuickAccessCard({
    required this.item,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.delay,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress != null ? () => widget.onLongPress!(widget.item) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 140,
          height: 120,
          child: GxFuturisticCard(
            accentColor: _isHovered ? widget.accentColor : widget.item.color,
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.item.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.item.color.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: widget.item.iconUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                widget.item.iconUrl!,
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => Icon(
                                  CupertinoIcons.globe,
                                  size: 18,
                                  color: widget.item.color,
                                ),
                              ),
                            )
                          : Icon(
                              CupertinoIcons.globe,
                              size: 18,
                              color: widget.item.color,
                            ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.name,
                      style: NotilusFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Uri.parse(widget.item.url).host.replaceFirst('www.', ''),
                      style: NotilusFonts.rajdhani(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: widget.delay)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), delay: widget.delay);
  }
}

/// Grille d'historique
class _HistoryGrid extends StatelessWidget {
  final List<HistoryItem> items;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final ValueChanged<String> onTap;

  const _HistoryGrid({
    required this.items,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _HistoryCard(
          item: item,
          accentColor: accentColor,
          bgColor: bgColor,
          panelOpacity: panelOpacity,
          delay: (index * 80).ms,
          onTap: () => onTap(item.url),
        );
      }).toList(),
    );
  }
}

/// Carte d'historique futuriste
class _HistoryCard extends StatefulWidget {
  final HistoryItem item;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final Duration delay;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.item,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: FaviconService.getFaviconWithCache(widget.item.url),
      builder: (context, faviconSnapshot) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              height: 120,
              child: GxFuturisticCard(
                accentColor: widget.accentColor,
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.accentColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: faviconSnapshot.hasData && faviconSnapshot.data != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    faviconSnapshot.data!,
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (_, __, ___) => Icon(
                                      CupertinoIcons.globe,
                                      size: 18,
                                      color: widget.accentColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  CupertinoIcons.globe,
                                  size: 18,
                                  color: widget.accentColor,
                                ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          style: NotilusFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Uri.parse(widget.item.url).host.replaceFirst('www.', ''),
                          style: NotilusFonts.rajdhani(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: widget.delay)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), delay: widget.delay);
      },
    );
  }
}

/// Carte d'outil dev
class _DevToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final VoidCallback onTap;

  const _DevToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GxFuturisticCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 22, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: NotilusFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: NotilusFonts.rajdhani(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
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

/// Ligne de métrique
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: NotilusFonts.rajdhani(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: NotilusFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}

/// Particules animées en arrière-plan
class _ParticleBackground extends StatelessWidget {
  final AnimationController controller;
  final Color accentColor;

  const _ParticleBackground({
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            progress: controller.value,
            accentColor: accentColor,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final List<_Particle> particles;

  _ParticlePainter({
    required this.progress,
    required this.accentColor,
  }) : particles = List.generate(30, (index) => _Particle.random());

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = (particle.startX + progress * particle.speedX) % size.width;
      final y = (particle.startY + progress * particle.speedY) % size.height;
      
      final paint = Paint()
        ..color = accentColor.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Particle {
  final double startX;
  final double startY;
  final double speedX;
  final double speedY;
  final double size;
  final double opacity;

  _Particle({
    required this.startX,
    required this.startY,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
  });

  factory _Particle.random() {
    final random = math.Random();
    return _Particle(
      startX: random.nextDouble() * 1000,
      startY: random.nextDouble() * 1000,
      speedX: (random.nextDouble() - 0.5) * 2,
      speedY: (random.nextDouble() - 0.5) * 2,
      size: random.nextDouble() * 2 + 1,
      opacity: random.nextDouble() * 0.3 + 0.1,
    );
  }
}

/// Scanlines animées
class _ScanlineOverlay extends StatelessWidget {
  final AnimationController controller;
  final Color accentColor;

  const _ScanlineOverlay({
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanlinePainter(
            progress: controller.value,
            accentColor: accentColor,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _ScanlinePainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final lineHeight = 2.0;
    final spacing = 100.0;
    final y = (progress * (size.height + spacing)) % (size.height + spacing) - spacing;

    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, lineHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

