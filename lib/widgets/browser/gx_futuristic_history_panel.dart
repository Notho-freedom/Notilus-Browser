/// Panel d'historique futuriste Notilus GX
library gx_futuristic_history_panel;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import '../../services/history_service.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../services/favicon_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../common/gx_futuristic_components.dart';
import '../common/gx_futuristic_dialog.dart';
import '../../services/gx_notification_service.dart';

class GxFuturisticHistoryPanel extends StatefulWidget {
  const GxFuturisticHistoryPanel({super.key});

  @override
  State<GxFuturisticHistoryPanel> createState() => _GxFuturisticHistoryPanelState();
}

class _GxFuturisticHistoryPanelState extends State<GxFuturisticHistoryPanel> {
  final HistoryService _historyService = HistoryService();
  late Future _historyFuture;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriodFilter = 'Toutes';
  String _selectedDomainFilter = 'Tous';
  final Map<String, bool> _expandedPeriods = {};
  final ScrollController _scrollController = ScrollController();
  
  // Cache pour optimiser les performances
  Timer? _searchDebounceTimer;
  Map<String, List<dynamic>>? _cachedGroupedItems;
  List<dynamic>? _cachedFilteredItems;
  List<String>? _cachedSortedDomains;
  String? _lastSearchQuery;
  String? _lastPeriodFilter;
  String? _lastDomainFilter;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.getHistory();
    _searchController.addListener(_onSearchChanged);
    _filterController.addListener(() {
      setState(() {
        // Le filtre sera géré par les sélecteurs
      });
    });
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
          _cachedFilteredItems = null;
          _cachedGroupedItems = null;
          _cachedSortedDomains = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _togglePeriod(String period) {
    setState(() {
      _expandedPeriods[period] = !(_expandedPeriods[period] ?? true);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _historyService.getHistory();
      // Invalider le cache
      _cachedFilteredItems = null;
      _cachedGroupedItems = null;
      _cachedSortedDomains = null;
    });
  }
  
  /// Groupe les items par période (Aujourd'hui, Hier, Cette semaine, etc.)
  /// Utilise le cache si disponible
  Map<String, List<dynamic>> _groupItemsByPeriod(List<dynamic> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    final Map<String, List<dynamic>> grouped = {};
    
    for (final item in items) {
      final visitedAt = item.visitedAt ?? DateTime.now();
      final visitedDate = DateTime(visitedAt.year, visitedAt.month, visitedAt.day);
      
      String period;
      if (visitedDate == today) {
        period = 'Aujourd\'hui';
      } else if (visitedDate == yesterday) {
        period = 'Hier';
      } else if (visitedDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        period = 'Cette semaine';
      } else if (visitedDate.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        period = 'Ce mois';
      } else {
        period = 'Plus ancien';
      }
      
      grouped.putIfAbsent(period, () => []).add(item);
    }
    
    // Trier les périodes dans l'ordre chronologique
    final orderedPeriods = ['Aujourd\'hui', 'Hier', 'Cette semaine', 'Ce mois', 'Plus ancien'];
    final Map<String, List<dynamic>> orderedGrouped = {};
    
    for (final period in orderedPeriods) {
      if (grouped.containsKey(period)) {
        orderedGrouped[period] = grouped[period]!;
      }
    }
    
    return orderedGrouped;
  }

