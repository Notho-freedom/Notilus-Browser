import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/tab_model.dart';
import '../../core/constants/notilus_colors.dart';
import '../../widgets/browser/web_content_view.dart';

/// Panneau split-screen avancé avec support drag-and-drop
class AdvancedSplitPane extends StatefulWidget {
  final int paneIndex;
  final TabModel? tab;
  final Function(TabModel) onTabDropped;
  final VoidCallback? onClose;
  final VoidCallback? onSwap;

  const AdvancedSplitPane({
    super.key,
    required this.paneIndex,
    this.tab,
    required this.onTabDropped,
    this.onClose,
    this.onSwap,
  });

  @override
  State<AdvancedSplitPane> createState() => _AdvancedSplitPaneState();
}

class _AdvancedSplitPaneState extends State<AdvancedSplitPane> {
  bool _isHovered = false;
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TabModel>(
      onWillAccept: (data) => true,
      onAccept: (tab) {
        widget.onTabDropped(tab);
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
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B0E),
            border: Border.all(
              color: _isDraggingOver
                  ? NotilusColors.neonRed
                  : (_isHovered
                      ? NotilusColors.neonRed.withOpacity(0.5)
                      : NotilusColors.neonRed.withOpacity(0.1)),
              width: _isDraggingOver ? 3 : (_isHovered ? 2 : 1),
            ),
          ),
          child: Stack(
            children: [
              // Contenu
              widget.tab != null
                  ? WebContentView(tab: widget.tab)
                  : _buildEmptyState(),

              // Overlay de drop
              if (_isDraggingOver)
                Container(
                  color: NotilusColors.neonRed.withOpacity(0.15),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: NotilusColors.neonRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NotilusColors.neonRed,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_down_circle_fill,
                            size: 48,
                            color: NotilusColors.neonRed,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Déposer l\'onglet ici',
                            style: TextStyle(
                              color: NotilusColors.neonRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Barre de contrôle (apparaît au survol)
              if (_isHovered && !_isDraggingOver)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onSwap != null)
                        _ControlButton(
                          icon: CupertinoIcons.arrow_left_right,
                          tooltip: 'Échanger avec le panneau précédent',
                          onPressed: widget.onSwap!,
                        ),
                      const SizedBox(width: 4),
                      if (widget.onClose != null)
                        _ControlButton(
                          icon: CupertinoIcons.xmark_circle_fill,
                          tooltip: 'Fermer ce panneau',
                          onPressed: widget.onClose!,
                          isDanger: true,
                        ),
                    ],
                  ),
                ),

              // Détecteur de survol
              MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Container(color: Colors.transparent),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.square_split_2x1,
            size: 64,
            color: NotilusColors.neonRed.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Panneau ${widget.paneIndex + 1}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Glissez un onglet ici',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDanger;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDanger
        ? NotilusColors.neonRed
        : NotilusColors.neonRed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? color.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withOpacity(_isHovered ? 0.6 : 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: color.withOpacity(_isHovered ? 1.0 : 0.7),
          ),
        ),
      ),
    );
  }
}

