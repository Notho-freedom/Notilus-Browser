import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../models/tab_model.dart';

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
            color: const Color(0xFFFF2D55).withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _BrandBadge(),
          const SizedBox(width: 6),
          _GXTabBarIconButton(
            icon: isSidebarVisible
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            tooltip: isSidebarVisible ? 'Masquer la barre latérale' : 'Afficher la barre latérale',
            onPressed: onMenuTap,
          ),
          const SizedBox(width: 6),
          // Tabs container
          Expanded(
            child: Consumer<TabManager>(
              builder: (context, tabManager, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  itemCount: tabManager.tabs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == tabManager.tabs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Tooltip(
                          message: 'Nouvel onglet',
                          child: _GXTabBarIconButton(
                            icon: Icons.add,
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
          const SizedBox(width: 4),
        ],
      ),
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
          height: 28,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            // Fond avec bordures angulaires comme GX
            color: widget.isActive
                ? const Color(0xFF2A2A30)
                : (_isHovered 
                    ? const Color(0xFF1F1F23)
                    : const Color(0xFF1C1C20)),
            // Bordure top rouge pour l'onglet actif
            border: widget.isActive
                ? const Border(
                    top: BorderSide(
                      color: Color(0xFFFA2F55),
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Favicon
              Container(
                width: 32,
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
              
              // Title
              Expanded(
                child: Text(
                  displayTitle,
                  style: TextStyle(
                    color: widget.isActive
                        ? Colors.white.withOpacity(0.95)
                        : Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              
              // Close button
              MouseRegion(
                onEnter: (_) => setState(() => _closeHovered = true),
                onExit: (_) => setState(() => _closeHovered = false),
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _closeHovered
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: (_isHovered || widget.isActive)
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultFavicon() {
    return Icon(
      Icons.language,
      size: 16,
      color: Colors.white.withOpacity(0.4),
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
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          size: widget.compact ? 16 : 18,
          color: widget.onPressed != null
              ? (_isHovered ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.6))
              : Colors.white.withOpacity(0.25),
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

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFF2D55),
          width: 1,
        ),
      ),
      child: const Center(
        child: Text(
          'NOTILUS',
          style: TextStyle(
            color: Color(0xFFFF2D55),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
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
          icon: Icons.remove,
          iconSize: 14,
          tooltip: 'Minimiser',
          onTap: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
          iconSize: 12,
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
          icon: Icons.close,
          iconSize: 14,
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
            ? (widget.hoverColor ?? Colors.white.withOpacity(0.08))
            : Colors.transparent,
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _hovered && widget.hoverColor != null
                ? Colors.white
                : Colors.white.withOpacity(0.8),
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
