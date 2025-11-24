import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/tab_model.dart';
import '../../core/constants/notilus_colors.dart';
import '../../widgets/browser/web_content_view.dart';
import '../../services/tab_webview_manager.dart';

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
              // Contenu - Utilise le même engine que la tab pour éviter les duplications
              widget.tab != null
                  ? _buildTabContent()
                  : _buildEmptyState(),

              // Overlay de drop avec animation
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
                        boxShadow: [
                          BoxShadow(
                            color: NotilusColors.neonRed.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_down_circle_fill,
                            size: 48,
                            color: NotilusColors.neonRed,
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 1000.ms, color: NotilusColors.neonRed.withOpacity(0.5))
                              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.easeInOut)
                              .then()
                              .scale(begin: const Offset(1.0, 1.0), end: const Offset(0.9, 0.9), duration: 500.ms, curve: Curves.easeInOut),
                          const SizedBox(height: 12),
                          Text(
                            'Déposer l\'onglet ici',
                            style: TextStyle(
                              color: NotilusColors.neonRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 200.ms),
                        ],
                      ),
                    )
                        .animate()
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 200.ms, curve: Curves.easeOutCubic),
                  ),
                ),

              // Barre de contrôle (apparaît au survol) avec animation
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
                          onPressed: () {
                            widget.onSwap!();
                            // Effet de feedback
                            HapticFeedback.mediumImpact();
                          },
                        )
                            .animate()
                            .fadeIn(duration: 200.ms, delay: 50.ms)
                            .slideX(begin: 0.2, end: 0, duration: 200.ms, curve: Curves.easeOutCubic),
                      const SizedBox(width: 4),
                      if (widget.onClose != null)
                        _ControlButton(
                          icon: CupertinoIcons.xmark_circle_fill,
                          tooltip: 'Fermer ce panneau',
                          onPressed: () {
                            widget.onClose!();
                            // Effet de feedback
                            HapticFeedback.mediumImpact();
                          },
                          isDanger: true,
                        )
                            .animate()
                            .fadeIn(duration: 200.ms, delay: 100.ms)
                            .slideX(begin: 0.2, end: 0, duration: 200.ms, curve: Curves.easeOutCubic),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: -0.1, end: 0, duration: 200.ms, curve: Curves.easeOutCubic),
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

  Widget _buildTabContent() {
    if (widget.tab == null) return const SizedBox.shrink();
    
    // Utiliser le même engine que la tab pour éviter les duplications
    return Consumer<TabWebViewManager>(
      builder: (context, webViewManager, _) {
        final engine = webViewManager.getEngine(widget.tab!.id);
        if (engine == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: NotilusColors.neonRed,
            ),
          );
        }
        
        // Utiliser WebContentView qui gère déjà le partage d'engine
        return WebContentView(tab: widget.tab)
            .animate()
            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic);
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

