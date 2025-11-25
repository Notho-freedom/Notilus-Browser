import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/animations/notilus_animations.dart';

class DocumentationPanel extends StatefulWidget {
  const DocumentationPanel({super.key});

  @override
  State<DocumentationPanel> createState() => _DocumentationPanelState();
}

class _DocumentationPanelState extends State<DocumentationPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _expandedSection = -1;

  final List<_DocCategory> _categories = [
    _DocCategory(
      title: 'Démarrage Rapide',
      icon: CupertinoIcons.rocket,
      sections: [
        _DocSection(
          title: 'Introduction',
          content: '''
**Notilus Browser** est un navigateur web moderne conçu spécifiquement pour les développeurs.

### Caractéristiques principales
- 🔧 **DevTools intégrés** - Console, Network, Performance, Security
- 📊 **Métriques temps réel** - FPS, mémoire, CPU
- 🔒 **Audit de sécurité** - Détection des vulnérabilités
- 🌳 **Widget Inspector** - Inspectez l'arbre Flutter
- 🖥️ **Terminal intégré** - PowerShell/Bash

### Pour qui ?
Développeurs web, développeurs Flutter, DevOps, et tous ceux qui ont besoin d'outils de développement intégrés à leur navigateur.''',
        ),
        _DocSection(
          title: 'Installation',
          content: '''
### Prérequis
```
Flutter SDK 3.x+
Windows 10/11 (WebView2)
Visual Studio 2022 avec C++ workload
```

### Lancement
```bash
# Mode développement
flutter run -d windows --hot

# Build release
flutter build windows --release
```''',
        ),
      ],
    ),
    _DocCategory(
      title: 'Interface Utilisateur',
      icon: CupertinoIcons.square_grid_2x2,
      sections: [
        _DocSection(
          title: 'Sidebar (Barre latérale)',
          content: '''
| Icône | Section | Description |
|-------|---------|-------------|
| 🏠 | Accueil | Nouvelle page avec raccourcis |
| 🔖 | Favoris | Gestionnaire de bookmarks |
| 🕐 | Historique | Historique de navigation |
| ⬇️ | Téléchargements | Gestionnaire downloads |
| 📦 | Widgets | Widgets système |
| ✨ | AI | Hyper Assistant IA |
| ⚙️ | Paramètres | Configuration |
| 📟 | Terminal | Terminal intégré |
| 🔧 | DevTools | Outils développeur |
| 🐜 | DevTools Natif | Chrome DevTools (F12) |
| 📖 | Documentation | Cette doc |''',
        ),
        _DocSection(
          title: 'Barre d\'onglets',
          content: '''
### Interactions
- **Glisser-déposer** : Réorganiser les onglets
- **Clic molette** : Fermer un onglet
- **Double-clic** : Renommer l'onglet
- **Clic droit** : Menu contextuel

### Groupes d\'onglets
Les onglets peuvent être groupés par couleur pour une meilleure organisation.''',
        ),
        _DocSection(
          title: 'Barre d\'adresse',
          content: '''
### Fonctionnalités
- Autocomplétion intelligente
- Suggestions de recherche
- Indicateurs de sécurité (HTTPS)
- Actions rapides (reload, favoris)

### Raccourcis
- `Ctrl+L` : Focus barre d\'adresse
- `Entrée` : Naviguer/Rechercher
- `Échap` : Annuler''',
        ),
      ],
    ),
    _DocCategory(
      title: 'DevTools Notilus',
      icon: CupertinoIcons.wrench_fill,
      sections: [
        _DocSection(
          title: 'Console',
          content: '''
### Types de logs
| Niveau | Couleur | Usage |
|--------|---------|-------|
| INFO | 🔵 | Information générale |
| WARN | 🟠 | Avertissements |
| ERROR | 🔴 | Erreurs |
| DEBUG | 🟢 | Debug only |
| SYSTEM | 🟣 | Messages système |

### Fonctionnalités
- Filtrage par niveau
- Recherche textuelle
- Export des logs
- REPL interactif intégré''',
        ),
        _DocSection(
          title: 'Network',
          content: '''
### Interception des requêtes
- Requêtes Flutter (http package)
- Requêtes WebView (fetch, XHR)

### Informations capturées
- URL, méthode HTTP
- Headers request/response
- Body request/response
- Timing détaillé
- Status code

### Codes couleur
| Code | Couleur | Signification |
|------|---------|---------------|
| 2xx | 🟢 | Succès |
| 3xx | 🔵 | Redirection |
| 4xx | 🟠 | Erreur client |
| 5xx | 🔴 | Erreur serveur |''',
        ),
        _DocSection(
          title: 'Performance',
          content: '''
### Métriques temps réel
- **FPS** : Frames par seconde (target: 60)
- **Memory** : Mémoire utilisée (MB)
- **CPU** : Estimation basée sur frame time
- **Render** : Temps de rendu par frame
- **Widgets** : Nombre de widgets actifs
- **GC** : Détection garbage collection

### Sources des données
```dart
// Memory via ProcessInfo
ProcessInfo.currentRss

// FPS via SchedulerBinding
SchedulerBinding.instance.addPostFrameCallback
```''',
        ),
        _DocSection(
          title: 'Alerts (Smart Monitoring)',
          content: '''
### Types d\'alertes
- **FPS Drop** : Chute sous 30 FPS
- **Memory Spike** : Dépassement 500 MB
- **Slow Request** : Requête > 3000ms
- **Error Burst** : 5+ erreurs en 60s

### Sévérités
| Niveau | Icône | Action |
|--------|-------|--------|
| INFO | ℹ️ | Information |
| WARNING | ⚠️ | Attention requise |
| CRITICAL | 🚨 | Action immédiate |''',
        ),
        _DocSection(
          title: 'Security Audit',
          content: '''
### Détections automatiques
- Connexions HTTP (non HTTPS)
- Clés API exposées dans URLs
- Données sensibles dans réponses
- Contenu mixte (HTTP dans HTTPS)

### Score de sécurité
Score 0-100 basé sur les problèmes détectés.

### Recommandations
Chaque problème inclut une recommandation de correction.''',
        ),
        _DocSection(
          title: 'Widget Inspector',
          content: '''
### Fonctionnalités
- Capture de l\'arbre Flutter complet
- Hiérarchie navigable
- Propriétés des widgets
- Bounds de rendu (x, y, width, height)

### Navigation
- Clic pour sélectionner
- Chevron pour expand/collapse
- Panneau propriétés à droite''',
        ),
        _DocSection(
          title: 'Analytics',
          content: '''
### Statistiques par onglet
- Nombre de requêtes
- Données transférées
- Taux d\'erreur

### Session Recording
Enregistrez et rejouez vos sessions de développement.

```bash
record start [name]  # Démarrer
record stop          # Arrêter
sessions             # Lister
```

### Export
Générez des rapports JSON complets avec toutes les métriques.''',
        ),
      ],
    ),
    _DocCategory(
      title: 'Commandes REPL',
      icon: CupertinoIcons.command,
      sections: [
        _DocSection(
          title: 'Commandes de base',
          content: '''
```bash
help              # Affiche l'aide
clear             # Vide la console
logs              # Nombre de logs
echo <message>    # Affiche message
version           # Version DevTools
```''',
        ),
        _DocSection(
          title: 'Commandes réseau',
          content: '''
```bash
requests          # Nombre de requêtes
fetch <url>       # Requête GET
```''',
        ),
        _DocSection(
          title: 'Commandes performance',
          content: '''
```bash
perf              # Métriques actuelles
widgets           # Capture arbre widgets
```''',
        ),
        _DocSection(
          title: 'Commandes analytics',
          content: '''
```bash
analytics         # Stats globales
alerts            # Alertes actives
security          # Problèmes sécurité
```''',
        ),
        _DocSection(
          title: 'Commandes session',
          content: '''
```bash
record            # Toggle enregistrement
record start      # Démarrer (nom auto)
record start Test # Démarrer avec nom
record stop       # Arrêter
sessions          # Lister sessions
```''',
        ),
        _DocSection(
          title: 'Commandes storage',
          content: '''
```bash
storage           # Nombre d'entrées
get <key>         # Lire valeur
set <key> <value> # Définir valeur
del <key>         # Supprimer clé
```''',
        ),
        _DocSection(
          title: 'Commandes utilitaires',
          content: '''
```bash
bookmark <titre>  # Ajouter bookmark
export            # Rapport JSON
monitor on/off    # Toggle monitoring
env               # Info environnement
time              # Heure ISO
json <string>     # Formatter JSON
```''',
        ),
      ],
    ),
    _DocCategory(
      title: 'Raccourcis Clavier',
      icon: CupertinoIcons.keyboard,
      sections: [
        _DocSection(
          title: 'Navigation',
          content: '''
| Raccourci | Action |
|-----------|--------|
| `Ctrl+T` | Nouvel onglet |
| `Ctrl+W` | Fermer onglet |
| `Ctrl+Tab` | Onglet suivant |
| `Ctrl+Shift+Tab` | Onglet précédent |
| `Ctrl+1-9` | Aller à l\'onglet N |
| `Alt+←` | Page précédente |
| `Alt+→` | Page suivante |
| `Ctrl+R` | Recharger |''',
        ),
        _DocSection(
          title: 'DevTools',
          content: '''
| Raccourci | Action |
|-----------|--------|
| `F12` | Toggle DevTools |
| `Ctrl+Shift+I` | Toggle DevTools |
| `Ctrl+Shift+C` | Inspecter élément |
| `Ctrl+Shift+J` | Ouvrir Console |''',
        ),
        _DocSection(
          title: 'Édition',
          content: '''
| Raccourci | Action |
|-----------|--------|
| `Ctrl+L` | Focus adresse |
| `Ctrl+K` | Recherche rapide |
| `Ctrl+D` | Ajouter favoris |''',
        ),
      ],
    ),
    _DocCategory(
      title: 'Architecture',
      icon: CupertinoIcons.layers,
      sections: [
        _DocSection(
          title: 'Stack technique',
          content: '''
```
┌─────────────────────────────────┐
│         Notilus Browser         │
├─────────────────────────────────┤
│  UI Layer (Flutter Widgets)     │
│  - GXSidebar, GXTabBar          │
│  - DevTools Panels              │
├─────────────────────────────────┤
│  Service Layer                  │
│  - TabManager                   │
│  - NotilusDevToolsService       │
│  - DownloadService              │
├─────────────────────────────────┤
│  Engine Layer                   │
│  - WebView2BrowserEngine        │
│  - JavaScript Bridge            │
├─────────────────────────────────┤
│  Platform Layer                 │
│  - webview_windows              │
│  - window_manager               │
└─────────────────────────────────┘
```''',
        ),
        _DocSection(
          title: 'Structure des fichiers',
          content: '''
```
lib/
├── core/
│   ├── constants/    # Couleurs
│   ├── services/     # ColorTheme
│   ├── theme/        # ModernTheme
│   └── animations/   # Animations
├── models/
│   ├── tab_model.dart
│   └── devtools_models.dart
├── services/
│   ├── tab_manager.dart
│   ├── notilus_devtools_service.dart
│   └── webview2_browser_engine.dart
├── widgets/
│   ├── browser/      # UI principale
│   ├── dev_tools/    # Onglets DevTools
│   └── terminal/     # Terminal
└── main.dart
```''',
        ),
        _DocSection(
          title: 'Services principaux',
          content: '''
### TabManager
Gestion des onglets (création, fermeture, réorganisation).

### TabWebViewManager
Association onglets ↔ moteurs WebView.

### NotilusDevToolsService
Service singleton pour tous les DevTools:
- Logging
- Network interception
- Performance monitoring
- Smart alerts
- Security audit''',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_DocCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    
    return _categories.map((cat) {
      final filteredSections = cat.sections.where((section) {
        return section.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               section.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      
      return _DocCategory(
        title: cat.title,
        icon: cat.icon,
        sections: filteredSections,
      );
    }).where((cat) => cat.sections.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final accentColor = colorThemeManager.nativeSecondaryColor;
    
    return Container(
      color: const Color(0xFF0D0D10),
      child: Column(
        children: [
          // Header avec recherche
          _buildHeader(accentColor),
          
          // Navigation par catégories
          _buildCategoryTabs(accentColor),
          
          // Contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildCategoryContent(category, accentColor);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return FadeInWidget(
      duration: const Duration(milliseconds: 400),
      slideOffset: const Offset(0, -10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.15),
              accentColor.withOpacity(0.05),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.book_fill,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documentation Notilus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Guide complet pour développeurs',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildVersionBadge(accentColor),
              ],
            ),
            const SizedBox(height: 12),
            // Barre de recherche
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher dans la documentation...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    color: Colors.white.withOpacity(0.3),
                    size: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionBadge(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'v3.0.0',
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(Color accentColor) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: accentColor,
        indicatorWeight: 2,
        labelColor: accentColor,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: _categories.map((cat) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, size: 14),
                const SizedBox(width: 6),
                Text(cat.title),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryContent(_DocCategory category, Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: category.sections.length,
      itemBuilder: (context, index) {
        final section = category.sections[index];
        return StaggeredListItem(
          index: index,
          baseDelay: const Duration(milliseconds: 100),
          itemDelay: const Duration(milliseconds: 50),
          child: _DocSectionCard(
            section: section,
            accentColor: accentColor,
            isExpanded: _expandedSection == index,
            onToggle: () {
              setState(() {
                _expandedSection = _expandedSection == index ? -1 : index;
              });
            },
          ),
        );
      },
    );
  }
}

class _DocSectionCard extends StatelessWidget {
  final _DocSection section;
  final Color accentColor;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DocSectionCard({
    required this.section,
    required this.accentColor,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isExpanded
            ? accentColor.withOpacity(0.08)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? accentColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          hoverColor: accentColor.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.25 : 0,
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        color: accentColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        section.title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(isExpanded ? 1 : 0.85),
                          fontSize: 14,
                          fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isExpanded ? 1 : 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ouvert',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _MarkdownContent(
                    content: section.content,
                    accentColor: accentColor,
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

class _MarkdownContent extends StatelessWidget {
  final String content;
  final Color accentColor;

  const _MarkdownContent({
    required this.content,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      _parseMarkdown(content),
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 12,
        height: 1.6,
        fontFamily: 'JetBrains Mono',
      ),
    );
  }

  TextSpan _parseMarkdown(String text) {
    final List<InlineSpan> spans = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      
      // Headers
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '${line.substring(4)}\n',
          style: TextStyle(
            color: accentColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ));
        continue;
      }
      
      // Code blocks
      if (line.startsWith('```')) {
        // Find end of code block
        int endIndex = i + 1;
        while (endIndex < lines.length && !lines[endIndex].startsWith('```')) {
          endIndex++;
        }
        
        // Get code content
        final codeLines = lines.sublist(i + 1, endIndex);
        final codeContent = codeLines.join('\n');
        
        spans.add(WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              codeContent,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ));
        
        i = endIndex;
        continue;
      }
      
      // Tables
      if (line.startsWith('|')) {
        // Skip table for now, show as text
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontFamily: 'JetBrains Mono',
          ),
        ));
        continue;
      }
      
      // Bold text
      line = line.replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*'),
        (match) => '【${match.group(1)}】',
      );
      
      // Inline code
      line = line.replaceAllMapped(
        RegExp(r'`(.+?)`'),
        (match) => '⌜${match.group(1)}⌝',
      );
      
      // Process styled text
      final processedSpans = <InlineSpan>[];
      final parts = line.split(RegExp(r'(【.+?】|⌜.+?⌝)'));
      
      for (final part in parts) {
        if (part.startsWith('【') && part.endsWith('】')) {
          processedSpans.add(TextSpan(
            text: part.substring(1, part.length - 1),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ));
        } else if (part.startsWith('⌜') && part.endsWith('⌝')) {
          processedSpans.add(TextSpan(
            text: part.substring(1, part.length - 1),
            style: TextStyle(
              color: accentColor,
              backgroundColor: accentColor.withOpacity(0.1),
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
            ),
          ));
        } else {
          processedSpans.add(TextSpan(text: part));
        }
      }
      
      spans.addAll(processedSpans);
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return TextSpan(children: spans);
  }
}

class _DocCategory {
  final String title;
  final IconData icon;
  final List<_DocSection> sections;

  const _DocCategory({
    required this.title,
    required this.icon,
    required this.sections,
  });
}

class _DocSection {
  final String title;
  final String content;

  const _DocSection({
    required this.title,
    required this.content,
  });
}

