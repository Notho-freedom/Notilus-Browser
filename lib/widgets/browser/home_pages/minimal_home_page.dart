import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/tab_manager.dart';
import '../../../core/services/wallpaper_manager.dart';
import '../../../services/settings_service.dart';
import '../../../core/services/color_theme_manager.dart';
import '../../common/notilus_monogram.dart';

/// Page d'accueil minimaliste - Focus sur l'essentiel, design épuré
class MinimalHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  final VoidCallback? onDevToolsSelected;
  
  const MinimalHomePage({
    super.key,
    this.onTerminalSelected,
    this.onDevToolsSelected,
  });

  @override
  State<MinimalHomePage> createState() => _MinimalHomePageState();
}

class _MinimalHomePageState extends State<MinimalHomePage> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SettingsService _settings = SettingsService();
  late AnimationController _breatheController;
  String _currentTime = '';
  String _currentDate = '';

  // Quelques raccourcis essentiels seulement
  final List<_MinimalLink> _essentials = [
    _MinimalLink('Google', 'https://google.com', CupertinoIcons.search),
    _MinimalLink('GitHub', 'https://github.com', CupertinoIcons.chevron_left_slash_chevron_right),
    _MinimalLink('Gmail', 'https://mail.google.com', CupertinoIcons.mail),
    _MinimalLink('Calendar', 'https://calendar.google.com', CupertinoIcons.calendar),
  ];

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _updateTime();
    _startClock();
    _settings.addListener(_onSettingsChanged);
    
    // Auto-focus la barre de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _startClock() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _updateTime();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    final weekdays = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate = '${weekdays[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
    });
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _openUrl(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
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
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    final wallpaperManager = context.watch<WallpaperManager>();
    final transparency = _settings.widgetTransparency;
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.75),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Subtle gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // Main centered content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Time display (big and elegant)
                if (_settings.showClock)
                  AnimatedBuilder(
                    animation: _breatheController,
                    builder: (context, child) {
                      final opacity = 0.85 + _breatheController.value * 0.15;
                      return Opacity(
                        opacity: opacity,
                        child: Text(
                          _currentTime,
                          style: TextStyle(
                            fontSize: 96,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                            letterSpacing: -4,
                            height: 1,
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 800.ms).scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                  ),
                
                if (_settings.showClock)
                  const SizedBox(height: 8),
                
                // Date
                if (_settings.showClock)
                  Text(
                    _currentDate,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                
                SizedBox(height: _settings.showClock ? 60 : 0),
                
                // Search bar - elegant and minimal
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08 * (1 - transparency)),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rechercher ou saisir une URL',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.35),
                            ),
                            border: InputBorder.none,
                          ),
                          cursorColor: gxRed,
                          onSubmitted: _handleSearch,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(
                  begin: 0.1,
                  end: 0,
                ),
                
                const SizedBox(height: 48),
                
                // Essential links - ultra minimal
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _essentials.asMap().entries.map((entry) {
                    return _buildMinimalLink(entry.value, gxRed, transparency, entry.key);
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Bottom branding - very subtle
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NotilusMonogram(
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notilus',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.25),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 800.ms),
          ),
          
          // Quick actions in corner (very discrete)
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                _buildCornerAction(CupertinoIcons.square_list, widget.onTerminalSelected),
                const SizedBox(width: 8),
                _buildCornerAction(CupertinoIcons.ant, widget.onDevToolsSelected),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalLink(_MinimalLink link, Color gxRed, double transparency, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => _openUrl(link.url),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06 * (1 - transparency)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  link.icon,
                  size: 22,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                link.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: (500 + index * 80).ms,
    ).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCornerAction(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

// === DATA CLASSES ===

class _MinimalLink {
  final String name;
  final String url;
  final IconData icon;

  const _MinimalLink(this.name, this.url, this.icon);
}
