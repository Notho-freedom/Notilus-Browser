/// Panel de favoris futuriste Notilus GX
library gx_futuristic_bookmarks_panel;

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

class GxFuturisticBookmarksPanel extends StatefulWidget {
  const GxFuturisticBookmarksPanel({super.key});

  @override
  State<GxFuturisticBookmarksPanel> createState() => _GxFuturisticBookmarksPanelState();
}

class _GxFuturisticBookmarksPanelState extends State<GxFuturisticBookmarksPanel> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<List<Bookmark>> _bookmarksFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _bookmarkService.getBookmarks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _bookmarksFuture = _bookmarkService.getBookmarks();
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
        tags: (result['tags'] as String?)?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [],
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

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.bookmark_fill,
                        color: accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'FAVORIS',
                        style: NotilusFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      GxFuturisticButton(
                        label: 'Ajouter',
                        icon: CupertinoIcons.add_circled,
                        variant: GxFuturisticButtonVariant.primary,
                        accentColor: accentColor,
                        onPressed: _addBookmark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Barre de recherche
                  GxFuturisticInput(
                    controller: _searchController,
                    hint: 'Rechercher dans les favoris...',
                    prefixIcon: CupertinoIcons.search,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
            
            // Liste
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
                    final filteredBookmarks = _searchQuery.isEmpty
                        ? bookmarks
                        : bookmarks.where((bookmark) {
                            return bookmark.title.toLowerCase().contains(_searchQuery) ||
                                   bookmark.url.toLowerCase().contains(_searchQuery) ||
                                   (bookmark.description?.toLowerCase().contains(_searchQuery) ?? false) ||
                                   bookmark.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
                          }).toList();

                    if (filteredBookmarks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.bookmark,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun favori'
                                  : 'Aucun résultat',
                              style: NotilusFonts.rajdhani(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Ajoutez des favoris pour y accéder rapidement'
                                  : 'Aucun favori ne correspond à votre recherche',
                              style: NotilusFonts.rajdhani(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filteredBookmarks.length,
                      separatorBuilder: (_, __) => GxFuturisticDivider(
                        accentColor: accentColor,
                        height: 0.5,
                      ),
                      itemBuilder: (context, index) {
                        final bookmark = filteredBookmarks[index];
                        return _BookmarkListItem(
                          bookmark: bookmark,
                          accentColor: accentColor,
                          bgColor: bgColor,
                          panelOpacity: panelOpacity,
                          onTap: () {
                            final tabManager = Provider.of<TabManager>(context, listen: false);
                            tabManager.addTab(url: bookmark.url);
                          },
                          onDelete: () => _deleteBookmark(bookmark),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkListItem extends StatelessWidget {
  final Bookmark bookmark;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkListItem({
    required this.bookmark,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GxFuturisticListItem(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: bookmark.favicon != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  bookmark.favicon!,
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => Icon(
                    CupertinoIcons.bookmark_fill,
                    size: 18,
                    color: accentColor,
                  ),
                ),
              )
            : Icon(
                CupertinoIcons.bookmark_fill,
                size: 18,
                color: accentColor,
              ),
      ),
      title: Text(
        bookmark.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: NotilusFonts.rajdhani(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bookmark.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NotilusFonts.rajdhani(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          if (bookmark.description != null && bookmark.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bookmark.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NotilusFonts.rajdhani(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
          if (bookmark.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: bookmark.tags.take(3).map((tag) {
                return GxFuturisticChip(
                  label: tag,
                  icon: CupertinoIcons.tag,
                  accentColor: accentColor,
                );
              }).toList(),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GxFuturisticButton(
            label: '',
            icon: CupertinoIcons.arrow_right,
            variant: GxFuturisticButtonVariant.ghost,
            accentColor: accentColor,
            width: 32,
            height: 32,
            padding: EdgeInsets.zero,
            onPressed: onTap,
          ),
          const SizedBox(width: 8),
          GxFuturisticButton(
            label: '',
            icon: CupertinoIcons.delete,
            variant: GxFuturisticButtonVariant.ghost,
            accentColor: const Color(0xFFFF453A),
            width: 32,
            height: 32,
            padding: EdgeInsets.zero,
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
      accentColor: accentColor,
    );
  }
}

