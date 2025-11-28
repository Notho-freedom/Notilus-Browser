/// Panel d'historique futuriste Notilus GX
library gx_futuristic_history_panel;

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.getHistory();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _historyService.getHistory();
    });
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.time,
                        color: accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'HISTORIQUE',
                        style: NotilusFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      GxFuturisticButton(
                        label: 'Effacer',
                        icon: CupertinoIcons.delete,
                        variant: GxFuturisticButtonVariant.outline,
                        accentColor: accentColor,
                        onPressed: _clearHistory,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Barre de recherche
                  GxFuturisticInput(
                    controller: _searchController,
                    hint: 'Rechercher dans l\'historique...',
                    prefixIcon: CupertinoIcons.search,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
            
            // Liste
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
                    final filteredItems = _searchQuery.isEmpty
                        ? items
                        : items.where((item) {
                            return item.title.toLowerCase().contains(_searchQuery) ||
                                   item.url.toLowerCase().contains(_searchQuery);
                          }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.time,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun historique'
                                  : 'Aucun résultat',
                              style: NotilusFonts.rajdhani(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Votre historique de navigation apparaîtra ici'
                                  : 'Aucun élément ne correspond à votre recherche',
                              style: NotilusFonts.rajdhani(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => GxFuturisticDivider(
                        accentColor: accentColor,
                        height: 0.5,
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _HistoryListItem(
                          item: item,
                          accentColor: accentColor,
                          bgColor: bgColor,
                          panelOpacity: panelOpacity,
                          dateFormat: dateFormat,
                          onTap: () {
                            final tabManager = Provider.of<TabManager>(context, listen: false);
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

class _HistoryListItem extends StatelessWidget {
  final dynamic item;
  final Color accentColor;
  final Color? bgColor;
  final double panelOpacity;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _HistoryListItem({
    required this.item,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: FaviconService.getFaviconWithCache(item.url),
      builder: (context, faviconSnapshot) {
        return GxFuturisticListItem(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: faviconSnapshot.hasData && faviconSnapshot.data != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      faviconSnapshot.data!,
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => Icon(
                        CupertinoIcons.globe,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                  )
                : Icon(
                    CupertinoIcons.globe,
                    size: 18,
                    color: accentColor,
                  ),
          ),
          title: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NotilusFonts.rajdhani(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NotilusFonts.rajdhani(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(item.visitedAt ?? DateTime.now()),
                style: NotilusFonts.rajdhani(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
          trailing: GxFuturisticButton(
            label: '',
            icon: CupertinoIcons.arrow_right,
            variant: GxFuturisticButtonVariant.ghost,
            accentColor: accentColor,
            width: 32,
            height: 32,
            padding: EdgeInsets.zero,
            onPressed: onTap,
          ),
          onTap: onTap,
          accentColor: accentColor,
        );
      },
    );
  }
}

