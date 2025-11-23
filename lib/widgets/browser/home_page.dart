import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/theme_extensions.dart';
import '../../services/tab_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Page d'accueil moderne style Opera GX (Speed Dial)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Sites web populaires pour les tuiles
  final List<SpeedDialTile> _speedDialTiles = [
    SpeedDialTile(
      name: 'Twitch',
      url: 'https://www.twitch.tv',
      icon: '🎮',
      color: Color(0xFF9146FF),
    ),
    SpeedDialTile(
      name: 'YouTube',
      url: 'https://www.youtube.com',
      icon: '▶️',
      color: Color(0xFFFF0000),
    ),
    SpeedDialTile(
      name: 'GitHub',
      url: 'https://github.com',
      icon: '💻',
      color: Color(0xFF24292E),
    ),
    SpeedDialTile(
      name: 'Stack Overflow',
      url: 'https://stackoverflow.com',
      icon: '📚',
      color: Color(0xFFF48024),
    ),
    SpeedDialTile(
      name: 'Discord',
      url: 'https://discord.com',
      icon: '💬',
      color: Color(0xFF5865F2),
    ),
    SpeedDialTile(
      name: 'Reddit',
      url: 'https://www.reddit.com',
      icon: '🤖',
      color: Color(0xFFFF4500),
    ),
    SpeedDialTile(
      name: 'ChatGPT',
      url: 'https://chat.openai.com',
      icon: '🤖',
      color: Color(0xFF10A37F),
    ),
    SpeedDialTile(
      name: 'Amazon',
      url: 'https://www.amazon.com',
      icon: '📦',
      color: Color(0xFFFF9900),
    ),
    SpeedDialTile(
      name: 'Netflix',
      url: 'https://www.netflix.com',
      icon: '🎬',
      color: Color(0xFFE50914),
    ),
    SpeedDialTile(
      name: 'Spotify',
      url: 'https://open.spotify.com',
      icon: '🎵',
      color: Color(0xFF1DB954),
    ),
    SpeedDialTile(
      name: 'Twitter',
      url: 'https://twitter.com',
      icon: '🐦',
      color: Color(0xFF1DA1F2),
    ),
    SpeedDialTile(
      name: 'Instagram',
      url: 'https://www.instagram.com',
      icon: '📷',
      color: Color(0xFFE4405F),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    final tabManager = Provider.of<TabManager>(context, listen: false);
    
    // Si c'est une URL, naviguer directement
    String url = query.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Si ça ressemble à une URL (contient un point), ajouter https://
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        // Sinon, recherche Google
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      }
    }

    // Créer un nouvel onglet avec l'URL
    tabManager.addTab(url: url);
  }

  void _openSpeedDial(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final customTheme = theme as dynamic;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0D0D),
            Color(0xFF1A0A0A),
            Color(0xFF0D0D0D),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Fond animé avec effets de circuit
          _buildAnimatedBackground(),
          
          // Contenu principal
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo Notilus
                  _buildLogo(),
                  
                  const SizedBox(height: 40),
                  
                  // Barre de recherche
                  _buildSearchBar(theme),
                  
                  const SizedBox(height: 50),
                  
                  // Grille de Speed Dial
                  _buildSpeedDialGrid(theme),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CircuitBoardPainter(),
        child: Container(),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 3000.ms, color: Color(0xFFFF0040).withOpacity(0.3));
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Text(
          'NOTILUS',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Mono',
            color: Color(0xFFFF0040),
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: Color(0xFFFF0040).withOpacity(0.8),
                blurRadius: 20,
              ),
              Shadow(
                color: Color(0xFFFF0040).withOpacity(0.4),
                blurRadius: 40,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, end: 0),
        const SizedBox(height: 8),
        Text(
          'Navigateur pour développeurs',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
            fontFamily: 'Roboto Mono',
            letterSpacing: 2,
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms, delay: 200.ms)
            .slideY(begin: -0.2, end: 0),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme theme) {
    return Container(
      constraints: BoxConstraints(maxWidth: 600),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: false,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Roboto Mono',
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher sur le web ou entrer une adresse',
          hintStyle: TextStyle(
            color: Color(0xFF666666),
            fontFamily: 'Roboto Mono',
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFFFF0040),
          ),
          filled: true,
          fillColor: Color(0xFF1A1A1A).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Color(0xFFFF0040).withOpacity(0.3),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Color(0xFFFF0040).withOpacity(0.3),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Color(0xFFFF0040),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        onSubmitted: _handleSearch,
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: 300.ms)
          .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1)),
    );
  }

  Widget _buildSpeedDialGrid(ColorScheme theme) {
    return Container(
      constraints: BoxConstraints(maxWidth: 1000),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _speedDialTiles.length + 1, // +1 pour le bouton "Ajouter"
        itemBuilder: (context, index) {
          if (index == _speedDialTiles.length) {
            // Bouton "Ajouter"
            return _buildAddTile(theme);
          }
          return _buildSpeedDialTile(_speedDialTiles[index], theme, index);
        },
      ),
    );
  }

  Widget _buildSpeedDialTile(SpeedDialTile tile, ColorScheme theme, int index) {
    return GestureDetector(
      onTap: () => _openSpeedDial(tile.url),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFFFF0040).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: tile.color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tile.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tile.color.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  tile.icon,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tile.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Roboto Mono',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(
            duration: 400.ms,
            delay: (index * 50).ms,
          )
          .scale(
            begin: Offset(0.8, 0.8),
            end: Offset(1, 1),
            delay: (index * 50).ms,
          ),
    );
  }

  Widget _buildAddTile(ColorScheme theme) {
    return GestureDetector(
      onTap: () {
        // TODO: Ouvrir un dialogue pour ajouter un nouveau site
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF333333),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add,
          color: Color(0xFF666666),
          size: 32,
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1)),
    );
  }
}

class SpeedDialTile {
  final String name;
  final String url;
  final String icon;
  final Color color;

  SpeedDialTile({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });
}

/// Peintre pour le fond avec effets de circuit board
class CircuitBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFFF0040).withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Lignes horizontales
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Lignes verticales
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Points de connexion
    final pointPaint = Paint()
      ..color = Color(0xFFFF0040).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 60) {
      for (double y = 0; y < size.height; y += 60) {
        canvas.drawCircle(Offset(x, y), 2, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

