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
import '../../../services/backend_lab/backend_lab_service.dart';
import '../../../models/backend_lab/backend_lab_models.dart';
import '../../common/notilus_logo_image.dart';

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
  
  // Backend Lab state
  String? _selectedServerId;
  bool _isLoadingRoutes = false;
  String? _routesError;

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
    });
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
                                    _buildCommandCenter(gxRed, transparency),
                                    const SizedBox(height: 32),
                                    _buildMetricsDashboard(gxRed, transparency),
                                    const SizedBox(height: 32),
                                    _buildToolsSection(gxRed, transparency),
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
          const NotilusMonogramImage(size: 24),
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
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
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
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
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

  Widget _buildBackendLabPanel(Color gxRed, double transparency) {
    final labService = Provider.of<BackendLabService>(context, listen: true);
    
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
        border: Border(
          left: BorderSide(color: const Color(0xFF00FF88).withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFF00FF88).withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.square_stack_3d_up, size: 14, color: const Color(0xFF00FF88)),
                const SizedBox(width: 8),
                Text(
                  'BACKEND LAB',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00FF88),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs: Servers / Console
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: const Color(0xFF00FF88),
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    indicatorColor: const Color(0xFF00FF88),
                    labelStyle: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'SERVERS'),
                      Tab(text: 'ROUTES'),
                      Tab(text: 'CONSOLE'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00FF88)),
                                      strokeWidth: 2,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading routes...',
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
                            
                            final routes = labService.routes.where((r) => r.serverId == _selectedServerId).toList();
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
                      ],
                    ),
                  ),
                ],
              ),
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
                ? const Color(0xFF00FF88).withOpacity(0.2)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00FF88).withOpacity(0.6)
                  : const Color(0xFF00FF88).withOpacity(0.2),
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
      // Charger les routes du serveur
      await labService.discoverRoutes(serverId);
      
      if (mounted) {
        setState(() {
          _isLoadingRoutes = false;
        });
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
    showDialog(
      context: context,
      builder: (context) => _RouteDetailsDialog(route: route),
    );
  }

  Widget _buildConsoleLogItem(ConsoleLogEntry log, Color gxRed) {
    final levelColor = log.level == 'ERROR'
        ? const Color(0xFFFF5F56)
        : log.level == 'WARNING'
            ? const Color(0xFFFFBD2E)
            : const Color(0xFF00FF88);
    
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

/// Dialog pour afficher les détails d'une route
class _RouteDetailsDialog extends StatelessWidget {
  final DiscoveredRoute route;
  
  const _RouteDetailsDialog({required this.route});
  
  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: accentColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMethodColor(route.method).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      route.method.name,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getMethodColor(route.method),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      route.path,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: Colors.white.withOpacity(0.7)),
                    onPressed: () => Navigator.of(context).pop(),
                    iconSize: 18,
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary
                    if (route.summary != null) ...[
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route.summary!,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Description
                    if (route.description != null) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route.description!,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Path Parameters
                    if (route.pathParams.isNotEmpty) ...[
                      Text(
                        'Path Parameters',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...route.pathParams.map((param) => _buildParameterItem(param, accentColor)),
                      const SizedBox(height: 16),
                    ],
                    // Query Parameters
                    if (route.queryParams.isNotEmpty) ...[
                      Text(
                        'Query Parameters',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...route.queryParams.map((param) => _buildParameterItem(param, accentColor)),
                      const SizedBox(height: 16),
                    ],
                    // Auth
                    if (route.authRequired) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.lock, size: 14, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Authentication required${route.authType != null ? ' (${route.authType})' : ''}',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParameterItem(RouteParameter param, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                param.name,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  param.type,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    color: accentColor,
                  ),
                ),
              ),
              if (param.required) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'REQUIRED',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 7,
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (param.description != null) ...[
            const SizedBox(height: 4),
            Text(
              param.description!,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
          if (param.defaultValue != null) ...[
            const SizedBox(height: 4),
            Text(
              'Default: ${param.defaultValue}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8,
                color: Colors.white.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
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
}

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
  final bool isSecondary;

  _GridPatternPainter({required this.color, this.isSecondary = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Mode secondary : grille plus dense et visible
    final opacity = isSecondary ? 0.08 : 0.03;
    final spacing = isSecondary ? 30.0 : 40.0;
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(opacity)
      ..strokeWidth = isSecondary ? 0.8 : 0.5;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => 
      (oldDelegate as _GridPatternPainter).isSecondary != isSecondary;
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
