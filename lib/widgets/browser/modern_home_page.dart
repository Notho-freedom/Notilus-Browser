import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/quick_access_service.dart';
import '../../services/history_service.dart';
import '../../models/history_item.dart';
import '../../core/utils/url_validator.dart';
import '../common/notilus_monogram.dart';
import '../common/context_menu.dart';

class ModernHomePage extends StatefulWidget {
  const ModernHomePage({super.key});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final QuickAccessService _quickAccessService = QuickAccessService();
  final HistoryService _historyService = HistoryService();
  List<QuickAccessItem> _quickAccessItems = [];
  List<HistoryItem> _recentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadQuickAccessItems();
    _loadRecentHistory();
  }

  Future<void> _loadQuickAccessItems() async {
    final items = await _quickAccessService.getQuickAccessItems();
    if (items.isEmpty) {
      // Créer des items par défaut
      final defaultItems = [
        await _quickAccessService.extractSiteInfo('https://github.com'),
        await _quickAccessService.extractSiteInfo('https://google.com'),
        await _quickAccessService.extractSiteInfo('https://youtube.com'),
        await _quickAccessService.extractSiteInfo('https://stackoverflow.com'),
      ];
      for (final item in defaultItems) {
        if (item != null) {
          await _quickAccessService.addQuickAccessItem(item);
        }
      }
      await _loadQuickAccessItems();
    } else {
      setState(() {
        _quickAccessItems = items;
      });
    }
  }

  Future<void> _loadRecentHistory() async {
    final history = await _historyService.getHistory();
    setState(() {
      _recentHistory = history.take(5).toList();
    });
  }

  Future<void> _addQuickAccessSite() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15151A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: const Color(0xFFFF2D55).withOpacity(0.6), width: 1),
        ),
        title: const Text('Ajouter un site rapide', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: const Color(0xFFFF2D55),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'https://example.com',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFFFF2D55).withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF2D55)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Ajouter', style: TextStyle(color: Color(0xFFFF2D55))),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final url = UrlValidator.validateAndFormat(result) ?? result;
      final item = await _quickAccessService.extractSiteInfo(url);
      if (item != null) {
        await _quickAccessService.addQuickAccessItem(item);
        await _loadQuickAccessItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Site rapide ajouté')),
          );
        }
      }
    }
  }


  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    final tabManager = Provider.of<TabManager>(context, listen: false);
    String url = query.trim();
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      }
    }

    tabManager.addTab(url: url);
  }

  void _openQuickAccess(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  void _showQuickAccessContextMenu(BuildContext context, QuickAccessItem item) {
    ContextMenu.show(
      context: context,
      actions: [
        ContextMenuAction(
          label: 'Ouvrir dans un nouvel onglet',
          icon: CupertinoIcons.add,
          onTap: () => _openQuickAccess(item.url),
        ),
        ContextMenuAction(
          label: 'Supprimer',
          icon: CupertinoIcons.delete,
          isDestructive: true,
          onTap: () async {
            await _quickAccessService.removeQuickAccessItem(item.id);
            await _loadQuickAccessItems();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final wallpaperManager = context.watch<WallpaperManager>();
    
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(isDark ? 0.65 : 0.75),
            BlendMode.srcOver,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.88),
            Colors.black.withOpacity(0.94),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Contenu central
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                    // Logo + titre
                    Column(
                      children: [
                        const NotilusMonogram(
                          size: 78,
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),

                        const SizedBox(height: 20),

                        Text(
                          'Notilus Speed Dial',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 150.ms)
                            .slideY(begin: 0.12, end: 0),

                        const SizedBox(height: 6),

                        Text(
                          'Hub de lancement pour vos outils de développement',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 220.ms)
                            .slideY(begin: 0.12, end: 0),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Barre de recherche avec double contour néon
                    Container(
                      constraints: const BoxConstraints(maxWidth: 720),
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF2D55).withOpacity(0.85),
                            const Color(0xFF6B2C5F).withOpacity(0.65),
                          ],
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black.withOpacity(0.28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 18),
                            const Icon(
                              CupertinoIcons.search,
                              size: 20,
                              color: Color(0xFFFF2D55),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                cursorColor: const Color(0xFFFF2D55),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher sur le web ou saisir une adresse',
                                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.45),
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                ),
                                onSubmitted: _handleSearch,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFFF2D55).withOpacity(0.14),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  CupertinoIcons.arrow_right,
                                  color: Color(0xFFFF2D55),
                                ),
                                onPressed: () =>
                                    _handleSearch(_searchController.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 550.ms, delay: 300.ms)
                        .scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1, 1),
                        ),

                      const SizedBox(height: 18),

                    // Mini widgets CPU / RAM / Réseau façon GX
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _StatChip(
                            icon: CupertinoIcons.gauge,
                            label: 'CPU',
                            value: '32%',
                          ),
                          SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.memory,
                            label: 'RAM',
                            value: '45%',
                          ),
                          SizedBox(width: 10),
                          _StatChip(
                            icon: CupertinoIcons.waveform_path,
                            label: 'Réseau',
                            value: 'Stable',
                          ),
                        ],
                      )
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 380.ms)
                        .slideY(begin: 0.08, end: 0),

                      const SizedBox(height: 32),

                    // Titre de section Speed Dial
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF2D55),
                                    Color(0xFF5856D6),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sites rapides',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(CupertinoIcons.add_circled, color: Color(0xFFFF2D55)),
                              tooltip: 'Ajouter un site rapide',
                              onPressed: _addQuickAccessSite,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Grille Speed Dial
                      Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children:
                            _quickAccessItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;

                          return _QuickAccessTile(
                            item: item,
                            onTap: () => _openQuickAccess(item.url),
                            onLongPress: () => _showQuickAccessContextMenu(context, item),
                            delay: (index * 60).ms,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Section Accès rapide (Historique récent)
                      if (_recentHistory.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 2,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF2D55),
                                      Color(0xFF5856D6),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Accès rapide',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  // Ouvrir le panel historique
                                  // TODO: Implémenter l'ouverture du panel
                                },
                                child: const Text(
                                  'Voir tout',
                                  style: TextStyle(color: Color(0xFFFF2D55)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _recentHistory.take(5).map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _HistoryQuickAccessTile(
                                  historyItem: item,
                                  onTap: () => _openQuickAccess(item.url),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Suggestions (bientôt personnalisées pour vos workflows)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.55),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Label vertical "WIDGETS" à droite façon Opera GX
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFFF2D55).withOpacity(0.8),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D55).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'WIDGETS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// QuickAccessItem est maintenant défini dans quick_access_service.dart

