/// Panel de mises à jour futuriste Notilus GX
library gx_futuristic_updates_panel;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/update_service.dart';
import '../../services/settings_service.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

class GxFuturisticUpdatesPanel extends StatefulWidget {
  const GxFuturisticUpdatesPanel({super.key});

  @override
  State<GxFuturisticUpdatesPanel> createState() => _GxFuturisticUpdatesPanelState();
}

class _GxFuturisticUpdatesPanelState extends State<GxFuturisticUpdatesPanel> {
  final UpdateService _updateService = UpdateService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriodFilter = 'Toutes';
  String _selectedCategoryFilter = 'Toutes';
  final Map<String, bool> _expandedPeriods = {};
  
  // Cache pour optimiser les performances
  Timer? _searchDebounceTimer;
  Map<String, List<UpdateInfo>>? _cachedGroupedItems;
  List<UpdateInfo>? _cachedFilteredItems;
  String? _lastSearchQuery;
  String? _lastPeriodFilter;
  String? _lastCategoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_updateService.recentUpdates.isEmpty) {
        _updateService.checkForUpdates();
      }
    });
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
          _cachedFilteredItems = null;
          _cachedGroupedItems = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  
  void _togglePeriod(String period) {
    setState(() {
      _expandedPeriods[period] = !(_expandedPeriods[period] ?? true);
    });
  }

  Map<String, List<UpdateInfo>> _groupUpdatesByPeriod(List<UpdateInfo> updates) {
    final now = DateTime.now();
    final grouped = <String, List<UpdateInfo>>{};
    
    for (final update in updates) {
      final difference = now.difference(update.date);
      String period;
      
      if (difference.inDays == 0) {
        period = 'Aujourd\'hui';
      } else if (difference.inDays == 1) {
        period = 'Hier';
      } else if (difference.inDays < 7) {
        period = 'Cette semaine';
      } else if (difference.inDays < 30) {
        period = 'Ce mois';
      } else {
        period = 'Plus ancien';
      }
      
      grouped.putIfAbsent(period, () => []).add(update);
    }
    
    // Trier chaque groupe par date (plus récent en premier)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
    });
    
    return grouped;
  }

  List<UpdateInfo> _filterUpdates(List<UpdateInfo> updates) {
    // Utiliser le cache si les filtres n'ont pas changé
    if (_cachedFilteredItems != null &&
        _lastSearchQuery == _searchQuery &&
        _lastPeriodFilter == _selectedPeriodFilter &&
        _lastCategoryFilter == _selectedCategoryFilter) {
      return _cachedFilteredItems!;
    }
    
    var filtered = updates;
    
    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((update) {
        return update.title.toLowerCase().contains(_searchQuery) ||
               update.description.toLowerCase().contains(_searchQuery) ||
               update.category.label.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    // Filtre par catégorie
    if (_selectedCategoryFilter != 'Toutes') {
      filtered = filtered.where((update) {
        return update.category.label == _selectedCategoryFilter;
      }).toList();
    }
    
    // Filtre par période
    if (_selectedPeriodFilter != 'Toutes') {
      final now = DateTime.now();
      filtered = filtered.where((update) {
        final difference = now.difference(update.date);
        String period;
        
        if (difference.inDays == 0) {
          period = 'Aujourd\'hui';
        } else if (difference.inDays == 1) {
          period = 'Hier';
        } else if (difference.inDays < 7) {
          period = 'Cette semaine';
        } else if (difference.inDays < 30) {
          period = 'Ce mois';
        } else {
          period = 'Plus ancien';
        }
        
        return period == _selectedPeriodFilter;
      }).toList();
    }
    
    // Mettre en cache
    _cachedFilteredItems = filtered;
    _lastSearchQuery = _searchQuery;
    _lastPeriodFilter = _selectedPeriodFilter;
    _lastCategoryFilter = _selectedCategoryFilter;
    
    return filtered;
  }

  Map<String, List<UpdateInfo>> _getGroupedItems() {
    final filtered = _filterUpdates(_updateService.recentUpdates);
    
    // Utiliser le cache si les filtres n'ont pas changé
    if (_cachedGroupedItems != null &&
        _lastSearchQuery == _searchQuery &&
        _lastPeriodFilter == _selectedPeriodFilter &&
        _lastCategoryFilter == _selectedCategoryFilter) {
      return _cachedGroupedItems!;
    }
    
    final grouped = _groupUpdatesByPeriod(filtered);
    _cachedGroupedItems = grouped;
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    final wallpaperManager = context.watch<WallpaperManager>();
    final wallpaperUrl = wallpaperManager.currentImageUrl;

    return Container(
      decoration: BoxDecoration(
        image: wallpaperUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(wallpaperUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 300;
            final isMedium = constraints.maxWidth >= 300 && constraints.maxWidth < 450;
            final horizontalPadding = isCompact ? 12.0 : isMedium ? 16.0 : 24.0;
            final itemSpacing = isCompact ? 8.0 : isMedium ? 10.0 : 12.0;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_up_circle,
                        color: accentColor,
                        size: isCompact ? 20 : isMedium ? 22 : 24,
                      ),
                      SizedBox(width: itemSpacing),
                      Expanded(
                        child: Text(
                          'MISES À JOUR',
                          style: NotilusFonts.orbitron(
                            fontSize: isCompact ? 16 : isMedium ? 18 : 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      GxFuturisticBadge(
                        label: 'v${_updateService.version}',
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
                
                // Barre de recherche
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: GxFuturisticInput(
                    controller: _searchController,
                    hint: 'Rechercher...',
                    prefixIcon: CupertinoIcons.search,
                    accentColor: accentColor,
                  ),
                ),
                
                SizedBox(height: itemSpacing),
                
                // Filtres (toujours visibles)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    children: [
                      // Filtre par période
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Période',
                          value: _selectedPeriodFilter,
                          items: ['Toutes', 'Aujourd\'hui', 'Hier', 'Cette semaine', 'Ce mois', 'Plus ancien'],
                          accentColor: accentColor,
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriodFilter = value ?? 'Toutes';
                              _cachedFilteredItems = null;
                              _cachedGroupedItems = null;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: itemSpacing),
                      // Filtre par catégorie
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Catégorie',
                          value: _selectedCategoryFilter,
                          items: ['Toutes', 'Nouvelle fonctionnalité', 'Amélioration', 'Correction', 'Sécurité'],
                          accentColor: accentColor,
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryFilter = value ?? 'Toutes';
                              _cachedFilteredItems = null;
                              _cachedGroupedItems = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: itemSpacing),
                
                // Bouton vérifier
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: ListenableBuilder(
                    listenable: _updateService,
                    builder: (context, _) {
                      return GxFuturisticButton(
                        label: _updateService.isChecking 
                            ? 'Vérification...' 
                            : 'Vérifier les mises à jour',
                        icon: _updateService.isChecking 
                            ? null 
                            : CupertinoIcons.arrow_clockwise,
                        variant: GxFuturisticButtonVariant.secondary,
                        accentColor: accentColor,
                        isLoading: _updateService.isChecking,
                        onPressed: _updateService.isChecking 
                            ? null 
                            : () {
                                _updateService.checkForUpdates();
                                GxNotificationService().showInfo(
                                  title: 'Vérification',
                                  message: 'Recherche de mises à jour en cours...',
                                  context: context,
                                );
                              },
                      );
                    },
                  ),
                ),
                
                if (_updateService.lastCheck != null) ...[
                  SizedBox(height: itemSpacing),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Text(
                      'Dernière vérification: ${_updateService.formatRelativeDate(_updateService.lastCheck!)}',
                      style: NotilusFonts.rajdhani(
                        fontSize: isCompact ? 9 : 10,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: itemSpacing),
                
                // Liste des mises à jour
                Expanded(
                  child: ListenableBuilder(
                    listenable: _updateService,
                    builder: (context, _) {
                      final groupedItems = _getGroupedItems();
                      final flatItems = _buildFlatItemsList(groupedItems);
                      
                      if (flatItems.isEmpty && !_updateService.isChecking) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: const Color(0xFF22C55E),
                                size: isCompact ? 48 : isMedium ? 56 : 64,
                              ),
                              SizedBox(height: isCompact ? 12 : 16),
                              Text(
                                'Vous êtes à jour!',
                                style: NotilusFonts.rajdhani(
                                  fontSize: isCompact ? 14 : isMedium ? 15 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isCompact ? 6 : 8),
                              Text(
                                'Notilus v${_updateService.version}',
                                style: NotilusFonts.rajdhani(
                                  fontSize: isCompact ? 10 : (isMedium ? 11 : 12),
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
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
                            final update = itemData.update!;
                            return RepaintBoundary(
                              key: ValueKey('update_${update.title}_${update.date}'),
                              child: _UpdateListItem(
                                update: update,
                                accentColor: accentColor,
                                bgColor: bgColor,
                                panelOpacity: panelOpacity,
                                isCompact: isCompact,
                                isMedium: isMedium,
                                relativeDate: _updateService.formatRelativeDate(update.date),
                              ),
                            );
                          }
                        },
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

  List<_ListItemData> _buildFlatItemsList(Map<String, List<UpdateInfo>> groupedItems) {
    final flatItems = <_ListItemData>[];
    final orderedPeriods = ['Aujourd\'hui', 'Hier', 'Cette semaine', 'Ce mois', 'Plus ancien'];
    
    bool isFirst = true;
    for (final period in orderedPeriods) {
      final items = groupedItems[period];
      if (items != null && items.isNotEmpty) {
        final isExpanded = _expandedPeriods[period] ?? true;
        
        // Ajouter le séparateur
        flatItems.add(_ListItemData(
          type: _ListItemType.separator,
          period: period,
          isExpanded: isExpanded,
          isFirst: isFirst,
        ));
        isFirst = false;
        
        // Ajouter les items si la période est expandée
        if (isExpanded) {
          for (final item in items) {
            flatItems.add(_ListItemData(
              type: _ListItemType.update,
              update: item,
            ));
          }
        }
      }
    }
    
    return flatItems;
  }
}

enum _ListItemType { separator, update }

class _ListItemData {
  final _ListItemType type;
  final UpdateInfo? update;
  final String? period;
  final bool? isExpanded;
  final bool isFirst;

  _ListItemData({
    required this.type,
    this.update,
    this.period,
    this.isExpanded,
    this.isFirst = false,
  });
}

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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          border: Border(
            left: BorderSide(
              color: accentColor,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: NotilusFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _UpdateListItem extends StatefulWidget {
  final UpdateInfo update;
  final Color accentColor;
  final Color bgColor;
  final double panelOpacity;
  final bool isCompact;
  final bool isMedium;
  final String relativeDate;

  const _UpdateListItem({
    required this.update,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.isCompact,
    required this.isMedium,
    required this.relativeDate,
  });

  @override
  State<_UpdateListItem> createState() => _UpdateListItemState();
}

class _UpdateListItemState extends State<_UpdateListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final titleFontSize = widget.isCompact ? 11.0 : widget.isMedium ? 12.0 : 14.0;
    final descFontSize = widget.isCompact ? 9.0 : widget.isMedium ? 10.0 : 12.0;
    final itemPadding = widget.isCompact ? 8.0 : widget.isMedium ? 10.0 : 12.0;
    final itemSpacing = widget.isCompact ? 6.0 : widget.isMedium ? 8.0 : 12.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: itemSpacing),
        padding: EdgeInsets.all(itemPadding),
        decoration: BoxDecoration(
          color: widget.bgColor.withOpacity(widget.panelOpacity * 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: widget.update.isNew 
                  ? widget.accentColor 
                  : Colors.white.withOpacity(0.1),
              width: _isHovered ? 4 : 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.update.category.icon,
                  style: TextStyle(fontSize: widget.isCompact ? 14 : 16),
                ),
                SizedBox(width: itemPadding),
                if (widget.update.isNew)
                  GxFuturisticBadge(
                    label: 'NOUVEAU',
                    color: widget.accentColor,
                  ),
                const Spacer(),
                GxFuturisticChip(
                  label: widget.update.category.label,
                  accentColor: widget.accentColor,
                ),
              ],
            ),
            SizedBox(height: itemSpacing),
            Text(
              widget.update.title,
              style: NotilusFonts.rajdhani(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: widget.isCompact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: itemPadding / 2),
            Text(
              widget.update.description,
              style: NotilusFonts.rajdhani(
                fontSize: descFontSize,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: widget.isCompact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: itemSpacing),
            Row(
              children: [
                Icon(
                  CupertinoIcons.time,
                  size: widget.isCompact ? 10 : 12,
                  color: Colors.white.withOpacity(0.4),
                ),
                SizedBox(width: 4),
                Text(
                  widget.relativeDate,
                  style: NotilusFonts.rajdhani(
                    fontSize: widget.isCompact ? 9 : 10,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
