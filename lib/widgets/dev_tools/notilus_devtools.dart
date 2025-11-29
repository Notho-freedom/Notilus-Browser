/// Module DevTools natif de Notilus
/// Interface complète pour l'inspection et le débogage web
/// Utilise la couleur secondaire du thème
library notilus_devtools;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/devtools_service.dart';
import '../../services/browser_engine.dart';
import '../../services/settings_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import 'devtools_console_panel.dart';
import 'devtools_network_panel.dart';
import 'devtools_elements_panel.dart';
import 'devtools_performance_panel.dart';
import 'devtools_application_panel.dart';
import 'devtools_resources_panel.dart';
import 'backend_lab_panel.dart';

/// Onglets disponibles dans le DevTools
enum NotilusDevToolsTab {
  elements,
  console,
  network,
  resources,
  performance,
  application,
  backendLab,
}

extension NotilusDevToolsTabExtension on NotilusDevToolsTab {
  String get label {
    switch (this) {
      case NotilusDevToolsTab.elements: return 'Elements';
      case NotilusDevToolsTab.console: return 'Console';
      case NotilusDevToolsTab.network: return 'Network';
      case NotilusDevToolsTab.resources: return 'Resources';
      case NotilusDevToolsTab.performance: return 'Performance';
      case NotilusDevToolsTab.application: return 'Application';
      case NotilusDevToolsTab.backendLab: return 'Backend Lab';
    }
  }

  IconData get icon {
    switch (this) {
      case NotilusDevToolsTab.elements: return Icons.code_rounded;
      case NotilusDevToolsTab.console: return Icons.terminal_rounded;
      case NotilusDevToolsTab.network: return Icons.wifi_rounded;
      case NotilusDevToolsTab.resources: return Icons.folder_rounded;
      case NotilusDevToolsTab.performance: return Icons.speed_rounded;
      case NotilusDevToolsTab.application: return Icons.storage_rounded;
      case NotilusDevToolsTab.backendLab: return Icons.science_rounded;
    }
  }

  String get shortcut {
    switch (this) {
      case NotilusDevToolsTab.elements: return 'Ctrl+Shift+C';
      case NotilusDevToolsTab.console: return 'Ctrl+Shift+J';
      case NotilusDevToolsTab.network: return 'Ctrl+Shift+E';
      case NotilusDevToolsTab.resources: return 'Ctrl+Shift+R';
      case NotilusDevToolsTab.performance: return 'Ctrl+Shift+P';
      case NotilusDevToolsTab.application: return 'Ctrl+Shift+A';
      case NotilusDevToolsTab.backendLab: return 'Ctrl+Shift+B';
    }
  }
}

/// Widget principal du DevTools Notilus
class NotilusDevTools extends StatefulWidget {
  final BrowserEngine? engine;
  final VoidCallback? onClose;
  final double? initialHeight;
  final VoidCallback? onDetach; // Callback pour détacher vers mini DevTools

