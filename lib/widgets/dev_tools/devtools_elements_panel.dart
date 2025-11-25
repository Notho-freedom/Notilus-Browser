/// Panneau Elements du DevTools natif Notilus - Inspection DOM
library devtools_elements_panel;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/devtools_models.dart';
import '../../services/devtools_service.dart';
import '../../core/constants/notilus_colors.dart';

class DevToolsElementsPanel extends StatefulWidget {
  const DevToolsElementsPanel({super.key});

  @override
  State<DevToolsElementsPanel> createState() => _DevToolsElementsPanelState();
}

class _DevToolsElementsPanelState extends State<DevToolsElementsPanel> {
  final Set<String> _expandedNodes = {};
  DOMNode? _selectedNode;
  Map<String, dynamic>? _selectedNodeDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDOMTree();
  }

  Future<void> _loadDOMTree() async {
    setState(() => _isLoading = true);
    
    final devTools = context.read<DevToolsService>();
    await devTools.fetchDOMTree();
    
    setState(() => _isLoading = false);
  }

  void _toggleNode(DOMNode node) {
    setState(() {
      if (_expandedNodes.contains(node.id)) {
        _expandedNodes.remove(node.id);
      } else {
        _expandedNodes.add(node.id);
      }
    });
  }

  Future<void> _selectNode(DOMNode node) async {
    setState(() {
      _selectedNode = node;
      _selectedNodeDetails = null;
    });

    // Construire le sélecteur
    String selector = node.tagName;
    if (node.attributes['id']?.isNotEmpty == true) {
      selector = '#${node.attributes['id']}';
    } else if (node.attributes['class']?.isNotEmpty == true) {
      selector = '${node.tagName}.${node.attributes['class']!.split(' ').first}';
    }

    // Récupérer les détails
    final devTools = context.read<DevToolsService>();
    final details = await devTools.inspectElement(selector);
    
    if (details != null && mounted) {
      setState(() {
        _selectedNodeDetails = details;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        return Container(
          color: const Color(0xFF0D0D12),
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(),

              // Contenu principal
              Expanded(
                child: Row(
                  children: [
                    // Arbre DOM
                    Expanded(
                      flex: 3,
                      child: _isLoading
                          ? _buildLoadingState()
                          : devTools.domTree == null
                              ? _buildEmptyState()
                              : _buildDOMTree(devTools.domTree!),
                    ),

                    // Panneau de détails
                    if (_selectedNode != null) ...[
                      Container(
                        width: 1,
                        color: NotilusColors.neonRed.withOpacity(0.2),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildDetailsPanel(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          _ToolbarButton(
            icon: Icons.refresh,
            tooltip: 'Actualiser l\'arbre DOM',
            onPressed: _loadDOMTree,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.unfold_more,
            tooltip: 'Tout développer',
            onPressed: () {
              final devTools = context.read<DevToolsService>();
              if (devTools.domTree != null) {
                _expandAllNodes(devTools.domTree!);
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.unfold_less,
            tooltip: 'Tout réduire',
            onPressed: () {
              setState(() {
                _expandedNodes.clear();
              });
            },
          ),
          const Spacer(),
          Text(
            'Inspecteur DOM',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _expandAllNodes(DOMNode node) {
    setState(() {
      _expandedNodes.add(node.id);
      for (final child in node.children) {
        _expandAllNodes(child);
      }
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: NotilusColors.neonRed,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement du DOM...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.code_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun DOM chargé',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadDOMTree,
            icon: Icon(
              Icons.refresh,
              size: 16,
              color: NotilusColors.neonRed,
            ),
            label: Text(
              'Charger le DOM',
              style: TextStyle(
                color: NotilusColors.neonRed,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDOMTree(DOMNode root) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildDOMNode(root),
      ],
    );
  }

  Widget _buildDOMNode(DOMNode node) {
    final isExpanded = _expandedNodes.contains(node.id);
    final isSelected = _selectedNode?.id == node.id;
    final hasChildren = node.hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne du noeud
        Material(
          color: isSelected
              ? NotilusColors.neonRed.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _selectNode(node),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.only(
                left: node.depth * 16.0,
                right: 8,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  // Icône expand/collapse
                  if (hasChildren)
                    GestureDetector(
                      onTap: () => _toggleNode(node),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    )
                  else
                    const SizedBox(width: 16),

                  // Tag d'ouverture
                  _buildTag(node, isOpening: true),

                  // Texte inline si présent et pas d'enfants
                  if (node.hasText && !hasChildren) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        node.textContent!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildTag(node, isOpening: false),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Enfants
        if (hasChildren && isExpanded) ...[
          ...node.children.map((child) => _buildDOMNode(child)),
          // Tag de fermeture
          Padding(
            padding: EdgeInsets.only(
              left: node.depth * 16.0 + 16,
              top: 4,
              bottom: 4,
            ),
            child: _buildTag(node, isOpening: false),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(DOMNode node, {required bool isOpening}) {
    final List<InlineSpan> spans = [];

    if (isOpening) {
      spans.add(TextSpan(
        text: '<',
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ));
      spans.add(TextSpan(
        text: node.tagName,
        style: TextStyle(color: _getTagColor(node.tagName)),
      ));

      // Attributs
      node.attributes.forEach((key, value) {
        spans.add(TextSpan(
          text: ' $key',
          style: const TextStyle(color: Color(0xFF9CDCFE)),
        ));
        spans.add(TextSpan(
          text: '=',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ));
        spans.add(TextSpan(
          text: '"$value"',
          style: const TextStyle(color: Color(0xFFCE9178)),
        ));
      });

      spans.add(TextSpan(
        text: node.hasChildren || node.hasText ? '>' : ' />',
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ));
    } else {
      spans.add(TextSpan(
        text: '</',
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ));
      spans.add(TextSpan(
        text: node.tagName,
        style: TextStyle(color: _getTagColor(node.tagName)),
      ));
      spans.add(TextSpan(
        text: '>',
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'JetBrains Mono',
        ),
        children: spans,
      ),
    );
  }

  Color _getTagColor(String tagName) {
    switch (tagName.toLowerCase()) {
      case 'html':
      case 'head':
      case 'body':
        return const Color(0xFF569CD6);
      case 'div':
      case 'span':
      case 'p':
        return const Color(0xFF4EC9B0);
      case 'a':
      case 'link':
        return const Color(0xFFDCDCAA);
      case 'script':
      case 'style':
        return const Color(0xFFC586C0);
      case 'img':
      case 'video':
      case 'audio':
        return const Color(0xFFFFB86C);
      case 'input':
      case 'button':
      case 'form':
        return const Color(0xFF50FA7B);
      default:
        return const Color(0xFF4FC1FF);
    }
  }

  Widget _buildDetailsPanel() {
    return Container(
      color: const Color(0xFF0D0D12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                Text(
                  'Élément',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NotilusColors.neonRed,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: () {
                    setState(() {
                      _selectedNode = null;
                      _selectedNodeDetails = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Tag info
                _DetailSection(
                  title: 'Tag',
                  child: _buildTag(_selectedNode!, isOpening: true),
                ),

                const SizedBox(height: 16),

                // Attributs
                if (_selectedNode!.attributes.isNotEmpty)
                  _DetailSection(
                    title: 'Attributs',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _selectedNode!.attributes.entries
                          .map((e) => _AttributeRow(
                                name: e.key,
                                value: e.value,
                              ))
                          .toList(),
                    ),
                  ),

                // Styles (si disponibles)
                if (_selectedNodeDetails != null &&
                    _selectedNodeDetails!['styles'] != null) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Styles calculés',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (_selectedNodeDetails!['styles']
                              as Map<String, dynamic>)
                          .entries
                          .map((e) => _StyleRow(
                                property: e.key,
                                value: e.value.toString(),
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // Box model (si disponible)
                if (_selectedNodeDetails != null &&
                    _selectedNodeDetails!['rect'] != null) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Box Model',
                    child: _BoxModelView(
                      rect: _selectedNodeDetails!['rect'] as Map<String, dynamic>,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
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
            padding: const EdgeInsets.all(6),
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

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String name;
  final String value;

  const _AttributeRow({
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CDCFE),
              fontFamily: 'JetBrains Mono',
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFCE9178),
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  final String property;
  final String value;

  const _StyleRow({
    required this.property,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CDCFE),
              fontFamily: 'JetBrains Mono',
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxModelView extends StatelessWidget {
  final Map<String, dynamic> rect;

  const _BoxModelView({required this.rect});

  @override
  Widget build(BuildContext context) {
    final width = (rect['width'] as num?)?.toDouble() ?? 0;
    final height = (rect['height'] as num?)?.toDouble() ?? 0;
    final x = (rect['x'] as num?)?.toDouble() ?? 0;
    final y = (rect['y'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Dimensions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BoxValue(label: 'W', value: width.toStringAsFixed(0)),
              const SizedBox(width: 24),
              _BoxValue(label: 'H', value: height.toStringAsFixed(0)),
            ],
          ),
          const SizedBox(height: 12),
          // Position
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BoxValue(label: 'X', value: x.toStringAsFixed(0)),
              const SizedBox(width: 24),
              _BoxValue(label: 'Y', value: y.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoxValue extends StatelessWidget {
  final String label;
  final String value;

  const _BoxValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: NotilusColors.neonRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${value}px',
            style: TextStyle(
              fontSize: 11,
              color: NotilusColors.neonRed,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
