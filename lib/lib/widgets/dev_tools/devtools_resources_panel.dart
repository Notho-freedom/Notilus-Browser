/// Panneau Resources du DevTools Notilus
/// Visualisateur complet des ressources de la page
library devtools_resources_panel;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/devtools_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/gx_notification_service.dart';

/// Types de ressources
enum ResourceType { 
  document, script, stylesheet, image, font, media, xhr, fetch, websocket, manifest, other 
}

extension ResourceTypeExt on ResourceType {
  String get label {
    switch (this) {
      case ResourceType.document: return 'Document';
      case ResourceType.script: return 'Script';
      case ResourceType.stylesheet: return 'Stylesheet';
      case ResourceType.image: return 'Image';
      case ResourceType.font: return 'Font';
      case ResourceType.media: return 'Media';
      case ResourceType.xhr: return 'XHR';
      case ResourceType.fetch: return 'Fetch';
      case ResourceType.websocket: return 'WS';
      case ResourceType.manifest: return 'Manifest';
      case ResourceType.other: return 'Other';
    }
  }
  
  IconData get icon {
    switch (this) {
      case ResourceType.document: return Icons.description;
      case ResourceType.script: return Icons.code;
      case ResourceType.stylesheet: return Icons.style;
      case ResourceType.image: return Icons.image;
      case ResourceType.font: return Icons.font_download;
      case ResourceType.media: return Icons.movie;
      case ResourceType.xhr: return Icons.swap_horiz;
      case ResourceType.fetch: return Icons.cloud_download;
      case ResourceType.websocket: return Icons.cable;
      case ResourceType.manifest: return Icons.list_alt;
      case ResourceType.other: return Icons.insert_drive_file;
    }
  }
  
  Color get color {
    switch (this) {
      case ResourceType.document: return const Color(0xFF64B5F6);
      case ResourceType.script: return const Color(0xFFFFD54F);
      case ResourceType.stylesheet: return const Color(0xFF81C784);
      case ResourceType.image: return const Color(0xFFBA68C8);
      case ResourceType.font: return const Color(0xFF4DD0E1);
      case ResourceType.media: return const Color(0xFFFF8A65);
      case ResourceType.xhr: return const Color(0xFFA1887F);
      case ResourceType.fetch: return const Color(0xFF90A4AE);
      case ResourceType.websocket: return const Color(0xFFE57373);
      case ResourceType.manifest: return const Color(0xFFAED581);
      case ResourceType.other: return const Color(0xFF9E9E9E);
    }
  }
}

/// Modèle de ressource
class PageResource {
  final String id;
  final String url;
  final String name;
  final ResourceType type;
  final int? size;
  final double? loadTime;
  final int? statusCode;
  final String? mimeType;
  final String? initiator;
  final DateTime timestamp;
  final bool fromCache;
  final Map<String, String>? headers;
  String? _preview;
  
  PageResource({
    required this.id,
    required this.url,
    required this.name,
    required this.type,
    this.size,
    this.loadTime,
    this.statusCode,
    this.mimeType,
    this.initiator,
    required this.timestamp,
    this.fromCache = false,
    this.headers,
  });
  
  String get formattedSize {
    if (size == null) return '-';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  String get formattedLoadTime {
    if (loadTime == null) return '-';
    if (loadTime! < 1000) return '${loadTime!.toStringAsFixed(0)} ms';
    return '${(loadTime! / 1000).toStringAsFixed(2)} s';
  }
  
  String? get preview => _preview;
  set preview(String? value) => _preview = value;
}

class DevToolsResourcesPanel extends StatefulWidget {
  const DevToolsResourcesPanel({super.key});

  @override
  State<DevToolsResourcesPanel> createState() => _DevToolsResourcesPanelState();
}

class _DevToolsResourcesPanelState extends State<DevToolsResourcesPanel> {
  List<PageResource> _resources = [];
  PageResource? _selectedResource;
  bool _isLoading = false;
  Set<ResourceType> _visibleTypes = ResourceType.values.toSet();
  String _searchQuery = '';
  String _sortBy = 'time'; // time, size, name, type
  bool _sortAscending = false;
  
  // Vue
  bool _showFrames = true;
  bool _showTree = false;
  String? _selectedFrame;
  
