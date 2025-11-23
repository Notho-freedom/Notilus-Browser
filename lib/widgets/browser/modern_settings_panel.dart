import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/wallpapers.dart';
import '../../core/services/theme_mode_notifier.dart';

class ModernSettingsPanel extends StatefulWidget {
  const ModernSettingsPanel({super.key});

  @override
  State<ModernSettingsPanel> createState() => _ModernSettingsPanelState();
}

class _ModernSettingsPanelState extends State<ModernSettingsPanel> {
  late final String _backgroundUrl;

  @override
  void initState() {
    super.initState();
    final wallpapers = NotilusWallpapers.all;
    final random = Random();
    _backgroundUrl = wallpapers[random.nextInt(wallpapers.length)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_backgroundUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.8),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Consumer<ThemeModeNotifier>(
            builder: (context, themeNotifier, _) {
              final mode = themeNotifier.mode;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Apparence',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Système'),
                        selected: mode == ThemeMode.system,
                        onSelected: (_) =>
                            themeNotifier.setMode(ThemeMode.system),
                      ),
                      ChoiceChip(
                        label: const Text('Clair'),
                        selected: mode == ThemeMode.light,
                        onSelected: (_) =>
                            themeNotifier.setMode(ThemeMode.light),
                      ),
                      ChoiceChip(
                        label: const Text('Sombre'),
                        selected: mode == ThemeMode.dark,
                        onSelected: (_) =>
                            themeNotifier.setMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Onglets',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Restaurer les onglets au démarrage'),
                    subtitle: const Text(
                      'Les onglets ouverts seront rechargés au prochain lancement.',
                    ),
                    value: true,
                    onChanged: (_) {
                      // TODO: brancher sur une vraie préférence
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ouvrir Notilus sur la page d’accueil'),
                    value: true,
                    onChanged: (_) {
                      // TODO: préférence de démarrage
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Confidentialité',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_moon_outlined),
                    title: const Text('Effacer les données de navigation'),
                    subtitle: const Text(
                      'Historique, cookies et cache (à implémenter).',
                    ),
                    onTap: () {
                      // TODO: effacement des données
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Notilus Browser — Build futuriste expérimental',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


