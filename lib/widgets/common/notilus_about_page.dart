import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import 'notilus_logo.dart';

/// Page "À propos de Notilus" avec logo en grand format
/// Peut être affichée en full-screen et capturée
class NotilusAboutPage extends StatelessWidget {
  final bool fullScreen;
  final bool showCaptureButton;

  const NotilusAboutPage({
    super.key,
    this.fullScreen = false,
    this.showCaptureButton = true,
  });

  /// Affiche la page "À propos" en modal full-screen futuriste
  static Future<void> showFullScreen(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => const _FullScreenAboutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;

    return RepaintBoundary(
      key: const ValueKey('notilus_about_page'),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              bgColor,
              bgColor.withOpacity(0.95),
              const Color(0xFF0A0A0F),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Effets de fond décoratifs
            _BackgroundEffects(gxRed: gxRed),
            
            // Contenu principal - Logo uniquement
            SafeArea(
              child: Center(
                child: _LogoSection(gxRed: gxRed, bgColor: bgColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog full-screen pour afficher la page "À propos"
class _FullScreenAboutDialog extends StatelessWidget {
  const _FullScreenAboutDialog();

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = colorThemeManager.nativeSecondaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Page "À propos" en full-screen
          const NotilusAboutPage(
            fullScreen: true,
            showCaptureButton: false,
          ),
          
          // Bouton de fermeture
          Positioned(
            top: 24,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gxRed.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.xmark,
                  color: gxRed,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section du logo en grand format - Juste la marque graphique
class _LogoSection extends StatelessWidget {
  final Color gxRed;
  final Color bgColor;

  const _LogoSection({
    required this.gxRed,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Logo très grand - minimum 600px, jusqu'à 80% de la largeur de l'écran
    final logoSize = screenSize.width > 1000 
        ? 800.0 
        : screenSize.width > 800 
            ? 600.0 
            : screenSize.width * 0.8;

    return NotilusLogo(
      size: logoSize,
      animated: false, // Pas d'animations
      showText: false, // Pas de texte, juste la marque
      showGlow: false, // Pas de lueur rouge
      showParticles: false, // Pas de particules (liées aux animations)
      primaryColor: gxRed,
      secondaryColor: Colors.white,
    );
  }
}


/// Effets de fond décoratifs
class _BackgroundEffects extends StatelessWidget {
  final Color gxRed;

  const _BackgroundEffects({
    required this.gxRed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Cercles décoratifs
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  gxRed.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  gxRed.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Lignes géométriques
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _GeometricLinesPainter(gxRed: gxRed),
        ),
      ],
    );
  }
}

/// Peintre pour les lignes géométriques de fond
class _GeometricLinesPainter extends CustomPainter {
  final Color gxRed;

  _GeometricLinesPainter({required this.gxRed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gxRed.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Lignes diagonales
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width * 0.3, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height),
      Offset(size.width, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

