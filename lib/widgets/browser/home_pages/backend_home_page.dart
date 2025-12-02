import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../../services/tab_manager.dart';
import '../../../core/services/wallpaper_manager.dart';
import '../../../services/settings_service.dart';
import '../../../services/system_metrics_service.dart';
import '../../../core/services/color_theme_manager.dart';
import '../../common/notilus_monogram.dart';

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
    
    _updateTime();
    _startClock();
    _metricsService.addListener(_onMetricsUpdate);
    _settings.addListener(_onSettingsChanged);
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

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.92),
            BlendMode.srcOver,
          ),
        ),
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
        color: Colors.black.withOpacity(1 - transparency * 0.5),
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
                            color: const Color(0xFF27C93F).withOpacity(_pulseController.value * 0.5),
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
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  _MatrixRainPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.03);
    
    final chars = '01アイウエオカキクケコ{}[]<>/\\';
    final random = math.Random(42);
    final columns = size.width ~/ 20;
    
    for (int i = 0; i < columns; i++) {
      final x = i * 20.0;
      final speed = 0.5 + random.nextDouble() * 0.5;
      final offset = random.nextDouble();
      
      for (int j = 0; j < 10; j++) {
        final y = ((progress * speed + offset + j * 0.1) % 1.2) * size.height - size.height * 0.1;
        final opacity = (1 - (j / 10)) * 0.03;
        paint.color = color.withOpacity(opacity);
        
        final char = chars[random.nextInt(chars.length)];
        final textPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
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
  bool shouldRepaint(_MatrixRainPainter oldDelegate) => true;
}
