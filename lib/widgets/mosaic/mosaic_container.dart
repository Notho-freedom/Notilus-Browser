/// Notilus Mosaic Container - Conteneur principal de la mosaïque
/// Gère le rendu récursif des tiles et les interactions drag/drop
library mosaic_container;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/mosaic_models.dart';
import '../../services/mosaic_service.dart';
import '../../core/services/color_theme_manager.dart';
import 'mosaic_tile_widget.dart';

/// Widget principal de la mosaïque
class MosaicContainer extends StatefulWidget {
  const MosaicContainer({super.key});

  @override
  State<MosaicContainer> createState() => _MosaicContainerState();
}

class _MosaicContainerState extends State<MosaicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotilusMosaicService>(
      builder: (context, mosaicService, _) {
        if (!mosaicService.isMosaicActive) {
          return const SizedBox.shrink();
        }

        final rootTile = mosaicService.rootTile;
        if (rootTile == null) {
          return const _MosaicEmptyState();
        }

        return Container(
          color: const Color(0xFF0B0B0E),
          child: Column(
            children: [
              // Toolbar inline (remplace MosaicToolbar)
              _buildMosaicToolbar(context, mosaicService),
              
              // Contenu mosaïque
              Expanded(
                child: _buildTileTree(context, rootTile, mosaicService)
                    .animate(controller: _animationController)
                    .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construire l'arbre de tiles récursivement
  Widget _buildTileTree(
    BuildContext context,
    MosaicTile tile,
    NotilusMosaicService service,
  ) {
    // Si c'est une feuille
    if (tile.isLeaf) {
      return MosaicTileWidget(tile: tile);
    }

    // Si c'est un conteneur avec des enfants
    final children = tile.children!;
    final direction = tile.splitDirection ?? SplitDirection.horizontal;

    if (direction == SplitDirection.horizontal) {
      return _buildHorizontalSplit(context, tile, children, service);
    } else {
      return _buildVerticalSplit(context, tile, children, service);
    }
  }

  Widget _buildHorizontalSplit(
    BuildContext context,
    MosaicTile parent,
    List<MosaicTile> children,
    NotilusMosaicService service,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    final widgets = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      
      widgets.add(
        Expanded(
          flex: (child.flexFactor * 1000).round(),
          child: _buildTileTree(context, child, service),
        ),
      );

      // Ajouter un resizer entre les tiles
      if (i < children.length - 1) {
        widgets.add(
          _MosaicResizer(
            direction: SplitDirection.horizontal,
            isActive: false,
            accentColor: accentColor,
            onDragUpdate: (delta) {
              final normalizedDelta = delta / screenWidth;
              service.resizeTiles(parent.id, i, normalizedDelta);
            },
          ),
        );
      }
    }

    return Row(children: widgets);
  }

  Widget _buildVerticalSplit(
    BuildContext context,
    MosaicTile parent,
    List<MosaicTile> children,
    NotilusMosaicService service,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    final widgets = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      
      widgets.add(
        Expanded(
          flex: (child.flexFactor * 1000).round(),
          child: _buildTileTree(context, child, service),
        ),
      );

      // Ajouter un resizer entre les tiles
      if (i < children.length - 1) {
        widgets.add(
          _MosaicResizer(
            direction: SplitDirection.vertical,
            isActive: false,
            accentColor: accentColor,
            onDragUpdate: (delta) {
              final normalizedDelta = delta / screenHeight;
              service.resizeTiles(parent.id, i, normalizedDelta);
            },
          ),
        );
      }
    }

    return Column(children: widgets);
  }

  /// Toolbar inline pour la mosaïque
  Widget _buildMosaicToolbar(BuildContext context, NotilusMosaicService service) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Titre
          const Text(
            'Mosaic',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Actions
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, size: 16),
            onPressed: () => service.deactivate(),
            tooltip: 'Fermer la mosaïque',
            iconSize: 16,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }
}

/// Widget de redimensionnement entre tiles
class _MosaicResizer extends StatefulWidget {
  final SplitDirection direction;
  final bool isActive;
  final Color accentColor;
  final ValueChanged<double> onDragUpdate;

  const _MosaicResizer({
    required this.direction,
    required this.isActive,
    required this.accentColor,
    required this.onDragUpdate,
  });

  @override
  State<_MosaicResizer> createState() => _MosaicResizerState();
}

class _MosaicResizerState extends State<_MosaicResizer> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.direction == SplitDirection.horizontal;
    final isActive = _isHovered || _isDragging;

    return MouseRegion(
      cursor: isHorizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
          HapticFeedback.selectionClick();
        },
        onPanUpdate: (details) {
          widget.onDragUpdate(
            isHorizontal ? details.delta.dx : details.delta.dy,
          );
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isHorizontal ? 6 : null,
          height: isHorizontal ? null : 6,
          decoration: BoxDecoration(
            color: isActive
                ? widget.accentColor.withOpacity(0.3)
                : Colors.transparent,
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isHorizontal ? 2 : 40,
              height: isHorizontal ? 40 : 2,
              decoration: BoxDecoration(
                color: isActive
                    ? widget.accentColor
                    : widget.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(1),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// État vide de la mosaïque
class _MosaicEmptyState extends StatelessWidget {
  const _MosaicEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      color: const Color(0xFF0B0B0E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.square_grid_2x2,
                size: 64,
                color: accentColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mosaïque Notilus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez un layout ou glissez des éléments',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: MosaicLayoutPreset.presets.take(6).map((preset) {
                return _PresetButton(preset: preset);
              }).toList(),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

class _PresetButton extends StatefulWidget {
  final MosaicLayoutPreset preset;

  const _PresetButton({required this.preset});

  @override
  State<_PresetButton> createState() => _PresetButtonState();
}

class _PresetButtonState extends State<_PresetButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final service = context.read<NotilusMosaicService>();
          service.applyPreset(widget.preset);
          HapticFeedback.mediumImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? accentColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.preset.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: _isHovered ? accentColor : Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.preset.name,
                style: TextStyle(
                  color: _isHovered ? accentColor : Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
