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
            _DocItem(icon: CupertinoIcons.info_circle, label: 'Navigateur moderne pour développeurs'),
            _DocItem(icon: CupertinoIcons.wrench, label: 'DevTools intégrés natifs'),
            _DocItem(icon: CupertinoIcons.shield, label: 'Audit de sécurité automatique'),
            _DocItem(icon: CupertinoIcons.chart_bar, label: 'Monitoring réseau avancé'),
            _DocItem(icon: CupertinoIcons.text_cursor, label: 'Terminal intégré'),
          ],
        ),
        _DocSection(
          title: 'Installation',
          items: [
            _DocItem(icon: CupertinoIcons.checkmark_circle, label: 'Windows 10/11 requis'),
            _DocItem(icon: CupertinoIcons.checkmark_circle, label: 'WebView2 Runtime inclus'),
            _DocItem(icon: CupertinoIcons.arrow_down_circle, label: 'Télécharger depuis GitHub'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Interface',
      icon: CupertinoIcons.square_grid_2x2_fill,
      sections: [
        _DocSection(
          title: 'Sidebar',
          items: [
            _DocItem(icon: CupertinoIcons.house, label: 'Accueil', detail: 'Nouvelle page avec speed dial'),
            _DocItem(icon: CupertinoIcons.bookmark, label: 'Favoris', detail: 'Gestionnaire de bookmarks'),
            _DocItem(icon: CupertinoIcons.clock, label: 'Historique', detail: 'Historique de navigation'),
            _DocItem(icon: CupertinoIcons.arrow_down_to_line, label: 'Téléchargements', detail: 'Gestionnaire de downloads'),
            _DocItem(icon: CupertinoIcons.wrench_fill, label: 'DevTools', detail: 'Outils développeur'),
            _DocItem(icon: CupertinoIcons.text_cursor, label: 'Terminal', detail: 'Shell intégré'),
            _DocItem(icon: CupertinoIcons.book, label: 'Documentation', detail: 'Ce panneau'),
          ],
        ),
        _DocSection(
          title: 'Onglets',
          items: [
            _DocItem(icon: CupertinoIcons.hand_draw, label: 'Glisser-déposer pour réorganiser'),
            _DocItem(icon: CupertinoIcons.xmark_circle, label: 'Clic molette pour fermer'),
            _DocItem(icon: CupertinoIcons.pencil, label: 'Double-clic pour renommer'),
            _DocItem(icon: CupertinoIcons.rectangle_split_3x1, label: 'Split-screen disponible'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'DevTools',
      icon: CupertinoIcons.wrench_fill,
      sections: [
        _DocSection(
          title: 'Console',
          items: [
            _DocItem(icon: CupertinoIcons.text_alignleft, label: 'Logs WebView', detail: 'console.log, warn, error'),
            _DocItem(icon: CupertinoIcons.line_horizontal_3_decrease, label: 'Filtres par niveau'),
            _DocItem(icon: CupertinoIcons.search, label: 'Recherche textuelle'),
            _DocItem(icon: CupertinoIcons.keyboard, label: 'REPL interactif'),
          ],
        ),
        _DocSection(
          title: 'Network',
          items: [
            _DocItem(icon: CupertinoIcons.globe, label: 'Capture requêtes HTTP/HTTPS'),
            _DocItem(icon: CupertinoIcons.doc_text, label: 'Headers request/response'),
            _DocItem(icon: CupertinoIcons.timer, label: 'Timing détaillé'),
            _DocItem(icon: CupertinoIcons.exclamationmark_triangle, label: 'Détection erreurs'),
          ],
        ),
        _DocSection(
          title: 'Performance',
          items: [
            _DocItem(icon: CupertinoIcons.gauge, label: 'Métriques temps réel'),
            _DocItem(icon: CupertinoIcons.memories, label: 'Usage mémoire'),
            _DocItem(icon: CupertinoIcons.chart_bar, label: 'Graphiques FPS'),
          ],
        ),
        _DocSection(
          title: 'Alerts',
          items: [
            _DocItem(icon: CupertinoIcons.bell_fill, label: 'Alertes automatiques'),
            _DocItem(icon: CupertinoIcons.speedometer, label: 'Requêtes lentes', detail: '> 3000ms'),
            _DocItem(icon: CupertinoIcons.exclamationmark_bubble, label: 'Rafales d\'erreurs', detail: '5+ en 60s'),
          ],
        ),
        _DocSection(
          title: 'Security',
          items: [
            _DocItem(icon: CupertinoIcons.lock_open, label: 'Connexions HTTP non sécurisées'),
            _DocItem(icon: CupertinoIcons.lock, label: 'Clés API exposées dans URLs'),
            _DocItem(icon: CupertinoIcons.eye_slash, label: 'Données sensibles détectées'),
            _DocItem(icon: CupertinoIcons.chart_pie, label: 'Score de sécurité 0-100'),
          ],
        ),
        _DocSection(
          title: 'Analytics',
          items: [
            _DocItem(icon: CupertinoIcons.graph_square, label: 'Stats par onglet'),
            _DocItem(icon: CupertinoIcons.videocam, label: 'Session Recording'),
            _DocItem(icon: CupertinoIcons.bookmark, label: 'Bookmarks & annotations'),
            _DocItem(icon: CupertinoIcons.square_arrow_up, label: 'Export rapport JSON'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Commandes',
      icon: CupertinoIcons.command,
      sections: [
        _DocSection(
          title: 'Console',
          items: [
            _DocItem(icon: CupertinoIcons.question_circle, label: 'help', detail: 'Affiche l\'aide'),
            _DocItem(icon: CupertinoIcons.trash, label: 'clear', detail: 'Vide la console'),
            _DocItem(icon: CupertinoIcons.text_bubble, label: 'echo <msg>', detail: 'Affiche un message'),
          ],
        ),
        _DocSection(
          title: 'Réseau',
          items: [
            _DocItem(icon: CupertinoIcons.list_number, label: 'requests', detail: 'Nombre de requêtes'),
            _DocItem(icon: CupertinoIcons.cloud_download, label: 'fetch <url>', detail: 'Requête GET'),
          ],
        ),
        _DocSection(
          title: 'Session',
          items: [
            _DocItem(icon: CupertinoIcons.circle_fill, label: 'record start', detail: 'Démarrer enregistrement'),
            _DocItem(icon: CupertinoIcons.stop_fill, label: 'record stop', detail: 'Arrêter enregistrement'),
            _DocItem(icon: CupertinoIcons.list_bullet, label: 'sessions', detail: 'Lister les sessions'),
          ],
        ),
        _DocSection(
          title: 'Utilitaires',
          items: [
            _DocItem(icon: CupertinoIcons.bookmark, label: 'bookmark <t>', detail: 'Créer bookmark'),
            _DocItem(icon: CupertinoIcons.square_arrow_up, label: 'export', detail: 'Export JSON'),
            _DocItem(icon: CupertinoIcons.bell, label: 'monitor on/off', detail: 'Toggle monitoring'),
            _DocItem(icon: CupertinoIcons.doc_text, label: 'json <str>', detail: 'Formater JSON'),
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
            _DocItem(icon: CupertinoIcons.arrow_counterclockwise, label: 'Ctrl+R', detail: 'Recharger'),
          ],
        ),
        _DocSection(
          title: 'DevTools',
          items: [
            _DocItem(icon: CupertinoIcons.wrench, label: 'F12', detail: 'Toggle DevTools'),
            _DocItem(icon: CupertinoIcons.wrench, label: 'Ctrl+Shift+I', detail: 'Toggle DevTools'),
          ],
        ),
        _DocSection(
          title: 'Édition',
          items: [
            _DocItem(icon: CupertinoIcons.link, label: 'Ctrl+L', detail: 'Focus barre d\'adresse'),
            _DocItem(icon: CupertinoIcons.bookmark, label: 'Ctrl+D', detail: 'Ajouter aux favoris'),
          ],
        ),
      ],
    ),
    _DocCategory(
      title: 'Services',
      icon: CupertinoIcons.globe,
      sections: [
        _DocSection(
          title: 'Intégrés',
          items: [
            _DocItem(icon: CupertinoIcons.music_note, label: 'YouTube Music', detail: 'Musique en sidebar'),
            _DocItem(icon: CupertinoIcons.play_circle, label: 'YouTube', detail: 'Vidéos en panneau'),
            _DocItem(icon: CupertinoIcons.chat_bubble_2, label: 'ChatGPT', detail: 'Assistant IA'),
            _DocItem(icon: CupertinoIcons.sparkles, label: 'DeepSeek', detail: 'IA alternative'),
            _DocItem(icon: CupertinoIcons.chat_bubble_text, label: 'WhatsApp', detail: 'Messagerie'),
            _DocItem(icon: CupertinoIcons.paperplane, label: 'Telegram', detail: 'Messagerie'),
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
    
    return Container(
      color: const Color(0xFF0D0D10),
      child: Column(
        children: [
          _buildHeader(accentColor),
          _buildCategoryTabs(accentColor),
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
                      Text(
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
                        'Documentation pour développeurs',
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
                  hintText: 'Rechercher...',
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
            'v3.0',
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

  Widget _buildCategoryTabs(Color accentColor) {
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
