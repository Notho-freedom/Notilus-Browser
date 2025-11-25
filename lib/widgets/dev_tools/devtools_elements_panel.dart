/// Panneau Elements du DevTools natif Notilus - Éditeur DOM style VSCode
/// - Arborescence en sidebar style explorateur de fichiers
/// - Édition live des tags, attributs et contenu
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

    String selector = _buildSelector(node);

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

  String _buildSelector(DOMNode node) {
    if (node.attributes['id']?.isNotEmpty == true) {
      return '#${node.attributes['id']}';
    } else if (node.attributes['class']?.isNotEmpty == true) {
      return '${node.tagName}.${node.attributes['class']!.split(' ').first}';
    }
    return node.tagName;
  }

  /// Éditer un attribut d'un élément
  Future<void> _editAttribute(DOMNode node, String attrName, String newValue, Color accentColor) async {
    final devTools = context.read<DevToolsService>();
    final selector = _buildSelector(node);
    
    final escaped = newValue.replaceAll('"', '\\"').replaceAll("'", "\\'");
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) {
          el.setAttribute('$attrName', '$escaped');
        }
      })();
    ''');
    
    await _loadDOMTree();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✏️ Attribut "$attrName" modifié'), backgroundColor: accentColor, duration: const Duration(seconds: 1)),
      );
    }
  }

  /// Éditer le contenu texte d'un élément
  Future<void> _editTextContent(DOMNode node, String newText, Color accentColor) async {
    final devTools = context.read<DevToolsService>();
    final selector = _buildSelector(node);
    
    final escaped = newText.replaceAll('`', '\\`').replaceAll('\$', '\\\$');
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) {
          el.textContent = `$escaped`;
        }
      })();
    ''');
    
    await _loadDOMTree();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✏️ Contenu modifié'), backgroundColor: accentColor, duration: const Duration(seconds: 1)),
      );
    }
  }

  /// Éditer le tag HTML complet (outerHTML)
  Future<void> _editOuterHTML(DOMNode node, String newHTML, Color accentColor) async {
    final devTools = context.read<DevToolsService>();
    final selector = _buildSelector(node);
    
    final escaped = newHTML.replaceAll('`', '\\`').replaceAll('\$', '\\\$');
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) {
          el.outerHTML = `$escaped`;
        }
      })();
    ''');
    
    await _loadDOMTree();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✏️ HTML modifié'), backgroundColor: accentColor, duration: const Duration(seconds: 1)),
      );
    }
  }

  /// Ajouter un nouvel attribut
  Future<void> _addAttribute(DOMNode node, String attrName, String attrValue, Color accentColor) async {
    await _editAttribute(node, attrName, attrValue, accentColor);
  }

  /// Supprimer un attribut
  Future<void> _removeAttribute(DOMNode node, String attrName, Color accentColor) async {
    final devTools = context.read<DevToolsService>();
    final selector = _buildSelector(node);
    
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) {
          el.removeAttribute('$attrName');
        }
      })();
    ''');
    
    await _loadDOMTree();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ Attribut "$attrName" supprimé'), backgroundColor: accentColor, duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _applyCssChanges(Color accentColor) async {
    if (_selectedNode == null) return;
    
    final devTools = context.read<DevToolsService>();
    final selector = _buildSelector(_selectedNode!);
    
    final cssText = _cssEditorController.text;
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) { el.style.cssText = `$cssText`; }
      })();
    ''');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Styles appliqués'), backgroundColor: accentColor, duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _deleteElement(DOMNode node, Color accentColor) async {
    final devTools = context.read<DevToolsService>();
    final selector = _buildSelector(node);
    
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) { el.remove(); }
      })();
    ''');
    
    setState(() {
      _selectedNode = null;
      _selectedNodeDetails = null;
    });
    
    await _loadDOMTree();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('🗑️ Élément supprimé'), backgroundColor: accentColor, duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _duplicateElement(DOMNode node, Color accentColor) async {
    final devTools = context.read<DevToolsService>();
    final selector = _buildSelector(node);
    
    await devTools.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (el) {
          const clone = el.cloneNode(true);
          el.parentNode.insertBefore(clone, el.nextSibling);
        }
      })();
    ''');
    
    await _loadDOMTree();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('📋 Élément dupliqué'), backgroundColor: accentColor, duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        return Container(
          color: const Color(0xFF1E1E1E),
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
                  width: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252526),
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
          _ToolbarButton(icon: Icons.folder_open, tooltip: 'Ressources', isActive: _showResources, accentColor: accentColor, onPressed: () => setState(() => _showResources = !_showResources)),
          _ToolbarButton(icon: Icons.refresh, tooltip: 'Actualiser', accentColor: accentColor, onPressed: () { _loadDOMTree(); _loadResources(); }),
          _ToolbarButton(icon: Icons.unfold_more, tooltip: 'Tout développer', accentColor: accentColor, onPressed: () {
              final devTools = context.read<DevToolsService>();
            if (devTools.domTree != null) _expandAllNodes(devTools.domTree!);
          }),
          _ToolbarButton(icon: Icons.unfold_less, tooltip: 'Tout réduire', accentColor: accentColor, onPressed: () => setState(() => _expandedNodes.clear())),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 12, color: accentColor),
                const SizedBox(width: 4),
                Text('Double-clic pour éditer', style: TextStyle(fontSize: 10, color: accentColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
        _EditableDOMNode(
          node: node,
          isSelected: isSelected,
          isExpanded: isExpanded,
          hasChildren: hasChildren,
          accentColor: accentColor,
            onTap: () => _selectNode(node),
          onToggle: hasChildren ? () => _toggleNode(node) : null,
          onEditAttribute: (name, value) => _editAttribute(node, name, value, accentColor),
          onEditText: (text) => _editTextContent(node, text, accentColor),
          onEditHTML: (html) => _editOuterHTML(node, html, accentColor),
          onDelete: () => _deleteElement(node, accentColor),
          onDuplicate: () => _duplicateElement(node, accentColor),
          onAddAttribute: (name, value) => _addAttribute(node, name, value, accentColor),
          onRemoveAttribute: (name) => _removeAttribute(node, name, accentColor),
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
        return const Color(0xFF569CD6);
      case 'div': case 'span': case 'section': case 'article': case 'aside':
        return const Color(0xFF4EC9B0);
      case 'a': case 'link':
        return const Color(0xFFDCDCAA);
      case 'script': case 'style':
        return const Color(0xFFC586C0);
      case 'img': case 'video': case 'audio': case 'source': case 'svg':
        return const Color(0xFFD7BA7D);
      case 'input': case 'button': case 'form': case 'select': case 'textarea': case 'label':
        return const Color(0xFF4FC1FF);
      case 'h1': case 'h2': case 'h3': case 'h4': case 'h5': case 'h6':
        return const Color(0xFFFF79C6);
      case 'p': case 'ul': case 'ol': case 'li':
        return const Color(0xFF98C379);
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
              Text('Propriétés', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
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
                style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
              ),
              if (_selectedNode?.attributes['id']?.isNotEmpty == true)
                Text(' #${_selectedNode!.attributes['id']}', style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Color(0xFF9CDCFE))),
              if (_selectedNode?.attributes['class']?.isNotEmpty == true)
                Text(' .${_selectedNode!.attributes['class']!.split(' ').first}', style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Color(0xFFCE9178))),
              ],
            ),
          ),

        // Attributs éditables
        _buildAttributesEditor(accentColor),
        
        // CSS Editor
        Expanded(child: _buildCSSEditor(accentColor)),
        
        // Quick actions
        _buildQuickActions(accentColor),
      ],
    );
  }

  Widget _buildAttributesEditor(Color accentColor) {
    if (_selectedNode == null) return const SizedBox.shrink();
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
            child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
              children: [
          Text('ATTRIBUTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accentColor, letterSpacing: 1)),
          const SizedBox(height: 8),
          ..._selectedNode!.attributes.entries.map((attr) {
            return _EditableAttributeRow(
              name: attr.key,
              value: attr.value,
              accentColor: accentColor,
              onEdit: (newValue) => _editAttribute(_selectedNode!, attr.key, newValue, accentColor),
              onDelete: () => _removeAttribute(_selectedNode!, attr.key, accentColor),
            );
          }),
          // Bouton ajouter attribut
          TextButton.icon(
            onPressed: () => _showAddAttributeDialog(accentColor),
            icon: Icon(Icons.add, size: 12, color: accentColor),
            label: Text('Ajouter attribut', style: TextStyle(fontSize: 10, color: accentColor)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
        ],
      ),
    );
  }

  void _showAddAttributeDialog(Color accentColor) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252526),
        title: Text('Ajouter un attribut', style: TextStyle(color: accentColor, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Nom',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Valeur',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () {
              if (nameController.text.isNotEmpty && _selectedNode != null) {
                _addAttribute(_selectedNode!, nameController.text, valueController.text, accentColor);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Widget _buildCSSEditor(Color accentColor) {
    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _cssEditorExpanded = !_cssEditorExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
            child: Row(
              children: [
                Icon(_cssEditorExpanded ? Icons.expand_less : Icons.expand_more, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Text('element.style {', style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: accentColor)),
                const Spacer(),
                if (_cssEditorExpanded)
                  TextButton(
                    onPressed: () => _applyCssChanges(accentColor),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
        
        if (_cssEditorExpanded)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF1E1E1E),
              child: TextField(
                controller: _cssEditorController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Colors.white70, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'property: value;',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        
        if (_cssEditorExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text('}', style: TextStyle(fontFamily: 'Consolas', fontSize: 11, color: accentColor)),
          ),
      ],
    );
  }

  Widget _buildQuickActions(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D30),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          _QuickActionButton(icon: Icons.visibility_off, label: 'Hide', accentColor: accentColor, onTap: () async {
            if (_selectedNode != null) {
              final devTools = context.read<DevToolsService>();
              final selector = _buildSelector(_selectedNode!);
              await devTools.executeScript('document.querySelector("$selector").style.display="none"');
            }
          }),
          _QuickActionButton(icon: Icons.content_copy, label: 'Dupliquer', accentColor: accentColor, onTap: () {
            if (_selectedNode != null) _duplicateElement(_selectedNode!, accentColor);
          }),
          _QuickActionButton(icon: Icons.delete_outline, label: 'Delete', accentColor: accentColor, onTap: () {
            if (_selectedNode != null) _deleteElement(_selectedNode!, accentColor);
          }),
          _QuickActionButton(icon: Icons.copy, label: 'Copy HTML', accentColor: accentColor, onTap: () async {
            if (_selectedNode != null) {
              final devTools = context.read<DevToolsService>();
              final selector = _buildSelector(_selectedNode!);
              final html = await devTools.executeScript('document.querySelector("$selector")?.outerHTML || ""');
              if (html != null) await Clipboard.setData(ClipboardData(text: html));
            }
          }),
        ],
      ),
    );
  }
}

// === WIDGET EDITABLE DOM NODE ===

class _EditableDOMNode extends StatefulWidget {
  final DOMNode node;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final Function(String name, String value) onEditAttribute;
  final Function(String text) onEditText;
  final Function(String html) onEditHTML;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final Function(String name, String value) onAddAttribute;
  final Function(String name) onRemoveAttribute;

  const _EditableDOMNode({
    required this.node,
    required this.isSelected,
    required this.isExpanded,
    required this.hasChildren,
    required this.accentColor,
    required this.onTap,
    required this.onToggle,
    required this.onEditAttribute,
    required this.onEditText,
    required this.onEditHTML,
    required this.onDelete,
    required this.onDuplicate,
    required this.onAddAttribute,
    required this.onRemoveAttribute,
  });

  @override
  State<_EditableDOMNode> createState() => _EditableDOMNodeState();
}

class _EditableDOMNodeState extends State<_EditableDOMNode> {
  bool _isEditing = false;
  late TextEditingController _editController;
  String _editMode = 'tag'; // 'tag', 'text', 'html'
  String? _editingAttribute;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing(String mode, [String? attrName]) {
    setState(() {
      _isEditing = true;
      _editMode = mode;
      _editingAttribute = attrName;
      
      switch (mode) {
        case 'text':
          _editController.text = widget.node.textContent ?? '';
          break;
        case 'attr':
          _editController.text = widget.node.attributes[attrName] ?? '';
          break;
        case 'html':
          // On va récupérer le outerHTML
          _editController.text = '<${widget.node.tagName.toLowerCase()}>${widget.node.textContent}</${widget.node.tagName.toLowerCase()}>';
          break;
        default:
          _editController.text = widget.node.tagName;
      }
    });
  }

  void _finishEditing() {
    final value = _editController.text;
    
    switch (_editMode) {
      case 'text':
        widget.onEditText(value);
        break;
      case 'attr':
        if (_editingAttribute != null) {
          widget.onEditAttribute(_editingAttribute!, value);
        }
        break;
      case 'html':
        widget.onEditHTML(value);
        break;
    }
    
    setState(() {
      _isEditing = false;
      _editingAttribute = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingAttribute = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && _editMode == 'html') {
      return _buildHTMLEditor();
    }

    return Material(
      color: widget.isSelected ? widget.accentColor.withOpacity(0.15) : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onDoubleTap: () => _startEditing('html'),
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: Padding(
          padding: EdgeInsets.only(left: widget.node.depth * 16.0, top: 2, bottom: 2, right: 4),
          child: Row(
      children: [
              // Chevron expand/collapse
              GestureDetector(
                onTap: widget.onToggle,
                child: SizedBox(
                  width: 16,
                  child: widget.hasChildren
                      ? Icon(
                          widget.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                          size: 14,
            color: Colors.white.withOpacity(0.5),
                        )
                      : null,
                ),
              ),
              // Tag HTML coloré style VSCode
              Expanded(child: _buildVSCodeTag()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHTMLEditor() {
    return Container(
      margin: EdgeInsets.only(left: widget.node.depth * 16.0, top: 2, bottom: 2, right: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: widget.accentColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 12, color: widget.accentColor),
              const SizedBox(width: 8),
              Text('Édition HTML', style: TextStyle(fontSize: 10, color: widget.accentColor, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.check, size: 14),
                color: Colors.green,
                onPressed: _finishEditing,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Appliquer',
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                color: Colors.red,
                onPressed: _cancelEditing,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Annuler',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _editController,
            autofocus: true,
            maxLines: 5,
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderSide: BorderSide(color: widget.accentColor.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.accentColor)),
              contentPadding: const EdgeInsets.all(8),
            ),
            onSubmitted: (_) => _finishEditing(),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: const Color(0xFF2D2D30),
      items: [
        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 14, color: widget.accentColor), const SizedBox(width: 8), const Text('Éditer HTML', style: TextStyle(color: Colors.white, fontSize: 11))])),
        PopupMenuItem(value: 'editText', child: Row(children: [Icon(Icons.text_fields, size: 14, color: widget.accentColor), const SizedBox(width: 8), const Text('Éditer texte', style: TextStyle(color: Colors.white, fontSize: 11))])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, size: 14, color: widget.accentColor), const SizedBox(width: 8), const Text('Dupliquer', style: TextStyle(color: Colors.white, fontSize: 11))])),
        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 14, color: Colors.red), const SizedBox(width: 8), const Text('Supprimer', style: TextStyle(color: Colors.red, fontSize: 11))])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'copyHTML', child: Row(children: [Icon(Icons.code, size: 14, color: widget.accentColor), const SizedBox(width: 8), const Text('Copier outerHTML', style: TextStyle(color: Colors.white, fontSize: 11))])),
      ],
    ).then((value) {
      switch (value) {
        case 'edit':
          _startEditing('html');
          break;
        case 'editText':
          _startEditing('text');
          break;
        case 'duplicate':
          widget.onDuplicate();
          break;
        case 'delete':
          widget.onDelete();
          break;
        case 'copyHTML':
          // Copy handled in parent
          break;
      }
    });
  }

  Color _getVSCodeTagColor(String tagName) {
    switch (tagName.toLowerCase()) {
      case 'html': case 'head': case 'body': case 'main': case 'header': case 'footer': case 'nav':
        return const Color(0xFF569CD6);
      case 'div': case 'span': case 'section': case 'article': case 'aside':
        return const Color(0xFF4EC9B0);
      case 'a': case 'link':
        return const Color(0xFFDCDCAA);
      case 'script': case 'style':
        return const Color(0xFFC586C0);
      case 'img': case 'video': case 'audio': case 'source': case 'svg':
        return const Color(0xFFD7BA7D);
      case 'input': case 'button': case 'form': case 'select': case 'textarea': case 'label':
        return const Color(0xFF4FC1FF);
      case 'h1': case 'h2': case 'h3': case 'h4': case 'h5': case 'h6':
        return const Color(0xFFFF79C6);
      case 'p': case 'ul': case 'ol': case 'li':
        return const Color(0xFF98C379);
      default:
        return const Color(0xFF569CD6);
    }
  }

  Widget _buildVSCodeTag() {
    final node = widget.node;
    final tagColor = _getVSCodeTagColor(node.tagName);

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, fontFamily: 'Consolas', height: 1.4),
        children: [
          TextSpan(text: '<', style: TextStyle(color: Colors.grey.shade500)),
          TextSpan(text: node.tagName.toLowerCase(), style: TextStyle(color: tagColor)),
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
            TextSpan(text: (node.textContent ?? '').length > 50 ? '${(node.textContent ?? '').substring(0, 50)}...' : (node.textContent ?? ''), style: const TextStyle(color: Colors.white70)),
          if (node.hasText && !node.hasChildren) ...[
            TextSpan(text: '</', style: TextStyle(color: Colors.grey.shade500)),
            TextSpan(text: node.tagName.toLowerCase(), style: TextStyle(color: tagColor)),
            TextSpan(text: '>', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }
}

// === AUTRES WIDGETS ===

class _EditableAttributeRow extends StatefulWidget {
  final String name;
  final String value;
  final Color accentColor;
  final Function(String) onEdit;
  final VoidCallback onDelete;

  const _EditableAttributeRow({
    required this.name,
    required this.value,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EditableAttributeRow> createState() => _EditableAttributeRowState();
}

class _EditableAttributeRowState extends State<_EditableAttributeRow> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(widget.name, style: const TextStyle(fontSize: 10, color: Color(0xFF9CDCFE), fontFamily: 'Consolas')),
          const Text('=', style: TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(width: 4),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 10, color: Color(0xFFCE9178), fontFamily: 'Consolas'),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      border: OutlineInputBorder(borderSide: BorderSide(color: widget.accentColor)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.accentColor)),
                    ),
                    onSubmitted: (val) {
                      widget.onEdit(val);
                      setState(() => _isEditing = false);
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () => setState(() => _isEditing = true),
                    child: Text('"${widget.value}"', style: const TextStyle(fontSize: 10, color: Color(0xFFCE9178), fontFamily: 'Consolas')),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 12),
            color: Colors.red.withOpacity(0.5),
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          ),
        ],
      ),
    );
  }
}

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

  const _VSCodeSidebar({required this.resources, required this.selectedType, required this.accentColor, required this.onTypeSelected, required this.onResourceTap});

  @override
  Widget build(BuildContext context) {
    final filtered = selectedType == null ? resources : resources.where((r) => r.type == selectedType).toList();

    return Container(
      width: 180,
      decoration: BoxDecoration(color: const Color(0xFF252526), border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Column(
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF2D2D30), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
            child: Row(children: [
              Icon(Icons.folder, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text('RESSOURCES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor, letterSpacing: 1)),
            ]),
          ),
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
                  return _TypeChip(label: type.name.substring(0, 3).toUpperCase(), count: count, isSelected: selectedType == type, accentColor: accentColor, onTap: () => onTypeSelected(type));
                }),
              ],
            ),
          ),
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
                    child: Row(children: [
                      Icon(_getResourceIcon(resource.type), size: 12, color: accentColor.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(resource.name, style: const TextStyle(fontSize: 10, color: Colors.white60), overflow: TextOverflow.ellipsis)),
                    ]),
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
          child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 14, color: isActive ? accentColor : Colors.white.withOpacity(0.5))),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4))),
          ]),
        ),
      ),
    );
  }
}
