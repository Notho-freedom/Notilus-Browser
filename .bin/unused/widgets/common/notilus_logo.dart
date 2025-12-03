import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/notilus_colors.dart';

/// Logo Notilus unifié - Version complète avec animations
/// Utilisé dans la splash screen et les zones de marque
class NotilusLogo extends StatefulWidget {
  final double size;
  final bool animated;
  final bool showText;
  final bool showGlow;
  final bool showParticles;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Duration animationDuration;

  const NotilusLogo({
    super.key,
    this.size = 120,
    this.animated = true,
    this.showText = true,
    this.showGlow = true,
    this.showParticles = true,
    this.primaryColor,
    this.secondaryColor,
    this.animationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<NotilusLogo> createState() => _NotilusLogoState();
}

class _NotilusLogoState extends State<NotilusLogo>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Animation principale d'entrée
    _mainController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_mainController);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Animation de pulsation continue
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation de rotation subtile
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _rotateAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    if (widget.animated) {
      _mainController.forward();
      _pulseController.repeat(reverse: true);
      _rotateController.repeat(reverse: true);
    } else {
      _mainController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? NotilusColors.neonRed;
    final secondary = widget.secondaryColor ?? Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _pulseController, _rotateController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo principal
          _NotilusLogoMark(
            size: widget.size,
            primary: primary,
            secondary: secondary,
            showGlow: widget.showGlow,
            showParticles: widget.showParticles && widget.animated,
          ),
          if (widget.showText) ...[
            SizedBox(height: widget.size * 0.2),
            _NotilusLogoText(
              size: widget.size,
              primary: primary,
            ),
          ],
        ],
      ),
    );
  }
}

/// Marque graphique du logo Notilus (le "N" stylisé)
class _NotilusLogoMark extends StatelessWidget {
  final double size;
  final Color primary;
  final Color secondary;
  final bool showGlow;
  final bool showParticles;

  const _NotilusLogoMark({
    required this.size,
    required this.primary,
    required this.secondary,
    this.showGlow = true,
    this.showParticles = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow externe
          if (showGlow)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: size * 0.5,
                    spreadRadius: size * 0.1,
                  ),
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: size * 0.8,
                    spreadRadius: size * 0.2,
                  ),
                ],
              ),
            ),

          // Cercle de fond avec gradient
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A1A24),
                  const Color(0xFF0D0D14),
                  const Color(0xFF050508),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                width: 2,
                color: primary.withOpacity(0.6),
              ),
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),

          // Cercle intérieur décoratif
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 1,
                color: primary.withOpacity(0.15),
              ),
            ),
          ),

          // Le "N" stylisé avec design nautique/sous-marin
          CustomPaint(
            size: Size(size * 0.55, size * 0.55),
            painter: _NotilusNPainter(
              primary: primary,
              secondary: secondary,
              showGlow: showGlow,
            ),
          ),

          // Particules flottantes
          if (showParticles) _FloatingParticles(size: size, color: primary),
        ],
      ),
    );
  }
}

