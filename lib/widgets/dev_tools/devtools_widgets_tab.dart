import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/notilus_devtools_service.dart';
import '../../models/devtools_models.dart';

/// Onglet Widget Tree Inspector
class DevToolsWidgetsTab extends StatefulWidget {
  const DevToolsWidgetsTab({super.key});

  @override
  State<DevToolsWidgetsTab> createState() => _DevToolsWidgetsTabState();
}

class _DevToolsWidgetsTabState extends State<DevToolsWidgetsTab> {
  WidgetTreeNode? _selectedNode;
  final Set<String> _expandedNodes = {};

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<NotilusDevToolsService>(
      builder: (context, devTools, _) {
        final tree = devTools.widgetTree;

        return Column(
          children: [
            // Toolbar
            _buildToolbar(context, accentColor, devTools, tree),

            // Content
            Expanded(
              child: Row(
                children: [
                  // Tree view
                  Expanded(
                    flex: 2,
                    child: tree.isEmpty
                        ? _buildEmptyState(accentColor, devTools)
                        : _buildTreeView(tree, accentColor),
                  ),
                  
                  // Properties panel
                  if (_selectedNode != null)
                    Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        border: Border(
                          left: BorderSide(
                            color: accentColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: _buildPropertiesPanel(_selectedNode!, accentColor),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, Color accentColor, NotilusDevToolsService devTools, List<WidgetTreeNode> tree) {
    int totalWidgets = 0;
    void count(List<WidgetTreeNode> nodes) {
      for (final node in nodes) {
        totalWidgets++;
        count(node.children);
      }
    }
    count(tree);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Capture button
          GestureDetector(
            onTap: () {
              devTools.captureWidgetTree();
              setState(() {
                _expandedNodes.clear();
                _selectedNode = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.camera,
                    size: 12,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Capturer',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$totalWidgets widgets',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),

          const Spacer(),

          // Expand/Collapse all
          GestureDetector(
            onTap: () {
              setState(() {
                if (_expandedNodes.isEmpty) {
                  // Expand first level
                  for (final node in tree) {
                    _expandedNodes.add(node.id);
                  }
                } else {
                  _expandedNodes.clear();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _expandedNodes.isEmpty
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.chevron_up,
                    size: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expandedNodes.isEmpty ? 'Expand' : 'Collapse',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor, NotilusDevToolsService devTools) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.rectangle_3_offgrid,
            size: 48,
            color: accentColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Widget Tree Inspector',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capturez l\'arbre des widgets Flutter\npour inspecter la hiérarchie',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => devTools.captureWidgetTree(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.camera, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Capturer maintenant',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeView(List<WidgetTreeNode> tree, Color accentColor) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: tree.map((node) => _buildTreeNode(node, accentColor)).toList(),
    );
  }

  Widget _buildTreeNode(WidgetTreeNode node, Color accentColor) {
    final isExpanded = _expandedNodes.contains(node.id);
    final isSelected = _selectedNode?.id == node.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedNode = node;
              if (node.hasChildren) {
                if (isExpanded) {
                  _expandedNodes.remove(node.id);
                } else {
                  _expandedNodes.add(node.id);
                }
              }
            });
          },
          child: Container(
            margin: EdgeInsets.only(left: node.depth * 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(color: accentColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expand/collapse icon
                if (node.hasChildren)
                  Icon(
                    isExpanded
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.chevron_right,
                    size: 12,
                    color: Colors.white.withOpacity(0.5),
                  )
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
                
                // Widget type icon
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: node.typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      node.widgetType[0],
                      style: TextStyle(
                        color: node.typeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                
                // Widget name
                Flexible(
                  child: Text(
                    node.displayName,
                    style: TextStyle(
                      color: isSelected ? accentColor : node.typeColor,
                      fontSize: 11,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Children count
                if (node.hasChildren)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${node.children.length}',
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
        
        // Children
        if (isExpanded && node.children.isNotEmpty)
          ...node.children.map((child) => _buildTreeNode(child, accentColor)),
      ],
    );
  }

  Widget _buildPropertiesPanel(WidgetTreeNode node, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: node.typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    node.widgetType[0],
                    style: TextStyle(
                      color: node.typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.widgetType,
                      style: TextStyle(
                        color: node.typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    Text(
                      'Depth: ${node.depth}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Properties
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildPropertyItem('ID', node.id, accentColor),
              if (node.key != null)
                _buildPropertyItem('Key', node.key!, accentColor),
              _buildPropertyItem('Children', '${node.children.length}', accentColor),
              if (node.renderBounds != null) ...[
                _buildPropertyItem('X', node.renderBounds!.left.toStringAsFixed(1), accentColor),
                _buildPropertyItem('Y', node.renderBounds!.top.toStringAsFixed(1), accentColor),
                _buildPropertyItem('Width', node.renderBounds!.width.toStringAsFixed(1), accentColor),
                _buildPropertyItem('Height', node.renderBounds!.height.toStringAsFixed(1), accentColor),
              ],
              ...node.properties.entries.map((e) => _buildPropertyItem(e.key, e.value, accentColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyItem(String label, String value, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

