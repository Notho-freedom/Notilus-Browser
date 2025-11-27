import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/history_service.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/favicon_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../common/gx_futuristic_widgets.dart';

class ModernHistoryPanel extends StatefulWidget {
  const ModernHistoryPanel({super.key});

  @override
  State<ModernHistoryPanel> createState() => _ModernHistoryPanelState();
}

class _ModernHistoryPanelState extends State<ModernHistoryPanel> {
  final HistoryService _historyService = HistoryService();
  late Future _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.getHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _historyService.getHistory();
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
                  'Historique',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await _historyService.clearHistory();
                    await _refresh();
                  },
                  child: Text(
                    'Effacer',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data as List<dynamic>? ?? [];

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun historique pour le moment',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    );
                  }

                  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FutureBuilder<String?>(
                        future: FaviconService.getFaviconWithCache(item.url),
                        builder: (context, faviconSnapshot) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Builder(
                              builder: (context) {
                                final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
                                return faviconSnapshot.hasData && faviconSnapshot.data != null
                                    ? Image.network(
                                        faviconSnapshot.data!,
                                        width: 18,
                                        height: 18,
                                        errorBuilder: (_, __, ___) => Icon(
                                          CupertinoIcons.globe,
                                          size: 18,
                                          color: gxRed,
                                        ),
                                      )
                                    : Icon(
                                        CupertinoIcons.globe,
                                        size: 18,
                                        color: gxRed,
                                      );
                              },
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              item.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              onPressed: () {
                                final tabManager =
                                    Provider.of<TabManager>(context, listen: false);
                                tabManager.addTab(url: item.url);
                              },
                            ),
                            onTap: () {
                              final tabManager =
                                  Provider.of<TabManager>(context, listen: false);
                              tabManager.addTab(url: item.url);
                            },
                          );
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