/// Painter personnalisé pour le "N" de Notilus
class _NotilusNPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final bool showGlow;

  _NotilusNPainter({
    required this.primary,
    required this.secondary,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.12;
    final barHeight = size.height * 0.75;

    // Peinture pour la barre gauche (rouge/primary)
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary,
          primary.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height))
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Peinture pour la barre droite (blanche/secondary)
    final rightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          secondary,
          secondary.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height))
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glow pour les barres
    if (showGlow) {
      final glowPaint = Paint()
        ..color = primary.withOpacity(0.5)
        ..strokeWidth = strokeWidth * 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth);

      // Dessiner le glow de la barre gauche
      canvas.drawLine(
        Offset(center.dx - size.width * 0.2, center.dy - barHeight / 2),
        Offset(center.dx - size.width * 0.2, center.dy + barHeight / 2),
        glowPaint,
      );

      // Dessiner le glow de la diagonale
      canvas.drawLine(
        Offset(center.dx - size.width * 0.2, center.dy - barHeight / 2),
        Offset(center.dx + size.width * 0.2, center.dy + barHeight / 2),
        glowPaint,
      );
    }

    // Dessiner la barre verticale gauche
    canvas.drawLine(
      Offset(center.dx - size.width * 0.2, center.dy - barHeight / 2),
      Offset(center.dx - size.width * 0.2, center.dy + barHeight / 2),
      leftPaint,
    );

    // Dessiner la barre verticale droite
    canvas.drawLine(
      Offset(center.dx + size.width * 0.2, center.dy - barHeight / 2),
      Offset(center.dx + size.width * 0.2, center.dy + barHeight / 2),
      rightPaint,
    );

    // Dessiner la diagonale du N (du haut gauche au bas droit)
    final diagonalPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary,
          secondary,
        ],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height))
      ..strokeWidth = strokeWidth * 0.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - size.width * 0.2, center.dy - barHeight / 2),
      Offset(center.dx + size.width * 0.2, center.dy + barHeight / 2),
      diagonalPaint,
    );

    // Points décoratifs aux extrémités
    final dotPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - size.width * 0.2, center.dy - barHeight / 2),
      strokeWidth * 0.4,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(center.dx + size.width * 0.2, center.dy + barHeight / 2),
      strokeWidth * 0.4,
      dotPaint..color = secondary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Texte du logo Notilus
class _NotilusLogoText extends StatelessWidget {
  final double size;
  final Color primary;

  const _NotilusLogoText({
    required this.size,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nom principal
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              primary,
              Colors.white,
              primary.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            'NOTILUS',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w900,
              letterSpacing: size * 0.04,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: primary.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: size * 0.02),
        // Tagline
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.1,
            vertical: size * 0.02,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: primary.withOpacity(0.4),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'DEVELOPER BROWSER',
            style: TextStyle(
              fontSize: size * 0.08,
              fontWeight: FontWeight.w600,
              letterSpacing: size * 0.02,
              color: primary.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// Particules flottantes animées autour du logo
class _FloatingParticles extends StatefulWidget {
  final double size;
  final Color color;

  const _FloatingParticles({
    required this.size,
    required this.color,
  });

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Générer les particules
    final random = math.Random(42);
    _particles = List.generate(8, (index) {
      final angle = (index / 8) * 2 * math.pi;
      return _Particle(
        angle: angle,
        radius: widget.size * (0.45 + random.nextDouble() * 0.1),
        size: widget.size * (0.015 + random.nextDouble() * 0.02),
        speed: 0.5 + random.nextDouble() * 0.5,
        opacity: 0.3 + random.nextDouble() * 0.5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double radius;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final currentAngle = particle.angle + progress * 2 * math.pi * particle.speed;
      final x = center.dx + math.cos(currentAngle) * particle.radius;
      final y = center.dy + math.sin(currentAngle) * particle.radius;

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * (0.5 + 0.5 * math.sin(progress * 2 * math.pi + particle.angle)))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);

      // Trail effect
      for (int i = 1; i <= 3; i++) {
        final trailAngle = currentAngle - (i * 0.1);
        final trailX = center.dx + math.cos(trailAngle) * particle.radius;
        final trailY = center.dy + math.sin(trailAngle) * particle.radius;
        final trailPaint = Paint()
          ..color = color.withOpacity(particle.opacity * (1 - i * 0.3) * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(trailX, trailY), particle.size * (1 - i * 0.2), trailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Version compacte du logo pour la sidebar et les icônes
class NotilusLogoCompact extends StatelessWidget {
  final double size;
  final bool showGlow;
  final Color? primaryColor;
  final Color? secondaryColor;

  const NotilusLogoCompact({
    super.key,
    this.size = 32,
    this.showGlow = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? NotilusColors.neonRed;
    final secondary = secondaryColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A24),
            const Color(0xFF0D0D14),
          ],
        ),
        border: Border.all(
          color: primary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.5, size * 0.5),
          painter: _NotilusNPainter(
            primary: primary,
            secondary: secondary,
            showGlow: false,
          ),
        ),
      ),
    );
  }
}
