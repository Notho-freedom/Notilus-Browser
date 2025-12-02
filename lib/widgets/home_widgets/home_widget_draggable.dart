/// Widget draggable pour les widgets de la page d'accueil (style Mosaic)
library home_widget_draggable;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/home_widget_models.dart';
import '../../models/home_widget_drag_data.dart';
import '../../models/mosaic_models.dart'; // Pour DropZone
import '../../services/home_widget_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import 'home_widget_base.dart';
import '../../widgets/browser/home_pages/widget_factory.dart' as widgetFactory;

/// Widget draggable pour un widget de la page d'accueil
class HomeWidgetDraggable extends StatefulWidget {
  final HomeWidget widget;
  final bool isEditMode;
  final VoidCallback? onMinimize;
  final VoidCallback? onRemove;
  final VoidCallback? onSettings;

  const HomeWidgetDraggable({
    super.key,
    required this.widget,
    required this.isEditMode,
    this.onMinimize,
    this.onRemove,
    this.onSettings,
  });

  @override
  State<HomeWidgetDraggable> createState() => _HomeWidgetDraggableState();
}

class _HomeWidgetDraggableState extends State<HomeWidgetDraggable> {
  bool _isHovered = false;
  bool _showControls = false;

  void _onHoverChange(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
      _showControls = isHovered && widget.isEditMode;
    });
  }

  DropZone? _getDropZoneFromOffset(Offset localPosition, Size size) {
    final x = localPosition.dx;
    final y = localPosition.dy;
    final w = size.width;
    final h = size.height;

    // Zone centrale (40% au milieu)
    final centerRect = Rect.fromLTWH(w * 0.3, h * 0.3, w * 0.4, h * 0.4);
    if (centerRect.contains(localPosition)) {
      return DropZone.center;
    }

    // Zones sur les bords
    if (x < w * 0.3) return DropZone.left;
    if (x > w * 0.7) return DropZone.right;
    if (y < h * 0.3) return DropZone.top;
    if (y > h * 0.7) return DropZone.bottom;

    return DropZone.center;
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = colorTheme.nativeSecondaryColor;
    final widgetService = Provider.of<HomeWidgetService>(context, listen: true);
    
    final isDragOver = widgetService.dragOverWidgetId == widget.widget.id;
    final dragZone = widgetService.dragOverZone;

    if (!widget.isEditMode) {
      return widgetFactory.HomeWidgetFactory.buildWidget(
        widget: widget.widget,
        onMinimize: widget.onMinimize,
        onRemove: widget.onRemove,
        onSettings: widget.onSettings,
      );
    }

    return _DualDragTarget(
      widget: widget.widget,
      widgetService: widgetService,
      getDropZoneFromOffset: _getDropZoneFromOffset,
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            widgetService.setFocusedWidget(widget.widget.id);
            HapticFeedback.selectionClick();
          },
          child: MouseRegion(
            onEnter: (_) => _onHoverChange(true),
            onExit: (_) => _onHoverChange(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12).withOpacity(0.6),
                border: Border.all(
                  color: widgetService.focusedWidgetId == widget.widget.id
                      ? accentColor.withOpacity(0.8)
                      : (_isHovered
                          ? accentColor.withOpacity(0.4)
                          : accentColor.withOpacity(0.1)),
                  width: widgetService.focusedWidgetId == widget.widget.id ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: widgetService.focusedWidgetId == widget.widget.id
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Contenu du widget
                  Positioned.fill(
                    child: widget.widget.isMinimized
                        ? _MinimizedContent(widget: widget.widget, accentColor: accentColor)
                        : widgetFactory.HomeWidgetFactory.buildWidget(
                            widget: widget.widget,
                            onMinimize: widget.onMinimize,
                            onRemove: widget.onRemove,
                            onSettings: widget.onSettings,
                          ),
                  ),

                  // Indicateurs de drop zone
                  if (isDragOver && dragZone != null)
                    Positioned.fill(
                      child: _DropZoneIndicator(
                        zone: dragZone,
                        accentColor: accentColor,
                      ),
                    ),

                  // Contrôles (apparaissent au hover)
                  if (_showControls && !isDragOver)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _WidgetControls(
                        widget: widget.widget,
                        accentColor: accentColor,
                        onMinimize: widget.onMinimize,
                        onRemove: widget.onRemove,
                        onSettings: widget.onSettings,
                      )
                          .animate()
                          .fadeIn(duration: 150.ms)
                          .slideY(begin: -0.2, end: 0, duration: 150.ms),
                    ),

                  // Handle de drag (coin supérieur gauche)
                  if (_showControls && !isDragOver)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _DragHandle(
                        widget: widget.widget,
                        accentColor: accentColor,
                      )
                          .animate()
                          .fadeIn(duration: 150.ms)
                          .slideX(begin: -0.2, end: 0, duration: 150.ms),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Handle de drag pour déplacer le widget
class _DragHandle extends StatefulWidget {
  final HomeWidget widget;
  final Color accentColor;

  const _DragHandle({required this.widget, required this.accentColor});

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final widgetService = Provider.of<HomeWidgetService>(context, listen: false);
    
    return Draggable<HomeWidgetDragData>(
      data: HomeWidgetDragData(
        widget: widget.widget,
        sourceWidgetId: widget.widget.id,
      ),
      onDragStarted: () {
        setState(() => _isDragging = true);
        HapticFeedback.mediumImpact();
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
        widgetService.setDragOver(null, null);
      },
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A22).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.widget.type.icon, color: widget.accentColor, size: 32),
              const SizedBox(height: 8),
              Text(
                widget.widget.type.label,
                style: TextStyle(
                  color: widget.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.accentColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          CupertinoIcons.move,
          size: 14,
          color: widget.accentColor.withOpacity(0.5),
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isDragging
                ? widget.accentColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            CupertinoIcons.move,
            size: 14,
            color: widget.accentColor,
          ),
        ),
      ),
    );
  }
}

