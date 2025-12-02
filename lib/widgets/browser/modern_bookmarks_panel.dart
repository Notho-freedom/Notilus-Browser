import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/bookmark_service.dart';
import '../../models/bookmark.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

class ModernBookmarksPanel extends StatefulWidget {
  const ModernBookmarksPanel({super.key});

  @override
  State<ModernBookmarksPanel> createState() => _ModernBookmarksPanelState();
}

class _ModernBookmarksPanelState extends State<ModernBookmarksPanel> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<List<Bookmark>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _bookmarkService.getBookmarks();
  }

  Future<void> _refresh() async {
    setState(() {
      _bookmarksFuture = _bookmarkService.getBookmarks();
    });
  }

  Future<Map<String, String>?> _showAddBookmarkDialog(
    BuildContext context,
    String initialTitle,
    String url,
    String? favicon,
    Color accentColor,
  ) {
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController();
    final tagsController = TextEditingController();

    return GxFuturisticDialog.show<Map<String, String>>(
      context: context,
      title: 'Ajouter aux favoris',
      titleIcon: CupertinoIcons.bookmark_fill,
      accentColor: accentColor,
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (favicon != null)
            Row(
              children: [
                Image.network(
                  favicon,
                  width: 24,
                  height: 24,
                  errorBuilder: (_, __, ___) => Icon(CupertinoIcons.bookmark_fill, color: accentColor, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              url,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Titre',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (optionnel)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tagsController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Tags (séparés par virgule)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              hintText: 'ex: travail, dev, docs',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ],
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.pop(context),
        ),
        GxFuturisticButton(
          label: 'Ajouter',
          icon: CupertinoIcons.bookmark_fill,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
          onPressed: () {
            Navigator.pop(context, {
              'title': titleController.text,
              'description': descController.text,
              'tags': tagsController.text,
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(context.watch<WallpaperManager>().current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Text(
                  'Favoris',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, size: 18, color: Provider.of<ColorThemeManager>(context).nativeSecondaryColor),
                  tooltip: 'Ajouter un favori',
                  onPressed: () async {
                    final tabManager = Provider.of<TabManager>(context, listen: false);
                    final activeTab = tabManager.activeTab;
                    final accentColor = Provider.of<ColorThemeManager>(context, listen: false).nativeSecondaryColor;
                    
                    if (activeTab?.url != null && !activeTab!.url!.startsWith('about:')) {
                      // Afficher un dialogue d'édition
                      final result = await _showAddBookmarkDialog(
                        context, 
                        activeTab.title ?? 'Sans titre',
                        activeTab.url!,
                        activeTab.favicon,
                        accentColor,
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
                            title: 'Favoris',
                            message: 'Favori ajouté',
                            context: context,
                          );
                        }
                      }
                    } else {
                      GxNotificationService().showWarning(
                        title: 'Avertissement',
                        message: 'Aucune page à ajouter aux favoris',
                        context: context,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Bookmark>>(
                future: _bookmarksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookmarks = snapshot.data ?? [];

                  if (bookmarks.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun favori pour le moment',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: bookmark.favicon != null
                            ? Image.network(
                                bookmark.favicon!,
                                width: 18,
                                height: 18,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.bookmark,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.bookmark,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                        title: Text(
                          bookmark.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          bookmark.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () async {
                            await _bookmarkService.removeBookmark(bookmark.id);
                            await _refresh();
                          },
                        ),
                        onTap: () {
                          final tabManager =
                              Provider.of<TabManager>(context, listen: false);
                          tabManager.addTab(url: bookmark.url);
                        },
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


