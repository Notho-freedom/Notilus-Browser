import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';

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
          const SizedBox(height: 12),
          
          // Icône Home/Speed Dial
          _GXSidebarIcon(
            icon: Icons.grid_view_rounded,
            isSelected: _selectedIndex == 0,
            isHovered: _hoveredIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              widget.onSectionSelected?.call(SidebarSection.home);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 0 : -1),
          ),
          
          const SizedBox(height: 2),
          
          // Icône Favoris
          _GXSidebarIcon(
            icon: Icons.bookmark_outline_rounded,
            isSelected: _selectedIndex == 1,
            isHovered: _hoveredIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              widget.onSectionSelected?.call(SidebarSection.favorites);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 1 : -1),
          ),
          
          const SizedBox(height: 2),
          
          // Icône Historique
          _GXSidebarIcon(
            icon: Icons.history_rounded,
            isSelected: _selectedIndex == 2,
            isHovered: _hoveredIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              widget.onSectionSelected?.call(SidebarSection.history);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 2 : -1),
          ),
          
          const SizedBox(height: 2),
          
          // Icône Téléchargements
          _GXSidebarIcon(
            icon: Icons.download_outlined,
            isSelected: _selectedIndex == 3,
            isHovered: _hoveredIndex == 3,
            onTap: () {
              setState(() => _selectedIndex = 3);
              widget.onSectionSelected?.call(SidebarSection.downloads);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 3 : -1),
          ),
          
          const Spacer(),
          
          // Section du bas - Paramètres
          _GXSidebarIcon(
            icon: Icons.settings_outlined,
            isSelected: _selectedIndex == 4,
            isHovered: _hoveredIndex == 4,
            onTap: () {
              setState(() => _selectedIndex = 4);
              widget.onSectionSelected?.call(SidebarSection.settings);
            },
            onHover: (hover) => setState(() => _hoveredIndex = hover ? 4 : -1),
          ),
          
          const SizedBox(height: 8),
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
                      color: const Color(0xFFFA2F55),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFA2F55).withOpacity(0.8),
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
                        ? Colors.white.withOpacity(0.08)
                        : (isHovered 
                            ? Colors.white.withOpacity(0.04) 
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? const Color(0xFFFA2F55)
                        : (isHovered
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.4)),
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
