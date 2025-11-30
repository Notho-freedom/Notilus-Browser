import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import 'notilus_logo_image.dart';
import 'gx_futuristic_components.dart';
import 'gx_futuristic_dialog.dart';

/// Widget "À propos de Notilus" avec logo dans une carte futuriste GX
class NotilusAboutCard extends StatelessWidget {
  const NotilusAboutCard({super.key});

  /// Affiche la carte "À propos" dans un dialog futuriste
  static Future<void> show(BuildContext context) {
    return GxFuturisticDialog.show(
      context: context,
      title: 'À propos de Notilus',
      titleIcon: CupertinoIcons.info_circle,
      width: 600,
      height: 500,
      child: const NotilusAboutCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final gxRed = colorThemeManager.nativeSecondaryColor;

    return RepaintBoundary(
      key: const ValueKey('notilus_about_card'),
      child: GxFuturisticCard(
        accentColor: gxRed,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: const NotilusLogoImage(
            size: 300,
            showGlow: false,
          ),
        ),
      ),
    );
  }
}
