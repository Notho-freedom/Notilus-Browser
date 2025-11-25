/// Panneau Elements du DevTools natif Notilus - Éditeur DOM style VSCode
/// - Arborescence en sidebar style explorateur de fichiers
/// - Édition live des attributs et styles
/// - Utilise la couleur secondaire du thème
library devtools_elements_panel;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/devtools_models.dart';
import '../../services/devtools_service.dart';
import '../../core/services/color_theme_manager.dart';

class DevToolsElementsPanel extends StatefulWidget {
  const DevToolsElementsPanel({super.key});

  @override
  State<DevToolsElementsPanel> createState() => _DevToolsElementsPanelState();
}

class _DevToolsElementsPanelState extends State<DevToolsElementsPanel>
    with SingleTickerProviderStateMixin {
  final Set<String> _expandedNodes = {};
  DOMNode? _selectedNode;
  Map<String, dynamic>? _selectedNodeDetails;
  bool _isLoading = false;
  
  // Sidebar ressources
  bool _showResources = true;
  List<_PageResource> _resources = [];
  _ResourceType? _selectedResourceType;
  
  // Éditeur CSS
  final TextEditingController _cssEditorController = TextEditingController();
  bool _cssEditorExpanded = true;
  
  // Onglet details
  late TabController _detailsTabController;
  
  @override
  void initState() {
    super.initState();
    _detailsTabController = TabController(length: 3, vsync: this);
    _loadDOMTree();
    _loadResources();
  }

  @override
  void dispose() {
    _cssEditorController.dispose();
    _detailsTabController.dispose();
    super.dispose();
  }

  Future<void> _loadDOMTree() async {
    setState(() => _isLoading = true);
    final devTools = context.read<DevToolsService>();
    await devTools.fetchDOMTree();
    setState(() => _isLoading = false);
  }

  Future<void> _loadResources() async {
    final devTools = context.read<DevToolsService>();
    try {
      final result = await devTools.executeScript('''
        (function() {
          const resources = [];
          document.querySelectorAll('img').forEach(img => {
            resources.push({ type: 'image', url: img.src, name: img.src.split('/').pop() || 'image' });
          });
          document.querySelectorAll('script[src]').forEach(s => {
            resources.push({ type: 'script', url: s.src, name: s.src.split('/').pop() || 'script.js' });
          });
          document.querySelectorAll('link[rel="stylesheet"]').forEach(l => {
            resources.push({ type: 'stylesheet', url: l.href, name: l.href.split('/').pop() || 'style.css' });
          });
          return JSON.stringify(resources);
        })();
      ''');
      
      if (result != null && mounted) {
        final List<dynamic> resourceList = jsonDecode(result);
        setState(() {
          _resources = resourceList.map((r) => _PageResource(
            type: _ResourceType.values.firstWhere((t) => t.name == r['type'], orElse: () => _ResourceType.other),
            url: r['url'] ?? '',
            name: r['name'] ?? 'Unknown',
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading resources: $e');
    }
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

    String selector = node.tagName;
    if (node.attributes['id']?.isNotEmpty == true) {
      selector = '#${node.attributes['id']}';
    } else if (node.attributes['class']?.isNotEmpty == true) {
      selector = '${node.tagName}.${node.attributes['class']!.split(' ').first}';
    }

    final devTools = context.read<DevToolsService>();
    final details = await devTools.inspectElement(selector);
    
    if (details != null && mounted) {
      setState(() {
        _selectedNodeDetails = details;
        if (details['styles'] != null) {
          final styles = details['styles'] as Map<String, dynamic>;
          final cssText = styles.entries.map((e) => '${e.key}: ${e.value};').join('\n');
          _cssEditorController.text = cssText;
        }
      });
    }
  }

  Future<void> _applyCssChanges(Color accentColor) async {
    if (_selectedNode == null) return;
    
    final devTools = context.read<DevToolsService>();
    String selector = _selectedNode!.tagName;
    if (_selectedNode!.attributes['id']?.isNotEmpty == true) {
      selector = '#${_selectedNode!.attributes['id']}';
    }
    
    final cssText = _cssEditorController.text;
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) { el.style.cssText = `$cssText`; }
      })();
    ''');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Styles appliqués'),
          backgroundColor: accentColor,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _exportAsHtml(Color accentColor) async {
    final devTools = context.read<DevToolsService>();
    final html = await devTools.executeScript('document.documentElement.outerHTML');
    if (html != null) {
      await Clipboard.setData(ClipboardData(text: html));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('📋 HTML copié'), backgroundColor: accentColor),
        );
      }
    }
  }

  Future<void> _exportAsPdf() async {
    final devTools = context.read<DevToolsService>();
    await devTools.executeScript('window.print()');
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        return Container(
          color: const Color(0xFF1E1E1E), // VSCode dark background
          child: Row(
            children: [
              // === SIDEBAR GAUCHE: Ressources style VSCode ===
              if (_showResources)
                _VSCodeSidebar(
                  resources: _resources,
                  selectedType: _selectedResourceType,
                  accentColor: accentColor,
                  onTypeSelected: (type) => setState(() => _selectedResourceType = type),
                  onResourceTap: (r) => Clipboard.setData(ClipboardData(text: r.url)),
                ),
              
              // === ZONE PRINCIPALE: Arbre DOM ===
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildToolbar(accentColor),
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingState()
                          : devTools.domTree == null
                              ? _buildEmptyState(accentColor)
                              : _buildDOMTree(devTools.domTree!, accentColor),
                    ),
                  ],
                ),
              ),

              // === PANNEAU DROITE: Styles/Attributs ===
              if (_selectedNode != null)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252526), // VSCode sidebar
                    border: Border(left: BorderSide(color: accentColor.withOpacity(0.2))),
                  ),
                  child: _buildStylesPanel(accentColor),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(Color accentColor) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.folder_open,
            tooltip: 'Ressources',
            isActive: _showResources,
            accentColor: accentColor,
            onPressed: () => setState(() => _showResources = !_showResources),
          ),
          _ToolbarButton(
            icon: Icons.refresh,
            tooltip: 'Actualiser',
            accentColor: accentColor,
            onPressed: () { _loadDOMTree(); _loadResources(); },
          ),
          _ToolbarButton(
            icon: Icons.unfold_more,
            tooltip: 'Tout développer',
            accentColor: accentColor,
            onPressed: () {
              final devTools = context.read<DevToolsService>();
              if (devTools.domTree != null) _expandAllNodes(devTools.domTree!);
            },
          ),
          _ToolbarButton(
            icon: Icons.unfold_less,
            tooltip: 'Tout réduire',
            accentColor: accentColor,
            onPressed: () => setState(() => _expandedNodes.clear()),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Exporter',
            icon: Icon(Icons.download, size: 14, color: Colors.white.withOpacity(0.6)),
            color: const Color(0xFF2D2D30),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'html',
                child: Row(children: [
                  Icon(Icons.code, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  const Text('Copier HTML', style: TextStyle(color: Colors.white, fontSize: 11)),
                ]),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(children: [
                  Icon(Icons.picture_as_pdf, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  const Text('Imprimer/PDF', style: TextStyle(color: Colors.white, fontSize: 11)),
                ]),
              ),
            ],
            onSelected: (value) {
              if (value == 'html') _exportAsHtml(accentColor);
              if (value == 'pdf') _exportAsPdf();
            },
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(height: 12),
          Text('Chargement...', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_outlined, size: 40, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text('Aucun DOM', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadDOMTree,
            icon: Icon(Icons.refresh, size: 14, color: accentColor),
            label: Text('Charger', style: TextStyle(color: accentColor, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildDOMTree(DOMNode root, Color accentColor) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: ListView(
        padding: const EdgeInsets.all(4),
        children: [_buildDOMNode(root, accentColor)],
      ),
    );
  }

  Widget _buildDOMNode(DOMNode node, Color accentColor) {
    final isExpanded = _expandedNodes.contains(node.id);
    final isSelected = _selectedNode?.id == node.id;
    final hasChildren = node.hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
          child: InkWell(
            onTap: () => _selectNode(node),
            child: Padding(
              padding: EdgeInsets.only(left: node.depth * 16.0, top: 2, bottom: 2, right: 4),
              child: Row(
                children: [
                  // Chevron expand/collapse
                  GestureDetector(
                    onTap: hasChildren ? () => _toggleNode(node) : null,
                    child: SizedBox(
                      width: 16,
                      child: hasChildren
                          ? Icon(
                              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              size: 14,
                              color: Colors.white.withOpacity(0.5),
                            )
                          : null,
                    ),
                  ),
                  // Tag HTML coloré style VSCode
                  Expanded(child: _buildVSCodeTag(node, accentColor)),
                ],
              ),
            ),
          ),
        ),
        if (hasChildren && isExpanded) ...[
          ...node.children.map((child) => _buildDOMNode(child, accentColor)),
          // Tag fermant
          Padding(
            padding: EdgeInsets.only(left: node.depth * 16.0 + 16, top: 2, bottom: 2),
            child: _buildClosingTag(node),
          ),
        ],
      ],
    );
  }

  Widget _buildVSCodeTag(DOMNode node, Color accentColor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, fontFamily: 'Consolas', height: 1.4),
        children: [
          TextSpan(text: '<', style: TextStyle(color: Colors.grey.shade500)),
          TextSpan(text: node.tagName.toLowerCase(), style: TextStyle(color: _getVSCodeTagColor(node.tagName))),
          ...node.attributes.entries.expand((e) => [
            TextSpan(text: ' ${e.key}', style: const TextStyle(color: Color(0xFF9CDCFE))),
            TextSpan(text: '=', style: TextStyle(color: Colors.grey.shade500)),
            TextSpan(text: '"${e.value}"', style: const TextStyle(color: Color(0xFFCE9178))),
          ]),
          TextSpan(
            text: node.hasChildren || node.hasText ? '>' : ' />',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (node.hasText && !node.hasChildren)
            TextSpan(text: node.textContent, style: const TextStyle(color: Colors.white70)),
          if (node.hasText && !node.hasChildren) ...[
            TextSpan(text: '</', style: TextStyle(color: Colors.grey.shade500)),
            TextSpan(text: node.tagName.toLowerCase(), style: TextStyle(color: _getVSCodeTagColor(node.tagName))),
            TextSpan(text: '>', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _buildClosingTag(DOMNode node) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, fontFamily: 'Consolas'),
        children: [
          TextSpan(text: '</', style: TextStyle(color: Colors.grey.shade500)),
          TextSpan(text: node.tagName.toLowerCase(), style: TextStyle(color: _getVSCodeTagColor(node.tagName))),
          TextSpan(text: '>', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Color _getVSCodeTagColor(String tagName) {
    switch (tagName.toLowerCase()) {
      case 'html': case 'head': case 'body': case 'main': case 'header': case 'footer': case 'nav':
        return const Color(0xFF569CD6); // Bleu
      case 'div': case 'span': case 'section': case 'article': case 'aside':
        return const Color(0xFF4EC9B0); // Cyan
      case 'a': case 'link':
        return const Color(0xFFDCDCAA); // Jaune
      case 'script': case 'style':
        return const Color(0xFFC586C0); // Violet
      case 'img': case 'video': case 'audio': case 'source': case 'svg':
        return const Color(0xFFD7BA7D); // Or
      case 'input': case 'button': case 'form': case 'select': case 'textarea': case 'label':
        return const Color(0xFF4FC1FF); // Bleu clair
      case 'h1': case 'h2': case 'h3': case 'h4': case 'h5': case 'h6':
        return const Color(0xFFFF79C6); // Rose
      case 'p': case 'ul': case 'ol': case 'li':
        return const Color(0xFF98C379); // Vert
      default:
        return const Color(0xFF569CD6);
    }
  }

  Widget _buildStylesPanel(Color accentColor) {
    return Column(
      children: [
        // Header
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D30),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Icon(Icons.style, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text('Styles', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 12),
                color: Colors.white38,
                onPressed: () => setState(() => _selectedNode = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
            ],
          ),
        ),
        
        // Element info
        Container(
          padding: const EdgeInsets.all(8),
          color: accentColor.withOpacity(0.1),
          child: Row(
            children: [
              Text(
                '<${_selectedNode?.tagName.toLowerCase() ?? ''}>',
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_selectedNode?.attributes['id']?.isNotEmpty == true)
                Text(
                  ' #${_selectedNode!.attributes['id']}',
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Color(0xFF9CDCFE)),
                ),
              if (_selectedNode?.attributes['class']?.isNotEmpty == true)
                Text(
                  ' .${_selectedNode!.attributes['class']!.split(' ').first}',
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Color(0xFFCE9178)),
                ),
            ],
          ),
        ),
        
        // CSS Editor
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header éditeur CSS
              InkWell(
                onTap: () => setState(() => _cssEditorExpanded = !_cssEditorExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _cssEditorExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'element.style {',
                        style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: accentColor),
                      ),
                      const Spacer(),
                      if (_cssEditorExpanded)
                        TextButton(
                          onPressed: () => _applyCssChanges(accentColor),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 12, color: accentColor),
                              const SizedBox(width: 4),
                              Text('Appliquer', style: TextStyle(fontSize: 10, color: accentColor)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Éditeur CSS
              if (_cssEditorExpanded)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: const Color(0xFF1E1E1E),
                    child: TextField(
                      controller: _cssEditorController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: 'property: value;',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              
              // Fermeture accolade
              if (_cssEditorExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text('}', style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: accentColor)),
                ),
              
              // Quick actions
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D30),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  children: [
                    _QuickActionButton(icon: Icons.visibility_off, label: 'Hide', accentColor: accentColor, onTap: () => _executeOnElement('el.style.display="none"')),
                    _QuickActionButton(icon: Icons.delete_outline, label: 'Delete', accentColor: accentColor, onTap: () => _executeOnElement('el.remove()')),
                    _QuickActionButton(icon: Icons.content_copy, label: 'Copy', accentColor: accentColor, onTap: _copyElementHtml),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _executeOnElement(String code) async {
    if (_selectedNode == null) return;
    final devTools = context.read<DevToolsService>();
    String selector = _selectedNode!.tagName;
    if (_selectedNode!.attributes['id']?.isNotEmpty == true) {
      selector = '#${_selectedNode!.attributes['id']}';
    }
    await devTools.executeScript('(function(){const el=document.querySelector("$selector");if(el){$code}})();');
    _loadDOMTree();
  }

  Future<void> _copyElementHtml() async {
    if (_selectedNode == null) return;
    final devTools = context.read<DevToolsService>();
    String selector = '#${_selectedNode!.attributes['id'] ?? _selectedNode!.tagName}';
    final html = await devTools.executeScript('document.querySelector("$selector")?.outerHTML || ""');
    if (html != null) {
      await Clipboard.setData(ClipboardData(text: html));
    }
  }
}

// === COMPOSANTS ===

enum _ResourceType { image, script, stylesheet, font, video, other }

class _PageResource {
  final _ResourceType type;
  final String url;
  final String name;
  _PageResource({required this.type, required this.url, required this.name});
}

class _VSCodeSidebar extends StatelessWidget {
  final List<_PageResource> resources;
  final _ResourceType? selectedType;
  final Color accentColor;
  final ValueChanged<_ResourceType?> onTypeSelected;
  final ValueChanged<_PageResource> onResourceTap;

  const _VSCodeSidebar({
    required this.resources,
    required this.selectedType,
    required this.accentColor,
    required this.onTypeSelected,
    required this.onResourceTap,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedType == null ? resources : resources.where((r) => r.type == selectedType).toList();

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D30),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Text('RESSOURCES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor, letterSpacing: 1)),
              ],
            ),
          ),
          
          // Filtres par type
          Container(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _TypeChip(label: 'Tous', count: resources.length, isSelected: selectedType == null, accentColor: accentColor, onTap: () => onTypeSelected(null)),
                ..._ResourceType.values.map((type) {
                  final count = resources.where((r) => r.type == type).length;
                  if (count == 0) return const SizedBox.shrink();
                  return _TypeChip(
                    label: type.name.substring(0, 3).toUpperCase(),
                    count: count,
                    isSelected: selectedType == type,
                    accentColor: accentColor,
                    onTap: () => onTypeSelected(type),
                  );
                }),
              ],
            ),
          ),
          
          // Liste des ressources
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final resource = filtered[index];
                return InkWell(
                  onTap: () => onResourceTap(resource),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(_getResourceIcon(resource.type), size: 12, color: accentColor.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resource.name,
                            style: const TextStyle(fontSize: 10, color: Colors.white60),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResourceIcon(_ResourceType type) {
    switch (type) {
      case _ResourceType.image: return Icons.image;
      case _ResourceType.script: return Icons.javascript;
      case _ResourceType.stylesheet: return Icons.style;
      case _ResourceType.font: return Icons.font_download;
      case _ResourceType.video: return Icons.videocam;
      case _ResourceType.other: return Icons.insert_drive_file;
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.count, required this.isSelected, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? accentColor.withOpacity(0.5) : Colors.transparent),
        ),
        child: Text('$label ($count)', style: TextStyle(fontSize: 9, color: isSelected ? accentColor : Colors.white54)),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color accentColor;
  final bool isActive;

  const _ToolbarButton({required this.icon, required this.tooltip, required this.onPressed, required this.accentColor, this.isActive = false});

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
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 14, color: isActive ? accentColor : Colors.white.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white54),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4))),
            ],
          ),
        ),
      ),
    );
  }
}
