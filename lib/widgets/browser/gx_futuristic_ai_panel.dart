/// Panel AI futuriste Notilus GX
library gx_futuristic_ai_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

class GxFuturisticAiPanel extends StatefulWidget {
  const GxFuturisticAiPanel({super.key});

  @override
  State<GxFuturisticAiPanel> createState() => _GxFuturisticAiPanelState();
}

class _GxFuturisticAiPanelState extends State<GxFuturisticAiPanel> {
  final TextEditingController _promptController = TextEditingController();
  final SettingsService _settings = SettingsService();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    final wallpaperManager = context.watch<WallpaperManager>();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    color: accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HYPER ASSISTANT',
                    style: NotilusFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GxFuturisticBadge(
                    label: 'BETA',
                    color: accentColor,
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: ListenableBuilder(
                listenable: _settings,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    children: [
                      GxFuturisticCard(
                        accentColor: accentColor,
                        padding: const EdgeInsets.all(16),
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.lightbulb,
                                  color: accentColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assistant contextuel',
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Analyse la page et propose des actions rapides',
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GxFuturisticSwitch(
                                  value: _settings.aiContextualEnabled,
                                  accentColor: accentColor,
                                  onChanged: (v) => _settings.setAiContextualEnabled(v),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GxFuturisticCard(
                        accentColor: accentColor,
                        padding: const EdgeInsets.all(16),
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  color: accentColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Résumé instantané',
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Synthétise les articles longs en un clic',
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GxFuturisticSwitch(
                                  value: _settings.aiSummaryEnabled,
                                  accentColor: accentColor,
                                  onChanged: (v) => _settings.setAiSummaryEnabled(v),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GxFuturisticCard(
                        accentColor: accentColor,
                        padding: const EdgeInsets.all(16),
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.shield,
                                  color: accentColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Protection intelligente',
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bloque les scripts suspects en arrière plan',
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GxFuturisticSwitch(
                                  value: _settings.aiProtectionEnabled,
                                  accentColor: accentColor,
                                  onChanged: (v) => _settings.setAiProtectionEnabled(v),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Zone de prompt
                      GxFuturisticCard(
                        accentColor: accentColor,
                        padding: const EdgeInsets.all(20),
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.text_cursor,
                                  color: accentColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'HYPER PROMPT',
                                  style: NotilusFonts.orbitron(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GxFuturisticTextArea(
                              controller: _promptController,
                              hint: 'Décrivez ce que vous voulez faire...',
                              minLines: 3,
                              maxLines: 5,
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Ex: "Résume cette page", "Trouve des alternatives"',
                                    style: NotilusFonts.rajdhani(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GxFuturisticButton(
                                  label: 'Envoyer',
                                  icon: CupertinoIcons.paperplane_fill,
                                  variant: GxFuturisticButtonVariant.primary,
                                  accentColor: accentColor,
                                  onPressed: () {
                                    if (_promptController.text.isNotEmpty) {
                                      GxNotificationService().showInfo(
                                        title: 'Fonctionnalité AI',
                                        message: 'En développement - Bientôt disponible',
                                        context: context,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

