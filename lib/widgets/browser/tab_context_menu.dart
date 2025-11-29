import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/glassmorphic_container.dart';

class TabContextMenu extends StatelessWidget {
  final TabModel tab;
  final VoidCallback onClose;
  final VoidCallback? onReload;
  final VoidCallback? onDuplicate;
  final VoidCallback? onPin;
  final VoidCallback? onAddToGroup;
  final VoidCallback? onCloseOthers;
  final VoidCallback? onCloseToRight;
  final Offset position;

  const TabContextMenu({
    super.key,
    required this.tab,
    required this.onClose,
    this.onReload,
    this.onDuplicate,
    this.onPin,
    this.onAddToGroup,
    this.onCloseOthers,
    this.onCloseToRight,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GlassmorphicContainer(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 4),
        showNeonBorder: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onReload != null)
              _buildMenuItem(
                context,
                theme,
                icon: Icons.refresh,
                label: 'Recharger',
                onTap: () {
                  Navigator.of(context).pop();
                  onReload!();
                },
              ),
            if (onDuplicate != null)
              _buildMenuItem(
                context,
                theme,
                icon: Icons.copy,
                label: 'Dupliquer',
                onTap: () {
                  Navigator.of(context).pop();
                  onDuplicate!();
                },
              ),
            if (onPin != null)
              _buildMenuItem(
                context,
                theme,
                icon: tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: tab.isPinned ? 'Désépingler' : 'Épingler',
                onTap: () {
                  Navigator.of(context).pop();
                  onPin!();
                },
              ),
            const Divider(height: 1),
            if (onAddToGroup != null)
              _buildMenuItem(
                context,
                theme,
                icon: Icons.folder,
                label: 'Ajouter à un groupe',
                onTap: () {
                  Navigator.of(context).pop();
                  onAddToGroup!();
                },
              ),
            const Divider(height: 1),
            if (onCloseOthers != null)
              _buildMenuItem(
                context,
                theme,
                icon: Icons.close,
                label: 'Fermer les autres',
                onTap: () {
                  Navigator.of(context).pop();
                  onCloseOthers!();
                },
              ),
            if (onCloseToRight != null)
              _buildMenuItem(
                context,
                theme,
                icon: Icons.arrow_forward,
                label: 'Fermer à droite',
                onTap: () {
                  Navigator.of(context).pop();
                  onCloseToRight!();
                },
              ),
            _buildMenuItem(
              context,
              theme,
              icon: Icons.close,
              label: 'Fermer',
              onTap: () {
                Navigator.of(context).pop();
                onClose();
              },
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    AppTheme theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDanger ? theme.error : theme.text,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDanger ? theme.error : theme.text,
                fontSize: 14,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppTheme _getThemeFromContext() {
    return const AppTheme(
      name: 'Default',
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF1A1A1A),
      primary: Color(0xFFFF0040),
      secondary: Color(0xFFFF3366),
      accent: Color(0xFF00FF88),
      text: Color(0xFFE0E0E0),
      textSecondary: Color(0xFF888888),
      error: Color(0xFFFF0040),
      success: Color(0xFF00FF88),
      warning: Color(0xFFFFAA00),
      border: Color(0xFF333333),
      hover: Color(0xFF2A2A2A),
      selected: Color(0xFFFF0040),
    );
  }
}

