import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/tab_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Page d'accueil ultra moderne style Opera GX++
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _particlesController;
  
  final List<SpeedDialTile> _speedDialTiles = [
    SpeedDialTile(
      name: 'GitHub',
      url: 'https://github.com',
      emoji: '💻',
      gradient: [Color(0xFF6E40C9), Color(0xFF8E2DE2)],
    ),
    SpeedDialTile(
      name: 'YouTube',
      url: 'https://www.youtube.com',
      emoji: '▶️',
      gradient: [Color(0xFFFF0000), Color(0xFFCC0000)],
    ),
    SpeedDialTile(
      name: 'ChatGPT',
      url: 'https://chat.openai.com',
      emoji: '🤖',
      gradient: [Color(0xFF10A37F), Color(0xFF0D8A6B)],
    ),
    SpeedDialTile(
      name: 'Twitter',
      url: 'https://twitter.com',
      emoji: '𝕏',
      gradient: [Color(0xFF1DA1F2), Color(0xFF0077B5)],
    ),
    SpeedDialTile(
      name: 'Stack Overflow',
      url: 'https://stackoverflow.com',
      emoji: '📚',
      gradient: [Color(0xFFF48024), Color(0xFFD86B1F)],
    ),
    SpeedDialTile(
      name: 'Discord',
      url: 'https://discord.com',
      emoji: '💬',
      gradient: [Color(0xFF5865F2), Color(0xFF4752C4)],
    ),
    SpeedDialTile(
      name: 'Spotify',
      url: 'https://open.spotify.com',
      emoji: '🎵',
      gradient: [Color(0xFF1DB954), Color(0xFF1AA34A)],
    ),
    SpeedDialTile(
      name: 'Reddit',
      url: 'https://www.reddit.com',
      emoji: '🔥',
      gradient: [Color(0xFFFF4500), Color(0xFFCC3700)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _particlesController.dispose();
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
  }

  void _openSpeedDial(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A0010),
            Color(0xFF0A0A0A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Particules animées en arrière-plan
          _buildAnimatedParticles(),
          
          // Grille néon en arrière-plan
          _buildNeonGrid(),
          
          // Contenu principal avec effet de profondeur
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 80),
                      
                      // Logo avec effet holographique
                      _buildHolographicLogo(),
                      
                      SizedBox(height: 60),
                      
                      // Barre de recherche futuriste
                      _buildFuturisticSearchBar(),
                      
                      SizedBox(height: 80),
                    ],
                  ),
                ),
                
                // Grille Speed Dial avec effets 3D
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  sliver: _buildSpeedDialGrid(),
                ),
                
                SliverToBoxAdapter(
                  child: SizedBox(height: 60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedParticles() {
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(
            progress: _particlesController.value,
            color: Color(0xFFFF0040),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildNeonGrid() {
    return Positioned.fill(
      child: CustomPaint(
        painter: NeonGridPainter(),
      ),
    );
  }

  Widget _buildHolographicLogo() {
    return Container(
      child: Column(
        children: [
          // Logo avec effet de chrome
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Color(0xFFFF0040),
                Color(0xFFFF3366),
                Color(0xFF00FFFF),
                Color(0xFFFF0040),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ).createShader(bounds),
            child: Text(
              'NOTILUS',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                fontFamily: 'Roboto Mono',
                color: Colors.white,
                letterSpacing: 16,
                height: 1.2,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 3000.ms,
                color: Color(0xFFFF0040).withOpacity(0.5),
              )
              .then()
              .shake(duration: 1000.ms, hz: 0.5, curve: Curves.easeInOut),
          
          SizedBox(height: 16),
          
          // Sous-titre avec effet typing
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF0040).withOpacity(0.1),
                  Color(0xFFFF0040).withOpacity(0.2),
                  Color(0xFFFF0040).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color(0xFFFF0040).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '> Developer Browser_',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00FFFF),
                fontFamily: 'Roboto Mono',
                letterSpacing: 2,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 300.ms)
              .slideX(begin: -0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildFuturisticSearchBar() {
    return Container(
      constraints: BoxConstraints(maxWidth: 700),
      margin: EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A).withOpacity(0.8),
              Color(0xFF2A1A2A).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            width: 2,
            color: Color(0xFFFF0040).withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF0040).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Color(0xFF00FFFF).withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 24),
            Icon(
              Icons.search_rounded,
              color: Color(0xFFFF0040),
              size: 28,
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Roboto Mono',
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher ou entrer une adresse...',
                  hintStyle: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Roboto Mono',
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onSubmitted: _handleSearch,
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF0040), Color(0xFFFF3366)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF0040).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: 500.ms)
          .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1)),
    );
  }

  Widget _buildSpeedDialGrid() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == _speedDialTiles.length) {
            return _buildAddTile();
          }
          return _buildSpeedDialTile(_speedDialTiles[index], index);
        },
        childCount: _speedDialTiles.length + 1,
      ),
    );
  }

  Widget _buildSpeedDialTile(SpeedDialTile tile, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openSpeedDial(tile.url),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A1A).withOpacity(0.6),
                Color(0xFF2A1A2A).withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 1.5,
              color: tile.gradient.first.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: tile.gradient.first.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Effet de brillance en arrière-plan
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          tile.gradient.first.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Contenu
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône avec effet 3D
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: tile.gradient,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: tile.gradient.first.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            tile.emoji,
                            style: TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Nom avec effet néon
                      Text(
                        tile.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Roboto Mono',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: tile.gradient.first.withOpacity(0.8),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (index * 50).ms)
            .scale(
              begin: Offset(0.8, 0.8),
              end: Offset(1, 1),
              delay: (index * 50).ms,
            )
            .then()
            .shimmer(
              duration: 2000.ms,
              delay: (index * 100).ms,
            ),
      ),
    );
  }

  Widget _buildAddTile() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: 2,
          color: Color(0xFF333333),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add_rounded,
          color: Color(0xFF666666),
          size: 40,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1));
  }
}

class SpeedDialTile {
  final String name;
  final String url;
  final String emoji;
  final List<Color> gradient;

  SpeedDialTile({
    required this.name,
    required this.url,
    required this.emoji,
    required this.gradient,
  });
}

/// Peintre pour les particules animées
class ParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Créer des particules qui flottent
    for (int i = 0; i < 30; i++) {
      final offsetX = (i * 37.5) % size.width;
      final offsetY = ((progress * size.height * 0.3) + (i * 50)) % size.height;
      final opacity = (math.sin(progress * math.pi * 2 + i) + 1) / 2;
      
      paint.color = color.withOpacity(opacity * 0.1);
      
      canvas.drawCircle(
        Offset(offsetX, offsetY),
        2 + (opacity * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

/// Peintre pour la grille néon
class NeonGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFFF0040).withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = 80.0;

    // Lignes horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Lignes verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Points de connexion brillants
    final pointPaint = Paint()
      ..color = Color(0xFFFF0040).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
