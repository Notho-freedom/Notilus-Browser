import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
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
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C20),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF2D55).withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _GXTabBarIconButton(
            icon: isSidebarVisible
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            tooltip: isSidebarVisible ? 'Masquer la barre latérale' : 'Afficher la barre latérale',
            onPressed: onMenuTap,
          ),
          const SizedBox(width: 2),
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