class _QuickAccessTile extends StatefulWidget {
  final QuickAccessItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final Duration delay;

  const _QuickAccessTile({
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
    required this.delay,
  });

  @override
  State<_QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<_QuickAccessTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          height: 90,
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: _isHovered
                ? LinearGradient(
                    colors: [
                      widget.item.color.withOpacity(0.95),
                      const Color(0xFFFF2D55).withOpacity(0.9),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      widget.item.color.withOpacity(0.65),
                      widget.item.color.withOpacity(0.25),
                    ],
                  ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? const Color(0xFF050509).withOpacity(0.96)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Barre accent en bas
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          widget.item.color,
                          widget.item.color.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: widget.item.color.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: widget.item.iconUrl != null
                                ? Image.network(
                                    widget.item.iconUrl!,
                                    width: 18,
                                    height: 18,
                                    errorBuilder: (_, __, ___) => Icon(
                                      CupertinoIcons.globe,
                                      size: 18,
                                      color: widget.item.color,
                                    ),
                                  )
                                : Icon(
                                    CupertinoIcons.globe,
                                    size: 18,
                                    color: widget.item.color,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.item.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Uri.parse(widget.item.url).host.replaceFirst(
                                  'www.',
                                  '',
                                ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 14,
                            color: theme.iconTheme.color?.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: widget.delay)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          delay: widget.delay,
        );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1C1C24),
            Color(0xFF252535),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFF2D55).withOpacity(0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFFFF2D55),
          ),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryQuickAccessTile extends StatelessWidget {
  final HistoryItem historyItem;
  final VoidCallback onTap;

  const _HistoryQuickAccessTile({
    required this.historyItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF5856D6).withOpacity(0.2),
          border: Border.all(
            color: const Color(0xFF5856D6).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.globe,
              size: 24,
              color: Color(0xFF5856D6),
            ),
            const SizedBox(height: 4),
            Text(
              historyItem.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
