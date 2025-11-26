import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  final List<_DocCategory> _categories = [
    _DocCategory(
      title: 'Démarrage',
      icon: CupertinoIcons.rocket_fill,
      sections: [
        _DocSection(
          title: 'À propos de Notilus',
          items: [
            _DocItem(icon: CupertinoIcons.info_circle, label: 'Navigateur moderne pour développeurs', detail: 'Basé sur Flutter et WebView2'),
            _DocItem(icon: CupertinoIcons.ant, label: 'DevTools intégrés (F12)', detail: 'Panel en bas de l\'écran'),
            _DocItem(icon: CupertinoIcons.shield, label: 'Moteur Chromium WebView2', detail: 'Rendu haute performance'),
            _DocItem(icon: CupertinoIcons.chart_bar, label: 'Monitoring réseau avancé', detail: 'Capture et analyse des requêtes'),
            _DocItem(icon: CupertinoIcons.text_cursor, label: 'Terminal intégré', detail: 'PowerShell natif'),
            _DocItem(icon: CupertinoIcons.gauge, label: 'Notilus Lighthouse', detail: 'Analyse complète de performance'),
            _DocItem(icon: CupertinoIcons.device_phone_portrait, label: 'Notilus Studio', detail: 'Outils de test front-end'),
          ],
        ),
        _DocSection(
          title: 'Installation',
          items: [
            _DocItem(icon: CupertinoIcons.checkmark_circle, label: 'Windows 10/11 requis'),
            _DocItem(icon: CupertinoIcons.checkmark_circle, label: 'WebView2 Runtime inclus'),
            _DocItem(icon: CupertinoIcons.arrow_down_circle, label: 'flutter run -d windows', detail: 'Pour le développement'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Interface',
      icon: CupertinoIcons.square_grid_2x2_fill,
      sections: [
        _DocSection(
          title: 'Sidebar - Navigation',
          items: [
            _DocItem(icon: CupertinoIcons.house, label: 'Accueil', detail: 'Page avec speed dial et raccourcis'),
            _DocItem(icon: CupertinoIcons.bookmark, label: 'Favoris', detail: 'Gestionnaire de bookmarks complet'),
            _DocItem(icon: CupertinoIcons.clock, label: 'Historique', detail: 'Historique de navigation avec recherche'),
            _DocItem(icon: CupertinoIcons.arrow_down_to_line, label: 'Téléchargements', detail: 'Gestionnaire de downloads avec pause/reprise'),
            _DocItem(icon: CupertinoIcons.text_cursor, label: 'Terminal', detail: 'Shell PowerShell intégré'),
            _DocItem(icon: CupertinoIcons.ant, label: 'DevTools (F12)', detail: 'Outils développeur en bas'),
            _DocItem(icon: CupertinoIcons.book, label: 'Documentation', detail: 'Ce panneau de documentation'),
            _DocItem(icon: CupertinoIcons.square_grid_2x2, label: 'Mosaïque', detail: 'Système de workspace multi-contenu'),
            _DocItem(icon: CupertinoIcons.device_phone_portrait, label: 'Studio', detail: 'Outils de test front-end'),
            _DocItem(icon: CupertinoIcons.gauge, label: 'Lighthouse', detail: 'Analyse de performance'),
          ],
        ),
        _DocSection(
          title: 'Sidebar - Services Web',
          items: [
            _DocItem(icon: CupertinoIcons.music_note, label: 'YouTube Music', detail: 'Musique en sidebar'),
            _DocItem(icon: CupertinoIcons.play_circle, label: 'YouTube', detail: 'Vidéos en panneau'),
            _DocItem(icon: CupertinoIcons.chat_bubble_2, label: 'ChatGPT', detail: 'Assistant IA OpenAI'),
            _DocItem(icon: CupertinoIcons.sparkles, label: 'DeepSeek', detail: 'IA alternative'),
            _DocItem(icon: CupertinoIcons.chat_bubble_text, label: 'WhatsApp', detail: 'Messagerie'),
            _DocItem(icon: CupertinoIcons.paperplane, label: 'Telegram', detail: 'Messagerie'),
          ],
        ),
        _DocSection(
          title: 'Onglets',
          items: [
            _DocItem(icon: CupertinoIcons.hand_draw, label: 'Glisser-déposer', detail: 'Réorganiser les onglets'),
            _DocItem(icon: CupertinoIcons.xmark_circle, label: 'Clic molette', detail: 'Fermer un onglet'),
            _DocItem(icon: CupertinoIcons.pencil, label: 'Double-clic', detail: 'Renommer un onglet'),
            _DocItem(icon: CupertinoIcons.rectangle_split_3x1, label: 'Groupes', detail: 'Organiser en groupes'),
            _DocItem(icon: CupertinoIcons.doc_on_doc, label: 'Dupliquer', detail: 'Menu contextuel'),
            _DocItem(icon: CupertinoIcons.arrow_counterclockwise, label: 'Recharger', detail: 'Menu contextuel'),
          ],
        ),
        _DocSection(
          title: 'Barre d\'adresse',
          items: [
            _DocItem(icon: CupertinoIcons.link, label: 'Navigation', detail: 'Entrer une URL ou recherche'),
            _DocItem(icon: CupertinoIcons.person_circle, label: 'Compte', detail: 'Profil utilisateur'),
            _DocItem(icon: CupertinoIcons.square_grid_2x2, label: 'Widgets', detail: 'Panneau de widgets'),
            _DocItem(icon: CupertinoIcons.arrow_down_to_line, label: 'Téléchargements', detail: 'Accès rapide'),
            _DocItem(icon: CupertinoIcons.ellipsis, label: 'Plus d\'outils', detail: 'Menu contextuel'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Notilus Lighthouse',
      icon: CupertinoIcons.gauge,
      sections: [
        _DocSection(
          title: 'Accès',
          items: [
            _DocItem(icon: CupertinoIcons.gauge, label: 'Icône Lighthouse', detail: 'Dans la sidebar'),
            _DocItem(icon: CupertinoIcons.keyboard, label: 'Ctrl+Shift+L', detail: 'Raccourci clavier'),
            _DocItem(icon: CupertinoIcons.keyboard, label: 'Ctrl+Shift+R', detail: 'Lancer un audit (quand Lighthouse actif)'),
          ],
        ),
        _DocSection(
          title: 'Audit Complet',
          items: [
            _DocItem(icon: CupertinoIcons.speedometer, label: 'Performance', detail: 'Core Web Vitals (LCP, FID, CLS, TTFB, TTI)'),
            _DocItem(icon: CupertinoIcons.person_2, label: 'Accessibilité', detail: 'WCAG 2.1 niveau AA - 30+ règles'),
            _DocItem(icon: CupertinoIcons.search, label: 'SEO', detail: '30+ règles de référencement'),
            _DocItem(icon: CupertinoIcons.shield, label: 'Sécurité', detail: 'OWASP Top 10 - 28 règles'),
            _DocItem(icon: CupertinoIcons.checkmark_seal, label: 'Bonnes Pratiques', detail: 'Standards web modernes'),
            _DocItem(icon: CupertinoIcons.star, label: 'Score Global', detail: '0-100 avec grade (A-F)'),
          ],
        ),
        _DocSection(
          title: 'AI Advisor',
          items: [
            _DocItem(icon: CupertinoIcons.bolt, label: 'Quick Wins', detail: 'Corrections faciles avec grand impact'),
            _DocItem(icon: CupertinoIcons.lightbulb, label: 'Recommandations', detail: 'Priorisées par impact/effort'),
            _DocItem(icon: CupertinoIcons.chat_bubble, label: 'Chat IA', detail: 'Questions contextuelles sur l\'audit'),
            _DocItem(icon: CupertinoIcons.chart_bar, label: 'Gain Estimé', detail: 'Points de score par correction'),
          ],
        ),
        _DocSection(
          title: 'History & Trends',
          items: [
            _DocItem(icon: CupertinoIcons.clock, label: 'Historique', detail: 'Stockage local des audits'),
            _DocItem(icon: CupertinoIcons.chart_bar, label: 'Graphiques', detail: 'Évolution des métriques'),
            _DocItem(icon: CupertinoIcons.exclamationmark_triangle, label: 'Régressions', detail: 'Détection automatique'),
            _DocItem(icon: CupertinoIcons.arrow_up_arrow_down, label: 'Tendances', detail: 'Amélioration/dégradation'),
          ],
        ),
        _DocSection(
          title: 'Rapports',
          items: [
            _DocItem(icon: CupertinoIcons.doc_text, label: 'Export PDF', detail: 'Rapport complet formaté'),
            _DocItem(icon: CupertinoIcons.square_list, label: 'Export JSON', detail: 'Données structurées'),
            _DocItem(icon: CupertinoIcons.table, label: 'Export CSV', detail: 'Données tabulaires'),
            _DocItem(icon: CupertinoIcons.share, label: 'Partage', detail: 'Exporter et partager les résultats'),
          ],
        ),
        _DocSection(
          title: 'Règles d\'Audit',
          items: [
            _DocItem(icon: CupertinoIcons.checkmark_circle, label: '100+ Règles', detail: 'Total des règles d\'audit'),
            _DocItem(icon: CupertinoIcons.person_2, label: 'WCAG 2.1', detail: '30 règles d\'accessibilité'),
            _DocItem(icon: CupertinoIcons.search, label: 'SEO', detail: '30 règles de référencement'),
            _DocItem(icon: CupertinoIcons.shield, label: 'Sécurité OWASP', detail: '28 règles de sécurité'),
            _DocItem(icon: CupertinoIcons.speedometer, label: 'Performance', detail: '26 règles de performance'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Notilus Studio',
      icon: CupertinoIcons.device_phone_portrait,
      sections: [
        _DocSection(
          title: 'Accès',
          items: [
            _DocItem(icon: CupertinoIcons.device_phone_portrait, label: 'Icône Studio', detail: 'Dans la sidebar'),
            _DocItem(icon: CupertinoIcons.keyboard, label: 'Ctrl+Shift+S', detail: 'Raccourci clavier'),
          ],
        ),
        _DocSection(
          title: 'Responsive Tester',
          items: [
            _DocItem(icon: CupertinoIcons.device_phone_portrait, label: 'Multi-viewport', detail: 'Jusqu\'à 6 viewports simultanés'),
            _DocItem(icon: CupertinoIcons.arrow_clockwise, label: 'Sync Scroll', detail: 'Synchronisation du scroll'),
            _DocItem(icon: CupertinoIcons.arrow_2_circlepath, label: 'Rotation', detail: 'Rotation des viewports'),
            _DocItem(icon: CupertinoIcons.bars, label: 'Breakpoints CSS', detail: 'Détection automatique'),
            _DocItem(icon: CupertinoIcons.device_desktop, label: '40+ Presets', detail: 'iPhone, iPad, Desktop, etc.'),
          ],
        ),
        _DocSection(
          title: 'Screenshot Studio',
          items: [
            _DocItem(icon: CupertinoIcons.camera, label: 'Modes de capture', detail: 'Viewport, Full page, Element'),
            _DocItem(icon: CupertinoIcons.photo, label: 'Formats', detail: 'PNG, JPEG, WebP'),
            _DocItem(icon: CupertinoIcons.slider_horizontal_3, label: 'Qualité & Scale', detail: 'Contrôle fin'),
            _DocItem(icon: CupertinoIcons.rectangle_on_rectangle, label: 'Templates Mockup', detail: 'iPhone, MacBook, Browser'),
            _DocItem(icon: CupertinoIcons.arrow_down_doc, label: 'Export', detail: 'Sauvegarde automatique'),
          ],
        ),
        _DocSection(
          title: 'Live Editor',
          items: [
            _DocItem(icon: CupertinoIcons.pencil, label: 'Édition HTML/CSS', detail: 'Modification en temps réel'),
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Styles CSS', detail: 'Éditeur avec coloration'),
            _DocItem(icon: CupertinoIcons.tag, label: 'Attributs HTML', detail: 'Ajout/modification/suppression'),
            _DocItem(icon: CupertinoIcons.clock, label: 'Historique', detail: 'Annuler/Refaire'),
            _DocItem(icon: CupertinoIcons.arrow_down_doc, label: 'Export', detail: 'CSS patch, HTML complet'),
          ],
        ),
        _DocSection(
          title: 'Interaction Recorder',
          items: [
            _DocItem(icon: CupertinoIcons.circle_fill, label: 'Enregistrement', detail: 'Clics, scrolls, inputs'),
            _DocItem(icon: CupertinoIcons.time, label: 'Timeline', detail: 'Visualisation des interactions'),
            _DocItem(icon: CupertinoIcons.play, label: 'Playback', detail: 'Rejouer les interactions'),
            _DocItem(icon: CupertinoIcons.arrow_down_doc, label: 'Export', detail: 'Script d\'automatisation'),
          ],
        ),
        _DocSection(
          title: 'Mockup Comparator',
          items: [
            _DocItem(icon: CupertinoIcons.photo, label: 'Import Mockup', detail: 'Image de référence'),
            _DocItem(icon: CupertinoIcons.camera, label: 'Capture Site', detail: 'Capture de la page actuelle'),
            _DocItem(icon: CupertinoIcons.rectangle_split_3x1, label: 'Modes', detail: 'Split, Overlay, Diff, Slide, Onion'),
            _DocItem(icon: CupertinoIcons.slider_horizontal_3, label: 'Opacité', detail: 'Contrôle du chevauchement'),
            _DocItem(icon: CupertinoIcons.percent, label: 'Similarité', detail: 'Score de comparaison pixel par pixel'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'DevTools',
      icon: CupertinoIcons.ant,
      sections: [
        _DocSection(
          title: 'Accès DevTools',
          items: [
            _DocItem(icon: CupertinoIcons.ant, label: 'Bouton Fourmi 🐜', detail: 'Dans la sidebar'),
            _DocItem(icon: CupertinoIcons.keyboard, label: 'F12', detail: 'Raccourci clavier'),
            _DocItem(icon: CupertinoIcons.keyboard, label: 'Ctrl+Shift+I', detail: 'Raccourci alternatif'),
            _DocItem(icon: CupertinoIcons.arrow_up_down, label: 'Redimensionnable', detail: 'Glisser la bordure'),
            _DocItem(icon: CupertinoIcons.escape, label: 'Echap', detail: 'Fermer DevTools'),
          ],
        ),
        _DocSection(
          title: 'Console',
          items: [
            _DocItem(icon: CupertinoIcons.text_alignleft, label: 'Logs WebView', detail: 'console.log, warn, error'),
            _DocItem(icon: CupertinoIcons.line_horizontal_3_decrease, label: 'Filtres par niveau', detail: 'log, info, warn, error'),
            _DocItem(icon: CupertinoIcons.search, label: 'Recherche textuelle', detail: 'Filtrer les logs'),
            _DocItem(icon: CupertinoIcons.trash, label: 'Clear console', detail: 'Effacer tous les logs'),
            _DocItem(icon: CupertinoIcons.chevron_down, label: 'Logs multilignes', detail: 'Collapsible par défaut'),
            _DocItem(icon: CupertinoIcons.text_cursor, label: 'Console interactive', detail: 'Exécuter du JavaScript'),
          ],
        ),
        _DocSection(
          title: 'Network',
          items: [
            _DocItem(icon: CupertinoIcons.globe, label: 'Capture requêtes', detail: 'HTTP/HTTPS automatique'),
            _DocItem(icon: CupertinoIcons.doc_text, label: 'Headers', detail: 'Request/Response complets'),
            _DocItem(icon: CupertinoIcons.timer, label: 'Timing détaillé', detail: 'DNS, Connect, TTFB, Download'),
            _DocItem(icon: CupertinoIcons.exclamationmark_triangle, label: 'Détection erreurs', detail: '4xx, 5xx automatiques'),
            _DocItem(icon: CupertinoIcons.line_horizontal_3_decrease, label: 'Filtres', detail: 'Par méthode, type, statut'),
            _DocItem(icon: CupertinoIcons.search, label: 'Recherche', detail: 'Filtrer par URL'),
          ],
        ),
        _DocSection(
          title: 'Elements',
          items: [
            _DocItem(icon: CupertinoIcons.chevron_left_slash_chevron_right, label: 'Arbre DOM', detail: 'Navigation complète'),
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Inspection styles', detail: 'CSS calculé et hérité'),
            _DocItem(icon: CupertinoIcons.square_on_square, label: 'Box Model', detail: 'Margin, Padding, Border'),
            _DocItem(icon: CupertinoIcons.pencil, label: 'Édition live', detail: 'Double-clic pour éditer'),
            _DocItem(icon: CupertinoIcons.tag, label: 'Attributs', detail: 'Ajouter/modifier/supprimer'),
            _DocItem(icon: CupertinoIcons.folder, label: 'Ressources', detail: 'Images, scripts, styles'),
            _DocItem(icon: CupertinoIcons.doc_text, label: 'Vue source', detail: 'HTML formaté'),
            _DocItem(icon: CupertinoIcons.arrow_down_doc, label: 'Export', detail: 'HTML/PDF'),
          ],
        ),
        _DocSection(
          title: 'Performance',
          items: [
            _DocItem(icon: CupertinoIcons.gauge, label: 'Métriques temps réel', detail: 'FPS, Frame time'),
            _DocItem(icon: CupertinoIcons.memories, label: 'Usage mémoire', detail: 'Heap size, Used heap'),
            _DocItem(icon: CupertinoIcons.chart_bar, label: 'Graphiques', detail: 'Visualisation des métriques'),
            _DocItem(icon: CupertinoIcons.timer, label: 'Frame timing', detail: 'Temps par frame'),
            _DocItem(icon: CupertinoIcons.arrow_clockwise, label: 'Auto-refresh', detail: 'Mise à jour automatique'),
          ],
        ),
        _DocSection(
          title: 'Application',
          items: [
            _DocItem(icon: CupertinoIcons.tray_full, label: 'LocalStorage', detail: 'Clés/valeurs'),
            _DocItem(icon: CupertinoIcons.tray, label: 'SessionStorage', detail: 'Données de session'),
            _DocItem(icon: CupertinoIcons.archivebox, label: 'Cookies', detail: 'Gestion complète'),
            _DocItem(icon: CupertinoIcons.folder, label: 'Cache', detail: 'Ressources mises en cache'),
            _DocItem(icon: CupertinoIcons.trash, label: 'Clear', detail: 'Effacer le stockage'),
          ],
        ),
        _DocSection(
          title: 'Resources',
          items: [
            _DocItem(icon: CupertinoIcons.photo, label: 'Images', detail: 'Liste des images chargées'),
            _DocItem(icon: CupertinoIcons.doc_text, label: 'Scripts', detail: 'Fichiers JavaScript'),
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Styles', detail: 'Feuilles CSS'),
            _DocItem(icon: CupertinoIcons.textformat, label: 'Fonts', detail: 'Polices web'),
            _DocItem(icon: CupertinoIcons.play_circle, label: 'Media', detail: 'Vidéos, audio'),
            _DocItem(icon: CupertinoIcons.folder, label: 'Autres', detail: 'Autres ressources'),
          ],
        ),
        _DocSection(
          title: 'Mode Responsive',
          items: [
            _DocItem(icon: CupertinoIcons.device_phone_portrait, label: 'Simulation', detail: 'Mobile, Tablet, Desktop'),
            _DocItem(icon: CupertinoIcons.arrow_clockwise, label: 'Rotation', detail: 'Portrait/Paysage'),
            _DocItem(icon: CupertinoIcons.slider_horizontal_3, label: 'Zoom', detail: 'Ajuster le zoom'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Mosaïque',
      icon: CupertinoIcons.square_grid_2x2,
      sections: [
        _DocSection(
          title: 'Accès',
          items: [
            _DocItem(icon: CupertinoIcons.square_grid_2x2, label: 'Icône Mosaïque', detail: 'Dans la sidebar'),
            _DocItem(icon: CupertinoIcons.keyboard, label: 'Ctrl+Shift+M', detail: 'Raccourci clavier'),
          ],
        ),
        _DocSection(
          title: 'Fonctionnalités',
          items: [
            _DocItem(icon: CupertinoIcons.rectangle_split_3x3, label: 'Workspaces', detail: 'Plusieurs espaces de travail'),
            _DocItem(icon: CupertinoIcons.hand_draw, label: 'Glisser-déposer', detail: 'Réorganiser les tuiles'),
            _DocItem(icon: CupertinoIcons.add, label: 'Types de contenu', detail: 'Web, Terminal, DevTools, etc.'),
            _DocItem(icon: CupertinoIcons.resize, label: 'Redimensionnable', detail: 'Ajuster la taille des tuiles'),
            _DocItem(icon: CupertinoIcons.folder, label: 'Sauvegarde', detail: 'Workspaces persistants'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Raccourcis',
      icon: CupertinoIcons.keyboard,
      sections: [
        _DocSection(
          title: 'Navigation',
          items: [
            _DocItem(icon: CupertinoIcons.add, label: 'Ctrl+T', detail: 'Nouvel onglet'),
            _DocItem(icon: CupertinoIcons.xmark, label: 'Ctrl+W', detail: 'Fermer onglet'),
            _DocItem(icon: CupertinoIcons.arrow_right, label: 'Ctrl+Tab', detail: 'Onglet suivant'),
            _DocItem(icon: CupertinoIcons.arrow_left, label: 'Ctrl+Shift+Tab', detail: 'Onglet précédent'),
            _DocItem(icon: CupertinoIcons.arrow_counterclockwise, label: 'Ctrl+R', detail: 'Recharger'),
            _DocItem(icon: CupertinoIcons.arrow_counterclockwise, label: 'F5', detail: 'Recharger'),
            _DocItem(icon: CupertinoIcons.arrow_left, label: 'Alt+←', detail: 'Retour'),
            _DocItem(icon: CupertinoIcons.arrow_right, label: 'Alt+→', detail: 'Avant'),
          ],
        ),
        _DocSection(
          title: 'DevTools',
          items: [
            _DocItem(icon: CupertinoIcons.ant, label: 'F12', detail: 'Toggle DevTools'),
            _DocItem(icon: CupertinoIcons.ant, label: 'Ctrl+Shift+I', detail: 'Toggle DevTools'),
            _DocItem(icon: CupertinoIcons.escape, label: 'Echap', detail: 'Fermer DevTools'),
          ],
        ),
        _DocSection(
          title: 'Lighthouse & Studio',
          items: [
            _DocItem(icon: CupertinoIcons.gauge, label: 'Ctrl+Shift+L', detail: 'Ouvrir Lighthouse'),
            _DocItem(icon: CupertinoIcons.device_phone_portrait, label: 'Ctrl+Shift+S', detail: 'Ouvrir Studio'),
            _DocItem(icon: CupertinoIcons.play, label: 'Ctrl+Shift+R', detail: 'Lancer audit (Lighthouse actif)'),
          ],
        ),
        _DocSection(
          title: 'Mosaïque',
          items: [
            _DocItem(icon: CupertinoIcons.square_grid_2x2, label: 'Ctrl+Shift+M', detail: 'Toggle Mosaïque'),
          ],
        ),
        _DocSection(
          title: 'Édition',
          items: [
            _DocItem(icon: CupertinoIcons.link, label: 'Ctrl+L', detail: 'Focus barre d\'adresse'),
            _DocItem(icon: CupertinoIcons.bookmark, label: 'Ctrl+D', detail: 'Ajouter aux favoris'),
            _DocItem(icon: CupertinoIcons.doc_on_doc, label: 'Ctrl+C', detail: 'Copier'),
            _DocItem(icon: CupertinoIcons.doc_on_clipboard, label: 'Ctrl+V', detail: 'Coller'),
          ],
        ),
        _DocSection(
          title: 'Système',
          items: [
            _DocItem(icon: CupertinoIcons.arrow_up_left_arrow_down_right, label: 'F11', detail: 'Plein écran'),
            _DocItem(icon: CupertinoIcons.clock, label: 'Ctrl+H', detail: 'Historique'),
            _DocItem(icon: CupertinoIcons.arrow_down_to_line, label: 'Ctrl+J', detail: 'Téléchargements'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Terminal',
      icon: CupertinoIcons.text_cursor,
      sections: [
        _DocSection(
          title: 'Accès',
          items: [
            _DocItem(icon: CupertinoIcons.square_list, label: 'Icône Terminal', detail: 'Dans la sidebar'),
            _DocItem(icon: CupertinoIcons.text_cursor, label: 'PowerShell', detail: 'Shell par défaut Windows'),
          ],
        ),
        _DocSection(
          title: 'Fonctionnalités',
          items: [
            _DocItem(icon: CupertinoIcons.doc_text, label: 'Historique commandes', detail: 'Navigation avec flèches'),
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Coloration syntaxique', detail: 'Mise en évidence'),
            _DocItem(icon: CupertinoIcons.arrow_up_down, label: 'Redimensionnable', detail: 'Ajuster la hauteur'),
            _DocItem(icon: CupertinoIcons.doc_on_doc, label: 'Copier/Coller', detail: 'Support natif'),
            _DocItem(icon: CupertinoIcons.trash, label: 'Clear', detail: 'Effacer le terminal'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Extensions',
      icon: CupertinoIcons.square_grid_2x2,
      sections: [
        _DocSection(
          title: 'Installation',
          items: [
            _DocItem(icon: CupertinoIcons.plus_circle, label: 'Installer', detail: 'Depuis un fichier manifest.json'),
            _DocItem(icon: CupertinoIcons.folder, label: 'Manifest', detail: 'Format JSON standard'),
            _DocItem(icon: CupertinoIcons.checkmark_seal, label: 'Validation', detail: 'Vérification automatique'),
          ],
        ),
        _DocSection(
          title: 'Gestion',
          items: [
            _DocItem(icon: CupertinoIcons.square_list, label: 'Liste', detail: 'Voir toutes les extensions'),
            _DocItem(icon: CupertinoIcons.slider_horizontal_3, label: 'Activer/Désactiver', detail: 'Toggle par extension'),
            _DocItem(icon: CupertinoIcons.trash, label: 'Désinstaller', detail: 'Supprimer une extension'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Paramètres',
      icon: CupertinoIcons.settings,
      sections: [
        _DocSection(
          title: 'Général',
          items: [
            _DocItem(icon: CupertinoIcons.house, label: 'Page d\'accueil', detail: 'Configurer la page de démarrage'),
            _DocItem(icon: CupertinoIcons.arrow_down_circle, label: 'Dossier téléchargements', detail: 'Choisir le dossier'),
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Thème', detail: 'Clair, Sombre, Système'),
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Couleurs', detail: 'Personnaliser les couleurs'),
          ],
        ),
        _DocSection(
          title: 'Données',
          items: [
            _DocItem(icon: CupertinoIcons.clock, label: 'Effacer historique', detail: 'Supprimer l\'historique'),
            _DocItem(icon: CupertinoIcons.archivebox, label: 'Effacer cookies', detail: 'Supprimer les cookies'),
            _DocItem(icon: CupertinoIcons.folder, label: 'Effacer cache', detail: 'Vider le cache'),
            _DocItem(icon: CupertinoIcons.trash, label: 'Tout effacer', detail: 'Reset complet'),
          ],
        ),
        _DocSection(
          title: 'DevTools',
          items: [
            _DocItem(icon: CupertinoIcons.arrow_up_down, label: 'Position', detail: 'Bas, Droite, Détaché'),
            _DocItem(icon: CupertinoIcons.resize, label: 'Taille', detail: 'Hauteur par défaut'),
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Thème', detail: 'Cohérent avec l\'app'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Architecture',
      icon: CupertinoIcons.layers_fill,
      sections: [
        _DocSection(
          title: 'Stack Technique',
          items: [
            _DocItem(icon: CupertinoIcons.paintbrush, label: 'Flutter 3.x', detail: 'Framework UI'),
            _DocItem(icon: CupertinoIcons.globe, label: 'WebView2', detail: 'Moteur Chromium'),
            _DocItem(icon: CupertinoIcons.bolt, label: 'Dart', detail: 'Langage principal'),
            _DocItem(icon: CupertinoIcons.desktopcomputer, label: 'Windows', detail: 'Plateforme cible'),
          ],
        ),
        _DocSection(
          title: 'Services Principaux',
          items: [
            _DocItem(icon: CupertinoIcons.rectangle_stack, label: 'TabManager', detail: 'Gestion des onglets'),
            _DocItem(icon: CupertinoIcons.globe, label: 'TabWebViewManager', detail: 'Moteurs WebView'),
            _DocItem(icon: CupertinoIcons.ant, label: 'DevToolsService', detail: 'Outils développeur'),
            _DocItem(icon: CupertinoIcons.gauge, label: 'LighthouseService', detail: 'Analyse de performance'),
            _DocItem(icon: CupertinoIcons.device_phone_portrait, label: 'StudioService', detail: 'Outils de test'),
            _DocItem(icon: CupertinoIcons.arrow_down_circle, label: 'DownloadService', detail: 'Téléchargements'),
            _DocItem(icon: CupertinoIcons.text_cursor, label: 'TerminalService', detail: 'Terminal intégré'),
            _DocItem(icon: CupertinoIcons.square_grid_2x2, label: 'NotilusMosaicService', detail: 'Système de mosaïque'),
            _DocItem(icon: CupertinoIcons.chart_bar, label: 'SystemMetricsService', detail: 'Métriques système'),
          ],
        ),
        _DocSection(
          title: 'Structure Fichiers',
          items: [
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/core/', detail: 'Constants, Theme, Utils, Animations'),
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/models/', detail: 'Modèles de données'),
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/services/', detail: 'Logique métier'),
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/services/lighthouse/', detail: 'Services Lighthouse'),
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/services/studio/', detail: 'Services Studio'),
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/widgets/', detail: 'Composants UI'),
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/widgets/lighthouse/', detail: 'Panneaux Lighthouse'),
            _DocItem(icon: CupertinoIcons.folder, label: 'lib/widgets/studio/', detail: 'Panneaux Studio'),
          ],
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

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final accentColor = colorThemeManager.nativeSecondaryColor;
    
    // Filtrer les catégories et sections selon la recherche
    final filteredCategories = _categories.map((category) {
      final filteredSections = category.sections.map((section) {
        final filteredItems = section.items.where((item) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return item.label.toLowerCase().contains(query) ||
                 (item.detail?.toLowerCase().contains(query) ?? false);
        }).toList();
        return _DocSection(
          title: section.title,
          items: filteredItems,
        );
      }).where((section) => section.items.isNotEmpty).toList();
      
      return _DocCategory(
        title: category.title,
        icon: category.icon,
        sections: filteredSections,
      );
    }).where((category) => category.sections.isNotEmpty).toList();
    
    return Container(
      color: const Color(0xFF0D0D10),
      child: Column(
        children: [
          _buildHeader(accentColor),
          _buildCategoryTabs(accentColor, filteredCategories),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: filteredCategories.map((category) {
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.book_fill,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notilus Browser',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Documentation complète - v3.1',
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
            const SizedBox(height: 14),
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
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
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: Colors.white.withOpacity(0.3),
                            size: 16,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
            'v3.1',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(Color accentColor, List<_DocCategory> categories) {
    return Container(
      height: 44,
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
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: accentColor,
        unselectedLabelColor: Colors.white.withOpacity(0.4),
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: categories.map((cat) {
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
    if (category.sections.isEmpty) {
      return Center(
        child: Text(
          'Aucun résultat pour "$_searchQuery"',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: category.sections.length,
      itemBuilder: (context, index) {
        final section = category.sections[index];
        return StaggeredListItem(
          index: index,
          baseDelay: const Duration(milliseconds: 50),
          itemDelay: const Duration(milliseconds: 30),
          child: _DocSectionWidget(
            section: section,
            accentColor: accentColor,
          ),
        );
      },
    );
  }
}

class _DocSectionWidget extends StatelessWidget {
  final _DocSection section;
  final Color accentColor;

  const _DocSectionWidget({
    required this.section,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  section.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: section.items.map((item) {
                return _DocItemWidget(item: item, accentColor: accentColor);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocItemWidget extends StatefulWidget {
  final _DocItem item;
  final Color accentColor;

  const _DocItemWidget({
    required this.item,
    required this.accentColor,
  });

  @override
  State<_DocItemWidget> createState() => _DocItemWidgetState();
}

class _DocItemWidgetState extends State<_DocItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered 
              ? widget.accentColor.withOpacity(0.08) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isHovered 
                    ? widget.accentColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.item.icon,
                size: 14,
                color: _isHovered 
                    ? widget.accentColor 
                    : Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      color: _isHovered 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.item.detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.item.detail!,
                      style: TextStyle(
                        color: _isHovered
                            ? widget.accentColor.withOpacity(0.8)
                            : Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isHovered)
              Icon(
                CupertinoIcons.chevron_right,
                size: 12,
                color: widget.accentColor.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
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
  final List<_DocItem> items;

  const _DocSection({
    required this.title,
    required this.items,
  });
}

class _DocItem {
  final IconData icon;
  final String label;
  final String? detail;

  const _DocItem({
    required this.icon,
    required this.label,
    this.detail,
  });
}