  const NotilusDevTools({
    super.key,
    this.engine,
    this.onClose,
    this.initialHeight,
    this.onDetach,
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
  bool _responsiveMode = false;
  String _responsiveDevice = 'desktop'; // 'mobile', 'tablet', 'desktop'
  
  // Inspection avancée
  Map<String, dynamic>? _inspectedElement;
  bool _showInspectorPanel = false;

  final List<NotilusDevToolsTab> _tabs = NotilusDevToolsTab.values;

  static const Map<String, Map<String, dynamic>> _responsiveDevices = {
    'mobile': {'name': 'Mobile', 'width': 375, 'height': 667, 'icon': Icons.phone_android},
    'tablet': {'name': 'Tablet', 'width': 768, 'height': 1024, 'icon': Icons.tablet_android},
    'desktop': {'name': 'Desktop', 'width': 1920, 'height': 1080, 'icon': Icons.desktop_windows},
    'iphone14': {'name': 'iPhone 14', 'width': 390, 'height': 844, 'icon': Icons.phone_iphone},
    'pixel7': {'name': 'Pixel 7', 'width': 412, 'height': 915, 'icon': Icons.phone_android},
    'ipadPro': {'name': 'iPad Pro', 'width': 1024, 'height': 1366, 'icon': Icons.tablet_mac},
  };

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
        if (_inspectMode) {
          _toggleInspectMode();
        } else {
        widget.onClose?.call();
        }
      }
    }
  }

  void _toggleInspectMode() {
    setState(() => _inspectMode = !_inspectMode);
    
    final devTools = context.read<DevToolsService>();
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentHex = _colorToHex(colorTheme.nativeSecondaryColor);
    
    if (_inspectMode) {
      // Script d'inspection avancé avec box model complet
      devTools.executeScript('''
        (function() {
          if (window.__notilusInspectMode) return;
          window.__notilusInspectMode = true;
          
          // Créer les overlays
          const overlay = document.createElement('div');
          overlay.id = '__notilus_overlay';
          overlay.innerHTML = \`
            <div id="__notilus_content" style="position:absolute;background:rgba(111,168,220,0.66);pointer-events:none;"></div>
            <div id="__notilus_padding" style="position:absolute;background:rgba(147,196,125,0.55);pointer-events:none;"></div>
            <div id="__notilus_border" style="position:absolute;background:rgba(255,229,153,0.66);pointer-events:none;"></div>
            <div id="__notilus_margin" style="position:absolute;background:rgba(246,178,107,0.66);pointer-events:none;"></div>
          \`;
          overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:999998;';
          document.body.appendChild(overlay);
          
          // Info tooltip amélioré
          const info = document.createElement('div');
          info.id = '__notilus_info';
          info.style.cssText = 'position:fixed;z-index:999999;background:#1E1E24;color:white;padding:8px 12px;font-size:11px;font-family:"JetBrains Mono",monospace;border-radius:6px;pointer-events:none;display:none;box-shadow:0 4px 12px rgba(0,0,0,0.4);border:1px solid $accentHex;max-width:300px;';
          document.body.appendChild(info);
          
          // Guidelines
          const guideH = document.createElement('div');
          guideH.id = '__notilus_guide_h';
          guideH.style.cssText = 'position:fixed;left:0;right:0;height:1px;background:$accentHex;opacity:0.5;pointer-events:none;z-index:999997;display:none;';
          document.body.appendChild(guideH);
          
          const guideV = document.createElement('div');
          guideV.id = '__notilus_guide_v';
          guideV.style.cssText = 'position:fixed;top:0;bottom:0;width:1px;background:$accentHex;opacity:0.5;pointer-events:none;z-index:999997;display:none;';
          document.body.appendChild(guideV);
          
          function getBoxModel(el) {
            const rect = el.getBoundingClientRect();
            const style = getComputedStyle(el);
            
            const margin = {
              top: parseFloat(style.marginTop) || 0,
              right: parseFloat(style.marginRight) || 0,
              bottom: parseFloat(style.marginBottom) || 0,
              left: parseFloat(style.marginLeft) || 0
            };
            
            const border = {
              top: parseFloat(style.borderTopWidth) || 0,
              right: parseFloat(style.borderRightWidth) || 0,
              bottom: parseFloat(style.borderBottomWidth) || 0,
              left: parseFloat(style.borderLeftWidth) || 0
            };
            
            const padding = {
              top: parseFloat(style.paddingTop) || 0,
              right: parseFloat(style.paddingRight) || 0,
              bottom: parseFloat(style.paddingBottom) || 0,
              left: parseFloat(style.paddingLeft) || 0
            };
            
            return { rect, margin, border, padding, style };
          }
          
          function updateOverlay(el) {
            const { rect, margin, border, padding } = getBoxModel(el);
            
            const content = document.getElementById('__notilus_content');
            const paddingEl = document.getElementById('__notilus_padding');
            const borderEl = document.getElementById('__notilus_border');
            const marginEl = document.getElementById('__notilus_margin');
            
            // Content box
            const contentW = rect.width - padding.left - padding.right - border.left - border.right;
            const contentH = rect.height - padding.top - padding.bottom - border.top - border.bottom;
            content.style.cssText = 'position:absolute;background:rgba(111,168,220,0.66);pointer-events:none;' +
              'left:' + (rect.left + border.left + padding.left) + 'px;' +
              'top:' + (rect.top + border.top + padding.top) + 'px;' +
              'width:' + Math.max(0, contentW) + 'px;' +
              'height:' + Math.max(0, contentH) + 'px;';
            
            // Padding box
            paddingEl.style.cssText = 'position:absolute;background:rgba(147,196,125,0.55);pointer-events:none;' +
              'left:' + (rect.left + border.left) + 'px;' +
              'top:' + (rect.top + border.top) + 'px;' +
              'width:' + (rect.width - border.left - border.right) + 'px;' +
              'height:' + (rect.height - border.top - border.bottom) + 'px;' +
              'clip-path:polygon(0 0,100% 0,100% 100%,0 100%,' +
              padding.left + 'px ' + (rect.height - border.top - border.bottom - padding.bottom) + 'px,' +
              padding.left + 'px ' + padding.top + 'px,' +
              (rect.width - border.left - border.right - padding.right) + 'px ' + padding.top + 'px,' +
              (rect.width - border.left - border.right - padding.right) + 'px ' + (rect.height - border.top - border.bottom - padding.bottom) + 'px,' +
              padding.left + 'px ' + (rect.height - border.top - border.bottom - padding.bottom) + 'px,' +
              '0 100%);';
            
            // Border box
            borderEl.style.cssText = 'position:absolute;background:rgba(255,229,153,0.66);pointer-events:none;' +
              'left:' + rect.left + 'px;' +
              'top:' + rect.top + 'px;' +
              'width:' + rect.width + 'px;' +
              'height:' + rect.height + 'px;' +
              'clip-path:polygon(0 0,100% 0,100% 100%,0 100%,' +
              border.left + 'px ' + (rect.height - border.bottom) + 'px,' +
              border.left + 'px ' + border.top + 'px,' +
              (rect.width - border.right) + 'px ' + border.top + 'px,' +
              (rect.width - border.right) + 'px ' + (rect.height - border.bottom) + 'px,' +
              border.left + 'px ' + (rect.height - border.bottom) + 'px,' +
              '0 100%);';
            
            // Margin box
            marginEl.style.cssText = 'position:absolute;background:rgba(246,178,107,0.66);pointer-events:none;' +
              'left:' + (rect.left - margin.left) + 'px;' +
              'top:' + (rect.top - margin.top) + 'px;' +
              'width:' + (rect.width + margin.left + margin.right) + 'px;' +
              'height:' + (rect.height + margin.top + margin.bottom) + 'px;' +
              'clip-path:polygon(0 0,100% 0,100% 100%,0 100%,' +
              margin.left + 'px ' + (rect.height + margin.top) + 'px,' +
              margin.left + 'px ' + margin.top + 'px,' +
              (rect.width + margin.left) + 'px ' + margin.top + 'px,' +
              (rect.width + margin.left) + 'px ' + (rect.height + margin.top) + 'px,' +
              margin.left + 'px ' + (rect.height + margin.top) + 'px,' +
              '0 100%);';
          }
          
          document.addEventListener('mousemove', function(e) {
            if (!window.__notilusInspectMode) return;
            const el = document.elementFromPoint(e.clientX, e.clientY);
            if (el && !el.id.startsWith('__notilus')) {
              updateOverlay(el);
              
              // Update guidelines
              const rect = el.getBoundingClientRect();
              document.getElementById('__notilus_guide_h').style.display = 'block';
              document.getElementById('__notilus_guide_h').style.top = (rect.top + rect.height/2) + 'px';
              document.getElementById('__notilus_guide_v').style.display = 'block';
              document.getElementById('__notilus_guide_v').style.left = (rect.left + rect.width/2) + 'px';
              
              // Update tooltip
              const info = document.getElementById('__notilus_info');
              const { style } = getBoxModel(el);
              info.style.display = 'block';
              info.style.left = Math.min(e.clientX + 15, window.innerWidth - 320) + 'px';
              info.style.top = Math.min(e.clientY + 15, window.innerHeight - 150) + 'px';
              
              let classStr = el.className ? '.' + el.className.toString().split(' ').filter(c=>c).join('.') : '';
              if (classStr.length > 30) classStr = classStr.substring(0, 30) + '...';
              
              info.innerHTML = \`
                <div style="color:$accentHex;font-weight:600;margin-bottom:4px;">
                  &lt;\${el.tagName.toLowerCase()}&gt;\${el.id ? ' <span style="color:#9CDCFE">#\${el.id}</span>' : ''}\${classStr ? ' <span style="color:#CE9178">\${classStr}</span>' : ''}
                </div>
                <div style="color:#888;font-size:10px;">
                  <span style="color:#6FB3D2">\${Math.round(rect.width)}</span> × <span style="color:#6FB3D2">\${Math.round(rect.height)}</span>px
                  \${style.display !== 'block' ? ' • <span style="color:#BA68C8">' + style.display + '</span>' : ''}
                  \${style.position !== 'static' ? ' • <span style="color:#4FC1FF">' + style.position + '</span>' : ''}
                </div>
                <div style="margin-top:6px;padding-top:6px;border-top:1px solid #333;font-size:9px;color:#666;">
                  <span style="background:#6fb3d2;color:#000;padding:1px 3px;border-radius:2px;">content</span>
                  <span style="background:#93c47d;color:#000;padding:1px 3px;border-radius:2px;">padding</span>
                  <span style="background:#ffe599;color:#000;padding:1px 3px;border-radius:2px;">border</span>
                  <span style="background:#f6b26b;color:#000;padding:1px 3px;border-radius:2px;">margin</span>
                </div>
              \`;
            }
          });
          
          document.addEventListener('click', function(e) {
            if (!window.__notilusInspectMode) return;
            e.preventDefault();
            e.stopPropagation();
            const el = document.elementFromPoint(e.clientX, e.clientY);
            if (el && !el.id.startsWith('__notilus')) {
              const { rect, margin, border, padding, style } = getBoxModel(el);
              
              // Collecter les styles calculés importants
              const computedStyles = {
                display: style.display,
                position: style.position,
                width: style.width,
                height: style.height,
                color: style.color,
                backgroundColor: style.backgroundColor,
                fontSize: style.fontSize,
                fontFamily: style.fontFamily,
                fontWeight: style.fontWeight,
                lineHeight: style.lineHeight,
                textAlign: style.textAlign,
                flexDirection: style.flexDirection,
                justifyContent: style.justifyContent,
                alignItems: style.alignItems,
                gap: style.gap,
                gridTemplateColumns: style.gridTemplateColumns,
                overflow: style.overflow,
                zIndex: style.zIndex,
                opacity: style.opacity,
                transform: style.transform,
                transition: style.transition,
              };
              
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'inspect_element_detailed',
                tagName: el.tagName,
                id: el.id,
                className: el.className.toString(),
                rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
                boxModel: { margin, border, padding },
                computedStyles: computedStyles,
                attributes: Array.from(el.attributes).reduce((acc, attr) => { acc[attr.name] = attr.value; return acc; }, {}),
                outerHTML: el.outerHTML.substring(0, 1000),
                textContent: el.textContent?.substring(0, 200) || '',
                childCount: el.children.length,
                parentTag: el.parentElement?.tagName || null,
              }));
            }
          }, true);
          
          // Cleanup on disable
          window.__notilusCleanupInspect = function() {
            const ids = ['__notilus_overlay', '__notilus_info', '__notilus_guide_h', '__notilus_guide_v'];
            ids.forEach(id => document.getElementById(id)?.remove());
            window.__notilusInspectMode = false;
          };
        })();
      ''');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.gps_fixed, size: 16, color: colorTheme.nativeSecondaryColor),
              const SizedBox(width: 8),
              const Expanded(child: Text('Mode inspection activé - Cliquez sur un élément')),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E24),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Désactiver le mode inspection
      devTools.executeScript('if(window.__notilusCleanupInspect) window.__notilusCleanupInspect();');
      setState(() => _showInspectorPanel = false);
    }
  }
  
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
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
          border: Border(top: BorderSide(color: accentColor.withOpacity(0.5), width: 1)),
          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          children: [
            _buildResizeHandle(accentColor),
            _buildTabBar(accentColor),
            Expanded(
              child: Row(
                children: [
                  // Main content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
                    ),
                  ),
                  
                  // Inspector panel (quand un élément est sélectionné)
                  if (_showInspectorPanel && _inspectedElement != null)
                    _buildInspectorPanel(accentColor),
                ],
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
      onVerticalDragUpdate: (details) => setState(() => _height = (_height - details.delta.dy).clamp(150.0, 600.0)),
      onVerticalDragEnd: (_) => setState(() => _isResizing = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 6,
          color: _isResizing ? accentColor.withOpacity(0.3) : Colors.transparent,
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
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(child: Text('N', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white))),
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
          
          // Bouton device mode
          _ActionButton(
            icon: Icons.devices,
            tooltip: 'Mode responsive',
            isActive: _responsiveMode,
            accentColor: accentColor,
            onPressed: () => _showResponsiveMenu(context, accentColor),
          ),

          Container(width: 1, height: 20, color: Colors.white.withOpacity(0.1)),

          // Onglets
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(border: Border(bottom: BorderSide(color: accentColor, width: 2))),
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

          // Statistiques
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

          _ActionButton(icon: Icons.cleaning_services_outlined, tooltip: 'Tout effacer', accentColor: accentColor, onPressed: () => context.read<DevToolsService>().clearAll()),
          _ActionButton(icon: Icons.settings_outlined, tooltip: 'Paramètres DevTools', accentColor: accentColor, onPressed: () {
            _showDevToolsSettings(context, accentColor);
          }),
          _ActionButton(
            icon: _isDocked ? Icons.open_in_new : Icons.dock,
            tooltip: _isDocked ? 'Détacher' : 'Docker',
            accentColor: accentColor,
            onPressed: () {
              if (_isDocked && widget.onDetach != null) {
                // Si docked et callback disponible, ouvrir mini DevTools
                widget.onDetach!();
              } else {
                // Sinon, toggle dock state
                setState(() => _isDocked = !_isDocked);
              }
            },
          ),
          _ActionButton(icon: Icons.close, tooltip: 'Fermer (Echap)', accentColor: accentColor, onPressed: widget.onClose),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTabContent(NotilusDevToolsTab tab) {
    switch (tab) {
      case NotilusDevToolsTab.elements: return const DevToolsElementsPanel();
      case NotilusDevToolsTab.console: return const DevToolsConsolePanel();
      case NotilusDevToolsTab.network: return const DevToolsNetworkPanel();
      case NotilusDevToolsTab.resources: return const DevToolsResourcesPanel();
      case NotilusDevToolsTab.performance: return const DevToolsPerformancePanel();
      case NotilusDevToolsTab.application: return const DevToolsApplicationPanel();
      case NotilusDevToolsTab.backendLab: return const BackendLabPanel();
    }
  }
  
  Widget _buildInspectorPanel(Color accentColor) {
    final element = _inspectedElement!;
    final boxModel = element['boxModel'] as Map<String, dynamic>?;
    final styles = element['computedStyles'] as Map<String, dynamic>?;
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        border: Border(left: BorderSide(color: accentColor.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252526),
              border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(Icons.select_all, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '<${element['tagName']?.toLowerCase()}>',
                    style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 12),
                  color: Colors.white38,
                  onPressed: () => setState(() => _showInspectorPanel = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Box Model Visualization
                if (boxModel != null) ...[
                  Text('BOX MODEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accentColor, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _BoxModelWidget(
                    margin: boxModel['margin'],
                    border: boxModel['border'],
                    padding: boxModel['padding'],
                    contentWidth: element['rect']?['width']?.toDouble() ?? 0,
                    contentHeight: element['rect']?['height']?.toDouble() ?? 0,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Computed Styles
                if (styles != null) ...[
                  Text('COMPUTED STYLES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accentColor, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...styles.entries.where((e) => e.value != null && e.value != '' && e.value != 'none' && e.value != 'normal').map((e) {
                    return _StyleRow(property: e.key, value: e.value.toString());
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResponsiveMenu(BuildContext context, Color accentColor) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;
    
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(
      Offset(button.size.width - 250, button.size.height),
      ancestor: overlay,
    );

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx - 250,
        overlay.size.height - position.dy,
      ),
      color: const Color(0xFF1A1A20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(Icons.desktop_windows, color: accentColor, size: 18),
              const SizedBox(width: 12),
              const Text('Desktop', style: TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              if (_responsiveDevice == 'desktop')
                Icon(Icons.check, color: accentColor, size: 16),
            ],
          ),
          onTap: () {
            setState(() {
              _responsiveMode = true;
              _responsiveDevice = 'desktop';
            });
            _applyResponsiveMode();
          },
        ),
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(Icons.tablet_android, color: accentColor, size: 18),
              const SizedBox(width: 12),
              const Text('Tablet', style: TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              if (_responsiveDevice == 'tablet')
                Icon(Icons.check, color: accentColor, size: 16),
            ],
          ),
          onTap: () {
            setState(() {
              _responsiveMode = true;
              _responsiveDevice = 'tablet';
            });
            _applyResponsiveMode();
          },
        ),
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(Icons.phone_android, color: accentColor, size: 18),
              const SizedBox(width: 12),
              const Text('Mobile', style: TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              if (_responsiveDevice == 'mobile')
                Icon(Icons.check, color: accentColor, size: 16),
            ],
          ),
          onTap: () {
            setState(() {
              _responsiveMode = true;
              _responsiveDevice = 'mobile';
            });
            _applyResponsiveMode();
          },
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(Icons.close, color: Colors.white.withOpacity(0.5), size: 18),
              const SizedBox(width: 12),
              const Text('Désactiver', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          onTap: () {
            setState(() {
              _responsiveMode = false;
            });
            _removeResponsiveMode();
          },
        ),
      ],
    );
  }

  void _applyResponsiveMode() {
    final devTools = context.read<DevToolsService>();
    final device = _responsiveDevices[_responsiveDevice]!;
    final width = device['width'] as int;
    final height = device['height'] as int;
    
    devTools.executeScript('''
      (function() {
        const viewport = document.querySelector('meta[name="viewport"]');
        if (!viewport) {
          const meta = document.createElement('meta');
          meta.name = 'viewport';
          meta.content = 'width=$width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
          document.head.appendChild(meta);
        } else {
          viewport.content = 'width=$width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        }
        
        // Appliquer la taille au body
        document.body.style.maxWidth = '${width}px';
        document.body.style.margin = '0 auto';
        document.body.style.border = '2px solid #FF6B6B';
        document.body.style.boxShadow = '0 0 20px rgba(255, 107, 107, 0.3)';
      })();
    ''');
  }

  void _removeResponsiveMode() {
    final devTools = context.read<DevToolsService>();
    devTools.executeScript('''
      (function() {
        const viewport = document.querySelector('meta[name="viewport"]');
        if (viewport) {
          viewport.content = 'width=device-width, initial-scale=1.0';
        }
        document.body.style.maxWidth = '';
        document.body.style.margin = '';
        document.body.style.border = '';
        document.body.style.boxShadow = '';
      })();
    ''');
  }

  void _showDevToolsSettings(BuildContext context, Color accentColor) {
    GxFuturisticDialog.show(
      context: context,
      title: 'Paramètres DevTools',
      titleIcon: Icons.settings_rounded,
      accentColor: accentColor,
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Les paramètres DevTools sont disponibles dans le panneau Paramètres de l\'application.',
            style: NotilusFonts.rajdhani(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          GxFuturisticButton(
            label: 'Ouvrir les paramètres',
            icon: Icons.settings_rounded,
            variant: GxFuturisticButtonVariant.primary,
            accentColor: accentColor,
            onPressed: () {
              Navigator.pop(context);
              // Ouvrir le panneau settings (sera géré par le parent)
            },
          ),
        ],
      ),
      actions: [
        GxFuturisticButton(
          label: 'Fermer',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
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
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
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

  const _ActionButton({required this.icon, required this.tooltip, required this.accentColor, this.onPressed, this.isActive = false});

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
            child: Icon(icon, size: 16, color: isActive ? accentColor : Colors.white.withOpacity(0.6)),
            ),
          ),
        ),
    );
  }
}

