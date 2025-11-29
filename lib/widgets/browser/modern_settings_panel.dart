import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/theme_mode_notifier.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../services/settings_service.dart';
import '../../services/terminal_service.dart';
import '../../services/history_service.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/config_sync_service.dart';
import '../../widgets/auth/sync_status_widget.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../common/color_picker_dialog.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/gx_notification_service.dart';
import '../../services/tts_service.dart';
import '../../services/ai_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show Platform;

class ModernSettingsPanel extends StatefulWidget {
  final VoidCallback? onClose;
  
  const ModernSettingsPanel({
    super.key,
    this.onClose,
  });

  @override
  State<ModernSettingsPanel> createState() => _ModernSettingsPanelState();
}

class _ModernSettingsPanelState extends State<ModernSettingsPanel> {
  final SettingsService _settings = SettingsService();
  String _currentSection = 'appearance';
  
  @override
  void initState() {
    super.initState();
    _settings.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(context.watch<WallpaperManager>().current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.88),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => Container(
          color: Colors.black.withOpacity(1.0 - _settings.panelTransparency),
          child: Row(
          children: [
            // Navigation latérale des sections
            Container(
              width: 180,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: gxRed.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Paramètres',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildSectionItem('appearance', 'Apparence', CupertinoIcons.paintbrush, gxRed),
                        _buildSectionItem('wallpaper', 'Fonds d\'écran', CupertinoIcons.photo, gxRed),
                        _buildSectionItem('tabs', 'Onglets', CupertinoIcons.square_on_square, gxRed),
                        _buildSectionItem('downloads', 'Téléchargements', CupertinoIcons.arrow_down_circle, gxRed),
                        _buildSectionItem('terminal', 'Terminal', CupertinoIcons.square_list, gxRed),
                        _buildSectionItem('homepage', 'Page d\'accueil', CupertinoIcons.house, gxRed),
                        _buildSectionItem('webservices', 'Services Web', CupertinoIcons.globe, gxRed),
                        _buildSectionItem('privacy', 'Confidentialité', CupertinoIcons.shield, gxRed),
                        _buildSectionItem('account', 'Compte', CupertinoIcons.person_circle, gxRed),
                        _buildSectionItem('ai', 'Assistant IA', CupertinoIcons.sparkles, gxRed),
                        _buildSectionItem('devtools', 'DevTools', CupertinoIcons.ant, gxRed),
                        _buildSectionItem('gxComponents', 'Composants GX', CupertinoIcons.square_grid_2x2, gxRed),
                        _buildSectionItem('notifications', 'Notifications', CupertinoIcons.bell, gxRed),
                        _buildSectionItem('tts', 'Synthèse vocale', CupertinoIcons.speaker_2, gxRed),
                        _buildSectionItem('about', 'À propos', CupertinoIcons.info_circle, gxRed),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenu de la section
            Expanded(
              child: _buildSectionContent(context, theme, gxRed),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSectionItem(String id, String label, IconData icon, Color gxRed) {
    final isSelected = _currentSection == id;
    return InkWell(
      onTap: () => setState(() => _currentSection = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? gxRed.withOpacity(0.15) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? gxRed : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? gxRed : Colors.white60,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? gxRed : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(BuildContext context, ThemeData theme, Color gxRed) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(gxRed),
          const SizedBox(height: 20),
          switch (_currentSection) {
            'appearance' => _buildAppearanceSection(context, theme, gxRed),
            'wallpaper' => _buildWallpaperSection(context, theme, gxRed),
            'tabs' => _buildTabsSection(context, theme, gxRed),
            'downloads' => _buildDownloadsSection(context, theme, gxRed),
            'terminal' => _buildTerminalSection(context, theme, gxRed),
            'homepage' => _buildHomepageSection(context, theme, gxRed),
            'webservices' => _buildWebServicesSection(context, theme, gxRed),
            'privacy' => _buildPrivacySection(context, theme, gxRed),
            'gxComponents' => _buildGxComponentsSection(context, theme, gxRed),
            'notifications' => _buildNotificationsSection(context, theme, gxRed),
            'tts' => _buildTtsSection(context, theme, gxRed),
            'account' => _buildAccountSection(context, theme, gxRed),
            'ai' => _buildAiSection(context, theme, gxRed),
            'devtools' => _buildDevToolsSection(context, theme, gxRed),
            'about' => _buildAboutSection(context, theme, gxRed),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }

  Widget _buildSectionHeader(Color gxRed) {
    final titles = {
      'appearance': ('Apparence', 'Personnalisez l\'apparence de Notilus'),
      'wallpaper': ('Fonds d\'écran', 'Gérez les fonds d\'écran dynamiques'),
      'tabs': ('Onglets', 'Comportement des onglets au démarrage'),
      'downloads': ('Téléchargements', 'Configurez le dossier et le comportement'),
      'terminal': ('Terminal', 'Choisissez votre terminal préféré'),
      'homepage': ('Page d\'accueil', 'Personnalisez la page d\'accueil'),
      'webservices': ('Services Web', 'Gérez les services de la sidebar'),
      'privacy': ('Confidentialité', 'Protégez vos données de navigation'),
      'account': ('Compte', 'Authentification et synchronisation'),
      'devtools': ('DevTools', 'Configuration des outils de développement'),
      'about': ('À propos', 'Informations sur Notilus Browser'),
    };
    final info = titles[_currentSection] ?? ('', '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: gxRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              info.$1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (info.$2.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              info.$2,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================
  // SECTION APPARENCE
  // ============================================
  
  Widget _buildAppearanceSection(BuildContext context, ThemeData theme, Color gxRed) {
    return Consumer<ThemeModeNotifier>(
      builder: (context, themeNotifier, _) {
        final mode = themeNotifier.mode;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Mode de thème', gxRed),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildThemeModeChip('Système', ThemeMode.system, mode, themeNotifier, gxRed),
                _buildThemeModeChip('Clair', ThemeMode.light, mode, themeNotifier, gxRed),
                _buildThemeModeChip('Sombre', ThemeMode.dark, mode, themeNotifier, gxRed),
              ],
            ),
            const SizedBox(height: 28),
            _buildSubsectionTitle('Thème de couleur', gxRed),
            const SizedBox(height: 4),
            Text(
              'Change la couleur principale de l\'interface',
              style: TextStyle(fontSize: 10, color: Colors.white60),
            ),
            const SizedBox(height: 12),
            Consumer<ColorThemeManager>(
              builder: (context, colorThemeManager, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ColorThemeManager.availableThemes.map((colorTheme) {
                    final isSelected = colorThemeManager.currentTheme.id == colorTheme.id;
                    return _buildColorThemeChip(colorTheme, isSelected, colorThemeManager);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            _buildSubsectionTitle('Couleurs personnalisées', gxRed),
            const SizedBox(height: 12),
            Consumer<ColorThemeManager>(
              builder: (context, colorThemeManager, _) {
                return Column(
                  children: [
                    _buildColorPickerTile(
                      context,
                      title: 'Couleur de fond',
                      subtitle: 'Sidebar, barres d\'outils',
                      color: colorThemeManager.nativeBackgroundColor,
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
                    ),
                    const SizedBox(height: 12),
                    _buildColorPickerTile(
                      context,
                      title: 'Couleur secondaire',
                      subtitle: 'Accents, éléments actifs',
                      color: colorThemeManager.nativeSecondaryColor,
                      onTap: () async {
                        final color = await ColorPickerDialog.show(
                          context,
                          initialColor: colorThemeManager.nativeSecondaryColor,
                          title: 'Couleur secondaire',
                        );
                        if (color != null) {
                          await colorThemeManager.setNativeSecondaryColor(color);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await colorThemeManager.resetCustomColors();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Réinitialiser les couleurs'),
                        style: TextButton.styleFrom(
                          foregroundColor: gxRed,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeModeChip(String label, ThemeMode mode, ThemeMode currentMode, ThemeModeNotifier notifier, Color gxRed) {
    final isSelected = currentMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => notifier.setMode(mode),
      selectedColor: gxRed.withOpacity(0.2),
      backgroundColor: Colors.white.withOpacity(0.05),
      side: BorderSide(color: isSelected ? gxRed : Colors.white24),
      labelStyle: TextStyle(
        color: isSelected ? gxRed : Colors.white70,
        fontSize: 11,
      ),
    );
  }

  Widget _buildColorThemeChip(ColorTheme colorTheme, bool isSelected, ColorThemeManager manager) {
    return GestureDetector(
      onTap: () => manager.setTheme(colorTheme.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorTheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorTheme.primary : Colors.white.withOpacity(0.1),
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
                color: colorTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              colorTheme.name,
              style: TextStyle(
                color: isSelected ? colorTheme.primary : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPickerTile(BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SECTION FONDS D'ÉCRAN
  // ============================================
  
  Widget _buildWallpaperSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Fond d\'écran dynamique', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Activer les fonds d\'écran',
              subtitle: 'Affiche un fond d\'écran sur la page d\'accueil et les panneaux',
              value: _settings.wallpaperEnabled,
              onChanged: (v) => _settings.setWallpaperEnabled(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Rotation automatique',
              subtitle: 'Change le fond d\'écran périodiquement',
              value: _settings.wallpaperRotationEnabled,
              onChanged: (v) => _settings.setWallpaperRotationEnabled(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 16),
            _buildSubsectionTitle('Intervalle de rotation', gxRed),
            const SizedBox(height: 12),
            _buildIntervalSelector(gxRed),
            const SizedBox(height: 24),
            _buildSubsectionTitle('Aperçu', gxRed),
            const SizedBox(height: 12),
            Consumer<WallpaperManager>(
              builder: (context, wallpaperManager, _) {
                return Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(wallpaperManager.current),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: gxRed.withOpacity(0.3)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => wallpaperManager.next(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Changer maintenant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gxRed.withOpacity(0.2),
                        foregroundColor: gxRed,
                        side: BorderSide(color: gxRed.withOpacity(0.5)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntervalSelector(Color gxRed) {
    final intervals = [1, 2, 5, 10, 15, 30];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: intervals.map((minutes) {
        final isSelected = _settings.wallpaperIntervalMinutes == minutes;
        return ChoiceChip(
          label: Text('$minutes min'),
          selected: isSelected,
          onSelected: (_) => _settings.setWallpaperIntervalMinutes(minutes),
          selectedColor: gxRed.withOpacity(0.2),
          backgroundColor: Colors.white.withOpacity(0.05),
          side: BorderSide(color: isSelected ? gxRed : Colors.white24),
          labelStyle: TextStyle(
            color: isSelected ? gxRed : Colors.white70,
            fontSize: 11,
          ),
        );
      }).toList(),
    );
  }

  // ============================================
  // SECTION ONGLETS
  // ============================================
  
  Widget _buildTabsSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Démarrage', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Restaurer les onglets',
              subtitle: 'Recharge les onglets ouverts au prochain lancement',
              value: _settings.restoreTabsOnStartup,
              onChanged: (v) => _settings.setRestoreTabsOnStartup(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Ouvrir sur la page d\'accueil',
              subtitle: 'Démarre Notilus sur le Speed Dial',
              value: _settings.startOnHomePage,
              onChanged: (v) => _settings.setStartOnHomePage(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 24),
            _buildSubsectionTitle('Nouvel onglet', gxRed),
            const SizedBox(height: 12),
            _buildNewTabBehaviorSelector(gxRed),
          ],
        );
      },
    );
  }

  Widget _buildNewTabBehaviorSelector(Color gxRed) {
    final behaviors = {
      'home': 'Page d\'accueil',
      'blank': 'Page vide',
      'url': 'URL personnalisée',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: behaviors.entries.map((entry) {
            final isSelected = _settings.newTabBehavior == entry.key;
            return ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) => _settings.setNewTabBehavior(entry.key),
              selectedColor: gxRed.withOpacity(0.2),
              backgroundColor: Colors.white.withOpacity(0.05),
              side: BorderSide(color: isSelected ? gxRed : Colors.white24),
              labelStyle: TextStyle(
                color: isSelected ? gxRed : Colors.white70,
                fontSize: 11,
              ),
            );
          }).toList(),
        ),
        if (_settings.newTabBehavior == 'url') ...[
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: _settings.newTabUrl),
            onChanged: (v) => _settings.setNewTabUrl(v),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'https://example.com',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: gxRed),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================
  // SECTION TÉLÉCHARGEMENTS
  // ============================================
  
  Widget _buildDownloadsSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Emplacement', gxRed),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.folder, color: gxRed, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dossier de téléchargement', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          _settings.downloadFolder ?? '~/Downloads/Notilus',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: 'Sélectionnez le dossier de téléchargement',
                      );
                      if (selectedDirectory != null) {
                        await _settings.setDownloadFolder(selectedDirectory);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Dossier défini: $selectedDirectory'),
                              backgroundColor: gxRed,
                            ),
                          );
                        }
                      }
                    },
                    child: Text('Changer', style: TextStyle(color: gxRed, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSubsectionTitle('Comportement', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Demander où enregistrer',
              subtitle: 'Affiche un dialogue pour chaque téléchargement',
              value: _settings.askDownloadLocation,
              onChanged: (v) => _settings.setAskDownloadLocation(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Ouvrir automatiquement',
              subtitle: 'Ouvre les fichiers après téléchargement',
              value: _settings.autoOpenDownloads,
              onChanged: (v) => _settings.setAutoOpenDownloads(v),
              gxRed: gxRed,
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // SECTION TERMINAL
  // ============================================
  
  Widget _buildTerminalSection(BuildContext context, ThemeData theme, Color gxRed) {
    final terminalService = TerminalService();
    
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Terminal préféré', gxRed),
            const SizedBox(height: 12),
            ...terminalService.nativeTerminals.map((terminal) {
              final isSelected = _settings.preferredTerminal == terminal.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTerminalOption(terminal, isSelected, gxRed),
              );
            }),
            const SizedBox(height: 20),
            _buildSubsectionTitle('Terminaux isolés', gxRed),
            const SizedBox(height: 4),
            Text('Environnements via Docker/WSL', style: TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(height: 12),
            ...terminalService.isolatedTerminals.take(4).map((terminal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTerminalOption(terminal, false, gxRed, locked: terminal.isLocked),
              );
            }),
            const SizedBox(height: 20),
            _buildSubsectionTitle('Interface', gxRed),
            const SizedBox(height: 4),
            Text('Choisissez le type d\'interface du terminal', style: TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(height: 12),
            _buildTerminalInterfaceSelector(gxRed),
            const SizedBox(height: 20),
            _buildSubsectionTitle('Apparence', gxRed),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Taille de police', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.remove, color: gxRed, size: 18),
                  onPressed: () {
                    if (_settings.terminalFontSize > 10) {
                      _settings.setTerminalFontSize(_settings.terminalFontSize - 1);
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_settings.terminalFontSize.toInt()}px',
                    style: TextStyle(color: gxRed, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: gxRed, size: 18),
                  onPressed: () {
                    if (_settings.terminalFontSize < 24) {
                      _settings.setTerminalFontSize(_settings.terminalFontSize + 1);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTerminalInterfaceSelector(Color gxRed) {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: 'Interface native Notilus - Interface Flutter optimisée, légère et rapide',
            child: GestureDetector(
              onTap: () => _settings.setTerminalInterfaceType('native'),
              child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _settings.terminalInterfaceType == 'native'
                    ? gxRed.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _settings.terminalInterfaceType == 'native'
                      ? gxRed
                      : Colors.white.withOpacity(0.1),
                  width: _settings.terminalInterfaceType == 'native' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.square_list,
                    color: _settings.terminalInterfaceType == 'native' ? gxRed : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notilus Native',
                    style: TextStyle(
                      color: _settings.terminalInterfaceType == 'native' ? gxRed : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Interface Flutter',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Tooltip(
            message: 'XTerm.js - Terminal avancé avec support complet des fonctionnalités terminal',
            child: GestureDetector(
              onTap: () => _settings.setTerminalInterfaceType('xterm'),
              child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _settings.terminalInterfaceType == 'xterm'
                    ? gxRed.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _settings.terminalInterfaceType == 'xterm'
                      ? gxRed
                      : Colors.white.withOpacity(0.1),
                  width: _settings.terminalInterfaceType == 'xterm' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.square_list,
                    color: _settings.terminalInterfaceType == 'xterm' ? gxRed : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'XTerm.js',
                    style: TextStyle(
                      color: _settings.terminalInterfaceType == 'xterm' ? gxRed : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terminal avancé',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalOption(dynamic terminal, bool isSelected, Color gxRed, {bool locked = false}) {
    return GestureDetector(
      onTap: locked ? null : () => _settings.setPreferredTerminal(terminal.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? gxRed.withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? gxRed : (locked ? Colors.white12 : Colors.white24),
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.square_list,
              size: 18,
              color: locked ? Colors.white30 : (isSelected ? gxRed : Colors.white70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terminal.name,
                    style: TextStyle(
                      color: locked ? Colors.white30 : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    terminal.description,
                    style: TextStyle(
                      color: locked ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(CupertinoIcons.checkmark_circle_fill, color: gxRed, size: 18),
            if (locked)
              Icon(CupertinoIcons.lock, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SECTION PAGE D'ACCUEIL
  // ============================================
  
  Widget _buildHomepageSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Style de page d\'accueil', gxRed),
            const SizedBox(height: 4),
            Text(
              'Choisissez l\'apparence adaptée à votre profil de développeur',
              style: TextStyle(color: Colors.white60, fontSize: 10),
            ),
            const SizedBox(height: 16),
            _buildHomePageStyleSelector(gxRed),
            
            const SizedBox(height: 28),
            
            // === TRANSPARENCE DES WIDGETS ===
            _buildSubsectionTitle('Transparence des widgets', gxRed),
            const SizedBox(height: 4),
            Text(
              'Réglez la transparence pour voir le fond d\'écran à travers les éléments',
              style: TextStyle(color: Colors.white60, fontSize: 10),
            ),
            const SizedBox(height: 16),
            _buildTransparencySlider(
              label: 'Widgets',
              value: _settings.widgetTransparency,
              onChanged: (v) => _settings.setWidgetTransparency(v),
              gxRed: gxRed,
              tooltip: 'Transparence des widgets et éléments de l\'interface (barre d\'adresse, onglets, etc.)',
            ),
            const SizedBox(height: 12),
            _buildTransparencySlider(
              label: 'Panneaux latéraux',
              value: _settings.panelTransparency,
              onChanged: (v) => _settings.setPanelTransparency(v),
              gxRed: gxRed,
              tooltip: 'Transparence des panneaux latéraux (sidebar, paramètres, documentation, etc.)',
            ),
            const SizedBox(height: 12),
            _buildTransparencySlider(
              label: 'Overlays',
              value: _settings.overlayTransparency,
              onChanged: (v) => _settings.setOverlayTransparency(v),
              gxRed: gxRed,
              tooltip: 'Transparence des overlays et menus contextuels',
            ),
            const SizedBox(height: 12),
            _buildTransparencySlider(
              label: 'Page d\'accueil',
              value: _settings.homePageBlur,
              onChanged: (v) => _settings.setHomePageBlur(v),
              gxRed: gxRed,
              tooltip: 'Contrôle l\'opacité du fond d\'écran et du flou sur la page d\'accueil',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Intensité du flou', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_settings.glassBlurIntensity.toInt()}',
                    style: TextStyle(color: gxRed, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _settings.glassBlurIntensity,
              min: 0,
              max: 30,
              divisions: 30,
              activeColor: gxRed,
              inactiveColor: Colors.white24,
              onChanged: (v) => _settings.setGlassBlurIntensity(v),
            ),
            
            const SizedBox(height: 28),
            
            // === PERSONNALISATION AVANCÉE ===
            _buildSubsectionTitle('Personnalisation avancée', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Afficher l\'horloge',
              subtitle: 'Heure et date sur la page d\'accueil',
              value: _settings.showClock,
              onChanged: (v) => _settings.setShowClock(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Afficher les citations',
              subtitle: 'Citations inspirantes pour développeurs',
              value: _settings.showQuotes,
              onChanged: (v) => _settings.setShowQuotes(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Animations',
              subtitle: 'Effets visuels et transitions',
              value: _settings.showAnimations,
              onChanged: (v) => _settings.setShowAnimations(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 16),
            
            // Message de bienvenue personnalisé
            Text('Message de bienvenue', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _settings.customGreeting),
              onChanged: (v) => _settings.setCustomGreeting(v),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Ex: Bonjour, [Votre nom]!',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: gxRed),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            
            const SizedBox(height: 28),
            
            // === PANNEAUX LATÉRAUX (Modern uniquement) ===
            _buildSubsectionTitle('Panneaux latéraux', gxRed),
            const SizedBox(height: 4),
            Text(
              'Disponible uniquement pour le style Modern',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _settings.homePageStyle == 'modern' ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: _settings.homePageStyle != 'modern',
                child: Column(
                  children: [
                    _buildSettingSwitch(
                      title: 'Panneau Dev Tools (gauche)',
                      subtitle: 'Affiche le panneau d\'outils de développement',
                      value: _settings.leftColumnExpanded,
                      onChanged: (v) => _settings.setLeftColumnExpanded(v),
                      gxRed: gxRed,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingSwitch(
                      title: 'Panneau Quick Actions (droite)',
                      subtitle: 'Affiche les raccourcis rapides',
                      value: _settings.rightColumnExpanded,
                      onChanged: (v) => _settings.setRightColumnExpanded(v),
                      gxRed: gxRed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSubsectionTitle('Sections visibles', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Widgets système',
              subtitle: 'CPU, RAM, GPU, etc.',
              value: _settings.showSystemWidgets,
              onChanged: (v) => _settings.setShowSystemWidgets(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Sites rapides',
              subtitle: 'Grille Speed Dial',
              value: _settings.showQuickAccess,
              onChanged: (v) => _settings.setShowQuickAccess(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Historique récent',
              subtitle: 'Accès rapide aux pages visitées',
              value: _settings.showRecentHistory,
              onChanged: (v) => _settings.setShowRecentHistory(v),
              gxRed: gxRed,
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildTransparencySlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color gxRed,
    String? tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (tooltip != null)
              Tooltip(
                message: tooltip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 14, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
              )
            else
              Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(color: gxRed, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: gxRed,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: gxRed,
            overlayColor: gxRed.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHomePageStyleSelector(Color gxRed) {
    // Tous les styles de pages d'accueil disponibles
    final styles = [
      (
        'modern',
        'Modern',
        'Style classique avec Speed Dial et widgets système',
        CupertinoIcons.square_grid_2x2,
        '🌟',
        const Color(0xFFFF4444),
      ),
      (
        'notilus_dev',
        'Notilus Dev',
        'Command bar style IDE avec catégories de liens',
        CupertinoIcons.chevron_left_slash_chevron_right,
        '💻',
        const Color(0xFFFF4444),
      ),
      (
        'frontend',
        'Frontend',
        'Optimisé pour React, Vue, Angular et le web',
        CupertinoIcons.paintbrush,
        '⚛️',
        const Color(0xFF61DAFB),
      ),
      (
        'backend',
        'Backend',
        'Terminal-style avec métriques système et APIs',
        CupertinoIcons.square_list,
        '🖥️',
        const Color(0xFF339933),
      ),
      (
        'devops',
        'DevOps',
        'Dashboard monitoring et statut des services',
        CupertinoIcons.cloud,
        '☁️',
        const Color(0xFF00FF88),
      ),
      (
        'data_science',
        'Data Science',
        'Visualisations et outils ML/AI',
        CupertinoIcons.chart_bar,
        '📊',
        const Color(0xFF8B5CF6),
      ),
      (
        'minimal',
        'Minimal',
        'Interface épurée, focus sur l\'essentiel',
        CupertinoIcons.sparkles,
        '✨',
        Colors.white,
      ),
      (
        'gx_futuristic',
        'GX Futuristic',
        'Design ultra-futuriste avec contours géométriques façon OS Science-Fiction',
        CupertinoIcons.flame,
        '🚀',
        const Color(0xFFFF2D55),
      ),
    ];
    
    return Column(
      children: styles.map((style) {
        final isSelected = _settings.homePageStyle == style.$1;
        final accentColor = style.$6;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _settings.setHomePageStyle(style.$1),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        style.$5,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style.$2,
                          style: TextStyle(
                            color: isSelected ? accentColor : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          style.$3,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: accentColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================
  // SECTION SERVICES WEB
  // ============================================
  
  Widget _buildWebServicesSection(BuildContext context, ThemeData theme, Color gxRed) {
    final services = [
      ('youtubeMusic', 'YouTube Music', CupertinoIcons.music_note),
      ('youtube', 'YouTube', CupertinoIcons.play_circle),
      ('chatgpt', 'ChatGPT', CupertinoIcons.chat_bubble_2),
      ('deepseek', 'DeepSeek', CupertinoIcons.sparkles),
      ('whatsapp', 'WhatsApp', CupertinoIcons.chat_bubble_text),
      ('telegram', 'Telegram', CupertinoIcons.paperplane),
    ];
    
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Services dans la sidebar', gxRed),
            const SizedBox(height: 4),
            Text(
              'Activez ou désactivez les services web accessibles depuis la sidebar',
              style: TextStyle(color: Colors.white60, fontSize: 10),
            ),
            const SizedBox(height: 16),
            ...services.map((service) {
              final isEnabled = _settings.isWebServiceEnabled(service.$1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(service.$3, size: 18, color: isEnabled ? gxRed : Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          service.$2,
                          style: TextStyle(
                            color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: isEnabled,
                        onChanged: (v) => _settings.toggleWebService(service.$1, v),
                        activeColor: gxRed,
                        activeTrackColor: gxRed.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ============================================
  // SECTION CONFIDENTIALITÉ
  // ============================================
  
  Widget _buildPrivacySection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Données de navigation', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Enregistrer l\'historique',
              subtitle: 'Garde une trace des pages visitées',
              value: _settings.saveHistory,
              onChanged: (v) => _settings.setSaveHistory(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Conserver les cookies',
              subtitle: 'Garde les sessions de connexion',
              value: _settings.saveCookies,
              onChanged: (v) => _settings.setSaveCookies(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Bloquer les trackers',
              subtitle: 'Protection contre le pistage (expérimental)',
              value: _settings.blockTrackers,
              onChanged: (v) => _settings.setBlockTrackers(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 24),
            _buildSubsectionTitle('Effacer les données', gxRed),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildClearButton('Historique', CupertinoIcons.time, gxRed, () async {
                  final confirm = await _showClearConfirmDialog(
                    context, 
                    'Effacer l\'historique', 
                    'Voulez-vous vraiment effacer tout l\'historique de navigation ?',
                    gxRed,
                  );
                  if (confirm == true) {
                    await HistoryService().clearHistory();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Historique effacé'),
                          backgroundColor: gxRed,
                        ),
                      );
                    }
                  }
                }),
                _buildClearButton('Cookies', CupertinoIcons.lock, gxRed, () async {
                  final confirm = await _showClearConfirmDialog(
                    context, 
                    'Effacer les cookies', 
                    'Voulez-vous vraiment effacer tous les cookies ?\nVous serez déconnecté de tous les sites.',
                    gxRed,
                  );
                  if (confirm == true) {
                    // Appeler clearCookies sur tous les engines actifs
                    try {
                      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
                      await webViewManager.clearAllCookies();
                    } catch (e) {
                      debugPrint('Erreur clear cookies: $e');
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cookies effacés'),
                          backgroundColor: gxRed,
                        ),
                      );
                    }
                  }
                }),
                _buildClearButton('Cache', CupertinoIcons.trash, gxRed, () async {
                  final confirm = await _showClearConfirmDialog(
                    context, 
                    'Effacer le cache', 
                    'Voulez-vous vraiment effacer le cache de navigation ?',
                    gxRed,
                  );
                  if (confirm == true) {
                    // Appeler clearCache sur tous les engines actifs
                    try {
                      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
                      await webViewManager.clearAllCache();
                    } catch (e) {
                      debugPrint('Erreur clear cache: $e');
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cache effacé'),
                          backgroundColor: gxRed,
                        ),
                      );
                    }
                  }
                }),
                _buildClearButton('Tout effacer', CupertinoIcons.delete, gxRed, () async {
                  final confirm = await _showClearConfirmDialog(
                    context, 
                    'Effacer toutes les données', 
                    'Voulez-vous vraiment effacer :\n• Historique\n• Cookies\n• Cache\n• Données de navigation\n\nCette action est irréversible.',
                    gxRed,
                    isDestructive: true,
                  );
                  if (confirm == true) {
                    // Effacer historique
                    await HistoryService().clearHistory();
                    
                    // Effacer cookies et cache
                    try {
                      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
                      await webViewManager.clearAllCookies();
                      await webViewManager.clearAllCache();
                    } catch (e) {
                      debugPrint('Erreur clear all: $e');
                    }
                    
                    // Effacer les données SharedPreferences liées à la navigation
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('notilus_bookmarks');
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Toutes les données effacées'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }, destructive: true),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildClearButton(String label, IconData icon, Color gxRed, VoidCallback onTap, {bool destructive = false}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive ? Colors.red : gxRed,
        side: BorderSide(color: destructive ? Colors.red.withOpacity(0.5) : gxRed.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<bool?> _showClearConfirmDialog(
    BuildContext context, 
    String title, 
    String message, 
    Color accentColor,
    {bool isDestructive = false}
  ) {
    return GxFuturisticDialog.show<bool>(
      context: context,
      title: title,
      titleIcon: isDestructive ? Icons.warning_rounded : Icons.delete_rounded,
      accentColor: isDestructive ? Colors.red : accentColor,
      width: 450,
      child: Text(
        message,
        style: NotilusFonts.rajdhani(
          fontSize: 13,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.pop(context, false),
        ),
        GxFuturisticButton(
          label: 'Confirmer',
          icon: Icons.check_rounded,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: isDestructive ? Colors.red : accentColor,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }

  // ============================================
  // SECTION DEVTOOLS
  // ============================================
  
  Widget _buildDevToolsSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final positions = {
          'bottom': 'En bas',
          'right': 'À droite',
          'detached': 'Détaché',
        };
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === POSITION ET TAILLE ===
            _buildSubsectionTitle('Position et taille', gxRed),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: positions.entries.map((entry) {
                final isSelected = _settings.devToolsPosition == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (_) => _settings.setDevToolsPosition(entry.key),
                  selectedColor: gxRed.withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  side: BorderSide(color: isSelected ? gxRed : Colors.white24),
                  labelStyle: TextStyle(color: isSelected ? gxRed : Colors.white70, fontSize: 11),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Hauteur', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _settings.devToolsHeight,
                    min: 200,
                    max: 600,
                    divisions: 8,
                    activeColor: gxRed,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => _settings.setDevToolsHeight(v),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                  child: Text('${_settings.devToolsHeight.toInt()}px', style: TextStyle(color: gxRed, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // === CONSOLE ===
            _buildSubsectionTitle('Console', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Afficher les timestamps',
              subtitle: 'Horodatage des messages',
              value: _settings.devToolsShowTimestamps,
              onChanged: (v) => _settings.setDevToolsShowTimestamps(v),
              gxRed: gxRed,
            ),
            _buildSettingSwitch(
              title: 'Grouper les logs similaires',
              subtitle: 'Agrège les messages répétés',
              value: _settings.devToolsGroupLogs,
              onChanged: (v) => _settings.setDevToolsGroupLogs(v),
              gxRed: gxRed,
            ),
            _buildSettingSwitch(
              title: 'Défilement automatique',
              subtitle: 'Scroll vers les nouveaux messages',
              value: _settings.devToolsAutoScroll,
              onChanged: (v) => _settings.setDevToolsAutoScroll(v),
              gxRed: gxRed,
            ),
            _buildSettingSwitch(
              title: 'Préserver les logs',
              subtitle: 'Garder les logs lors de la navigation',
              value: _settings.devToolsPreserveLogs,
              onChanged: (v) => _settings.setDevToolsPreserveLogs(v),
              gxRed: gxRed,
            ),
            
            const SizedBox(height: 24),
            
            // === NETWORK ===
            _buildSubsectionTitle('Network', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Capturer les corps de requête',
              subtitle: 'Enregistrer le contenu des requêtes/réponses',
              value: _settings.devToolsCaptureBody,
              onChanged: (v) => _settings.setDevToolsCaptureBody(v),
              gxRed: gxRed,
            ),
            _buildSettingSwitch(
              title: 'Désactiver le cache',
              subtitle: 'Forcer le rechargement des ressources',
              value: _settings.devToolsDisableCache,
              onChanged: (v) => _settings.setDevToolsDisableCache(v),
              gxRed: gxRed,
            ),
            
            const SizedBox(height: 24),
            
            // === INSPECTION ===
            _buildSubsectionTitle('Inspection d\'éléments', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Afficher le box model',
              subtitle: 'Margin, border, padding, content',
              value: _settings.devToolsShowBoxModel,
              onChanged: (v) => _settings.setDevToolsShowBoxModel(v),
              gxRed: gxRed,
            ),
            _buildSettingSwitch(
              title: 'Afficher les dimensions',
              subtitle: 'Taille en pixels lors de l\'inspection',
              value: _settings.devToolsShowDimensions,
              onChanged: (v) => _settings.setDevToolsShowDimensions(v),
              gxRed: gxRed,
            ),
            _buildSettingSwitch(
              title: 'Afficher les guides',
              subtitle: 'Lignes de guidage horizontales/verticales',
              value: _settings.devToolsShowGuides,
              onChanged: (v) => _settings.setDevToolsShowGuides(v),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Couleur de surbrillance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                _buildColorPicker(_settings.devToolsHighlightColor, gxRed, (color) => _settings.setDevToolsHighlightColor(color)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // === PERFORMANCE ===
            _buildSubsectionTitle('Performance', gxRed),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Taux de rafraîchissement', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _settings.devToolsRefreshRate.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: gxRed,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => _settings.setDevToolsRefreshRate(v.toInt()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                  child: Text('${_settings.devToolsRefreshRate}s', style: TextStyle(color: gxRed, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // === APPARENCE ===
            _buildSubsectionTitle('Apparence', gxRed),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Taille de police', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _settings.devToolsFontSize,
                    min: 10,
                    max: 16,
                    divisions: 6,
                    activeColor: gxRed,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => _settings.setDevToolsFontSize(v),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                  child: Text('${_settings.devToolsFontSize.toInt()}px', style: TextStyle(color: gxRed, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // === RACCOURCIS ===
            _buildSubsectionTitle('Raccourcis clavier', gxRed),
            const SizedBox(height: 12),
            _buildShortcutInfo('Ouvrir DevTools', 'F12'),
            _buildShortcutInfo('Ouvrir DevTools', 'Ctrl + Shift + I'),
            _buildShortcutInfo('Console', 'Ctrl + Shift + J'),
            _buildShortcutInfo('Inspecter élément', 'Ctrl + Shift + C'),
            _buildShortcutInfo('Network', 'Ctrl + Shift + E'),
            _buildShortcutInfo('Resources', 'Ctrl + Shift + R'),
            _buildShortcutInfo('Fermer DevTools', 'Echap'),
            _buildShortcutInfo('Effacer la console', 'Ctrl + L'),
            
            const SizedBox(height: 24),
            
            // === ACTIONS ===
            _buildSubsectionTitle('Actions', gxRed),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Reset DevTools settings
                      _settings.resetDevToolsSettings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Paramètres DevTools réinitialisés'), backgroundColor: gxRed),
                      );
                    },
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Réinitialiser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Export DevTools config
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Configuration exportée dans le presse-papiers'), backgroundColor: gxRed),
                      );
                    },
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: const Text('Exporter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gxRed,
                      side: BorderSide(color: gxRed.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildColorPicker(String currentColor, Color gxRed, Function(String) onSelect) {
    final colors = [
      '#FF6B6B', // Rouge
      '#4ECDC4', // Cyan
      '#45B7D1', // Bleu
      '#96CEB4', // Vert
      '#FFEAA7', // Jaune
      '#DDA0DD', // Violet
      '#FF8C00', // Orange
    ];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((hex) {
        final isSelected = currentColor == hex;
        final color = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
        return GestureDetector(
          onTap: () => onSelect(hex),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShortcutInfo(String action, String shortcut) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(action, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SECTION COMPTE
  // ============================================
  
  Widget _buildAccountSection(BuildContext context, ThemeData theme, Color gxRed) {
    return Consumer2<FirebaseAuthService?, ConfigSyncService?>(
      builder: (context, authService, syncService, _) {
        if (authService == null || syncService == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubsectionTitle('Authentification', gxRed),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Firebase n\'est pas configuré. Configurez Firebase pour activer l\'authentification et la synchronisation.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final isSignedIn = authService.isAnySignedIn;
        final user = authService.currentUser;
        final githubUser = authService.githubUser;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Authentification', gxRed),
            const SizedBox(height: 12),
            if (!isSignedIn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Connectez-vous pour synchroniser vos configurations',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AuthDialog(
                            authService: authService,
                            onAuthStarted: () {
                              // Fermer le panel de paramètres quand l'auth démarre
                              widget.onClose?.call();
                            },
                          ),
                        );
                        if (result == true && context.mounted) {
                          await syncService!.restoreConfigs();
                        }
                      },
                      icon: Icon(CupertinoIcons.person_circle),
                      label: const Text('Se connecter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gxRed.withOpacity(0.2),
                        foregroundColor: gxRed,
                        side: BorderSide(color: gxRed),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if ((user?.photoURL ?? githubUser?.avatarUrl) != null)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage((user?.photoURL ?? githubUser?.avatarUrl)!),
                          )
                        else
                          CircleAvatar(
                            radius: 20,
                            child: Icon(CupertinoIcons.person),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? user?.email ?? githubUser?.name ?? githubUser?.email ?? 'Utilisateur',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                user?.email ?? githubUser?.email ?? '',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Déconnexion réussie')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                          ),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSubsectionTitle('Synchronisation', gxRed),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: syncService.isSyncing
                          ? null
                          : () async {
                              final success = await syncService.exportConfigs();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Configurations synchronisées'
                                        : 'Erreur lors de la synchronisation'),
                                  ),
                                );
                              }
                            },
                      icon: Icon(CupertinoIcons.cloud_upload),
                      label: const Text('Exporter vers le cloud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gxRed.withOpacity(0.2),
                        foregroundColor: gxRed,
                        side: BorderSide(color: gxRed),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: syncService.isSyncing
                          ? null
                          : () async {
                              final success = await syncService.restoreConfigs();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Configurations restaurées'
                                        : 'Erreur lors de la restauration'),
                                  ),
                                );
                              }
                            },
                      icon: Icon(CupertinoIcons.cloud_download),
                      label: const Text('Restaurer depuis le cloud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SyncStatusWidget(syncService: syncService),
            ],
          ],
        );
      },
    );
  }

  // ============================================
  // SECTION ASSISTANT IA
  // ============================================
  
  Widget _buildAiSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Configuration Groq', gxRed),
            const SizedBox(height: 12),
            Text(
              'Configurez votre clé API Groq pour utiliser l\'assistant IA. L\'auto-switch de modèles est activé par défaut pour éviter les limites de quota.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 20),
            
            // Clé API
            _buildSubsectionTitle('Clé API Groq', gxRed),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: _settings.groqApiKey),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Clé API Groq',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                hintText: 'gsk_...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: gxRed),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: _settings.groqApiKey.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.check_mark_circled, size: 18),
                        color: Colors.green,
                        onPressed: () {},
                        tooltip: 'Clé API configurée',
                      )
                    : null,
              ),
              onChanged: (value) => _settings.setGroqApiKey(value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.info, size: 14, color: Colors.white60),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Obtenez votre clé API sur https://console.groq.com',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Ouvrir le lien dans le navigateur
                  },
                  child: const Text('Ouvrir', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // Auto-switch
            _buildSubsectionTitle('Auto-switch de modèles', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Activer l\'auto-switch',
              subtitle: 'Change automatiquement de modèle en cas de limite de quota',
              value: _settings.aiAutoSwitch,
              onChanged: (value) => _settings.setAiAutoSwitch(value),
              gxRed: gxRed,
            ),
            const SizedBox(height: 16),
            if (_settings.aiAutoSwitch) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les modèles seront automatiquement changés en cas de rate limit ou quota dépassé.',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            
            // Modèle préféré
            _buildSubsectionTitle('Modèle préféré', gxRed),
            const SizedBox(height: 12),
            Text(
              'Sélectionnez un modèle spécifique ou laissez vide pour utiliser l\'auto-sélection.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 12),
            _AiModelsSelector(gxRed: gxRed),
            const SizedBox(height: 28),
            
            // Fonctionnalités AI
            _buildSubsectionTitle('Fonctionnalités', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Assistant contextuel',
              subtitle: 'Utilise le contexte de la page pour améliorer les réponses',
              value: _settings.aiContextualEnabled,
              onChanged: (value) => _settings.setAiContextualEnabled(value),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Résumés automatiques',
              subtitle: 'Génère automatiquement des résumés de contenu',
              value: _settings.aiSummaryEnabled,
              onChanged: (value) => _settings.setAiSummaryEnabled(value),
              gxRed: gxRed,
            ),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Protection IA',
              subtitle: 'Filtre les contenus sensibles avant l\'envoi à l\'IA',
              value: _settings.aiProtectionEnabled,
              onChanged: (value) => _settings.setAiProtectionEnabled(value),
              gxRed: gxRed,
            ),
            const SizedBox(height: 28),
            
            // Mémoire glissante
            _buildSubsectionTitle('Mémoire contextuelle', gxRed),
            const SizedBox(height: 12),
            Text(
              'La mémoire glissante stocke automatiquement le contexte (site web, console, réseau) pour améliorer les réponses de l\'IA.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await _settings.clearAiSlidingMemory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Mémoire contextuelle vidée avec succès'),
                      backgroundColor: gxRed,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(CupertinoIcons.trash, size: 14),
              label: const Text('Vider la mémoire', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 28),
            
            // Test de connexion
            _buildSubsectionTitle('Test', gxRed),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _settings.groqApiKey.isEmpty
                  ? null
                  : () async {
                      final aiService = AiService();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Test de connexion en cours...'),
                          backgroundColor: gxRed,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      
                      final success = await aiService.testConnection();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success 
                                  ? 'Connexion réussie! L\'assistant IA est opérationnel.'
                                  : 'Erreur: ${aiService.lastError ?? "Impossible de se connecter"}',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
              icon: const Icon(CupertinoIcons.checkmark_circle_fill, size: 16),
              label: const Text('Tester la connexion', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: gxRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // SECTION COMPOSANTS GX
  // ============================================
  
  Widget _buildGxComponentsSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Composants Futuristes', gxRed),
            const SizedBox(height: 8),
            Text(
              'Configuration des composants avec style OS Science-Fiction',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 24),
            
            // Informations sur les composants
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: gxRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: gxRed, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Composants disponibles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildComponentInfo('GxFuturisticCard', 'Cartes avec contours géométriques'),
                  _buildComponentInfo('GxFuturisticInput', 'Champs de saisie futuristes'),
                  _buildComponentInfo('GxFuturisticBadge', 'Badges avec effet glow'),
                  _buildComponentInfo('GxFuturisticSwitch', 'Interrupteurs animés'),
                  _buildComponentInfo('GxFuturisticProgress', 'Barres de progression'),
                  _buildComponentInfo('GxFuturisticDialog', 'Dialogs avec animations'),
                  _buildComponentInfo('GxNotificationService', 'Système de notifications'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Lien vers le panel de test
            _buildSubsectionTitle('Panel de Test', gxRed),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Testez tous les composants',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ouvrez le panel de test depuis la sidebar pour voir tous les composants en action.',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Fermer les paramètres et ouvrir le panel de test
                      Navigator.of(context).pop();
                      // Le panel sera ouvert via la sidebar
                    },
                    icon: const Icon(Icons.science_rounded, size: 14),
                    label: const Text('Ouvrir le panel de test', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gxRed,
                      side: BorderSide(color: gxRed.withOpacity(0.5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Documentation
            _buildSubsectionTitle('Documentation', gxRed),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guide d\'utilisation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consultez le fichier GX_FUTURISTIC_COMPONENTS_README.md pour des exemples d\'utilisation détaillés.',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildComponentInfo(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: NotilusColors.getSecondaryColor(context),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SECTION NOTIFICATIONS
  // ============================================
  
  Widget _buildNotificationsSection(BuildContext context, ThemeData theme, Color gxRed) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final positions = {
          'top-right': 'Haut droite',
          'top-left': 'Haut gauche',
          'bottom-right': 'Bas droite',
          'bottom-left': 'Bas gauche',
        };
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Position', gxRed),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: positions.entries.map((entry) {
                final isSelected = _settings.notificationPosition == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (_) => _settings.setNotificationPosition(entry.key),
                  selectedColor: gxRed.withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  side: BorderSide(color: isSelected ? gxRed : Colors.white24),
                  labelStyle: TextStyle(color: isSelected ? gxRed : Colors.white70, fontSize: 11),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            
            _buildSubsectionTitle('Son', gxRed),
            const SizedBox(height: 12),
            _buildSettingSwitch(
              title: 'Activer le son',
              subtitle: 'Jouer un son lors de l\'affichage d\'une notification',
              value: _settings.notificationSoundEnabled,
              onChanged: (value) => _settings.setNotificationSoundEnabled(value),
              gxRed: gxRed,
            ),
            const SizedBox(height: 16),
            if (_settings.notificationSoundEnabled) ...[
              Row(
                children: [
                  const Text('Volume', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _settings.notificationVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      activeColor: gxRed,
                      inactiveColor: Colors.white.withOpacity(0.1),
                      onChanged: (value) => _settings.setNotificationVolume(value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(_settings.notificationVolume * 100).toInt()}%',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            
            _buildSubsectionTitle('Affichage', gxRed),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Durée d\'affichage', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _settings.notificationDuration.toDouble(),
                    min: 2.0,
                    max: 10.0,
                    divisions: 8,
                    activeColor: gxRed,
                    inactiveColor: Colors.white.withOpacity(0.1),
                    onChanged: (value) => _settings.setNotificationDuration(value.toInt()),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_settings.notificationDuration}s',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Nombre maximum visible', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _settings.notificationMaxVisible.toDouble(),
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    activeColor: gxRed,
                    inactiveColor: Colors.white.withOpacity(0.1),
                    onChanged: (value) => _settings.setNotificationMaxVisible(value.toInt()),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_settings.notificationMaxVisible}',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // Test de notification
            _buildSubsectionTitle('Test', gxRed),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    GxNotificationService().showSuccess(
                      title: 'Notification de test',
                      message: 'Ceci est une notification de succès',
                      context: context,
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Test Succès', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    GxNotificationService().showError(
                      title: 'Notification de test',
                      message: 'Ceci est une notification d\'erreur',
                      context: context,
                    );
                  },
                  icon: const Icon(Icons.error_rounded, size: 16),
                  label: const Text('Test Erreur', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    GxNotificationService().showWarning(
                      title: 'Notification de test',
                      message: 'Ceci est une notification d\'avertissement',
                      context: context,
                    );
                  },
                  icon: const Icon(Icons.warning_rounded, size: 16),
                  label: const Text('Test Avertissement', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    GxNotificationService().showInfo(
                      title: 'Notification de test',
                      message: 'Ceci est une notification d\'information',
                      context: context,
                    );
                  },
                  icon: const Icon(Icons.info_rounded, size: 16),
                  label: const Text('Test Info', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // SECTION À PROPOS
  // ============================================
  
  Widget _buildAboutSection(BuildContext context, ThemeData theme, Color gxRed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gxRed, gxRed.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gxRed.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Notilus Browser',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0 Beta',
                style: TextStyle(color: gxRed, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Build futuriste expérimental',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSubsectionTitle('Informations', gxRed),
        const SizedBox(height: 12),
        _buildInfoRow('Moteur', 'WebView2 / WebKit'),
        _buildInfoRow('Framework', 'Flutter 3.x'),
        _buildInfoRow('Plateforme', 'Windows, macOS, Linux'),
        const SizedBox(height: 24),
        _buildSubsectionTitle('Réinitialisation', gxRed),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _settings.resetAppearanceSettings(),
              icon: const Icon(CupertinoIcons.paintbrush, size: 14),
              label: const Text('Apparence', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: gxRed,
                side: BorderSide(color: gxRed.withOpacity(0.5)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _settings.resetPrivacySettings(),
              icon: const Icon(CupertinoIcons.shield, size: 14),
              label: const Text('Confidentialité', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: gxRed,
                side: BorderSide(color: gxRed.withOpacity(0.5)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF15151A),
                    title: const Text('Réinitialiser tout', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Cette action va réinitialiser tous les paramètres aux valeurs par défaut.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          _settings.resetAllSettings();
                          Navigator.pop(ctx);
                        },
                        child: Text('Réinitialiser', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.refresh, size: 14),
              label: const Text('Tout réinitialiser', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // ============================================
  // WIDGETS UTILITAIRES
  // ============================================
  
  Widget _buildSubsectionTitle(String title, Color gxRed) {
    return Text(
      title,
      style: TextStyle(
        color: gxRed,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  // ============================================
  // SECTION TTS (Text-to-Speech)
  // ============================================
  
  Widget _buildTtsSection(BuildContext context, ThemeData theme, Color gxRed) {
    final ttsService = TtsService(baseUrl: _settings.ttsBackendUrl);
    
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statut de connexion
                _buildSubsectionTitle('Connexion', gxRed),
                const SizedBox(height: 12),
                FutureBuilder<bool>(
                  future: ttsService.checkConnection(),
                  builder: (context, snapshot) {
                    final isConnected = snapshot.data ?? false;
                    return Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'Backend TTS connecté' : 'Backend TTS non disponible',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {});
                            ttsService.checkConnection();
                          },
                          child: const Text('Vérifier', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                
                // Activation du service
                _buildSubsectionTitle('Activation', gxRed),
                const SizedBox(height: 12),
                _buildSettingSwitch(
                  title: 'Activer la synthèse vocale',
                  subtitle: 'Permet d\'utiliser le service TTS pour lire du texte',
                  value: _settings.ttsEnabled,
                  onChanged: (value) => _settings.setTtsEnabled(value),
                  gxRed: gxRed,
                ),
                const SizedBox(height: 28),
                
                if (_settings.ttsEnabled) ...[
                  // Configuration de la voix
                  _buildSubsectionTitle('Voix par défaut', gxRed),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: ttsService.getVoices(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final voices = snapshot.data ?? [];
                      final currentVoice = _settings.ttsDefaultVoice;
                      
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: DropdownButton<String>(
                              value: currentVoice,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1A1A1A),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              underline: const SizedBox(),
                              items: voices.map((voice) {
                                final shortName = voice['ShortName'] as String? ?? '';
                                final name = voice['Name'] as String? ?? shortName;
                                final locale = voice['Locale'] as String? ?? '';
                                final gender = voice['Gender'] as String? ?? '';
                                
                                return DropdownMenuItem<String>(
                                  value: shortName,
                                  child: Text('$name ($locale, $gender)'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _settings.setTtsDefaultVoice(value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {});
                              ttsService.getVoices(forceRefresh: true);
                            },
                            icon: const Icon(CupertinoIcons.arrow_clockwise, size: 14),
                            label: const Text('Actualiser la liste', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  
                  // Détection automatique
                  _buildSubsectionTitle('Détection automatique', gxRed),
                  const SizedBox(height: 12),
                  _buildSettingSwitch(
                    title: 'Détecter automatiquement la langue',
                    subtitle: 'Sélectionne automatiquement une voix selon la langue du texte',
                    value: _settings.ttsAutoDetectLanguage,
                    onChanged: (value) => _settings.setTtsAutoDetectLanguage(value),
                    gxRed: gxRed,
                  ),
                  const SizedBox(height: 16),
                  if (_settings.ttsAutoDetectLanguage) ...[
                    _buildSubsectionTitle('Genre préféré', gxRed),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Féminin'),
                          selected: _settings.ttsPreferredGender == 'Female',
                          onSelected: (_) => _settings.setTtsPreferredGender('Female'),
                          selectedColor: gxRed.withOpacity(0.2),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          side: BorderSide(
                            color: _settings.ttsPreferredGender == 'Female' ? gxRed : Colors.white24,
                          ),
                          labelStyle: TextStyle(
                            color: _settings.ttsPreferredGender == 'Female' ? gxRed : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Masculin'),
                          selected: _settings.ttsPreferredGender == 'Male',
                          onSelected: (_) => _settings.setTtsPreferredGender('Male'),
                          selectedColor: gxRed.withOpacity(0.2),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          side: BorderSide(
                            color: _settings.ttsPreferredGender == 'Male' ? gxRed : Colors.white24,
                          ),
                          labelStyle: TextStyle(
                            color: _settings.ttsPreferredGender == 'Male' ? gxRed : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  
                  // Paramètres audio
                  _buildSubsectionTitle('Paramètres audio', gxRed),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Volume', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _settings.ttsVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          activeColor: gxRed,
                          inactiveColor: Colors.white.withOpacity(0.1),
                          onChanged: (value) => _settings.setTtsVolume(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(_settings.ttsVolume * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Vitesse', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _settings.ttsSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          activeColor: gxRed,
                          inactiveColor: Colors.white.withOpacity(0.1),
                          onChanged: (value) => _settings.setTtsSpeed(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_settings.ttsSpeed.toStringAsFixed(1)}x',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Configuration backend
                  _buildSubsectionTitle('Configuration backend', gxRed),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: _settings.ttsBackendUrl),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'URL du backend TTS',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                      hintText: 'http://localhost:8000',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: gxRed),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (value) => _settings.setTtsBackendUrl(value),
                  ),
                  const SizedBox(height: 28),
                  
                  // Test
                  _buildSubsectionTitle('Test', gxRed),
                  const SizedBox(height: 12),
                  _TtsTestButton(
                    ttsService: ttsService,
                    voice: _settings.ttsDefaultVoice,
                    gxRed: gxRed,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // Widget pour le bouton de test TTS avec lecture audio
  Widget _TtsTestButton({
    required TtsService ttsService,
    required String voice,
    required Color gxRed,
  }) {
    return _TtsTestButtonStateful(
      ttsService: ttsService,
      voice: voice,
      gxRed: gxRed,
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color gxRed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: gxRed,
            activeTrackColor: gxRed.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// Widget pour sélectionner les modèles AI avec rafraîchissement
class _AiModelsSelector extends StatefulWidget {
  final Color gxRed;
  
  const _AiModelsSelector({required this.gxRed});
  
  @override
  State<_AiModelsSelector> createState() => _AiModelsSelectorState();
}

class _AiModelsSelectorState extends State<_AiModelsSelector> {
  final AiService _aiService = AiService();
  final SettingsService _settings = SettingsService();
  Future<List<String>?>? _modelsFuture;
  
  @override
  void initState() {
    super.initState();
    _loadModels();
  }
  
  void _loadModels() {
    setState(() {
      _modelsFuture = _aiService.getModels();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>?>(
      future: _modelsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final models = snapshot.data ?? [];
        final currentModel = _settings.aiPreferredModel;
        
        if (models.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Impossible de charger les modèles. Vérifiez la connexion au backend.',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                TextButton(
                  onPressed: _loadModels,
                  child: const Text('Réessayer', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<String>(
                value: currentModel.isEmpty ? null : (models.contains(currentModel) ? currentModel : null),
                isExpanded: true,
                hint: const Text(
                  'Auto-sélection (recommandé)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Auto-sélection (recommandé)'),
                  ),
                  ...models.map((model) {
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(model),
                    );
                  }),
                ],
                onChanged: (value) {
                  _settings.setAiPreferredModel(value ?? '');
                },
              ),
            ),
            const SizedBox(height: 12),
            if (models.isNotEmpty) ...[
              Text(
                'Modèles disponibles (${models.length}):',
                style: TextStyle(color: Colors.white60, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: models.map((model) {
                  final shortName = model.split('-').take(2).join('-');
                  final isSelected = currentModel == model;
                  return ChoiceChip(
                    label: Text(shortName, style: const TextStyle(fontSize: 10)),
                    selected: isSelected,
                    onSelected: (_) {
                      _settings.setAiPreferredModel(isSelected ? '' : model);
                    },
                    selectedColor: widget.gxRed.withOpacity(0.2),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    side: BorderSide(
                      color: isSelected ? widget.gxRed : Colors.white24,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? widget.gxRed : Colors.white70,
                      fontSize: 10,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _loadModels,
                    icon: const Icon(CupertinoIcons.arrow_clockwise, size: 14),
                    label: const Text('Actualiser la liste', style: TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// Widget Stateful pour le bouton de test TTS avec lecture audio
class _TtsTestButtonStateful extends StatefulWidget {
  final TtsService ttsService;
  final String voice;
  final Color gxRed;
  
  const _TtsTestButtonStateful({
    required this.ttsService,
    required this.voice,
    required this.gxRed,
  });
  
  @override
  State<_TtsTestButtonStateful> createState() => _TtsTestButtonStatefulState();
}

class _TtsTestButtonStatefulState extends State<_TtsTestButtonStateful> {
  bool _isPlaying = false;
  final AudioPlayer _player = AudioPlayer();
  
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  
  Future<void> _testVoice() async {
    setState(() => _isPlaying = true);
    final testText = 'Bonjour, ceci est un test de synthèse vocale.';
    
    try {
      final audioData = await widget.ttsService.generateTts(
        text: testText,
        voice: widget.voice,
      );
      
      if (audioData != null && mounted) {
        // Sauvegarder temporairement le fichier audio
        final tempDir = await getTemporaryDirectory();
        final fileName = 'tts_test_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(audioData);
        
        // Pour Windows, utiliser le chemin absolu du fichier
        // Convertir les backslashes en forward slashes pour l'URL
        final filePath = file.absolute.path.replaceAll('\\', '/');
        // Utiliser file:/// avec 3 slashes pour Windows
        final fileUrl = Platform.isWindows 
            ? 'file:///$filePath' 
            : 'file://$filePath';
        
        await _player.setSource(UrlSource(fileUrl));
        await _player.resume();
        
        // Attendre la fin de la lecture
        _player.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() => _isPlaying = false);
          }
          file.delete(); // Nettoyer le fichier temporaire
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Lecture de l\'audio en cours...'),
              backgroundColor: widget.gxRed,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${widget.ttsService.lastError ?? "Impossible de générer l\'audio"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la lecture: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isPlaying ? null : _testVoice,
      icon: Icon(
        _isPlaying ? CupertinoIcons.stop_circle : CupertinoIcons.play_circle,
        size: 16,
      ),
      label: Text(
        _isPlaying ? 'Lecture...' : 'Tester la voix actuelle',
        style: const TextStyle(fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.gxRed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
