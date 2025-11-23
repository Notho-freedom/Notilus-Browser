import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../models/tab_model.dart';

const Color _gxRed = Color(0xFFFF2D55);

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
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        border: Border(
          bottom: BorderSide(
            color: _gxRed.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
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
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: tabManager.tabs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == tabManager.tabs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Tooltip(
                          message: 'Nouvel onglet',
                          child: _GXTabBarIconButton(
                            icon: CupertinoIcons.add,
                            tooltip: 'Nouvel onglet',
                            compact: true,
                            onPressed: () => tabManager.createNewTab(),
                          ),
                        ),
                      );
                    }

                    final tab = tabManager.tabs[index];
                    final isActive = tab.isSelected;

                    return _GXTabItem(
                      tab: tab,
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
              _GXTabBarIconButton(
                icon: CupertinoIcons.square_split_2x1,
                tooltip: 'Split view (bientôt)',
                onPressed: () {},
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
                side: BorderSide(color: _gxRed.withOpacity(0.6), width: 1),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              title: Row(
                children: [
                  const Icon(CupertinoIcons.search, size: 16, color: _gxRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      cursorColor: _gxRed,
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
                                    errorBuilder: (_, __, ___) => Icon(
                                      CupertinoIcons.globe,
                                      size: 18,
                                      color: _gxRed.withOpacity(0.85),
                                    ),
                                  )
                                : Icon(
                                    CupertinoIcons.globe,
                                    size: 18,
                                    color: _gxRed.withOpacity(0.85),
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
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _GXTabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_GXTabItem> createState() => _GXTabItemState();
}

class _GXTabItemState extends State<_GXTabItem> {
  bool _isHovered = false;
  bool _closeHovered = false;

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.tab.title ?? 'Speed Dial';
    const activeGradient = LinearGradient(
      colors: [
        Color(0xFFFF3B6A),
        Color(0xFFB1165A),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 240,
          ),
          height: 32,
          margin: const EdgeInsets.only(right: 2),
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
                        // Favicon
                        SizedBox(
                          width: 24,
                          child: Center(
                            child: widget.tab.favicon != null
                                ? Image.network(
                                    widget.tab.favicon!,
                                    width: 16,
                                    height: 16,
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
                              color: Colors.white.withOpacity(widget.isActive ? 0.95 : 0.8),
                              fontSize: 12,
                              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Close button
                        MouseRegion(
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
  final bool compact;

  const _GXTabBarIconButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.compact = false,
  });

  @override
  State<_GXTabBarIconButton> createState() => _GXTabBarIconButtonState();
}

class _GXTabBarIconButtonState extends State<_GXTabBarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.compact ? 28 : 32,
        height: 28,
        decoration: BoxDecoration(
          color: _isHovered && widget.onPressed != null
              ? _gxRed.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          size: widget.compact ? 16 : 18,
          color: widget.onPressed != null
              ? (_isHovered ? _gxRed : _gxRed.withOpacity(0.8))
              : _gxRed.withOpacity(0.35),
        ),
      ),
    );

    final content = MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.tooltip != null
          ? Tooltip(
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

    return Row(
      children: [
        _WindowButton(
          icon: CupertinoIcons.minus,
          iconSize: 13,
          tooltip: 'Minimiser',
          onTap: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: _isMaximized ? CupertinoIcons.rectangle : CupertinoIcons.square,
          iconSize: 13,
          tooltip: _isMaximized ? 'Restaurer' : 'Agrandir',
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
          hoverColor: const Color(0xFFE81123),
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
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    this.hoverColor,
    required this.onTap,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 44,
        height: 32,
        color: _hovered
            ? (widget.hoverColor ?? _gxRed.withOpacity(0.18))
            : Colors.transparent,
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.hoverColor != null
                ? Colors.white
                : (_hovered ? _gxRed : _gxRed.withOpacity(0.8)),
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: button,
      ),
    );
  }
}
