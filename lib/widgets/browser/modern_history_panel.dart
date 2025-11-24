import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/history_service.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';

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
            Colors.black.withOpacity(0.8),
            BlendMode.srcOver,
          ),
        ),
      ),
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
                  'Historique',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await _historyService.clearHistory();
                    await _refresh();
                  },
                  child: const Text('Tout effacer'),
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
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}


