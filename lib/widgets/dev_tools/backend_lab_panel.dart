/// Backend Lab Panel
/// Interface avancée pour les tests backend et la découverte de serveurs
library backend_lab_panel;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/backend_lab/backend_lab_service.dart';
import '../../models/backend_lab/backend_lab_models.dart';
import '../../core/services/color_theme_manager.dart';

/// Onglets du Backend Lab
enum BackendLabTab {
  overview,
  servers,
  routes,
  testing,
  security,
  performance,
  capture,
}

extension BackendLabTabExt on BackendLabTab {
  String get label {
    switch (this) {
      case BackendLabTab.overview: return 'Vue d\'ensemble';
      case BackendLabTab.servers: return 'Serveurs';
      case BackendLabTab.routes: return 'Routes';
      case BackendLabTab.testing: return 'Tests API';
      case BackendLabTab.security: return 'Sécurité';
      case BackendLabTab.performance: return 'Performance';
      case BackendLabTab.capture: return 'Capture';
    }
  }
  
  IconData get icon {
    switch (this) {
      case BackendLabTab.overview: return Icons.dashboard_rounded;
      case BackendLabTab.servers: return Icons.dns_rounded;
      case BackendLabTab.routes: return Icons.alt_route_rounded;
      case BackendLabTab.testing: return Icons.science_rounded;
      case BackendLabTab.security: return Icons.shield_rounded;
      case BackendLabTab.performance: return Icons.speed_rounded;
      case BackendLabTab.capture: return Icons.videocam_rounded;
    }
  }
  
  Color get accentColor {
    switch (this) {
      case BackendLabTab.overview: return const Color(0xFF6366F1);
      case BackendLabTab.servers: return const Color(0xFF22C55E);
      case BackendLabTab.routes: return const Color(0xFF3B82F6);
      case BackendLabTab.testing: return const Color(0xFFF59E0B);
      case BackendLabTab.security: return const Color(0xFFEF4444);
      case BackendLabTab.performance: return const Color(0xFF8B5CF6);
      case BackendLabTab.capture: return const Color(0xFF14B8A6);
    }
  }
}

/// Panneau principal Backend Lab
class BackendLabPanel extends StatefulWidget {
  const BackendLabPanel({super.key});

  @override
  State<BackendLabPanel> createState() => _BackendLabPanelState();
}

