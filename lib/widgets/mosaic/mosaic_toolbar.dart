/// Notilus Mosaic Toolbar - Barre d'outils de la mosaïque
/// Permet de gérer les layouts, workspaces et options
library mosaic_toolbar;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/mosaic_models.dart';
import '../../services/mosaic_service.dart';
import '../../core/services/color_theme_manager.dart';

class MosaicToolbar extends StatefulWidget {
  const MosaicToolbar({super.key});

  @override
  State<MosaicToolbar> createState() => _MosaicToolbarState();
}

class _MosaicToolbarState extends State<MosaicToolbar> {
  bool _showLayoutMenu = false;
  bool _showWorkspaceMenu = false;
  bool _showAddMenu = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorTheme.nativeBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo Mosaïque
          _MosaicLogo(accentColor: accentColor),
          
          const SizedBox(width: 12),
          
          Container(width: 1, height: 24, color: accentColor.withOpacity(0.2)),
          
          const SizedBox(width: 12),

          // Menu layouts
          _ToolbarDropdown(
            icon: CupertinoIcons.square_grid_2x2,
            label: 'Layouts',
            isOpen: _showLayoutMenu,
            accentColor: accentColor,
            onTap: () => setState(() {
              _showLayoutMenu = !_showLayoutMenu;
              _showWorkspaceMenu = false;
              _showAddMenu = false;
            }),
            menuBuilder: _buildLayoutMenu,
          ),

          const SizedBox(width: 8),

          // Menu workspaces
          Consumer<NotilusMosaicService>(
            builder: (context, service, _) {
              return _ToolbarDropdown(
                icon: CupertinoIcons.layers,
                label: service.activeWorkspace?.name ?? 'Workspace',
                isOpen: _showWorkspaceMenu,
                accentColor: accentColor,
                onTap: () => setState(() {
                  _showWorkspaceMenu = !_showWorkspaceMenu;
                  _showLayoutMenu = false;
                  _showAddMenu = false;
                }),
                menuBuilder: _buildWorkspaceMenu,
              );
            },
          ),

          const SizedBox(width: 8),

          // Bouton ajouter tile
          _ToolbarDropdown(
            icon: CupertinoIcons.plus_square,
            label: 'Ajouter',
            isOpen: _showAddMenu,
            accentColor: accentColor,
            onTap: () => setState(() {
              _showAddMenu = !_showAddMenu;
              _showLayoutMenu = false;
              _showWorkspaceMenu = false;
            }),
            menuBuilder: _buildAddMenu,
          ),

          const Spacer(),

