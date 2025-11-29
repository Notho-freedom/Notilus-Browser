/// Panel de téléchargements futuriste Notilus GX
library gx_futuristic_downloads_panel;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriodFilter = 'Toutes';
  String _selectedStatusFilter = 'Tous';
  final Map<String, bool> _expandedPeriods = {};
  
  // Cache pour optimiser les performances
  Timer? _searchDebounceTimer;
  List<DownloadModel>? _cachedFilteredDownloads;
  Map<String, List<DownloadModel>>? _cachedGroupedDownloads;
  List<String>? _cachedSortedDomains;
  String? _lastSearchQuery;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initialiser toutes les périodes comme expandées
    _expandedPeriods.addAll({
      'Aujourd\'hui': true,
      'Hier': true,
      'Cette semaine': true,
      'Ce mois': true,
      'Plus ancien': true,
    });
  }
  
  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
          // Invalider le cache
          _cachedFilteredDownloads = null;
          _cachedGroupedDownloads = null;
          _cachedSortedDomains = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _togglePeriod(String period) {
    setState(() {
      _expandedPeriods[period] = !(_expandedPeriods[period] ?? true);
    });
  }
  
  /// Groupe les téléchargements par période
  Map<String, List<DownloadModel>> _groupDownloadsByPeriod(List<DownloadModel> downloads) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    final Map<String, List<DownloadModel>> grouped = {};
    
    for (final download in downloads) {
      final startDate = DateTime(download.startTime.year, download.startTime.month, download.startTime.day);
      
      String period;
      if (startDate == today) {
        period = 'Aujourd\'hui';
      } else if (startDate == yesterday) {
        period = 'Hier';
      } else if (startDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        period = 'Cette semaine';
      } else if (startDate.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        period = 'Ce mois';
      } else {
        period = 'Plus ancien';
      }
      
      grouped.putIfAbsent(period, () => []).add(download);
    }
    
    // Trier les périodes dans l'ordre chronologique
    final orderedPeriods = ['Aujourd\'hui', 'Hier', 'Cette semaine', 'Ce mois', 'Plus ancien'];
    final Map<String, List<DownloadModel>> orderedGrouped = {};
    
    for (final period in orderedPeriods) {
      if (grouped.containsKey(period)) {
        orderedGrouped[period] = grouped[period]!;
      }
    }
    
    return orderedGrouped;
  }
  
  String _extractDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        return uri.host.replaceFirst(RegExp(r'^www\.'), '');
      }
    } catch (_) {}
    return 'unknown';
  }
  
  Widget _buildDownloadsList({
    required List<DownloadModel> downloads,
    required DownloadService downloadService,
    required Color accentColor,
    required Color? bgColor,
    required double panelOpacity,
    required bool isCompact,
    required bool isMedium,
    required double horizontalPadding,
    required double itemSpacing,
  }) {
    // Filtrer par recherche
    List<DownloadModel> filteredDownloads;
    if (_cachedFilteredDownloads != null && _lastSearchQuery == _searchQuery) {
      filteredDownloads = _cachedFilteredDownloads!;
    } else {
      filteredDownloads = _searchQuery.isEmpty
          ? downloads
          : downloads.where((download) {
              final fileName = download.fileName.toLowerCase();
              final url = download.url.toLowerCase();
              return fileName.contains(_searchQuery) || url.contains(_searchQuery);
            }).toList();
      _cachedFilteredDownloads = filteredDownloads;
      _lastSearchQuery = _searchQuery;
    }
    
    // Filtrer par statut
    if (_selectedStatusFilter != 'Tous') {
      filteredDownloads = filteredDownloads.where((download) {
        switch (_selectedStatusFilter) {
          case 'En cours':
            return download.status == DownloadStatus.downloading || download.status == DownloadStatus.pending;
          case 'Terminés':
            return download.status == DownloadStatus.completed;
          case 'Échoués':
            return download.status == DownloadStatus.failed || download.status == DownloadStatus.cancelled;
          default:
            return true;
        }
      }).toList();
    }
    
    // Grouper par période
    Map<String, List<DownloadModel>> groupedDownloads;
    if (_cachedGroupedDownloads != null && _lastSearchQuery == _searchQuery) {
      groupedDownloads = _cachedGroupedDownloads!;
    } else {
      groupedDownloads = _groupDownloadsByPeriod(filteredDownloads);
      _cachedGroupedDownloads = groupedDownloads;
    }
    
    // Filtrer par période
    final filteredGroupedDownloads = _selectedPeriodFilter == 'Toutes'
        ? groupedDownloads
        : groupedDownloads.containsKey(_selectedPeriodFilter)
            ? {_selectedPeriodFilter: groupedDownloads[_selectedPeriodFilter]!}
            : <String, List<DownloadModel>>{};
    
    // Extraire les domaines uniques
    List<String> sortedDomains;
    if (_cachedSortedDomains != null && _lastSearchQuery == _searchQuery) {
      sortedDomains = _cachedSortedDomains!;
    } else {
      final uniqueDomains = <String>{};
      for (final download in filteredDownloads) {
        uniqueDomains.add(_extractDomainFromUrl(download.url));
      }
      sortedDomains = uniqueDomains.toList()..sort();
      _cachedSortedDomains = sortedDomains;
    }
    
    // Préparer la liste avec séparateurs
    final List<_DownloadListItemData> flatItems = [];
    
    filteredGroupedDownloads.forEach((period, periodDownloads) {
      final isExpanded = _expandedPeriods[period] ?? true;
      
      // Ajouter le séparateur
      flatItems.add(_DownloadListItemData(
        type: _DownloadListItemType.separator,
        period: period,
        isExpanded: isExpanded,
        isFirst: flatItems.isEmpty,
      ));
      
      // Ajouter les téléchargements de cette période si expandée
      if (isExpanded) {
        for (final download in periodDownloads) {
          flatItems.add(_DownloadListItemData(
            type: _DownloadListItemType.item,
            download: download,
          ));
        }
      }
    });
    
    if (filteredDownloads.isEmpty) {
      return Center(
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
              _searchQuery.isEmpty
                  ? 'Aucun téléchargement'
                  : 'Aucun résultat',
              style: NotilusFonts.rajdhani(
                fontSize: isCompact ? 13 : isMedium ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Les fichiers téléchargés apparaîtront ici'
                  : 'Aucun téléchargement ne correspond',
              style: NotilusFonts.rajdhani(
                fontSize: isCompact ? 10 : isMedium ? 11 : 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Filtres
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: itemSpacing),
          child: Row(
            children: [
              // Filtre par période
              Expanded(
                child: _FilterDropdown(
                  label: 'Période',
                  value: _selectedPeriodFilter,
                  items: ['Toutes', ...groupedDownloads.keys.toList()],
                  accentColor: accentColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriodFilter = value ?? 'Toutes';
                    });
                  },
                ),
              ),
              SizedBox(width: itemSpacing),
              // Filtre par statut
              Expanded(
                child: _FilterDropdown(
                  label: 'Statut',
                  value: _selectedStatusFilter,
                  items: ['Tous', 'En cours', 'Terminés', 'Échoués'],
                  accentColor: accentColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatusFilter = value ?? 'Tous';
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        // Liste avec scroll
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: itemSpacing,
            ),
            itemCount: flatItems.length,
            cacheExtent: 500,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemBuilder: (context, index) {
              final itemData = flatItems[index];
              
              if (itemData.type == _DownloadListItemType.separator) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: itemData.isFirst ? 0 : itemSpacing * 2,
                    horizontal: 0,
                  ),
                  child: _PeriodSeparator(
                    label: itemData.period!,
                    accentColor: accentColor,
                    isExpanded: itemData.isExpanded!,
                    onTap: () => _togglePeriod(itemData.period!),
                  ),
                );
              } else {
                final download = itemData.download!;
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
                        _cachedFilteredDownloads = null;
                        _cachedGroupedDownloads = null;
                        _cachedSortedDomains = null;
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
              }
            },
          ),
        ),
      ],
    );
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
                    // Header compact avec recherche
                    Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, itemSpacing),
                      child: Row(
                        children: [
                          // Barre de recherche compacte
                          Expanded(
                            child: GxFuturisticInput(
                              controller: _searchController,
                              hint: isCompact ? 'Rechercher...' : 'Rechercher dans les téléchargements...',
                              prefixIcon: CupertinoIcons.search,
                              accentColor: accentColor,
                            ),
                          ),
                          SizedBox(width: itemSpacing),
                          // Bouton effacer terminés
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
                                _cachedFilteredDownloads = null;
                                _cachedGroupedDownloads = null;
                                _cachedSortedDomains = null;
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
                          : _buildDownloadsList(
                              downloads: downloads,
                              downloadService: downloadService,
                              accentColor: accentColor,
                              bgColor: bgColor,
                              panelOpacity: panelOpacity,
                              isCompact: isCompact,
                              isMedium: isMedium,
                              horizontalPadding: horizontalPadding,
                              itemSpacing: itemSpacing,
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
  
  /// Extrait le domaine de l'URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        return uri.host.replaceFirst(RegExp(r'^www\.'), '');
      }
    } catch (_) {}
    return url.length > 30 ? '${url.substring(0, 30)}...' : url;
  }
  
  /// Formate le temps relatif (il y a X minutes/heures/jours)
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} min';
    } else {
      return 'À l\'instant';
    }
  }

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
    final urlFontSize = widget.isCompact ? 9.0 : widget.isMedium ? 10.0 : 11.0;
    final metaFontSize = widget.isCompact ? 8.0 : widget.isMedium ? 9.0 : 10.0;
    
    final domain = _extractDomain(widget.download.url);
    final relativeTime = _formatRelativeTime(widget.download.startTime);

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
                                fontWeight: FontWeight.w600,
                                color: _isHovered
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.95),
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: widget.isCompact ? 2 : 4),
                            // Domaine avec taille à la suite
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    domain,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NotilusFonts.rajdhani(
                                      fontSize: urlFontSize,
                                      color: Colors.white.withOpacity(
                                        _isHovered ? 0.7 : 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.download.totalBytes != null && widget.download.totalBytes! > 0) ...[
                                  SizedBox(width: 6),
                                  Text(
                                    '• ${(widget.download.totalBytes! / 1024 / 1024).toStringAsFixed(1)} MB',
                                    style: NotilusFonts.rajdhani(
                                      fontSize: urlFontSize,
                                      color: widget.accentColor.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 8 : 12),
                      // Colonne droite : horloge + flèche (comme historique)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Horloge avec temps relatif
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.time,
                                size: metaFontSize + 2,
                                color: Colors.white.withOpacity(0.4),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  relativeTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NotilusFonts.rajdhani(
                                    fontSize: metaFontSize,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          // Bouton action : flèche par défaut, X en hover pour supprimer
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.identity()
                              ..translate(_isHovered ? 2.0 : 0.0),
                            child: GxFuturisticButton(
                              label: '',
                              icon: _isHovered && widget.download.status != DownloadStatus.downloading
                                  ? CupertinoIcons.xmark
                                  : (widget.download.status == DownloadStatus.downloading
                                      ? CupertinoIcons.xmark
                                      : CupertinoIcons.chevron_right),
                              variant: GxFuturisticButtonVariant.ghost,
                              accentColor: _isHovered && widget.download.status != DownloadStatus.downloading
                                  ? const Color(0xFFEF4444)
                                  : (widget.download.status == DownloadStatus.downloading
                                      ? const Color(0xFFEF4444)
                                      : widget.accentColor),
                              width: widget.isCompact ? 28 : 32,
                              height: widget.isCompact ? 28 : 32,
                              padding: EdgeInsets.zero,
                              onPressed: _isHovered && widget.download.status != DownloadStatus.downloading
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


/// Type d'élément dans la liste
enum _DownloadListItemType {
  separator,
  item,
}

/// Données pour un élément de la liste
class _DownloadListItemData {
  final _DownloadListItemType type;
  final DownloadModel? download;
  final String? period;
  final bool? isExpanded;
  final bool isFirst;

  _DownloadListItemData({
    required this.type,
    this.download,
    this.period,
    this.isExpanded,
    this.isFirst = false,
  });
}

/// Séparateur de période avec collapse/expand
class _PeriodSeparator extends StatelessWidget {
  final String label;
  final Color accentColor;
  final bool isExpanded;
  final VoidCallback onTap;

  const _PeriodSeparator({
    required this.label,
    required this.accentColor,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: accentColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GxFuturisticSeparator(
                label: label,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown de filtre
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Color accentColor;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: NotilusFonts.rajdhani(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.black.withOpacity(0.85),
                style: NotilusFonts.rajdhani(
                  fontSize: 10,
                  color: Colors.white,
                ),
                icon: Icon(
                  CupertinoIcons.chevron_down,
                  size: 12,
                  color: accentColor,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(item),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
