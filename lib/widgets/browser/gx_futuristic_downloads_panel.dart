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
import '../../services/gx_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class GxFuturisticDownloadsPanel extends StatefulWidget {
  const GxFuturisticDownloadsPanel({super.key});

  @override
  State<GxFuturisticDownloadsPanel> createState() => _GxFuturisticDownloadsPanelState();
}

class _GxFuturisticDownloadsPanelState extends State<GxFuturisticDownloadsPanel> {
  final ScrollController _scrollController = ScrollController();
  
  // Cache pour optimiser les performances
  List<DownloadModel>? _cachedDownloads;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        child: Consumer<DownloadService>(
          builder: (context, downloadService, _) {
            final downloads = downloadService.downloads;
            
            // Utiliser le cache si disponible
            if (_cachedDownloads == null || _cachedDownloads!.length != downloads.length) {
              _cachedDownloads = List.from(downloads);
            }
            
            return LayoutBuilder(
              builder: (context, constraints) {
                // Dimensions adaptatives selon la taille du panel
                final isCompact = constraints.maxWidth < 400;
                final isMedium = constraints.maxWidth >= 400 && constraints.maxWidth < 600;
                
                // Padding adaptatif
                final horizontalPadding = isCompact ? 12.0 : isMedium ? 16.0 : 24.0;
                final verticalPadding = isCompact ? 8.0 : isMedium ? 12.0 : 16.0;
                final itemSpacing = isCompact ? 6.0 : isMedium ? 8.0 : 12.0;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header compact (sans titre répété)
                    Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, itemSpacing),
                      child: Row(
                        children: [
                          const Spacer(),
                          if (downloads.isNotEmpty)
                            GxFuturisticButton(
                              label: isCompact ? '' : 'Effacer terminés',
                              icon: CupertinoIcons.delete,
                              variant: GxFuturisticButtonVariant.secondary,
                              accentColor: accentColor,
                              width: isCompact ? 36 : null,
                              height: isCompact ? 36 : null,
                              padding: isCompact ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              onPressed: () async {
                                for (final download in downloads) {
                                  if (download.status == DownloadStatus.completed ||
                                      download.status == DownloadStatus.failed ||
                                      download.status == DownloadStatus.cancelled) {
                                    downloadService.removeDownload(download.id);
                                  }
                                }
                                _cachedDownloads = null; // Invalider le cache
                                if (mounted) {
                                  GxNotificationService().showSuccess(
                                    title: 'Nettoyage effectué',
                                    message: 'Les téléchargements terminés ont été supprimés',
                                    context: context,
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    
                    // Liste avec dimensions adaptatives
                    Expanded(
                      child: downloads.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_down_circle,
                                    size: isCompact ? 48 : isMedium ? 56 : 64,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  SizedBox(height: isCompact ? 12 : 16),
                                  Text(
                                    'Aucun téléchargement',
                                    style: NotilusFonts.rajdhani(
                                      fontSize: isCompact ? 13 : isMedium ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 6 : 8),
                                  Text(
                                    'Les fichiers téléchargés apparaîtront ici',
                                    style: NotilusFonts.rajdhani(
                                      fontSize: isCompact ? 10 : isMedium ? 11 : 12,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: itemSpacing,
                              ),
                              itemCount: downloads.length,
                              cacheExtent: 500, // Cache optimisé
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                              itemBuilder: (context, index) {
                                final download = downloads[index];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: itemSpacing),
                                  child: RepaintBoundary(
                                    key: ValueKey('download_${download.id}'),
                                    child: _DownloadListItem(
                                      download: download,
                                      accentColor: accentColor,
                                      bgColor: bgColor,
                                      panelOpacity: panelOpacity,
                                      isCompact: isCompact,
                                      isMedium: isMedium,
                                      onCancel: () => downloadService.cancelDownload(download.id),
                                      onRemove: () {
                                        downloadService.removeDownload(download.id);
                                        _cachedDownloads = null; // Invalider le cache
                                      },
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
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DownloadListItem extends StatefulWidget {
  final DownloadModel download;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final bool isCompact;
  final bool isMedium;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const _DownloadListItem({
    required this.download,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.isCompact,
    required this.isMedium,
    required this.onCancel,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  State<_DownloadListItem> createState() => _DownloadListItemState();
}

class _DownloadListItemState extends State<_DownloadListItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  IconData _getStatusIcon() {
    switch (widget.download.status) {
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
    switch (widget.download.status) {
      case DownloadStatus.completed:
        return const Color(0xFF22C55E);
      case DownloadStatus.failed:
        return const Color(0xFFEF4444);
      case DownloadStatus.cancelled:
        return const Color(0xFFF59E0B);
      case DownloadStatus.downloading:
        return widget.accentColor;
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
    final itemPadding = widget.isCompact ? 8.0 : widget.isMedium ? 10.0 : 12.0;
    final itemHorizontalPadding = widget.isCompact ? 12.0 : widget.isMedium ? 14.0 : 16.0;
    final iconSize = widget.isCompact ? 20.0 : widget.isMedium ? 24.0 : 28.0;
    final titleFontSize = widget.isCompact ? 11.0 : widget.isMedium ? 12.0 : 13.0;
    final metaFontSize = widget.isCompact ? 9.0 : widget.isMedium ? 10.0 : 11.0;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (widget.download.status == DownloadStatus.completed) {
              widget.onOpen();
            }
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0)),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
              border: _isHovered
                  ? Border(
                      left: BorderSide(
                        color: widget.accentColor,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: itemHorizontalPadding,
                vertical: itemPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Icône de statut avec animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: iconSize + 8,
                        height: iconSize + 8,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(
                            _isHovered ? 0.25 : 0.15,
                          ),
                          borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
                          border: Border.all(
                            color: statusColor.withOpacity(
                              _isHovered ? 0.5 : 0.3,
                            ),
                            width: _isHovered ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          statusIcon,
                          size: iconSize - 6,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 10 : 12),
                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nom du fichier
                            Text(
                              widget.download.fileName,
                              maxLines: widget.isCompact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: NotilusFonts.rajdhani(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: _isHovered
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.95),
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: widget.isCompact ? 4 : 6),
                            // Barre de progression ou texte de statut
                            if (widget.download.status == DownloadStatus.downloading) ...[
                              GxFuturisticProgress(
                                value: widget.download.progress,
                                accentColor: widget.accentColor,
                                height: 2,
                              ),
                              SizedBox(height: widget.isCompact ? 4 : 6),
                            ],
                            Text(
                              widget.download.progressText,
                              style: NotilusFonts.rajdhani(
                                fontSize: metaFontSize,
                                color: Colors.white.withOpacity(
                                  _isHovered ? 0.7 : 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 8 : 12),
                      // Bouton action : flèche par défaut, X en hover pour supprimer
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()
                          ..translate(_isHovered ? 2.0 : 0.0),
                        child: GxFuturisticButton(
                          label: '',
                          icon: _isHovered
                              ? CupertinoIcons.xmark
                              : (widget.download.status == DownloadStatus.downloading
                                  ? CupertinoIcons.xmark
                                  : widget.download.status == DownloadStatus.completed
                                      ? CupertinoIcons.chevron_right
                                      : CupertinoIcons.chevron_right),
                          variant: GxFuturisticButtonVariant.ghost,
                          accentColor: _isHovered
                              ? const Color(0xFFEF4444)
                              : (widget.download.status == DownloadStatus.downloading
                                  ? const Color(0xFFEF4444)
                                  : widget.accentColor),
                          width: widget.isCompact ? 28 : 32,
                          height: widget.isCompact ? 28 : 32,
                          padding: EdgeInsets.zero,
                          onPressed: _isHovered
                              ? widget.onRemove
                              : (widget.download.status == DownloadStatus.downloading
                                  ? widget.onCancel
                                  : widget.download.status == DownloadStatus.completed
                                      ? widget.onOpen
                                      : widget.onRemove),
                        ),
                      ),
                    ],
                  ),
                  // Message d'erreur si présent
                  if (widget.download.error != null) ...[
                    SizedBox(height: widget.isCompact ? 8 : 12),
                    GxFuturisticAlert(
                      title: 'Erreur',
                      message: widget.download.error!,
                      type: GxFuturisticAlertType.error,
                      accentColor: widget.accentColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

