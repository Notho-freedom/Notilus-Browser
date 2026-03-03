/// Panel de favoris futuriste Notilus GX
library gx_futuristic_bookmarks_panel;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/bookmark_service.dart';
import '../../models/bookmark.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../common/gx_futuristic_components.dart';
import '../common/gx_futuristic_dialog.dart';
import '../../services/gx_notification_service.dart';
import '../../services/favicon_service.dart';

class GxFuturisticBookmarksPanel extends StatefulWidget {
  const GxFuturisticBookmarksPanel({super.key});

  @override
  State<GxFuturisticBookmarksPanel> createState() => _GxFuturisticBookmarksPanelState();
}

class _GxFuturisticBookmarksPanelState extends State<GxFuturisticBookmarksPanel> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<List<Bookmark>> _bookmarksFuture;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedDomainFilter = 'Tous';
  
  // Cache pour optimiser les performances
  Timer? _searchDebounceTimer;
  List<Bookmark>? _cachedFilteredBookmarks;
  List<String>? _cachedSortedDomains;
  String? _lastSearchQuery;
  
  String _extractDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        return uri.host.replaceFirst(RegExp(r'^www\.'), '');
      }
    } catch (_) {}
    return 'unknown';
  }

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _bookmarkService.getBookmarks();
    _searchController.addListener(_onSearchChanged);
  }
  
  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
          // Invalider le cache
                          _cachedFilteredBookmarks = null;
                          _cachedSortedDomains = null;
                        });
                      }
                    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _bookmarksFuture = _bookmarkService.getBookmarks();
      // Invalider le cache
      _cachedFilteredBookmarks = null;
    });
  }

  Future<void> _addBookmark() async {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final activeTab = tabManager.activeTab;
    final accentColor = NotilusColors.getSecondaryColor(context);
    
    if (activeTab?.url == null || activeTab!.url!.startsWith('about:')) {
      GxNotificationService().showWarning(
        title: 'Impossible d\'ajouter',
        message: 'Aucune page valide à ajouter aux favoris',
        context: context,
      );
      return;
    }

    final titleController = TextEditingController(text: activeTab.title ?? 'Sans titre');
    final descController = TextEditingController();
    final tagsController = TextEditingController();

    final result = await GxFuturisticDialog.show<Map<String, String>>(
      context: context,
      title: 'Ajouter aux favoris',
      titleIcon: CupertinoIcons.bookmark_fill,
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GxFuturisticLabel(
            text: 'URL',
            icon: CupertinoIcons.globe,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              activeTab.url!,
              style: NotilusFonts.rajdhani(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          GxFuturisticInput(
            controller: titleController,
            label: 'Titre',
            hint: 'Titre du favori',
            prefixIcon: CupertinoIcons.textformat,
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          GxFuturisticTextArea(
            controller: descController,
            label: 'Description',
            hint: 'Description (optionnel)',
            minLines: 2,
            maxLines: 3,
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          GxFuturisticInput(
            controller: tagsController,
            label: 'Tags',
            hint: 'ex: travail, dev, docs',
            prefixIcon: CupertinoIcons.tag,
            accentColor: accentColor,
          ),
        ],
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GxFuturisticButton(
          label: 'Ajouter',
          icon: CupertinoIcons.check_mark,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
          onPressed: () => Navigator.of(context).pop({
            'title': titleController.text,
            'description': descController.text,
            'tags': tagsController.text,
          }),
        ),
      ],
    );

    if (result != null) {
      final bookmark = Bookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result['title'] ?? activeTab.title ?? 'Sans titre',
        url: activeTab.url!,
        favicon: activeTab.favicon,
        description: result['description'],
        tags: result['tags'] != null 
            ? (result['tags'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : [],
        createdAt: DateTime.now(),
      );
      await _bookmarkService.addBookmark(bookmark);
      await _refresh();
      if (mounted) {
        GxNotificationService().showSuccess(
          title: 'Favori ajouté',
          message: 'Le favori a été ajouté avec succès',
          context: context,
        );
      }
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final result = await GxFuturisticDialog.show<bool>(
      context: context,
      title: 'Supprimer le favori',
      titleIcon: CupertinoIcons.delete,
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer "${bookmark.title}" ?',
            style: NotilusFonts.rajdhani(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        GxFuturisticButton(
          label: 'Supprimer',
          icon: CupertinoIcons.delete,
          variant: GxFuturisticButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (result == true) {
      await _bookmarkService.removeBookmark(bookmark.id);
      await _refresh();
      if (mounted) {
        GxNotificationService().showSuccess(
          title: 'Favori supprimé',
          message: 'Le favori a été supprimé',
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    final wallpaperManager = context.watch<WallpaperManager>();
    final wallpaperUrl = wallpaperManager.currentImageUrl;

    return Container(
      decoration: BoxDecoration(
        image: wallpaperUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(wallpaperUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Dimensions adaptatives selon la taille du panel
            final isCompact = constraints.maxWidth < 400;
            final isMedium = constraints.maxWidth >= 400 && constraints.maxWidth < 600;
            
            // Padding adaptatif
            final horizontalPadding = isCompact ? 12.0 : isMedium ? 16.0 : 24.0;
            final verticalPadding = isCompact ? 8.0 : isMedium ? 12.0 : 16.0;
            final itemSpacing = isCompact ? 6.0 : isMedium ? 8.0 : 12.0;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header compact (sans titre répété)
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, itemSpacing),
                  child: Row(
                    children: [
                      // Barre de recherche compacte
                      Expanded(
                        child: GxFuturisticInput(
                          controller: _searchController,
                          hint: isCompact ? 'Rechercher...' : 'Rechercher dans les favoris...',
                          prefixIcon: CupertinoIcons.search,
                          accentColor: accentColor,
                        ),
                      ),
                      SizedBox(width: itemSpacing),
                      // Bouton ajouter avec variant secondary et icône centrée
                      GxFuturisticButton(
                        label: isCompact ? '' : 'Ajouter',
                        icon: CupertinoIcons.add_circled,
                        variant: GxFuturisticButtonVariant.secondary,
                        accentColor: accentColor,
                        width: isCompact ? 36 : null,
                        height: isCompact ? 36 : null,
                        padding: isCompact ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onPressed: _addBookmark,
                      ),
                    ],
                  ),
                ),
                
                // Liste avec dimensions adaptatives
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: accentColor,
                    child: FutureBuilder<List<Bookmark>>(
                      future: _bookmarksFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: GxFuturisticSpinner(
                              accentColor: accentColor,
                              message: 'Chargement...',
                            ),
                          );
                        }

                        final bookmarks = snapshot.data ?? [];
                        
                        // Utiliser le cache si la recherche n'a pas changé
                        List<Bookmark> filteredBookmarks;
                        if (_cachedFilteredBookmarks != null && 
                            _lastSearchQuery == _searchQuery) {
                          filteredBookmarks = _cachedFilteredBookmarks!;
                        } else {
                          filteredBookmarks = _searchQuery.isEmpty
                              ? bookmarks
                              : bookmarks.where((bookmark) {
                                  final title = bookmark.title.toLowerCase();
                                  final url = bookmark.url.toLowerCase();
                                  final desc = (bookmark.description ?? '').toLowerCase();
                                  return title.contains(_searchQuery) ||
                                         url.contains(_searchQuery) ||
                                         desc.contains(_searchQuery) ||
                                         bookmark.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
                                }).toList();
                          _cachedFilteredBookmarks = filteredBookmarks;
                          _lastSearchQuery = _searchQuery;
                        }
                        
                        // Filtrer par domaine si sélectionné
                        if (_selectedDomainFilter != 'Tous') {
                          filteredBookmarks = filteredBookmarks.where((bookmark) {
                            final domain = _extractDomainFromUrl(bookmark.url);
                            return domain == _selectedDomainFilter;
                          }).toList();
                        }
                        
                        // Extraire les domaines uniques pour le filtre
                        List<String> sortedDomains;
                        if (_cachedSortedDomains != null && _lastSearchQuery == _searchQuery) {
                          sortedDomains = _cachedSortedDomains!;
                        } else {
                          final uniqueDomains = <String>{};
                          for (final bookmark in bookmarks) {
                            uniqueDomains.add(_extractDomainFromUrl(bookmark.url));
                          }
                          sortedDomains = uniqueDomains.toList()..sort();
                          _cachedSortedDomains = sortedDomains;
                        }

                        if (filteredBookmarks.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.bookmark,
                                  size: isCompact ? 48 : isMedium ? 56 : 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                SizedBox(height: isCompact ? 12 : 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Aucun favori'
                                      : 'Aucun résultat',
                                  style: NotilusFonts.rajdhani(
                                    fontSize: isCompact ? 13 : isMedium ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(height: isCompact ? 6 : 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Ajoutez des favoris pour y accéder rapidement'
                                      : 'Aucun favori ne correspond à votre recherche',
                                  style: NotilusFonts.rajdhani(
                                    fontSize: isCompact ? 10 : isMedium ? 11 : 12,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Utiliser ListView.builder pour virtualisation avec espacement comme historique
                        return Column(
                          children: [
                            // Filtres
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: itemSpacing),
                              child: Row(
                                children: [
                                  // Filtre par domaine
                                  Expanded(
                                    child: _FilterDropdown(
                                      label: 'Domaine',
                                      value: _selectedDomainFilter,
                                      items: ['Tous', ...sortedDomains],
                                      accentColor: accentColor,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDomainFilter = value ?? 'Tous';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Liste
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: itemSpacing,
                                ),
                                itemCount: filteredBookmarks.length,
                                cacheExtent: 500, // Cache optimisé
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                itemBuilder: (context, index) {
                                  final bookmark = filteredBookmarks[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: itemSpacing),
                                    child: RepaintBoundary(
                                      key: ValueKey('bookmark_${bookmark.id}'),
                                      child: _BookmarkListItem(
                                        bookmark: bookmark,
                                        accentColor: accentColor,
                                        bgColor: bgColor,
                                        panelOpacity: panelOpacity,
                                        isCompact: isCompact,
                                        isMedium: isMedium,
                                        onTap: () {
                                          final tabManager = Provider.of<TabManager>(context, listen: false);
                                          tabManager.addTab(url: bookmark.url);
                                        },
                                        onDelete: () => _deleteBookmark(bookmark),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Dropdown de filtre
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Color accentColor;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: NotilusFonts.rajdhani(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.black.withOpacity(0.85),
                style: NotilusFonts.rajdhani(
                  fontSize: 10,
                  color: Colors.white,
                ),
                icon: Icon(
                  CupertinoIcons.chevron_down,
                  size: 12,
                  color: accentColor,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(item),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkListItem extends StatefulWidget {
  final Bookmark bookmark;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final bool isCompact;
  final bool isMedium;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkListItem({
    required this.bookmark,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.isCompact,
    required this.isMedium,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_BookmarkListItem> createState() => _BookmarkListItemState();
}

class _BookmarkListItemState extends State<_BookmarkListItem> {
  bool _isHovered = false;
  bool _isPressed = false;
  
  /// Extrait le domaine de l'URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        return uri.host.replaceFirst(RegExp(r'^www\.'), '');
      }
    } catch (_) {}
    return url.length > 30 ? '${url.substring(0, 30)}...' : url;
  }

  @override
  Widget build(BuildContext context) {
    final domain = _extractDomain(widget.bookmark.url);
    final itemPadding = widget.isCompact ? 8.0 : widget.isMedium ? 10.0 : 12.0;
    final itemHorizontalPadding = widget.isCompact ? 12.0 : widget.isMedium ? 14.0 : 16.0;
    final faviconSize = widget.isCompact ? 20.0 : widget.isMedium ? 24.0 : 28.0;
    final titleFontSize = widget.isCompact ? 11.0 : widget.isMedium ? 12.0 : 13.0;
    final urlFontSize = widget.isCompact ? 9.0 : widget.isMedium ? 10.0 : 11.0;
    
    return FutureBuilder<String?>(
      future: FaviconService.getFaviconWithCache(widget.bookmark.url),
      builder: (context, faviconSnapshot) {
        return RepaintBoundary(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..scale(_isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0)),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.accentColor.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
                  border: _isHovered
                      ? Border(
                          left: BorderSide(
                            color: widget.accentColor,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: itemHorizontalPadding,
                    vertical: itemPadding,
                  ),
                  child: Row(
                    children: [
                      // Favicon avec animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: faviconSize + 8,
                        height: faviconSize + 8,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(
                            _isHovered ? 0.25 : 0.15,
                          ),
                          borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(
                              _isHovered ? 0.5 : 0.3,
                            ),
                            width: _isHovered ? 1.5 : 1,
                          ),
                        ),
                        child: faviconSnapshot.hasData && faviconSnapshot.data != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(widget.isCompact ? 4 : 6),
                                child: Image.network(
                                  faviconSnapshot.data!,
                                  width: faviconSize - 4,
                                  height: faviconSize - 4,
                                  errorBuilder: (_, __, ___) => Icon(
                                    CupertinoIcons.bookmark_fill,
                                    size: faviconSize - 6,
                                    color: widget.accentColor,
                                  ),
                                ),
                              )
                            : Icon(
                                CupertinoIcons.bookmark_fill,
                                size: faviconSize - 6,
                                color: widget.accentColor,
                              ),
                      ),
                      SizedBox(width: widget.isCompact ? 10 : 12),
                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Titre
                            Text(
                              widget.bookmark.title,
                              maxLines: widget.isCompact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: NotilusFonts.rajdhani(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: _isHovered
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.95),
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: widget.isCompact ? 2 : 4),
                            // Domaine
                            Text(
                              domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NotilusFonts.rajdhani(
                                fontSize: urlFontSize,
                                color: Colors.white.withOpacity(
                                  _isHovered ? 0.7 : 0.6,
                                ),
                              ),
                            ),
                            // Description si disponible
                            if (widget.bookmark.description != null && 
                                widget.bookmark.description!.isNotEmpty && 
                                !widget.isCompact) ...[
                              SizedBox(height: widget.isCompact ? 2 : 4),
                              Text(
                                widget.bookmark.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NotilusFonts.rajdhani(
                                  fontSize: urlFontSize - 1,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                            // Tags si disponibles
                            if (widget.bookmark.tags.isNotEmpty && !widget.isCompact) ...[
                              SizedBox(height: widget.isCompact ? 4 : 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: widget.bookmark.tags.take(3).map((tag) {
                                  return GxFuturisticChip(
                                    label: tag,
                                    icon: CupertinoIcons.tag,
                                    accentColor: widget.accentColor,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 8 : 12),
                      // Bouton action : flèche par défaut, X en hover pour supprimer
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()
                          ..translate(_isHovered ? 2.0 : 0.0),
                        child: GxFuturisticButton(
                          label: '',
                          icon: _isHovered
                              ? CupertinoIcons.xmark
                              : CupertinoIcons.chevron_right,
                          variant: GxFuturisticButtonVariant.ghost,
                          accentColor: _isHovered
                              ? const Color(0xFFEF4444)
                              : widget.accentColor,
                          width: widget.isCompact ? 28 : 32,
                          height: widget.isCompact ? 28 : 32,
                          padding: EdgeInsets.zero,
                          onPressed: _isHovered
                              ? widget.onDelete
                              : widget.onTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

