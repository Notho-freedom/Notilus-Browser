import 'dart:io';
import 'dart:convert';
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
import '../common/notilus_logo_image.dart';
import '../common/context_menu.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../common/wallpaper_background.dart';
import 'gx_futuristic_history_panel.dart';

class ModernHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  
  const ModernHomePage({
    super.key,
    this.onTerminalSelected,
  });

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage> {
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

  @override
  void initState() {
    super.initState();
    _loadColumnStates();
    _loadQuickAccessItems();
    _loadRecentHistory();
    _metricsService.addListener(_onMetricsUpdate);
    _settings.addListener(_onSettingsChanged);
    // Mettre à jour le nombre d'onglets
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
    super.dispose();
  }

  Future<void> _loadQuickAccessItems() async {
    final items = await _quickAccessService.getQuickAccessItems();
    if (items.isEmpty) {
      // Créer des items par défaut
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
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    
    final result = await GxFuturisticDialog.show<String>(
      context: context,
      title: 'Ajouter un site rapide',
      titleIcon: CupertinoIcons.add_circled,
      accentColor: gxRed,
      width: 450,
      child: TextField(
        controller: controller,
        autofocus: true,
        cursorColor: gxRed,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'https://example.com',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: gxRed.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: gxRed, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: gxRed.withOpacity(0.3)),
          ),
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: gxRed,
          onPressed: () => Navigator.pop(context),
        ),
        GxFuturisticButton(
          label: 'Ajouter',
          icon: CupertinoIcons.add_circled,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: gxRed,
          onPressed: () => Navigator.pop(context, controller.text),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Site rapide ajouté')),
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

  void _showQuickAccessContextMenu(BuildContext context, QuickAccessItem item) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    
    final wallpaperManager = context.watch<WallpaperManager>();
    
    // #region agent log
    final currentUrl = wallpaperManager.current;
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'C',
        'location': 'modern_home_page.dart:251',
        'message': 'modern_home_page using CachedNetworkImageProvider',
        'data': {
          'currentUrl': currentUrl.isEmpty ? 'EMPTY' : (currentUrl.length > 100 ? '${currentUrl.substring(0, 100)}...' : currentUrl),
          'isVideo': wallpaperManager.isVideo,
          'isVideoUrl': currentUrl.contains('.mp4') || currentUrl.contains('video/upload'),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
      logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => WallpaperBackground(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(_settings.homePageOverlayOpacity),
          BlendMode.srcOver,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity((_settings.homePageBlur * (1.0 - _settings.widgetTransparency)).clamp(0.0, 1.0)),
                Colors.black.withOpacity(((_settings.homePageBlur + 0.06) * (1.0 - _settings.widgetTransparency)).clamp(0.0, 1.0)),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Row(
                  children: [
                    // Colonne gauche - Widgets dev
                    _buildLeftColumn(context, theme, gxRed),
                    
                    // Contenu central - recentré sans limiter la largeur
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),

                              // Logo + titre
                              Column(
                                children: [
                                  const NotilusMonogramImage(
                                    size: 78,
                                  )
                                      .animate()
                                      .fadeIn(duration: 500.ms)
                                      .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),

                                  const SizedBox(height: 32),

                                  Text(
                                    'Notilus Speed Dial',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 500.ms, delay: 150.ms)
                                      .slideY(begin: 0.12, end: 0),

                                  const SizedBox(height: 12),

                                  Text(
                                    'Hub de lancement pour vos outils de développement',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 500.ms, delay: 220.ms)
                                      .slideY(begin: 0.12, end: 0),
                                ],
                              ),

                              const SizedBox(height: 48),

                              // Barre de recherche avec double contour néon
                              Container(
                                constraints: const BoxConstraints(maxWidth: 720),
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      gxRed.withOpacity(0.85),
                                      const Color(0xFF6B2C5F).withOpacity(0.65),
                                    ],
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: Colors.black.withOpacity(0.28),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 18),
                                      Icon(
                                        CupertinoIcons.search,
                                        size: 20,
                                        color: gxRed,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocusNode,
                                          cursorColor: gxRed,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Rechercher sur le web ou saisir une adresse',
                                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.white.withOpacity(0.45),
                                            ),
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            fillColor: Colors.transparent,
                                            filled: true,
                                          ),
                                          onSubmitted: _handleSearch,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: gxRed.withOpacity(0.14),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            CupertinoIcons.arrow_right,
                                            color: gxRed,
                                          ),
                                          onPressed: () =>
                                              _handleSearch(_searchController.text),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 550.ms, delay: 300.ms)
                                  .scale(
                                    begin: const Offset(0.96, 0.96),
                                    end: const Offset(1, 1),
                                  ),

                              // Widgets système - visible selon les paramètres
                              if (_settings.showSystemWidgets) ...[
                                const SizedBox(height: 24),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          ListenableBuilder(
                                            listenable: _metricsService,
                                            builder: (context, _) => _StatChip(
                                              icon: CupertinoIcons.gauge,
                                              label: 'CPU',
                                              value: '${_metricsService.cpuUsage.toStringAsFixed(0)}%',
                                            ),
                                          ),
                                          ListenableBuilder(
                                            listenable: _metricsService,
                                            builder: (context, _) => _StatChip(
                                              icon: Icons.memory,
                                              label: 'RAM',
                                              value: '${_metricsService.ramUsage.toStringAsFixed(0)}%',
                                            ),
                                          ),
                                          ListenableBuilder(
                                            listenable: _metricsService,
                                            builder: (context, _) => _StatChip(
                                              icon: CupertinoIcons.waveform_path,
                                              label: 'Réseau',
                                              value: _metricsService.networkStatus,
                                            ),
                                          ),
                                          ListenableBuilder(
                                            listenable: _metricsService,
                                            builder: (context, _) => _StatChip(
                                              icon: CupertinoIcons.speedometer,
                                              label: 'GPU',
                                              value: '${_metricsService.gpuTemp.toStringAsFixed(0)}°C',
                                            ),
                                          ),
                                          ListenableBuilder(
                                            listenable: _metricsService,
                                            builder: (context, _) => _StatChip(
                                              icon: CupertinoIcons.battery_charging,
                                              label: 'Batterie',
                                              value: '${_metricsService.batteryLevel.toStringAsFixed(0)}%',
                                            ),
                                          ),
                                          ListenableBuilder(
                                            listenable: _metricsService,
                                            builder: (context, _) => _StatChip(
                                              icon: CupertinoIcons.globe,
                                              label: 'Onglets',
                                              value: '${_metricsService.tabCount}',
                                            ),
                                          ),
                                        ],
                                      )
                                          .animate()
                                          .fadeIn(duration: 450.ms, delay: 380.ms)
                                          .slideY(begin: 0.08, end: 0),
                                    );
                                  },
                                ),
                              ],

                              // Sites rapides - visible selon les paramètres
                              if (_settings.showQuickAccess) ...[
                                const SizedBox(height: 48),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            gxRed,
                                            const Color(0xFF5856D6),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sites rapides',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: Icon(CupertinoIcons.add_circled, color: gxRed),
                                      tooltip: 'Ajouter un site rapide',
                                      onPressed: _addQuickAccessSite,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final rows = (_quickAccessItems.length / 5).ceil();
                                    
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(rows, (rowIndex) {
                                        final startIndex = rowIndex * 5;
                                        final endIndex = (startIndex + 5).clamp(0, _quickAccessItems.length);
                                        final rowItems = _quickAccessItems.sublist(startIndex, endIndex);
                                        
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 18 : 0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: List.generate(5, (colIndex) {
                                              if (colIndex < rowItems.length) {
                                                final item = rowItems[colIndex];
                                                final index = startIndex + colIndex;
                                                return Padding(
                                                  padding: EdgeInsets.only(right: colIndex < 4 ? 18 : 0),
                                                  child: SizedBox(
                                                    width: 120,
                                                    child: _QuickAccessTile(
                                                      item: item,
                                                      onTap: () => _openQuickAccess(item.url),
                                                      onLongPress: () => _showQuickAccessContextMenu(context, item),
                                                      delay: (index * 60).ms,
                                                      compact: true,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return const SizedBox(width: 120);
                                              }
                                            }),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                              ],

                              // Section Accès rapide (Historique récent) - visible selon les paramètres
                              if (_settings.showRecentHistory && _recentHistory.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            gxRed,
                                            const Color(0xFF5856D6),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Accès rapide',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () {
                                        // Ouvrir le panel historique
                                        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
                                        final gxRed = colorThemeManager.nativeSecondaryColor;
                                        GxFuturisticDialog.show(
                                          context: context,
                                          title: 'Historique',
                                          titleIcon: CupertinoIcons.time,
                                          accentColor: gxRed,
                                          width: 900,
                                          height: 700,
                                          child: const GxFuturisticHistoryPanel(),
                                        );
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
                                          return Text(
                                            'Voir tout',
                                            style: TextStyle(color: gxRed),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                // Grille Accès rapide - 5 éléments max par ligne, 2 colonnes
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final historyItems = _recentHistory.take(5).toList();
                                    final rows = (historyItems.length / 5).ceil();
                                    
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(rows, (rowIndex) {
                                        final startIndex = rowIndex * 5;
                                        final endIndex = (startIndex + 5).clamp(0, historyItems.length);
                                        final rowItems = historyItems.sublist(startIndex, endIndex);
                                        
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 12 : 0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: List.generate(5, (colIndex) {
                                              if (colIndex < rowItems.length) {
                                                final item = rowItems[colIndex];
                                                return Padding(
                                                  padding: EdgeInsets.only(right: colIndex < 4 ? 18 : 0),
                                                  child: SizedBox(
                                                    width: 120,
                                                    child: _HistoryQuickAccessTile(
                                                      historyItem: item,
                                                      onTap: () => _openQuickAccess(item.url),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return const SizedBox(width: 120);
                                              }
                                            }),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                              ],

                              // Section Widgets système
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            gxRed,
                                            const Color(0xFF5856D6),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Widgets système',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Grille de widgets métriques
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 600),
                                  child: GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 2.5,
                                    children: [
                                      ListenableBuilder(
                                        listenable: _metricsService,
                                        builder: (context, _) => _MetricWidget(
                                          title: 'Temps actif',
                                          value: _metricsService.formatActiveTime(),
                                          icon: CupertinoIcons.time,
                                        ),
                                      ),
                                      ListenableBuilder(
                                        listenable: _metricsService,
                                        builder: (context, _) => _MetricWidget(
                                          title: 'Pages visitées',
                                          value: '${_metricsService.pagesVisited}',
                                          icon: CupertinoIcons.doc_text,
                                        ),
                                      ),
                                      ListenableBuilder(
                                        listenable: _metricsService,
                                        builder: (context, _) => _MetricWidget(
                                          title: 'Données utilisées',
                                          value: _metricsService.formatDataUsed(),
                                          icon: CupertinoIcons.cloud_download,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Colonne droite - Widgets dev
                    _buildRightColumn(context, theme, gxRed),
                  ],
                ),
                
                // Label gauche - toujours visible, collé à la sidebar en collapse
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
                          color: Colors.black.withOpacity(0.3),
                          border: Border(
                            left: BorderSide(
                              color: gxRed.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              'DEV TOOLS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                                color: gxRed,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Label droit - toujours visible, collé au bord droit de l'écran
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
                          color: Colors.black.withOpacity(0.3),
                          border: Border(
                            right: BorderSide(
                              color: gxRed.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              'QUICK ACTIONS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                                color: gxRed,
                                fontSize: 10,
                              ),
                            ),
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
    );
  }

  Widget _buildLeftColumn(BuildContext context, ThemeData theme, Color gxRed) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        width: _leftColumnExpanded ? 280 : 0,
        decoration: BoxDecoration(
          border: _leftColumnExpanded
              ? Border(
                  right: BorderSide(
                    color: gxRed.withOpacity(0.2),
                    width: 1,
                  ),
                )
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: _leftColumnExpanded
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEV TOOLS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w700,
                                  color: gxRed,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDevWidget(
                                context,
                                icon: CupertinoIcons.doc_text,
                                title: 'Code Editor',
                                subtitle: 'VS Code',
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildDevWidget(
                                context,
                                icon: CupertinoIcons.square_list,
                                title: 'Terminal',
                                subtitle: 'Ouvrir le terminal',
                                onTap: () {
                                  widget.onTerminalSelected?.call();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildDevWidget(
                                context,
                                icon: CupertinoIcons.doc_text_search,
                                title: 'API Docs',
                                subtitle: 'REST Client',
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: gxRed.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34C759),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'System Status',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ListenableBuilder(
                                  listenable: _metricsService,
                                  builder: (context, _) => Text(
                                    'CPU: ${_metricsService.cpuUsage.toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                ListenableBuilder(
                                  listenable: _metricsService,
                                  builder: (context, _) => Text(
                                    'RAM: ${_metricsService.ramUsage.toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context, ThemeData theme, Color gxRed) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        width: _rightColumnExpanded ? 280 : 0,
        decoration: BoxDecoration(
          border: _rightColumnExpanded
              ? Border(
                  left: BorderSide(
                    color: gxRed.withOpacity(0.2),
                    width: 1,
                  ),
                )
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: _rightColumnExpanded
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QUICK ACTIONS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w700,
                                  color: gxRed,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDevWidget(
                                context,
                                icon: CupertinoIcons.cloud,
                                title: 'GitHub',
                                subtitle: 'Repositories',
                                onTap: () => _openQuickAccess('https://github.com'),
                              ),
                              const SizedBox(height: 12),
                              _buildDevWidget(
                                context,
                                icon: CupertinoIcons.doc_on_doc,
                                title: 'Stack Overflow',
                                subtitle: 'Q&A',
                                onTap: () => _openQuickAccess('https://stackoverflow.com'),
                              ),
                              const SizedBox(height: 12),
                              _buildDevWidget(
                                context,
                                icon: CupertinoIcons.book,
                                title: 'MDN Docs',
                                subtitle: 'Web Docs',
                                onTap: () => _openQuickAccess('https://developer.mozilla.org'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: gxRed.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: gxRed,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Active Session',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ListenableBuilder(
                                  listenable: _metricsService,
                                  builder: (context, _) => Text(
                                    'Time: ${_metricsService.formatActiveTime()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                ListenableBuilder(
                                  listenable: _metricsService,
                                  builder: (context, _) => Text(
                                    'Tabs: ${_metricsService.tabCount}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDevWidget(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: gxRed.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: gxRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: gxRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
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

class _QuickAccessTile extends StatefulWidget {
  final QuickAccessItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final Duration delay;

  const _QuickAccessTile({
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
    required this.delay,
  });

  @override
  State<_QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<_QuickAccessTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          height: 90,
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: _isHovered
                ? LinearGradient(
                    colors: [
                      widget.item.color.withOpacity(0.95),
                      gxRed.withOpacity(0.9),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      widget.item.color.withOpacity(0.65),
                      widget.item.color.withOpacity(0.25),
                    ],
                  ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? const Color(0xFF050509).withOpacity(0.96)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Barre accent en bas
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          widget.item.color,
                          widget.item.color.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: widget.item.color.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: widget.item.iconUrl != null
                                ? Image.network(
                                    widget.item.iconUrl!,
                                    width: 18,
                                    height: 18,
                                    errorBuilder: (_, __, ___) => Icon(
                                      CupertinoIcons.globe,
                                      size: 18,
                                      color: widget.item.color,
                                    ),
                                  )
                                : Icon(
                                    CupertinoIcons.globe,
                                    size: 18,
                                    color: widget.item.color,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.item.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              Uri.parse(widget.item.url).host.replaceFirst(
                                    'www.',
                                    '',
                                  ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 14,
                            color: theme.iconTheme.color?.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: widget.delay)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          delay: widget.delay,
        );
  }
}

class _MetricWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricWidget({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: gxRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1C1C24),
            Color(0xFF252535),
          ],
        ),
        border: Border.all(
          color: gxRed.withOpacity(0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: gxRed,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label ',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: gxRed,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryQuickAccessTile extends StatelessWidget {
  final HistoryItem historyItem;
  final VoidCallback onTap;

  const _HistoryQuickAccessTile({
    required this.historyItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FutureBuilder<String?>(
      future: FaviconService.getFaviconWithCache(historyItem.url),
      builder: (context, faviconSnapshot) {
        return GestureDetector(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          child: Container(
            width: 120,
            height: 90,
            padding: const EdgeInsets.all(1.6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5856D6).withOpacity(0.65),
                  const Color(0xFF5856D6).withOpacity(0.25),
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark
                    ? const Color(0xFF050509).withOpacity(0.96)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5856D6),
                            const Color(0xFF5856D6).withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5856D6).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: faviconSnapshot.hasData && faviconSnapshot.data != null
                                  ? Image.network(
                                      faviconSnapshot.data!,
                                      width: 18,
                                      height: 18,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        CupertinoIcons.globe,
                                        size: 18,
                                        color: Color(0xFF5856D6),
                                      ),
                                    )
                                  : const Icon(
                                      CupertinoIcons.globe,
                                      size: 18,
                                      color: Color(0xFF5856D6),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                historyItem.title,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                Uri.parse(historyItem.url).host.replaceFirst('www.', ''),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: Color(0xFF5856D6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context) {
    final quickAccessService = QuickAccessService();
    final bookmarkService = BookmarkService();
    
    ContextMenu.show(
      context: context,
      actions: [
        ContextMenuAction(
          label: 'Ajouter aux sites rapides',
          icon: CupertinoIcons.add_circled,
          onTap: () async {
            final item = await quickAccessService.extractSiteInfo(historyItem.url);
            if (item != null) {
              await quickAccessService.addQuickAccessItem(item);
            }
          },
        ),
        ContextMenuAction(
          label: 'Ajouter aux favoris',
          icon: CupertinoIcons.bookmark,
          onTap: () async {
            final bookmark = Bookmark(
              url: historyItem.url,
              title: historyItem.title,
              description: '',
              tags: [],
              createdAt: DateTime.now(),
            );
            await bookmarkService.addBookmark(bookmark);
          },
        ),
      ],
    );
  }
}