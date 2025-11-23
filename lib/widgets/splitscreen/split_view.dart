import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../models/tab_model.dart';
import '../../core/utils/theme_extensions.dart';
import '../../widgets/common/neon_button.dart';
import 'split_pane.dart';

enum SplitLayout { horizontal, vertical, grid }

class SplitView extends StatefulWidget {
  const SplitView({super.key});

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  SplitLayout _layout = SplitLayout.horizontal;
  final List<String?> _paneTabIds = [null, null];
  List<double> _paneSizes = [0.5, 0.5];
  bool _isResizing = false;
  int? _resizingIndex;

  @override
  Widget build(BuildContext context) {
    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        return Column(
          children: [
            // Control bar
            _buildControlBar(context, tabManager),
            
            // Split panes
            Expanded(
              child: _buildSplitPanes(context, tabManager),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlBar(BuildContext context, TabManager tabManager) {
    final theme = Theme.of(context);
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
                color: context.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Layout selector
          NeonButton(
            text: _layout == SplitLayout.horizontal ? '⥀' : '⥁',
            variant: NeonButtonVariant.primary,
            onPressed: () {
              setState(() {
                _layout = _layout == SplitLayout.horizontal
                    ? SplitLayout.vertical
                    : SplitLayout.horizontal;
              });
            },
            width: 32,
            height: 32,
            padding: EdgeInsets.zero,
          ),
          
          const SizedBox(width: 8),
          
          // Add pane button
          NeonButton(
            text: '+',
            variant: NeonButtonVariant.accent,
            onPressed: () {
              setState(() {
                _paneTabIds.add(null);
                _paneSizes = List.generate(
                  _paneTabIds.length,
                  (index) => 1.0 / _paneTabIds.length,
                );
              });
            },
            width: 32,
            height: 32,
            padding: EdgeInsets.zero,
          ),
          
          const SizedBox(width: 8),
          
          // Tab selector for each pane
          ...List.generate(_paneTabIds.length, (index) {
            final tabId = _paneTabIds[index];
            final tab = tabId != null
                ? tabManager.tabs.firstWhere(
                    (t) => t.id == tabId,
                    orElse: () => TabModel(),
                  )
                : null;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showTabSelector(context, tabManager, index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tab != null
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: tab != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.border ?? Colors.grey.shade800,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab != null && tab.favicon != null)
                        Image.network(
                          tab.favicon!,
                          width: 16,
                          height: 16,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        )
                      else
                        Icon(
                          Icons.language,
                          size: 16,
                          color: context.textSecondaryColor,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        tab?.title ?? tab?.url ?? 'Panneau ${index + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tab != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSplitPanes(BuildContext context, TabManager tabManager) {
    if (_paneTabIds.length == 1) {
      final tab = _paneTabIds[0] != null
          ? tabManager.tabs.firstWhere(
              (t) => t.id == _paneTabIds[0],
              orElse: () => TabModel(),
            )
          : null;
      
      return SplitPane(
        tab: tab,
        onClose: () {
          setState(() {
            _paneTabIds.clear();
            _paneTabIds.add(null);
          });
        },
      );
    }

    if (_layout == SplitLayout.horizontal) {
      return Row(
        children: _buildHorizontalPanes(context, tabManager),
      );
    } else {
      return Column(
        children: _buildVerticalPanes(context, tabManager),
      );
    }
  }

  List<Widget> _buildHorizontalPanes(
      BuildContext context, TabManager tabManager) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panes = <Widget>[];
    
    for (int i = 0; i < _paneTabIds.length; i++) {
      final tab = _paneTabIds[i] != null
          ? tabManager.tabs.firstWhere(
              (t) => t.id == _paneTabIds[i],
              orElse: () => TabModel(),
            )
          : null;
      
      panes.add(
        Expanded(
          flex: (_paneSizes[i] * 100).round(),
          child: SplitPane(
            tab: tab,
            onClose: i > 0
                ? () {
                    setState(() {
                      final removedSize = _paneSizes[i];
                      _paneTabIds.removeAt(i);
                      _paneSizes.removeAt(i);
                      // Redistribute sizes
                      for (int j = 0; j < _paneSizes.length; j++) {
                        _paneSizes[j] += removedSize / _paneSizes.length;
                      }
                    });
                  }
                : null,
            onSwap: i > 0
                ? () {
                    setState(() {
                      final temp = _paneTabIds[i];
                      _paneTabIds[i] = _paneTabIds[i - 1];
                      _paneTabIds[i - 1] = temp;
                    });
                  }
                : null,
          ),
        ),
      );
      
      // Resizer
      if (i < _paneTabIds.length - 1) {
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
                setState(() {
                  final delta = details.delta.dx / screenWidth;
                  if (_paneSizes[_resizingIndex!] + delta > 0.1 &&
                      _paneSizes[_resizingIndex! + 1] - delta > 0.1) {
                    _paneSizes[_resizingIndex!] += delta;
                    _paneSizes[_resizingIndex! + 1] -= delta;
                  }
                });
              }
            },
            onPanEnd: (_) {
              setState(() {
                _isResizing = false;
                _resizingIndex = null;
              });
            },
            child: Container(
              width: 4,
              color: _isResizing && _resizingIndex == i
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.border,
            ),
          ),
        );
      }
    }
    
    return panes;
  }

  List<Widget> _buildVerticalPanes(
      BuildContext context, TabManager tabManager) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panes = <Widget>[];
    
    for (int i = 0; i < _paneTabIds.length; i++) {
      final tab = _paneTabIds[i] != null
          ? tabManager.tabs.firstWhere(
              (t) => t.id == _paneTabIds[i],
              orElse: () => TabModel(),
            )
          : null;
      
      panes.add(
        Expanded(
          flex: (_paneSizes[i] * 100).round(),
          child: SplitPane(
            tab: tab,
            onClose: i > 0
                ? () {
                    setState(() {
                      final removedSize = _paneSizes[i];
                      _paneTabIds.removeAt(i);
                      _paneSizes.removeAt(i);
                      // Redistribute sizes
                      for (int j = 0; j < _paneSizes.length; j++) {
                        _paneSizes[j] += removedSize / _paneSizes.length;
                      }
                    });
                  }
                : null,
            onSwap: i > 0
                ? () {
                    setState(() {
                      final temp = _paneTabIds[i];
                      _paneTabIds[i] = _paneTabIds[i - 1];
                      _paneTabIds[i - 1] = temp;
                    });
                  }
                : null,
          ),
        ),
      );
      
      // Resizer
      if (i < _paneTabIds.length - 1) {
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
                setState(() {
                  final delta = details.delta.dy / screenHeight;
                  if (_paneSizes[_resizingIndex!] + delta > 0.1 &&
                      _paneSizes[_resizingIndex! + 1] - delta > 0.1) {
                    _paneSizes[_resizingIndex!] += delta;
                    _paneSizes[_resizingIndex! + 1] -= delta;
                  }
                });
              }
            },
            onPanEnd: (_) {
              setState(() {
                _isResizing = false;
                _resizingIndex = null;
              });
            },
            child: Container(
              height: 4,
              color: _isResizing && _resizingIndex == i
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.border,
            ),
          ),
        );
      }
    }
    
    return panes;
  }

  void _showTabSelector(
      BuildContext context, TabManager tabManager, int paneIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Sélectionner un onglet pour le panneau ${paneIndex + 1}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tabManager.tabs.length,
            itemBuilder: (context, index) {
              final tab = tabManager.tabs[index];
              return ListTile(
                leading: tab.favicon != null
                    ? Image.network(
                        tab.favicon!,
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(Icons.language),
                      )
                    : const Icon(Icons.language),
                title: Text(tab.title ?? tab.url ?? 'Onglet'),
                onTap: () {
                  setState(() {
                    _paneTabIds[paneIndex] = tab.id;
                  });
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

