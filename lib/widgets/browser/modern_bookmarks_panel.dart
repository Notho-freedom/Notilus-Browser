import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bookmark_service.dart';
import '../../models/bookmark.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';

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
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Ajouter un favori',
                  onPressed: () async {
                    final tabManager = Provider.of<TabManager>(context, listen: false);
                    final activeTab = tabManager.activeTab;
                    if (activeTab?.url != null && !activeTab!.url!.startsWith('about:')) {
                      // TODO: Ajouter le favori
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