  @override
  void initState() {
    super.initState();
    _loadResources();
  }
  
  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    
    final devTools = context.read<DevToolsService>();
    try {
      final result = await devTools.executeScript('''
        (function() {
          const resources = [];
          const entries = performance.getEntriesByType('resource');
          
          entries.forEach((entry, index) => {
            const url = entry.name;
            const name = url.split('/').pop().split('?')[0] || url;
            let type = 'other';
            
            if (entry.initiatorType === 'script' || url.endsWith('.js')) type = 'script';
            else if (entry.initiatorType === 'link' || entry.initiatorType === 'css' || url.endsWith('.css')) type = 'stylesheet';
            else if (entry.initiatorType === 'img' || /\\.(png|jpg|jpeg|gif|svg|webp|ico)\$/i.test(url)) type = 'image';
            else if (/\\.(woff2?|ttf|otf|eot)\$/i.test(url)) type = 'font';
            else if (/\\.(mp4|webm|mp3|wav|ogg)\$/i.test(url)) type = 'media';
            else if (entry.initiatorType === 'xmlhttprequest') type = 'xhr';
            else if (entry.initiatorType === 'fetch') type = 'fetch';
            else if (url.includes('manifest')) type = 'manifest';
            else if (entry.initiatorType === 'document') type = 'document';
            
            resources.push({
              id: 'res_' + index,
              url: url,
              name: name,
              type: type,
              size: entry.transferSize || entry.encodedBodySize || null,
              loadTime: entry.duration,
              initiator: entry.initiatorType,
              timestamp: entry.startTime,
              fromCache: entry.transferSize === 0 && entry.encodedBodySize > 0,
            });
          });
          
          // Ajouter le document principal
          const navEntry = performance.getEntriesByType('navigation')[0];
          if (navEntry) {
            resources.unshift({
              id: 'res_nav',
              url: location.href,
              name: document.title || location.pathname,
              type: 'document',
              size: navEntry.transferSize,
              loadTime: navEntry.duration,
              initiator: 'navigation',
              timestamp: 0,
              fromCache: false,
            });
          }
          
          return JSON.stringify(resources);
        })();
      ''');
      
      if (result != null && mounted) {
        final List<dynamic> data = jsonDecode(result);
        setState(() {
          _resources = data.map((r) => PageResource(
            id: r['id'] ?? '',
            url: r['url'] ?? '',
            name: r['name'] ?? 'Unknown',
            type: ResourceType.values.firstWhere(
              (t) => t.name == r['type'],
              orElse: () => ResourceType.other,
            ),
            size: r['size']?.toInt(),
            loadTime: r['loadTime']?.toDouble(),
            initiator: r['initiator'],
            timestamp: DateTime.now().subtract(Duration(milliseconds: (r['timestamp'] ?? 0).toInt())),
            fromCache: r['fromCache'] ?? false,
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading resources: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  List<PageResource> get _filteredResources {
    var list = _resources.where((r) => _visibleTypes.contains(r.type)).toList();
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((r) => 
        r.name.toLowerCase().contains(query) || 
        r.url.toLowerCase().contains(query)
      ).toList();
    }
    
    // Tri
    list.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'size':
          result = (a.size ?? 0).compareTo(b.size ?? 0);
          break;
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'type':
          result = a.type.index.compareTo(b.type.index);
          break;
        case 'time':
        default:
          result = (a.loadTime ?? 0).compareTo(b.loadTime ?? 0);
      }
      return _sortAscending ? result : -result;
    });
    
    return list;
  }
  
  Map<ResourceType, List<PageResource>> get _groupedResources {
    final map = <ResourceType, List<PageResource>>{};
    for (final resource in _filteredResources) {
      map.putIfAbsent(resource.type, () => []).add(resource);
    }
    return map;
  }
  
  int get _totalSize => _resources.fold(0, (sum, r) => sum + (r.size ?? 0));
  
  Future<void> _previewResource(PageResource resource) async {
    if (resource.type == ResourceType.image) {
      setState(() => _selectedResource = resource);
      return;
    }
    
    final devTools = context.read<DevToolsService>();
    try {
      final content = await devTools.executeScript('''
        (async function() {
          try {
            const response = await fetch('${resource.url}');
            const text = await response.text();
            return text.substring(0, 5000);
          } catch (e) {
            return 'Error: ' + e.message;
          }
        })();
      ''');
      
      if (content != null && mounted) {
        resource.preview = content;
        setState(() => _selectedResource = resource);
      }
    } catch (e) {
      debugPrint('Error previewing resource: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          _buildToolbar(accentColor),
          _buildStats(accentColor),
          Expanded(
            child: Row(
              children: [
                // Liste des ressources
                Expanded(
                  flex: _selectedResource != null ? 1 : 2,
                  child: _isLoading
                      ? _buildLoading(accentColor)
                      : _filteredResources.isEmpty
                          ? _buildEmpty(accentColor)
                          : _showTree
                              ? _buildTreeView(accentColor)
                              : _buildListView(accentColor),
                ),
                
                // Preview
                if (_selectedResource != null) ...[
                  Container(width: 1, color: accentColor.withOpacity(0.2)),
                  Expanded(
                    flex: 1,
                    child: _buildPreview(_selectedResource!, accentColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolbar(Color accentColor) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          _ToolbarButton(icon: Icons.refresh, tooltip: 'Actualiser', accentColor: accentColor, onPressed: _loadResources),
          _ToolbarButton(
            icon: _showTree ? Icons.list : Icons.account_tree,
            tooltip: _showTree ? 'Vue liste' : 'Vue arbre',
            accentColor: accentColor,
            onPressed: () => setState(() => _showTree = !_showTree),
          ),
          
          Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.white12),
          
          // Filtres de type
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ResourceType.values.map((type) {
                  final count = _resources.where((r) => r.type == type).length;
                  if (count == 0) return const SizedBox.shrink();
                  final isSelected = _visibleTypes.contains(type);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _FilterChip(
                      icon: type.icon,
                      label: '${type.label} ($count)',
                      color: type.color,
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        if (isSelected) {
                          _visibleTypes.remove(type);
                        } else {
                          _visibleTypes.add(type);
                        }
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Recherche
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              decoration: InputDecoration(
                hintText: 'Filtrer...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 14, color: Colors.white.withOpacity(0.3)),
                prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 24),
                fillColor: Colors.transparent,
                filled: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStats(Color accentColor) {
    final totalSize = _totalSize;
    final cached = _resources.where((r) => r.fromCache).length;
    
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          _StatBadge(icon: Icons.folder, label: '${_filteredResources.length} ressources', color: accentColor),
          const SizedBox(width: 16),
          _StatBadge(icon: Icons.cloud_download, label: _formatSize(totalSize), color: Colors.blue),
          const SizedBox(width: 16),
          _StatBadge(icon: Icons.cached, label: '$cached from cache', color: Colors.green),
          const Spacer(),
          // Tri
          PopupMenuButton<String>(
            tooltip: 'Trier par',
            icon: Icon(Icons.sort, size: 14, color: Colors.white.withOpacity(0.5)),
            color: const Color(0xFF2D2D30),
            onSelected: (value) => setState(() {
              if (_sortBy == value) {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = value;
                _sortAscending = false;
              }
            }),
            itemBuilder: (ctx) => [
              _sortMenuItem('time', 'Temps de chargement'),
              _sortMenuItem('size', 'Taille'),
              _sortMenuItem('name', 'Nom'),
              _sortMenuItem('type', 'Type'),
            ],
          ),
        ],
      ),
    );
  }
  
  PopupMenuItem<String> _sortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.white70)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: _sortBy == value ? Colors.white : Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
  
  Widget _buildLoading(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
          const SizedBox(height: 12),
          Text('Chargement des ressources...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }
  
  Widget _buildEmpty(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 48, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text('Aucune ressource', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadResources,
            icon: Icon(Icons.refresh, size: 14, color: accentColor),
            label: Text('Actualiser', style: TextStyle(color: accentColor, fontSize: 11)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListView(Color accentColor) {
    final resources = _filteredResources;
    
    return Column(
      children: [
        // Header
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: const Color(0xFF252526),
          child: Row(
            children: [
              const SizedBox(width: 24),
              Expanded(flex: 3, child: Text('Nom', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5)))),
              SizedBox(width: 80, child: Text('Taille', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5)))),
              SizedBox(width: 80, child: Text('Temps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5)))),
              SizedBox(width: 60, child: Text('Cache', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5)))),
            ],
          ),
        ),
        
        // Liste
        Expanded(
          child: ListView.builder(
            itemCount: resources.length,
            itemBuilder: (ctx, index) {
              final resource = resources[index];
              final isSelected = _selectedResource?.id == resource.id;
              
              return _ResourceRow(
                resource: resource,
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () => _previewResource(resource),
                onCopyUrl: () {
                  Clipboard.setData(ClipboardData(text: resource.url));
                  GxNotificationService().showSuccess(
                    title: 'Copié',
                    message: 'URL copiée',
                    context: context,
                    duration: const Duration(seconds: 1),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTreeView(Color accentColor) {
    final grouped = _groupedResources;
    
    return ListView(
      padding: const EdgeInsets.all(8),
      children: grouped.entries.map((entry) {
        final type = entry.key;
        final resources = entry.value;
        final totalSize = resources.fold<int>(0, (sum, r) => sum + (r.size ?? 0));
        
        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Icon(type.icon, size: 16, color: type.color),
          title: Text(
            '${type.label} (${resources.length})',
            style: TextStyle(fontSize: 11, color: type.color, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(_formatSize(totalSize), style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
          initiallyExpanded: true,
          children: resources.map((r) => ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 40, right: 12),
            leading: Icon(type.icon, size: 14, color: type.color.withOpacity(0.7)),
            title: Text(r.name, style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
            subtitle: Text(r.formattedSize, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
            trailing: r.fromCache 
                ? Icon(Icons.cached, size: 12, color: Colors.green.withOpacity(0.7))
                : null,
            onTap: () => _previewResource(r),
          )).toList(),
        );
      }).toList(),
    );
  }
  
  Widget _buildPreview(PageResource resource, Color accentColor) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252526),
              border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(resource.type.icon, size: 14, color: resource.type.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(resource.name, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: () {
                    // Ouvrir dans un nouvel onglet
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Ouvrir',
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: () => setState(() => _selectedResource = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          
          // Infos
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white.withOpacity(0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('URL', resource.url, accentColor),
                _InfoRow('Type', resource.type.label, accentColor),
                _InfoRow('Taille', resource.formattedSize, accentColor),
                _InfoRow('Temps', resource.formattedLoadTime, accentColor),
                if (resource.initiator != null)
                  _InfoRow('Initiateur', resource.initiator!, accentColor),
                _InfoRow('Cache', resource.fromCache ? 'Oui' : 'Non', accentColor),
              ],
            ),
          ),
          
          // Preview content
          Expanded(
            child: _buildResourceContent(resource, accentColor),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResourceContent(PageResource resource, Color accentColor) {
    if (resource.type == ResourceType.image) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Image.network(
            resource.url,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: accentColor,
              );
            },
            errorBuilder: (ctx, error, stack) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.red.withOpacity(0.5)),
                const SizedBox(height: 8),
                Text('Impossible de charger l\'image', style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
        ),
      );
    }
    
    final preview = resource.preview;
    if (preview == null) {
      return Center(
        child: TextButton.icon(
          onPressed: () => _previewResource(resource),
          icon: Icon(Icons.visibility, size: 14, color: accentColor),
          label: Text('Charger le contenu', style: TextStyle(color: accentColor, fontSize: 11)),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          preview,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'JetBrains Mono',
            height: 1.5,
          ),
        ),
      ),
    );
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

// === WIDGETS ===

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

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.icon, required this.label, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isSelected ? color.withOpacity(0.5) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: isSelected ? color : Colors.white.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 9, color: isSelected ? color : Colors.white.withOpacity(0.4))),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final PageResource resource;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onCopyUrl;

  const _ResourceRow({
    required this.resource,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.onCopyUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onSecondaryTap: onCopyUrl,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
          ),
          child: Row(
            children: [
              Icon(resource.type.icon, size: 14, color: resource.type.color),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Tooltip(
                  message: resource.url,
                  child: Text(
                    resource.name,
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(resource.formattedSize, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontFamily: 'JetBrains Mono')),
              ),
              SizedBox(
                width: 80,
                child: Text(resource.formattedLoadTime, style: TextStyle(fontSize: 10, color: _getTimeColor(resource.loadTime), fontFamily: 'JetBrains Mono')),
              ),
              SizedBox(
                width: 60,
                child: resource.fromCache 
                    ? Icon(Icons.cached, size: 12, color: Colors.green.withOpacity(0.7))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTimeColor(double? time) {
    if (time == null) return Colors.white.withOpacity(0.5);
    if (time < 100) return const Color(0xFF4CAF50);
    if (time < 500) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _InfoRow(this.label, this.value, this.accentColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'JetBrains Mono'),
            ),
          ),
        ],
      ),
    );
  }
}

