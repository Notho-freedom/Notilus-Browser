import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bookmark_service.dart';
import '../../models/bookmark.dart';
import '../../services/tab_manager.dart';
import '../common/animated_wallpaper_background.dart';

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

    return AnimatedWallpaperBackground(
      darkness: 0.8,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Text(
                  'Favoris',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return ListTile(
                        dense: true,
                        leading: bookmark.favicon != null
                            ? Image.network(
                                bookmark.favicon!,
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.bookmark,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.bookmark,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                        title: Text(
                          bookmark.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          bookmark.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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


