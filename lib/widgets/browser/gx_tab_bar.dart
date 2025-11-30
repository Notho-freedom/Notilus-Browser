import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/quick_access_service.dart';
import 'package:flutter/services.dart';
import '../../services/bookmark_service.dart';
import '../../models/tab_model.dart';
import '../../services/terminal_manager.dart';
import '../../models/bookmark.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';
import '../../services/tab_group_service.dart';
import '../common/notilus_monogram.dart';
import '../common/notilus_tooltip.dart';
import '../common/context_menu.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../../core/constants/notilus_fonts.dart';

// La couleur rouge est maintenant gérée par ColorThemeManager

class GXTabBar extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onGroupsPressed;
  final bool isSidebarVisible;

  const GXTabBar({
    super.key,
    this.onMenuTap,
    this.onGroupsPressed,
    this.isSidebarVisible = true,
  });

  @override
  State<GXTabBar> createState() => _GXTabBarState();
}

class _GXTabBarState extends State<GXTabBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    return Container(
      height: 36,
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
          SizedBox(width: widget.isSidebarVisible ? 10 : 10),
          if (!widget.isSidebarVisible) ...[
            const NotilusTooltip(
              message: 'Identité Notilus',
              child: NotilusMonogram(
                size: 22,
                showGlow: false,
              ),
            ),
            const SizedBox(width: 8),
          ],
          _GXTabBarIconButton(
            icon: widget.isSidebarVisible
                ? CupertinoIcons.sidebar_left
                : CupertinoIcons.sidebar_right,
            tooltip: widget.isSidebarVisible ? 'Masquer la barre latérale' : 'Afficher la barre latérale',
            onPressed: widget.onMenuTap,
          ),
          const SizedBox(width: 10),
          // Tabs container
          Expanded(
            child: Consumer4<TabManager, TabGroupService, SettingsService, ColorThemeManager>(
              builder: (context, tabManager, groupService, settings, colorThemeManager, _) {
                final groupingEnabled = settings.tabGroupingEnabled;
                final groups = groupingEnabled ? groupService.orderedGroups : [];
                final allTabs = tabManager.tabs;
                
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculer la largeur des onglets
                    final tabCount = allTabs.length + groups.length;
                    final double tabWidth = tabCount > 0
                        ? (constraints.maxWidth / (tabCount + 0.4))
                            .clamp(110, 210)
                            .toDouble()
                        : 150.0;

                    // Construire la liste des widgets à afficher
                    final List<Widget> tabBarItems = [];
                    
                    // Identifier les onglets qui sont dans un groupe
                    final tabsInGroups = <String>{};
                    for (final group in groups) {
                      tabsInGroups.addAll(group.tabIds);
                    }
                    
                    // Afficher les onglets non groupés (domaines avec un seul onglet)
                    for (final tab in allTabs) {
                      if (!tabsInGroups.contains(tab.id)) {
                        final isActive = tab.id == tabManager.activeTab?.id;
                        // Extraire le domaine de l'URL
                        String domain = _extractDomain(tab.url);
                        final colorCode = groupService.getColorForDomain(domain);
                        
                        tabBarItems.add(
                          _buildGXTabItem(
                            context: context,
                            tab: tab,
                            tabWidth: tabWidth,
                            isActive: isActive,
                            colorCode: colorCode,
                            colorThemeManager: colorThemeManager,
                            tabManager: tabManager,
                          ),
                        );
                      }
                    }
                    
                    // Afficher les groupes (domaines avec plusieurs onglets)
                    for (final group in groups) {
                      // Si le groupe est expandé, insérer ses onglets avant le groupe
                      if (group.isExpanded) {
                        final selectedGroupId = groupService.selectedGroupId;
                        final isSelected = selectedGroupId == group.id;
                        
                        // Si un groupe est sélectionné et ce n'est pas celui-ci, ne pas afficher les onglets
                        if (selectedGroupId != null && !isSelected) {
                          // Ne rien ajouter, juste le groupe
                        } else {
                          // Ajouter les onglets du groupe
                          for (final tabId in group.tabIds) {
                            try {
                              final tab = tabManager.tabs.firstWhere((t) => t.id == tabId);
                              final isActive = tab.id == tabManager.activeTab?.id;
                              
                              // Si le groupe est sélectionné, n'afficher que l'onglet actif
                              if (isSelected && !isActive) {
                                continue;
                              }
                              
                              tabBarItems.add(
                                _buildGXTabItem(
                                  context: context,
                                  tab: tab,
                                  tabWidth: tabWidth,
                                  isActive: isActive,
                                  colorCode: group.colorCode,
                                  colorThemeManager: colorThemeManager,
                                  tabManager: tabManager,
                                ),
                              );
                            } catch (e) {
                              // Onglet introuvable, ignorer
                            }
                          }
                        }
                      }
                      
                      // Ajouter le widget du groupe
                      tabBarItems.add(
                        _buildGXGroupWidget(
                          context: context,
                          group: group,
                          tabManager: tabManager,
                          groupService: groupService,
                          colorThemeManager: colorThemeManager,
                          tabWidth: tabWidth,
                        ),
                      );
                    }
                    
                    // Ajouter le bouton "nouvel onglet" à la fin
                    tabBarItems.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _GXTabBarIconButton(
                          icon: CupertinoIcons.add,
                          tooltip: 'Nouvel onglet (maintenir pour menu)',
                          compact: true,
                          onPressed: () => tabManager.createNewTab(),
                          onLongPress: () {
                            // Menu contextuel pour choisir le type d'onglet
                            final RenderBox renderBox = context.findRenderObject() as RenderBox;
                            final Offset offset = renderBox.localToGlobal(Offset.zero);
                            
                            showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                offset.dx,
                                offset.dy + 30,
                                offset.dx + 100,
                                offset.dy + 100,
                              ),
                              items: [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(CupertinoIcons.globe, size: 16),
                                      SizedBox(width: 8),
                                      Text('Nouvel onglet web'),
                                    ],
                                  ),
                                  onTap: () => tabManager.createNewTab(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );

                    return Scrollbar(
                      controller: _scrollController,
                      thickness: 2,
                      radius: const Radius.circular(1),
                      thumbVisibility: false,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: tabBarItems.length,
                        itemBuilder: (context, index) {
                          return tabBarItems[index];
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(width: 4),

          // Actions
          Row(
            children: [
              _GXTabBarIconButton(
                icon: CupertinoIcons.search,
                tooltip: 'Rechercher un onglet',
                onPressed: () => _openTabSearch(context),
              ),
              // Bouton groupes (seulement si le groupement est activé)
              Consumer<SettingsService>(
                builder: (context, settings, _) {
                  if (!settings.tabGroupingEnabled) return const SizedBox.shrink();
                  return _GXTabBarIconButton(
                    icon: CupertinoIcons.rectangle_stack,
                    tooltip: 'Groupes d\'onglets',
                    onPressed: widget.onGroupsPressed,
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 6),
          const GXWindowControls(),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Extrait le domaine d'une URL
  String _extractDomain(String? url) {
    if (url == null || url.isEmpty) {
      return 'local';
    }
    
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        // Retirer www. si présent
        return uri.host.replaceFirst(RegExp(r'^www\.'), '');
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
    
    // Pour les URLs spéciales (about:, file:, etc.)
    if (url.startsWith('about:')) {
      return 'about';
    } else if (url.startsWith('file:')) {
      return 'local';
    }
    
    return 'unknown';
  }
  
  /// Construit un widget d'onglet GX avec couleur du domaine
  Widget _buildGXTabItem({
    required BuildContext context,
    required TabModel tab,
    required double tabWidth,
    required bool isActive,
    required int colorCode,
    required ColorThemeManager colorThemeManager,
    required TabManager tabManager,
  }) {
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final domainColor = Color(colorCode);
    
    return DragTarget<TabModel>(
      onWillAccept: (data) => data != null && data.id != tab.id,
      onAccept: (draggedTab) {
        if (draggedTab.id != tab.id) {
          final oldIndex = tabManager.tabs.indexWhere((t) => t.id == draggedTab.id);
          final newIndex = tabManager.tabs.indexWhere((t) => t.id == tab.id);
          if (oldIndex != -1 && newIndex != -1) {
            tabManager.reorderTab(oldIndex, newIndex);
            HapticFeedback.mediumImpact();
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<TabModel>(
          key: ValueKey(tab.id),
          data: tab,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          delay: const Duration(milliseconds: 300),
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.05,
              child: Container(
                width: tabWidth,
                height: 32,
                decoration: BoxDecoration(
                  color: colorThemeManager.nativeBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: domainColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: domainColor.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _GXTabItem(
                  tab: tab,
                  width: tabWidth,
                  isActive: true,
                  colorCode: colorCode,
                  onTap: () {},
                  onClose: () {},
                ),
              ),
            ),
          ),
          childWhenDragging: AnimatedOpacity(
            opacity: 0.2,
            duration: const Duration(milliseconds: 200),
            child: _GXTabItem(
              tab: tab,
              width: tabWidth,
              isActive: isActive,
              colorCode: colorCode,
              onTap: () => tabManager.selectTab(tab.id),
              onClose: () {
                final webViewManager = Provider.of<TabWebViewManager>(
                  context,
                  listen: false,
                );
                webViewManager.removeEngineForTab(tab.id);
                tabManager.closeTab(tab.id);
              },
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: candidateData.isNotEmpty
                ? BoxDecoration(
                    border: Border.all(
                      color: domainColor,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: domainColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: _GXTabItem(
              tab: tab,
              width: tabWidth,
              isActive: isActive,
              colorCode: colorCode,
              onTap: () => tabManager.selectTab(tab.id),
              onClose: () {
                final webViewManager = Provider.of<TabWebViewManager>(
                  context,
                  listen: false,
                );
                webViewManager.removeEngineForTab(tab.id);
                tabManager.closeTab(tab.id);
              },
            ),
          ),
        );
      },
    );
  }
  
  /// Construit un widget de groupe GX
  Widget _buildGXGroupWidget({
    required BuildContext context,
    required TabGroup group,
    required TabManager tabManager,
    required TabGroupService groupService,
    required ColorThemeManager colorThemeManager,
    required double tabWidth,
  }) {
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final domainColor = Color(group.colorCode);
    final activeTab = tabManager.activeTab;
    final isGroupActive = group.tabIds.contains(activeTab?.id);
    final selectedGroupId = groupService.selectedGroupId;
    final isSelected = selectedGroupId == group.id;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: tabWidth * 1.5,
        minWidth: 120,
      ),
      child: GestureDetector(
        onTap: () {
          groupService.toggleGroup(group.id);
        },
        child: Container(
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: domainColor.withOpacity(isGroupActive ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isGroupActive
                  ? domainColor.withOpacity(0.6)
                  : domainColor.withOpacity(0.3),
              width: isGroupActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de couleur
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: domainColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Nom du groupe
              Expanded(
                child: Text(
                  group.displayName,
                  style: NotilusFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: isGroupActive ? FontWeight.w700 : FontWeight.w500,
                    color: isGroupActive ? domainColor : Colors.white.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              // Badge avec nombre d'onglets
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: domainColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${group.tabCount}',
                  style: TextStyle(
                    color: domainColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Icône expand/collapse
              Icon(
                group.isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                size: 10,
                color: isGroupActive ? domainColor : Colors.white.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTabSearch(BuildContext context) async {
    final tabManager = context.read<TabManager>();
    final controller = TextEditingController();
    String query = '';

    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    
    await GxFuturisticDialog.show(
      context: context,
      title: 'Rechercher un onglet',
      titleIcon: CupertinoIcons.search,
      accentColor: gxRed,
      width: 450,
      height: 350,
      child: StatefulBuilder(
        builder: (context, setState) {
          final filteredTabs = tabManager.tabs.where((tab) {
            if (query.isEmpty) return true;
            final q = query.toLowerCase();
            return (tab.title?.toLowerCase().contains(q) ?? false) ||
                (tab.url?.toLowerCase().contains(q) ?? false);
          }).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                cursorColor: gxRed,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un onglet...',
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
                  fillColor: Colors.white.withOpacity(0.05),
                  filled: true,
                ),
                onChanged: (value) => setState(() => query = value.trim()),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredTabs.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun onglet trouvé',
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredTabs.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withOpacity(0.08),
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final tab = filteredTabs[index];
                          return ListTile(
                            leading: tab.favicon != null
                                ? Image.network(
                                    tab.favicon!,
                                    width: 18,
                                    height: 18,
                                    errorBuilder: (_, __, ___) {
                                      return Icon(
                                        CupertinoIcons.globe,
                                        size: 18,
                                        color: gxRed.withOpacity(0.85),
                                      );
                                    },
                                  )
                                : Icon(
                                    CupertinoIcons.globe,
                                    size: 18,
                                    color: gxRed.withOpacity(0.85),
                                  ),
                            title: Text(
                              tab.title ?? 'Sans titre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: tab.url != null
                                ? Text(
                                    tab.url!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.38),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              tabManager.selectTab(tab.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GXTabItem extends StatefulWidget {
  final TabModel tab;
  final double width;
  final bool isActive;
  final int colorCode;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _GXTabItem({
    required this.tab,
    required this.width,
    required this.isActive,
    required this.colorCode,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_GXTabItem> createState() => _GXTabItemState();
}

class _GXTabItemState extends State<_GXTabItem>
    with SingleTickerProviderStateMixin {
  Color get _gxRed {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    return colorThemeManager.nativeSecondaryColor;
  }
  bool _isHovered = false;
  bool _closeHovered = false;
  bool _isPressed = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleHoverChange(bool hover) {
    setState(() => _isHovered = hover);
    if (hover) {
      _animController.forward();
    } else if (!_isPressed) {
      _animController.reverse();
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    if (widget.tab.url == null || widget.tab.url!.isEmpty || widget.tab.url!.startsWith('about:')) {
      return;
    }

    final quickAccessService = QuickAccessService();
    final bookmarkService = BookmarkService();
    
    final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
    
    ContextMenu.show(
      context: context,
      position: position,
      actions: [
        ContextMenuAction(
          label: 'Recharger',
          icon: CupertinoIcons.arrow_clockwise,
          onTap: () {
            final engine = webViewManager.getEngine(widget.tab.id);
            engine?.reload();
          },
        ),
        ContextMenuAction(
          label: 'Dupliquer',
          icon: CupertinoIcons.doc_on_doc,
          onTap: () {
            final tabManager = Provider.of<TabManager>(context, listen: false);
            tabManager.addTab(url: widget.tab.url);
          },
        ),
        ContextMenuAction(
          label: 'Ajouter aux sites rapides',
          icon: CupertinoIcons.add_circled,
          onTap: () async {
            final item = await quickAccessService.extractSiteInfo(widget.tab.url!);
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
              url: widget.tab.url!,
              title: widget.tab.title ?? widget.tab.url!,
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

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.tab.title ?? 'Speed Dial';
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final domainColor = Color(widget.colorCode);
    
    // Utiliser la couleur du domaine si l'onglet est actif, sinon utiliser gxRed
    final activeColor = widget.isActive ? domainColor : gxRed;

    return NotilusTooltip(
      message: widget.tab.title ?? widget.tab.url ?? 'Onglet',
      child: MouseRegion(
        onEnter: (_) => _handleHoverChange(true),
        onExit: (_) => _handleHoverChange(false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          onLongPress: () {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero);
              _showContextMenu(context, position);
            }
          },
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? 0.97 : _scaleAnimation.value,
                child: child,
              );
            },
            child: SizedBox(
              width: widget.width,
              height: 32,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? domainColor.withOpacity(0.15)
                      : (_isHovered
                          ? Colors.white.withOpacity(0.05)
                          : Colors.transparent),
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isActive ? domainColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      // Favicon dynamique
                      SizedBox(
                        width: 24,
                        child: Center(
                          child: widget.tab.favicon != null && 
                                 widget.tab.favicon!.isNotEmpty &&
                                 widget.tab.url != null &&
                                 !widget.tab.url!.startsWith('about:')
                              ? Image.network(
                                  widget.tab.favicon!,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Center(
                                        child: SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _gxRed.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => _defaultFavicon(),
                                )
                              : _defaultFavicon(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Title
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: NotilusFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                            color: widget.isActive ? domainColor : Colors.white.withOpacity(0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Close button
                      NotilusTooltip(
                        message: 'Fermer cet onglet',
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _closeHovered = true),
                          onExit: (_) => setState(() => _closeHovered = false),
                          child: GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _closeHovered
                                    ? Colors.white.withValues(alpha:0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 12,
                                color: widget.isActive || _isHovered
                                    ? Colors.white
                                    : Colors.white.withValues(alpha:0.6),
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
        ),
      ),
    );
  }

  Widget _defaultFavicon() {
    final domainColor = Color(widget.colorCode);
    return Icon(
      CupertinoIcons.globe,
      size: 16,
      color: widget.isActive ? domainColor : _gxRed,
    );
  }
}

class _GXTabBarIconButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool compact;

  const _GXTabBarIconButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.onLongPress,
    this.compact = false,
  });

  @override
  State<_GXTabBarIconButton> createState() => _GXTabBarIconButtonState();
}

class _GXTabBarIconButtonState extends State<_GXTabBarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final button = GestureDetector(
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.compact ? 28 : 32,
        height: 28,
        decoration: BoxDecoration(
          color: _isHovered && widget.onPressed != null
              ? gxRed.withValues(alpha:0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          size: widget.compact ? 16 : 18,
          color: widget.onPressed != null
              ? (_isHovered ? gxRed : gxRed.withValues(alpha:0.8))
              : gxRed.withValues(alpha:0.35),
        ),
      ),
    );

    final content = MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.tooltip != null
          ? NotilusTooltip(
              message: widget.tooltip!,
              child: button,
            )
          : button,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: content,
    );
  }
}

class GXWindowControls extends StatefulWidget {
  const GXWindowControls({super.key});

  @override
  State<GXWindowControls> createState() => _GXWindowControlsState();
}

class _GXWindowControlsState extends State<GXWindowControls>
    with WindowListener {
  bool _isMaximized = false;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _checkMaximized();
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'maximize' || eventName == 'unmaximize') {
      _checkMaximized();
    }
  }

  Future<void> _checkMaximized() async {
    if (!_isDesktop) return;
    final maximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return const SizedBox.shrink();
    }

    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    return Row(
      children: [
        _WindowButton(
          icon: CupertinoIcons.minus,
          iconSize: 13,
          tooltip: 'Minimiser',
          iconColor: gxRed,
          onTap: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: _isMaximized ? CupertinoIcons.rectangle : CupertinoIcons.square,
          iconSize: 13,
          tooltip: _isMaximized ? 'Restaurer' : 'Agrandir',
          iconColor: gxRed,
          onTap: () async {
            if (_isMaximized) {
              await windowManager.restore();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: CupertinoIcons.xmark,
          iconSize: 13,
          tooltip: 'Fermer',
          hoverColor: gxRed.withValues(alpha:0.2),
          iconColor: gxRed,
          onTap: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final Color? hoverColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    this.hoverColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final button = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 44,
        height: 32,
        color: _hovered
            ? (widget.hoverColor ?? Colors.white.withValues(alpha:0.08))
            : Colors.transparent,
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _hovered
                ? (widget.iconColor ?? Colors.white)
                : (widget.iconColor ?? Colors.white.withValues(alpha:0.8)),
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: NotilusTooltip(message: widget.tooltip, child: button),
    );
  }
}
