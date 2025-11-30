import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/quick_access_service.dart';
import '../../services/history_service.dart';
import '../../services/system_metrics_service.dart';
import '../../services/settings_service.dart';
import '../../models/history_item.dart';
import '../../services/favicon_service.dart';
import '../../core/utils/url_validator.dart';
import '../../core/services/color_theme_manager.dart';
import '../common/notilus_monogram.dart';

/// Page d'accueil Notilus Dev - Style développeur/IDE immersif
class NotilusDevHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  final VoidCallback? onDevToolsSelected;
  
  const NotilusDevHomePage({
    super.key,
    this.onTerminalSelected,
    this.onDevToolsSelected,
  });

  @override
  State<NotilusDevHomePage> createState() => _NotilusDevHomePageState();
}

class _NotilusDevHomePageState extends State<NotilusDevHomePage> 
    with TickerProviderStateMixin {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  final QuickAccessService _quickAccessService = QuickAccessService();
  final HistoryService _historyService = HistoryService();
  final SystemMetricsService _metricsService = SystemMetricsService();
  final SettingsService _settings = SettingsService();
  
  List<QuickAccessItem> _quickAccessItems = [];
  List<HistoryItem> _recentHistory = [];
  late AnimationController _glowController;
  late AnimationController _scanlineController;
  String _currentTime = '';
  
  // Catégories de liens pour développeurs
  final List<_DevCategory> _devCategories = [
    _DevCategory(
      title: 'CODE',
      icon: CupertinoIcons.chevron_left_slash_chevron_right,
      items: [
        _DevLink('GitHub', 'https://github.com', '⌥G', const Color(0xFF6E5494)),
        _DevLink('GitLab', 'https://gitlab.com', '⌥L', const Color(0xFFFC6D26)),
        _DevLink('CodePen', 'https://codepen.io', '⌥P', const Color(0xFF1E1F26)),
        _DevLink('Replit', 'https://replit.com', '⌥R', const Color(0xFFF26207)),
      ],
    ),
    _DevCategory(
      title: 'DOCS',
      icon: CupertinoIcons.book,
      items: [
        _DevLink('MDN', 'https://developer.mozilla.org', '⌥M', const Color(0xFF1E90FF)),
        _DevLink('DevDocs', 'https://devdocs.io', '⌥D', const Color(0xFF5BAAFF)),
        _DevLink('Stack Overflow', 'https://stackoverflow.com', '⌥S', const Color(0xFFF48024)),
        _DevLink('W3Schools', 'https://w3schools.com', '⌥W', const Color(0xFF04AA6D)),
      ],
    ),
    _DevCategory(
      title: 'AI',
      icon: CupertinoIcons.sparkles,
      items: [
        _DevLink('ChatGPT', 'https://chat.openai.com', '⌥C', const Color(0xFF10A37F)),
        _DevLink('Claude', 'https://claude.ai', '⌥A', const Color(0xFFD97757)),
        _DevLink('DeepSeek', 'https://chat.deepseek.com', '⌥K', const Color(0xFF00A8FF)),
        _DevLink('Perplexity', 'https://perplexity.ai', '⌥X', const Color(0xFF20B2AA)),
      ],
    ),
    _DevCategory(
      title: 'TOOLS',
      icon: CupertinoIcons.wrench,
      items: [
        _DevLink('Figma', 'https://figma.com', '⌥F', const Color(0xFFA259FF)),
        _DevLink('Vercel', 'https://vercel.com', '⌥V', const Color(0xFF000000)),
        _DevLink('Netlify', 'https://netlify.com', '⌥N', const Color(0xFF00C7B7)),
        _DevLink('Railway', 'https://railway.app', '⌥Y', const Color(0xFF0B0D0E)),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _loadData();
    _updateTime();
    _metricsService.addListener(_onMetricsUpdate);
    _settings.addListener(_onSettingsChanged);
    
    // Mettre à jour l'horloge
    Future.delayed(Duration.zero, () {
      _startClock();
    });
  }
  
  void _startClock() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _updateTime();
      }
    }
  }
  
  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }
  
  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }
  
  void _onMetricsUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scanlineController.dispose();
    _commandController.dispose();
    _commandFocusNode.dispose();
    _metricsService.removeListener(_onMetricsUpdate);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    final items = await _quickAccessService.getQuickAccessItems();
    final history = await _historyService.getHistory();
    
    if (mounted) {
      setState(() {
        _quickAccessItems = items;
        _recentHistory = history.take(8).toList();
      });
      
      final tabManager = Provider.of<TabManager>(context, listen: false);
      _metricsService.updateTabCount(tabManager.tabs.length);
    }
  }

  void _handleCommand(String command) {
    if (command.trim().isEmpty) return;

    final tabManager = Provider.of<TabManager>(context, listen: false);
    String url = command.trim();
    
    // Commandes spéciales
    if (command.startsWith(':')) {
      _executeSpecialCommand(command.substring(1));
      _commandController.clear();
      return;
    }
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(command)}';
      }
    }

    tabManager.addTab(url: url);
    _commandController.clear();
  }
  
  void _executeSpecialCommand(String cmd) {
    switch (cmd.toLowerCase()) {
      case 'term':
      case 'terminal':
        widget.onTerminalSelected?.call();
        break;
      case 'dev':
      case 'devtools':
        widget.onDevToolsSelected?.call();
        break;
      case 'gh':
      case 'github':
        _openUrl('https://github.com');
        break;
      case 'new':
        Provider.of<TabManager>(context, listen: false).addTab();
        break;
    }
  }

  void _openUrl(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    final wallpaperManager = context.watch<WallpaperManager>();
    final currentUrl = wallpaperManager.current;
    
    return Container(
      decoration: BoxDecoration(
        image: currentUrl.isNotEmpty && !wallpaperManager.isVideo
            ? DecorationImage(
                image: CachedNetworkImageProvider(currentUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.92),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Effet de grille technique
          _buildTechGrid(gxRed),
          
          // Scanlines subtiles
          _buildScanlines(),
          
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Header avec status système
                _buildDevHeader(theme, gxRed),
                
                // Zone principale
                Expanded(
                  child: Row(
                    children: [
                      // Zone centrale - Command Bar + Quick Links
                      Expanded(
                        flex: 3,
                        child: _buildMainContent(theme, gxRed),
                      ),
                      
                      // Sidebar droite - Activité récente
                      if (_settings.showRecentHistory)
                        _buildActivitySidebar(theme, gxRed),
                    ],
                  ),
                ),
                
                // Footer avec métriques
                _buildDevFooter(theme, gxRed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechGrid(Color gxRed) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return CustomPaint(
          painter: _TechGridPainter(
            color: gxRed,
            progress: _glowController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildScanlines() {
    return AnimatedBuilder(
      animation: _scanlineController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.03,
          child: CustomPaint(
            painter: _ScanlinePainter(
              progress: _scanlineController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildDevHeader(ThemeData theme, Color gxRed) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: gxRed.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo + Version
          Row(
            children: [
              NotilusMonogram(size: 18)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 3000.ms, color: gxRed.withValues(alpha: 0.3)),
              const SizedBox(width: 10),
              Text(
                'NOTILUS',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: gxRed,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: gxRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: gxRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'DEV',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: gxRed,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Métriques rapides
          Row(
            children: [
              _buildHeaderMetric(CupertinoIcons.gauge, '${_metricsService.cpuUsage.toInt()}%', gxRed),
              const SizedBox(width: 16),
              _buildHeaderMetric(Icons.memory, '${_metricsService.ramUsage.toInt()}%', gxRed),
              const SizedBox(width: 16),
              _buildHeaderMetric(CupertinoIcons.square_grid_2x2, '${_metricsService.tabCount}', gxRed),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: gxRed.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _currentTime,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: gxRed,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.3, end: 0);
  }
  
  Widget _buildHeaderMetric(IconData icon, String value, Color gxRed) {
    return Row(
      children: [
        Icon(icon, size: 12, color: gxRed.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(ThemeData theme, Color gxRed) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Command Bar style IDE
          _buildCommandBar(theme, gxRed),
          
          const SizedBox(height: 48),
          
          // Quick Actions (Terminal, DevTools, etc.)
          _buildQuickActions(theme, gxRed),
          
          const SizedBox(height: 48),
          
          // Dev Categories Grid
          _buildDevCategoriesGrid(theme, gxRed),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCommandBar(ThemeData theme, Color gxRed) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt style terminal
          Text(
            '> Tapez une URL, recherchez, ou utilisez :commande',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: gxRed.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          
          // Command input
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: gxRed.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gxRed.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  '❯',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: gxRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    focusNode: _commandFocusNode,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'github.com, :terminal, search query...',
                      hintStyle: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _handleCommand,
                    cursorColor: gxRed,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: gxRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.command, size: 10, color: gxRed.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        'K',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: gxRed.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildQuickActions(ThemeData theme, Color gxRed) {
    final actions = [
      _QuickAction('Terminal', CupertinoIcons.square_list, ':term', widget.onTerminalSelected),
      _QuickAction('DevTools', CupertinoIcons.ant, ':dev', widget.onDevToolsSelected),
      _QuickAction('GitHub', CupertinoIcons.arrow_up_right_square, ':gh', () => _openUrl('https://github.com')),
      _QuickAction('Nouveau Tab', CupertinoIcons.plus_square, ':new', () => Provider.of<TabManager>(context, listen: false).addTab()),
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        
        return Padding(
          padding: EdgeInsets.only(right: index < actions.length - 1 ? 12 : 0),
          child: _buildQuickActionButton(action, gxRed, index),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionButton(_QuickAction action, Color gxRed, int index) {
    return GestureDetector(
      onTap: action.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: gxRed.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 16, color: gxRed),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    action.command,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      color: gxRed.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (300 + index * 80).ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildDevCategoriesGrid(ThemeData theme, Color gxRed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: _devCategories.asMap().entries.map((entry) {
            return _buildDevCategoryCard(entry.value, gxRed, entry.key);
          }).toList(),
        );
      },
    );
  }

  Widget _buildDevCategoryCard(_DevCategory category, Color gxRed, int index) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gxRed.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(category.icon, size: 14, color: gxRed),
              const SizedBox(width: 8),
              Text(
                category.title,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: gxRed,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Links
          ...category.items.map((link) => _buildDevLink(link, gxRed)),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (400 + index * 100).ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildDevLink(_DevLink link, Color gxRed) {
    return GestureDetector(
      onTap: () => _openUrl(link.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: link.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  link.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  link.shortcut,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySidebar(ThemeData theme, Color gxRed) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          left: BorderSide(
            color: gxRed.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: gxRed.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.clock, size: 14, color: gxRed),
                const SizedBox(width: 8),
                Text(
                  'RÉCENT',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: gxRed,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          // Activity list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _recentHistory.length,
              itemBuilder: (context, index) {
                final item = _recentHistory[index];
                return _buildActivityItem(item, gxRed, index);
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildActivityItem(HistoryItem item, Color gxRed, int index) {
    return GestureDetector(
      onTap: () => _openUrl(item.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              FutureBuilder<String?>(
                future: FaviconService.getFaviconWithCache(item.url),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        snapshot.data!,
                        width: 16,
                        height: 16,
                        errorBuilder: (_, __, ___) => Icon(
                          CupertinoIcons.globe,
                          size: 16,
                          color: gxRed.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }
                  return Icon(
                    CupertinoIcons.globe,
                    size: 16,
                    color: gxRed.withValues(alpha: 0.5),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Uri.parse(item.url).host.replaceFirst('www.', ''),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (400 + index * 50).ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildDevFooter(ThemeData theme, Color gxRed) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: gxRed.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Session info
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34C759).withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Session active',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '•',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 16),
              ListenableBuilder(
                listenable: _metricsService,
                builder: (context, _) => Text(
                  _metricsService.formatActiveTime(),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Quick stats
          Row(
            children: [
              _buildFooterStat('Pages', '${_metricsService.pagesVisited}', gxRed),
              const SizedBox(width: 20),
              _buildFooterStat('Data', _metricsService.formatDataUsed(), gxRed),
              const SizedBox(width: 20),
              _buildFooterStat('Network', _metricsService.networkStatus, gxRed),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildFooterStat(String label, String value, Color gxRed) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: gxRed.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// === PAINTERS ===

class _TechGridPainter extends CustomPainter {
  final Color color;
  final double progress;

  _TechGridPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final spacing = 60.0;
    final opacity = 0.03 + (math.sin(progress * math.pi) * 0.02);
    paint.color = color.withValues(alpha: opacity);

    // Grille horizontale
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Grille verticale
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Points aux intersections
    final pointPaint = Paint()
      ..color = color.withValues(alpha: opacity * 2)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TechGridPainter oldDelegate) => 
      oldDelegate.progress != progress;
}

class _ScanlinePainter extends CustomPainter {
  final double progress;

  _ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // Lignes de scan
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => false;
}

// === DATA CLASSES ===

class _DevCategory {
  final String title;
  final IconData icon;
  final List<_DevLink> items;

  const _DevCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _DevLink {
  final String name;
  final String url;
  final String shortcut;
  final Color color;

  const _DevLink(this.name, this.url, this.shortcut, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String command;
  final VoidCallback? onTap;

  const _QuickAction(this.label, this.icon, this.command, this.onTap);
}
