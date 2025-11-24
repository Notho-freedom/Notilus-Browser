import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/tab_manager.dart';

class ModernDownloadsPanel extends StatefulWidget {
  const ModernDownloadsPanel({super.key});

  @override
  State<ModernDownloadsPanel> createState() => _ModernDownloadsPanelState();
}

class _ModernDownloadsPanelState extends State<ModernDownloadsPanel> {
  final List<_LocalDownload> _downloads = [];
  int _counter = 1;

  @override
  void initState() {
    super.initState();
  }

  void _addMockDownload() {
    setState(() {
      _downloads.insert(
        0,
        _LocalDownload(
          fileName: 'archive_${_counter.toString().padLeft(2, '0')}.zip',
          url: 'https://example.com/download/$_counter',
          sizeLabel: '${(Random().nextInt(900) + 100)} Mo',
          status: 'Terminé',
        ),
      );
      _counter++;
    });
  }

  void _clearDownloads() {
    setState(() {
      _downloads.clear();
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
                  Expanded(
                    child: Text(
                      'Téléchargements',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _downloads.isEmpty ? null : _clearDownloads,
                    child: const Text('Effacer'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _addMockDownload,
                    icon: const Icon(Icons.download, size: 18),
                    tooltip: 'Simuler un téléchargement',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _downloads.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun téléchargement pour le moment',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: _downloads.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _downloads[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.file_download,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            item.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(
                            '${item.sizeLabel} • ${item.status}',
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalDownload {
  final String fileName;
  final String url;
  final String sizeLabel;
  final String status;

  _LocalDownload({
    required this.fileName,
    required this.url,
    required this.sizeLabel,
    required this.status,
  });
}