          // Stats tiles
          Consumer<NotilusMosaicService>(
            builder: (context, service, _) {
              final count = service.countActiveTiles();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.square_grid_2x2_fill,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count panneau${count > 1 ? 'x' : ''}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // Boutons d'action
          _ToolbarIconButton(
            icon: CupertinoIcons.eye_slash,
            tooltip: 'Masquer la mosaïque',
            accentColor: accentColor,
            onTap: () {
              context.read<NotilusMosaicService>().setVisible(false);
              HapticFeedback.lightImpact();
            },
          ),

          const SizedBox(width: 4),

          _ToolbarIconButton(
            icon: CupertinoIcons.xmark,
            tooltip: 'Fermer la mosaïque',
            accentColor: accentColor,
            onTap: () {
              context.read<NotilusMosaicService>().deactivate();
              HapticFeedback.mediumImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutMenu(BuildContext context, Color accentColor) {
    return _DropdownMenu(
      width: 220,
      accentColor: accentColor,
      onClose: () => setState(() => _showLayoutMenu = false),
      children: MosaicLayoutPreset.presets.map((preset) {
        return _DropdownMenuItem(
          icon: Text(preset.icon, style: const TextStyle(fontSize: 18)),
          label: preset.name,
          subtitle: preset.description,
          accentColor: accentColor,
          onTap: () {
            context.read<NotilusMosaicService>().applyPreset(preset);
            setState(() => _showLayoutMenu = false);
            HapticFeedback.selectionClick();
          },
        );
      }).toList(),
    );
  }

  Widget _buildWorkspaceMenu(BuildContext context, Color accentColor) {
    return Consumer<NotilusMosaicService>(
      builder: (context, service, _) {
        return _DropdownMenu(
          width: 240,
          accentColor: accentColor,
          onClose: () => setState(() => _showWorkspaceMenu = false),
          children: [
            ...service.workspaces.map((workspace) {
              final isActive = workspace.id == service.activeWorkspace?.id;
              return _DropdownMenuItem(
                icon: Icon(
                  isActive ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  size: 16,
                  color: isActive ? accentColor : Colors.white.withOpacity(0.5),
                ),
                label: workspace.name,
                subtitle: workspace.isDefault ? 'Workspace par défaut' : null,
                accentColor: accentColor,
                isSelected: isActive,
                onTap: () {
                  service.setActiveWorkspace(workspace.id);
                  setState(() => _showWorkspaceMenu = false);
                  HapticFeedback.selectionClick();
                },
                trailing: !workspace.isDefault
                    ? GestureDetector(
                        onTap: () {
                          service.deleteWorkspace(workspace.id);
                          HapticFeedback.mediumImpact();
                        },
                        child: Icon(
                          CupertinoIcons.trash,
                          size: 14,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      )
                    : null,
              );
            }),
            const Divider(height: 1, color: Colors.white12),
            _DropdownMenuItem(
              icon: Icon(
                CupertinoIcons.plus,
                size: 16,
                color: accentColor,
              ),
              label: 'Nouveau workspace',
              accentColor: accentColor,
              onTap: () {
                _showNewWorkspaceDialog(context, accentColor);
                setState(() => _showWorkspaceMenu = false);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddMenu(BuildContext context, Color accentColor) {
    final tileTypes = [
      MosaicTileType.web,
      MosaicTileType.terminal,
      MosaicTileType.devtools,
      MosaicTileType.widgets,
      MosaicTileType.bookmarks,
      MosaicTileType.history,
      MosaicTileType.downloads,
      MosaicTileType.ai,
      MosaicTileType.documentation,
    ];

    return _DropdownMenu(
      width: 200,
      accentColor: accentColor,
      onClose: () => setState(() => _showAddMenu = false),
      children: tileTypes.map((type) {
        return _DropdownMenuItem(
          icon: Icon(type.icon, size: 16, color: accentColor.withOpacity(0.8)),
          label: type.label,
          accentColor: accentColor,
          onTap: () {
            // Ajouter une nouvelle tile du type sélectionné
            final service = context.read<NotilusMosaicService>();
            final focusedTileId = service.focusedTileId;
            
            if (focusedTileId != null) {
              // Splitter la tile focusée
              service.splitTile(focusedTileId, SplitDirection.horizontal, newTileType: type);
            } else if (service.rootTile?.type == MosaicTileType.empty) {
              // Si root est vide, définir son contenu
              service.setTileContent(service.rootTile!.id, type);
            } else {
              // Sinon, splitter la root
              service.splitTile(service.rootTile!.id, SplitDirection.horizontal, newTileType: type);
            }
            
            setState(() => _showAddMenu = false);
            HapticFeedback.mediumImpact();
          },
        );
      }).toList(),
    );
  }

  void _showNewWorkspaceDialog(BuildContext context, Color accentColor) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15151A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withOpacity(0.5)),
        ),
        title: Text(
          'Nouveau Workspace',
          style: TextStyle(color: accentColor, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom du workspace',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<NotilusMosaicService>().createWorkspace(controller.text);
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _MosaicLogo extends StatelessWidget {
  final Color accentColor;

  const _MosaicLogo({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor, accentColor.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              CupertinoIcons.square_grid_2x2_fill,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOSAIC',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'WORKSPACE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 8,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolbarDropdown extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isOpen;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget Function(BuildContext, Color) menuBuilder;

  const _ToolbarDropdown({
    required this.icon,
    required this.label,
    required this.isOpen,
    required this.accentColor,
    required this.onTap,
    required this.menuBuilder,
  });

  @override
  State<_ToolbarDropdown> createState() => _ToolbarDropdownState();
}

class _ToolbarDropdownState extends State<_ToolbarDropdown> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isOpen || _isHovered;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? widget.accentColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? widget.accentColor.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: isActive
                        ? widget.accentColor
                        : Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: isActive
                          ? widget.accentColor
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.isOpen
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 12,
                    color: isActive
                        ? widget.accentColor
                        : Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isOpen)
          Positioned(
            top: 40,
            left: 0,
            child: widget.menuBuilder(context, widget.accentColor)
                .animate()
                .fadeIn(duration: 150.ms)
                .slideY(begin: -0.1, end: 0, duration: 150.ms, curve: Curves.easeOutCubic),
          ),
      ],
    );
  }
}

class _DropdownMenu extends StatelessWidget {
  final double width;
  final Color accentColor;
  final VoidCallback onClose;
  final List<Widget> children;

  const _DropdownMenu({
    required this.width,
    required this.accentColor,
    required this.onClose,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuItem extends StatefulWidget {
  final Widget icon;
  final String label;
  final String? subtitle;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DropdownMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.accentColor,
    this.isSelected = false,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_DropdownMenuItem> createState() => _DropdownMenuItemState();
}

class _DropdownMenuItemState extends State<_DropdownMenuItem> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: _isHovered
              ? widget.accentColor.withOpacity(0.1)
              : (widget.isSelected
                  ? widget.accentColor.withOpacity(0.05)
                  : Colors.transparent),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: widget.icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isSelected
                            ? widget.accentColor
                            : Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ToolbarIconButton> createState() => _ToolbarIconButtonState();
}

class _ToolbarIconButtonState extends State<_ToolbarIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isPressed
                  ? widget.accentColor.withOpacity(0.25)
                  : (_isHovered
                      ? widget.accentColor.withOpacity(0.15)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: _isHovered
                  ? Border.all(
                      color: widget.accentColor.withOpacity(0.4),
                      width: 1,
                    )
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _isHovered
                  ? widget.accentColor
                  : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
