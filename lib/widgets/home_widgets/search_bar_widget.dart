/// Widget autonome pour une barre de recherche
library search_bar_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Widget autonome pour une barre de recherche
class SearchBarWidget extends StatefulWidget {
  final Color? accentColor;
  final double transparency;
  final String? hintText;
  final double? maxWidth;
  final List<Color>? gradientColors;

  const SearchBarWidget({
    super.key,
    this.accentColor,
    this.transparency = 0.0,
    this.hintText,
    this.maxWidth,
    this.gradientColors,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    final tabManager = Provider.of<TabManager>(context, listen: false);
    String url = query.trim();
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      }
    }
    tabManager.addTab(url: url);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = widget.accentColor ?? colorTheme.nativeSecondaryColor;
    final gradientColors = widget.gradientColors ?? [
      accentColor.withOpacity(0.6),
      accentColor.withOpacity(0.4),
    ];
    
    return Container(
      constraints: widget.maxWidth != null 
          ? BoxConstraints(maxWidth: widget.maxWidth!)
          : null,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: gradientColors),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.black.withOpacity((1 - widget.transparency).clamp(0.0, 1.0)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(CupertinoIcons.search, size: 20, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'JetBrains Mono',
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Search docs, packages, or navigate...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                    fontFamily: 'JetBrains Mono',
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onSubmitted: _handleSearch,
                cursorColor: accentColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ENTER',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

