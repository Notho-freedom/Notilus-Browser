import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/tab_manager.dart';
import '../../../core/services/wallpaper_manager.dart';
import '../../../services/settings_service.dart';
import '../../../services/system_metrics_service.dart';
import '../../../core/services/color_theme_manager.dart';
import '../../../services/backend_lab/backend_lab_service.dart';
import '../../../models/backend_lab/backend_lab_models.dart';
import '../../../services/history_service.dart';
import '../../../models/history_item.dart';
import '../../../services/ai_service.dart';
import '../../common/notilus_logo_image.dart';
import '../../common/gx_futuristic_dialog.dart';
import '../../common/gx_futuristic_components.dart';
import '../../common/hack_loading_indicator.dart';
import '../../../core/constants/notilus_fonts.dart';

/// Page d'accueil Backend Developer - Style terminal/serveur
class BackendHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  final VoidCallback? onDevToolsSelected;
  
  const BackendHomePage({
    super.key,
    this.onTerminalSelected,
    this.onDevToolsSelected,
  });

  @override
  State<BackendHomePage> createState() => _BackendHomePageState();
}

class _BackendHomePageState extends State<BackendHomePage> 
    with TickerProviderStateMixin {
  final TextEditingController _commandController = TextEditingController();
  final SettingsService _settings = SettingsService();
  final SystemMetricsService _metricsService = SystemMetricsService();
  late AnimationController _pulseController;
  late AnimationController _matrixController;
  String _currentTime = '';
  String _uptime = '0d 0h 0m';
  
  // Backend Lab state
  String? _selectedServerId;
  bool _isLoadingRoutes = false;
  String? _routesError;
  late TabController _tabController;
  
  // History servers
  List<DiscoveredServer> _historyServers = [];
  bool _isLoadingHistory = false;
  
  // Langages Backend
  final List<_BackendLang> _languages = [
    _BackendLang('Node.js', 'https://nodejs.org', '🟢', const Color(0xFF339933)),
    _BackendLang('Python', 'https://python.org', '🐍', const Color(0xFF3776AB)),
    _BackendLang('Go', 'https://go.dev', '🔵', const Color(0xFF00ADD8)),
    _BackendLang('Rust', 'https://rust-lang.org', '🦀', const Color(0xFFDEA584)),
    _BackendLang('Java', 'https://java.com', '☕', const Color(0xFFED8B00)),
    _BackendLang('C#', 'https://docs.microsoft.com/dotnet/csharp/', '💜', const Color(0xFF512BD4)),
    _BackendLang('Ruby', 'https://ruby-lang.org', '💎', const Color(0xFFCC342D)),
    _BackendLang('PHP', 'https://php.net', '🐘', const Color(0xFF777BB4)),
  ];

  // Outils Backend
  final List<_ToolSection> _tools = [
    _ToolSection('Databases', CupertinoIcons.tray_full, [
      _BackendTool('PostgreSQL', 'https://postgresql.org', const Color(0xFF336791)),
      _BackendTool('MongoDB', 'https://mongodb.com', const Color(0xFF47A248)),
      _BackendTool('Redis', 'https://redis.io', const Color(0xFFDC382D)),
      _BackendTool('MySQL', 'https://mysql.com', const Color(0xFF4479A1)),
    ]),
    _ToolSection('Infrastructure', CupertinoIcons.cloud, [
      _BackendTool('Docker', 'https://docker.com', const Color(0xFF2496ED)),
      _BackendTool('Kubernetes', 'https://kubernetes.io', const Color(0xFF326CE5)),
      _BackendTool('AWS', 'https://aws.amazon.com', const Color(0xFFFF9900)),
      _BackendTool('Terraform', 'https://terraform.io', const Color(0xFF7B42BC)),
    ]),
    _ToolSection('APIs & Docs', CupertinoIcons.doc_text, [
      _BackendTool('Swagger', 'https://swagger.io', const Color(0xFF85EA2D)),
      _BackendTool('Postman', 'https://postman.com', const Color(0xFFFF6C37)),
      _BackendTool('GraphQL', 'https://graphql.org', const Color(0xFFE10098)),
      _BackendTool('gRPC', 'https://grpc.io', const Color(0xFF244C5A)),
    ]),
  ];

  final List<String> _devQuotes = [
    "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. — Martin Fowler",
    "First, solve the problem. Then, write the code. — John Johnson",
    "Talk is cheap. Show me the code. — Linus Torvalds",
    "The best error message is the one that never shows up. — Thomas Fuchs",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _matrixController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // TabController pour 4 onglets: SERVERS, ROUTES, CONSOLE, HISTORY
    _tabController = TabController(length: 4, vsync: this);
    
    _updateTime();
    _startClock();
    _metricsService.addListener(_onMetricsUpdate);
    _settings.addListener(_onSettingsChanged);
    
    // Initialiser Backend Lab (utilise l'instance partagée du Provider)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final labService = Provider.of<BackendLabService>(context, listen: false);
      if (!labService.isConnected) {
        labService.checkConnection().then((_) {
          if (labService.isConnected && mounted) {
            labService.getServers();
            labService.connectConsole();
          }
        });
      } else {
        // Déjà connecté, juste rafraîchir les données
        labService.getServers();
        labService.connectConsole(); // connectConsole vérifie déjà si déjà connecté
      }
      
      // Charger les serveurs de l'historique
      _loadHistoryServers();
    });
  }
  
  Future<void> _loadHistoryServers() async {
    setState(() => _isLoadingHistory = true);
    try {
      final historyService = HistoryService();
      final history = await historyService.getHistory();
      
      // Extraire les serveurs uniques de l'historique
      final serverMap = <String, DiscoveredServer>{};
      
      for (final item in history) {
        try {
          final uri = Uri.parse(item.url);
          final host = uri.host;
          final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
          
          // Exclure les serveurs locaux (localhost et IPs locales)
          final isLocal = host == 'localhost' || 
                         host == '127.0.0.1' || 
                         host.startsWith('192.168.') || 
                         host.startsWith('10.') || 
                         host.startsWith('172.');
          
          if (!isLocal) {
            final serverId = '$host:$port';
            if (!serverMap.containsKey(serverId)) {
              serverMap[serverId] = DiscoveredServer(
                id: serverId,
                host: host,
                port: port,
                protocol: uri.scheme,
                name: item.title,
                status: ServerStatus.unknown,
              );
            }
          }
        } catch (e) {
          // Ignorer les URLs invalides
        }
      }
      
      if (mounted) {
        setState(() {
          _historyServers = serverMap.values.toList();
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _startClock() async {
    int uptimeMinutes = 0;
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _updateTime();
        uptimeMinutes++;
        if (uptimeMinutes % 60 == 0) {
          setState(() {
            final hours = uptimeMinutes ~/ 60;
            final days = hours ~/ 24;
            final h = hours % 24;
            final m = uptimeMinutes % 60;
            _uptime = '${days}d ${h}h ${m}m';
          });
        }
      }
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  void _onMetricsUpdate() {
    if (mounted) setState(() {});
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _matrixController.dispose();
    _tabController.dispose();
    _commandController.dispose();
    _metricsService.removeListener(_onMetricsUpdate);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _openUrl(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  void _handleCommand(String cmd) {
    if (cmd.trim().isEmpty) return;
    
    // Commandes spéciales
    if (cmd.startsWith('./') || cmd.startsWith('curl') || cmd.startsWith('npm') || cmd.startsWith('docker')) {
      widget.onTerminalSelected?.call();
      _commandController.clear();
      return;
    }
    
    final tabManager = Provider.of<TabManager>(context, listen: false);
    String url = cmd.trim();
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(cmd)}';
      }
    }
    tabManager.addTab(url: url);
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    final wallpaperManager = context.watch<WallpaperManager>();
    final transparency = _settings.widgetTransparency;
    final currentUrl = wallpaperManager.current;

    return Container(
      decoration: BoxDecoration(
        image: currentUrl.isNotEmpty && !wallpaperManager.isVideo
            ? DecorationImage(
                image: CachedNetworkImageProvider(currentUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.92),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Matrix-style falling code effect
          _buildMatrixBackground(gxRed),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Terminal-style header
                _buildTerminalHeader(gxRed),
                
                Expanded(
                  child: Row(
                    children: [
                      // Left panel - System status
                      _buildSystemPanel(gxRed, transparency),
                      
                      // Main content
                      Expanded(
                        child: Row(
                          children: [
                            // Main content area
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Command prompt section
                                    _buildCommandSection(gxRed, transparency),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Languages grid
                                    _buildLanguagesSection(gxRed, transparency),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Tools sections
                                    _buildToolsSections(gxRed, transparency),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Quote
                                    if (_settings.showQuotes)
                                      _buildQuoteSection(gxRed, transparency),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Right panel - Server list + FastAPI Console
                            _buildBackendLabPanel(gxRed, transparency),
                          ],
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
    );
  }

  Widget _buildMatrixBackground(Color gxRed) {
    return AnimatedBuilder(
      animation: _matrixController,
      builder: (context, child) {
        return CustomPaint(
          painter: _MatrixRainPainter(
            progress: _matrixController.value,
            color: const Color(0xFF339933),
            isSecondary: true, // Mode secondary matrix activé
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildTerminalHeader(Color gxRed) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF339933).withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Terminal window controls
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5F56),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFBD2E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF27C93F),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF339933).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF339933).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🖥️', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  'BACKEND DEV',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF339933),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'user@notilus:~\$',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              color: const Color(0xFF339933),
            ),
          ),
          const SizedBox(width: 16),
          if (_settings.showClock)
            Text(
              _currentTime,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSystemPanel(Color gxRed, double transparency) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
        border: Border(
          right: BorderSide(color: const Color(0xFF339933).withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27C93F),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF27C93F).withOpacity((_pulseController.value * 0.5).clamp(0.0, 1.0)),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'SYSTEM STATUS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF339933),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),
          
          // Metrics
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMetricRow('CPU', '${_metricsService.cpuUsage.toInt()}%', _metricsService.cpuUsage / 100),
                const SizedBox(height: 16),
                _buildMetricRow('RAM', '${_metricsService.ramUsage.toInt()}%', _metricsService.ramUsage / 100),
                const SizedBox(height: 16),
                _buildMetricRow('DISK', '67%', 0.67),
                const SizedBox(height: 16),
                _buildMetricRow('NET', _metricsService.networkStatus, 0.85),
                
                const SizedBox(height: 24),
                
                // Quick info
                _buildInfoRow('Uptime', _uptime),
                _buildInfoRow('Processes', '142'),
                _buildInfoRow('Containers', '7 running'),
                _buildInfoRow('Load Avg', '2.1, 1.8, 1.6'),
                
                const SizedBox(height: 24),
                
                // Quick actions
                Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF339933),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickAction('Terminal', CupertinoIcons.square_list, widget.onTerminalSelected),
                _buildQuickAction('DevTools', CupertinoIcons.ant, widget.onDevToolsSelected),
                _buildQuickAction('Docker', CupertinoIcons.cube_box, () => _openUrl('https://hub.docker.com')),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildMetricRow(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF339933),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(
              progress > 0.8 ? const Color(0xFFFF5F56) : const Color(0xFF339933),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF339933)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandSection(Color gxRed, double transparency) {
    final customGreeting = _settings.customGreeting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting
        Text(
          customGreeting.isNotEmpty ? customGreeting : '# Welcome back, Developer',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          '// Ready to build scalable systems',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            color: const Color(0xFF339933).withOpacity(0.7),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        
        const SizedBox(height: 32),
        
        // Command input
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF339933).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF339933).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
                child: Text(
                  '\$ ~',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF339933),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'type a command, URL, or search...',
                    hintStyle: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                  cursorColor: const Color(0xFF339933),
                  onSubmitted: _handleCommand,
                ),
              ),
              IconButton(
                onPressed: () => _handleCommand(_commandController.text),
                icon: Icon(
                  CupertinoIcons.return_icon,
                  size: 18,
                  color: const Color(0xFF339933),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildLanguagesSection(Color gxRed, double transparency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// Languages & Runtimes',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            color: const Color(0xFF339933).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _languages.asMap().entries.map((entry) {
            return _buildLanguageCard(entry.value, transparency, entry.key);
          }).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }

  Widget _buildLanguageCard(_BackendLang lang, double transparency, int index) {
    return GestureDetector(
      onTap: () => _openUrl(lang.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: lang.color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(lang.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                lang.name,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: lang.color,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 300.ms,
      delay: (500 + index * 40).ms,
    ).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildToolsSections(Color gxRed, double transparency) {
    return Column(
      children: _tools.asMap().entries.map((entry) {
        return _buildToolSection(entry.value, transparency, entry.key);
      }).toList(),
    );
  }

  Widget _buildToolSection(_ToolSection section, double transparency, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, size: 14, color: const Color(0xFF339933)),
              const SizedBox(width: 8),
              Text(
                '// ${section.name}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: const Color(0xFF339933).withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: section.tools.map((tool) => _buildToolChip(tool, transparency)).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (700 + index * 100).ms);
  }

  Widget _buildToolChip(_BackendTool tool, double transparency) {
    return GestureDetector(
      onTap: () => _openUrl(tool.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tool.color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tool.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tool.name,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackendLabPanel(Color gxRed, double transparency) {
    final labService = Provider.of<BackendLabService>(context, listen: true);
    
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
        border: Border(
          left: BorderSide(color: const Color(0xFF339933).withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFF339933).withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.square_stack_3d_up, size: 14, color: const Color(0xFF339933)),
                const SizedBox(width: 8),
                Text(
                  'BACKEND LAB',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF339933),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs: Servers / Routes / Console / History
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF339933),
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
                  indicatorColor: const Color(0xFF339933),
                  labelStyle: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'SERVERS'),
                    Tab(text: 'ROUTES'),
                    Tab(text: 'CONSOLE'),
                    Tab(text: 'HISTORY'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                        // Server list
                        ListenableBuilder(
                          listenable: labService,
                          builder: (context, _) {
                            final servers = labService.servers;
                            if (servers.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.square_stack_3d_up,
                                      size: 32,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No servers',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: servers.length,
                              itemBuilder: (context, index) {
                                final server = servers[index];
                                return _buildServerItem(server, gxRed);
                              },
                            );
                          },
                        ),
                        // Routes list (for selected server)
                        ListenableBuilder(
                          listenable: labService,
                          builder: (context, _) {
                            if (_selectedServerId == null) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.arrow_right_circle,
                                      size: 32,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Select a server to view routes',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            if (_isLoadingRoutes) {
                              return Center(
                                child: HackLoadingIndicator(
                                  accentColor: const Color(0xFF339933),
                                ),
                              );
                            }
                            
                            if (_routesError != null) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.exclamationmark_triangle,
                                      size: 32,
                                      color: Colors.red.withOpacity(0.7),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _routesError!,
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        color: Colors.red.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            // Filtrer les routes par serverId, en vérifiant aussi les variantes possibles
                            final routes = labService.routes.where((r) {
                              // Vérifier l'ID exact
                              if (r.serverId == _selectedServerId) return true;
                              
                              // Vérifier aussi si le serveur a été découvert avec un ID différent
                              // (par exemple, si le serveur de l'historique a été ajouté)
                              final selectedServer = labService.servers.firstWhere(
                                (s) => s.id == _selectedServerId,
                                orElse: () => DiscoveredServer(id: '', port: 0),
                              );
                              
                              if (selectedServer.id.isNotEmpty) {
                                // Vérifier si la route correspond au host:port du serveur sélectionné
                                final routeServer = labService.servers.firstWhere(
                                  (s) => s.id == r.serverId,
                                  orElse: () => DiscoveredServer(id: '', port: 0),
                                );
                                
                                if (routeServer.id.isNotEmpty) {
                                  return routeServer.host == selectedServer.host && 
                                         routeServer.port == selectedServer.port;
                                }
                              }
                              
                              return false;
                            }).toList();
                            if (routes.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.arrow_right_circle,
                                      size: 32,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No routes found',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: routes.length,
                              itemBuilder: (context, index) {
                                final route = routes[index];
                                return _buildRouteItem(route, gxRed);
                              },
                            );
                          },
                        ),
                        // FastAPI Console
                        ListenableBuilder(
                          listenable: labService,
                          builder: (context, _) {
                            final logs = labService.consoleLogs;
                            if (logs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.text_alignleft,
                                      size: 32,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No logs',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final log = logs[logs.length - 1 - index]; // Reverse order
                                return _buildConsoleLogItem(log, gxRed);
                              },
                            );
                          },
                        ),
                        // History Servers
                        _isLoadingHistory
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF339933)),
                                      strokeWidth: 2,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading history servers...',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _historyServers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.clock,
                                          size: 32,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No servers in history',
                                          style: TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 10,
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _historyServers.length,
                                    itemBuilder: (context, index) {
                                      final server = _historyServers[index];
                                      return _buildServerItem(server, gxRed);
                                    },
                                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerItem(DiscoveredServer server, Color gxRed) {
    final statusColor = server.status == ServerStatus.running
        ? const Color(0xFF22C55E)
        : Colors.grey;
    final isSelected = _selectedServerId == server.id;
    
    return GestureDetector(
      onTap: () => _onServerSelected(server.id),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF339933).withOpacity(0.2)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF339933).withOpacity(0.6)
                  : const Color(0xFF339933).withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name ?? 'Unknown',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${server.host}:${server.port}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 8,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleLogItem(ConsoleLogEntry log, Color gxRed) {
    final levelColor = log.level == 'ERROR'
        ? const Color(0xFFFF5F56)
        : log.level == 'WARNING'
            ? const Color(0xFFFFBD2E)
            : const Color(0xFF339933);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: levelColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.timestamp != null)
                  Text(
                    log.timestamp.toString().substring(11, 19),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 7,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _onServerSelected(String serverId) async {
    if (_selectedServerId == serverId) {
      // Déjà sélectionné, désélectionner
      setState(() {
        _selectedServerId = null;
        _routesError = null;
      });
      return;
    }
    
    setState(() {
      _selectedServerId = serverId;
      _isLoadingRoutes = true;
      _routesError = null;
    });
    
    final labService = Provider.of<BackendLabService>(context, listen: false);
    
    try {
      // Vérifier si le serveur existe dans BackendLab
      DiscoveredServer? server = labService.servers.firstWhere(
        (s) => s.id == serverId,
        orElse: () => DiscoveredServer(id: '', port: 0),
      );
      
      // Si le serveur n'existe pas, vérifier s'il vient de l'historique
      if (server.id.isEmpty) {
        final historyServer = _historyServers.firstWhere(
          (s) => s.id == serverId,
          orElse: () => DiscoveredServer(id: '', port: 0),
        );
        
        if (historyServer.id.isNotEmpty) {
          // Découvrir/ajouter le serveur de l'historique à BackendLab
          server = await labService.discoverOrAddServer(
            host: historyServer.host,
            port: historyServer.port,
            protocol: historyServer.protocol,
            name: historyServer.name,
          );
          
          if (server != null && server.id.isNotEmpty) {
            // Mettre à jour l'ID sélectionné avec celui du serveur découvert
            setState(() {
              _selectedServerId = server!.id;
            });
          } else {
            // Si la découverte échoue, utiliser quand même le serveur de l'historique
            server = historyServer;
          }
        }
      }
      
      if (server != null && server.id.isNotEmpty) {
        // Redirection automatique vers l'onglet ROUTES avant le scan
        if (mounted) {
          _tabController.animateTo(1);
        }
        
        // Charger les routes du serveur
        await labService.discoverRoutes(server.id);
        
        if (mounted) {
          setState(() {
            _isLoadingRoutes = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingRoutes = false;
            _routesError = 'Server not found or unavailable';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
          _routesError = 'Error loading routes: $e';
        });
      }
    }
  }
  
  Widget _buildRouteItem(DiscoveredRoute route, Color gxRed) {
    final methodColor = _getMethodColor(route.method);
    
    return GestureDetector(
      onTap: () => _showRouteDetails(route),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: methodColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: methodColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      route.method.name,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: methodColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.path,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (route.summary != null) ...[
                const SizedBox(height: 4),
                Text(
                  route.summary!,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (route.pathParams.isNotEmpty || route.queryParams.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (route.pathParams.isNotEmpty)
                      _buildParamBadge('${route.pathParams.length} path', Colors.blue),
                    if (route.queryParams.isNotEmpty) ...[
                      if (route.pathParams.isNotEmpty) const SizedBox(width: 4),
                      _buildParamBadge('${route.queryParams.length} query', Colors.orange),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildParamBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 7,
          color: color,
        ),
      ),
    );
  }
  
  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.GET:
        return const Color(0xFF4CAF50);
      case HttpMethod.POST:
        return const Color(0xFF2196F3);
      case HttpMethod.PUT:
        return const Color(0xFFFF9800);
      case HttpMethod.DELETE:
        return const Color(0xFFF44336);
      case HttpMethod.PATCH:
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }
  
  void _showRouteDetails(DiscoveredRoute route) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = colorTheme.nativeSecondaryColor;
    final labService = Provider.of<BackendLabService>(context, listen: false);
    final server = labService.servers.firstWhere(
      (s) => s.id == route.serverId,
      orElse: () => DiscoveredServer(id: route.serverId, port: 0),
    );
    
    // Contrôleurs pour les paramètres
    final pathParamControllers = <String, TextEditingController>{};
    final queryParamControllers = <String, TextEditingController>{};
    
    // Initialiser les contrôleurs avec les valeurs par défaut
    for (final param in route.pathParams) {
      pathParamControllers[param.name] = TextEditingController(
        text: param.defaultValue?.toString() ?? '',
      );
    }
    for (final param in route.queryParams) {
      queryParamControllers[param.name] = TextEditingController(
        text: param.defaultValue?.toString() ?? '',
      );
    }
    
    GxFuturisticDialog.show(
      context: context,
      title: '${route.method.name} ${route.path}',
      titleIcon: CupertinoIcons.arrow_right_circle,
      accentColor: route.methodColor,
      width: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (route.summary != null || route.description != null) ...[
            if (route.summary != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  route.summary!,
                  style: NotilusFonts.rajdhani(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (route.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  route.description!,
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
          ],
          
          // Path Parameters
          if (route.pathParams.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Path Parameters',
                style: NotilusFonts.rajdhani(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...route.pathParams.map((param) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          param.name,
                          style: NotilusFonts.rajdhani(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (param.required)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                'REQUIRED',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 8,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (param.description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 2),
                        child: Text(
                          param.description!,
                          style: NotilusFonts.rajdhani(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    GxFuturisticInput(
                      controller: pathParamControllers[param.name]!,
                      hint: 'Enter ${param.name} (${param.type})',
                      accentColor: accentColor,
                    ),
                  ],
                ),
              );
            }),
          ],
          
          // Query Parameters
          if (route.queryParams.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'Query Parameters',
                style: NotilusFonts.rajdhani(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...route.queryParams.map((param) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          param.name,
                          style: NotilusFonts.rajdhani(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (param.required)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                'REQUIRED',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 8,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (param.description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 2),
                        child: Text(
                          param.description!,
                          style: NotilusFonts.rajdhani(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    GxFuturisticInput(
                      controller: queryParamControllers[param.name]!,
                      hint: 'Enter ${param.name} (${param.type})',
                      accentColor: accentColor,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
      actions: [
        GxFuturisticButton(
          label: 'OK',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () {
            Navigator.of(context).pop();
            // Nettoyer les contrôleurs
            for (final controller in pathParamControllers.values) {
              controller.dispose();
            }
            for (final controller in queryParamControllers.values) {
              controller.dispose();
            }
          },
        ),
        GxFuturisticButton(
          label: 'EXECUTER',
          icon: CupertinoIcons.play_fill,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: route.methodColor,
          onPressed: () async {
            // Construire l'URL avec les paramètres
            String finalPath = route.path;
            for (final param in route.pathParams) {
              final value = pathParamControllers[param.name]?.text ?? '';
              finalPath = finalPath.replaceAll('{${param.name}}', value);
            }
            
            final uri = Uri.parse('${server.baseUrl}$finalPath');
            final finalUri = uri.replace(
              queryParameters: {
                for (final param in route.queryParams)
                  if (queryParamControllers[param.name]?.text?.isNotEmpty ?? false)
                    param.name: queryParamControllers[param.name]!.text,
              },
            );
            
            // Exécuter la requête HTTP
            try {
              http.Response response;
              switch (route.method) {
                case HttpMethod.GET:
                  response = await http.get(finalUri);
                  break;
                case HttpMethod.POST:
                  response = await http.post(finalUri);
                  break;
                case HttpMethod.PUT:
                  response = await http.put(finalUri);
                  break;
                case HttpMethod.DELETE:
                  response = await http.delete(finalUri);
                  break;
                case HttpMethod.PATCH:
                  response = await http.patch(finalUri);
                  break;
                default:
                  response = await http.get(finalUri);
              }
              
              // Afficher le résultat
              if (mounted) {
                Navigator.of(context).pop();
                // Nettoyer les contrôleurs
                for (final controller in pathParamControllers.values) {
                  controller.dispose();
                }
                for (final controller in queryParamControllers.values) {
                  controller.dispose();
                }
                
                // Afficher le résultat dans un nouveau dialog
                GxFuturisticDialog.show(
                  context: context,
                  title: 'Response',
                  titleIcon: CupertinoIcons.check_mark_circled,
                  accentColor: response.statusCode >= 200 && response.statusCode < 300
                      ? const Color(0xFF4CAF50)
                      : Colors.red,
                  width: 700,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${response.statusCode}',
                          style: NotilusFonts.rajdhani(
                            fontSize: 12,
                            color: response.statusCode >= 200 && response.statusCode < 300
                                ? const Color(0xFF4CAF50)
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Response Body:',
                          style: NotilusFonts.rajdhani(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          response.body.length > 1000
                              ? '${response.body.substring(0, 1000)}...'
                              : response.body,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    GxFuturisticButton(
                      label: 'Fermer',
                      variant: GxFuturisticButtonVariant.secondary,
                      accentColor: accentColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.of(context).pop(); // Fermer la popup de chargement
                // Nettoyer les contrôleurs
                for (final controller in pathParamControllers.values) {
                  controller.dispose();
                }
                for (final controller in queryParamControllers.values) {
                  controller.dispose();
                }
                
                // Analyser l'erreur avec l'IA
                await _analyzeErrorWithAI(context, e, route, finalUri, accentColor);
              }
            }
          },
        ),
      ],
    );
  }

  /// Analyse une erreur avec l'IA et affiche le résultat
  Future<void> _analyzeErrorWithAI(
    BuildContext context,
    dynamic error,
    DiscoveredRoute route,
    Uri requestUri,
    Color accentColor,
  ) async {
    // Afficher la popup de transition auto-fermante
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GxFuturisticDialog(
        title: 'Analyse de l\'erreur',
        titleIcon: CupertinoIcons.sparkles,
        accentColor: accentColor,
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HackLoadingIndicator(
              accentColor: accentColor,
              message: 'Analyse de l\'erreur avec l\'IA...',
              messages: [
                '> Analyse de l\'erreur HTTP...',
                '> Identification du problème...',
                '> Recherche de solutions...',
                '> Génération de recommandations...',
              ],
            ),
          ],
        ),
      ),
    );

    // Attendre un peu pour que la popup s'affiche
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final aiService = AiService();
      final settings = SettingsService();
      
      // Construire le prompt pour l'IA
      final errorMessage = error.toString();
      final prompt = '''Analyse cette erreur d'exécution de route API et fournis une explication structurée.

Contexte:
- Route: ${route.method.name} ${route.path}
- URL complète: $requestUri
- Erreur: $errorMessage

Fournis une réponse au format JSON avec les clés suivantes:
- "summary": Un résumé court de l'erreur (1-2 phrases)
- "cause": La cause probable de l'erreur
- "solutions": Une liste de solutions possibles (tableau de strings)
- "prevention": Comment éviter cette erreur à l'avenir

Réponds UNIQUEMENT en JSON valide, sans texte avant ou après.''';

      final response = await aiService.chat(
        prompt: prompt,
        type: 'error_analysis',
        model: settings.aiPreferredModel.isNotEmpty ? settings.aiPreferredModel : null,
      );

      // Fermer la popup de transition
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher le résultat de l'IA
      if (mounted && response != null) {
        String? analysisText = response['content'] as String?;
        analysisText ??= response['response'] as String?;
        analysisText ??= response['message'] as String?;
        analysisText ??= response['text'] as String?;

        // Essayer de parser le JSON si présent
        Map<String, dynamic>? parsedAnalysis;
        if (analysisText != null) {
          try {
            // Extraire le JSON si présent dans le texte
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(analysisText);
            if (jsonMatch != null) {
              parsedAnalysis = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
            }
          } catch (e) {
            // Si le parsing échoue, utiliser le texte brut
          }
        }

        // Afficher le résultat structuré
        GxFuturisticDialog.show(
          context: context,
          title: 'Analyse IA de l\'erreur',
          titleIcon: CupertinoIcons.sparkles,
          accentColor: accentColor,
          width: 700,
          child: SingleChildScrollView(
            child: parsedAnalysis != null
                ? _buildStructuredAnalysis(parsedAnalysis, accentColor)
                : _buildTextAnalysis(analysisText ?? 'Analyse non disponible', accentColor),
          ),
          actions: [
            GxFuturisticButton(
              label: 'Fermer',
              variant: GxFuturisticButtonVariant.secondary,
              accentColor: accentColor,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      } else {
        // Si l'IA n'a pas répondu, afficher l'erreur brute
        if (mounted) {
          GxFuturisticDialog.show(
            context: context,
            title: 'Erreur',
            titleIcon: CupertinoIcons.exclamationmark_triangle,
            accentColor: Colors.red,
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erreur lors de l\'exécution:',
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  error.toString(),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'L\'analyse IA n\'a pas pu être effectuée.',
                  style: NotilusFonts.rajdhani(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            actions: [
              GxFuturisticButton(
                label: 'Fermer',
                variant: GxFuturisticButtonVariant.secondary,
                accentColor: Colors.red,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }
      }
    } catch (aiError) {
      // Si l'analyse IA échoue, fermer la popup et afficher l'erreur brute
      if (mounted) {
        Navigator.of(context).pop(); // Fermer la popup de transition
        
        GxFuturisticDialog.show(
          context: context,
          title: 'Erreur',
          titleIcon: CupertinoIcons.exclamationmark_triangle,
          accentColor: Colors.red,
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Erreur lors de l\'exécution:',
                style: NotilusFonts.rajdhani(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                error.toString(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'L\'analyse IA a échoué: $aiError',
                style: NotilusFonts.rajdhani(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          actions: [
            GxFuturisticButton(
              label: 'Fermer',
              variant: GxFuturisticButtonVariant.secondary,
              accentColor: Colors.red,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      }
    }
  }

  /// Construit l'affichage structuré de l'analyse IA
  Widget _buildStructuredAnalysis(Map<String, dynamic> analysis, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Résumé
        if (analysis['summary'] != null) ...[
          _buildAnalysisSection(
            'Résumé',
            analysis['summary'].toString(),
            accentColor,
            CupertinoIcons.info_circle,
          ),
          const SizedBox(height: 16),
        ],
        
        // Cause
        if (analysis['cause'] != null) ...[
          _buildAnalysisSection(
            'Cause probable',
            analysis['cause'].toString(),
            accentColor,
            CupertinoIcons.exclamationmark_circle,
          ),
          const SizedBox(height: 16),
        ],
        
        // Solutions
        if (analysis['solutions'] != null) ...[
          _buildSolutionsSection(
            'Solutions possibles',
            analysis['solutions'],
            accentColor,
          ),
          const SizedBox(height: 16),
        ],
        
        // Prévention
        if (analysis['prevention'] != null) ...[
          _buildAnalysisSection(
            'Prévention',
            analysis['prevention'].toString(),
            accentColor,
            CupertinoIcons.lock_shield,
          ),
        ],
      ],
    );
  }

  /// Construit une section d'analyse
  Widget _buildAnalysisSection(String title, String content, Color accentColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: NotilusFonts.rajdhani(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section des solutions
  Widget _buildSolutionsSection(String title, dynamic solutions, Color accentColor) {
    List<String> solutionsList = [];
    if (solutions is List) {
      solutionsList = solutions.map((s) => s.toString()).toList();
    } else if (solutions is String) {
      solutionsList = [solutions];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.lightbulb, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: NotilusFonts.rajdhani(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...solutionsList.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      entry.value,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Construit l'affichage texte simple de l'analyse
  Widget _buildTextAnalysis(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10,
          color: Colors.white.withOpacity(0.8),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildQuoteSection(Color gxRed, double transparency) {
    final quote = _devQuotes[DateTime.now().day % _devQuotes.length];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(1 - transparency),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF339933).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '/*',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              color: const Color(0xFF339933).withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quote,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.6),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '*/',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              color: const Color(0xFF339933).withOpacity(0.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 900.ms);
  }
}

// === HACK LOADING INDICATOR ===

// _HackLoadingIndicator remplacé par le composant réutilisable HackLoadingIndicator

// === DATA CLASSES ===

class _BackendLang {
  final String name;
  final String url;
  final String emoji;
  final Color color;

  const _BackendLang(this.name, this.url, this.emoji, this.color);
}

class _ToolSection {
  final String name;
  final IconData icon;
  final List<_BackendTool> tools;

  const _ToolSection(this.name, this.icon, this.tools);
}


class _BackendTool {
  final String name;
  final String url;
  final Color color;

  const _BackendTool(this.name, this.url, this.color);
}

// === PAINTERS ===

class _MatrixRainPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isSecondary;

  _MatrixRainPainter({
    required this.progress,
    required this.color,
    this.isSecondary = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Mode secondary matrix : plus dense et visible
    final baseOpacity = isSecondary ? 0.08 : 0.03;
    final columns = isSecondary ? size.width ~/ 15 : size.width ~/ 20;
    final chars = '01アイウエオカキクケコ{}[]<>/\\';
    final random = math.Random(42);
    
    for (int i = 0; i < columns; i++) {
      final x = i * (isSecondary ? 15.0 : 20.0);
      final speed = 0.5 + random.nextDouble() * 0.5;
      final offset = random.nextDouble();
      final charCount = isSecondary ? 15 : 10;
      
      for (int j = 0; j < charCount; j++) {
        final y = ((progress * speed + offset + j * 0.1) % 1.2) * size.height - size.height * 0.1;
        final opacity = (1 - (j / charCount)) * baseOpacity;
        final paint = Paint()..color = color.withOpacity(opacity);
        
        final char = chars[random.nextInt(chars.length)];
        final fontSize = isSecondary ? 14.0 : 12.0;
        final textPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: fontSize,
              color: paint.color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixRainPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.isSecondary != isSecondary;
}
