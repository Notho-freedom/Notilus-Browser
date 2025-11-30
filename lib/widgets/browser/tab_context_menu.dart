import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../models/tab_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/settings_service.dart';

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
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final primaryColor = themeManager.primaryColor;
    final secondaryColor = themeManager.nativeSecondaryColor;
    final settings = SettingsService();
    final contextMenuOpacity = settings.contextMenuOpacity;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(contextMenuOpacity),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secondaryColor.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: secondaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onReload != null)
              _buildMenuItem(
                context,
                secondaryColor,
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
                secondaryColor,
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
                secondaryColor,
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
                secondaryColor,
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
                secondaryColor,
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
                secondaryColor,
                icon: Icons.arrow_forward,
                label: 'Fermer à droite',
                onTap: () {
                  Navigator.of(context).pop();
                  onCloseToRight!();
                },
              ),
            _buildMenuItem(
              context,
              secondaryColor,
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
    Color secondaryColor, {
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
              color: isDanger ? NotilusColors.neonRed : secondaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDanger ? NotilusColors.neonRed : secondaryColor,
                fontSize: 14,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

