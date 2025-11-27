import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../common/gx_futuristic_widgets.dart';
import '../../services/download_service.dart';
import '../../models/download_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ModernDownloadsPanel extends StatelessWidget {
  const ModernDownloadsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(context.watch<WallpaperManager>().current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Consumer<DownloadService>(
          builder: (context, downloadService, _) {
            final downloads = downloadService.downloads;
            
            return Column(
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
                      if (downloads.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Supprimer tous les téléchargements terminés
                            for (final download in downloads) {
                              if (download.status == DownloadStatus.completed ||
                                  download.status == DownloadStatus.failed ||
                                  download.status == DownloadStatus.cancelled) {
                                downloadService.removeDownload(download.id);
                              }
                            }
                          },
                          child: const Text('Effacer terminés'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: downloads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_outlined,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun téléchargement',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Les fichiers téléchargés apparaîtront ici',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          itemCount: downloads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final download = downloads[index];
                            return _DownloadItem(
                              download: download,
                              onCancel: () => downloadService.cancelDownload(download.id),
                              onRemove: () => downloadService.removeDownload(download.id),
                              onOpen: () => downloadService.openDownload(download.id),
                              gxRed: gxRed,
                            );
                          },
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

class _DownloadItem extends StatelessWidget {
  final DownloadModel download;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onOpen;
  final Color gxRed;

  const _DownloadItem({
    required this.download,
    required this.onCancel,
    required this.onRemove,
    required this.onOpen,
    required this.gxRed,
  });

  IconData _getStatusIcon() {
    switch (download.status) {
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.cancelled:
        return Icons.cancel;
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.paused:
        return Icons.pause_circle;
      case DownloadStatus.pending:
        return Icons.pending;
    }
  }

  Color _getStatusColor() {
    switch (download.status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.orange;
      case DownloadStatus.downloading:
        return gxRed;
      case DownloadStatus.paused:
        return Colors.yellow;
      case DownloadStatus.pending:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  statusIcon,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      download.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (download.status == DownloadStatus.downloading)
                          Expanded(
                            child: LinearProgressIndicator(
                              value: download.progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(gxRed),
                              minHeight: 2,
                            ),
                          )
                        else
                          Text(
                            download.progressText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (download.status == DownloadStatus.downloading)
                IconButton(
                  icon: const Icon(Icons.cancel, size: 18),
                  onPressed: onCancel,
                  tooltip: 'Annuler',
                  color: Colors.white.withValues(alpha: 0.7),
                )
              else if (download.status == DownloadStatus.completed)
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () async {
                    if (download.filePath != null) {
                      final file = File(download.filePath!);
                      if (await file.exists()) {
                        // Ouvrir le fichier avec l'application par défaut
                        final uri = Uri.file(download.filePath!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    }
                  },
                  tooltip: 'Ouvrir',
                  color: gxRed,
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onRemove,
                tooltip: 'Supprimer',
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          if (download.error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Erreur: ${download.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.red.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
