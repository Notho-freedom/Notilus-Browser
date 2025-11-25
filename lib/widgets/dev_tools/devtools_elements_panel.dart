/// Panneau Elements du DevTools natif Notilus - Éditeur DOM Avancé style VSCode
/// Fonctionnalités:
/// - Édition live des tags, attributs et styles
/// - Ressources du site en sidebar
/// - Export PDF/HTML
/// - Mode éditeur DOM complet
library devtools_elements_panel;

import 'dart:convert';
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

class _DevToolsElementsPanelState extends State<DevToolsElementsPanel>
    with SingleTickerProviderStateMixin {
  final Set<String> _expandedNodes = {};
  DOMNode? _selectedNode;
  Map<String, dynamic>? _selectedNodeDetails;
  bool _isLoading = false;
  
  // Mode d'affichage
  _ViewMode _viewMode = _ViewMode.tree;
  
  // Sidebar ressources
  bool _showResources = false;
  List<_PageResource> _resources = [];
  _ResourceType? _selectedResourceType;
  
  // Éditeur CSS
  final TextEditingController _cssEditorController = TextEditingController();
  bool _cssEditorExpanded = false;
  
  // Éditeur HTML inline
  bool _isEditingHtml = false;
  final TextEditingController _htmlEditorController = TextEditingController();
  
  // Onglet details
  late TabController _detailsTabController;
  
  @override
  void initState() {
    super.initState();
    _detailsTabController = TabController(length: 4, vsync: this);
    _loadDOMTree();
    _loadResources();
  }

  @override
  void dispose() {
    _cssEditorController.dispose();
    _htmlEditorController.dispose();
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
    
    // Charger les ressources via JavaScript
    try {
      final result = await devTools.executeScript('''
        (function() {
          const resources = [];
          
          // Images
          document.querySelectorAll('img').forEach(img => {
            resources.push({
              type: 'image',
              url: img.src,
              name: img.src.split('/').pop() || 'image',
              size: img.naturalWidth + 'x' + img.naturalHeight
            });
          });
          
          // Scripts
          document.querySelectorAll('script[src]').forEach(script => {
            resources.push({
              type: 'script',
              url: script.src,
              name: script.src.split('/').pop() || 'script.js'
            });
          });
          
          // Styles
          document.querySelectorAll('link[rel="stylesheet"]').forEach(link => {
            resources.push({
              type: 'stylesheet',
              url: link.href,
              name: link.href.split('/').pop() || 'style.css'
            });
          });
          
          // Fonts
          document.querySelectorAll('link[rel="preload"][as="font"]').forEach(font => {
            resources.push({
              type: 'font',
              url: font.href,
              name: font.href.split('/').pop() || 'font'
            });
          });
          
          // Videos
          document.querySelectorAll('video source').forEach(video => {
            resources.push({
              type: 'video',
              url: video.src,
              name: video.src.split('/').pop() || 'video'
            });
          });
          
          return JSON.stringify(resources);
        })();
      ''');
      
      if (result != null && mounted) {
        final List<dynamic> resourceList = jsonDecode(result);
        setState(() {
          _resources = resourceList.map((r) => _PageResource(
            type: _ResourceType.values.firstWhere(
              (t) => t.name == r['type'],
              orElse: () => _ResourceType.other,
            ),
            url: r['url'] ?? '',
            name: r['name'] ?? 'Unknown',
            size: r['size'],
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
      _isEditingHtml = false;
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
        // Charger les styles dans l'éditeur CSS
        if (details['styles'] != null) {
          final styles = details['styles'] as Map<String, dynamic>;
          final cssText = styles.entries
              .map((e) => '${e.key}: ${e.value};')
              .join('\n');
          _cssEditorController.text = cssText;
        }
      });
    }
  }

  // Appliquer les modifications CSS en temps réel
  Future<void> _applyCssChanges() async {
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
        if (el) {
          el.style.cssText = `$cssText`;
        }
      })();
    ''');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Styles appliqués'),
        backgroundColor: NotilusColors.neonRed,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Modifier un attribut
  Future<void> _editAttribute(String name, String oldValue) async {
    final controller = TextEditingController(text: oldValue);
    
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text(
          'Éditer $name',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'JetBrains Mono',
          ),
          decoration: InputDecoration(
            hintText: 'Nouvelle valeur',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: NotilusColors.neonRed.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: NotilusColors.neonRed),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: NotilusColors.neonRed),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
    
    if (newValue != null && _selectedNode != null) {
      final devTools = context.read<DevToolsService>();
      String selector = '#${_selectedNode!.attributes['id'] ?? _selectedNode!.tagName}';
      
      await devTools.executeScript('''
        (function() {
          const el = document.querySelector('$selector');
          if (el) {
            el.setAttribute('$name', '$newValue');
          }
        })();
      ''');
      
      // Refresh
      await _selectNode(_selectedNode!);
    }
  }

  // Exporter en HTML
  Future<void> _exportAsHtml() async {
    final devTools = context.read<DevToolsService>();
    final html = await devTools.executeScript('document.documentElement.outerHTML');
    
    if (html != null) {
      await Clipboard.setData(ClipboardData(text: html));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📋 HTML copié dans le presse-papier'),
            backgroundColor: NotilusColors.neonRed,
          ),
        );
      }
    }
  }

  // Exporter en PDF (simulation - copie une version simplifiée)
  Future<void> _exportAsPdf() async {
    final devTools = context.read<DevToolsService>();
    await devTools.executeScript('window.print()');
  }

  // Télécharger une ressource
  Future<void> _downloadResource(_PageResource resource) async {
    await Clipboard.setData(ClipboardData(text: resource.url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 URL copiée: ${resource.name}'),
          backgroundColor: NotilusColors.neonRed,
        ),
      );
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
              _buildToolbar(),
              Expanded(
                child: Row(
                  children: [
                    // Sidebar ressources
                    if (_showResources)
                      _ResourcesSidebar(
                        resources: _resources,
                        selectedType: _selectedResourceType,
                        onTypeSelected: (type) => setState(() => _selectedResourceType = type),
                        onResourceTap: _downloadResource,
                        onClose: () => setState(() => _showResources = false),
                      ),
                    
                    // Arbre DOM
                    Expanded(
                      flex: 3,
                      child: _isLoading
                          ? _buildLoadingState()
                          : devTools.domTree == null
                              ? _buildEmptyState()
                              : _viewMode == _ViewMode.tree
                                  ? _buildDOMTree(devTools.domTree!)
                                  : _buildSourceView(devTools.domTree!),
                    ),

                    // Panneau de détails / éditeur
                    if (_selectedNode != null) ...[
                      Container(
                        width: 1,
                        color: NotilusColors.neonRed.withOpacity(0.2),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildAdvancedDetailsPanel(),
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
      height: 40,
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
          // Vue
          _ToolbarSegment(
            items: [
              _SegmentItem(icon: Icons.account_tree, tooltip: 'Arbre', isSelected: _viewMode == _ViewMode.tree),
              _SegmentItem(icon: Icons.code, tooltip: 'Source', isSelected: _viewMode == _ViewMode.source),
            ],
            onItemSelected: (index) {
              setState(() {
                _viewMode = index == 0 ? _ViewMode.tree : _ViewMode.source;
              });
            },
          ),
          
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.white.withOpacity(0.1)),
          const SizedBox(width: 8),
          
          _ToolbarButton(
            icon: Icons.refresh,
            tooltip: 'Actualiser',
            onPressed: () {
              _loadDOMTree();
              _loadResources();
            },
          ),
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
            onPressed: () => setState(() => _expandedNodes.clear()),
          ),
          
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.white.withOpacity(0.1)),
          const SizedBox(width: 8),
          
          // Toggle ressources
          _ToolbarButton(
            icon: Icons.folder_open,
            tooltip: 'Ressources du site',
            isActive: _showResources,
            onPressed: () => setState(() => _showResources = !_showResources),
          ),
          
          const Spacer(),
          
          // Export
          PopupMenuButton<String>(
            tooltip: 'Exporter',
            icon: Icon(Icons.download, size: 16, color: Colors.white.withOpacity(0.6)),
            color: const Color(0xFF1E1E24),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'html',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 16, color: NotilusColors.neonRed),
                    const SizedBox(width: 8),
                    const Text('Copier HTML', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 16, color: NotilusColors.neonRed),
                    const SizedBox(width: 8),
                    const Text('Imprimer/PDF', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'html') _exportAsHtml();
              if (value == 'pdf') _exportAsPdf();
            },
          ),
          
          const SizedBox(width: 8),
          
          // Stats ressources
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder, size: 12, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  '${_resources.length} ressources',
                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                ),
              ],
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
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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
          Icon(Icons.code_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            'Aucun DOM chargé',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadDOMTree,
            icon: Icon(Icons.refresh, size: 16, color: NotilusColors.neonRed),
            label: Text('Charger le DOM', style: TextStyle(color: NotilusColors.neonRed, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDOMTree(DOMNode root) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [_buildDOMNode(root)],
    );
  }

  Widget _buildSourceView(DOMNode root) {
    // Vue source HTML brute
    final html = _nodeToHtml(root, 0);
    return Container(
      color: const Color(0xFF0A0A0E),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          html,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  String _nodeToHtml(DOMNode node, int indent) {
    final indentStr = '  ' * indent;
    final attrs = node.attributes.entries
        .map((e) => '${e.key}="${e.value}"')
        .join(' ');
    
    if (node.children.isEmpty && !node.hasText) {
      return '$indentStr<${node.tagName}${attrs.isNotEmpty ? ' $attrs' : ''} />';
    }
    
    final children = node.children.map((c) => _nodeToHtml(c, indent + 1)).join('\n');
    final text = node.textContent ?? '';
    
    return '''$indentStr<${node.tagName}${attrs.isNotEmpty ? ' $attrs' : ''}>
${text.isNotEmpty ? '$indentStr  $text' : ''}${children.isNotEmpty ? '\n$children' : ''}
$indentStr</${node.tagName}>''';
  }

  Widget _buildDOMNode(DOMNode node) {
    final isExpanded = _expandedNodes.contains(node.id);
    final isSelected = _selectedNode?.id == node.id;
    final hasChildren = node.hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: isSelected
              ? NotilusColors.neonRed.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _selectNode(node),
            onDoubleTap: () {
              // Double-clic = éditer HTML
              setState(() {
                _isEditingHtml = true;
                _htmlEditorController.text = _nodeToHtml(node, 0);
              });
            },
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
                  if (hasChildren)
                    GestureDetector(
                      onTap: () => _toggleNode(node),
                      child: Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                  _buildTag(node, isOpening: true),
                  if (node.hasText && !hasChildren) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        node.textContent!,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
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
        if (hasChildren && isExpanded) ...[
          ...node.children.map((child) => _buildDOMNode(child)),
          Padding(
            padding: EdgeInsets.only(left: node.depth * 16.0 + 16, top: 4, bottom: 4),
            child: _buildTag(node, isOpening: false),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(DOMNode node, {required bool isOpening}) {
    final List<InlineSpan> spans = [];

    if (isOpening) {
      spans.add(TextSpan(text: '<', style: TextStyle(color: Colors.white.withOpacity(0.5))));
      spans.add(TextSpan(text: node.tagName, style: TextStyle(color: _getTagColor(node.tagName))));
      node.attributes.forEach((key, value) {
        spans.add(TextSpan(text: ' $key', style: const TextStyle(color: Color(0xFF9CDCFE))));
        spans.add(TextSpan(text: '=', style: TextStyle(color: Colors.white.withOpacity(0.5))));
        spans.add(TextSpan(text: '"$value"', style: const TextStyle(color: Color(0xFFCE9178))));
      });
      spans.add(TextSpan(
        text: node.hasChildren || node.hasText ? '>' : ' />',
        style: TextStyle(color: Colors.white.withOpacity(0.5)),
      ));
    } else {
      spans.add(TextSpan(text: '</', style: TextStyle(color: Colors.white.withOpacity(0.5))));
      spans.add(TextSpan(text: node.tagName, style: TextStyle(color: _getTagColor(node.tagName))));
      spans.add(TextSpan(text: '>', style: TextStyle(color: Colors.white.withOpacity(0.5))));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, fontFamily: 'JetBrains Mono'),
        children: spans,
      ),
    );
  }

  Color _getTagColor(String tagName) {
    switch (tagName.toLowerCase()) {
      case 'html': case 'head': case 'body':
        return const Color(0xFF569CD6);
      case 'div': case 'span': case 'p': case 'section': case 'article':
        return const Color(0xFF4EC9B0);
      case 'a': case 'link':
        return const Color(0xFFDCDCAA);
      case 'script': case 'style':
        return const Color(0xFFC586C0);
      case 'img': case 'video': case 'audio': case 'source':
        return const Color(0xFFFFB86C);
      case 'input': case 'button': case 'form': case 'select': case 'textarea':
        return const Color(0xFF50FA7B);
      case 'h1': case 'h2': case 'h3': case 'h4': case 'h5': case 'h6':
        return const Color(0xFFFF79C6);
      default:
        return const Color(0xFF4FC1FF);
    }
  }

  Widget _buildAdvancedDetailsPanel() {
    return Container(
      color: const Color(0xFF0D0D12),
      child: Column(
        children: [
          // Header avec tabs
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF131318),
              border: Border(bottom: BorderSide(color: NotilusColors.neonRed.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _detailsTabController,
                    isScrollable: true,
                    indicatorColor: NotilusColors.neonRed,
                    indicatorWeight: 2,
                    labelColor: NotilusColors.neonRed,
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'STYLES'),
                      Tab(text: 'ATTRIBUTS'),
                      Tab(text: 'BOX MODEL'),
                      Tab(text: 'ÉVÉNEMENTS'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: () => setState(() {
                    _selectedNode = null;
                    _selectedNodeDetails = null;
                  }),
                ),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: TabBarView(
              controller: _detailsTabController,
              children: [
                _buildStylesTab(),
                _buildAttributesTab(),
                _buildBoxModelTab(),
                _buildEventsTab(),
              ],
            ),
          ),
          
          // Quick actions bar
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF131318),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.visibility_off,
                  label: 'Masquer',
                  onTap: () => _executeOnElement('el.style.display = "none"'),
                ),
                _QuickAction(
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  onTap: () => _executeOnElement('el.remove()'),
                ),
                _QuickAction(
                  icon: Icons.content_copy,
                  label: 'Copier',
                  onTap: _copyElementHtml,
                ),
                _QuickAction(
                  icon: Icons.screenshot,
                  label: 'Screenshot',
                  onTap: _screenshotElement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylesTab() {
    return Column(
      children: [
        // Éditeur CSS en haut
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0E),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Column(
            children: [
              // Header éditeur
              InkWell(
                onTap: () => setState(() => _cssEditorExpanded = !_cssEditorExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _cssEditorExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: NotilusColors.neonRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'element.style',
                        style: TextStyle(
                          fontSize: 11,
                          color: NotilusColors.neonRed,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const Spacer(),
                      if (_cssEditorExpanded)
                        TextButton.icon(
                          onPressed: _applyCssChanges,
                          icon: Icon(Icons.play_arrow, size: 14, color: NotilusColors.neonRed),
                          label: Text('Appliquer', style: TextStyle(fontSize: 10, color: NotilusColors.neonRed)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Éditeur
              if (_cssEditorExpanded)
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _cssEditorController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'property: value;\n...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Styles calculés
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'COMPUTED STYLES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedNodeDetails?['styles'] != null)
                ...(_selectedNodeDetails!['styles'] as Map<String, dynamic>).entries.map(
                  (e) => _EditableStyleRow(
                    property: e.key,
                    value: e.value.toString(),
                    onEdit: (newValue) => _updateStyle(e.key, newValue),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Info tag
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NotilusColors.neonRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.code, size: 16, color: NotilusColors.neonRed),
              const SizedBox(width: 8),
              Text(
                '<${_selectedNode?.tagName ?? ''}>',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: NotilusColors.neonRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Attributs éditables
        Row(
          children: [
            Text(
              'ATTRIBUTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.add, size: 14, color: NotilusColors.neonRed),
              onPressed: _addAttribute,
              tooltip: 'Ajouter attribut',
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        if (_selectedNode != null)
          ..._selectedNode!.attributes.entries.map(
            (e) => _EditableAttributeRow(
              name: e.key,
              value: e.value,
              onEdit: () => _editAttribute(e.key, e.value),
              onDelete: () => _deleteAttribute(e.key),
            ),
          ),
      ],
    );
  }

  Widget _buildBoxModelTab() {
    final rect = _selectedNodeDetails?['rect'] as Map<String, dynamic>?;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Visual box model
          _VisualBoxModel(rect: rect),
          
          const SizedBox(height: 16),
          
          // Dimensions numériques
          if (rect != null) ...[
            _DimensionRow(label: 'Width', value: rect['width']?.toString() ?? '0'),
            _DimensionRow(label: 'Height', value: rect['height']?.toString() ?? '0'),
            _DimensionRow(label: 'X', value: rect['x']?.toString() ?? '0'),
            _DimensionRow(label: 'Y', value: rect['y']?.toString() ?? '0'),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mouse, size: 32, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            'Event Listeners',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez sur un élément pour voir ses événements',
            style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _executeOnElement(String code) async {
    if (_selectedNode == null) return;
    
    final devTools = context.read<DevToolsService>();
    String selector = _selectedNode!.tagName;
    if (_selectedNode!.attributes['id']?.isNotEmpty == true) {
      selector = '#${_selectedNode!.attributes['id']}';
    }
    
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) { $code }
      })();
    ''');
    
    _loadDOMTree();
  }

  Future<void> _copyElementHtml() async {
    if (_selectedNode == null) return;
    final html = _nodeToHtml(_selectedNode!, 0);
    await Clipboard.setData(ClipboardData(text: html));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📋 HTML copié'),
          backgroundColor: NotilusColors.neonRed,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _screenshotElement() async {
    if (_selectedNode == null) return;
    
    final devTools = context.read<DevToolsService>();
    String selector = _selectedNode!.tagName;
    if (_selectedNode!.attributes['id']?.isNotEmpty == true) {
      selector = '#${_selectedNode!.attributes['id']}';
    }
    
    // Highlight l'élément
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) {
          el.style.outline = '3px solid red';
          setTimeout(() => { el.style.outline = ''; }, 2000);
        }
      })();
    ''');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📸 Élément surligné pendant 2s'),
          backgroundColor: NotilusColors.neonRed,
        ),
      );
    }
  }

  Future<void> _updateStyle(String property, String value) async {
    if (_selectedNode == null) return;
    
    final devTools = context.read<DevToolsService>();
    String selector = '#${_selectedNode!.attributes['id'] ?? _selectedNode!.tagName}';
    
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) { el.style['$property'] = '$value'; }
      })();
    ''');
  }

  Future<void> _addAttribute() async {
    // Dialog pour ajouter un nouvel attribut
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text('Nouvel attribut', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nom',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            TextField(
              controller: valueController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Valeur',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'value': valueController.text,
            }),
            style: ElevatedButton.styleFrom(backgroundColor: NotilusColors.neonRed),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    
    if (result != null && _selectedNode != null) {
      await _executeOnElement('el.setAttribute("${result['name']}", "${result['value']}")');
      _loadDOMTree();
    }
  }

  Future<void> _deleteAttribute(String name) async {
    await _executeOnElement('el.removeAttribute("$name")');
    _loadDOMTree();
  }
}

