import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/split_screen_service.dart';
import '../../services/quick_access_service.dart';
import 'package:flutter/services.dart';
import '../../services/bookmark_service.dart';
import '../../models/tab_model.dart';
import '../../services/terminal_manager.dart';
import '../../models/bookmark.dart';
import '../../core/services/color_theme_manager.dart';
import '../common/notilus_monogram.dart';
import '../common/notilus_tooltip.dart';
import '../common/context_menu.dart';

// La couleur rouge est maintenant gérée par ColorThemeManager

class GXTabBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final bool isSidebarVisible;

  const GXTabBar({
    super.key,
    this.onMenuTap,
    this.isSidebarVisible = true,
  });

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
          SizedBox(width: isSidebarVisible ? 10 : 10),
          if (!isSidebarVisible) ...[
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
            icon: isSidebarVisible
                ? CupertinoIcons.sidebar_left
                : CupertinoIcons.sidebar_right,
            tooltip: isSidebarVisible ? 'Masquer la barre latérale' : 'Afficher la barre latérale',
            onPressed: onMenuTap,
          ),
          const SizedBox(width: 10),
          // Tabs container
          Expanded(
            child: Consumer<TabManager>(
              builder: (context, tabManager, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final tabCount = tabManager.tabs.isEmpty ? 1 : tabManager.tabs.length;
                    final double tabWidth = (constraints.maxWidth / (tabCount + 0.4))
                        .clamp(110, 210)
                        .toDouble();

                    return Scrollbar(
                      thickness: 2,
                      radius: const Radius.circular(1),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: tabManager.tabs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == tabManager.tabs.length) {
                            return Padding(
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
                            );
                          }

                          final tab = tabManager.tabs[index];
                          final isActive = tab.isSelected;

                          return DragTarget<TabModel>(
                            onWillAccept: (data) => data != null && data.id != tab.id,
                            onAccept: (draggedTab) {
                              if (draggedTab.id != tab.id) {
                                final oldIndex = tabManager.tabs.indexWhere((t) => t.id == draggedTab.id);
                                final newIndex = index;
                                if (oldIndex != -1) {
                                  tabManager.reorderTab(oldIndex, newIndex);
                                  HapticFeedback.mediumImpact();
                                }
                              }
                            },
                            onMove: (details) {
                              // Feedback visuel pendant le drag
                            },
                            onLeave: (data) {
                              // Feedback visuel quand on quitte la zone
                            },
                            builder: (context, candidateData, rejectedData) {
                              return LongPressDraggable<TabModel>(
                                key: ValueKey(tab.id),
                                data: tab,
                                dragAnchorStrategy: pointerDragAnchorStrategy,
                                delay: const Duration(milliseconds: 300), // Délai raisonnable pour permettre les clics
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
                                          color: gxRed,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: gxRed.withValues(alpha:0.5),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: _GXTabItem(
                                        tab: tab,
                                        width: tabWidth,
                                        isActive: true,
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
                                            color: gxRed,
                                            width: 2.5,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: gxRed.withValues(alpha:0.3),
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
              Builder(
                builder: (context) {
                  final splitService = context.watch<SplitScreenService>();
                  final tabManager = context.watch<TabManager>();
                  
                  if (splitService.isActive && !splitService.isVisible) {
                    // Bouton pour réafficher le split
                    return _GXTabBarIconButton(
                      icon: CupertinoIcons.eye,
                      tooltip: 'Afficher le split-screen',
                      onPressed: () {
                        splitService.setVisible(true);
                        HapticFeedback.lightImpact();
                      },
                    );
                  }
                  
                  return _GXTabBarIconButton(
                    icon: splitService.isActive
                        ? CupertinoIcons.eye_slash // Icône différente quand actif pour indiquer qu'on peut masquer
                        : CupertinoIcons.square_split_2x1,
                    tooltip: splitService.isActive
                        ? 'Masquer le split-screen et revenir aux onglets'
                        : 'Activer le split-screen',
                    onPressed: () {
                      if (splitService.isActive) {
                        // Masquer le split pour revenir aux tabsviews
                        splitService.setVisible(false);
                        HapticFeedback.lightImpact();
                      } else {
                        // Activer le split
                        final activeTabId = tabManager.activeTab?.id;
                        splitService.toggle(activeTabId: activeTabId);
                        HapticFeedback.mediumImpact();
                      }
                    },
                  );
                },
              ),
              _GXTabBarIconButton(
                icon: CupertinoIcons.square_grid_2x2,
                tooltip: 'Groupes (bientôt)',
                onPressed: () {},
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

  Future<void> _openTabSearch(BuildContext context) async {
    final tabManager = context.read<TabManager>();
    final controller = TextEditingController();
    String query = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final colorThemeManager = Provider.of<ColorThemeManager>(dialogContext, listen: true);
        final gxRed = colorThemeManager.nativeSecondaryColor;
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredTabs = tabManager.tabs.where((tab) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return (tab.title?.toLowerCase().contains(q) ?? false) ||
                  (tab.url?.toLowerCase().contains(q) ?? false);
            }).toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF15151A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: gxRed.withValues(alpha: 0.6), width: 1),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              title: Row(
                children: [
                  Icon(CupertinoIcons.search, size: 16, color: gxRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      cursorColor: gxRed,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un onglet...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) => setState(() => query = value.trim()),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                height: 260,
                child: filteredTabs.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun onglet trouvé',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredTabs.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha:0.08),
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
                                      final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
                                      final gxRed = colorThemeManager.nativeSecondaryColor;
                                      return Icon(
                                        CupertinoIcons.globe,
                                        size: 18,
                                        color: gxRed.withValues(alpha: 0.85),
                                      );
                                    },
                                  )
                                : Builder(
                                    builder: (context) {
                                      final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
                                      final gxRed = colorThemeManager.nativeSecondaryColor;
                                      return Icon(
                                        CupertinoIcons.globe,
                                        size: 18,
                                        color: gxRed.withValues(alpha: 0.85),
                                      );
                                    },
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
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              tabManager.selectTab(tab.id);
                            },
                          );
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GXTabItem extends StatefulWidget {
  final TabModel tab;
  final double width;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _GXTabItem({
    required this.tab,
    required this.width,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_GXTabItem> createState() => _GXTabItemState();
}

class _GXTabItemState extends State<_GXTabItem> {
  Color get _gxRed {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    return colorThemeManager.nativeSecondaryColor;
  }
  bool _isHovered = false;
  bool _closeHovered = false;

  void _showContextMenu(BuildContext context, Offset position) {
    if (widget.tab.url == null || widget.tab.url!.isEmpty || widget.tab.url!.startsWith('about:')) {
      return;
    }

    final quickAccessService = QuickAccessService();
    final bookmarkService = BookmarkService();
    
    ContextMenu.show(
      context: context,
      position: position,
      actions: [
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
    final gxRedDark = colorThemeManager.primaryDarkColor;
    
    final activeGradient = LinearGradient(
      colors: [
        gxRed,
        gxRedDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return NotilusTooltip(
      message: widget.tab.title ?? widget.tab.url ?? 'Onglet',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          onLongPress: () {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero);
              _showContextMenu(context, position);
            }
          },
          child: SizedBox(
            width: widget.width,
            height: 32,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: widget.isActive ? activeGradient : null,
                    color: widget.isActive ? null : Colors.transparent,
                  ),
                ),
                const SizedBox(height: 1),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: widget.isActive
                          ? activeGradient
                          : null,
                      color: widget.isActive
                          ? null
                          : (_isHovered
                              ? const Color(0xFF1F1F23)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                        // Favicon dynamique
                        SizedBox(
                          width: 24,
                          child: Center(
                            child: widget.tab.favicon != null && 
                                   widget.tab.favicon!.isNotEmpty &&
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
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:widget.isActive ? 0.95 : 0.8),
                              fontSize: 12,
                              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
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
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _defaultFavicon() {
    return Icon(
      CupertinoIcons.globe,
      size: 16,
      color: _gxRed,
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
