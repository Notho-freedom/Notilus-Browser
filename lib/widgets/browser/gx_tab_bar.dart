import 'dart:convert';
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
import '../common/notilus_logo_image.dart';
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
            color: gxRed.withOpacity(0.2),
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
              child: const NotilusMonogramImage(
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
            child: ClipRect(
              child: Consumer4<TabManager, TabGroupService, SettingsService, ColorThemeManager>(
                builder: (context, tabManager, groupService, settings, colorThemeManager, _) {
                  final groupingEnabled = settings.tabGroupingEnabled;
                  return _buildTabBar(context, tabManager, groupService, colorThemeManager, groupingEnabled);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Bouton nouveau onglet
          _GXTabBarIconButton(
            icon: CupertinoIcons.add,
            tooltip: 'Nouvel onglet',
            compact: true,
            onPressed: () {
              final tabManager = Provider.of<TabManager>(context, listen: false);
              tabManager.createNewTab();
            },
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

  Widget _buildTabBar(
    BuildContext context,
    TabManager tabManager,
    TabGroupService groupService,
    ColorThemeManager colorThemeManager,
    bool groupingEnabled,
  ) {
    final groups = groupingEnabled ? groupService.orderedGroups : [];
    final allTabs = tabManager.tabs;
    final accentColor = colorThemeManager.nativeSecondaryColor;
    
    // Vérifier s'il y a des onglets (groupés ou non)
    if (allTabs.isEmpty) {
      return Center(
        child: Text(
          'Aucun onglet ouvert',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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
            // Obtenir la couleur du domaine même pour les onglets non groupés
            // Extraire le domaine de l'URL
            String domain = 'local';
            if (tab.url != null && tab.url!.isNotEmpty) {
              try {
                final uri = Uri.parse(tab.url!);
                if (uri.host.isNotEmpty) {
                  domain = uri.host.replaceFirst(RegExp(r'^www\.'), '');
                } else if (tab.url!.startsWith('about:')) {
                  domain = 'about';
                } else if (tab.url!.startsWith('file:')) {
                  domain = 'local';
                } else {
                  domain = 'unknown';
                }
              } catch (e) {
                domain = 'unknown';
              }
            }
            final colorCode = groupService.getColorForDomain(domain);
            
            tabBarItems.add(
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 100,
                  maxWidth: 200,
                ),
                child: _GXExpandedTabItem(
                  tab: tab,
                  isActive: isActive,
                  colorCode: colorCode,
                  accentColor: accentColor,
                  tabManager: tabManager,
                ),
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 100,
                        maxWidth: 200,
                      ),
                      child: _GXExpandedTabItem(
                        tab: tab,
                        isActive: isActive,
                        colorCode: group.colorCode,
                        accentColor: accentColor,
                        tabManager: tabManager,
                        onSelect: () {
                          tabManager.selectTab(tab.id);
                          groupService.selectGroup(group.id);
                          // Fermer le groupe après sélection pour économiser l'espace
                          groupService.collapseGroup(group.id);
                        },
                      ),
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
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.4,
                minWidth: 150,
              ),
              child: _GXGroupWidget(
                group: group,
                tabManager: tabManager,
                groupService: groupService,
                accentColor: accentColor,
              ),
            ),
          );
        }
        
        return Scrollbar(
          controller: _scrollController,
          thickness: 2,
          radius: const Radius.circular(1),
          thumbVisibility: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: tabBarItems,
            ),
          ),
        );
      },
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
                  fillColor: Colors.transparent,
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
                                              _gxRed.withOpacity(0.6),
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
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 12,
                                color: widget.isActive || _isHovered
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.6),
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

/// Widget pour les onglets insérés dans la tab bar quand un groupe est expandé (style GX)
class _GXExpandedTabItem extends StatefulWidget {
  final TabModel tab;
  final bool isActive;
  final int colorCode;
  final Color accentColor;
  final TabManager tabManager;
  final VoidCallback? onSelect;

  const _GXExpandedTabItem({
    required this.tab,
    required this.isActive,
    required this.colorCode,
    required this.accentColor,
    required this.tabManager,
    this.onSelect,
  });

  @override
  State<_GXExpandedTabItem> createState() => _GXExpandedTabItemState();
}

