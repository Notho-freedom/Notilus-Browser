import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../../services/tab_manager.dart';
import '../../../core/services/wallpaper_manager.dart';
import '../../../services/settings_service.dart';
import '../../../core/services/color_theme_manager.dart';
import '../../common/notilus_logo_image.dart';

/// Page d'accueil Frontend Developer - Style moderne avec focus sur CSS/HTML/JS
class FrontendHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  final VoidCallback? onDevToolsSelected;
  
  const FrontendHomePage({
    super.key,
    this.onTerminalSelected,
    this.onDevToolsSelected,
  });

  @override
  State<FrontendHomePage> createState() => _FrontendHomePageState();
}

class _FrontendHomePageState extends State<FrontendHomePage> 
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SettingsService _settings = SettingsService();
  late AnimationController _gradientController;
  late AnimationController _floatingController;
  String _currentTime = '';
  String _greeting = '';

  // Ressources Frontend populaires
  final List<_FrontendResource> _resources = [
    _FrontendResource('React', 'https://react.dev', '⚛️', const Color(0xFF61DAFB)),
    _FrontendResource('Vue.js', 'https://vuejs.org', '💚', const Color(0xFF42B883)),
    _FrontendResource('Angular', 'https://angular.io', '🔺', const Color(0xFFDD0031)),
    _FrontendResource('Svelte', 'https://svelte.dev', '🔥', const Color(0xFFFF3E00)),
    _FrontendResource('Next.js', 'https://nextjs.org', '▲', const Color(0xFF000000)),
    _FrontendResource('Tailwind', 'https://tailwindcss.com', '💨', const Color(0xFF06B6D4)),
    _FrontendResource('TypeScript', 'https://typescriptlang.org', '📘', const Color(0xFF3178C6)),
    _FrontendResource('Vite', 'https://vitejs.dev', '⚡', const Color(0xFFBD34FE)),
  ];

  final List<_ToolCategory> _toolCategories = [
    _ToolCategory('Design', CupertinoIcons.paintbrush, [
      _DevTool('Figma', 'https://figma.com', const Color(0xFFA259FF)),
      _DevTool('Dribbble', 'https://dribbble.com', const Color(0xFFEA4C89)),
      _DevTool('Behance', 'https://behance.net', const Color(0xFF1769FF)),
      _DevTool('Coolors', 'https://coolors.co', const Color(0xFF0B3D91)),
    ]),
    _ToolCategory('CSS Tools', CupertinoIcons.wand_stars, [
      _DevTool('CSS-Tricks', 'https://css-tricks.com', const Color(0xFFFF6B35)),
      _DevTool('Animista', 'https://animista.net', const Color(0xFFE91E63)),
      _DevTool('Neumorphism', 'https://neumorphism.io', const Color(0xFF5E35B1)),
      _DevTool('Glassmorphism', 'https://ui.glass', const Color(0xFF00BCD4)),
    ]),
    _ToolCategory('Icons & Assets', CupertinoIcons.sparkles, [
      _DevTool('Heroicons', 'https://heroicons.com', const Color(0xFF8B5CF6)),
      _DevTool('Lucide', 'https://lucide.dev', const Color(0xFFF56565)),
      _DevTool('Unsplash', 'https://unsplash.com', const Color(0xFF111111)),
      _DevTool('LottieFiles', 'https://lottiefiles.com', const Color(0xFF00DDB3)),
    ]),
  ];

  // Citations inspirantes pour développeurs frontend
  final List<String> _quotes = [
    "Design is not just what it looks like. Design is how it works. — Steve Jobs",
    "The details are not the details. They make the design. — Charles Eames",
    "Good design is obvious. Great design is transparent. — Joe Sparano",
    "Simplicity is the ultimate sophistication. — Leonardo da Vinci",
  ];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _updateTime();
    _startClock();
    _settings.addListener(_onSettingsChanged);
  }

  void _startClock() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _updateTime();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _greeting = _getGreeting(now.hour);
    });
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatingController.dispose();
    _searchController.dispose();
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
    final currentUrl = wallpaperManager.current;

    return Container(
      decoration: BoxDecoration(
        image: currentUrl.isNotEmpty && !wallpaperManager.isVideo
            ? DecorationImage(
                image: CachedNetworkImageProvider(currentUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.85),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Animated gradient background effect
          _buildAnimatedBackground(gxRed),
          
          // Floating CSS/HTML elements
          _buildFloatingElements(gxRed),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(gxRed),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hero section avec salutation
                        _buildHeroSection(gxRed, transparency),
                        
                        const SizedBox(height: 40),
                        
                        // Barre de recherche élégante
                        _buildSearchBar(gxRed, transparency),
                        
                        const SizedBox(height: 48),
                        
                        // Frameworks rapides
                        _buildFrameworksSection(gxRed, transparency),
                        
                        const SizedBox(height: 48),
                        
                        // Catégories d'outils
                        _buildToolCategories(gxRed, transparency),
                        
                        const SizedBox(height: 48),
                        
                        // Citation inspirante
                        if (_settings.showQuotes)
                          _buildQuoteSection(gxRed, transparency),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Color gxRed) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientMeshPainter(
            progress: _gradientController.value,
            primaryColor: gxRed,
            secondaryColor: const Color(0xFF61DAFB),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingElements(Color gxRed) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating CSS brackets
            Positioned(
              left: 50,
              top: 150 + (_floatingController.value * 20),
              child: Opacity(
                opacity: 0.1,
                child: Text(
                  '{ }',
                  style: TextStyle(
                    fontSize: 80,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w200,
                    color: gxRed,
                  ),
                ),
              ),
            ),
            // Floating HTML tags
            Positioned(
              right: 80,
              top: 200 + (_floatingController.value * 15),
              child: Opacity(
                opacity: 0.08,
                child: Text(
                  '</>',
                  style: TextStyle(
                    fontSize: 100,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w200,
                    color: const Color(0xFF61DAFB),
                  ),
                ),
              ),
            ),
            // Floating arrow function
            Positioned(
              left: 150,
              bottom: 200 + (_floatingController.value * 25),
              child: Opacity(
                opacity: 0.06,
                child: Text(
                  '() =>',
                  style: TextStyle(
                    fontSize: 60,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w200,
                    color: const Color(0xFFF7DF1E),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(Color gxRed) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const NotilusMonogramImage(size: 24),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF61DAFB).withOpacity(0.2),
                  const Color(0xFF42B883).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF61DAFB).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚛️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'FRONTEND',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF61DAFB),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_settings.showClock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gxRed.withOpacity(0.2)),
              ),
              child: Text(
                _currentTime,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildHeroSection(Color gxRed, double transparency) {
    final customGreeting = _settings.customGreeting;
    return Column(
      children: [
        Text(
          _greeting,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 2,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              const Color(0xFF61DAFB),
              const Color(0xFF42B883),
              gxRed,
            ],
          ).createShader(bounds),
          child: Text(
            customGreeting.isNotEmpty ? customGreeting : 'Build Beautiful Interfaces',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
        ),
        const SizedBox(height: 12),
        Text(
          'React • Vue • Angular • Svelte • Next.js',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildSearchBar(Color gxRed, double transparency) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 680),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF61DAFB).withOpacity(0.6),
            const Color(0xFF42B883).withOpacity(0.6),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.black.withOpacity(1 - transparency),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(CupertinoIcons.search, size: 20, color: const Color(0xFF61DAFB)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search docs, packages, or navigate...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onSubmitted: _handleSearch,
                cursorColor: const Color(0xFF61DAFB),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF61DAFB).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '⌘K',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: Color(0xFF61DAFB),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
    );
  }

  Widget _buildFrameworksSection(Color gxRed, double transparency) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF61DAFB), const Color(0xFF42B883)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'FRAMEWORKS & LIBRARIES',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF42B883), const Color(0xFF61DAFB)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _resources.asMap().entries.map((entry) {
            return _buildFrameworkCard(entry.value, transparency, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrameworkCard(_FrontendResource resource, double transparency, int index) {
    return GestureDetector(
      onTap: () => _openUrl(resource.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: resource.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                resource.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                resource.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: resource.color,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: (400 + index * 50).ms,
    ).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
    );
  }

  Widget _buildToolCategories(Color gxRed, double transparency) {
    return Column(
      children: _toolCategories.asMap().entries.map((entry) {
        return _buildToolCategorySection(entry.value, transparency, entry.key);
      }).toList(),
    );
  }

  Widget _buildToolCategorySection(_ToolCategory category, double transparency, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 16, color: const Color(0xFF61DAFB)),
              const SizedBox(width: 8),
              Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: category.tools.map((tool) {
              return _buildToolChip(tool, transparency);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: (600 + index * 100).ms,
    ).slideY(begin: 0.1, end: 0);
  }

  Widget _buildToolChip(_DevTool tool, double transparency) {
    return GestureDetector(
      onTap: () => _openUrl(tool.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tool.color.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tool.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tool.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteSection(Color gxRed, double transparency) {
    final quote = _quotes[DateTime.now().day % _quotes.length];
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(1 - transparency),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF61DAFB).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.quote_bubble,
            size: 24,
            color: const Color(0xFF61DAFB).withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 800.ms);
  }
}

// === DATA CLASSES ===

class _FrontendResource {
  final String name;
  final String url;
  final String emoji;
  final Color color;

  const _FrontendResource(this.name, this.url, this.emoji, this.color);
}

class _ToolCategory {
  final String name;
  final IconData icon;
  final List<_DevTool> tools;

  const _ToolCategory(this.name, this.icon, this.tools);
}

class _DevTool {
  final String name;
  final String url;
  final Color color;

  const _DevTool(this.name, this.url, this.color);
}

// === PAINTERS ===

class _GradientMeshPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _GradientMeshPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          math.cos(progress * 2 * math.pi) * 0.5,
          math.sin(progress * 2 * math.pi) * 0.5,
        ),
        radius: 1.5,
        colors: [
          primaryColor.withOpacity(0.05),
          secondaryColor.withOpacity(0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_GradientMeshPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
