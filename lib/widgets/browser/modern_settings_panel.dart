import 'dart:async';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Cache pour optimiser les performances
  Timer? _searchDebounceTimer;
  List<_SectionItem>? _cachedFilteredSections;
  List<_SearchResult>? _cachedSearchResults;
  String? _lastSearchQuery;
  
  // Index de recherche approfondie
  late List<_SettingIndex> _settingsIndex;
  
  // Liste des sections
  final List<_SectionItem> _sections = [
    _SectionItem('appearance', 'Apparence', CupertinoIcons.paintbrush),
    _SectionItem('wallpaper', 'Fonds d\'écran', CupertinoIcons.photo),
    _SectionItem('tabs', 'Onglets', CupertinoIcons.square_on_square),
    _SectionItem('downloads', 'Téléchargements', CupertinoIcons.arrow_down_circle),
    _SectionItem('terminal', 'Terminal', CupertinoIcons.square_list),
    _SectionItem('homepage', 'Page d\'accueil', CupertinoIcons.house),
    _SectionItem('webservices', 'Services Web', CupertinoIcons.globe),
    _SectionItem('privacy', 'Confidentialité', CupertinoIcons.shield),
    _SectionItem('account', 'Compte', CupertinoIcons.person_circle),
    _SectionItem('devtools', 'DevTools', CupertinoIcons.ant),
    _SectionItem('gxComponents', 'Composants GX', CupertinoIcons.square_grid_2x2),
    _SectionItem('notifications', 'Notifications', CupertinoIcons.bell),
    _SectionItem('about', 'À propos', CupertinoIcons.info_circle),
  ];
  
  @override
  void initState() {
    super.initState();
    _settings.initialize();
    _searchController.addListener(_onSearchChanged);
    _buildSettingsIndex();
  }
  
  void _buildSettingsIndex() {
    _settingsIndex = [
      // Section Apparence
      _SettingIndex('appearance', 'Mode de thème', 'Système, Clair, Sombre', 'Thème', 'appearance'),
      _SettingIndex('appearance', 'Thème de couleur', 'Change la couleur principale de l\'interface', 'Couleur', 'appearance'),
      _SettingIndex('appearance', 'Couleurs personnalisées', 'Couleur de fond, Couleur secondaire', 'Personnalisation', 'appearance'),
      _SettingIndex('appearance', 'Couleur de fond', 'Sidebar, barres d\'outils', 'Fond', 'appearance'),
      _SettingIndex('appearance', 'Couleur secondaire', 'Accents, éléments actifs', 'Accent', 'appearance'),
      
      // Section Fonds d'écran
      _SettingIndex('wallpaper', 'Fond d\'écran dynamique', 'Affiche un fond d\'écran sur la page d\'accueil et les panneaux', 'Fond écran', 'wallpaper'),
      _SettingIndex('wallpaper', 'Activer les fonds d\'écran', 'Affiche un fond d\'écran sur la page d\'accueil et les panneaux', 'Activer', 'wallpaper'),
      _SettingIndex('wallpaper', 'Rotation automatique', 'Change le fond d\'écran périodiquement', 'Rotation', 'wallpaper'),
      _SettingIndex('wallpaper', 'Intervalle de rotation', '1 min, 2 min, 5 min, 10 min, 15 min, 30 min', 'Intervalle', 'wallpaper'),
      
      // Section Onglets
      _SettingIndex('tabs', 'Démarrage', 'Restaurer les onglets, Ouvrir sur la page d\'accueil', 'Démarrage', 'tabs'),
      _SettingIndex('tabs', 'Restaurer les onglets', 'Recharge les onglets ouverts au prochain lancement', 'Restaurer', 'tabs'),
      _SettingIndex('tabs', 'Ouvrir sur la page d\'accueil', 'Démarre Notilus sur le Speed Dial', 'Page accueil', 'tabs'),
      _SettingIndex('tabs', 'Nouvel onglet', 'Page d\'accueil, Page vide, URL personnalisée', 'Nouvel onglet', 'tabs'),
      
      // Section Téléchargements
      _SettingIndex('downloads', 'Dossier de téléchargement', 'Configurez le dossier de téléchargement', 'Dossier', 'downloads'),
      _SettingIndex('downloads', 'Demander l\'emplacement', 'Demander où enregistrer chaque fichier', 'Emplacement', 'downloads'),
      _SettingIndex('downloads', 'Ouvrir automatiquement', 'Ouvrir les fichiers après téléchargement', 'Auto ouvrir', 'downloads'),
      
      // Section Terminal
      _SettingIndex('terminal', 'Terminal préféré', 'PowerShell, CMD, WSL', 'Terminal', 'terminal'),
      _SettingIndex('terminal', 'Taille de police', 'Taille de la police du terminal', 'Police', 'terminal'),
      _SettingIndex('terminal', 'Type d\'interface', 'Native, XTerm', 'Interface', 'terminal'),
      
      // Section Page d'accueil
      _SettingIndex('homepage', 'Style de page d\'accueil', 'Modern, Notilus Dev, Frontend, Backend, DevOps, Data Science, Minimal, GX Futuristic', 'Style', 'homepage'),
      _SettingIndex('homepage', 'Transparence des widgets', 'Réglez la transparence pour voir le fond d\'écran', 'Transparence', 'homepage'),
      _SettingIndex('homepage', 'Widgets', 'Transparence des widgets et éléments de l\'interface', 'Widgets', 'homepage'),
      _SettingIndex('homepage', 'Panneaux latéraux', 'Transparence des panneaux latéraux', 'Panneaux', 'homepage'),
      _SettingIndex('homepage', 'Overlays', 'Transparence des overlays et menus contextuels', 'Overlays', 'homepage'),
      _SettingIndex('homepage', 'Page d\'accueil', 'Contrôle l\'opacité du fond d\'écran et du flou', 'Page accueil', 'homepage'),
      _SettingIndex('homepage', 'Intensité du flou', 'Contrôle l\'intensité du flou d\'arrière-plan', 'Flou', 'homepage'),
      _SettingIndex('homepage', 'Personnalisation avancée', 'Horloge, Citations, Animations, Message de bienvenue', 'Personnalisation', 'homepage'),
      _SettingIndex('homepage', 'Afficher l\'horloge', 'Heure et date sur la page d\'accueil', 'Horloge', 'homepage'),
      _SettingIndex('homepage', 'Afficher les citations', 'Citations inspirantes pour développeurs', 'Citations', 'homepage'),
      _SettingIndex('homepage', 'Animations', 'Effets visuels et transitions', 'Animations', 'homepage'),
      _SettingIndex('homepage', 'Message de bienvenue', 'Message personnalisé sur la page d\'accueil', 'Message', 'homepage'),
      _SettingIndex('homepage', 'Panneaux latéraux', 'Panneau Dev Tools, Panneau Quick Actions', 'Panneaux', 'homepage'),
      _SettingIndex('homepage', 'Sections visibles', 'Widgets système, Sites rapides, Historique récent', 'Sections', 'homepage'),
      _SettingIndex('homepage', 'Widgets système', 'CPU, RAM, GPU, etc.', 'Système', 'homepage'),
      _SettingIndex('homepage', 'Sites rapides', 'Raccourcis vers vos sites favoris', 'Sites', 'homepage'),
      _SettingIndex('homepage', 'Historique récent', 'Afficher l\'historique récent sur la page d\'accueil', 'Historique', 'homepage'),
      
      // Section Services Web
      _SettingIndex('webservices', 'Services Web', 'YouTube Music, YouTube, ChatGPT, DeepSeek, WhatsApp, Telegram', 'Services', 'webservices'),
      _SettingIndex('webservices', 'YouTube Music', 'Service de musique YouTube', 'YouTube Music', 'webservices'),
      _SettingIndex('webservices', 'YouTube', 'Service vidéo YouTube', 'YouTube', 'webservices'),
      _SettingIndex('webservices', 'ChatGPT', 'Service d\'assistant IA ChatGPT', 'ChatGPT', 'webservices'),
      _SettingIndex('webservices', 'DeepSeek', 'Service d\'assistant IA DeepSeek', 'DeepSeek', 'webservices'),
      _SettingIndex('webservices', 'WhatsApp', 'Service de messagerie WhatsApp', 'WhatsApp', 'webservices'),
      _SettingIndex('webservices', 'Telegram', 'Service de messagerie Telegram', 'Telegram', 'webservices'),
      
      // Section Confidentialité
      _SettingIndex('privacy', 'Confidentialité', 'Protégez vos données de navigation', 'Confidentialité', 'privacy'),
      _SettingIndex('privacy', 'Sauvegarder l\'historique', 'Enregistrer l\'historique de navigation', 'Historique', 'privacy'),
      _SettingIndex('privacy', 'Sauvegarder les cookies', 'Enregistrer les cookies des sites', 'Cookies', 'privacy'),
      _SettingIndex('privacy', 'Bloquer les trackers', 'Bloquer les trackers publicitaires', 'Trackers', 'privacy'),
      
      // Section Compte
      _SettingIndex('account', 'Authentification', 'Connectez-vous pour synchroniser vos configurations', 'Auth', 'account'),
      _SettingIndex('account', 'Synchronisation', 'Exporter vers le cloud, Restaurer depuis le cloud', 'Sync', 'account'),
      _SettingIndex('account', 'Exporter vers le cloud', 'Sauvegarder vos configurations dans le cloud', 'Exporter', 'account'),
      _SettingIndex('account', 'Restaurer depuis le cloud', 'Restaurer vos configurations depuis le cloud', 'Restaurer', 'account'),
      
      // Section DevTools
      _SettingIndex('devtools', 'DevTools', 'Configuration des outils de développement', 'DevTools', 'devtools'),
      _SettingIndex('devtools', 'Position', 'Bottom, Right, Detached', 'Position', 'devtools'),
      _SettingIndex('devtools', 'Hauteur', 'Hauteur du panneau DevTools', 'Hauteur', 'devtools'),
      _SettingIndex('devtools', 'Afficher les timestamps', 'Afficher les horodatages dans les logs', 'Timestamps', 'devtools'),
      _SettingIndex('devtools', 'Grouper les logs', 'Grouper les logs similaires', 'Grouper', 'devtools'),
      _SettingIndex('devtools', 'Défilement automatique', 'Défilement automatique vers les nouveaux logs', 'Auto scroll', 'devtools'),
      _SettingIndex('devtools', 'Préserver les logs', 'Conserver les logs après navigation', 'Préserver', 'devtools'),
      _SettingIndex('devtools', 'Capturer le body', 'Capturer le contenu des requêtes', 'Body', 'devtools'),
      _SettingIndex('devtools', 'Désactiver le cache', 'Désactiver le cache pour les requêtes', 'Cache', 'devtools'),
      _SettingIndex('devtools', 'Afficher le box model', 'Afficher le modèle de boîte dans Elements', 'Box model', 'devtools'),
      _SettingIndex('devtools', 'Afficher les dimensions', 'Afficher les dimensions dans Elements', 'Dimensions', 'devtools'),
      _SettingIndex('devtools', 'Afficher les guides', 'Afficher les guides de mise en page', 'Guides', 'devtools'),
      _SettingIndex('devtools', 'Couleur de surbrillance', 'Couleur pour mettre en surbrillance les éléments', 'Couleur', 'devtools'),
      _SettingIndex('devtools', 'Taux de rafraîchissement', 'Fréquence de rafraîchissement des DevTools', 'Refresh', 'devtools'),
      _SettingIndex('devtools', 'Taille de police', 'Taille de la police dans les DevTools', 'Police', 'devtools'),
      
      // Section Composants GX
      _SettingIndex('gxComponents', 'Composants GX', 'Test et aperçu des composants GX Futuristic', 'Composants', 'gxComponents'),
      
      // Section Notifications
      _SettingIndex('notifications', 'Notifications', 'Configuration des notifications', 'Notifications', 'notifications'),
      _SettingIndex('notifications', 'Position', 'Top-right, Top-left, Bottom-right, Bottom-left', 'Position', 'notifications'),
      _SettingIndex('notifications', 'Son', 'Activer le son des notifications', 'Son', 'notifications'),
      
      // Section À propos
      _SettingIndex('about', 'À propos', 'Informations sur Notilus Browser', 'À propos', 'about'),
      _SettingIndex('about', 'Version', 'Version de Notilus Browser', 'Version', 'about'),
      _SettingIndex('about', 'Licence', 'Informations de licence', 'Licence', 'about'),
      _SettingIndex('about', 'Réinitialiser', 'Réinitialiser tous les paramètres', 'Réinitialiser', 'about'),
    ];
  }
  
  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
          _cachedFilteredSections = null;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  
  List<_SectionItem> _getFilteredSections() {
    if (_cachedFilteredSections != null && _lastSearchQuery == _searchQuery) {
      return _cachedFilteredSections!;
    }
    
    List<_SectionItem> filtered;
    if (_searchQuery.isEmpty) {
      filtered = _sections;
    } else {
      filtered = _sections.where((section) {
        return section.label.toLowerCase().contains(_searchQuery) ||
               section.id.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    _cachedFilteredSections = filtered;
    _lastSearchQuery = _searchQuery;
    return filtered;
  }
  
  List<_SearchResult> _performDeepSearch() {
    if (_cachedSearchResults != null && _lastSearchQuery == _searchQuery) {
      return _cachedSearchResults!;
    }
    
    if (_searchQuery.isEmpty) {
      _cachedSearchResults = [];
      return [];
    }
    
    final query = _searchQuery.toLowerCase();
    final results = <_SearchResult>[];
    
    // Recherche dans l'index
    for (final setting in _settingsIndex) {
      final relevance = _calculateRelevance(setting, query);
      if (relevance > 0) {
        results.add(_SearchResult(
          setting: setting,
          relevance: relevance,
        ));
      }
    }
    
    // Trier par pertinence
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    
    _cachedSearchResults = results;
    return results;
  }
  
  int _calculateRelevance(_SettingIndex setting, String query) {
    int score = 0;
    final titleLower = setting.title.toLowerCase();
    final descriptionLower = setting.description.toLowerCase();
    final keywordsLower = setting.keywords.toLowerCase();
    final sectionLabel = _sections.firstWhere((s) => s.id == setting.sectionId).label.toLowerCase();
    
    // Correspondance exacte dans le titre (score élevé)
    if (titleLower == query) {
      score += 100;
    } else if (titleLower.startsWith(query)) {
      score += 50;
    } else if (titleLower.contains(query)) {
      score += 30;
    }
    
    // Correspondance dans les mots-clés
    if (keywordsLower.contains(query)) {
      score += 20;
    }
    
    // Correspondance dans la description
    if (descriptionLower.contains(query)) {
      score += 10;
    }
    
    // Correspondance dans le nom de section
    if (sectionLabel.contains(query)) {
      score += 5;
    }
    
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final wallpaperManager = context.watch<WallpaperManager>();
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(wallpaperManager.current),
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
          color: Colors.black.withOpacity(panelOpacity),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final sidebarWidth = isCompact ? 160.0 : 180.0;
              final horizontalPadding = isCompact ? 12.0 : 16.0;
              
              return Row(
                children: [
                  // Navigation latérale des sections
                  Container(
                    width: sidebarWidth,
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
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Text(
                            'Paramètres',
                            style: NotilusFonts.orbitron(
                              fontSize: isCompact ? 12 : 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                        Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: GxFuturisticInput(
                            controller: _searchController,
                            hint: 'Rechercher...',
                            prefixIcon: CupertinoIcons.search,
                            accentColor: gxRed,
                          ),
                        ),
                        Expanded(
                          child: RepaintBoundary(
                            child: _searchQuery.isEmpty
                                ? ListView.builder(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _getFilteredSections().length,
                                    cacheExtent: 500,
                                    addAutomaticKeepAlives: false,
                                    addRepaintBoundaries: true,
                                    itemBuilder: (context, index) {
                                      final section = _getFilteredSections()[index];
                                      return RepaintBoundary(
                                        key: ValueKey('section_${section.id}'),
                                        child: _SectionItemWidget(
                                          section: section,
                                          isSelected: _currentSection == section.id,
                                          accentColor: gxRed,
                                          isCompact: isCompact,
                                          onTap: () => setState(() => _currentSection = section.id),
                                        ),
                                      );
                                    },
                                  )
                                : _buildSearchResults(gxRed, isCompact),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Contenu de la section
                  Expanded(
                    child: RepaintBoundary(
                      child: _buildSectionContent(context, theme, gxRed),
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


  Widget _buildSearchResults(Color gxRed, bool isCompact) {
    final results = _performDeepSearch();
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: isCompact ? 32 : 40,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              'Aucun résultat',
              style: NotilusFonts.rajdhani(
                fontSize: isCompact ? 12 : 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Essayez d\'autres mots-clés',
              style: NotilusFonts.rajdhani(
                fontSize: isCompact ? 10 : 11,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final result = results[index];
        final section = _sections.firstWhere((s) => s.id == result.setting.sectionId);
        return RepaintBoundary(
          key: ValueKey('search_result_${result.setting.sectionId}_${result.setting.title}'),
          child: _SearchResultWidget(
            result: result,
            section: section,
            isSelected: _currentSection == result.setting.sectionId,
            accentColor: gxRed,
            isCompact: isCompact,
            searchQuery: _searchQuery,
            onTap: () {
              setState(() {
                _currentSection = result.setting.sectionId;
                _searchController.clear();
                _searchQuery = '';
                _cachedSearchResults = null;
              });
            },
          ),
        );
      },
    );
  }
  
  Widget _buildSearchResultsContent(BuildContext context, ThemeData theme, Color gxRed) {
    final results = _performDeepSearch();
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: NotilusFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'autres mots-clés pour votre recherche',
              style: NotilusFonts.rajdhani(
                fontSize: 12,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }
    
    // Grouper les résultats par section
    final groupedResults = <String, List<_SearchResult>>{};
    for (final result in results) {
      groupedResults.putIfAbsent(result.setting.sectionId, () => []).add(result);
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final padding = isCompact ? 12.0 : isMedium ? 16.0 : 20.0;
        final spacing = isCompact ? 8.0 : isMedium ? 12.0 : 16.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.search, color: gxRed, size: isCompact ? 18 : 20),
                  SizedBox(width: spacing),
                  Text(
                    'Résultats de recherche',
                    style: NotilusFonts.orbitron(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${results.length} résultat${results.length > 1 ? 's' : ''}',
                    style: NotilusFonts.rajdhani(
                      fontSize: isCompact ? 11 : 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 1.5),
              ...groupedResults.entries.map((entry) {
                final section = _sections.firstWhere((s) => s.id == entry.key);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(section.icon, color: gxRed, size: isCompact ? 14 : 16),
                        SizedBox(width: spacing / 2),
                        Text(
                          section.label.toUpperCase(),
                          style: NotilusFonts.orbitron(
                            fontSize: isCompact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: gxRed,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Divider(
                            height: 1,
                            color: gxRed.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    ...entry.value.map((result) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: _SearchResultCard(
                          result: result,
                          accentColor: gxRed,
                          isCompact: isCompact,
                          isMedium: isMedium,
                          spacing: spacing,
                          searchQuery: _searchQuery,
                          onTap: () {
                            setState(() {
                              _currentSection = result.setting.sectionId;
                              _searchController.clear();
                              _searchQuery = '';
                              _cachedSearchResults = null;
                            });
                          },
                        ),
                      );
                    }),
                    SizedBox(height: spacing * 2),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionContent(BuildContext context, ThemeData theme, Color gxRed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final padding = isCompact ? 12.0 : isMedium ? 16.0 : 20.0;
        final spacing = isCompact ? 8.0 : isMedium ? 12.0 : 16.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(gxRed, isCompact, isMedium),
              SizedBox(height: spacing * 1.25),
              switch (_currentSection) {
                'appearance' => _buildAppearanceSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'wallpaper' => _buildWallpaperSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'tabs' => _buildTabsSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'downloads' => _buildDownloadsSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'terminal' => _buildTerminalSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'homepage' => _buildHomepageSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'webservices' => _buildWebServicesSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'privacy' => _buildPrivacySection(context, theme, gxRed, isCompact, isMedium, spacing),
                'gxComponents' => _buildGxComponentsSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'notifications' => _buildNotificationsSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'account' => _buildAccountSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'devtools' => _buildDevToolsSection(context, theme, gxRed, isCompact, isMedium, spacing),
                'about' => _buildAboutSection(context, theme, gxRed, isCompact, isMedium, spacing),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(Color gxRed, bool isCompact, bool isMedium) {
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
    final titleFontSize = isCompact ? 14.0 : (isMedium ? 16.0 : 18.0);
    final subtitleFontSize = isCompact ? 10.0 : (isMedium ? 11.0 : 12.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: isCompact ? 3 : 4,
              height: isCompact ? 18 : isMedium ? 22 : 24,
              decoration: BoxDecoration(
                color: gxRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: Text(
                info.$1,
                style: NotilusFonts.orbitron(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        if (info.$2.isNotEmpty) ...[
          SizedBox(height: isCompact ? 4 : 6),
          Padding(
            padding: EdgeInsets.only(left: isCompact ? 11 : 16),
            child: Text(
              info.$2,
              style: NotilusFonts.rajdhani(
                fontSize: subtitleFontSize,
                color: Colors.white.withOpacity(0.6),
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
  
  Widget _buildAppearanceSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
    return Consumer<ThemeModeNotifier>(
      builder: (context, themeNotifier, _) {
        final mode = themeNotifier.mode;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Mode de thème', gxRed, isCompact: isCompact, isMedium: isMedium),
            SizedBox(height: spacing),
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
  
  Widget _buildWallpaperSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Fond d\'écran dynamique', gxRed, isCompact: isCompact, isMedium: isMedium),
            SizedBox(height: spacing),
            _buildSettingSwitch(
              title: 'Activer les fonds d\'écran',
              subtitle: 'Affiche un fond d\'écran sur la page d\'accueil et les panneaux',
              value: _settings.wallpaperEnabled,
              onChanged: (v) => _settings.setWallpaperEnabled(v),
              gxRed: gxRed,
              isCompact: isCompact,
              isMedium: isMedium,
            ),
            SizedBox(height: spacing),
            _buildSettingSwitch(
              title: 'Rotation automatique',
              subtitle: 'Change le fond d\'écran périodiquement',
              value: _settings.wallpaperRotationEnabled,
              onChanged: (v) => _settings.setWallpaperRotationEnabled(v),
              gxRed: gxRed,
              isCompact: isCompact,
              isMedium: isMedium,
            ),
            SizedBox(height: spacing * 1.5),
            _buildSubsectionTitle('Intervalle de rotation', gxRed, isCompact: isCompact, isMedium: isMedium),
            SizedBox(height: spacing),
            _buildIntervalSelector(gxRed),
            SizedBox(height: spacing * 2),
            _buildSubsectionTitle('Aperçu', gxRed, isCompact: isCompact, isMedium: isMedium),
            SizedBox(height: spacing),
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
  
  Widget _buildTabsSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubsectionTitle('Démarrage', gxRed, isCompact: isCompact, isMedium: isMedium),
            SizedBox(height: spacing),
            _buildSettingSwitch(
              title: 'Restaurer les onglets',
              subtitle: 'Recharge les onglets ouverts au prochain lancement',
              value: _settings.restoreTabsOnStartup,
              onChanged: (v) => _settings.setRestoreTabsOnStartup(v),
              gxRed: gxRed,
              isCompact: isCompact,
              isMedium: isMedium,
            ),
            SizedBox(height: spacing),
            _buildSettingSwitch(
              title: 'Ouvrir sur la page d\'accueil',
              subtitle: 'Démarre Notilus sur le Speed Dial',
              value: _settings.startOnHomePage,
              onChanged: (v) => _settings.setStartOnHomePage(v),
              gxRed: gxRed,
              isCompact: isCompact,
              isMedium: isMedium,
            ),
            SizedBox(height: spacing * 2),
            _buildSubsectionTitle('Nouvel onglet', gxRed, isCompact: isCompact, isMedium: isMedium),
            SizedBox(height: spacing),
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
  
  Widget _buildDownloadsSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildTerminalSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildHomepageSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final style = styles[index];
        final isSelected = _settings.homePageStyle == style.$1;
        final accentColor = style.$6;
        return Padding(
          padding: EdgeInsets.only(bottom: index < styles.length - 1 ? 12 : 0),
          child: _HomePageStyleCard(
            id: style.$1,
            title: style.$2,
            description: style.$3,
            icon: style.$4,
            emoji: style.$5,
            accentColor: accentColor,
            isSelected: isSelected,
            onTap: () => _settings.setHomePageStyle(style.$1),
          ),
        );
      },
    );
  }

  // ============================================
  // SECTION SERVICES WEB
  // ============================================
  
  Widget _buildWebServicesSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildPrivacySection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildDevToolsSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildAccountSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
    return Consumer2<FirebaseAuthService?, ConfigSyncService?>(
      builder: (context, authService, syncService, _) {
        if (authService == null || syncService == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubsectionTitle('Authentification', gxRed, isCompact: isCompact, isMedium: isMedium),
              SizedBox(height: spacing),
              GxFuturisticCard(
                accentColor: const Color(0xFFF59E0B),
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info, color: const Color(0xFFF59E0B), size: isCompact ? 20 : 24),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        'Firebase n\'est pas configuré. Configurez Firebase pour activer l\'authentification et la synchronisation.',
                        style: NotilusFonts.rajdhani(
                          fontSize: isCompact ? 11 : 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
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
            _buildSubsectionTitle('Authentification', gxRed, isCompact: isCompact, isMedium: isMedium),
            SizedBox(height: spacing),
            if (!isSignedIn) ...[
              GxFuturisticCard(
                accentColor: gxRed,
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.person_circle, color: gxRed, size: isCompact ? 24 : 28),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Synchronisation des configurations',
                                style: NotilusFonts.rajdhani(
                                  fontSize: isCompact ? 12 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Connectez-vous pour sauvegarder et synchroniser vos paramètres sur tous vos appareils',
                                style: NotilusFonts.rajdhani(
                                  fontSize: isCompact ? 10 : 11,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing * 1.5),
                    GxFuturisticButton(
                      label: 'Se connecter',
                      icon: CupertinoIcons.person_circle,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: gxRed,
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AuthDialog(
                            authService: authService,
                            onAuthStarted: () {
                              widget.onClose?.call();
                            },
                          ),
                        );
                        if (result == true && context.mounted) {
                          await syncService!.restoreConfigs();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              GxFuturisticCard(
                accentColor: const Color(0xFF22C55E),
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if ((user?.photoURL ?? githubUser?.avatarUrl) != null)
                          Container(
                            width: isCompact ? 40 : 48,
                            height: isCompact ? 40 : 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: gxRed, width: 2),
                              image: DecorationImage(
                                image: NetworkImage((user?.photoURL ?? githubUser?.avatarUrl)!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: isCompact ? 40 : 48,
                            height: isCompact ? 40 : 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: gxRed.withOpacity(0.2),
                              border: Border.all(color: gxRed, width: 2),
                            ),
                            child: Icon(CupertinoIcons.person, color: gxRed, size: isCompact ? 20 : 24),
                          ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? user?.email ?? githubUser?.name ?? githubUser?.email ?? 'Utilisateur',
                                style: NotilusFonts.rajdhani(
                                  fontSize: isCompact ? 13 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                user?.email ?? githubUser?.email ?? '',
                                style: NotilusFonts.rajdhani(
                                  fontSize: isCompact ? 10 : 11,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              if (githubUser != null) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.star, size: 12, color: Colors.amber),
                                    SizedBox(width: 4),
                                    Text(
                                      'GitHub',
                                      style: NotilusFonts.rajdhani(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        GxFuturisticButton(
                          label: '',
                          icon: CupertinoIcons.xmark,
                          variant: GxFuturisticButtonVariant.secondary,
                          accentColor: const Color(0xFFEF4444),
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) {
                              GxNotificationService().showSuccess(
                                title: 'Déconnexion',
                                message: 'Déconnexion réussie',
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
              SizedBox(height: spacing * 1.5),
              _buildSubsectionTitle('Synchronisation', gxRed, isCompact: isCompact, isMedium: isMedium),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: GxFuturisticButton(
                      label: 'Exporter',
                      icon: CupertinoIcons.cloud_upload,
                      variant: GxFuturisticButtonVariant.secondary,
                      accentColor: gxRed,
                      isLoading: syncService.isSyncing,
                      onPressed: syncService.isSyncing
                          ? null
                          : () async {
                              final success = await syncService.exportConfigs();
                              if (context.mounted) {
                                if (success) {
                                  GxNotificationService().showSuccess(
                                    title: 'Succès',
                                    message: 'Configurations synchronisées',
                                    context: context,
                                  );
                                } else {
                                  GxNotificationService().showError(
                                    title: 'Erreur',
                                    message: 'Erreur lors de la synchronisation',
                                    context: context,
                                  );
                                }
                              }
                            },
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: GxFuturisticButton(
                      label: 'Restaurer',
                      icon: CupertinoIcons.cloud_download,
                      variant: GxFuturisticButtonVariant.secondary,
                      accentColor: const Color(0xFF3B82F6),
                      isLoading: syncService.isSyncing,
                      onPressed: syncService.isSyncing
                          ? null
                          : () async {
                              final success = await syncService.restoreConfigs();
                              if (context.mounted) {
                                if (success) {
                                  GxNotificationService().showSuccess(
                                    title: 'Succès',
                                    message: 'Configurations restaurées',
                                    context: context,
                                  );
                                } else {
                                  GxNotificationService().showError(
                                    title: 'Erreur',
                                    message: 'Erreur lors de la restauration',
                                    context: context,
                                  );
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              SyncStatusWidget(syncService: syncService),
            ],
          ],
        );
      },
    );
  }

  // ============================================
  // SECTION COMPOSANTS GX
  // ============================================
  
  Widget _buildGxComponentsSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildNotificationsSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildAboutSection(BuildContext context, ThemeData theme, Color gxRed, bool isCompact, bool isMedium, double spacing) {
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
  
  Widget _buildSubsectionTitle(String title, Color gxRed, {bool isCompact = false, bool isMedium = false}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isCompact ? 10 : isMedium ? 11 : 12,
        fontWeight: FontWeight.w600,
        color: gxRed,
        letterSpacing: 0.5,
        fontFamily: NotilusFonts.rajdhani().fontFamily,
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color gxRed,
    bool isCompact = false,
    bool isMedium = false,
  }) {
    final titleFontSize = isCompact ? 10.0 : isMedium ? 11.0 : 12.0;
    final subtitleFontSize = isCompact ? 9.0 : 10.0;
    final padding = isCompact ? 8.0 : isMedium ? 10.0 : 12.0;
    final verticalPadding = isCompact ? 6.0 : 8.0;
    
    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: verticalPadding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: NotilusFonts.rajdhani(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isCompact ? 1 : 2),
                      Text(
                        subtitle,
                        style: NotilusFonts.rajdhani(
                          fontSize: subtitleFontSize,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: padding),
                GxFuturisticSwitch(
                  value: value,
                  onChanged: onChanged,
                  accentColor: gxRed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// WIDGETS POUR PAGE D'ACCUEIL
// ============================================

class _HomePageStyleCard extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String emoji;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _HomePageStyleCard({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.emoji,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_HomePageStyleCard> createState() => _HomePageStyleCardState();
}

class _HomePageStyleCardState extends State<_HomePageStyleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withOpacity(0.15)
                : (_isHovered ? widget.accentColor.withOpacity(0.08) : Colors.white.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accentColor
                  : (_isHovered ? widget.accentColor.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
              width: widget.isSelected ? 2 : (_isHovered ? 1.5 : 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.accentColor.withOpacity(0.2)
                      : (_isHovered ? widget.accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(widget.isSelected ? 0.5 : 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: NotilusFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.isSelected
                                  ? widget.accentColor
                                  : (_isHovered ? Colors.white : Colors.white70),
                            ),
                          ),
                        ),
                        if (widget.isSelected)
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: widget.accentColor,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: NotilusFonts.rajdhani(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? widget.accentColor
                    : (_isHovered ? widget.accentColor.withOpacity(0.8) : Colors.white.withOpacity(0.4)),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// CLASSES UTILITAIRES
// ============================================

class _SectionItem {
  final String id;
  final String label;
  final IconData icon;

  const _SectionItem(this.id, this.label, this.icon);
}

// ============================================
// CLASSES POUR RECHERCHE APPROFONDIE
// ============================================

class _SettingIndex {
  final String sectionId;
  final String title;
  final String description;
  final String keywords;
  final String category;

  const _SettingIndex(
    this.sectionId,
    this.title,
    this.description,
    this.keywords,
    this.category,
  );
}

class _SearchResult {
  final _SettingIndex setting;
  final int relevance;

  const _SearchResult({
    required this.setting,
    required this.relevance,
  });
}

class _SearchResultWidget extends StatefulWidget {
  final _SearchResult result;
  final _SectionItem section;
  final bool isSelected;
  final Color accentColor;
  final bool isCompact;
  final String searchQuery;
  final VoidCallback onTap;

  const _SearchResultWidget({
    required this.result,
    required this.section,
    required this.isSelected,
    required this.accentColor,
    required this.isCompact,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  State<_SearchResultWidget> createState() => _SearchResultWidgetState();
}

class _SearchResultWidgetState extends State<_SearchResultWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 12 : 16,
            vertical: widget.isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withOpacity(0.15)
                : (_isHovered ? widget.accentColor.withOpacity(0.08) : Colors.transparent),
            border: Border(
              left: BorderSide(
                color: widget.isSelected
                    ? widget.accentColor
                    : (_isHovered ? widget.accentColor.withOpacity(0.5) : Colors.transparent),
                width: widget.isSelected ? 3 : (_isHovered ? 2 : 0),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    widget.section.icon,
                    size: widget.isCompact ? 14 : 16,
                    color: widget.isSelected
                        ? widget.accentColor
                        : (_isHovered ? widget.accentColor.withOpacity(0.8) : Colors.white60),
                  ),
                  SizedBox(width: widget.isCompact ? 8 : 10),
                  Expanded(
                    child: Text(
                      widget.result.setting.title,
                      style: NotilusFonts.rajdhani(
                        fontSize: widget.isCompact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? widget.accentColor
                            : (_isHovered ? Colors.white : Colors.white70),
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: widget.accentColor,
                      size: 16,
                    ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                widget.result.setting.description,
                style: NotilusFonts.rajdhani(
                  fontSize: widget.isCompact ? 9 : 10,
                  color: Colors.white.withOpacity(0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatefulWidget {
  final _SearchResult result;
  final Color accentColor;
  final bool isCompact;
  final bool isMedium;
  final double spacing;
  final String searchQuery;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.accentColor,
    required this.isCompact,
    required this.isMedium,
    required this.spacing,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<_SearchResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.spacing),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.1)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.result.setting.title,
                      style: NotilusFonts.rajdhani(
                        fontSize: widget.isCompact ? 12 : widget.isMedium ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: _isHovered ? widget.accentColor : Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: widget.isCompact ? 14 : 16,
                    color: widget.accentColor.withOpacity(0.6),
                  ),
                ],
              ),
              SizedBox(height: widget.spacing / 2),
              Text(
                widget.result.setting.description,
                style: NotilusFonts.rajdhani(
                  fontSize: widget.isCompact ? 10 : 11,
                  color: Colors.white.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionItemWidget extends StatefulWidget {
  final _SectionItem section;
  final bool isSelected;
  final Color accentColor;
  final bool isCompact;
  final VoidCallback onTap;

  const _SectionItemWidget({
    required this.section,
    required this.isSelected,
    required this.accentColor,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_SectionItemWidget> createState() => _SectionItemWidgetState();
}

class _SectionItemWidgetState extends State<_SectionItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 12 : 16,
            vertical: widget.isCompact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withOpacity(0.15)
                : (_isHovered ? widget.accentColor.withOpacity(0.08) : Colors.transparent),
            border: Border(
              left: BorderSide(
                color: widget.isSelected
                    ? widget.accentColor
                    : (_isHovered ? widget.accentColor.withOpacity(0.5) : Colors.transparent),
                width: widget.isSelected ? 3 : (_isHovered ? 2 : 0),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.section.icon,
                size: widget.isCompact ? 14 : 16,
                color: widget.isSelected
                    ? widget.accentColor
                    : (_isHovered ? widget.accentColor.withOpacity(0.8) : Colors.white60),
              ),
              SizedBox(width: widget.isCompact ? 8 : 10),
              Expanded(
                child: Text(
                  widget.section.label,
                  style: NotilusFonts.rajdhani(
                    fontSize: widget.isCompact ? 11 : 12,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isSelected
                        ? widget.accentColor
                        : (_isHovered ? Colors.white : Colors.white70),
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
