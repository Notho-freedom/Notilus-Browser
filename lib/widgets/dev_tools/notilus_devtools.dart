/// Module DevTools natif de Notilus
/// Interface complète pour l'inspection et le débogage web
library notilus_devtools;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/devtools_service.dart';
import '../../services/browser_engine.dart';
import '../../core/constants/notilus_colors.dart';
import 'devtools_console_panel.dart';
import 'devtools_network_panel.dart';
import 'devtools_elements_panel.dart';
import 'devtools_performance_panel.dart';
import 'devtools_application_panel.dart';

/// Onglets disponibles dans le DevTools
enum NotilusDevToolsTab {
  console,
  network,
  elements,
  performance,
  application,
  sources,
}

extension NotilusDevToolsTabExtension on NotilusDevToolsTab {
  String get label {
    switch (this) {
      case NotilusDevToolsTab.console:
        return 'Console';
      case NotilusDevToolsTab.network:
        return 'Network';
      case NotilusDevToolsTab.elements:
        return 'Elements';
      case NotilusDevToolsTab.performance:
        return 'Performance';
      case NotilusDevToolsTab.application:
        return 'Application';
      case NotilusDevToolsTab.sources:
        return 'Sources';
    }
  }

  IconData get icon {
    switch (this) {
      case NotilusDevToolsTab.console:
        return Icons.terminal_rounded;
      case NotilusDevToolsTab.network:
        return Icons.wifi_rounded;
      case NotilusDevToolsTab.elements:
        return Icons.code_rounded;
      case NotilusDevToolsTab.performance:
        return Icons.speed_rounded;
      case NotilusDevToolsTab.application:
        return Icons.storage_rounded;
      case NotilusDevToolsTab.sources:
        return Icons.source_rounded;
    }
  }

  String get shortcut {
    switch (this) {
      case NotilusDevToolsTab.console:
        return 'Ctrl+Shift+J';
      case NotilusDevToolsTab.network:
        return 'Ctrl+Shift+E';
      case NotilusDevToolsTab.elements:
        return 'Ctrl+Shift+C';
      case NotilusDevToolsTab.performance:
        return 'Ctrl+Shift+P';
      case NotilusDevToolsTab.application:
        return 'Ctrl+Shift+A';
      case NotilusDevToolsTab.sources:
        return 'Ctrl+Shift+S';
    }
  }
}

/// Widget principal du DevTools Notilus
class NotilusDevTools extends StatefulWidget {
  final BrowserEngine? engine;
  final VoidCallback? onClose;
  final double? initialHeight;

  const NotilusDevTools({
    super.key,
    this.engine,
    this.onClose,
    this.initialHeight,
  });

  @override
  State<NotilusDevTools> createState() => _NotilusDevToolsState();
}

class _NotilusDevToolsState extends State<NotilusDevTools>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotilusDevToolsTab _activeTab = NotilusDevToolsTab.console;
  double _height = 300;
  bool _isResizing = false;
  bool _isDocked = true;

  // Tabs disponibles dans l'ordre
  final List<NotilusDevToolsTab> _tabs = [
    NotilusDevToolsTab.console,
    NotilusDevToolsTab.network,
    NotilusDevToolsTab.elements,
    NotilusDevToolsTab.performance,
    NotilusDevToolsTab.application,
  ];

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight ?? 300;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabs[_tabController.index];
        });
      }
    });

    // Attacher le moteur au service DevTools
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.engine != null) {
        final devTools = context.read<DevToolsService>();
        devTools.attachEngine(widget.engine!);
        devTools.enable();
      }
    });
  }

  @override
  void didUpdateWidget(NotilusDevTools oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engine != oldWidget.engine && widget.engine != null) {
      final devTools = context.read<DevToolsService>();
      devTools.attachEngine(widget.engine!);
      devTools.enable();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Fermer avec Escape
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onClose?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          border: Border(
            top: BorderSide(
              color: NotilusColors.neonRed.withOpacity(0.5),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: NotilusColors.neonRed.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Barre de redimensionnement
            _buildResizeHandle(),

            // Barre d'onglets
            _buildTabBar(),

            // Contenu
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle() {
    return GestureDetector(
      onVerticalDragStart: (_) {
        setState(() => _isResizing = true);
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _height = (_height - details.delta.dy).clamp(150.0, 600.0);
        });
      },
      onVerticalDragEnd: (_) {
        setState(() => _isResizing = false);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: _isResizing
                ? NotilusColors.neonRed.withOpacity(0.3)
                : Colors.transparent,
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: _isResizing
                    ? NotilusColors.neonRed
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          bottom: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo Notilus DevTools
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        NotilusColors.neonRed,
                        NotilusColors.neonRedDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'DevTools',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NotilusColors.neonRed,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.1),
          ),

          // Onglets
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: NotilusColors.neonRed,
                    width: 2,
                  ),
                ),
              ),
              labelColor: NotilusColors.neonRed,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              dividerColor: Colors.transparent,
              tabs: _tabs.map((tab) {
                return Tab(
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 14),
                      const SizedBox(width: 6),
                      Text(tab.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Statistiques rapides
          Consumer<DevToolsService>(
            builder: (context, devTools, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (devTools.errorCount > 0)
                    _StatBadge(
                      icon: Icons.error_outline,
                      count: devTools.errorCount,
                      color: Colors.red,
                    ),
                  if (devTools.warningCount > 0)
                    _StatBadge(
                      icon: Icons.warning_amber_rounded,
                      count: devTools.warningCount,
                      color: Colors.orange,
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 8),

          // Actions
          _ActionButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: 'Tout effacer',
            onPressed: () {
              context.read<DevToolsService>().clearAll();
            },
          ),

          _ActionButton(
            icon: _isDocked ? Icons.open_in_new : Icons.dock,
            tooltip: _isDocked ? 'Détacher' : 'Docker',
            onPressed: () {
              setState(() => _isDocked = !_isDocked);
              // TODO: Implémenter la fenêtre détachée
            },
          ),

          _ActionButton(
            icon: Icons.close,
            tooltip: 'Fermer (Echap)',
            onPressed: widget.onClose,
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTabContent(NotilusDevToolsTab tab) {
    switch (tab) {
      case NotilusDevToolsTab.console:
        return const DevToolsConsolePanel();
      case NotilusDevToolsTab.network:
        return const DevToolsNetworkPanel();
      case NotilusDevToolsTab.elements:
        return const DevToolsElementsPanel();
      case NotilusDevToolsTab.performance:
        return const DevToolsPerformancePanel();
      case NotilusDevToolsTab.application:
        return const DevToolsApplicationPanel();
      case NotilusDevToolsTab.sources:
        return _buildSourcesPlaceholder();
    }
  }

  Widget _buildSourcesPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.source_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Sources',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cette fonctionnalité sera disponible prochainement',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget compact pour activer/désactiver rapidement les DevTools
class NotilusDevToolsToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final int errorCount;
  final int warningCount;

  const NotilusDevToolsToggle({
    super.key,
    required this.isOpen,
    required this.onToggle,
    this.errorCount = 0,
    this.warningCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOpen
          ? NotilusColors.neonRed.withOpacity(0.2)
          : Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bug_report_outlined,
                size: 16,
                color: isOpen
                    ? NotilusColors.neonRed
                    : Colors.white.withOpacity(0.6),
              ),
              if (errorCount > 0 || warningCount > 0) ...[
                const SizedBox(width: 6),
                if (errorCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$errorCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (warningCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$warningCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