// === COMPOSANTS AUXILIAIRES ===

enum _ViewMode { tree, source }

enum _ResourceType { image, script, stylesheet, font, video, other }

class _PageResource {
  final _ResourceType type;
  final String url;
  final String name;
  final String? size;
  
  _PageResource({required this.type, required this.url, required this.name, this.size});
}

class _ResourcesSidebar extends StatelessWidget {
  final List<_PageResource> resources;
  final _ResourceType? selectedType;
  final ValueChanged<_ResourceType?> onTypeSelected;
  final ValueChanged<_PageResource> onResourceTap;
  final VoidCallback onClose;

  const _ResourcesSidebar({
    required this.resources,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onResourceTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedType == null
        ? resources
        : resources.where((r) => r.type == selectedType).toList();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        border: Border(right: BorderSide(color: NotilusColors.neonRed.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open, size: 16, color: NotilusColors.neonRed),
                const SizedBox(width: 8),
                const Text('Ressources', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: onClose,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
          
          // Filtres
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _FilterChip(
                  label: 'Tous',
                  count: resources.length,
                  isSelected: selectedType == null,
                  onTap: () => onTypeSelected(null),
                ),
                ..._ResourceType.values.map((type) {
                  final count = resources.where((r) => r.type == type).length;
                  if (count == 0) return const SizedBox.shrink();
                  return _FilterChip(
                    label: type.name,
                    count: count,
                    isSelected: selectedType == type,
                    onTap: () => onTypeSelected(type),
                  );
                }),
              ],
            ),
          ),
          
          // Liste
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final resource = filtered[index];
                return _ResourceItem(resource: resource, onTap: () => onResourceTap(resource));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? NotilusColors.neonRed.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? NotilusColors.neonRed : Colors.transparent,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 9,
            color: isSelected ? NotilusColors.neonRed : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final _PageResource resource;
  final VoidCallback onTap;

  const _ResourceItem({required this.resource, required this.onTap});

  IconData _getIcon() {
    switch (resource.type) {
      case _ResourceType.image: return Icons.image;
      case _ResourceType.script: return Icons.javascript;
      case _ResourceType.stylesheet: return Icons.style;
      case _ResourceType.font: return Icons.font_download;
      case _ResourceType.video: return Icons.videocam;
      case _ResourceType.other: return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(_getIcon(), size: 14, color: NotilusColors.neonRed.withOpacity(0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.name,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (resource.size != null)
                    Text(
                      resource.size!,
                      style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4)),
                    ),
                ],
              ),
            ),
            Icon(Icons.content_copy, size: 12, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? NotilusColors.neonRed.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? NotilusColors.neonRed : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarSegment extends StatelessWidget {
  final List<_SegmentItem> items;
  final ValueChanged<int> onItemSelected;

  const _ToolbarSegment({required this.items, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Tooltip(
            message: item.tooltip,
            child: InkWell(
              onTap: () => onItemSelected(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.isSelected ? NotilusColors.neonRed.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  item.icon,
                  size: 14,
                  color: item.isSelected ? NotilusColors.neonRed : Colors.white54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SegmentItem {
  final IconData icon;
  final String tooltip;
  final bool isSelected;

  const _SegmentItem({required this.icon, required this.tooltip, required this.isSelected});
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white54),
              Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4))),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableStyleRow extends StatefulWidget {
  final String property;
  final String value;
  final ValueChanged<String> onEdit;

  const _EditableStyleRow({required this.property, required this.value, required this.onEdit});

  @override
  State<_EditableStyleRow> createState() => _EditableStyleRowState();
}

class _EditableStyleRowState extends State<_EditableStyleRow> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              widget.property,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CDCFE), fontFamily: 'JetBrains Mono'),
            ),
          ),
          Text(': ', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'JetBrains Mono'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      widget.onEdit(value);
                      setState(() => _isEditing = false);
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () => setState(() => _isEditing = true),
                    child: Text(
                      widget.value,
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7), fontFamily: 'JetBrains Mono'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditableAttributeRow extends StatelessWidget {
  final String name;
  final String value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EditableAttributeRow({
    required this.name,
    required this.value,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF9CDCFE), fontFamily: 'JetBrains Mono')),
          const Text(' = ', style: TextStyle(fontSize: 11, color: Colors.white38)),
          Expanded(
            child: Text(
              '"$value"',
              style: const TextStyle(fontSize: 11, color: Color(0xFFCE9178), fontFamily: 'JetBrains Mono'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 12, color: NotilusColors.neonRed.withOpacity(0.5)),
            onPressed: onEdit,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 12, color: Colors.red.withOpacity(0.5)),
            onPressed: onDelete,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _VisualBoxModel extends StatelessWidget {
  final Map<String, dynamic>? rect;

  const _VisualBoxModel({this.rect});

  @override
  Widget build(BuildContext context) {
    if (rect == null) {
      return const Center(
        child: Text('Sélectionnez un élément', style: TextStyle(color: Colors.white38)),
      );
    }

    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              '${rect!['width']?.toStringAsFixed(0)}×${rect!['height']?.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  final String label;
  final String value;

  const _DimensionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${value}px',
                style: TextStyle(fontSize: 11, color: NotilusColors.neonRed, fontFamily: 'JetBrains Mono'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