/// Contrôles du widget
class _WidgetControls extends StatelessWidget {
  final HomeWidget widget;
  final Color accentColor;
  final VoidCallback? onMinimize;
  final VoidCallback? onRemove;
  final VoidCallback? onSettings;

  const _WidgetControls({
    required this.widget,
    required this.accentColor,
    this.onMinimize,
    this.onRemove,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onSettings != null)
          _ControlButton(
            icon: CupertinoIcons.settings,
            tooltip: 'Paramètres',
            accentColor: accentColor,
            onTap: onSettings!,
          ),
        if (onMinimize != null) ...[
          const SizedBox(width: 4),
          _ControlButton(
            icon: widget.isMinimized ? CupertinoIcons.plus : CupertinoIcons.minus,
            tooltip: widget.isMinimized ? 'Restaurer' : 'Minimiser',
            accentColor: accentColor,
            onTap: onMinimize!,
          ),
        ],
        if (onRemove != null) ...[
          const SizedBox(width: 4),
          _ControlButton(
            icon: CupertinoIcons.xmark,
            tooltip: 'Supprimer',
            accentColor: accentColor,
            onTap: onRemove!,
          ),
        ],
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 14,
                color: _isHovered
                    ? widget.accentColor
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenu minimisé
class _MinimizedContent extends StatelessWidget {
  final HomeWidget widget;
  final Color accentColor;

  const _MinimizedContent({required this.widget, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(widget.type.icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.type.label,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur de zone de drop
class _DropZoneIndicator extends StatelessWidget {
  final DropZone zone;
  final Color accentColor;

  const _DropZoneIndicator({required this.zone, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Overlay général
        Container(color: accentColor.withOpacity(0.1)),
        
        // Zone mise en évidence
        Positioned(
          left: zone == DropZone.right ? null : 0,
          right: zone == DropZone.left ? null : 0,
          top: zone == DropZone.bottom ? null : 0,
          bottom: zone == DropZone.top ? null : 0,
          width: (zone == DropZone.left || zone == DropZone.right)
              ? (zone == DropZone.center ? null : MediaQuery.of(context).size.width * 0.4)
              : null,
          height: (zone == DropZone.top || zone == DropZone.bottom)
              ? (zone == DropZone.center ? null : MediaQuery.of(context).size.height * 0.4)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              border: Border.all(color: accentColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour accepter les drags de widgets
class _DualDragTarget extends StatelessWidget {
  final HomeWidget widget;
  final HomeWidgetService widgetService;
  final DropZone? Function(Offset, Size) getDropZoneFromOffset;
  final Widget Function(BuildContext, List<dynamic>, List<dynamic>) builder;

  const _DualDragTarget({
    required this.widget,
    required this.widgetService,
    required this.getDropZoneFromOffset,
    required this.builder,
  });

  void _handleDragMove(Offset offset, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(offset);
    final zone = getDropZoneFromOffset(localPos, box.size);
    widgetService.setDragOver(widget.id, zone);
  }

  void _handleDragLeave() {
    widgetService.setDragOver(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<HomeWidgetDragData>(
      onWillAcceptWithDetails: (details) => details.data.widget.id != widget.id,
      onMove: (details) => _handleDragMove(details.offset, context),
      onLeave: (_) => _handleDragLeave(),
      onAcceptWithDetails: (details) {
        final zone = widgetService.dragOverZone ?? DropZone.center;
        final draggedWidget = details.data.widget;
        
        if (zone == DropZone.center) {
          // Échanger les positions
          widgetService.swapWidgets(draggedWidget.id, widget.id);
        } else {
          // Déplacer le widget à côté
          widgetService.moveWidgetToZone(draggedWidget.id, widget.id, zone);
        }
        
        widgetService.setDragOver(null, null);
        HapticFeedback.mediumImpact();
      },
      builder: (context, candidateData, rejectedData) {
        return builder(context, candidateData, rejectedData);
      },
    );
  }
}

