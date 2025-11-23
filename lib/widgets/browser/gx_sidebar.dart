import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';

const Color _gxRed = Color(0xFFFF2D55);

enum SidebarSection {
  home,
  favorites,
  history,
  downloads,
  settings,
}

class GXSidebar extends StatefulWidget {
  final VoidCallback? onClose;
  final ValueChanged<SidebarSection>? onSectionSelected;
  
  const GXSidebar({
    super.key,
    this.onClose,
    this.onSectionSelected,
  });

  @override
  State<GXSidebar> createState() => _GXSidebarState();
}

class _GXSidebarState extends State<GXSidebar> {
  int _selectedIndex = -1; // -1 = aucune sélection par défaut
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      decoration: const BoxDecoration(
        // Fond noir mat avec très léger gradient
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF16161A),
            Color(0xFF0D0D10),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const _NotilusGlyph(),
          const SizedBox(height: 18),
          // Icône Home/Speed Dial
          _GXSidebarIcon(
            icon: CupertinoIcons.square_grid_2x2,
            isSelected: _selectedIndex == 0,
            isHovered: _hoveredIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              widget.onSectionSelected?.call(SidebarSection.home);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 0 : -1),
          ),
          const SizedBox(height: 4),
          // Icône Favoris
          _GXSidebarIcon(
            icon: CupertinoIcons.bookmark,
            isSelected: _selectedIndex == 1,
            isHovered: _hoveredIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              widget.onSectionSelected?.call(SidebarSection.favorites);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 1 : -1),
          ),
          const SizedBox(height: 4),
          // Icône Historique
          _GXSidebarIcon(
            icon: CupertinoIcons.time,
            isSelected: _selectedIndex == 2,
            isHovered: _hoveredIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              widget.onSectionSelected?.call(SidebarSection.history);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 2 : -1),
          ),
          const SizedBox(height: 4),
          // Icône Téléchargements
          _GXSidebarIcon(
            icon: CupertinoIcons.arrow_down_to_line,
            isSelected: _selectedIndex == 3,
            isHovered: _hoveredIndex == 3,
            onTap: () {
              setState(() => _selectedIndex = 3);
              widget.onSectionSelected?.call(SidebarSection.downloads);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 3 : -1),
          ),
          const SizedBox(height: 4),
          // Icône Paramètres
          _GXSidebarIcon(
            icon: CupertinoIcons.gear_alt,
            isSelected: _selectedIndex == 4,
            isHovered: _hoveredIndex == 4,
            onTap: () {
              setState(() => _selectedIndex = 4);
              widget.onSectionSelected?.call(SidebarSection.settings);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 4 : -1),
          ),
          const SizedBox(height: 20),
          const _SidebarSignature(),
          const Spacer(),
          const _SidebarVerticalLabel(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _GXSidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _GXSidebarIcon({
    required this.icon,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 40,
          child: Stack(
            children: [
              // Barre de sélection à gauche - exactement comme GX
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: _gxRed,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gxRed.withOpacity(0.8),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Fond au hover/sélection
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _gxRed.withOpacity(0.18)
                        : (isHovered
                            ? _gxRed.withOpacity(0.08)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: _gxRed.withOpacity(isSelected
                        ? 1
                        : (isHovered ? 0.9 : 0.65)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotilusGlyph extends StatelessWidget {
  const _NotilusGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gxRed, width: 1.4),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F1F2A),
            Color(0xFF0D0D12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _gxRed.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -math.pi / 7,
            child: Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: _gxRed,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 7,
            child: Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSignature extends StatelessWidget {
  const _SidebarSignature();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gxRed.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _gxRed,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: _gxRed.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NX',
            style: TextStyle(
              color: _gxRed.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'CORE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarVerticalLabel extends StatelessWidget {
  const _SidebarVerticalLabel();

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: Text(
        'NOTILUS BETA',
        style: TextStyle(
          color: _gxRed.withOpacity(0.7),
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
