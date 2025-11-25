/// Module DevTools natif de Notilus
/// Interface complète pour l'inspection et le débogage web
/// Utilise la couleur secondaire du thème
library notilus_devtools;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/devtools_service.dart';
import '../../services/browser_engine.dart';
import '../../core/services/color_theme_manager.dart';
import 'devtools_console_panel.dart';
import 'devtools_network_panel.dart';
import 'devtools_elements_panel.dart';
import 'devtools_performance_panel.dart';
import 'devtools_application_panel.dart';

/// Onglets disponibles dans le DevTools
enum NotilusDevToolsTab {
  elements,
  console,
  network,
  performance,
  application,
}

extension NotilusDevToolsTabExtension on NotilusDevToolsTab {
  String get label {
    switch (this) {
      case NotilusDevToolsTab.elements:
        return 'Elements';
      case NotilusDevToolsTab.console:
        return 'Console';
      case NotilusDevToolsTab.network:
        return 'Network';
      case NotilusDevToolsTab.performance:
        return 'Performance';
      case NotilusDevToolsTab.application:
        return 'Application';
    }
  }

  IconData get icon {
    switch (this) {
      case NotilusDevToolsTab.elements:
        return Icons.code_rounded;
      case NotilusDevToolsTab.console:
        return Icons.terminal_rounded;
      case NotilusDevToolsTab.network:
        return Icons.wifi_rounded;
      case NotilusDevToolsTab.performance:
        return Icons.speed_rounded;
      case NotilusDevToolsTab.application:
        return Icons.storage_rounded;
    }
  }

  String get shortcut {
    switch (this) {
      case NotilusDevToolsTab.elements:
        return 'Ctrl+Shift+C';
      case NotilusDevToolsTab.console:
        return 'Ctrl+Shift+J';
      case NotilusDevToolsTab.network:
        return 'Ctrl+Shift+E';
      case NotilusDevToolsTab.performance:
        return 'Ctrl+Shift+P';
      case NotilusDevToolsTab.application:
        return 'Ctrl+Shift+A';
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
  NotilusDevToolsTab _activeTab = NotilusDevToolsTab.elements;
  double _height = 300;
  bool _isResizing = false;
  bool _isDocked = true;
  bool _inspectMode = false;

  final List<NotilusDevToolsTab> _tabs = [
    NotilusDevToolsTab.elements,
    NotilusDevToolsTab.console,
    NotilusDevToolsTab.network,
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
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onClose?.call();
      }
    }
  }

