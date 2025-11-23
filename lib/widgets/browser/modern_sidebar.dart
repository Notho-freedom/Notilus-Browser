import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';

/// Sections disponibles dans la barre latérale
enum SidebarSection {
  home,
  favorites,
  history,
  downloads,
  settings,
}

class ModernSidebar extends StatefulWidget {
  final VoidCallback? onClose;
  final ValueChanged<SidebarSection>? onSectionSelected;
  
  const ModernSidebar({
    super.key,
    this.onClose,
    this.onSectionSelected,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  int _selectedIndex = 0;

  final List<SidebarItem> _items = [
    SidebarItem(
      icon: CupertinoIcons.home,
      label: 'Accueil',
      color: const Color(0xFF007AFF),
    ),
    SidebarItem(
      icon: CupertinoIcons.bookmark,
      label: 'Favoris',
      color: const Color(0xFFFF9500),
    ),
    SidebarItem(
      icon: CupertinoIcons.clock,
      label: 'Historique',
      color: const Color(0xFF5856D6),
    ),
    SidebarItem(
      icon: CupertinoIcons.download_circle,
      label: 'Téléchargements',
      color: const Color(0xFF34C759),
    ),
    SidebarItem(
      icon: CupertinoIcons.gear,
      label: 'Paramètres',
      color: const Color(0xFF8E8E93),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0E),
        border: Border(
          right: BorderSide(
            color: const Color(0xFFFF2D55).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Logo GX Corner avec bordure néon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF2D55),
                  Color(0xFF5856D6),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2D55).withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'GX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Icônes principales
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = _selectedIndex == index;
                
                return _SidebarIconButton(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });

                      if (widget.onSectionSelected != null &&
                          index >= 0 &&
                          index < SidebarSection.values.length) {
                        widget.onSectionSelected!(SidebarSection.values[index]);
                      }

                      if (index == 0) {
                        final tabManager =
                            Provider.of<TabManager>(context, listen: false);
                        tabManager.addTab(url: 'about:newtab');
                      }
                    },
                  );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.selected || _hovered
        ? widget.color.withOpacity(0.18)
        : Colors.transparent;

    final borderColor = widget.selected
        ? widget.color
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.label,
          child: Stack(
            children: [
              // Barre de sélection verticale à gauche
              if (widget.selected)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2D55).withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? Colors.white.withOpacity(0.05)
                      : (_hovered ? Colors.white.withOpacity(0.03) : Colors.transparent),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.selected
                        ? const Color(0xFFFF2D55)
                        : (_hovered
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.5)),
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

class SidebarItem {
  final IconData icon;
  final String label;
  final Color color;

  SidebarItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
