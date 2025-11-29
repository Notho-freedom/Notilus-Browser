/// Mini panel DevTools flottant "Notilus style"
/// Panel léger avec blur/transparency intégré à Notilus
/// Carte futuriste déplaçable avec mode collapse/expand
library notilus_mini_devtools_panel;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/devtools_service.dart';
import '../../services/browser_engine.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../models/devtools_models.dart';
import '../common/notilus_tooltip.dart';
import '../../services/gx_notification_service.dart';
import 'notilus_devtools.dart';

/// Mini panel DevTools flottant avec style Notilus dans une carte futuriste
class NotilusMiniDevToolsPanel extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isVisible;
  final Duration animationDuration;
  final BrowserEngine? engine; // Optionnel : pour attacher le service
  final VoidCallback? onSwitchToNative; // Callback pour ouvrir le DevTools natif en bas

  const NotilusMiniDevToolsPanel({
    super.key,
    this.onClose,
    this.isVisible = false,
    this.animationDuration = const Duration(milliseconds: 250),
    this.engine,
    this.onSwitchToNative,
  });

  @override
  State<NotilusMiniDevToolsPanel> createState() => _NotilusMiniDevToolsPanelState();
}

class _NotilusMiniDevToolsPanelState extends State<NotilusMiniDevToolsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _activeTab = 'console'; // 'console' ou 'network'
  final ScrollController _consoleScrollController = ScrollController();
  final ScrollController _networkScrollController = ScrollController();
  
  // État pour le déplacement et collapse/expand
  bool _isCollapsed = false;
  Offset _position = const Offset(0, 0);
  bool _isDragging = false;
  Offset _dragStartPosition = Offset.zero;
  Offset _dragStartOffset = Offset.zero;
  
  // Constantes pour les dimensions
  static const double _expandedWidth = 320.0;
  static const double _expandedHeight = 300.0;
  static const double _collapsedWidth = 200.0;
  static const double _collapsedHeight = 28.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // En bas
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Position par défaut : coin bas-droite
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      _position = Offset(
        screenSize.width - _expandedWidth - 12,
        screenSize.height - _expandedHeight - 12,
      );
    });

    if (widget.isVisible) {
      _animationController.forward();
    }

    // Attacher le service DevTools si un engine est fourni
    if (widget.engine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final devToolsService = Provider.of<DevToolsService>(context, listen: false);
        devToolsService.attachEngine(widget.engine!);
        devToolsService.enable();
      });
    }
  }

  @override
  void didUpdateWidget(NotilusMiniDevToolsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _consoleScrollController.dispose();
    _networkScrollController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      
      // Quand on collapse, repositionner dans le coin bas-droite
      if (_isCollapsed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final screenSize = MediaQuery.of(context).size;
          setState(() {
            _position = Offset(
              screenSize.width - _collapsedWidth - 12,
              screenSize.height - _collapsedHeight - 12,
            );
          });
        });
      }
    });
  }

  void _switchToNativeDevTools() {
    // Ouvrir le DevTools natif en bas via le callback
    // On utilise un callback pour communiquer avec le parent
    if (widget.onSwitchToNative != null) {
      widget.onSwitchToNative!();
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _dragStartOffset = _position;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        final delta = details.globalPosition - _dragStartPosition;
        _position = _dragStartOffset + delta;
        
        // Limiter la position dans les bounds de l'écran
        final screenSize = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
            WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
        final panelWidth = _isCollapsed ? _collapsedWidth : _expandedWidth;
        final panelHeight = _isCollapsed ? _collapsedHeight : _expandedHeight;
        
        _position = Offset(
          _position.dx.clamp(0.0, screenSize.width - panelWidth),
          _position.dy.clamp(0.0, screenSize.height - panelHeight),
        );
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _animationController.value == 0) {
      return const SizedBox.shrink();
    }

    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: MouseRegion(
            cursor: _isDragging ? SystemMouseCursors.move : SystemMouseCursors.basic,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: _isCollapsed ? _collapsedWidth : _expandedWidth,
                    height: _isCollapsed ? _collapsedHeight : _expandedHeight,
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(_isCollapsed ? 6 : 12),
                      border: Border.all(
                        color: gxRed.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: _isCollapsed ? 10 : 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isCollapsed ? _buildCollapsedView(context, gxRed) : _buildExpandedView(context, gxRed),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedView(BuildContext context, Color gxRed) {
    // Vue minimale : une seule ligne compacte
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.ant, size: 12, color: gxRed),
          const SizedBox(width: 6),
          Text(
            'DevTools',
            style: NotilusFonts.rajdhani(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          NotilusTooltip(
            message: 'Développer',
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 20,
              onPressed: _toggleCollapse,
              child: Icon(CupertinoIcons.chevron_up, size: 12, color: gxRed),
            ),
          ),
          const SizedBox(width: 2),
          NotilusTooltip(
            message: 'DevTools natif',
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 20,
              onPressed: _switchToNativeDevTools,
              child: Icon(CupertinoIcons.square_grid_2x2, size: 12, color: gxRed),
            ),
          ),
          if (widget.onClose != null) ...[
            const SizedBox(width: 2),
            NotilusTooltip(
              message: 'Fermer',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 20,
                onPressed: widget.onClose,
                child: Icon(CupertinoIcons.xmark, size: 12, color: gxRed.withOpacity(0.7)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedView(BuildContext context, Color gxRed) {
    return SizedBox(
      width: _expandedWidth,
      height: _expandedHeight,
      child: Column(
        children: [
          // Header avec drag handle et contrôles
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(color: gxRed.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Drag handle
                Icon(CupertinoIcons.bars, size: 14, color: gxRed.withOpacity(0.6)),
                const SizedBox(width: 8),
                // Tabs
                _buildTabButton('console', 'Console', CupertinoIcons.text_alignleft, gxRed),
                const SizedBox(width: 4),
                _buildTabButton('network', 'Network', CupertinoIcons.wifi, gxRed),
                const Spacer(),
                // Bouton collapse
                NotilusTooltip(
                  message: 'Réduire',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    onPressed: _toggleCollapse,
                    child: Icon(CupertinoIcons.chevron_down, size: 14, color: gxRed),
                  ),
                ),
                const SizedBox(width: 4),
                // Bouton switch vers natif
                NotilusTooltip(
                  message: 'DevTools natif',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    onPressed: _switchToNativeDevTools,
                    child: Icon(CupertinoIcons.square_grid_2x2, size: 14, color: gxRed),
                  ),
                ),
                if (widget.onClose != null) ...[
                  const SizedBox(width: 4),
                  NotilusTooltip(
                    message: 'Fermer (Esc)',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 24,
                      onPressed: widget.onClose,
                      child: Icon(CupertinoIcons.xmark, size: 14, color: gxRed.withOpacity(0.7)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Content area
          Expanded(
            child: _buildContent(context, gxRed),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon, Color gxRed) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? gxRed.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isActive ? Border.all(color: gxRed.withOpacity(0.4), width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? gxRed : gxRed.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: isActive ? gxRed : gxRed.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color gxRed) {
    return Consumer<DevToolsService>(
      builder: (context, devToolsService, _) {
        if (_activeTab == 'console') {
          return _buildConsolePanel(context, devToolsService, gxRed);
        } else {
          return _buildNetworkPanel(context, devToolsService, gxRed);
        }
      },
    );
  }

  Widget _buildConsolePanel(BuildContext context, DevToolsService service, Color gxRed) {
    final logs = service.consoleLogs;
    
    // Auto-scroll vers le bas quand de nouveaux logs arrivent
    if (logs.isNotEmpty && _consoleScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
    
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.text_alignleft,
              size: 32,
              color: gxRed.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun log console',
              style: TextStyle(
                color: gxRed.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Les logs apparaîtront ici',
              style: TextStyle(
                color: gxRed.withOpacity(0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black.withOpacity(0.2),
      child: ListView.builder(
        controller: _consoleScrollController,
        padding: const EdgeInsets.all(8),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildConsoleLogItem(log, gxRed);
        },
      ),
    );
  }

  Widget _buildConsoleLogItem(ConsoleEntry log, Color gxRed) {
    final logColor = log.level.color;
    final logIcon = log.level.icon;

    return GestureDetector(
      onLongPress: () => _copyLogMessage(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: logColor.withOpacity(0.5),
              width: 2,
            ),
          ),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            logIcon,
            size: 12,
            color: logColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontFamily: 'Consolas',
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.source != null || log.lineNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (log.source != null) ...[
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 8,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.source!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
                        if (log.lineNumber != null) ...[
                          if (log.source != null) const SizedBox(width: 8),
                          Text(
                            'L${log.lineNumber}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Bouton de copie
          NotilusTooltip(
            message: 'Copier',
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 20,
              onPressed: () => _copyLogMessage(log),
              child: Icon(
                CupertinoIcons.doc_on_doc,
                size: 12,
                color: gxRed.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _copyLogMessage(ConsoleEntry log) {
    // Construire le texte à copier avec toutes les informations
    final buffer = StringBuffer();
    buffer.writeln(log.message);
    if (log.source != null) {
      buffer.writeln('Source: ${log.source}');
    }
    if (log.lineNumber != null) {
      buffer.writeln('Ligne: ${log.lineNumber}');
    }
    if (log.stackTrace != null) {
      buffer.writeln('\nStack trace:');
      buffer.writeln(log.stackTrace);
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    // Afficher une notification futuriste
    if (mounted) {
      GxNotificationService().showSuccess(
        title: 'Message copié',
        message: 'Le contenu a été copié dans le presse-papiers',
        context: context,
        duration: const Duration(seconds: 2),
        icon: CupertinoIcons.doc_on_doc,
      );
    }
  }

  Widget _buildNetworkPanel(BuildContext context, DevToolsService service, Color gxRed) {
    final requests = service.networkRequests;
    
    // Auto-scroll vers le bas quand de nouvelles requêtes arrivent
    if (requests.isNotEmpty && _networkScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _networkScrollController.animateTo(
          _networkScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
    
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.wifi,
              size: 32,
              color: gxRed.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune requête réseau',
              style: TextStyle(
                color: gxRed.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Les requêtes apparaîtront ici',
              style: TextStyle(
                color: gxRed.withOpacity(0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black.withOpacity(0.2),
      child: ListView.builder(
        controller: _networkScrollController,
        padding: const EdgeInsets.all(8),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildNetworkRequestItem(request, gxRed);
        },
      ),
    );
  }

  Widget _buildNetworkRequestItem(NetworkRequest request, Color gxRed) {
    final method = request.method.name.toUpperCase();
    final url = request.url;
    final status = request.statusCode ?? 0;
    final duration = request.duration;
    
    Color statusColor;
    IconData statusIcon;
    if (status >= 200 && status < 300) {
      statusColor = Colors.green;
      statusIcon = CupertinoIcons.check_mark_circled;
    } else if (status >= 300 && status < 400) {
      statusColor = Colors.orange;
      statusIcon = CupertinoIcons.arrow_right_circle;
    } else if (status >= 400) {
      statusColor = Colors.red;
      statusIcon = CupertinoIcons.xmark_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = CupertinoIcons.clock;
    }

    // Extraire le domaine de l'URL pour affichage
    String displayUrl = url;
    try {
      final uri = Uri.parse(url);
      displayUrl = uri.host + uri.path;
      if (displayUrl.length > 50) {
        displayUrl = displayUrl.substring(0, 47) + '...';
      }
    } catch (_) {
      if (displayUrl.length > 50) {
        displayUrl = displayUrl.substring(0, 47) + '...';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
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
                  color: gxRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  method,
                  style: TextStyle(
                    color: gxRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayUrl,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (status > 0)
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toString(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (duration != null && duration > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.timer,
                    size: 8,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duration < 1000 
                        ? '${duration.round()}ms' 
                        : '${(duration / 1000).toStringAsFixed(2)}s',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 9,
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