  void _toggleInspectMode() {
    setState(() => _inspectMode = !_inspectMode);
    
    if (_inspectMode) {
      // Activer le mode inspection - injecter le script dans la page
      final devTools = context.read<DevToolsService>();
      devTools.executeScript('''
        (function() {
          if (window.__notilusInspectMode) return;
          window.__notilusInspectMode = true;
          
          const highlight = document.createElement('div');
          highlight.id = '__notilus_highlight';
          highlight.style.cssText = 'position:fixed;pointer-events:none;z-index:999999;border:2px solid #FF6B6B;background:rgba(255,107,107,0.1);transition:all 0.1s;display:none;';
          document.body.appendChild(highlight);
          
          const info = document.createElement('div');
          info.id = '__notilus_info';
          info.style.cssText = 'position:fixed;z-index:999999;background:#1E1E24;color:white;padding:4px 8px;font-size:11px;font-family:monospace;border-radius:4px;pointer-events:none;display:none;box-shadow:0 2px 8px rgba(0,0,0,0.3);';
          document.body.appendChild(info);
          
          document.addEventListener('mousemove', function(e) {
            if (!window.__notilusInspectMode) return;
            const el = document.elementFromPoint(e.clientX, e.clientY);
            if (el && el.id !== '__notilus_highlight' && el.id !== '__notilus_info') {
              const rect = el.getBoundingClientRect();
              highlight.style.display = 'block';
              highlight.style.left = rect.left + 'px';
              highlight.style.top = rect.top + 'px';
              highlight.style.width = rect.width + 'px';
              highlight.style.height = rect.height + 'px';
              
              info.style.display = 'block';
              info.style.left = (e.clientX + 10) + 'px';
              info.style.top = (e.clientY + 10) + 'px';
              info.innerHTML = '<' + el.tagName.toLowerCase() + '>' + (el.id ? ' #' + el.id : '') + (el.className ? ' .' + el.className.split(' ')[0] : '') + ' <span style="color:#888">' + Math.round(rect.width) + '×' + Math.round(rect.height) + '</span>';
            }
          });
          
          document.addEventListener('click', function(e) {
            if (!window.__notilusInspectMode) return;
            e.preventDefault();
            e.stopPropagation();
            const el = document.elementFromPoint(e.clientX, e.clientY);
            if (el && el.id !== '__notilus_highlight' && el.id !== '__notilus_info') {
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'inspect_element',
                tagName: el.tagName,
                id: el.id,
                className: el.className,
                rect: el.getBoundingClientRect(),
                attributes: Array.from(el.attributes).reduce((acc, attr) => { acc[attr.name] = attr.value; return acc; }, {}),
                outerHTML: el.outerHTML.substring(0, 500)
              }));
            }
          }, true);
        })();
      ''');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Mode inspection activé - Cliquez sur un élément'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Désactiver le mode inspection
      final devTools = context.read<DevToolsService>();
      devTools.executeScript('''
        (function() {
          window.__notilusInspectMode = false;
          const highlight = document.getElementById('__notilus_highlight');
          const info = document.getElementById('__notilus_info');
          if (highlight) highlight.style.display = 'none';
          if (info) info.style.display = 'none';
        })();
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          border: Border(
            top: BorderSide(color: accentColor.withOpacity(0.5), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildResizeHandle(accentColor),
            _buildTabBar(accentColor),
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

  Widget _buildResizeHandle(Color accentColor) {
    return GestureDetector(
      onVerticalDragStart: (_) => setState(() => _isResizing = true),
      onVerticalDragUpdate: (details) {
        setState(() {
          _height = (_height - details.delta.dy).clamp(150.0, 600.0);
        });
      },
      onVerticalDragEnd: (_) => setState(() => _isResizing = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: _isResizing ? accentColor.withOpacity(0.3) : Colors.transparent,
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: _isResizing ? accentColor : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(Color accentColor) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2))),
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
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text('N', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 6),
                Text('DevTools', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
              ],
            ),
          ),

          Container(width: 1, height: 20, color: Colors.white.withOpacity(0.1)),

          // Bouton mode inspection
          _ActionButton(
            icon: Icons.gps_fixed,
            tooltip: 'Sélectionner un élément (Ctrl+Shift+C)',
            isActive: _inspectMode,
            accentColor: accentColor,
            onPressed: _toggleInspectMode,
          ),

          Container(width: 1, height: 20, color: Colors.white.withOpacity(0.1)),

          // Onglets
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                border: Border(bottom: BorderSide(color: accentColor, width: 2)),
              ),
              labelColor: accentColor,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
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
                    _StatBadge(icon: Icons.error_outline, count: devTools.errorCount, color: Colors.red),
                  if (devTools.warningCount > 0)
                    _StatBadge(icon: Icons.warning_amber_rounded, count: devTools.warningCount, color: Colors.orange),
                ],
              );
            },
          ),

          const SizedBox(width: 8),

          _ActionButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: 'Tout effacer',
            accentColor: accentColor,
            onPressed: () => context.read<DevToolsService>().clearAll(),
          ),

          _ActionButton(
            icon: _isDocked ? Icons.open_in_new : Icons.dock,
            tooltip: _isDocked ? 'Détacher' : 'Docker',
            accentColor: accentColor,
            onPressed: () => setState(() => _isDocked = !_isDocked),
          ),

          _ActionButton(
            icon: Icons.close,
            tooltip: 'Fermer (Echap)',
            accentColor: accentColor,
            onPressed: widget.onClose,
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTabContent(NotilusDevToolsTab tab) {
    switch (tab) {
      case NotilusDevToolsTab.elements:
        return const DevToolsElementsPanel();
      case NotilusDevToolsTab.console:
        return const DevToolsConsolePanel();
      case NotilusDevToolsTab.network:
        return const DevToolsNetworkPanel();
      case NotilusDevToolsTab.performance:
        return const DevToolsPerformancePanel();
      case NotilusDevToolsTab.application:
        return const DevToolsApplicationPanel();
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatBadge({required this.icon, required this.count, required this.color});

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
          Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? accentColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? accentColor : Colors.white.withOpacity(0.6),
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
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Material(
      color: isOpen ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
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
                color: isOpen ? accentColor : Colors.white.withOpacity(0.6),
              ),
              if (errorCount > 0 || warningCount > 0) ...[
                const SizedBox(width: 6),
                if (errorCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$errorCount',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.red),
                    ),
                  ),
                if (warningCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$warningCount',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange),
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
