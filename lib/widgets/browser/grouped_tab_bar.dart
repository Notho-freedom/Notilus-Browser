import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_group_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../models/tab_model.dart';
import '../common/notilus_tooltip.dart';

/// Tab bar avec regroupements automatiques et codes couleur
class GroupedTabBar extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onGroupsPressed;
  final bool isSidebarVisible;

  const GroupedTabBar({
    super.key,
    this.onMenuTap,
    this.onGroupsPressed,
    this.isSidebarVisible = true,
  });

  @override
  State<GroupedTabBar> createState() => _GroupedTabBarState();
}

class _GroupedTabBarState extends State<GroupedTabBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final accentColor = colorThemeManager.nativeSecondaryColor;
    final tabManager = Provider.of<TabManager>(context);
    final groupService = Provider.of<TabGroupService>(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorThemeManager.nativeBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          // Bouton menu/sidebar
          _TabBarIconButton(
            icon: widget.isSidebarVisible
                ? CupertinoIcons.sidebar_left
                : CupertinoIcons.sidebar_right,
            tooltip: widget.isSidebarVisible ? 'Masquer la barre latérale' : 'Afficher la barre latérale',
            onPressed: widget.onMenuTap,
          ),
          const SizedBox(width: 10),
          // Zone des onglets avec scroll
          Expanded(
            child: ClipRect(
              child: _buildTabBar(context, tabManager, groupService, accentColor),
            ),
          ),
          const SizedBox(width: 4),
          // Bouton nouveau onglet
          _TabBarIconButton(
            icon: CupertinoIcons.add,
            tooltip: 'Nouvel onglet',
            onPressed: () => tabManager.createNewTab(),
          ),
          const SizedBox(width: 4),
          // Bouton recherche
          _TabBarIconButton(
            icon: CupertinoIcons.search,
            tooltip: 'Rechercher un onglet',
            onPressed: () => _openTabSearch(context),
          ),
          const SizedBox(width: 4),
          // Bouton groupes
          _TabBarIconButton(
            icon: CupertinoIcons.rectangle_stack,
            tooltip: 'Groupes d\'onglets',
            onPressed: widget.onGroupsPressed,
          ),
          const SizedBox(width: 6),
          const _WindowControls(),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
  
  Future<void> _openTabSearch(BuildContext context) async {
    final tabManager = context.read<TabManager>();
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A20),
          title: const Text('Rechercher un onglet', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tapez pour rechercher...',
              hintStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (value) {
              final matchingTabs = tabManager.tabs.where((tab) {
                final title = tab.title?.toLowerCase() ?? '';
                final url = tab.url?.toLowerCase() ?? '';
                final query = value.toLowerCase();
                return title.contains(query) || url.contains(query);
              }).toList();
              
              if (matchingTabs.isNotEmpty && dialogContext.mounted) {
                tabManager.selectTab(matchingTabs.first.id);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    TabManager tabManager,
    TabGroupService groupService,
    Color accentColor,
  ) {
    final groups = groupService.orderedGroups;
    
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'Aucun onglet ouvert',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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
              children: groups.map((group) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.4, // Limiter à 40% de la largeur disponible
                    minWidth: 150,
                  ),
                  child: _GroupWidget(
                    group: group,
                    tabManager: tabManager,
                    groupService: groupService,
                    accentColor: accentColor,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _GroupWidget extends StatelessWidget {
  final TabGroup group;
  final TabManager tabManager;
  final TabGroupService groupService;
  final Color accentColor;

  const _GroupWidget({
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 32, // Limiter à 32px pour tenir dans 36px (avec margin 1px)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // En-tête du groupe
            _GroupHeader(
              group: group,
              isActive: isGroupActive,
              groupService: groupService,
              accentColor: accentColor,
              colorCode: group.colorCode,
            ),
            // Onglets du groupe (si expandé) - Afficher seulement si on a de la place
            if (group.isExpanded)
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 12, // Hauteur réduite pour les onglets (32 - 20 = 12)
                    maxWidth: 400,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: group.tabIds.map((tabId) {
                    try {
                      final tab = tabManager.tabs.firstWhere(
                        (t) => t.id == tabId,
                      );
                      
                      final isActive = tab.id == activeTab?.id;
                      
                      return _GroupedTabItem(
                        tab: tab,
                        isActive: isActive,
                        colorCode: group.colorCode,
                        accentColor: accentColor,
                        onClose: () => tabManager.closeTab(tab.id),
                        onSelect: () => tabManager.selectTab(tab.id),
                      );
                    } catch (e) {
                      return const SizedBox.shrink();
                    }
                  }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final TabGroup group;
  final bool isActive;
  final TabGroupService groupService;
  final Color accentColor;
  final int colorCode;

  const _GroupHeader({
    required this.group,
    required this.isActive,
    required this.groupService,
    required this.accentColor,
    required this.colorCode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => groupService.toggleGroup(group.id),
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
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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

class _GroupedTabItem extends StatelessWidget {
  final TabModel tab;
  final bool isActive;
  final int colorCode;
  final Color accentColor;
  final VoidCallback onClose;
  final VoidCallback onSelect;

  const _GroupedTabItem({
    required this.tab,
    required this.isActive,
    required this.colorCode,
    required this.accentColor,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(left: 2, right: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        constraints: const BoxConstraints(
          minWidth: 100,
          maxWidth: 150,
          maxHeight: 12, // Hauteur réduite
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Color(colorCode).withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? Color(colorCode).withOpacity(0.6)
                : Colors.transparent,
            width: isActive ? 1.5 : 0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favicon ou icône
            _buildFavicon(),
            const SizedBox(width: 4),
            // Titre (tronqué)
            Flexible(
              child: Text(
                tab.title ?? tab.url ?? 'Nouvel onglet',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            // Bouton fermer
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(1),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 10,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavicon() {
    if (tab.favicon != null && tab.favicon!.isNotEmpty) {
      try {
        // TabModel utilise String? pour favicon (base64)
        final faviconBytes = base64Decode(tab.favicon!);
        return Image.memory(
          faviconBytes,
          width: 16,
          height: 16,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              CupertinoIcons.globe,
              size: 14,
              color: Color(colorCode),
            );
          },
        );
      } catch (e) {
        // En cas d'erreur de décodage, afficher l'icône par défaut
      }
    }
    
    return Icon(
      CupertinoIcons.globe,
      size: 14,
      color: Color(colorCode),
    );
  }
}

/// Bouton d'icône pour la tab bar
class _TabBarIconButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _TabBarIconButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
  });

  @override
  State<_TabBarIconButton> createState() => _TabBarIconButtonState();
}

class _TabBarIconButtonState extends State<_TabBarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final accentColor = colorThemeManager.nativeSecondaryColor;
    
    final button = GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 28,
        height: 26,
        decoration: BoxDecoration(
          color: _isHovered && widget.onPressed != null
              ? accentColor.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: widget.onPressed != null
              ? (_isHovered ? accentColor : accentColor.withOpacity(0.8))
              : accentColor.withOpacity(0.3),
        ),
      ),
    );

    return MouseRegion(
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
  }
}

/// Contrôles de fenêtre (minimiser, agrandir, fermer)
class _WindowControls extends StatefulWidget {
  const _WindowControls();

  @override
  State<_WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<_WindowControls> with WindowListener {
  bool _isMaximized = false;

  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

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
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
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
          hoverColor: gxRed.withOpacity(0.2),
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
  final Color iconColor;
  final Color? hoverColor;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    required this.iconColor,
    this.hoverColor,
    required this.onTap,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.hoverColor ?? widget.iconColor.withOpacity(0.2))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.iconColor,
          ),
        ),
      ),
    );
  }
}
