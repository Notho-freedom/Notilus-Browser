import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../models/tab_group_model.dart';
import '../../core/theme/app_theme.dart';

class TabDropTarget extends StatefulWidget {
  final Widget child;
  final TabGroupModel? group;
  final Function(TabModel, TabGroupModel?) onDrop;

  const TabDropTarget({
    super.key,
    required this.child,
    this.group,
    required this.onDrop,
  });

  @override
  State<TabDropTarget> createState() => _TabDropTargetState();
}

class _TabDropTargetState extends State<TabDropTarget> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();
    
    return DragTarget<TabModel>(
      onWillAccept: (data) => true,
      onAccept: (tab) {
        widget.onDrop(tab, widget.group);
        setState(() {
          _isDraggingOver = false;
        });
      },
      onLeave: (data) {
        setState(() {
          _isDraggingOver = false;
        });
      },
      onMove: (details) {
        setState(() {
          _isDraggingOver = true;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: _isDraggingOver
              ? BoxDecoration(
                  border: Border.all(
                    color: theme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.primary.withOpacity(0.1),
                )
              : null,
          child: widget.child,
        );
      },
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

