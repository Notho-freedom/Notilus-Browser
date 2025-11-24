import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../services/tab_manager.dart';
import '../common/notilus_monogram.dart';
import '../common/notilus_tooltip.dart';

const Color _gxRed = NotilusColors.neonRed;

enum SidebarSection {
  home,
  favorites,
  history,
  downloads,
  widgets,
  ai,
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
  int _selectedIndex = 0;
  int _hoveredIndex = -1;
  final List<_SidebarDestination> _destinations = const [
    _SidebarDestination(
      section: SidebarSection.home,
      icon: CupertinoIcons.square_grid_2x2,
      label: 'Accueil',
    ),
    _SidebarDestination(
      section: SidebarSection.favorites,
      icon: CupertinoIcons.bookmark,
      label: 'Favoris',
    ),
    _SidebarDestination(
      section: SidebarSection.history,
      icon: CupertinoIcons.time,
      label: 'Historique',
    ),
    _SidebarDestination(
      section: SidebarSection.downloads,
      icon: CupertinoIcons.arrow_down_to_line,
      label: 'Téléchargements',
    ),
    _SidebarDestination(
      section: SidebarSection.widgets,
      icon: CupertinoIcons.layers_alt,
      label: 'Widgets dynamiques',
    ),
    _SidebarDestination(
      section: SidebarSection.ai,
      icon: CupertinoIcons.sparkles,
      label: 'Hyper Assistant',
    ),
    _SidebarDestination(
      section: SidebarSection.settings,
      icon: CupertinoIcons.gear_alt,
      label: 'Paramètres',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NotilusColors.chromeDark,
            NotilusColors.chrome,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const NotilusMonogram(
            size: 30,
            showGlow: false,
            showFrame: true,
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < _destinations.length; i++) ...[
            NotilusTooltip(
              message: _destinations[i].label,
              child: _GXSidebarIcon(
                icon: _destinations[i].icon,
                isSelected: _selectedIndex == i,
                isHovered: _hoveredIndex == i,
                onTap: () {
                  setState(() {
                    _selectedIndex = i;
                  });
                  if (_destinations[i].section == SidebarSection.home) {
                    Provider.of<TabManager>(context, listen: false)
                        .addTab(url: 'about:newtab');
                  }
                  widget.onSectionSelected?.call(_destinations[i].section);
                },
                onHover: (hover) => setState(() => _hoveredIndex = hover ? i : -1),
              ),
            ),
            const SizedBox(height: 4),
          ],
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

class _SidebarDestination {
  final SidebarSection section;
  final IconData icon;
  final String label;

  const _SidebarDestination({
    required this.section,
    required this.icon,
    required this.label,
  });
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
