/// Backend Lab Mini Panel - Widget autonome et réutilisable
/// Encapsule toute la logique du Backend Lab (serveurs, routes, console, history)
library backend_lab_mini_panel;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../services/backend_lab/backend_lab_service.dart';
import '../../models/backend_lab/backend_lab_models.dart';
import '../../services/history_service.dart';
import '../../models/history_item.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../common/hack_loading_indicator.dart';

/// Widget autonome Backend Lab Mini avec toutes les fonctionnalités
class BackendLabMiniPanel extends StatefulWidget {
  /// Couleur d'accent personnalisée (optionnel, utilise le thème par défaut si null)
  final Color? accentColor;
  
  /// Largeur du panel
  final double width;
  
  /// Transparence du fond
  final double transparency;

  const BackendLabMiniPanel({
    super.key,
    this.accentColor,
    this.width = 320.0,
    this.transparency = 0.0,
  });

  @override
  State<BackendLabMiniPanel> createState() => _BackendLabMiniPanelState();
}

class _BackendLabMiniPanelState extends State<BackendLabMiniPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BackendLabService _labService;
  late HistoryService _historyService;
  
  // State
  String? _selectedServerId;
  bool _isLoadingRoutes = false;
  String? _routesError;
  bool _isLoadingHistory = false;
  List<DiscoveredServer> _historyServers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _labService = Provider.of<BackendLabService>(context, listen: false);
    _historyService = HistoryService();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _labService.checkConnection();
      _labService.connectConsole();
      _loadHistoryServers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (widget.accentColor != null) return widget.accentColor!;
    return Provider.of<ColorThemeManager>(context, listen: false).nativeSecondaryColor;
  }

  Future<void> _loadHistoryServers() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _historyService.getHistory();
      
      final serverMap = <String, DiscoveredServer>{};
      
      for (final item in history) {
        try {
          final uri = Uri.parse(item.url);
          final host = uri.host;
          final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
          
          // Exclure les serveurs localhost ou IP locales
          final isLocal = host == 'localhost' || host == '127.0.0.1' || 
                          host.startsWith('192.168.') || host.startsWith('10.') || host.startsWith('172.');
          
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
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _onServerSelected(String serverId) async {
    if (_selectedServerId == serverId) {
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
    
    try {
      DiscoveredServer? server = _labService.servers.firstWhere(
        (s) => s.id == serverId,
        orElse: () => DiscoveredServer(id: '', port: 0),
      );
      
      if (server.id.isEmpty) {
        final historyServer = _historyServers.firstWhere(
          (s) => s.id == serverId,
          orElse: () => DiscoveredServer(id: '', port: 0),
        );
        
        if (historyServer.id.isNotEmpty) {
          server = await _labService.discoverOrAddServer(
            host: historyServer.host,
            port: historyServer.port,
            protocol: historyServer.protocol,
            name: historyServer.name,
          );
          
          if (server != null && server.id.isNotEmpty) {
            setState(() {
              _selectedServerId = server!.id;
            });
          } else {
            server = historyServer;
          }
        }
      }
      
      if (server != null && server.id.isNotEmpty) {
        if (mounted) {
          _tabController.animateTo(1);
        }
        
        await _labService.discoverRoutes(server.id);
        
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - widget.transparency * 0.5).clamp(0.0, 1.0)),
        border: Border(
          left: BorderSide(color: _accentColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _accentColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.square_stack_3d_up, size: 14, color: _accentColor),
                const SizedBox(width: 8),
                Text(
                  'BACKEND LAB',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
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
                  isScrollable: false,
                  indicatorColor: _accentColor,
                  labelColor: _accentColor,
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
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
                      _buildServersTab(),
                      // Routes list
                      _buildRoutesTab(),
                      // Console
                      _buildConsoleTab(),
                      // History
                      _buildHistoryTab(),
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

  Widget _buildServersTab() {
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
        final servers = _labService.servers;
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
            return _buildServerItem(server);
          },
        );
      },
    );
  }

  Widget _buildRoutesTab() {
    return ListenableBuilder(
      listenable: _labService,
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
              accentColor: _accentColor,
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
        
        final routes = _labService.routes.where((r) {
          if (r.serverId == _selectedServerId) return true;
          
          final selectedServer = _labService.servers.firstWhere(
            (s) => s.id == _selectedServerId,
            orElse: () => DiscoveredServer(id: '', port: 0),
          );
          
          if (selectedServer.id.isNotEmpty) {
            final routeServer = _labService.servers.firstWhere(
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
            return _buildRouteItem(route);
          },
        );
      },
    );
  }

  Widget _buildConsoleTab() {
    return ListenableBuilder(
      listenable: _labService,
      builder: (context, _) {
        final logs = _labService.consoleLogs;
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
            final log = logs[logs.length - 1 - index];
            return _buildConsoleLogItem(log);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return Center(
        child: HackLoadingIndicator(
          accentColor: _accentColor,
          message: 'Loading history servers...',
        ),
      );
    }
    
    if (_historyServers.isEmpty) {
      return Center(
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
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _historyServers.length,
      itemBuilder: (context, index) {
        final server = _historyServers[index];
        return _buildServerItem(server);
      },
    );
  }

  Widget _buildServerItem(DiscoveredServer server) {
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
                ? _accentColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? _accentColor.withOpacity(0.6)
                  : _accentColor.withOpacity(0.2),
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

  Widget _buildRouteItem(DiscoveredRoute route) {
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

  Widget _buildConsoleLogItem(ConsoleLogEntry log) {
    final levelColor = log.level == 'ERROR'
        ? const Color(0xFFFF5F56)
        : log.level == 'WARNING'
            ? const Color(0xFFFFBD2E)
            : _accentColor;
    
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
    final accentColor = _accentColor;
    final server = _labService.servers.firstWhere(
      (s) => s.id == route.serverId,
      orElse: () => DiscoveredServer(id: route.serverId, port: 0),
    );
    
    final pathParamControllers = <String, TextEditingController>{};
    final queryParamControllers = <String, TextEditingController>{};
    
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
              
              if (mounted) {
                Navigator.of(context).pop();
                for (final controller in pathParamControllers.values) {
                  controller.dispose();
                }
                for (final controller in queryParamControllers.values) {
                  controller.dispose();
                }
                
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
                // Fermer la popup de route details
                Navigator.of(context).pop();
                for (final controller in pathParamControllers.values) {
                  controller.dispose();
                }
                for (final controller in queryParamControllers.values) {
                  controller.dispose();
                }
                
                // Analyser l'erreur avec l'IA (qui va afficher et fermer la popup de transition automatiquement)
                await _analyzeErrorWithAI(e, route, finalUri, accentColor);
              }
            }
          },
        ),
      ],
    );
  }

  /// Analyse une erreur avec l'IA et affiche le résultat
  Future<void> _analyzeErrorWithAI(
    dynamic error,
    DiscoveredRoute route,
    Uri requestUri,
    Color accentColor,
  ) async {
    // Afficher la popup de transition
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

      // Fermer la popup de transition avant d'afficher l'analyse
      if (mounted) {
        Navigator.of(context).pop();
        // Attendre un peu pour que la fermeture soit visible
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (mounted && response != null) {
        String? analysisText = response['content'] as String?;
        analysisText ??= response['response'] as String?;
        analysisText ??= response['message'] as String?;
        analysisText ??= response['text'] as String?;

        Map<String, dynamic>? parsedAnalysis;
        if (analysisText != null) {
          try {
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(analysisText);
            if (jsonMatch != null) {
              parsedAnalysis = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
            }
          } catch (e) {
            // Si le parsing échoue, utiliser le texte brut
          }
        }

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
      if (mounted) {
        Navigator.of(context).pop();
        
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

  Widget _buildStructuredAnalysis(Map<String, dynamic> analysis, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (analysis['summary'] != null) ...[
          _buildAnalysisSection(
            'Résumé',
            analysis['summary'].toString(),
            accentColor,
            CupertinoIcons.info_circle,
          ),
          const SizedBox(height: 16),
        ],
        
        if (analysis['cause'] != null) ...[
          _buildAnalysisSection(
            'Cause probable',
            analysis['cause'].toString(),
            accentColor,
            CupertinoIcons.exclamationmark_circle,
          ),
          const SizedBox(height: 16),
        ],
        
        if (analysis['solutions'] != null) ...[
          _buildSolutionsSection(
            'Solutions possibles',
            analysis['solutions'],
            accentColor,
          ),
          const SizedBox(height: 16),
        ],
        
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
}