/// Widget de visualisation du Box Model
class _BoxModelWidget extends StatelessWidget {
  final Map<String, dynamic> margin;
  final Map<String, dynamic> border;
  final Map<String, dynamic> padding;
  final double contentWidth;
  final double contentHeight;

  const _BoxModelWidget({
    required this.margin,
    required this.border,
    required this.padding,
    required this.contentWidth,
    required this.contentHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Margin box
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6B26B).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _BoxLabels(
                top: margin['top']?.toDouble() ?? 0,
                right: margin['right']?.toDouble() ?? 0,
                bottom: margin['bottom']?.toDouble() ?? 0,
                left: margin['left']?.toDouble() ?? 0,
                label: 'margin',
              ),
            ),
          ),
          
          // Border box
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE599).withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: _BoxLabels(
                top: border['top']?.toDouble() ?? 0,
                right: border['right']?.toDouble() ?? 0,
                bottom: border['bottom']?.toDouble() ?? 0,
                left: border['left']?.toDouble() ?? 0,
                label: 'border',
              ),
            ),
          ),
          
          // Padding box
          Positioned(
            top: 35,
            left: 35,
            right: 35,
            bottom: 35,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF93C47D).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: _BoxLabels(
                top: padding['top']?.toDouble() ?? 0,
                right: padding['right']?.toDouble() ?? 0,
                bottom: padding['bottom']?.toDouble() ?? 0,
                left: padding['left']?.toDouble() ?? 0,
                label: 'padding',
              ),
            ),
          ),
          
          // Content box
          Positioned(
            top: 50,
            left: 50,
            right: 50,
            bottom: 50,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6FB3D2).withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text(
                  '${contentWidth.toInt()} × ${contentHeight.toInt()}',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxLabels extends StatelessWidget {
  final double top, right, bottom, left;
  final String label;

  const _BoxLabels({required this.top, required this.right, required this.bottom, required this.left, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (top > 0) Positioned(top: 2, left: 0, right: 0, child: Center(child: Text('${top.toInt()}', style: const TextStyle(fontSize: 8, color: Colors.white70)))),
        if (bottom > 0) Positioned(bottom: 2, left: 0, right: 0, child: Center(child: Text('${bottom.toInt()}', style: const TextStyle(fontSize: 8, color: Colors.white70)))),
        if (left > 0) Positioned(left: 2, top: 0, bottom: 0, child: Center(child: Text('${left.toInt()}', style: const TextStyle(fontSize: 8, color: Colors.white70)))),
        if (right > 0) Positioned(right: 2, top: 0, bottom: 0, child: Center(child: Text('${right.toInt()}', style: const TextStyle(fontSize: 8, color: Colors.white70)))),
      ],
    );
  }
}

class _StyleRow extends StatelessWidget {
  final String property;
  final String value;

  const _StyleRow({required this.property, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(_formatProperty(property), style: const TextStyle(fontSize: 10, color: Color(0xFF9CDCFE), fontFamily: 'JetBrains Mono')),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 10, color: Color(0xFFCE9178), fontFamily: 'JetBrains Mono'), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
  
  String _formatProperty(String prop) {
    // CamelCase to kebab-case
    return prop.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '-${m.group(0)!.toLowerCase()}');
  }
}

/// Widget compact pour activer/désactiver rapidement les DevTools
class NotilusDevToolsToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final int errorCount;
  final int warningCount;

  const NotilusDevToolsToggle({super.key, required this.isOpen, required this.onToggle, this.errorCount = 0, this.warningCount = 0});

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
              Icon(Icons.bug_report_outlined, size: 16, color: isOpen ? accentColor : Colors.white.withOpacity(0.6)),
              if (errorCount > 0 || warningCount > 0) ...[
                const SizedBox(width: 6),
                if (errorCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('$errorCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.red)),
                  ),
                if (warningCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('$warningCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange)),
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