class _BackendLabPanelState extends State<BackendLabPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BackendLabTab _activeTab = BackendLabTab.overview;
  late BackendLabService _labService;
  bool _isInitialized = false;
  
  // Quick test state
  String _quickMethod = 'GET';
  final _quickUrlController = TextEditingController();
  final _quickBodyController = TextEditingController();
  bool _isRunningTest = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: BackendLabTab.values.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _labService = BackendLabService();
    _initializeService();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() => _activeTab = BackendLabTab.values[_tabController.index]);
    }
  }

  Future<void> _initializeService() async {
    await _labService.checkConnection();
    if (mounted) {
      setState(() => _isInitialized = true);
      if (_labService.isConnected) {
        _labService.refreshAll();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickUrlController.dispose();
    _quickBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accent = colorTheme.nativeSecondaryColor;

    return Container(
      color: const Color(0xFF0A0A0F),
      child: Column(
        children: [
          _buildHeader(accent),
          _buildTabBar(accent),
          Expanded(
            child: _isInitialized
                ? _buildContent()
                : _buildLoadingState(accent),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.15),
            accent.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
        border: Border(bottom: BorderSide(color: accent.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.science_outlined, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BACKEND LAB',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: accent,
                ),
              ),
              Text(
                'Tests API • Sécurité • Performance',
                style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Connection status
          _buildConnectionBadge(accent),
          
          const SizedBox(width: 12),
          
          // Actions
          _IconBtn(
            icon: Icons.refresh,
            tooltip: 'Rafraîchir',
            onTap: () => _labService.refreshAll(),
          ),
          _IconBtn(
            icon: Icons.settings_outlined,
            tooltip: 'Paramètres',
            onTap: _showSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(Color accent) {
    final connected = _labService.isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFF22C55E).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected ? const Color(0xFF22C55E).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: connected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (connected ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Connecté' : 'Déconnecté',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: connected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color accent) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        indicator: const BoxDecoration(),
        dividerColor: Colors.transparent,
        tabs: BackendLabTab.values.map((tab) {
          final isActive = _activeTab == tab;
          return Tab(
            height: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? tab.accentColor.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isActive ? Border.all(color: tab.accentColor.withOpacity(0.3)) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 14,
                    color: isActive ? tab.accentColor : Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? tab.accentColor : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState(Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connexion au Backend Lab...',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildOverviewTab(),
        _buildServersTab(),
        _buildRoutesTab(),
        _buildTestingTab(),
        _buildSecurityTab(),
        _buildPerformanceTab(),
        _buildCaptureTab(),
      ],
    );
  }

  // ============================================================================
  // Overview Tab
  // ============================================================================

  Widget _buildOverviewTab() {
    final stats = _labService.stats;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          _buildStatsRow(stats),
          const SizedBox(height: 24),
          
          // Quick actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildQuickTestCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentActivityCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(OverviewStats? stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
          title: 'Serveurs',
          value: '${stats?.serversDiscovered ?? _labService.servers.length}',
          subtitle: 'Découverts',
          icon: Icons.dns_rounded,
          color: const Color(0xFF22C55E),
          onTap: () => _tabController.animateTo(1),
        ),
        _StatCard(
          title: 'Routes',
          value: '${stats?.routesFound ?? _labService.routes.length}',
          subtitle: 'Mappées',
          icon: Icons.alt_route_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => _tabController.animateTo(2),
        ),
        _StatCard(
          title: 'Tests',
          value: '${stats?.testsRun ?? _labService.testResults.length}',
          subtitle: '${stats?.testsSuccessRate.toStringAsFixed(0) ?? 0}% succès',
          icon: Icons.science_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => _tabController.animateTo(3),
        ),
        _StatCard(
          title: 'Vulnérabilités',
          value: '${stats?.vulnerabilitiesFound ?? _labService.vulnerabilities.length}',
          subtitle: _getVulnSummary(),
          icon: Icons.shield_rounded,
          color: _labService.vulnerabilities.any((v) => v.severity == VulnerabilitySeverity.critical)
              ? const Color(0xFFEF4444)
              : const Color(0xFFF59E0B),
          onTap: () => _tabController.animateTo(4),
        ),
        _StatCard(
          title: 'Captures',
          value: '${_labService.captures.length}',
          subtitle: 'Requêtes',
          icon: Icons.videocam_rounded,
          color: const Color(0xFF14B8A6),
          onTap: () => _tabController.animateTo(6),
        ),
      ],
    );
  }
  
  String _getVulnSummary() {
    final vulns = _labService.vulnerabilities;
    if (vulns.isEmpty) return 'Aucune';
    final critical = vulns.where((v) => v.severity == VulnerabilitySeverity.critical).length;
    final high = vulns.where((v) => v.severity == VulnerabilitySeverity.high).length;
    if (critical > 0) return '$critical critiques';
    if (high > 0) return '$high élevées';
    return '${vulns.length} trouvées';
  }

  Widget _buildQuickTestCard() {
    return _Card(
      title: 'Test Rapide',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFF59E0B),
      child: Column(
        children: [
          // Method + URL
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _quickMethod,
                    dropdownColor: const Color(0xFF1A1A24),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m, style: TextStyle(color: _getMethodColor(m))),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _quickMethod = v!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StyledTextField(
                  controller: _quickUrlController,
                  hint: 'https://api.example.com/endpoint',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Body (for POST/PUT/PATCH)
          if (['POST', 'PUT', 'PATCH'].contains(_quickMethod)) ...[
            _StyledTextField(
              controller: _quickBodyController,
              hint: '{"key": "value"}',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
          ],
          
          // Run button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningTest ? null : _runQuickTest,
              icon: _isRunningTest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(_isRunningTest ? 'Exécution...' : 'Exécuter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _runQuickTest() async {
    if (_quickUrlController.text.isEmpty) return;
    
    setState(() => _isRunningTest = true);
    
    try {
      await _labService.runQuickTest(
        method: _quickMethod,
        url: _quickUrlController.text,
        body: _quickBodyController.text.isNotEmpty ? _quickBodyController.text : null,
        bodyType: _quickBodyController.text.isNotEmpty ? 'json' : 'none',
      );
    } finally {
      if (mounted) setState(() => _isRunningTest = false);
    }
  }

  Widget _buildRecentActivityCard() {
    return _Card(
      title: 'Activité Récente',
      icon: Icons.history_rounded,
      color: const Color(0xFF6366F1),
      child: _labService.testResults.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 32, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune activité',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _labService.testResults.take(5).length,
              itemBuilder: (context, index) {
                final result = _labService.testResults[index];
                return _ActivityItem(result: result);
              },
            ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET': return const Color(0xFF22C55E);
      case 'POST': return const Color(0xFF3B82F6);
      case 'PUT': return const Color(0xFFF59E0B);
      case 'DELETE': return const Color(0xFFEF4444);
      case 'PATCH': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }

  // ============================================================================
  // Servers Tab
  // ============================================================================

  Widget _buildServersTab() {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _labService.isScanning ? null : () => _labService.scanServers(),
                icon: _labService.isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.radar_rounded, size: 16),
                label: Text(_labService.isScanning ? 'Scan...' : 'Scanner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_labService.servers.length} serveurs découverts',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
        
        // Server list
        Expanded(
          child: _labService.servers.isEmpty
              ? _EmptyState(
                  icon: Icons.dns_outlined,
                  title: 'Aucun serveur découvert',
                  subtitle: 'Cliquez sur "Scanner" pour détecter les serveurs locaux',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _labService.servers.length,
                  itemBuilder: (context, index) {
                    final server = _labService.servers[index];
                    return _ServerCard(
                      server: server,
                      onDiscoverRoutes: () => _labService.discoverRoutes(server.id),
                      onHealthCheck: () => _labService.healthCheck(server.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // Routes Tab
  // ============================================================================

  Widget _buildRoutesTab() {
    final routes = _labService.routes;
    
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              Text(
                '${routes.length} routes découvertes',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
              ),
              const Spacer(),
              // Filter by method
              _FilterChip(label: 'Toutes', isActive: true, onTap: () {}),
              _FilterChip(label: 'GET', isActive: false, color: const Color(0xFF22C55E), onTap: () {}),
              _FilterChip(label: 'POST', isActive: false, color: const Color(0xFF3B82F6), onTap: () {}),
            ],
          ),
        ),
        
        // Routes list
        Expanded(
          child: routes.isEmpty
              ? _EmptyState(
                  icon: Icons.alt_route_outlined,
                  title: 'Aucune route découverte',
                  subtitle: 'Découvrez d\'abord des serveurs, puis leurs routes',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return _RouteCard(route: route);
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // Testing Tab
  // ============================================================================

  Widget _buildTestingTab() {
    return Row(
      children: [
        // Left: Test builder
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Column(
              children: [
                _SectionHeader(title: 'Constructeur de Requête', icon: Icons.build_rounded),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Method + URL
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _quickMethod,
                                  dropdownColor: const Color(0xFF1A1A24),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'].map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(m, style: TextStyle(color: _getMethodColor(m))),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => _quickMethod = v!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StyledTextField(
                                controller: _quickUrlController,
                                hint: 'URL de l\'endpoint',
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isRunningTest ? null : _runQuickTest,
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Envoyer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Headers, Body, etc. tabs
                        DefaultTabController(
                          length: 4,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TabBar(
                                  tabs: const [
                                    Tab(text: 'Headers'),
                                    Tab(text: 'Body'),
                                    Tab(text: 'Auth'),
                                    Tab(text: 'Params'),
                                  ],
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white.withOpacity(0.4),
                                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  indicator: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  dividerColor: Colors.transparent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 200,
                                child: TabBarView(
                                  children: [
                                    _KeyValueEditor(title: 'Headers'),
                                    _StyledTextField(
                                      controller: _quickBodyController,
                                      hint: '{\n  "key": "value"\n}',
                                      maxLines: 8,
                                    ),
                                    _AuthEditor(),
                                    _KeyValueEditor(title: 'Query Parameters'),
                                  ],
                                ),
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
          ),
        ),
        
        // Right: Results
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _SectionHeader(title: 'Résultats', icon: Icons.article_rounded),
              Expanded(
                child: _labService.testResults.isEmpty
                    ? _EmptyState(
                        icon: Icons.science_outlined,
                        title: 'Aucun résultat',
                        subtitle: 'Exécutez un test pour voir les résultats',
                        compact: true,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _labService.testResults.length,
                        itemBuilder: (context, index) {
                          final result = _labService.testResults[index];
                          return _TestResultCard(result: result);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Security Tab
  // ============================================================================

  Widget _buildSecurityTab() {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _labService.runSecurityScan(),
                icon: const Icon(Icons.security_rounded, size: 16),
                label: const Text('Lancer Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_labService.vulnerabilities.length} vulnérabilités trouvées',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
        
        // Vulnerabilities
        Expanded(
          child: _labService.vulnerabilities.isEmpty
              ? _EmptyState(
                  icon: Icons.verified_user_outlined,
                  title: 'Aucune vulnérabilité',
                  subtitle: 'Lancez un scan de sécurité pour vérifier vos APIs',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _labService.vulnerabilities.length,
                  itemBuilder: (context, index) {
                    final vuln = _labService.vulnerabilities[index];
                    return _VulnerabilityCard(vulnerability: vuln);
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // Performance Tab
  // ============================================================================

  Widget _buildPerformanceTab() {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showLoadTestDialog,
                icon: const Icon(Icons.speed_rounded, size: 16),
                label: const Text('Test de Charge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        
        // Performance results
        Expanded(
          child: _EmptyState(
            icon: Icons.trending_up_rounded,
            title: 'Tests de Performance',
            subtitle: 'Lancez un test de charge pour analyser les performances',
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Capture Tab
  // ============================================================================

  Widget _buildCaptureTab() {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              Text(
                '${_labService.captures.length} requêtes capturées',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _labService.clearCaptures(),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Effacer'),
                style: TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ),
        
        // Captures list
        Expanded(
          child: _labService.captures.isEmpty
              ? _EmptyState(
                  icon: Icons.videocam_off_outlined,
                  title: 'Aucune capture',
                  subtitle: 'Les requêtes interceptées apparaîtront ici',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _labService.captures.length,
                  itemBuilder: (context, index) {
                    final capture = _labService.captures[index];
                    return _CaptureCard(
                      capture: capture,
                      onReplay: () => _labService.replayCapture(capture.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // Dialogs
  // ============================================================================

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Paramètres Backend Lab', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StyledTextField(
              controller: TextEditingController(text: _labService.baseUrl),
              hint: 'URL du serveur Backend Lab',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _labService.checkConnection();
              Navigator.pop(context);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showLoadTestDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Nouveau Test de Charge', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StyledTextField(controller: nameController, hint: 'Nom du test'),
              const SizedBox(height: 12),
              _StyledTextField(controller: urlController, hint: 'URL cible'),
              const SizedBox(height: 12),
              // Additional options would go here
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                _labService.runLoadTest(
                  name: nameController.text,
                  targetUrl: urlController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Reusable Widgets
// ============================================================================

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 10, color: color.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
            Text(subtitle, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _Card({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'JetBrains Mono'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? chipColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? chipColor.withOpacity(0.3) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? chipColor : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 32 : 48, color: Colors.white.withOpacity(0.1)),
            SizedBox(height: compact ? 8 : 16),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: compact ? 10 : 11, color: Colors.white.withOpacity(0.2)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final TestResult result;

  const _ActivityItem({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: result.success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.method} ${result.url}',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${result.statusCode} • ${result.responseTimeMs}ms',
                  style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  final DiscoveredServer server;
  final VoidCallback onDiscoverRoutes;
  final VoidCallback onHealthCheck;

  const _ServerCard({
    required this.server,
    required this.onDiscoverRoutes,
    required this.onHealthCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: server.statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: server.statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: server.statusColor.withOpacity(0.5), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 12),
              Text(server.frameworkIcon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Text(
                      '${server.host}:${server.port} • ${server.framework ?? 'Unknown'}',
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onDiscoverRoutes,
                child: const Text('Routes', style: TextStyle(fontSize: 10)),
              ),
              TextButton(
                onPressed: onHealthCheck,
                child: const Text('Health', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final DiscoveredRoute route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: route.methodColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              route.method,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: route.methodColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              route.path,
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'JetBrains Mono'),
            ),
          ),
          if (route.description != null)
            Text(
              route.description!,
              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
            ),
        ],
      ),
    );
  }
}

class _TestResultCard extends StatelessWidget {
  final TestResult result;

  const _TestResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success
            ? const Color(0xFF22C55E).withOpacity(0.08)
            : const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: result.success
              ? const Color(0xFF22C55E).withOpacity(0.2)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                size: 14,
                color: result.success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.statusCode}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: result.success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.responseTimeMs}ms',
                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${result.method} ${result.url}',
            style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'JetBrains Mono'),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VulnerabilityCard extends StatelessWidget {
  final Vulnerability vulnerability;

  const _VulnerabilityCard({required this.vulnerability});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vulnerability.severityColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vulnerability.severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vulnerability.severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vulnerability.severity.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: vulnerability.severityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vulnerability.type.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vulnerability.description,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            vulnerability.affectedRoute,
            style: const TextStyle(fontSize: 10, color: Colors.white38, fontFamily: 'JetBrains Mono'),
          ),
        ],
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final CapturedRequest capture;
  final VoidCallback onReplay;

  const _CaptureCard({required this.capture, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: capture.methodColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              capture.method,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: capture.methodColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.url,
                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'JetBrains Mono'),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${capture.statusCode ?? '?'} • ${capture.responseTimeMs ?? '?'}ms',
                  style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.replay, size: 16),
            color: Colors.white.withOpacity(0.5),
            onPressed: onReplay,
            tooltip: 'Rejouer',
          ),
        ],
      ),
    );
  }
}

class _KeyValueEditor extends StatelessWidget {
  final String title;

  const _KeyValueEditor({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Key', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Value', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
              ),
              const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Content-Type',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'application/json',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 14),
                color: Colors.white.withOpacity(0.3),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'none',
              dropdownColor: const Color(0xFF1A1A24),
              style: const TextStyle(fontSize: 12, color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Aucune')),
                DropdownMenuItem(value: 'bearer', child: Text('Bearer Token')),
                DropdownMenuItem(value: 'basic', child: Text('Basic Auth')),
                DropdownMenuItem(value: 'apikey', child: Text('API Key')),
              ],
              onChanged: (v) {},
            ),
          ),
        ],
      ),
    );
  }
}
