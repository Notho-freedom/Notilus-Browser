/// Backend Lab Panel - Version Notilus GX Native
/// Interface ultra-réactive pour les tests backend avec configuration automatique
library backend_lab_panel;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/backend_lab/backend_lab_service.dart';
import '../../models/backend_lab/backend_lab_models.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';

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

/// Panneau principal Backend Lab - Style Notilus GX
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
  
  // Auto-config state
  final Map<String, bool> _configuringServers = {};
  
  // Selected items for details panel
  DiscoveredServer? _selectedServer;
  DiscoveredRoute? _selectedRoute;
  
  // Filter for routes tab
  String? _filteredServerId;
  
  // Loading states
  final Map<String, bool> _loadingStates = {};

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
      final newTab = BackendLabTab.values[_tabController.index];
      setState(() {
        _activeTab = newTab;
        // Réinitialiser les sélections si on change d'onglet
        if (newTab != BackendLabTab.servers) {
          _selectedServer = null;
        }
        if (newTab != BackendLabTab.routes) {
          _selectedRoute = null;
        }
      });
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
    final bgColor = NotilusColors.getNativeBackgroundColor(context);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          _buildHeader(accent, bgColor),
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

  Widget _buildHeader(Color accent, Color bgColor) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.12),
            accent.withOpacity(0.06),
            Colors.transparent,
          ],
        ),
        border: Border(bottom: BorderSide(color: accent.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          // Logo avec style GX
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
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
                style: NotilusFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ).copyWith(letterSpacing: 1.5),
              ),
              Text(
                'Tests API • Sécurité • Performance',
                style: NotilusFonts.rajdhani(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Connection status avec animation
          _buildConnectionBadge(accent),
          
          const SizedBox(width: 12),
          
          // Actions
          _GxIconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Rafraîchir',
            accent: accent,
            onTap: () => _labService.refreshAll(),
          ),
          _GxIconBtn(
            icon: Icons.settings_outlined,
            tooltip: 'Paramètres',
            accent: accent,
            onTap: _showSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(Color accent) {
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
    final connected = _labService.isConnected;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
            color: connected 
                ? const Color(0xFF22C55E).withOpacity(0.15) 
                : const Color(0xFFEF4444).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
              color: connected 
                  ? const Color(0xFF22C55E).withOpacity(0.3) 
                  : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: connected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                      color: (connected ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                          .withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Connecté' : 'Déconnecté',
                style: NotilusFonts.rajdhani(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: connected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildTabBar(Color accent) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: NotilusColors.chromeDark,
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
            height: 42,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? tab.accentColor.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isActive 
                    ? Border.all(color: tab.accentColor.withOpacity(0.3), width: 1)
                    : null,
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
                    style: NotilusFonts.rajdhani(
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
            style: NotilusFonts.rajdhani(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
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
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
    final stats = _labService.stats;
        final accent = NotilusColors.getSecondaryColor(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Stats cards avec style GX
              _buildStatsRow(stats, accent),
          const SizedBox(height: 24),
          
          // Quick actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Expanded(child: _buildQuickTestCard(accent)),
              const SizedBox(width: 16),
                  Expanded(child: _buildRecentActivityCard(accent)),
            ],
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildStatsRow(OverviewStats? stats, Color accent) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _GxStatCard(
          title: 'Serveurs',
          value: '${stats?.totalServers ?? _labService.servers.length}',
          subtitle: 'Découverts',
          icon: Icons.dns_rounded,
          color: const Color(0xFF22C55E),
          accent: accent,
          onTap: () => _tabController.animateTo(1),
        ),
        _GxStatCard(
          title: 'Routes',
          value: '${stats?.totalRoutes ?? _labService.routes.length}',
          subtitle: 'Mappées',
          icon: Icons.alt_route_rounded,
          color: const Color(0xFF3B82F6),
          accent: accent,
          onTap: () => _tabController.animateTo(2),
        ),
        _GxStatCard(
          title: 'Tests',
          value: '${stats?.totalTestsRun ?? _labService.testResults.length}',
          subtitle: '${stats?.testSuccessRate.toStringAsFixed(0) ?? 0}% succès',
          icon: Icons.science_rounded,
          color: const Color(0xFFF59E0B),
          accent: accent,
          onTap: () => _tabController.animateTo(3),
        ),
        _GxStatCard(
          title: 'Vulnérabilités',
          value: '${stats?.totalVulnerabilities ?? _labService.vulnerabilities.length}',
          subtitle: _getVulnSummary(),
          icon: Icons.shield_rounded,
          color: _labService.vulnerabilities.any((v) => v.severity == VulnerabilitySeverity.critical)
              ? const Color(0xFFEF4444)
              : const Color(0xFFF59E0B),
          accent: accent,
          onTap: () => _tabController.animateTo(4),
        ),
        _GxStatCard(
          title: 'Captures',
          value: '${_labService.captures.length}',
          subtitle: 'Requêtes',
          icon: Icons.videocam_rounded,
          color: const Color(0xFF14B8A6),
          accent: accent,
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

  Widget _buildQuickTestCard(Color accent) {
    return _GxCard(
      title: 'Test Rapide',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFF59E0B),
      accent: accent,
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
                    dropdownColor: NotilusColors.chromeDark,
                    style: NotilusFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w600),
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
                child: _GxTextField(
                  controller: _quickUrlController,
                  hint: 'https://api.example.com/endpoint',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Body (for POST/PUT/PATCH)
          if (['POST', 'PUT', 'PATCH'].contains(_quickMethod)) ...[
            _GxTextField(
              controller: _quickBodyController,
              hint: '{"key": "value"}',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
          ],
          
          // Run button avec style GX
          SizedBox(
            width: double.infinity,
            child: _GxButton(
              onPressed: _isRunningTest ? null : _runQuickTest,
              icon: _isRunningTest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(_isRunningTest ? 'Exécution...' : 'Exécuter'),
              color: const Color(0xFFF59E0B),
              accent: accent,
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

  Widget _buildRecentActivityCard(Color accent) {
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
        return _GxCard(
      title: 'Activité Récente',
      icon: Icons.history_rounded,
      color: const Color(0xFF6366F1),
          accent: accent,
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
                          style: NotilusFonts.rajdhani(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
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
                    return _GxActivityItem(result: result);
              },
            ),
        );
      },
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
  // Servers Tab - Style DevTools avec split view
  // ============================================================================

  Widget _buildServersTab() {
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
        final accent = NotilusColors.getSecondaryColor(context);
        
        return Row(
          children: [
            // === LISTE GAUCHE: Serveurs style console ===
            Expanded(
              flex: 2,
              child: Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
                      color: NotilusColors.chromeDark,
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
                        _GxButton(
                          onPressed: _labService.isScanning ? null : () => _scanServersWithLoader(),
                icon: _labService.isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.radar_rounded, size: 16),
                label: Text(_labService.isScanning ? 'Scan...' : 'Scanner'),
                          color: const Color(0xFF22C55E),
                          accent: accent,
                          compact: true,
              ),
              const SizedBox(width: 12),
              Text(
                          '${_labService.servers.length} serveurs',
                          style: NotilusFonts.rajdhani(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
              ),
            ],
          ),
        ),
        
                  // Liste des serveurs style console
        Expanded(
          child: _labService.servers.isEmpty
                        ? _GxEmptyState(
                  icon: Icons.dns_outlined,
                  title: 'Aucun serveur découvert',
                  subtitle: 'Cliquez sur "Scanner" pour détecter les serveurs locaux',
                )
              : ListView.builder(
                            padding: EdgeInsets.zero,
                  itemCount: _labService.servers.length,
                  itemBuilder: (context, index) {
                    final server = _labService.servers[index];
                              final isSelected = _selectedServer?.id == server.id;
                              return _DevToolsServerListItem(
                      server: server,
                                accent: accent,
                                isSelected: isSelected,
                                isLoading: _loadingStates[server.id] ?? false,
                                onTap: () => setState(() => _selectedServer = server),
                                onRoutesTap: () => _navigateToRoutesForServer(server.id),
                    );
                  },
                ),
                  ),
                ],
              ),
            ),
            
            // === PANNEAU DROITE: Détails du serveur ===
            if (_selectedServer != null)
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: NotilusColors.chromeDark,
                  border: Border(left: BorderSide(color: accent.withOpacity(0.2))),
                ),
                child: _buildServerDetailsPanel(_selectedServer!, accent),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildServerDetailsPanel(DiscoveredServer server, Color accent) {
    return Column(
      children: [
        // Header avec bouton fermer
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: NotilusColors.chromeDark,
            border: Border(bottom: BorderSide(color: accent.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Icon(Icons.dns_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  server.displayName,
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: Colors.white.withOpacity(0.5),
                onPressed: () => setState(() => _selectedServer = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        
        // Contenu scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                _DetailSection(
                  title: 'Informations',
                  accentColor: accent,
                  children: [
                    _DetailRow('Host', server.host),
                    _DetailRow('Port', '${server.port}'),
                    _DetailRow('Protocol', server.protocol),
                    _DetailRow('Base URL', server.baseUrl),
                    _DetailRow('Framework', server.framework.name),
                    if (server.language != null) _DetailRow('Language', server.language!),
                    _DetailRow('Status', server.status.name),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Health
                _DetailSection(
                  title: 'Health Check',
                  accentColor: accent,
                  children: [
                    _DetailRow('Status', server.health.status.name),
                    _DetailRow('Response Time', '${server.health.responseTimeMs.toStringAsFixed(0)}ms'),
                    _DetailRow('Uptime', '${server.health.uptimePercentage.toStringAsFixed(1)}%'),
                    if (server.health.errorMessage != null)
                      _DetailRow('Error', server.health.errorMessage!),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Statistiques
                _DetailSection(
                  title: 'Statistiques',
                  accentColor: accent,
                  children: [
                    _DetailRow('Routes découvertes', '${server.routesCount}'),
                    _DetailRow('Requêtes totales', '${server.requestCount}'),
                    _DetailRow('Temps de réponse moyen', '${server.avgResponseTime.toStringAsFixed(0)}ms'),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Actions
                _DetailSection(
                  title: 'Actions',
                  accentColor: accent,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _GxButton(
                        onPressed: _configuringServers[server.id] == true
                            ? null
                            : () => _autoConfigureServer(server.id),
                        icon: _configuringServers[server.id] == true
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text(_configuringServers[server.id] == true ? 'Configuration...' : 'Configuration Auto'),
                        color: accent,
                        accent: accent,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _GxButton(
                        onPressed: _loadingStates['${server.id}_routes'] == true
                            ? null
                            : () => _discoverRoutesWithLoader(server.id),
                        icon: _loadingStates['${server.id}_routes'] == true
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.alt_route_rounded, size: 16),
                        label: Text(_loadingStates['${server.id}_routes'] == true ? 'Découverte...' : 'Découvrir Routes'),
                        color: const Color(0xFF3B82F6),
                        accent: accent,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _GxButton(
                        onPressed: _loadingStates['${server.id}_health'] == true
                            ? null
                            : () => _healthCheckWithLoader(server.id),
                        icon: _loadingStates['${server.id}_health'] == true
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.favorite_rounded, size: 16),
                        label: Text(_loadingStates['${server.id}_health'] == true ? 'Vérification...' : 'Health Check'),
                        color: const Color(0xFF22C55E),
                        accent: accent,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _GxButton(
                        onPressed: () => _navigateToRoutesForServer(server.id),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Voir Routes'),
                        color: const Color(0xFF8B5CF6),
                        accent: accent,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _scanServersWithLoader() async {
    setState(() => _loadingStates['scan'] = true);
    try {
      await _labService.scanServers();
      await _labService.getServers(); // Actualiser
    } finally {
      if (mounted) {
        setState(() => _loadingStates['scan'] = false);
      }
    }
  }
  
  Future<void> _discoverRoutesWithLoader(String serverId) async {
    setState(() => _loadingStates['${serverId}_routes'] = true);
    try {
      await _labService.discoverRoutes(serverId);
      await _labService.getRoutes(serverId); // Actualiser
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Routes découvertes avec succès !',
              style: NotilusFonts.rajdhani(),
            ),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: NotilusFonts.rajdhani(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingStates['${serverId}_routes'] = false);
      }
    }
  }
  
  Future<void> _healthCheckWithLoader(String serverId) async {
    setState(() => _loadingStates['${serverId}_health'] = true);
    try {
      await _labService.healthCheck(serverId);
      await _labService.getServers(); // Actualiser
    } finally {
      if (mounted) {
        setState(() => _loadingStates['${serverId}_health'] = false);
      }
    }
  }
  
  void _navigateToRoutesForServer(String serverId) {
    setState(() {
      _filteredServerId = serverId;
      _selectedServer = null; // Fermer le panel de détails
    });
    _tabController.animateTo(BackendLabTab.routes.index);
  }
  
  Future<void> _autoConfigureServer(String serverId) async {
    setState(() {
      _configuringServers[serverId] = true;
      _loadingStates['${serverId}_config'] = true;
    });
    
    try {
      await _labService.configureServer(
        serverId,
        discoverRoutes: true,
        detectParameters: true,
        createTests: true,
      );
      
      // Actualiser les données
      await Future.wait([
        _labService.getServers(),
        _labService.getRoutes(serverId),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Configuration automatique terminée !',
              style: NotilusFonts.rajdhani(),
            ),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la configuration: $e',
              style: NotilusFonts.rajdhani(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _configuringServers[serverId] = false;
          _loadingStates['${serverId}_config'] = false;
        });
      }
    }
  }

  // ============================================================================
  // Routes Tab - Style DevTools avec split view
  // ============================================================================

  Widget _buildRoutesTab() {
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
        final allRoutes = _labService.routes;
        final filteredRoutes = _filteredServerId != null
            ? allRoutes.where((r) => r.serverId == _filteredServerId).toList()
            : allRoutes;
        final accent = NotilusColors.getSecondaryColor(context);
        
        return Row(
          children: [
            // === LISTE GAUCHE: Routes style console ===
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: NotilusColors.chromeDark,
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: Row(
                      children: [
                        if (_filteredServerId != null) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back, size: 16),
                            color: accent,
                            onPressed: () => setState(() => _filteredServerId = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Routes du serveur',
                            style: NotilusFonts.rajdhani(
                              fontSize: 11,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Text(
                          '${filteredRoutes.length} routes',
                          style: NotilusFonts.rajdhani(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const Spacer(),
                        // Filter by method
                        _GxFilterChip(
                          label: 'Toutes',
                          isActive: true,
                          accent: accent,
                          onTap: () {},
                        ),
                        _GxFilterChip(
                          label: 'GET',
                          isActive: false,
                          color: const Color(0xFF22C55E),
                          accent: accent,
                          onTap: () {},
                        ),
                        _GxFilterChip(
                          label: 'POST',
                          isActive: false,
                          color: const Color(0xFF3B82F6),
                          accent: accent,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  
                  // Liste des routes style console
                  Expanded(
                    child: filteredRoutes.isEmpty
                        ? _GxEmptyState(
                            icon: Icons.alt_route_outlined,
                            title: 'Aucune route découverte',
                            subtitle: _filteredServerId != null
                                ? 'Aucune route pour ce serveur'
                                : 'Sélectionnez un serveur et configurez-le automatiquement',
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filteredRoutes.length,
                            itemBuilder: (context, index) {
                              final route = filteredRoutes[index];
                              final isSelected = _selectedRoute?.id == route.id;
                              return _DevToolsRouteListItem(
                                route: route,
                                accent: accent,
                                isSelected: isSelected,
                                onTap: () => setState(() => _selectedRoute = route),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            
            // === PANNEAU DROITE: Détails de la route ===
            if (_selectedRoute != null)
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: NotilusColors.chromeDark,
                  border: Border(left: BorderSide(color: accent.withOpacity(0.2))),
                ),
                child: _buildRouteDetailsPanel(_selectedRoute!, accent),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildRouteDetailsPanel(DiscoveredRoute route, Color accent) {
    return Column(
      children: [
        // Header avec bouton fermer
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: NotilusColors.chromeDark,
            border: Border(bottom: BorderSide(color: accent.withOpacity(0.2))),
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
                  route.method.name,
                  style: NotilusFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: route.methodColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.path,
                  style: NotilusFonts.code(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: Colors.white.withOpacity(0.5),
                onPressed: () => setState(() => _selectedRoute = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        
        // Contenu scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                _DetailSection(
                  title: 'Informations',
                  accentColor: accent,
                  children: [
                    _DetailRow('Méthode', route.method.name),
                    _DetailRow('Path', route.path),
                    if (route.summary != null) _DetailRow('Summary', route.summary!),
                    if (route.description != null) _DetailRow('Description', route.description!),
                    _DetailRow('Auth Required', route.authRequired ? 'Oui' : 'Non'),
                    if (route.authType != null) _DetailRow('Auth Type', route.authType!),
                    _DetailRow('Deprecated', route.deprecated ? 'Oui' : 'Non'),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Paramètres de chemin
                if (route.pathParams.isNotEmpty)
                  _DetailSection(
                    title: 'Path Parameters',
                    accentColor: accent,
                    children: route.pathParams.map((param) => _DetailRow(
                      param.name,
                      '${param.type}${param.required ? " (required)" : ""}',
                    )).toList(),
                  ),
                
                if (route.pathParams.isNotEmpty) const SizedBox(height: 16),
                
                // Paramètres de query
                if (route.queryParams.isNotEmpty)
                  _DetailSection(
                    title: 'Query Parameters',
                    accentColor: accent,
                    children: route.queryParams.map((param) => _DetailRow(
                      param.name,
                      '${param.type}${param.required ? " (required)" : ""}',
                    )).toList(),
                  ),
                
                if (route.queryParams.isNotEmpty) const SizedBox(height: 16),
                
                // Statistiques
                _DetailSection(
                  title: 'Statistiques',
                  accentColor: accent,
                  children: [
                    _DetailRow('Tests', '${route.testCount}'),
                    _DetailRow('Appels', '${route.callCount}'),
                    _DetailRow('Temps de réponse moyen', '${route.avgResponseTime.toStringAsFixed(0)}ms'),
                    _DetailRow('Vulnérabilités', '${route.vulnerabilityCount}'),
                  ],
                ),
                
                if (route.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Tags',
                    accentColor: accent,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: route.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: NotilusFonts.rajdhani(
                              fontSize: 10,
                              color: accent,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Testing Tab
  // ============================================================================

  Widget _buildTestingTab() {
    final accent = NotilusColors.getSecondaryColor(context);
    
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
                _GxSectionHeader(title: 'Constructeur de Requête', icon: Icons.build_rounded, accent: accent),
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
                                  dropdownColor: NotilusColors.chromeDark,
                                  style: NotilusFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w600),
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
                              child: _GxTextField(
                                controller: _quickUrlController,
                                hint: 'URL de l\'endpoint',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _GxButton(
                              onPressed: _isRunningTest ? null : _runQuickTest,
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Envoyer'),
                              color: const Color(0xFF3B82F6),
                              accent: accent,
                              compact: true,
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
                                  labelStyle: NotilusFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600),
                                  indicator: BoxDecoration(
                                    color: accent.withOpacity(0.2),
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
                                    _GxKeyValueEditor(title: 'Headers', accent: accent),
                                    _GxTextField(
                                      controller: _quickBodyController,
                                      hint: '{\n  "key": "value"\n}',
                                      maxLines: 8,
                                    ),
                                    _GxAuthEditor(accent: accent),
                                    _GxKeyValueEditor(title: 'Query Parameters', accent: accent),
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
              _GxSectionHeader(title: 'Résultats', icon: Icons.article_rounded, accent: accent),
              Expanded(
                child: ListenableBuilder(
                  listenable: _labService,
                  builder: (context, _) {
                    return _labService.testResults.isEmpty
                        ? _GxEmptyState(
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
                              return _GxTestResultCard(result: result);
                            },
                          );
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
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
        final accent = NotilusColors.getSecondaryColor(context);
        
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
                color: NotilusColors.chromeDark,
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
                  _GxButton(
                onPressed: () => _labService.runSecurityScan(),
                icon: const Icon(Icons.security_rounded, size: 16),
                label: const Text('Lancer Scan'),
                    color: const Color(0xFFEF4444),
                    accent: accent,
                    compact: true,
              ),
              const SizedBox(width: 12),
              Text(
                '${_labService.vulnerabilities.length} vulnérabilités trouvées',
                    style: NotilusFonts.rajdhani(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ),
        
        // Vulnerabilities
        Expanded(
          child: _labService.vulnerabilities.isEmpty
                  ? _GxEmptyState(
                  icon: Icons.verified_user_outlined,
                  title: 'Aucune vulnérabilité',
                  subtitle: 'Lancez un scan de sécurité pour vérifier vos APIs',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _labService.vulnerabilities.length,
                  itemBuilder: (context, index) {
                    final vuln = _labService.vulnerabilities[index];
                        return _GxVulnerabilityCard(vulnerability: vuln);
                  },
                ),
        ),
      ],
        );
      },
    );
  }

  // ============================================================================
  // Performance Tab
  // ============================================================================

  Widget _buildPerformanceTab() {
    final accent = NotilusColors.getSecondaryColor(context);
    
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: NotilusColors.chromeDark,
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              _GxButton(
                onPressed: _showLoadTestDialog,
                icon: const Icon(Icons.speed_rounded, size: 16),
                label: const Text('Test de Charge'),
                color: const Color(0xFF8B5CF6),
                accent: accent,
                compact: true,
              ),
            ],
          ),
        ),
        
        // Performance results
        Expanded(
          child: _GxEmptyState(
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
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
                color: NotilusColors.chromeDark,
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              Text(
                '${_labService.captures.length} requêtes capturées',
                    style: NotilusFonts.rajdhani(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _labService.clearCaptures(),
                icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      'Effacer',
                      style: NotilusFonts.rajdhani(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
        
        // Captures list
        Expanded(
          child: _labService.captures.isEmpty
                  ? _GxEmptyState(
                  icon: Icons.videocam_off_outlined,
                  title: 'Aucune capture',
                  subtitle: 'Les requêtes interceptées apparaîtront ici',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _labService.captures.length,
                  itemBuilder: (context, index) {
                    final capture = _labService.captures[index];
                        return _GxCaptureCard(
                      capture: capture,
                      onReplay: () => _labService.replayCapture(capture.id),
                    );
                  },
                ),
        ),
      ],
        );
      },
    );
  }

  // ============================================================================
  // Dialogs
  // ============================================================================

  void _showSettings() {
    final urlController = TextEditingController(text: _labService.baseUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NotilusColors.chromeDark,
        title: Text(
          'Paramètres Backend Lab',
          style: NotilusFonts.orbitron(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GxTextField(
              controller: urlController,
              hint: 'URL du serveur Backend Lab',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: NotilusFonts.rajdhani()),
          ),
          _GxButton(
            onPressed: () {
              _labService.baseUrl = urlController.text;
              _labService.checkConnection();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save_rounded, size: 16),
            label: const Text('Sauvegarder'),
            color: NotilusColors.getSecondaryColor(context),
            accent: NotilusColors.getSecondaryColor(context),
            compact: true,
          ),
        ],
      ),
    );
  }

  void _showLoadTestDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final accent = NotilusColors.getSecondaryColor(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NotilusColors.chromeDark,
        title: Text(
          'Nouveau Test de Charge',
          style: NotilusFonts.orbitron(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GxTextField(controller: nameController, hint: 'Nom du test'),
              const SizedBox(height: 12),
              _GxTextField(controller: urlController, hint: 'URL cible'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: NotilusFonts.rajdhani()),
          ),
          _GxButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                _labService.runLoadTest(
                  name: nameController.text,
                  targetUrl: urlController.text,
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Démarrer'),
            color: const Color(0xFF8B5CF6),
            accent: accent,
            compact: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Reusable GX Widgets - Style Notilus GX
// ============================================================================

class _GxIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accent;
  final VoidCallback onTap;

  const _GxIconBtn({
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.onTap,
  });

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
            child: Icon(icon, size: 16, color: accent.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }
}

class _GxStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accent;
  final VoidCallback? onTap;

  const _GxStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accent,
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
              style: NotilusFonts.orbitron(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
              ).copyWith(height: 1),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            Text(
              subtitle,
              style: NotilusFonts.rajdhani(
                fontSize: 9,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GxCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color accent;
  final Widget child;

  const _GxCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotilusColors.chromeLight,
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
                style: NotilusFonts.rajdhani(
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

class _GxSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;

  const _GxSectionHeader({
    required this.title,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: NotilusColors.chromeDark,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accent.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            title,
            style: NotilusFonts.rajdhani(
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

class _GxTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _GxTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final accent = NotilusColors.getSecondaryColor(context);
    
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: NotilusFonts.code(fontSize: 12, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: NotilusFonts.rajdhani(
          fontSize: 12,
          color: Colors.white.withOpacity(0.3),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _GxButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final Color color;
  final Color accent;
  final bool compact;

  const _GxButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: label,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 8 : 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: NotilusFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _GxFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final Color accent;
  final VoidCallback onTap;

  const _GxFilterChip({
    required this.label,
    required this.isActive,
    this.color,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? chipColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? chipColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: NotilusFonts.rajdhani(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? chipColor : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class _GxEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _GxEmptyState({
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
              style: NotilusFonts.rajdhani(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: NotilusFonts.rajdhani(
                fontSize: compact ? 10 : 11,
                color: Colors.white.withOpacity(0.2),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GxActivityItem extends StatelessWidget {
  final TestResult result;

  const _GxActivityItem({required this.result});

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
              color: result.status == TestResultStatus.passed 
                  ? const Color(0xFF22C55E) 
                  : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.testId}',
                  style: NotilusFonts.code(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${result.durationMs.toStringAsFixed(0)}ms',
                  style: NotilusFonts.rajdhani(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GxServerCard extends StatelessWidget {
  final DiscoveredServer server;
  final Color accent;
  final bool isConfiguring;
  final VoidCallback onAutoConfigure;
  final VoidCallback onDiscoverRoutes;
  final VoidCallback onHealthCheck;
  final VoidCallback onRefresh;

  const _GxServerCard({
    required this.server,
    required this.accent,
    required this.isConfiguring,
    required this.onAutoConfigure,
    required this.onDiscoverRoutes,
    required this.onHealthCheck,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotilusColors.chromeLight,
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
                  boxShadow: [
                    BoxShadow(
                      color: server.statusColor.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(server.frameworkIcon, size: 16, color: accent.withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.displayName,
                      style: NotilusFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${server.host}:${server.port} • ${server.framework.name}',
                      style: NotilusFonts.rajdhani(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton de configuration automatique
              _GxButton(
                onPressed: isConfiguring ? null : onAutoConfigure,
                icon: isConfiguring
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 14),
                label: Text(isConfiguring ? 'Config...' : 'Auto Config'),
                color: accent,
                accent: accent,
                compact: true,
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDiscoverRoutes,
                child: Text(
                  'Routes',
                  style: NotilusFonts.rajdhani(fontSize: 10),
                ),
              ),
              TextButton(
                onPressed: onHealthCheck,
                child: Text(
                  'Health',
                  style: NotilusFonts.rajdhani(fontSize: 10),
                ),
              ),
            ],
          ),
          if (server.routesCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.alt_route_rounded, size: 12, color: accent.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  '${server.routesCount} routes découvertes',
                  style: NotilusFonts.rajdhani(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GxRouteCard extends StatelessWidget {
  final DiscoveredRoute route;
  final Color accent;

  const _GxRouteCard({required this.route, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NotilusColors.chromeLight,
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
              route.method.name,
              style: NotilusFonts.rajdhani(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: route.methodColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              route.path,
              style: NotilusFonts.code(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ),
          if (route.pathParams.isNotEmpty || route.queryParams.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${route.pathParams.length + route.queryParams.length} params',
                style: NotilusFonts.rajdhani(
                  fontSize: 9,
                  color: accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GxTestResultCard extends StatelessWidget {
  final TestResult result;

  const _GxTestResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.status == TestResultStatus.passed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF22C55E).withOpacity(0.08)
            : const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSuccess
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
                result.statusIcon,
                size: 14,
                color: result.statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${result.assertionsPassed}/${result.assertionsPassed + result.assertionsFailed} assertions',
                style: NotilusFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: result.statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.durationMs.toStringAsFixed(0)}ms',
                style: NotilusFonts.rajdhani(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          if (result.errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
              result.errorMessage!,
              style: NotilusFonts.code(
                fontSize: 10,
                color: Colors.white54,
              ),
            overflow: TextOverflow.ellipsis,
          ),
          ],
        ],
      ),
    );
  }
}

class _GxVulnerabilityCard extends StatelessWidget {
  final Vulnerability vulnerability;

  const _GxVulnerabilityCard({required this.vulnerability});

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
                  style: NotilusFonts.rajdhani(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: vulnerability.severityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vulnerability.title,
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vulnerability.description,
            style: NotilusFonts.rajdhani(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
          ),
          ),
        ],
      ),
    );
  }
}

class _GxCaptureCard extends StatelessWidget {
  final CapturedRequest capture;
  final VoidCallback onReplay;

  const _GxCaptureCard({required this.capture, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NotilusColors.chromeLight,
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
              style: NotilusFonts.rajdhani(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: capture.methodColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.url,
                  style: NotilusFonts.code(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${capture.statusCode ?? '?'} • ${capture.durationMs.toStringAsFixed(0)}ms',
                  style: NotilusFonts.rajdhani(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.4),
                  ),
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

class _GxKeyValueEditor extends StatelessWidget {
  final String title;
  final Color accent;

  const _GxKeyValueEditor({required this.title, required this.accent});

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
                child: Text(
                  'Key',
                  style: NotilusFonts.rajdhani(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Value',
                  style: NotilusFonts.rajdhani(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: NotilusFonts.rajdhani(fontSize: 11, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Content-Type',
                    hintStyle: NotilusFonts.rajdhani(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  style: NotilusFonts.rajdhani(fontSize: 11, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'application/json',
                    hintStyle: NotilusFonts.rajdhani(
                      color: Colors.white.withOpacity(0.2),
                    ),
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

class _GxAuthEditor extends StatelessWidget {
  final Color accent;

  const _GxAuthEditor({required this.accent});

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
              dropdownColor: NotilusColors.chromeDark,
              style: NotilusFonts.rajdhani(fontSize: 12, color: Colors.white),
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

// ============================================================================
// DevTools Style List Items
// ============================================================================

class _DevToolsServerListItem extends StatelessWidget {
  final DiscoveredServer server;
  final Color accent;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onRoutesTap;

  const _DevToolsServerListItem({
    required this.server,
    required this.accent,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
    required this.onRoutesTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: server.statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: server.statusColor.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Icon(
              server.frameworkIcon,
              size: 16,
              color: accent.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.displayName,
                    style: NotilusFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${server.host}:${server.port} • ${server.framework.name}',
                    style: NotilusFonts.rajdhani(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Routes count
            if (server.routesCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${server.routesCount} routes',
                  style: NotilusFonts.rajdhani(
                    fontSize: 9,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Loading indicator
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _DevToolsRouteListItem extends StatelessWidget {
  final DiscoveredRoute route;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _DevToolsRouteListItem({
    required this.route,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Method badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: route.methodColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                route.method.name,
                style: NotilusFonts.rajdhani(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: route.methodColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Path
            Expanded(
              child: Text(
                route.path,
                style: NotilusFonts.code(
                  fontSize: 11,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Params count
            if (route.pathParams.isNotEmpty || route.queryParams.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${route.pathParams.length + route.queryParams.length}',
                  style: NotilusFonts.rajdhani(
                    fontSize: 9,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Detail Panel Widgets
// ============================================================================

class _DetailSection extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: NotilusFonts.rajdhani(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: NotilusFonts.rajdhani(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: NotilusFonts.code(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
