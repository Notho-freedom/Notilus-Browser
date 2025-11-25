import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/theme_mode_notifier.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../common/color_picker_dialog.dart';

class ModernSettingsPanel extends StatefulWidget {
  const ModernSettingsPanel({super.key});

  @override
  State<ModernSettingsPanel> createState() => _ModernSettingsPanelState();
}

class _ModernSettingsPanelState extends State<ModernSettingsPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(context.watch<WallpaperManager>().current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Apparence',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Système'),
                        selected: mode == ThemeMode.system,
                        onSelected: (_) =>
                            themeNotifier.setMode(ThemeMode.system),
                        selectedColor: NotilusColors.neonRed.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: mode == ThemeMode.system
                              ? NotilusColors.neonRed
                              : Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Clair'),
                        selected: mode == ThemeMode.light,
                        onSelected: (_) =>
                            themeNotifier.setMode(ThemeMode.light),
                        selectedColor: NotilusColors.neonRed.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: mode == ThemeMode.light
                              ? NotilusColors.neonRed
                              : Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Sombre'),
                        selected: mode == ThemeMode.dark,
                        onSelected: (_) =>
                            themeNotifier.setMode(ThemeMode.dark),
                        selectedColor: NotilusColors.neonRed.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: mode == ThemeMode.dark
                              ? NotilusColors.neonRed
                              : Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Consumer<ColorThemeManager>(
                    builder: (context, colorThemeManager, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thème de couleur',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ColorThemeManager.availableThemes.map((theme) {
                              final isSelected = colorThemeManager.currentTheme.id == theme.id;
                              return GestureDetector(
                                onTap: () => colorThemeManager.setTheme(theme.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.primary.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.primary
                                          : Colors.white.withValues(alpha: 0.1),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: theme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        theme.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? theme.primary
                                              : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Consumer<ColorThemeManager>(
                    builder: (context, colorThemeManager, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Couleurs personnalisées',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Couleur de fond native
                          GestureDetector(
                            onTap: () async {
                              final color = await ColorPickerDialog.show(
                                context,
                                initialColor: colorThemeManager.nativeBackgroundColor,
                                title: 'Couleur de fond native',
                              );
                              if (color != null) {
                                await colorThemeManager.setNativeBackgroundColor(color);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorThemeManager.nativeBackgroundColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fond natif',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Sidebar, topbars, etc.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Couleur secondaire native
                          GestureDetector(
                            onTap: () async {
                              final color = await ColorPickerDialog.show(
                                context,
                                initialColor: colorThemeManager.nativeSecondaryColor,
                                title: 'Couleur secondaire native',
                              );
                              if (color != null) {
                                await colorThemeManager.setNativeSecondaryColor(color);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorThemeManager.nativeSecondaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Secondaire native',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Éléments secondaires',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Bouton réinitialiser
                          TextButton.icon(
                            onPressed: () async {
                              await colorThemeManager.resetCustomColors();
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Réinitialiser les couleurs'),
                            style: TextButton.styleFrom(
                              foregroundColor: NotilusColors.neonRed,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Onglets',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Restaurer les onglets au démarrage',
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      'Les onglets ouverts seront rechargés au prochain lancement.',
                      style: TextStyle(fontSize: 10),
                    ),
                    value: true,
                    onChanged: (_) {
                      // TODO: brancher sur une vraie préférence
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Ouvrir Notilus sur la page d\'accueil',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: true,
                    onChanged: (_) {
                      // TODO: préférence de démarrage
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Confidentialité',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_moon_outlined),
                    title: Text(
                      'Effacer les données de navigation',
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      'Historique, cookies et cache (à implémenter).',
                      style: TextStyle(fontSize: 10),
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


