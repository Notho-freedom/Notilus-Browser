import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../models/tab_model.dart';

class ModernTabBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final bool isSidebarVisible;

  const ModernTabBar({
    super.key,
    this.onMenuTap,
    this.isSidebarVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Bouton menu
          _HoverIconButton(
            icon: CupertinoIcons.sidebar_left,
            tooltip: 'Menu',
            onPressed: onMenuTap,
          ),
          
          // Onglets
          Expanded(
            child: Consumer<TabManager>(
              builder: (context, tabManager, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabManager.tabs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == tabManager.tabs.length) {
                      // Bouton nouveau tab
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => tabManager.createNewTab(),
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(
                                CupertinoIcons.add,
                                size: 18,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    final tab = tabManager.tabs[index];
                    final isActive = tab.isSelected;
                    
                    return _ModernTabItem(
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
          
          // Actions
          Row(
            children: [
              _HoverIconButton(
                icon: CupertinoIcons.square_split_2x1,
                tooltip: 'Split view (à venir)',
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              _HoverIconButton(
                icon: CupertinoIcons.square_grid_2x2,
                tooltip: 'Groupes (à venir)',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernTabItem extends StatefulWidget {
  final TabModel tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ModernTabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_ModernTabItem> createState() => _ModernTabItemState();
}

class _ModernTabItemState extends State<_ModernTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.isActive ? 200 : 180,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
                  : (_isHovered
                      ? (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: widget.isActive
                  ? Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      width: 1,
                    )
                  : null,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Favicon
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(0xFF5856D6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: widget.tab.favicon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            widget.tab.favicon!,
                            errorBuilder: (_, __, ___) => Icon(
                              CupertinoIcons.globe,
                              size: 12,
                              color: Color(0xFF5856D6),
                            ),
                          ),
                        )
                      : Icon(
                          CupertinoIcons.globe,
                          size: 12,
                          color: Color(0xFF5856D6),
                        ),
                ),
                const SizedBox(width: 8),
                
                // Titre
                Expanded(
                  child: Text(
                    widget.tab.title ?? widget.tab.url ?? 'Nouvel onglet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Bouton fermer
                if (_isHovered || widget.isActive)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 10,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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
}

/// Bouton d'icône avec effet hover discret, utilisé pour les actions de la barre d'onglets.
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _HoverIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = _hovered
        ? (isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04))
        : Colors.transparent;

    final iconColor = theme.iconTheme.color?.withOpacity(
      widget.onPressed == null ? 0.3 : 0.8,
    );

    final child = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        widget.icon,
        size: 18,
        color: iconColor,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: widget.tooltip != null
            ? Tooltip(
                message: widget.tooltip!,
                child: child,
              )
            : child,
      ),
    );
  }
}