  Future<void> _clearHistory() async {
    final result = await GxFuturisticDialog.show<bool>(
      context: context,
      title: 'Effacer l\'historique',
      titleIcon: CupertinoIcons.delete,
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir effacer tout l\'historique ? Cette action est irréversible.',
            style: NotilusFonts.rajdhani(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        GxFuturisticButton(
          label: 'Effacer',
          icon: CupertinoIcons.delete,
          variant: GxFuturisticButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (result == true) {
      await _historyService.clearHistory();
      await _refresh();
      if (mounted) {
        GxNotificationService().showSuccess(
          title: 'Historique effacé',
          message: 'Tout l\'historique a été supprimé',
          context: context,
        );
      }
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Dimensions adaptatives selon la taille du panel
            final isCompact = constraints.maxWidth < 400;
            final isMedium = constraints.maxWidth >= 400 && constraints.maxWidth < 600;
            
            // Padding adaptatif
            final horizontalPadding = isCompact ? 12.0 : isMedium ? 16.0 : 20.0;
            final verticalPadding = isCompact ? 8.0 : isMedium ? 12.0 : 16.0;
            final itemSpacing = isCompact ? 6.0 : isMedium ? 8.0 : 12.0;
            
            // Tailles de police adaptatives
            final titleFontSize = isCompact ? 11.0 : isMedium ? 12.0 : 13.0;
            final urlFontSize = isCompact ? 9.0 : isMedium ? 10.0 : 11.0;
            final metaFontSize = isCompact ? 8.0 : isMedium ? 9.0 : 10.0;
            
            // Hauteur des items adaptative
            final itemHeight = isCompact ? 56.0 : isMedium ? 64.0 : 72.0;
            final faviconSize = isCompact ? 20.0 : isMedium ? 24.0 : 28.0;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header compact (sans titre répété)
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, itemSpacing),
                  child: Row(
                    children: [
                      // Barre de recherche compacte
                      Expanded(
                        child: GxFuturisticInput(
                          controller: _searchController,
                          hint: isCompact ? 'Rechercher...' : 'Rechercher dans l\'historique...',
                          prefixIcon: CupertinoIcons.search,
                          accentColor: accentColor,
                        ),
                      ),
                      SizedBox(width: itemSpacing),
                      // Bouton effacer avec variant secondary
                      GxFuturisticButton(
                        label: isCompact ? '' : 'Effacer',
                        icon: CupertinoIcons.delete,
                        variant: GxFuturisticButtonVariant.secondary,
                        accentColor: accentColor,
                        width: isCompact ? 36 : null,
                        height: isCompact ? 36 : null,
                        padding: isCompact ? EdgeInsets.zero : null,
                        onPressed: _clearHistory,
                      ),
                    ],
                  ),
                ),
                
                // Liste avec dimensions adaptatives
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: accentColor,
                    child: FutureBuilder(
                      future: _historyFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: GxFuturisticSpinner(
                              accentColor: accentColor,
                              message: 'Chargement...',
                            ),
                          );
                        }

                        final items = snapshot.data as List<dynamic>? ?? [];
                        
                        // Utiliser le cache si les filtres n'ont pas changé
                        List<dynamic> filteredItems;
                        if (_cachedFilteredItems != null && 
                            _lastSearchQuery == _searchQuery) {
                          filteredItems = _cachedFilteredItems!;
                        } else {
                          filteredItems = _searchQuery.isEmpty
                              ? items
                              : items.where((item) {
                                  final title = (item.title ?? '').toLowerCase();
                                  final url = (item.url ?? '').toLowerCase();
                                  return title.contains(_searchQuery) ||
                                         url.contains(_searchQuery);
                                }).toList();
                          _cachedFilteredItems = filteredItems;
                          _lastSearchQuery = _searchQuery;
                        }

                        // Grouper les items par période (avec cache)
                        Map<String, List<dynamic>> groupedItems;
                        if (_cachedGroupedItems != null && 
                            _lastSearchQuery == _searchQuery) {
                          groupedItems = _cachedGroupedItems!;
                        } else {
                          groupedItems = _groupItemsByPeriod(filteredItems);
                          _cachedGroupedItems = groupedItems;
                        }
                        
                        // Filtrer par période si sélectionnée
                        final filteredGroupedItems = _selectedPeriodFilter == 'Toutes'
                            ? groupedItems
                            : groupedItems.containsKey(_selectedPeriodFilter)
                                ? {_selectedPeriodFilter: groupedItems[_selectedPeriodFilter]!}
                                : <String, List<dynamic>>{};

                        if (filteredItems.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.time,
                                  size: isCompact ? 48 : isMedium ? 56 : 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                SizedBox(height: isCompact ? 12 : 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Aucun historique'
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
                                      ? 'Votre historique apparaîtra ici'
                                      : 'Aucun élément ne correspond',
                                  style: NotilusFonts.rajdhani(
                                    fontSize: isCompact ? 10 : isMedium ? 11 : 12,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Extraire les domaines uniques pour le filtre (avec cache)
                        List<String> sortedDomains;
                        if (_cachedSortedDomains != null && 
                            _lastSearchQuery == _searchQuery) {
                          sortedDomains = _cachedSortedDomains!;
                        } else {
                          final uniqueDomains = <String>{};
                          for (final item in filteredItems) {
                            uniqueDomains.add(_extractDomainFromUrl(item.url ?? ''));
                          }
                          sortedDomains = uniqueDomains.toList()..sort();
                          _cachedSortedDomains = sortedDomains;
                        }

                        // Préparer la liste d'items pour ListView.builder
                        final List<_ListItemData> flatItems = [];
                        
                        filteredGroupedItems.forEach((period, periodItems) {
                          final isExpanded = _expandedPeriods[period] ?? true;
                          
                          // Ajouter le séparateur
                          flatItems.add(_ListItemData(
                            type: _ListItemType.separator,
                            period: period,
                            isExpanded: isExpanded,
                            isFirst: flatItems.isEmpty,
                          ));
                          
                          // Ajouter les items de cette période si expandée
                          if (isExpanded) {
                            for (final item in periodItems) {
                              // Filtrer par domaine si sélectionné
                              if (_selectedDomainFilter != 'Tous') {
                                final domain = _extractDomainFromUrl(item.url ?? '');
                                if (domain != _selectedDomainFilter) {
                                  continue;
                                }
                              }
                              
                              flatItems.add(_ListItemData(
                                type: _ListItemType.item,
                                item: item,
                              ));
                            }
                          }
                        });

                        return Column(
                          children: [
                            // Filtres (toujours visibles)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: itemSpacing),
                              child: Row(
                                children: [
                                  // Filtre par période
                                  Expanded(
                                    child: _FilterDropdown(
                                      label: 'Période',
                                      value: _selectedPeriodFilter,
                                      items: ['Toutes', ...groupedItems.keys.toList()],
                                      accentColor: accentColor,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPeriodFilter = value ?? 'Toutes';
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: itemSpacing),
                                  // Filtre par domaine
                                  Expanded(
                                    child: _FilterDropdown(
                                      label: 'Domaine',
                                      value: _selectedDomainFilter,
                                      items: ['Tous', ...sortedDomains],
                                      accentColor: accentColor,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDomainFilter = value ?? 'Tous';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Liste avec scroll optimisée (ListView.builder pour virtualisation)
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: itemSpacing,
                                ),
                                itemCount: flatItems.length,
                                cacheExtent: 500, // Cache optimisé
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                itemBuilder: (context, index) {
                                  final itemData = flatItems[index];
                                  
                                  if (itemData.type == _ListItemType.separator) {
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
                                    final item = itemData.item!;
                                    return RepaintBoundary(
                                      key: ValueKey('history_${item.id}'),
                                      child: _HistoryListItem(
                                        item: item,
                                        accentColor: accentColor,
                                        bgColor: bgColor,
                                        panelOpacity: panelOpacity,
                                        isCompact: isCompact,
                                        isMedium: isMedium,
                                        titleFontSize: titleFontSize,
                                        urlFontSize: urlFontSize,
                                        metaFontSize: metaFontSize,
                                        itemHeight: itemHeight,
                                        faviconSize: faviconSize,
                                        index: index,
                                        onTap: () {
                                          final tabManager = Provider.of<TabManager>(context, listen: false);
                                          tabManager.addTab(url: item.url);
                                        },
                                        onDelete: () async {
                                          await _historyService.removeHistoryItem(item.id);
                                          await _refresh();
                                          if (mounted) {
                                            GxNotificationService().showInfo(
                                              title: 'Item supprimé',
                                              message: 'L\'élément a été retiré de l\'historique',
                                              context: context,
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
}

/// Type d'élément dans la liste
enum _ListItemType {
  separator,
  item,
}

/// Données pour un élément de la liste
class _ListItemData {
  final _ListItemType type;
  final dynamic item;
  final String? period;
  final bool? isExpanded;
  final bool isFirst;

  _ListItemData({
    required this.type,
    this.item,
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

class _HistoryListItem extends StatefulWidget {
  final dynamic item;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final bool isCompact;
  final bool isMedium;
  final double titleFontSize;
  final double urlFontSize;
  final double metaFontSize;
  final double itemHeight;
  final double faviconSize;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _HistoryListItem({
    required this.item,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.isCompact,
    required this.isMedium,
    required this.titleFontSize,
    required this.urlFontSize,
    required this.metaFontSize,
    required this.itemHeight,
    required this.faviconSize,
    required this.index,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_HistoryListItem> createState() => _HistoryListItemState();
}

class _HistoryListItemState extends State<_HistoryListItem> {
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

  @override
  Widget build(BuildContext context) {
    final domain = _extractDomain(widget.item.url);
    final relativeTime = _formatRelativeTime(widget.item.visitedAt ?? DateTime.now());
    final visitCount = widget.item.visitCount ?? 1;
    
    return FutureBuilder<String?>(
      future: FaviconService.getFaviconWithCache(widget.item.url),
      builder: (context, faviconSnapshot) {
        final itemPadding = widget.isCompact ? 8.0 : widget.isMedium ? 10.0 : 12.0;
        final itemHorizontalPadding = widget.isCompact ? 12.0 : widget.isMedium ? 14.0 : 16.0;
        
        return RepaintBoundary(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onTap();
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
                  child: Row(
                    children: [
                      // Favicon avec animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: widget.faviconSize + 8,
                        height: widget.faviconSize + 8,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(
                            _isHovered ? 0.25 : 0.15,
                          ),
                          borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(
                              _isHovered ? 0.5 : 0.3,
                            ),
                            width: _isHovered ? 1.5 : 1,
                          ),
                        ),
                        child: faviconSnapshot.hasData && faviconSnapshot.data != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(widget.isCompact ? 4 : 6),
                                child: Image.network(
                                  faviconSnapshot.data!,
                                  width: widget.faviconSize - 4,
                                  height: widget.faviconSize - 4,
                                  errorBuilder: (_, __, ___) => Icon(
                                    CupertinoIcons.globe,
                                    size: widget.faviconSize - 6,
                                    color: widget.accentColor,
                                  ),
                                ),
                              )
                            : Icon(
                                CupertinoIcons.globe,
                                size: widget.faviconSize - 6,
                                color: widget.accentColor,
                              ),
                      ),
                      SizedBox(width: widget.isCompact ? 10 : 12),
                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        // Titre
                        Text(
                          widget.item.title ?? '',
                          maxLines: widget.isCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: NotilusFonts.rajdhani(
                            fontSize: widget.titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: _isHovered
                                ? Colors.white
                                : Colors.white.withOpacity(0.95),
                            height: 1.2,
                          ),
                        ),
                            SizedBox(height: widget.isCompact ? 2 : 4),
                            // Domaine
                            Text(
                              domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NotilusFonts.rajdhani(
                                fontSize: widget.urlFontSize,
                                color: Colors.white.withOpacity(
                                  _isHovered ? 0.7 : 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: widget.isCompact ? 8 : 12),
                      // Colonne droite : horloge + flèche
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Horloge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.time,
                                size: widget.metaFontSize + 2,
                                color: Colors.white.withOpacity(0.4),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  relativeTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NotilusFonts.rajdhani(
                                    fontSize: widget.metaFontSize,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              if (visitCount > 1) ...[
                                SizedBox(width: 6),
                                Icon(
                                  CupertinoIcons.arrow_counterclockwise,
                                  size: widget.metaFontSize + 2,
                                  color: widget.accentColor.withOpacity(0.7),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '$visitCount',
                                  style: NotilusFonts.rajdhani(
                                    fontSize: widget.metaFontSize,
                                    color: widget.accentColor.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
                              icon: _isHovered && widget.onDelete != null
                                  ? CupertinoIcons.xmark
                                  : CupertinoIcons.chevron_right,
                              variant: GxFuturisticButtonVariant.ghost,
                              accentColor: _isHovered && widget.onDelete != null
                                  ? const Color(0xFFEF4444)
                                  : widget.accentColor,
                              width: widget.isCompact ? 28 : 32,
                              height: widget.isCompact ? 28 : 32,
                              padding: EdgeInsets.zero,
                              onPressed: _isHovered && widget.onDelete != null
                                  ? widget.onDelete
                                  : widget.onTap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

