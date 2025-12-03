/// Adaptive Tab Bar - Barre d'onglets avec compression intelligente
/// Les tabs se compressent en mode favicon quand l'espace est insuffisant
library adaptive_tab_bar;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../common/nx_design_system.dart';

/// Configuration d'un onglet
class TabConfig {
  final String id;
  final String title;
  final String? faviconUrl;
  final IconData? icon;
  final bool isActive;
  final bool isPinned;
  final bool isLoading;
  final bool isPrivate;
  final Color? groupColor;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final VoidCallback? onMiddleClick;

  const TabConfig({
    required this.id,
    required this.title,
    this.faviconUrl,
    this.icon,
    this.isActive = false,
    this.isPinned = false,
    this.isLoading = false,
    this.isPrivate = false,
    this.groupColor,
    this.onTap,
    this.onClose,
    this.onMiddleClick,
  });
}

/// Mode d'affichage des tabs
enum TabDisplayMode {
  /// Affichage complet: favicon + titre + close
  full,
  /// Affichage compact: favicon + titre tronqué + close
  compact,
  /// Affichage icône: favicon uniquement (tooltip au hover)
  iconOnly,
}

/// Barre d'onglets adaptative avec Drag & Drop
class AdaptiveTabBar extends StatefulWidget {
  final List<TabConfig> tabs;
  final double availableWidth;
  final double minTabWidth;
  final double maxTabWidth;
  final double iconOnlyWidth;
  final double height;
  final Color? backgroundColor;
  final Color? activeTabColor;
  final ValueChanged<int>? onReorder;
  final VoidCallback? onNewTab;

  const AdaptiveTabBar({
    super.key,
    required this.tabs,
    required this.availableWidth,
    this.minTabWidth = 120.0,
    this.maxTabWidth = 200.0,
    this.iconOnlyWidth = 40.0,
    this.height = 36.0,
    this.backgroundColor,
    this.activeTabColor,
    this.onReorder,
    this.onNewTab,
  });

  @override
  State<AdaptiveTabBar> createState() => _AdaptiveTabBarState();
}

class _AdaptiveTabBarState extends State<AdaptiveTabBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  TabDisplayMode _calculateDisplayMode() {
    if (widget.tabs.isEmpty) return TabDisplayMode.full;
    
    final pinnedCount = widget.tabs.where((t) => t.isPinned).length;
    final normalCount = widget.tabs.length - pinnedCount;
    
    // Espace pour les tabs épinglées (toujours en mode icône)
    final pinnedWidth = pinnedCount * widget.iconOnlyWidth;
    
    // Espace restant pour les tabs normales
    final remainingWidth = widget.availableWidth - pinnedWidth - 40; // 40 pour le bouton +
    
    if (normalCount == 0) return TabDisplayMode.full;
    
    final widthPerTab = remainingWidth / normalCount;
    
    if (widthPerTab >= widget.minTabWidth) {
      return TabDisplayMode.full;
    } else if (widthPerTab >= widget.iconOnlyWidth * 2) {
      return TabDisplayMode.compact;
    } else {
      return TabDisplayMode.iconOnly;
    }
  }

  double _getTabWidth(TabConfig tab, TabDisplayMode mode) {
    if (tab.isPinned) return widget.iconOnlyWidth;
    
    switch (mode) {
      case TabDisplayMode.full:
        return widget.maxTabWidth;
      case TabDisplayMode.compact:
        return widget.minTabWidth;
      case TabDisplayMode.iconOnly:
        return widget.iconOnlyWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayMode = _calculateDisplayMode();

    return Container(
      height: widget.height,
      color: widget.backgroundColor ?? theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollController: _scrollController,
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 4,
                  color: Colors.transparent,
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                widget.onReorder?.call(newIndex);
              },
              itemCount: widget.tabs.length,
              itemBuilder: (context, index) {
                final tab = widget.tabs[index];
                return ReorderableDragStartListener(
                  key: ValueKey(tab.id),
                  index: index,
                  child: _AdaptiveTab(
                    config: tab,
                    displayMode: tab.isPinned ? TabDisplayMode.iconOnly : displayMode,
                    width: _getTabWidth(tab, displayMode),
                    height: widget.height,
                    activeColor: widget.activeTabColor,
                  ),
                );
              },
            ),
          ),
          // Bouton nouveau tab
          if (widget.onNewTab != null)
            NxIconButton(
              icon: CupertinoIcons.plus,
              onPressed: widget.onNewTab,
              tooltip: 'Nouvel onglet (Ctrl+T)',
              size: 16,
              padding: const EdgeInsets.all(10),
            ),
        ],
      ),
    );
  }
}

/// Widget d'onglet individuel
class _AdaptiveTab extends StatefulWidget {
  final TabConfig config;
  final TabDisplayMode displayMode;
  final double width;
  final double height;
  final Color? activeColor;

  const _AdaptiveTab({
    required this.config,
    required this.displayMode,
    required this.width,
    required this.height,
    this.activeColor,
  });

  @override
  State<_AdaptiveTab> createState() => _AdaptiveTabState();
}

class _AdaptiveTabState extends State<_AdaptiveTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = widget.config;
    
    final isActive = config.isActive;
    final showClose = _isHovered && !config.isPinned && widget.displayMode != TabDisplayMode.iconOnly;
    
    // Couleurs
    final bgColor = isActive 
        ? (widget.activeColor ?? theme.colorScheme.primaryContainer.withOpacity(0.3))
        : (_isHovered ? theme.colorScheme.surface.withOpacity(0.5) : Colors.transparent);
    
    final textColor = isActive 
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withOpacity(0.7);

    Widget tabContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: config.onTap,
        onTertiaryTapUp: (_) => config.onMiddleClick?.call(),
        child: AnimatedContainer(
          duration: NxTokens.durationFast,
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.displayMode == TabDisplayMode.iconOnly ? 0 : 8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(NxTokens.radiusSm),
            border: config.groupColor != null 
                ? Border(bottom: BorderSide(color: config.groupColor!, width: 2))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.displayMode == TabDisplayMode.iconOnly 
                ? MainAxisAlignment.center 
                : MainAxisAlignment.start,
            children: [
              // Favicon ou icône
              _buildFavicon(config, textColor),
              
              // Titre (seulement si pas iconOnly)
              if (widget.displayMode != TabDisplayMode.iconOnly) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    config.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
              
              // Bouton fermer
              if (showClose)
                GestureDetector(
                  onTap: config.onClose,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 12,
                      color: textColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Tooltip pour mode iconOnly
    if (widget.displayMode == TabDisplayMode.iconOnly || config.isPinned) {
      tabContent = NxTooltip(
        message: config.title,
        child: tabContent,
      );
    }

    return tabContent;
  }

  Widget _buildFavicon(TabConfig config, Color fallbackColor) {
    if (config.isLoading) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fallbackColor),
        ),
      );
    }

    if (config.isPrivate) {
      return Icon(
        CupertinoIcons.eye_slash,
        size: 14,
        color: fallbackColor,
      );
    }

    if (config.icon != null) {
      return Icon(
        config.icon,
        size: 14,
        color: fallbackColor,
      );
    }

    if (config.faviconUrl != null && config.faviconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.network(
          config.faviconUrl!,
          width: 14,
          height: 14,
          errorBuilder: (_, __, ___) => Icon(
            CupertinoIcons.globe,
            size: 14,
            color: fallbackColor,
          ),
        ),
      );
    }

    return Icon(
      CupertinoIcons.globe,
      size: 14,
      color: fallbackColor,
    );
  }
}

