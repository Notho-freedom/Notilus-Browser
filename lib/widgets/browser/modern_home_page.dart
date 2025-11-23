import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModernHomePage extends StatefulWidget {
  const ModernHomePage({super.key});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<QuickAccessItem> _quickAccessItems = [
    QuickAccessItem(
      name: 'GitHub',
      url: 'https://github.com',
      icon: CupertinoIcons.cloud_download,
      color: const Color(0xFF24292E),
    ),
    QuickAccessItem(
      name: 'Google',
      url: 'https://google.com',
      icon: CupertinoIcons.search,
      color: const Color(0xFF4285F4),
    ),
    QuickAccessItem(
      name: 'YouTube',
      url: 'https://youtube.com',
      icon: CupertinoIcons.play_rectangle,
      color: const Color(0xFFFF0000),
    ),
    QuickAccessItem(
      name: 'Stack Overflow',
      url: 'https://stackoverflow.com',
      icon: CupertinoIcons.layers_alt,
      color: const Color(0xFFF48024),
    ),
    QuickAccessItem(
      name: 'Twitter',
      url: 'https://twitter.com',
      icon: CupertinoIcons.at,
      color: const Color(0xFF1DA1F2),
    ),
    QuickAccessItem(
      name: 'LinkedIn',
      url: 'https://linkedin.com',
      icon: CupertinoIcons.briefcase,
      color: const Color(0xFF0077B5),
    ),
    QuickAccessItem(
      name: 'Reddit',
      url: 'https://reddit.com',
      icon: CupertinoIcons.bubble_left_bubble_right,
      color: const Color(0xFFFF4500),
    ),
    QuickAccessItem(
      name: 'Discord',
      url: 'https://discord.com',
      icon: CupertinoIcons.chat_bubble_2,
      color: const Color(0xFF5865F2),
    ),
  ];

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
  }

  void _openQuickAccess(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF000000),
                  const Color(0xFF0A0A0A),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFFFFFFF),
                ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo et titre
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5856D6),
                            Color(0xFF007AFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5856D6).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Bienvenue dans Notilus',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Votre navigateur professionnel',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Barre de recherche
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Rechercher sur le web ou saisir une adresse',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _handleSearch,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () => _handleSearch(_searchController.text),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                
                const SizedBox(height: 60),
                
                // Accès rapide
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _quickAccessItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    
                    return _QuickAccessTile(
                      item: item,
                      onTap: () => _openQuickAccess(item.url),
                      delay: (index * 50).ms,
                    );
                  }).toList(),
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuickAccessItem {
  final String name;
  final String url;
  final IconData icon;
  final Color color;

  QuickAccessItem({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });
}

class _QuickAccessTile extends StatefulWidget {
  final QuickAccessItem item;
  final VoidCallback onTap;
  final Duration delay;

  const _QuickAccessTile({
    required this.item,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<_QuickAccessTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.item.color.withOpacity(0.1)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.item.color.withOpacity(0.3)
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05)),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.item.color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                size: 28,
                color: _isHovered ? widget.item.color : theme.iconTheme.color,
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: widget.delay)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          delay: widget.delay,
        );
  }
}
