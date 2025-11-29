import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'tab_context_menu.dart';

class TabItem extends StatefulWidget {
  final TabModel tab;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback? onReload;
  final VoidCallback? onDuplicate;
  final VoidCallback? onPin;
  final VoidCallback? onAddToGroup;
  final VoidCallback? onCloseOthers;
  final VoidCallback? onCloseToRight;

  const TabItem({
    super.key,
    required this.tab,
    required this.onTap,
    required this.onClose,
    this.onReload,
    this.onDuplicate,
    this.onPin,
    this.onAddToGroup,
    this.onCloseOthers,
    this.onCloseToRight,
  });

  @override
  State<TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<TabItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  Offset? _contextMenuPosition;

  void _showContextMenu(BuildContext context, Offset position) {
    setState(() {
      _contextMenuPosition = position;
    });

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          TabContextMenu(
            tab: widget.tab,
            onClose: widget.onClose,
            onReload: widget.onReload,
            onDuplicate: widget.onDuplicate,
            onPin: widget.onPin,
            onAddToGroup: widget.onAddToGroup,
            onCloseOthers: widget.onCloseOthers,
            onCloseToRight: widget.onCloseToRight,
            position: position,
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        _contextMenuPosition = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.tab.isSelected;
    final isPinned = widget.tab.isPinned;
    
    final themeColors = _getThemeFromContext();
    final backgroundColor = isSelected
        ? themeColors.selected.withOpacity(0.2)
        : _isHovered
            ? themeColors.hover
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        onLongPress: () {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero);
            _showContextMenu(context, position);
          }
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppConstants.minTabWidth,
            maxWidth: AppConstants.maxTabWidth,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? themeColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Pin indicator
              if (isPinned)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.push_pin,
                    size: 12,
                    color: themeColors.primary,
                  ),
                ),
              
              // Favicon or loading indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildIcon(themeColors),
              ),
              
              // Title
              Expanded(
                child: Text(
                  widget.tab.title ?? widget.tab.url ?? 'Nouvel onglet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? themeColors.primary
                        : themeColors.text,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              
              // Close button
              if (_isHovered || isSelected)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: widget.onClose,
                  color: themeColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  tooltip: 'Fermer',
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(AppTheme theme) {
    if (widget.tab.state == TabState.loading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
        ),
      );
    }
    
    if (widget.tab.favicon != null) {
      return Image.network(
        widget.tab.favicon!,
        width: 16,
        height: 16,
        errorBuilder: (_, __, ___) => Icon(
          Icons.language,
          size: 16,
          color: theme.textSecondary,
        ),
      );
    }
    
    return Icon(
      Icons.language,
      size: 16,
      color: theme.textSecondary,
    );
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

