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

/// Page d'accueil DevOps - Style monitoring/infrastructure
class DevOpsHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  final VoidCallback? onDevToolsSelected;
  
  const DevOpsHomePage({
    super.key,
    this.onTerminalSelected,
    this.onDevToolsSelected,
  });

  @override
  State<DevOpsHomePage> createState() => _DevOpsHomePageState();
}

class _DevOpsHomePageState extends State<DevOpsHomePage> 
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SettingsService _settings = SettingsService();
  final SystemMetricsService _metricsService = SystemMetricsService();
  late AnimationController _radarController;
  late AnimationController _dataFlowController;
  String _currentTime = '';

  // Services status simulés
  final List<_ServiceStatus> _services = [
    _ServiceStatus('API Gateway', 'Running', true, '99.9%', 12),
    _ServiceStatus('Auth Service', 'Running', true, '99.8%', 45),
    _ServiceStatus('Database', 'Running', true, '99.99%', 8),
    _ServiceStatus('Cache (Redis)', 'Running', true, '100%', 3),
    _ServiceStatus('Message Queue', 'Warning', false, '98.5%', 156),
    _ServiceStatus('CDN', 'Running', true, '99.95%', 2),
  ];

  // Outils DevOps
  final List<_DevOpsCategory> _categories = [
    _DevOpsCategory('Cloud Providers', '☁️', [
      _DevOpsTool('AWS', 'https://aws.amazon.com', const Color(0xFFFF9900)),
      _DevOpsTool('GCP', 'https://cloud.google.com', const Color(0xFF4285F4)),
      _DevOpsTool('Azure', 'https://azure.microsoft.com', const Color(0xFF0078D4)),
      _DevOpsTool('DigitalOcean', 'https://digitalocean.com', const Color(0xFF0080FF)),
    ]),
    _DevOpsCategory('Containers & Orchestration', '🐳', [
      _DevOpsTool('Docker', 'https://docker.com', const Color(0xFF2496ED)),
      _DevOpsTool('Kubernetes', 'https://kubernetes.io', const Color(0xFF326CE5)),
      _DevOpsTool('Helm', 'https://helm.sh', const Color(0xFF0F1689)),
      _DevOpsTool('Rancher', 'https://rancher.com', const Color(0xFF0075A8)),
    ]),
    _DevOpsCategory('CI/CD', '🔄', [
      _DevOpsTool('GitHub Actions', 'https://github.com/features/actions', const Color(0xFF2088FF)),
      _DevOpsTool('GitLab CI', 'https://gitlab.com', const Color(0xFFFC6D26)),
      _DevOpsTool('Jenkins', 'https://jenkins.io', const Color(0xFFD33833)),
      _DevOpsTool('ArgoCD', 'https://argoproj.github.io/cd', const Color(0xFFEF7B4D)),
    ]),
    _DevOpsCategory('Monitoring & Logging', '📊', [
      _DevOpsTool('Grafana', 'https://grafana.com', const Color(0xFFF46800)),
      _DevOpsTool('Prometheus', 'https://prometheus.io', const Color(0xFFE6522C)),
      _DevOpsTool('Datadog', 'https://datadoghq.com', const Color(0xFF632CA6)),
      _DevOpsTool('ELK Stack', 'https://elastic.co', const Color(0xFF00BFB3)),
    ]),
    _DevOpsCategory('Infrastructure as Code', '📜', [
      _DevOpsTool('Terraform', 'https://terraform.io', const Color(0xFF7B42BC)),
      _DevOpsTool('Ansible', 'https://ansible.com', const Color(0xFFEE0000)),
      _DevOpsTool('Pulumi', 'https://pulumi.com', const Color(0xFF8A3391)),
      _DevOpsTool('CloudFormation', 'https://aws.amazon.com/cloudformation', const Color(0xFFFF9900)),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _dataFlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _updateTime();
    _startClock();
    _metricsService.addListener(_onMetricsUpdate);
    _settings.addListener(_onSettingsChanged);
  }

  void _startClock() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _updateTime();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} UTC';
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
    _radarController.dispose();
    _dataFlowController.dispose();
    _searchController.dispose();
    _metricsService.removeListener(_onMetricsUpdate);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _openUrl(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
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
    _searchController.clear();
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
                  Colors.black.withOpacity(0.93),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Grid pattern background
          _buildGridPattern(gxRed),
          
          // Radar sweep effect
          _buildRadarEffect(gxRed),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(gxRed),
                Expanded(
                  child: Row(
                    children: [
                      // Left panel - Service Status
                      _buildServicePanel(gxRed, transparency),
                      
                      // Main content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCommandCenter(gxRed, transparency),
                              const SizedBox(height: 32),
                              _buildMetricsDashboard(gxRed, transparency),
                              const SizedBox(height: 32),
                              _buildToolsSection(gxRed, transparency),
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

  Widget _buildGridPattern(Color gxRed) {
    return CustomPaint(
      painter: _GridPatternPainter(color: gxRed),
      size: Size.infinite,
    );
  }

  Widget _buildRadarEffect(Color gxRed) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return CustomPaint(
          painter: _RadarSweepPainter(
            progress: _radarController.value,
            color: const Color(0xFF00FF88),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader(Color gxRed) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF00FF88).withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const NotilusMonogram(size: 24),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00FF88).withOpacity(0.15),
                  const Color(0xFF326CE5).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _dataFlowController,
                  builder: (context, child) {
                    return Icon(
                      CupertinoIcons.wifi,
                      size: 14,
                      color: Color.lerp(
                        const Color(0xFF00FF88),
                        const Color(0xFF00FF88).withOpacity(0.3),
                        math.sin(_dataFlowController.value * 2 * math.pi).abs(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'DEVOPS COMMAND CENTER',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00FF88),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Status indicators
          _buildStatusIndicator('PROD', true),
          const SizedBox(width: 12),
          _buildStatusIndicator('STAGING', true),
          const SizedBox(width: 12),
          _buildStatusIndicator('DEV', true),
          
          const Spacer(),
          
          if (_settings.showClock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 12,
                    color: const Color(0xFF00FF88),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentTime,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatusIndicator(String label, bool isOnline) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isOnline ? const Color(0xFF00FF88) : const Color(0xFFFF4444)).withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildServicePanel(Color gxRed, double transparency) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(1 - transparency * 0.5),
        border: Border(
          right: BorderSide(color: const Color(0xFF00FF88).withOpacity(0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.square_stack_3d_up,
                  size: 14,
                  color: const Color(0xFF00FF88),
                ),
                const SizedBox(width: 8),
                Text(
                  'SERVICE STATUS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00FF88),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                return _buildServiceRow(_services[index], index);
              },
            ),
          ),
          // Quick actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK DEPLOY',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00FF88).withOpacity(0.7),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDeployButton('Deploy', CupertinoIcons.rocket, const Color(0xFF00FF88)),
                    const SizedBox(width: 8),
                    _buildDeployButton('Rollback', CupertinoIcons.arrow_counterclockwise, const Color(0xFFFFAA00)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildServiceRow(_ServiceStatus service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: service.isHealthy
              ? const Color(0xFF00FF88).withOpacity(0.2)
              : const Color(0xFFFFAA00).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: service.isHealthy ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      service.uptime,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        color: const Color(0xFF00FF88).withOpacity(0.7),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(color: Colors.white.withOpacity(0.3)),
                    ),
                    Text(
                      '${service.latency}ms',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: service.isHealthy
                  ? const Color(0xFF00FF88).withOpacity(0.1)
                  : const Color(0xFFFFAA00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              service.status,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: service.isHealthy ? const Color(0xFF00FF88) : const Color(0xFFFFAA00),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (100 + index * 50).ms);
  }

  Widget _buildDeployButton(String label, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTerminalSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandCenter(Color gxRed, double transparency) {
    final customGreeting = _settings.customGreeting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          customGreeting.isNotEmpty ? customGreeting : '// Infrastructure Control',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          'Monitor, deploy, and scale your infrastructure',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        
        const SizedBox(height: 24),
        
        // Search bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(CupertinoIcons.search, size: 18, color: const Color(0xFF00FF88)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search resources, logs, or documentation...',
                    hintStyle: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                  ),
                  cursorColor: const Color(0xFF00FF88),
                  onSubmitted: _handleSearch,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildMetricsDashboard(Color gxRed, double transparency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFRASTRUCTURE METRICS',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00FF88).withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMetricCard('CPU Usage', '${_metricsService.cpuUsage.toInt()}%', CupertinoIcons.gauge, transparency),
            const SizedBox(width: 12),
            _buildMetricCard('Memory', '${_metricsService.ramUsage.toInt()}%', Icons.memory, transparency),
            const SizedBox(width: 12),
            _buildMetricCard('Network I/O', _metricsService.networkStatus, CupertinoIcons.arrow_up_arrow_down, transparency),
            const SizedBox(width: 12),
            _buildMetricCard('Pods Active', '47/50', CupertinoIcons.cube_box, transparency),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }

  Widget _buildMetricCard(String label, String value, IconData icon, double transparency) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(1 - transparency),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: const Color(0xFF00FF88)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00FF88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection(Color gxRed, double transparency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _categories.asMap().entries.map((entry) {
        return _buildToolCategory(entry.value, transparency, entry.key);
      }).toList(),
    );
  }

  Widget _buildToolCategory(_DevOpsCategory category, double transparency, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00FF88).withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: category.tools.map((tool) {
              return _buildToolButton(tool, transparency);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (600 + index * 80).ms);
  }

  Widget _buildToolButton(_DevOpsTool tool, double transparency) {
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
                width: 8,
                height: 8,
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
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === DATA CLASSES ===

class _ServiceStatus {
  final String name;
  final String status;
  final bool isHealthy;
  final String uptime;
  final int latency;

  const _ServiceStatus(this.name, this.status, this.isHealthy, this.uptime, this.latency);
}

class _DevOpsCategory {
  final String name;
  final String emoji;
  final List<_DevOpsTool> tools;

  const _DevOpsCategory(this.name, this.emoji, this.tools);
}

class _DevOpsTool {
  final String name;
  final String url;
  final Color color;

  const _DevOpsTool(this.name, this.url, this.color);
}

// === PAINTERS ===

class _GridPatternPainter extends CustomPainter {
  final Color color;

  _GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarSweepPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarSweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.15);
    final radius = size.width * 0.15;
    
    final sweepAngle = progress * 2 * math.pi;
    
    final gradient = SweepGradient(
      startAngle: sweepAngle,
      endAngle: sweepAngle + math.pi / 2,
      colors: [
        color.withOpacity(0.2),
        color.withOpacity(0.05),
        Colors.transparent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, paint);
    
    // Radar line
    final linePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1;
    
    final lineEnd = Offset(
      center.dx + radius * math.cos(sweepAngle),
      center.dy + radius * math.sin(sweepAngle),
    );
    
    canvas.drawLine(center, lineEnd, linePaint);
  }

  @override
  bool shouldRepaint(_RadarSweepPainter oldDelegate) => 
      oldDelegate.progress != progress;
}