class _GXExpandedTabItemState extends State<_GXExpandedTabItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _closeHovered = false;
  bool _isPressed = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

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

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.tab.title ?? 'Speed Dial';
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final domainColor = Color(widget.colorCode);
    
    return NotilusTooltip(
      message: widget.tab.title ?? widget.tab.url ?? 'Onglet',
      child: MouseRegion(
        onEnter: (_) => _handleHoverChange(true),
        onExit: (_) => _handleHoverChange(false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (widget.onSelect != null) {
              widget.onSelect!();
            } else {
              widget.tabManager.selectTab(widget.tab.id);
            }
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? 0.97 : _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              height: 32,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicateur privé ou favicon dynamique
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: widget.tab.isPrivate
                            ? Icon(
                                CupertinoIcons.lock_fill,
                                size: 14,
                                color: widget.isActive ? domainColor : gxRed,
                              )
                            : (widget.tab.favicon != null && 
                               widget.tab.favicon!.isNotEmpty &&
                               widget.tab.url != null &&
                               !widget.tab.url!.startsWith('about:'))
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
                                            domainColor.withOpacity(0.6),
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
                    Flexible(
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
                          onTap: () {
                            final webViewManager = Provider.of<TabWebViewManager>(
                              context,
                              listen: false,
                            );
                            webViewManager.removeEngineForTab(widget.tab.id);
                            widget.tabManager.closeTab(widget.tab.id);
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _closeHovered
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 12,
                              color: widget.isActive || _isHovered
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
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

  Color get _gxRed {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    return colorThemeManager.nativeSecondaryColor;
  }
}

/// Widget de groupe pour GXTabBar
class _GXGroupWidget extends StatelessWidget {
  final TabGroup group;
  final TabManager tabManager;
  final TabGroupService groupService;
  final Color accentColor;

  const _GXGroupWidget({
    required this.group,
    required this.tabManager,
    required this.groupService,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeTab = tabManager.activeTab;
    final isGroupActive = group.tabIds.contains(activeTab?.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      constraints: const BoxConstraints(
        maxWidth: 400,
        minWidth: 150,
      ),
      decoration: BoxDecoration(
        color: Color(group.colorCode).withOpacity(isGroupActive ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGroupActive
              ? Color(group.colorCode).withOpacity(0.6)
              : Color(group.colorCode).withOpacity(0.3),
          width: isGroupActive ? 1.5 : 1,
        ),
      ),
      child: Container(
        height: 28, // Hauteur fixe pour le groupe
        child: _GXGroupHeader(
          group: group,
          isActive: isGroupActive,
          groupService: groupService,
          accentColor: accentColor,
          colorCode: group.colorCode,
          onToggle: () {
            // toggleGroup ferme déjà automatiquement les autres groupes
            groupService.toggleGroup(group.id);
          },
        ),
      ),
    );
  }
}

class _GXGroupHeader extends StatelessWidget {
  final TabGroup group;
  final bool isActive;
  final TabGroupService groupService;
  final Color accentColor;
  final int colorCode;

  final VoidCallback? onToggle;

  const _GXGroupHeader({
    required this.group,
    required this.isActive,
    required this.groupService,
    required this.accentColor,
    required this.colorCode,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle ?? () => groupService.toggleGroup(group.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        height: 18, // Hauteur fixe pour l'en-tête
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de couleur
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(colorCode),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Nom du groupe
            Text(
              group.displayName,
              style: NotilusFonts.rajdhani(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(width: 4),
            // Badge avec nombre d'onglets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(colorCode).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${group.tabCount}',
                style: TextStyle(
                  color: Color(colorCode),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Icône d'expansion
            Icon(
              group.isExpanded
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.chevron_right,
              size: 12,
              color: Colors.white60,
            ),
            const SizedBox(width: 4),
            // Bouton épingler
            GestureDetector(
              onTap: () => groupService.togglePinGroup(group.id),
              child: Icon(
                group.isPinned
                    ? CupertinoIcons.pin_fill
                    : CupertinoIcons.pin,
                size: 12,
                color: group.isPinned ? Color(colorCode) : Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 4),
            // Bouton fermer le groupe
            GestureDetector(
              onTap: () => groupService.closeGroup(group.id),
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 14,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
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
              ? gxRed.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          size: widget.compact ? 16 : 18,
          color: widget.onPressed != null
              ? (_isHovered ? gxRed : gxRed.withOpacity(0.8))
              : gxRed.withOpacity(0.35),
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
        Builder(
          builder: (context) {
            final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
            final iconColor = colorThemeManager.getIconColor();
            return Row(
              children: [
                _WindowButton(
                  icon: CupertinoIcons.minus,
                  iconSize: 13,
                  tooltip: 'Minimiser',
                  iconColor: iconColor,
                  onTap: () => windowManager.minimize(),
                ),
                _WindowButton(
                  icon: _isMaximized ? CupertinoIcons.rectangle : CupertinoIcons.square,
                  iconSize: 13,
                  tooltip: _isMaximized ? 'Restaurer' : 'Agrandir',
                  iconColor: iconColor,
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
                  hoverColor: iconColor.withOpacity(0.2),
                  iconColor: iconColor,
                  onTap: () => windowManager.close(),
                ),
              ],
            );
          },
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
            ? (widget.hoverColor ?? Colors.white.withOpacity(0.08))
            : Colors.transparent,
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _hovered
                ? (widget.iconColor ?? Colors.white)
                : (widget.iconColor ?? Colors.white.withOpacity(0.8)),
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
