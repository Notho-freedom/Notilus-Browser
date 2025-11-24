import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tab_manager.dart';
import '../../services/split_screen_service.dart';
import '../../services/tab_webview_manager.dart';
import '../../models/tab_model.dart';
import '../../core/constants/notilus_colors.dart';
import 'advanced_split_pane.dart';
import '../../widgets/browser/web_content_view.dart';

/// Vue split-screen avancée avec support drag-and-drop complet
class AdvancedSplitView extends StatefulWidget {
  const AdvancedSplitView({super.key});

  @override
  State<AdvancedSplitView> createState() => _AdvancedSplitViewState();
}

class _AdvancedSplitViewState extends State<AdvancedSplitView> {
  int? _resizingIndex;
  bool _isResizing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SplitScreenService, TabManager>(
      builder: (context, splitService, tabManager, _) {
        if (!splitService.isActive) {
          return const SizedBox.shrink();
        }
        
        if (!splitService.isVisible) {
          return const SizedBox.shrink();
        }

        return Container(
          color: const Color(0xFF0B0B0E),
          child: Column(
            children: [
              // Barre de contrôle
              _buildControlBar(context, splitService, tabManager),
              
              // Panneaux split
              Expanded(
                child: _buildSplitPanes(context, splitService, tabManager),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlBar(
    BuildContext context,
    SplitScreenService splitService,
    TabManager tabManager,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: NotilusColors.chrome,
        border: Border(
          bottom: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu des layouts prédéfinis
          _LayoutPresetMenu(
            currentLayout: splitService.layout,
            onPresetSelected: (presetId) {
              splitService.applyLayoutPreset(presetId);
              HapticFeedback.selectionClick();
            },
          ),
          
          const SizedBox(width: 8),
          
          // Toggle layout
          _ControlButton(
            icon: splitService.layout == SplitLayout.horizontal
                ? CupertinoIcons.arrow_left_right
                : CupertinoIcons.arrow_up_down,
            tooltip: 'Changer la disposition',
            onPressed: () {
              splitService.setLayout(
                splitService.layout == SplitLayout.horizontal
                    ? SplitLayout.vertical
                    : SplitLayout.horizontal,
              );
              HapticFeedback.selectionClick();
            },
          ),
          
          const SizedBox(width: 8),
          
          // Ajouter un panneau
          _ControlButton(
            icon: CupertinoIcons.add,
            tooltip: 'Ajouter un panneau',
            onPressed: () {
              splitService.addPane();
              HapticFeedback.mediumImpact();
            },
          ),
          
          const SizedBox(width: 8),
          
          // Sélecteurs d'onglets pour chaque panneau
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: splitService.panes.length,
              itemBuilder: (context, index) {
                final pane = splitService.panes[index];
                final tab = pane.tabId != null
                    ? tabManager.tabs.firstWhere(
                        (t) => t.id == pane.tabId,
                        orElse: () => TabModel(),
                      )
                    : null;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PaneTabSelector(
                    index: index,
                    tab: tab,
                    onTabSelected: (tabId) {
                      splitService.setPaneTab(index, tabId);
                    },
                    onClose: splitService.panes.length > 1
                        ? () => splitService.removePane(index)
                        : null,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Masquer split-screen (revenir aux tabs)
          _ControlButton(
            icon: CupertinoIcons.eye_slash,
            tooltip: 'Masquer le split-screen et revenir aux onglets',
            onPressed: () {
              splitService.setVisible(false);
              HapticFeedback.lightImpact();
            },
          ),
          
          const SizedBox(width: 8),
          
          // Fermer split-screen complètement
          _ControlButton(
            icon: CupertinoIcons.xmark,
            tooltip: 'Fermer complètement le split-screen',
            onPressed: () {
              splitService.toggle();
              HapticFeedback.mediumImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPanes(
    BuildContext context,
    SplitScreenService splitService,
    TabManager tabManager,
  ) {
    if (splitService.panes.isEmpty) {
      return const Center(
        child: Text(
          'Aucun panneau',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    if (splitService.layout == SplitLayout.horizontal) {
      return _buildHorizontalPanes(context, splitService, tabManager);
    } else {
      return _buildVerticalPanes(context, splitService, tabManager);
    }
  }

  Widget _buildHorizontalPanes(
    BuildContext context,
    SplitScreenService splitService,
    TabManager tabManager,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panes = <Widget>[];

    for (int i = 0; i < splitService.panes.length; i++) {
      final pane = splitService.panes[i];
      final tab = pane.tabId != null
          ? tabManager.tabs.firstWhere(
              (t) => t.id == pane.tabId,
              orElse: () => TabModel(),
            )
          : null;

      panes.add(
        Expanded(
          flex: (pane.size * 1000).round(),
          child: AdvancedSplitPane(
            paneIndex: i,
            tab: tab,
            onTabDropped: (droppedTab) {
              splitService.setPaneTab(i, droppedTab.id, tabManager: tabManager);
              HapticFeedback.mediumImpact();
            },
            onClose: splitService.panes.length > 1
                ? () => splitService.removePane(i)
                : null,
            onSwap: i > 0
                ? () => splitService.swapPanes(i, i - 1)
                : null,
          ),
        ),
      );

      // Resizer
      if (i < splitService.panes.length - 1) {
        panes.add(
          GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isResizing = true;
                _resizingIndex = i;
              });
            },
            onPanUpdate: (details) {
              if (_isResizing && _resizingIndex != null) {
                final delta = details.delta.dx / screenWidth;
                splitService.resizePanes(_resizingIndex!, delta);
              }
            },
            onPanEnd: (_) {
              setState(() {
                _isResizing = false;
                _resizingIndex = null;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _isResizing && _resizingIndex == i
                      ? NotilusColors.neonRed.withOpacity(0.8)
                      : NotilusColors.neonRed.withOpacity(0.2),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: NotilusColors.neonRed.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Row(children: panes);
  }

  Widget _buildVerticalPanes(
    BuildContext context,
    SplitScreenService splitService,
    TabManager tabManager,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panes = <Widget>[];

    for (int i = 0; i < splitService.panes.length; i++) {
      final pane = splitService.panes[i];
      final tab = pane.tabId != null
          ? tabManager.tabs.firstWhere(
              (t) => t.id == pane.tabId,
              orElse: () => TabModel(),
            )
          : null;

      panes.add(
        Expanded(
          flex: (pane.size * 1000).round(),
          child: AdvancedSplitPane(
            paneIndex: i,
            tab: tab,
            onTabDropped: (droppedTab) {
              splitService.setPaneTab(i, droppedTab.id, tabManager: tabManager);
              HapticFeedback.mediumImpact();
            },
            onClose: splitService.panes.length > 1
                ? () => splitService.removePane(i)
                : null,
            onSwap: i > 0
                ? () => splitService.swapPanes(i, i - 1)
                : null,
          ),
        ),
      );

      // Resizer
      if (i < splitService.panes.length - 1) {
        panes.add(
          GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isResizing = true;
                _resizingIndex = i;
              });
            },
            onPanUpdate: (details) {
              if (_isResizing && _resizingIndex != null) {
                final delta = details.delta.dy / screenHeight;
                splitService.resizePanes(_resizingIndex!, delta);
              }
            },
            onPanEnd: (_) {
              setState(() {
                _isResizing = false;
                _resizingIndex = null;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _isResizing && _resizingIndex == i
                      ? NotilusColors.neonRed.withOpacity(0.8)
                      : NotilusColors.neonRed.withOpacity(0.2),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: NotilusColors.neonRed.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(children: panes);
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isPressed
                ? NotilusColors.neonRed.withOpacity(0.2)
                : (_isHovered
                    ? NotilusColors.neonRed.withOpacity(0.12)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
            border: _isHovered
                ? Border.all(
                    color: NotilusColors.neonRed.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: NotilusColors.neonRed.withOpacity(
              _isPressed ? 1.0 : (_isHovered ? 0.9 : 0.7),
            ),
          ),
        )
            .animate(target: _isHovered ? 1 : 0)
            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 150.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _PaneTabSelector extends StatelessWidget {
  final int index;
  final TabModel? tab;
  final Function(String?) onTabSelected;
  final VoidCallback? onClose;

  const _PaneTabSelector({
    required this.index,
    this.tab,
    required this.onTabSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTabSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tab != null
              ? NotilusColors.neonRed.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: tab != null
                ? NotilusColors.neonRed.withOpacity(0.5)
                : NotilusColors.neonRed.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab != null && tab!.favicon != null)
              Image.network(
                tab!.favicon!,
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => const SizedBox(),
              )
            else
              Icon(
                CupertinoIcons.globe,
                size: 16,
                color: NotilusColors.neonRed.withOpacity(0.7),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tab?.title ?? tab?.url ?? 'Panneau ${index + 1}',
                style: TextStyle(
                  color: tab != null
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 14,
                  color: NotilusColors.neonRed.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTabSelector(BuildContext context) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15151A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.6),
            width: 1,
          ),
        ),
        title: Text(
          'Sélectionner un onglet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tabManager.tabs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: Icon(
                    CupertinoIcons.square,
                    color: NotilusColors.neonRed,
                  ),
                  title: Text(
                    'Vider le panneau',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    onTabSelected(null);
                    Navigator.of(context).pop();
                  },
                );
              }
              
              final tab = tabManager.tabs[index - 1];
              return ListTile(
                leading: tab.favicon != null
                    ? Image.network(
                        tab.favicon!,
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => Icon(
                          CupertinoIcons.globe,
                          color: NotilusColors.neonRed,
                        ),
                      )
                    : Icon(
                        CupertinoIcons.globe,
                        color: NotilusColors.neonRed,
                      ),
                title: Text(
                  tab.title ?? tab.url ?? 'Onglet',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: tab.url != null
                    ? Text(
                        tab.url!,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () {
                  onTabSelected(tab.id);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LayoutPresetMenu extends StatefulWidget {
  final SplitLayout currentLayout;
  final Function(String) onPresetSelected;

  const _LayoutPresetMenu({
    required this.currentLayout,
    required this.onPresetSelected,
  });

  @override
  State<_LayoutPresetMenu> createState() => _LayoutPresetMenuState();
}

class _LayoutPresetMenuState extends State<_LayoutPresetMenu> {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _isMenuOpen = !_isMenuOpen),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isHovered || _isMenuOpen
                    ? NotilusColors.neonRed.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: NotilusColors.neonRed.withOpacity(
                    _isHovered || _isMenuOpen ? 0.5 : 0.2,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.square_grid_2x2,
                    size: 16,
                    color: NotilusColors.neonRed.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Layouts',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isMenuOpen
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 12,
                    color: NotilusColors.neonRed.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            // Menu déroulant
            if (_isMenuOpen)
              Positioned(
                top: 40,
                left: 0,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NotilusColors.neonRed.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: SplitScreenService.availablePresets.map((preset) {
                      return InkWell(
                        onTap: () {
                          widget.onPresetSelected(preset['id']!);
                          setState(() => _isMenuOpen = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Text(
                                preset['icon']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  preset['name']!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: -0.1, end: 0, duration: 200.ms, curve: Curves.easeOutCubic),
              ),
          ],
        ),
      ),
    );
  }
}

