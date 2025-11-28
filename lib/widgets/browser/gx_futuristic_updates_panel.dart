/// Panel de mises à jour futuriste Notilus GX
library gx_futuristic_updates_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/update_service.dart';
import '../../services/settings_service.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

class GxFuturisticUpdatesPanel extends StatefulWidget {
  const GxFuturisticUpdatesPanel({super.key});

  @override
  State<GxFuturisticUpdatesPanel> createState() => _GxFuturisticUpdatesPanelState();
}

class _GxFuturisticUpdatesPanelState extends State<GxFuturisticUpdatesPanel> {
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_updateService.recentUpdates.isEmpty) {
        _updateService.checkForUpdates();
      }
    });
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
                    CupertinoIcons.arrow_up_circle,
                    color: accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MISES À JOUR',
                    style: NotilusFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GxFuturisticBadge(
                    label: 'v${_updateService.version}',
                    color: accentColor,
                  ),
                ],
              ),
            ),
            
            // Bouton vérifier
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListenableBuilder(
                listenable: _updateService,
                builder: (context, _) {
                  return GxFuturisticButton(
                    label: _updateService.isChecking 
                        ? 'Vérification en cours...' 
                        : 'Vérifier les mises à jour',
                    icon: _updateService.isChecking 
                        ? null 
                        : CupertinoIcons.arrow_clockwise,
                    variant: GxFuturisticButtonVariant.primary,
                    accentColor: accentColor,
                    isLoading: _updateService.isChecking,
                    onPressed: _updateService.isChecking 
                        ? null 
                        : () {
                            _updateService.checkForUpdates();
                            GxNotificationService().showInfo(
                              title: 'Vérification',
                              message: 'Recherche de mises à jour en cours...',
                              context: context,
                            );
                          },
                  );
                },
              ),
            ),
            
            if (_updateService.lastCheck != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Dernière vérification: ${_updateService.formatRelativeDate(_updateService.lastCheck!)}',
                  style: NotilusFonts.rajdhani(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GxFuturisticLabel(
                text: 'CHANGEMENTS RÉCENTS',
                icon: CupertinoIcons.doc_text,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Liste des mises à jour
            Expanded(
              child: ListenableBuilder(
                listenable: _updateService,
                builder: (context, _) {
                  final updates = _updateService.recentUpdates;
                  
                  if (updates.isEmpty && !_updateService.isChecking) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: const Color(0xFF22C55E),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Vous êtes à jour!',
                            style: NotilusFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notilus v${_updateService.version}',
                            style: NotilusFonts.rajdhani(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: updates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final update = updates[index];
                      return RepaintBoundary(
                        child: _UpdateCard(
                          title: update.title,
                          description: update.description,
                          date: _updateService.formatRelativeDate(update.date),
                          isNew: update.isNew,
                          category: update.category,
                          accentColor: accentColor,
                        ),
                      );
                    },
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

class _UpdateCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final bool isNew;
  final UpdateCategory category;
  final Color accentColor;

  const _UpdateCard({
    required this.title,
    required this.description,
    required this.date,
    required this.isNew,
    required this.category,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GxFuturisticCard(
      accentColor: isNew ? accentColor : Colors.white.withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              if (isNew)
                GxFuturisticBadge(
                  label: 'NOUVEAU',
                  color: accentColor,
                ),
              const Spacer(),
              GxFuturisticChip(
                label: category.label,
                accentColor: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: NotilusFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: NotilusFonts.rajdhani(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.time,
                size: 12,
                color: Colors.white.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                date,
                style: NotilusFonts.rajdhani(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

