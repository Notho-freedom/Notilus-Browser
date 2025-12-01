import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/notilus_colors.dart';
import '../core/constants/notilus_fonts.dart';
import '../widgets/common/notilus_logo_image.dart';

/// Splash Screen Notilus - Page de lancement immersive
/// Design inspiré de l'univers sous-marin/nautilus avec effets néon
class NotilusSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;

  const NotilusSplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 3500),
  });

  @override
  State<NotilusSplashScreen> createState() => _NotilusSplashScreenState();
}

class _NotilusSplashScreenState extends State<NotilusSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _waveController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  bool _showVersion = false;
  bool _showLoadingText = false;

  @override
  void initState() {
    super.initState();

    // Contrôleur pour le background animé
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Contrôleur pour les vagues
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Contrôleur pour la barre de progression
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    // Démarrer la séquence d'animation
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showVersion = true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showLoadingText = true);

    // Démarrer la progression
    _progressController.forward();

    // Attendre la fin et appeler onComplete
    await Future.delayed(widget.duration);
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primary = NotilusColors.neonRed;

    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: Stack(
        children: [
          // Background avec effet de profondeur océanique
          _AnimatedOceanBackground(
            controller: _backgroundController,
            size: size,
          ),

          // Vagues animées en fond
          _AnimatedWaves(
            controller: _waveController,
            size: size,
          ),

          // Grille de points style tech
          _TechGrid(size: size),

          // Contenu principal centré
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo Notilus animé
                NotilusLogoImage(
                  size: 160,
                  showGlow: true,
                  glowColor: primary,
                ),

                const SizedBox(height: 60),

                // Version avec animation
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showVersion ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primary.withOpacity(0.3),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      'v1.0.0 BETA',
                      style: NotilusFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Barre de progression stylisée
                _ProgressSection(
                  animation: _progressAnimation,
                  showText: _showLoadingText,
                ),

                const SizedBox(height: 40),

                // Message de chargement
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showLoadingText ? 1.0 : 0.0,
                  child: _LoadingMessages(),
                ),

                const Spacer(),
              ],
            ),
          ),

          // Signature en bas
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showVersion ? 1.0 : 0.0,
              child: Column(
                children: [
                  Text(
                    'POWERED BY NAUTILUS CORE',
                    style: NotilusFonts.rajdhani(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FOR DEVELOPERS',
                        style: NotilusFonts.orbitron(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Background océanique animé
class _AnimatedOceanBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _AnimatedOceanBackground({
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: _OceanBackgroundPainter(
            progress: controller.value,
          ),
        );
      },
    );
  }
}

class _OceanBackgroundPainter extends CustomPainter {
  final double progress;

  _OceanBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient de fond océanique
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment(
        0.3 * math.sin(progress * 2 * math.pi),
        -0.2 + 0.1 * math.cos(progress * 2 * math.pi),
      ),
      radius: 1.2,
      colors: const [
        Color(0xFF0A1628),
        Color(0xFF050D18),
        Color(0xFF020408),
        Color(0xFF000002),
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Lueur subtile rouge
    final glowCenter = Offset(
      size.width / 2 + 100 * math.sin(progress * 2 * math.pi),
      size.height / 3 + 50 * math.cos(progress * 2 * math.pi),
    );

    final glowGradient = RadialGradient(
      colors: [
        NotilusColors.neonRed.withOpacity(0.08),
        NotilusColors.neonRed.withOpacity(0.02),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      glowCenter,
      size.width * 0.4,
      Paint()..shader = glowGradient.createShader(
        Rect.fromCircle(center: glowCenter, radius: size.width * 0.4),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _OceanBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Vagues animées
class _AnimatedWaves extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _AnimatedWaves({
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: _WavesPainter(
            progress: controller.value,
          ),
        );
      },
    );
  }
}

class _WavesPainter extends CustomPainter {
  final double progress;

  _WavesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dessiner plusieurs vagues
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final waveHeight = 20.0 + i * 10;
      final yOffset = size.height * (0.6 + i * 0.08);
      final opacity = 0.1 - i * 0.015;
      final phase = progress * 2 * math.pi + i * 0.5;

      paint.color = NotilusColors.neonRed.withOpacity(opacity.clamp(0.02, 0.1));

      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 10) {
        final y = yOffset + 
            math.sin(x / 80 + phase) * waveHeight +
            math.sin(x / 40 + phase * 1.5) * waveHeight * 0.3;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Grille tech en fond
class _TechGrid extends StatelessWidget {
  final Size size;

  const _TechGrid({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _TechGridPainter(),
    );
  }
}

class _TechGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NotilusColors.neonRed.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const dotSize = 1.5;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        // Effet de fade vers les bords
        final distFromCenter = math.sqrt(
          math.pow((x - size.width / 2) / size.width, 2) +
          math.pow((y - size.height / 2) / size.height, 2),
        );
        final opacity = (0.05 * (1 - distFromCenter)).clamp(0.01, 0.05);
        paint.color = NotilusColors.neonRed.withOpacity(opacity);

        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Section de progression
class _ProgressSection extends StatelessWidget {
  final Animation<double> animation;
  final bool showText;

  const _ProgressSection({
    required this.animation,
    required this.showText,
  });

  @override
  Widget build(BuildContext context) {
    const primary = NotilusColors.neonRed;

    return Column(
      children: [
        // Barre de progression
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: showText ? 1.0 : 0.0,
          child: Container(
            width: 280,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: primary.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            primary.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Pourcentage
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Text(
              '${(animation.value * 100).toInt()}%',
              style: NotilusFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primary.withOpacity(0.8),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Messages de chargement animés
class _LoadingMessages extends StatefulWidget {
  @override
  State<_LoadingMessages> createState() => _LoadingMessagesState();
}

class _LoadingMessagesState extends State<_LoadingMessages> {
  final List<String> _messages = [
    'Initializing Nautilus Core...',
    'Loading browser engine...',
    'Configuring developer tools...',
    'Preparing workspace...',
    'Almost ready...',
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _cycleMessages();
  }

  void _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _messages[_currentIndex],
        key: ValueKey(_currentIndex),
        style: NotilusFonts.rajdhani(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// Décorations des coins
class _CornerDecorations extends StatelessWidget {
  final Size size;

  const _CornerDecorations({required this.size});

  @override
  Widget build(BuildContext context) {
    const primary = NotilusColors.neonRed;
    const cornerSize = 60.0;

    return Stack(
      children: [
        // Coin supérieur gauche
        Positioned(
          top: 20,
          left: 20,
          child: _Corner(size: cornerSize, rotation: 0),
        ),

        // Coin supérieur droit
        Positioned(
          top: 20,
          right: 20,
          child: _Corner(size: cornerSize, rotation: math.pi / 2),
        ),

        // Coin inférieur gauche
        Positioned(
          bottom: 60,
          left: 20,
          child: _Corner(size: cornerSize, rotation: -math.pi / 2),
        ),

        // Coin inférieur droit
        Positioned(
          bottom: 60,
          right: 20,
          child: _Corner(size: cornerSize, rotation: math.pi),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final double size;
  final double rotation;

  const _Corner({
    required this.size,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    const primary = NotilusColors.neonRed;

    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerPainter(color: primary),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 500.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Ligne horizontale
    canvas.drawLine(
      Offset.zero,
      Offset(size.width * 0.6, 0),
      paint,
    );

    // Ligne verticale
    canvas.drawLine(
      Offset.zero,
      Offset(0, size.height * 0.6),
      paint,
    );

    // Point à l'angle
    canvas.drawCircle(
      Offset.zero,
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
