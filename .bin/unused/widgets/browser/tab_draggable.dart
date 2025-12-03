import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import 'tab_item.dart';

class TabDraggable extends StatelessWidget {
  final TabModel tab;
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback? onDuplicate;
  final VoidCallback? onPin;
  final VoidCallback? onAddToGroup;
  final VoidCallback? onCloseOthers;
  final VoidCallback? onCloseToRight;

  const TabDraggable({
    super.key,
    required this.tab,
    required this.child,
    required this.onTap,
    required this.onClose,
    this.onDuplicate,
    this.onPin,
    this.onAddToGroup,
    this.onCloseOthers,
    this.onCloseToRight,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<TabModel>(
      data: tab,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: Container(
            width: 200,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: child,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: child,
      ),
      child: TabItem(
        tab: tab,
        onTap: onTap,
        onClose: onClose,
        onDuplicate: onDuplicate,
        onPin: onPin,
        onAddToGroup: onAddToGroup,
        onCloseOthers: onCloseOthers,
        onCloseToRight: onCloseToRight,
      ),
    );
  }
}

