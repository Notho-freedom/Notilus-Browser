/// Menu popup pour les téléchargements
library downloads_popup_menu;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/download_service.dart';
import '../../models/download_model.dart';
import '../common/gx_futuristic_components.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/gx_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

/// Menu popup compact pour afficher les téléchargements
class DownloadsPopupMenu extends StatelessWidget {
  const DownloadsPopupMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;
    
    return Consumer<DownloadService>(
      builder: (context, downloadService, _) {
        final downloads = downloadService.downloads;
        final activeDownloads = downloads.where((d) => 
          d.status == DownloadStatus.downloading || 
          d.status == DownloadStatus.pending
        ).toList();
        
        return Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.tray_arrow_down, color: accentColor, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Téléchargements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (downloads.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Ouvrir le panel complet
                          // TODO: Ouvrir le panel complet si nécessaire
                        },
                        child: Text(
                          'Voir tout',
                          style: TextStyle(color: accentColor, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // Liste des téléchargements
              Flexible(
                child: downloads.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_down_circle,
                              size: 48,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun téléchargement',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: downloads.length > 5 ? 5 : downloads.length,
                        itemBuilder: (context, index) {
                          final download = downloads[index];
                          return _DownloadItem(
                            download: download,
                            accentColor: accentColor,
                            onOpen: () {
                              if (download.filePath != null) {
                                final file = File(download.filePath!);
                                if (file.existsSync()) {
                                  final uri = Uri.file(download.filePath!);
                                  launchUrl(uri);
                                }
                              }
                            },
                            onCancel: () {
                              downloadService.cancelDownload(download.id);
                            },
                            onRemove: () {
                              downloadService.removeDownload(download.id);
                            },
                          );
                        },
                      ),
              ),
              if (downloads.length > 5)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${downloads.length - 5} téléchargement(s) supplémentaire(s)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadItem extends StatelessWidget {
  final DownloadModel download;
  final Color accentColor;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const _DownloadItem({
    required this.download,
    required this.accentColor,
    required this.onOpen,
    required this.onCancel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = download.status == DownloadStatus.downloading || 
                     download.status == DownloadStatus.pending;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  download.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, size: 16),
                  color: accentColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onCancel,
                )
              else if (download.status == DownloadStatus.completed)
                IconButton(
                  icon: const Icon(CupertinoIcons.check_mark, size: 16),
                  color: Colors.green,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onOpen,
                )
              else
                IconButton(
                  icon: const Icon(CupertinoIcons.delete, size: 16),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onRemove,
                ),
            ],
          ),
          if (isActive && download.progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: download.progress! / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${download.progress!.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

