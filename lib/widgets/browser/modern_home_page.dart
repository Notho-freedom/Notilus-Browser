import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/quick_access_service.dart';
import '../../services/history_service.dart';
import '../../models/quick_access_item.dart';
import '../../models/history_item.dart';
import '../common/notilus_monogram.dart';
import '../common/notilus_tooltip.dart';
import '../common/animated_wallpaper_background.dart';
import '../common/sidebar_panel_scope.dart';
import '../browser/gx_sidebar.dart';

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
  final Random _randomColor = Random();

  List<QuickAccessItem> _quickAccessItems = [];
  bool _loadingQuickAccess = true;
  List<HistoryItem> _recentHistory = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadQuickAccessItems();
    _loadRecentHistory();
  }

  Future<void> _loadQuickAccessItems() async {
    final items = await _quickAccessService.loadItems();
    if (!mounted) return;
    setState(() {
      _quickAccessItems = items;
      _loadingQuickAccess = false;
    });
  }

  Future<void> _loadRecentHistory() async {
    final history = await _historyService.getHistory();
    if (!mounted) return;
    setState(() {
      _recentHistory = history.take(7).toList();
      _loadingHistory = false;
    });
  }

  Future<void> _showAddQuickAccessDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    final result = await showDialog<QuickAccessItem>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un site rapide'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Nom requis' : null,
                ),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'URL requise' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final item = QuickAccessItem(
                    name: nameController.text.trim(),
                    url: _normalizeUrl(urlController.text),
                    color: _randomQuickAccessColor(),
                  );
                  Navigator.of(context).pop(item);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final items = await _quickAccessService.addItem(result);
      if (!mounted) return;
      setState(() {
        _quickAccessItems = items;
      });
    }
  }

  Color _randomQuickAccessColor() {
    const palette = [
      Color(0xFF1D2D50),
      Color(0xFF162447),
      Color(0xFF0F3460),
      Color(0xFF533483),
      Color(0xFF333A56),
      Color(0xFF4F5D75),
      Color(0xFF6930C3),
    ];
    return palette[_randomColor.nextInt(palette.length)];
  }

  String _normalizeUrl(String value) {
    var trimmed = value.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
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
    _loadRecentHistory();
  }

  void _openQuickAccess(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
    _loadRecentHistory();
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
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
                onPressed: () => _handleSearch(_searchController.text),
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
        );
  }

  Widget _buildStatsRow() {
    return Row(
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
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildQuickAccessHeader(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
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
          NotilusTooltip(
            message: 'Ajouter un site rapide',
            child: IconButton(
              icon: const Icon(CupertinoIcons.plus_circle),
              color: Colors.white.withOpacity(0.85),
              onPressed: _showAddQuickAccessDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    if (_loadingQuickAccess) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final tiles = <Widget>[];
    
    // Ajouter les tiles de quick access
    for (int index = 0; index < _quickAccessItems.length; index++) {
      final item = _quickAccessItems[index];
      tiles.add(
        _QuickAccessTile(
          item: item,
          onTap: () => _openQuickAccess(item.url),
          delay: (index * 60).ms,
        ),
      );
    }
    
    // Ajouter le tile "Ajouter"
    tiles.add(_QuickAccessAddTile(onPressed: _showAddQuickAccessDialog));

    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: tiles,
    );
  }

  Widget _buildRecentVisitsSection(
      ThemeData theme, SidebarPanelScope? panelScope) {
    if (_loadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dernières visites',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  panelScope?.openPanel(SidebarSection.history),
              child: const Text('Voir historique'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentHistory.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _recentHistory[index];
              return _RecentVisitChip(
                item: item,
                onTap: () => _openQuickAccess(item.url),
              );
            },
          ),
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
    final panelScope = SidebarPanelScope.of(context);

    return AnimatedWallpaperBackground(
      darkness: isDark ? 0.65 : 0.75,
      child: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.58),
                      borderRadius: BorderRadius.circular(32),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          _buildHeroHeader(theme),
                          const SizedBox(height: 28),
                          _buildSearchBar(theme),
                          const SizedBox(height: 18),
                          _buildStatsRow(),
                          const SizedBox(height: 28),
                          _buildQuickAccessHeader(theme),
                          const SizedBox(height: 12),
                          _buildQuickAccessGrid(),
                          const SizedBox(height: 28),
                          _buildRecentVisitsSection(theme, panelScope),
                          const SizedBox(height: 24),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

class _QuickAccessTile extends StatefulWidget {
  final QuickAccessItem item;
  final VoidCallback onTap;
  final Duration delay;

  const _QuickAccessTile({
    required this.item,
    required this.onTap,
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
                            child: Icon(
                              widget.item.icon,
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

class _QuickAccessAddTile extends StatelessWidget {
  final VoidCallback onPressed;

  const _QuickAccessAddTile({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: DottedBorderContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(CupertinoIcons.plus_circle, color: Colors.white70, size: 28),
            SizedBox(height: 8),
            Text(
              'Ajouter',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentVisitChip extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const _RecentVisitChip({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: Colors.white.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      label: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              item.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      onPressed: onTap,
    );
  }
}

class DottedBorderContainer extends StatelessWidget {
  final Widget child;

  const DottedBorderContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
          style: BorderStyle.solid,
        ),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Center(child: child),
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
