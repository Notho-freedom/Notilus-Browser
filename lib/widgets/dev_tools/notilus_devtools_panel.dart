import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/notilus_devtools_service.dart';
import '../../models/devtools_models.dart';
import 'devtools_console_tab.dart';
import 'devtools_network_tab.dart';
import 'devtools_performance_tab.dart';
import 'devtools_storage_tab.dart';
import 'devtools_alerts_tab.dart';
import 'devtools_security_tab.dart';
import 'devtools_analytics_tab.dart';

/// Onglet actif dans les DevTools
enum DevToolsTab {
  console,
  network,
  performance,
  storage,
  alerts,
  security,
  analytics,
}

/// Panneau DevTools natif de Notilus
class NotilusDevToolsPanel extends StatefulWidget {
  const NotilusDevToolsPanel({super.key});

  @override
  State<NotilusDevToolsPanel> createState() => _NotilusDevToolsPanelState();
}

class _NotilusDevToolsPanelState extends State<NotilusDevToolsPanel>
    with SingleTickerProviderStateMixin {
  DevToolsTab _activeTab = DevToolsTab.console;
  late TabController _tabController;
  
  final List<_TabInfo> _tabs = const [
    _TabInfo(
      tab: DevToolsTab.console,
      label: 'Console',
      icon: CupertinoIcons.text_cursor,
      shortcut: '1',
    ),
    _TabInfo(
      tab: DevToolsTab.network,
      label: 'Network',
      icon: CupertinoIcons.globe,
      shortcut: '2',
    ),
    _TabInfo(
      tab: DevToolsTab.performance,
      label: 'Perf',
      icon: CupertinoIcons.speedometer,
      shortcut: '3',
    ),
    _TabInfo(
      tab: DevToolsTab.alerts,
      label: 'Alerts',
      icon: CupertinoIcons.bell,
      shortcut: '4',
    ),
    _TabInfo(
      tab: DevToolsTab.security,
      label: 'Security',
      icon: CupertinoIcons.lock_shield,
      shortcut: '5',
    ),
    _TabInfo(
      tab: DevToolsTab.analytics,
      label: 'Analytics',
      icon: CupertinoIcons.chart_bar,
      shortcut: '6',
    ),
    _TabInfo(
      tab: DevToolsTab.storage,
      label: 'Storage',
      icon: CupertinoIcons.archivebox,
      shortcut: '7',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _activeTab = _tabs[_tabController.index].tab;
      });
    });
    
    // Initialiser le service DevTools
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final devTools = context.read<NotilusDevToolsService>();
      devTools.initialize();
      devTools.startPerformanceMonitoring();
      devTools.loadStorageEntries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;
    final bgColor = colorTheme.nativeBackgroundColor;
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header avec titre et onglets
          _buildHeader(accentColor, bgColor),
          
          // Contenu de l'onglet actif
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                DevToolsConsoleTab(),
                DevToolsNetworkTab(),
                DevToolsPerformanceTab(),
                DevToolsAlertsTab(),
                DevToolsSecurityTab(),
                DevToolsAnalyticsTab(),
                DevToolsStorageTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor, Color bgColor) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo DevTools
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.3),
                  accentColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '⚡',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          // Onglets
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tabInfo) {
                  final isActive = _activeTab == tabInfo.tab;
                  return _buildTab(tabInfo, isActive, accentColor);
                }).toList(),
              ),
            ),
          ),
          
          // Indicateur status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Consumer<NotilusDevToolsService>(
              builder: (context, devTools, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicateur recording session
                    if (devTools.isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.6),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REC',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Badge alertes critiques
                    if (devTools.criticalAlertCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${devTools.criticalAlertCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    // Badge sécurité
                    if (devTools.securityIssueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB74D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.lock_shield, size: 10, color: Colors.black87),
                            const SizedBox(width: 2),
                            Text(
                              '${devTools.securityIssueCount}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 9,
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // FPS
                    Text(
                      '${devTools.currentFps.toStringAsFixed(0)} FPS',
                      style: TextStyle(
                        color: devTools.currentFps >= 55
                            ? const Color(0xFF66BB6A)
                            : devTools.currentFps >= 30
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFFEF5350),
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(_TabInfo tabInfo, bool isActive, Color accentColor) {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(_tabs.indexOf(tabInfo));
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withOpacity(0.15)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isActive ? accentColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tabInfo.icon,
                size: 14,
                color: isActive
                    ? accentColor
                    : Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                tabInfo.label,
                style: TextStyle(
                  color: isActive
                      ? accentColor
                      : Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  tabInfo.shortcut,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabInfo {
  final DevToolsTab tab;
  final String label;
  final IconData icon;
  final String shortcut;

  const _TabInfo({
    required this.tab,
    required this.label,
    required this.icon,
    required this.shortcut,
  });
}
