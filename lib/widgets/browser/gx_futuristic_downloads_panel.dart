/// Panel de téléchargements futuriste Notilus GX
library gx_futuristic_downloads_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/download_service.dart';
import '../../models/download_model.dart';
import '../../services/settings_service.dart';
import '../common/gx_futuristic_components.dart';
import '../common/gx_futuristic_dialog.dart';
import '../../services/gx_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class GxFuturisticDownloadsPanel extends StatelessWidget {
  const GxFuturisticDownloadsPanel({super.key});

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
        child: Consumer<DownloadService>(
          builder: (context, downloadService, _) {
            final downloads = downloadService.downloads;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_down_circle_fill,
                        color: accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TÉLÉCHARGEMENTS',
                        style: NotilusFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      if (downloads.isNotEmpty)
                        GxFuturisticButton(
                          label: 'Effacer terminés',
                          icon: CupertinoIcons.delete,
                          variant: GxFuturisticButtonVariant.outline,
                          accentColor: accentColor,
                          onPressed: () async {
                            for (final download in downloads) {
                              if (download.status == DownloadStatus.completed ||
                                  download.status == DownloadStatus.failed ||
                                  download.status == DownloadStatus.cancelled) {
                                downloadService.removeDownload(download.id);
                              }
                            }
                            GxNotificationService().showSuccess(
                              title: 'Nettoyage effectué',
                              message: 'Les téléchargements terminés ont été supprimés',
                              context: context,
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                // Liste
                Expanded(
                  child: downloads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.arrow_down_circle,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun téléchargement',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Les fichiers téléchargés apparaîtront ici',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: downloads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final download = downloads[index];
                            return RepaintBoundary(
                              child: _DownloadListItem(
                                download: download,
                                accentColor: accentColor,
                                bgColor: bgColor,
                                panelOpacity: panelOpacity,
                                onCancel: () => downloadService.cancelDownload(download.id),
                                onRemove: () => downloadService.removeDownload(download.id),
                                onOpen: () async {
                                  if (download.filePath != null) {
                                    final file = File(download.filePath!);
                                    if (await file.exists()) {
                                      final uri = Uri.file(download.filePath!);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    }
                                  }
                                },
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
    );
  }
}

class _DownloadListItem extends StatelessWidget {
  final DownloadModel download;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const _DownloadListItem({
    required this.download,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.onCancel,
    required this.onRemove,
    required this.onOpen,
  });

  IconData _getStatusIcon() {
    switch (download.status) {
      case DownloadStatus.completed:
        return CupertinoIcons.checkmark_circle_fill;
      case DownloadStatus.failed:
        return CupertinoIcons.xmark_circle_fill;
      case DownloadStatus.cancelled:
        return CupertinoIcons.xmark_circle;
      case DownloadStatus.downloading:
        return CupertinoIcons.arrow_down_circle_fill;
      case DownloadStatus.paused:
        return CupertinoIcons.pause_circle_fill;
      case DownloadStatus.pending:
        return CupertinoIcons.clock;
    }
  }

  Color _getStatusColor() {
    switch (download.status) {
      case DownloadStatus.completed:
        return const Color(0xFF22C55E);
      case DownloadStatus.failed:
        return const Color(0xFFEF4444);
      case DownloadStatus.cancelled:
        return const Color(0xFFF59E0B);
      case DownloadStatus.downloading:
        return accentColor;
      case DownloadStatus.paused:
        return const Color(0xFFF59E0B);
      case DownloadStatus.pending:
        return Colors.white.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return GxFuturisticCard(
      accentColor: statusColor,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  statusIcon,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      download.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NotilusFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (download.status == DownloadStatus.downloading) ...[
                      GxFuturisticProgress(
                        value: download.progress,
                        accentColor: accentColor,
                        height: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        download.progressText,
                        style: NotilusFonts.rajdhani(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ] else ...[
                      Text(
                        download.progressText,
                        style: NotilusFonts.rajdhani(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (download.status == DownloadStatus.downloading)
                GxFuturisticButton(
                  label: '',
                  icon: CupertinoIcons.xmark,
                  variant: GxFuturisticButtonVariant.ghost,
                  accentColor: const Color(0xFFFF453A),
                  width: 32,
                  height: 32,
                  padding: EdgeInsets.zero,
                  onPressed: onCancel,
                )
              else if (download.status == DownloadStatus.completed)
                GxFuturisticButton(
                  label: '',
                  icon: CupertinoIcons.arrow_right,
                  variant: GxFuturisticButtonVariant.primary,
                  accentColor: accentColor,
                  width: 32,
                  height: 32,
                  padding: EdgeInsets.zero,
                  onPressed: onOpen,
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
                onPressed: onRemove,
              ),
            ],
          ),
          if (download.error != null) ...[
            const SizedBox(height: 12),
            GxFuturisticAlert(
              title: 'Erreur',
              message: download.error!,
              type: GxFuturisticAlertType.error,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}

