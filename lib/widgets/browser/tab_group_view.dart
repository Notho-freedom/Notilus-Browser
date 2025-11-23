import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../models/tab_group_model.dart';
import '../../models/tab_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/glassmorphic_container.dart';
import 'tab_drop_target.dart';

class TabGroupView extends StatefulWidget {
  final TabGroupModel group;
  final VoidCallback? onDelete;

  const TabGroupView({
    super.key,
    required this.group,
    this.onDelete,
  });

  @override
  State<TabGroupView> createState() => _TabGroupViewState();
}

class _TabGroupViewState extends State<TabGroupView> {
  bool _isExpanded = true;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.group.isCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final groupTabs = tabManager.tabs
        .where((tab) => tab.groupId == widget.group.id)
        .toList();

    return TabDropTarget(
      group: widget.group,
      onDrop: (tab, group) {
        if (group != null) {
          tabManager.addTabToGroup(tab.id, group.id);
        }
      },
      child: MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GlassmorphicContainer(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(8),
        showNeonBorder: _isHovered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Row(
              children: [
                // Color indicator
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _parseColor(widget.group.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Group icon
                if (widget.group.icon != null)
                  Icon(
                    _getIconData(widget.group.icon!),
                    size: 16,
                    color: theme.primary,
                  ),
                
                const SizedBox(width: 8),
                
                // Group name
                Expanded(
                  child: Text(
                    widget.group.name,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                ),
                
                // Tab count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${groupTabs.length}',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 12,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Expand/collapse button
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  color: theme.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                
                // Delete button
                if (_isHovered)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      if (widget.onDelete != null) {
                        widget.onDelete!();
                      }
                    },
                    color: theme.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Supprimer le groupe',
                  ),
              ],
            ),
            
            // Group tabs (if expanded)
            if (_isExpanded && groupTabs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...groupTabs.map((tab) => _buildTabItem(tab, theme, tabManager)),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTabItem(tab, AppTheme theme, TabManager tabManager) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tab.isSelected
            ? theme.selected.withOpacity(0.2)
            : theme.hover.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tab.isSelected
              ? theme.primary
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Favicon
          if (tab.favicon != null)
            Image.network(
              tab.favicon!,
              width: 16,
              height: 16,
              errorBuilder: (_, __, ___) => Icon(
                Icons.language,
                size: 16,
                color: theme.textSecondary,
              ),
            )
          else
            Icon(
              Icons.language,
              size: 16,
              color: theme.textSecondary,
            ),
          
          const SizedBox(width: 8),
          
          // Title
          Expanded(
            child: GestureDetector(
              onTap: () => tabManager.selectTab(tab.id),
              child: Text(
                tab.title ?? tab.url ?? 'Onglet',
                style: TextStyle(
                  color: tab.isSelected ? theme.primary : theme.text,
                  fontSize: 12,
                  fontFamily: 'Roboto Mono',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          
          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            onPressed: () {
              tabManager.removeTabFromGroup(tab.id);
              tabManager.closeTab(tab.id);
            },
            color: theme.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFFF0040);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'shopping':
        return Icons.shopping_cart;
      case 'entertainment':
        return Icons.movie;
      case 'social':
        return Icons.people;
      case 'dev':
        return Icons.code;
      default:
        return Icons.folder;
    }
  }

  AppTheme _getThemeFromContext() {
    return const AppTheme(
      name: 'Default',
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF1A1A1A),
      primary: Color(0xFFFF0040),
      secondary: Color(0xFFFF3366),
      accent: Color(0xFF00FF88),
      text: Color(0xFFE0E0E0),
      textSecondary: Color(0xFF888888),
      error: Color(0xFFFF0040),
      success: Color(0xFF00FF88),
      warning: Color(0xFFFFAA00),
      border: Color(0xFF333333),
      hover: Color(0xFF2A2A2A),
      selected: Color(0xFFFF0040),
    );
  }
}

