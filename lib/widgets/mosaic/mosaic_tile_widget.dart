/// Notilus Mosaic Tile Widget - Widget individuel de tile
/// Gère le rendu du contenu, les interactions et le drag/drop
library mosaic_tile_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/mosaic_models.dart';
import '../../models/tab_model.dart';
import '../../services/mosaic_service.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../core/services/color_theme_manager.dart';
import 'mosaic_tile_content.dart';

class MosaicTileWidget extends StatefulWidget {
  final MosaicTile tile;

  const MosaicTileWidget({super.key, required this.tile});

  @override
  State<MosaicTileWidget> createState() => _MosaicTileWidgetState();
}

class _MosaicTileWidgetState extends State<MosaicTileWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _showControls = false;
  DropZone? _hoverZone;
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChange(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
      _showControls = isHovered;
    });
    if (isHovered) {
      _hoverController.forward();
      context.read<NotilusMosaicService>().setHoveredTile(widget.tile.id);
    } else {
      _hoverController.reverse();
      context.read<NotilusMosaicService>().setHoveredTile(null);
    }
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
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final mosaicService = context.watch<NotilusMosaicService>();
    
    final isFocused = mosaicService.focusedTileId == widget.tile.id;
    final isDragOver = mosaicService.dragOverTileId == widget.tile.id;
    final dragZone = mosaicService.dragOverZone;

    // Accepter les MosaicDragData et les TabModel (depuis la barre d'onglets)
    return _DualDragTarget(
      tile: widget.tile,
      mosaicService: mosaicService,
      getDropZoneFromOffset: _getDropZoneFromOffset,
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            mosaicService.setFocusedTile(widget.tile.id);
            HapticFeedback.selectionClick();
          },
          child: MouseRegion(
            onEnter: (_) => _onHoverChange(true),
            onExit: (_) => _onHoverChange(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12),
                border: Border.all(
                  color: isFocused
                      ? accentColor.withOpacity(0.8)
                      : (_isHovered
                          ? accentColor.withOpacity(0.4)
                          : accentColor.withOpacity(0.1)),
                  width: isFocused ? 2 : 1,
                ),
                boxShadow: isFocused
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
                  // Contenu de la tile
                  Positioned.fill(
                    child: widget.tile.isMinimized
                        ? _MinimizedContent(tile: widget.tile, accentColor: accentColor)
                        : MosaicTileContent(tile: widget.tile),
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
                      child: _TileControls(
                        tile: widget.tile,
                        accentColor: accentColor,
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
                        tile: widget.tile,
                        accentColor: accentColor,
                      )
                          .animate()
                          .fadeIn(duration: 150.ms)
                          .slideX(begin: -0.2, end: 0, duration: 150.ms),
                    ),

                  // Barre de titre minimale
                  if (!_showControls && widget.tile.type != MosaicTileType.empty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: _TileLabel(tile: widget.tile, accentColor: accentColor),
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

/// Handle de drag pour déplacer la tile
class _DragHandle extends StatefulWidget {
  final MosaicTile tile;
  final Color accentColor;

  const _DragHandle({required this.tile, required this.accentColor});

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Draggable<MosaicDragData>(
      data: MosaicDragData(tile: widget.tile, sourceTileId: widget.tile.id),
      onDragStarted: () {
        setState(() => _isDragging = true);
        HapticFeedback.mediumImpact();
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
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
              Icon(widget.tile.type.icon, color: widget.accentColor, size: 32),
              const SizedBox(height: 8),
              Text(
                widget.tile.type.label,
                style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold),
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

/// Contrôles de la tile (fermer, splitter, maximiser, etc.)
class _TileControls extends StatelessWidget {
  final MosaicTile tile;
  final Color accentColor;

  const _TileControls({required this.tile, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Split horizontal
          _ControlButton(
            icon: CupertinoIcons.rectangle_split_3x1,
            tooltip: 'Diviser horizontalement',
            accentColor: accentColor,
            onTap: () {
              context.read<NotilusMosaicService>().splitTile(
                tile.id,
                SplitDirection.horizontal,
              );
              HapticFeedback.selectionClick();
            },
          ),
          
          const SizedBox(width: 2),
          
          // Split vertical
          _ControlButton(
            icon: CupertinoIcons.rectangle_split_3x1,
            tooltip: 'Diviser verticalement',
            accentColor: accentColor,
            rotated: true,
            onTap: () {
              context.read<NotilusMosaicService>().splitTile(
                tile.id,
                SplitDirection.vertical,
              );
              HapticFeedback.selectionClick();
            },
          ),
          
          const SizedBox(width: 2),
          
          // Maximiser
          _ControlButton(
            icon: CupertinoIcons.arrow_up_left_arrow_down_right,
            tooltip: 'Maximiser',
            accentColor: accentColor,
            onTap: () {
              context.read<NotilusMosaicService>().maximizeTile(tile.id);
              HapticFeedback.mediumImpact();
            },
          ),
          
          const SizedBox(width: 2),
          
          // Minimiser
          _ControlButton(
            icon: tile.isMinimized ? CupertinoIcons.chevron_up : CupertinoIcons.minus,
            tooltip: tile.isMinimized ? 'Restaurer' : 'Minimiser',
            accentColor: accentColor,
            onTap: () {
              context.read<NotilusMosaicService>().toggleMinimize(tile.id);
              HapticFeedback.selectionClick();
            },
          ),
          
          const SizedBox(width: 2),
          
          // Menu contenu
          _ContentMenuButton(tile: tile, accentColor: accentColor),
          
          const SizedBox(width: 2),
          
          // Fermer
          _ControlButton(
            icon: CupertinoIcons.xmark,
            tooltip: 'Fermer',
            accentColor: Colors.red,
            onTap: () {
              context.read<NotilusMosaicService>().closeTile(tile.id);
              HapticFeedback.mediumImpact();
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final VoidCallback onTap;
  final bool rotated;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    required this.onTap,
    this.rotated = false,
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
              child: Transform.rotate(
                angle: widget.rotated ? 1.5708 : 0, // 90 degrés
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
      ),
    );
  }
}

/// Menu de sélection de contenu
class _ContentMenuButton extends StatefulWidget {
  final MosaicTile tile;
  final Color accentColor;

  const _ContentMenuButton({required this.tile, required this.accentColor});

  @override
  State<_ContentMenuButton> createState() => _ContentMenuButtonState();
}

class _ContentMenuButtonState extends State<_ContentMenuButton> {
  bool _isHovered = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();
  DateTime? _menuOpenedAt;

  void _showMenu() {
    if (_overlayEntry != null) {
      // Si le menu est déjà ouvert, le fermer d'abord
      _hideMenu();
      return;
    }
    
    if (!context.mounted) return;
    
    _menuOpenedAt = DateTime.now();
    
    // Calculer la position du bouton
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fond transparent pour fermer (seulement en dehors du menu)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _hideMenu(force: true),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu positionné sous le bouton
          Positioned(
            left: offset.dx - 150, // Ajuster pour que le menu soit aligné à droite du bouton
            top: offset.dy + size.height + 4, // Juste en dessous du bouton
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              child: _ContentMenu(
                tile: widget.tile,
                accentColor: widget.accentColor,
                onClose: () => _hideMenu(force: true),
              ),
            ),
          ),
        ],
      ),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overlayEntry != null && context.mounted) {
        try {
          Overlay.of(context).insert(_overlayEntry!);
        } catch (e) {
          // Si l'insertion échoue, nettoyer
          _overlayEntry = null;
        }
      }
    });
  }

  void _hideMenu({bool force = false}) {
    if (_overlayEntry != null) {
      // Empêcher la fermeture trop rapide (sauf si forcée)
      if (!force && _menuOpenedAt != null) {
        final elapsed = DateTime.now().difference(_menuOpenedAt!);
        if (elapsed.inMilliseconds < 200) {
          // Attendre un peu avant de permettre la fermeture
          final remainingMs = 200 - elapsed.inMilliseconds;
          Future.delayed(Duration(milliseconds: remainingMs > 0 ? remainingMs : 0), () {
            if (_overlayEntry != null && mounted) {
              _hideMenu(force: true);
            }
          });
          return;
        }
      }
      
      final entry = _overlayEntry;
      _overlayEntry = null;
      _menuOpenedAt = null;
      try {
        entry!.remove();
      } catch (e) {
        // L'overlay a déjà été retiré ou n'est plus valide
        // Ignorer l'erreur
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _hideMenu(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Changer le contenu',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
          key: _buttonKey,
          onTap: () {
            if (_overlayEntry != null) {
              _hideMenu(force: true);
            } else {
              _showMenu();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _isHovered || _overlayEntry != null
                  ? widget.accentColor.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.ellipsis,
                size: 14,
                color: _isHovered || _overlayEntry != null
                    ? widget.accentColor
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void didUpdateWidget(_ContentMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le widget change, mettre à jour l'overlay si nécessaire
    if (_overlayEntry != null && !context.mounted) {
      _hideMenu(force: true);
    }
  }
}

class _ContentMenu extends StatelessWidget {
  final MosaicTile tile;
  final Color accentColor;
  final VoidCallback onClose;

  const _ContentMenu({
    required this.tile,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final types = MosaicTileType.values.where((t) => t != MosaicTileType.custom).toList();

    return Container(
      width: 200,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec bouton de fermeture
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Changer le contenu',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 4),
              // Types
              ...types.map((type) {
                final isSelected = tile.type == type;
                return _ContentMenuItem(
                  type: type,
                  isSelected: isSelected,
                  accentColor: accentColor,
                  onTap: () {
                    context.read<NotilusMosaicService>().setTileContent(tile.id, type);
                    onClose();
                    HapticFeedback.selectionClick();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentMenuItem extends StatefulWidget {
  final MosaicTileType type;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ContentMenuItem({
    required this.type,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ContentMenuItem> createState() => _ContentMenuItemState();
}

class _ContentMenuItemState extends State<_ContentMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _isHovered
              ? widget.accentColor.withOpacity(0.1)
              : (widget.isSelected ? widget.accentColor.withOpacity(0.05) : Colors.transparent),
          child: Row(
            children: [
              Icon(
                widget.type.icon,
                size: 16,
                color: widget.isSelected ? widget.accentColor : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.type.label,
                  style: TextStyle(
                    color: widget.isSelected ? widget.accentColor : Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 14,
                  color: widget.accentColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicateur visuel de zone de drop
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
              borderRadius: zone == DropZone.center ? BorderRadius.circular(8) : null,
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  _getZoneLabel(zone),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1.seconds, color: accentColor.withOpacity(0.3));
  }

  String _getZoneLabel(DropZone zone) {
    switch (zone) {
      case DropZone.left: return '← Gauche';
      case DropZone.right: return 'Droite →';
      case DropZone.top: return '↑ Haut';
      case DropZone.bottom: return 'Bas ↓';
      case DropZone.center: return 'Remplacer';
    }
  }
}

/// Label minimal de la tile
class _TileLabel extends StatelessWidget {
  final MosaicTile tile;
  final Color accentColor;

  const _TileLabel({required this.tile, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tile.type.icon,
            size: 10,
            color: accentColor.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            tile.type.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu minimisé
class _MinimizedContent extends StatelessWidget {
  final MosaicTile tile;
  final Color accentColor;

  const _MinimizedContent({required this.tile, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tile.type.icon,
              size: 24,
              color: accentColor.withOpacity(0.5),
            ),
            const SizedBox(height: 4),
            Text(
              tile.type.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Minimisé',
              style: TextStyle(
                color: accentColor.withOpacity(0.5),
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour accepter à la fois les MosaicDragData et les TabModel
class _DualDragTarget extends StatelessWidget {
  final MosaicTile tile;
  final NotilusMosaicService mosaicService;
  final DropZone? Function(Offset, Size) getDropZoneFromOffset;
  final Widget Function(BuildContext, List<dynamic>, List<dynamic>) builder;

  const _DualDragTarget({
    required this.tile,
    required this.mosaicService,
    required this.getDropZoneFromOffset,
    required this.builder,
  });

  void _handleDragMove(Offset offset, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(offset);
    final zone = getDropZoneFromOffset(localPos, box.size);
    mosaicService.setDragOver(tile.id, zone);
  }

  void _handleDragLeave() {
    mosaicService.setDragOver(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // DragTarget pour MosaicDragData (tiles internes)
        DragTarget<MosaicDragData>(
          onWillAcceptWithDetails: (details) => details.data.tile.id != tile.id,
          onMove: (details) => _handleDragMove(details.offset, context),
          onLeave: (_) => _handleDragLeave(),
          onAcceptWithDetails: (details) {
            final zone = mosaicService.dragOverZone ?? DropZone.center;
            mosaicService.moveTile(details.data.tile.id, tile.id, zone);
            mosaicService.setDragOver(null, null);
            HapticFeedback.mediumImpact();
          },
          builder: (context, mosaicData, rejectedMosaic) {
            // DragTarget pour TabModel (onglets depuis la barre)
            return DragTarget<TabModel>(
              onWillAcceptWithDetails: (details) => true,
              onMove: (details) => _handleDragMove(details.offset, context),
              onLeave: (_) => _handleDragLeave(),
              onAcceptWithDetails: (details) {
                final zone = mosaicService.dragOverZone ?? DropZone.center;
                final tabModel = details.data;
                
                if (zone == DropZone.center) {
                  // Remplacer le contenu de la tile
                  mosaicService.setTileTab(tile.id, tabModel.id);
                } else {
                  // Splitter la tile
                  final direction = (zone == DropZone.left || zone == DropZone.right)
                      ? SplitDirection.horizontal
                      : SplitDirection.vertical;
                  
                  // D'abord splitter
                  mosaicService.splitTile(tile.id, direction, newTileType: MosaicTileType.web);
                  
                  // Ensuite définir le contenu de la nouvelle tile
                  // Note: La nouvelle tile sera la dernière créée
                  final allTiles = mosaicService.getAllLeafTiles();
                  if (allTiles.isNotEmpty) {
                    final newTile = allTiles.last;
                    if (newTile.type == MosaicTileType.web && newTile.tabId == null) {
                      mosaicService.setTileTab(newTile.id, tabModel.id);
                    }
                  }
                }
                
                mosaicService.setDragOver(null, null);
                HapticFeedback.mediumImpact();
              },
              builder: (context, tabData, rejectedTab) {
                return builder(
                  context,
                  [...mosaicData, ...tabData],
                  [...rejectedMosaic, ...rejectedTab],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
