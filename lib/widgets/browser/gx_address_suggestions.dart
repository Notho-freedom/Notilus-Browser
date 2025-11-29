import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../../services/tab_manager.dart';
import '../../services/favicon_service.dart';
import '../../core/animations/notilus_animations.dart';
import 'address_suggestions.dart';
import '../common/gx_futuristic_components.dart';

/// Suggestions d'autocomplétion dans le style Notilus GX futuriste
/// Utilise les standards définis dans gx_test_panel
class GXAddressSuggestions extends StatelessWidget {
  final List<SuggestionItem> items;
  final Function(SuggestionItem) onSelect;

  const GXAddressSuggestions({
    super.key,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final accentColor = NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    
    return RepaintBoundary(
      child: _GXAddressSuggestionsContent(
        items: items,
        onSelect: onSelect,
        accentColor: accentColor,
        bgColor: bgColor,
        panelOpacity: panelOpacity,
      ),
    );
  }
}

/// Contenu optimisé des suggestions pour éviter les reconstructions
class _GXAddressSuggestionsContent extends StatelessWidget {
  final List<SuggestionItem> items;
  final Function(SuggestionItem) onSelect;
  final Color accentColor;
  final Color bgColor;
  final double panelOpacity;

  const _GXAddressSuggestionsContent({
    required this.items,
    required this.onSelect,
    required this.accentColor,
    required this.bgColor,
    required this.panelOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 300,
            minWidth: 0,
          ),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: panelOpacity.clamp(0.0, 1.0)),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Contours géométriques (comme dans GxFuturisticCard)
              _GeometricBorders(accentColor: accentColor),
              // Liste des suggestions avec animations staggerées et scroll quasi invisible
              ScrollbarTheme(
                data: ScrollbarThemeData(
                  thickness: MaterialStateProperty.all(2.0),
                  radius: const Radius.circular(1),
                  thumbColor: MaterialStateProperty.all(
                    accentColor.withValues(alpha: 0.15),
                  ),
                  minThumbLength: 20,
                  crossAxisMargin: 2,
                ),
                child: Scrollbar(
                  thumbVisibility: false,
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                    itemCount: items.take(8).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 0),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return RepaintBoundary(
                        key: ValueKey('suggestion_${item.url}'), // Clé pour maintenir l'état
                        child: StaggeredListItem(
                          index: index,
                          baseDelay: const Duration(milliseconds: 50),
                          itemDelay: const Duration(milliseconds: 30),
                          child: _CompactSuggestionItem(
                            key: ValueKey('item_${item.url}'), // Clé pour éviter les reconstructions
                            item: item,
                            accentColor: accentColor,
                            onSelect: onSelect,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contours géométriques pour les bordures (copié de GxFuturisticCard)
class _GeometricBorders extends StatelessWidget {
  final Color accentColor;

  const _GeometricBorders({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GeometricBordersPainter(accentColor: accentColor),
      child: const SizedBox.expand(),
    );
  }
}

class _GeometricBordersPainter extends CustomPainter {
  final Color accentColor;

  _GeometricBordersPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const cornerSize = 12.0;
    const lineLength = 8.0;

    // Coin supérieur gauche
    canvas.drawLine(Offset(0, cornerSize), Offset(0, cornerSize + lineLength), paint);
    canvas.drawLine(Offset(cornerSize, 0), Offset(cornerSize + lineLength, 0), paint);

    // Coin supérieur droit
    canvas.drawLine(Offset(size.width, cornerSize), Offset(size.width, cornerSize + lineLength), paint);
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width - cornerSize - lineLength, 0), paint);

    // Coin inférieur gauche
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height - cornerSize - lineLength), paint);
    canvas.drawLine(Offset(cornerSize, size.height), Offset(cornerSize + lineLength, size.height), paint);

    // Coin inférieur droit
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height - cornerSize - lineLength), paint);
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width - cornerSize - lineLength, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Item de suggestion compact avec taille réduite
class _CompactSuggestionItem extends StatefulWidget {
  final SuggestionItem item;
  final Color accentColor;
  final Function(SuggestionItem) onSelect;

  const _CompactSuggestionItem({
    super.key,
    required this.item,
    required this.accentColor,
    required this.onSelect,
  });

  @override
  State<_CompactSuggestionItem> createState() => _CompactSuggestionItemState();
}

class _CompactSuggestionItemState extends State<_CompactSuggestionItem> {
  // Cache le Future pour éviter de le recréer à chaque build
  Future<String?>? _faviconFuture;
  
  @override
  void initState() {
    super.initState();
    // Charger le favicon une seule fois
    _faviconFuture = FaviconService.getFaviconWithCache(widget.item.url);
  }
  
  @override
  void didUpdateWidget(_CompactSuggestionItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'URL change, recharger le favicon
    if (oldWidget.item.url != widget.item.url) {
      _faviconFuture = FaviconService.getFaviconWithCache(widget.item.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final url = widget.item.url;
    
    // Vérifier si un onglet avec cette URL est déjà ouvert
    final isTabOpen = tabManager.tabs.any((tab) => tab.url == url);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Appeler onSelect quand on clique sur l'item
          widget.onSelect(widget.item);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Favicon réel du site (avec cache)
              FutureBuilder<String?>(
                key: ValueKey('favicon_${widget.item.url}'), // Clé pour maintenir l'état
                future: _faviconFuture,
                builder: (context, faviconSnapshot) {
                return Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: faviconSnapshot.hasData && faviconSnapshot.data != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            faviconSnapshot.data!,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              widget.item.icon,
                              size: 11,
                              color: widget.accentColor,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Icon(
                                widget.item.icon,
                                size: 11,
                                color: widget.accentColor,
                              );
                            },
                            cacheWidth: 18, // Optimisation : limiter la taille en cache
                            cacheHeight: 18,
                          ),
                        )
                      : Icon(
                          widget.item.icon,
                          size: 11,
                          color: widget.accentColor,
                        ),
                );
                },
              ),
              const SizedBox(width: 10),
              // Titre et URL sur la même ligne
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.item.title,
                        style: NotilusFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.item.subtitle != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: Text(
                          widget.item.subtitle!,
                          style: NotilusFonts.rajdhani(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Bouton "passer à" si l'onglet est déjà ouvert
              if (isTabOpen) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    try {
                      final tab = tabManager.tabs.firstWhere((tab) => tab.url == url);
                      tabManager.selectTab(tab.id);
                    } catch (_) {
                      // Onglet non trouvé, ignorer
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        try {
                          final tab = tabManager.tabs.firstWhere((tab) => tab.url == url);
                          tabManager.selectTab(tab.id);
                        } catch (_) {
                          // Onglet non trouvé, ignorer
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Passer à',
                      style: NotilusFonts.rajdhani(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor,
                      ),
                    ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
