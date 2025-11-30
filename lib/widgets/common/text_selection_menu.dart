import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/text_selection_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';

/// Menu flottant pour les sélections de texte
class TextSelectionMenu extends StatelessWidget {
  const TextSelectionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TextSelectionService>(
      builder: (context, selectionService, _) {
        if (!selectionService.isVisible || selectionService.selectionPosition == null) {
          return const SizedBox.shrink();
        }

        final position = selectionService.selectionPosition!;
        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
        final accentColor = colorThemeManager.nativeSecondaryColor;
        final bgColor = colorThemeManager.nativeBackgroundColor;

        // S'assurer que la position est dans les limites de l'écran
        final screenSize = MediaQuery.of(context).size;
        final menuWidth = 120.0;
        final menuHeight = 40.0;
        
        // Les coordonnées du WebView sont relatives à la page web, pas à l'écran
        // Pour l'instant, on les utilise telles quelles mais on les limite à l'écran visible
        // TODO: Obtenir la position réelle du WebView pour convertir correctement
        final adjustedX = position.dx.clamp(0.0, screenSize.width - menuWidth);
        // Limiter la position Y pour qu'elle soit visible (les coordonnées du WebView peuvent être très grandes avec le scroll)
        final adjustedY = (position.dy > screenSize.height ? screenSize.height - menuHeight - 20 : position.dy - 50).clamp(0.0, screenSize.height - menuHeight);
        
        return Positioned(
          left: adjustedX,
          top: adjustedY,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuButton(
                    icon: CupertinoIcons.doc_on_doc,
                    tooltip: 'Copier',
                    onTap: () => selectionService.copyText(),
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 4),
                  _MenuButton(
                    icon: CupertinoIcons.search,
                    tooltip: 'Rechercher',
                    onTap: () => selectionService.searchText(),
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 4),
                  _MenuButton(
                    icon: CupertinoIcons.xmark,
                    tooltip: 'Fermer',
                    onTap: () => selectionService.hideMenu(),
                    accentColor: accentColor,
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

class _MenuButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color accentColor;

  const _MenuButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.accentColor,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered
                ? widget.accentColor
                : widget.accentColor.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}

