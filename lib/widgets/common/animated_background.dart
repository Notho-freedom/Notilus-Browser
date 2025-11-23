import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final bool showGradient;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showGradient = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    if (widget.showParticles) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 2 + 1,
          speed: random.nextDouble() * 0.5 + 0.1,
          direction: random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();
    
    return Stack(
      children: [
        // Animated gradient background
        if (widget.showGradient)
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_gradientController.value * 2 * math.pi) * 0.3,
                      math.cos(_gradientController.value * 2 * math.pi) * 0.3,
                    ),
                    radius: 1.5,
                    colors: [
                      theme.background,
                      theme.background,
                      theme.primary.withOpacity(0.05),
                      theme.background,
                    ],
                    stops: const [0.0, 0.5, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
        
        // Animated particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  primaryColor: theme.primary,
                  accentColor: theme.accent,
                ),
                size: Size.infinite,
              );
            },
          ),
        
        // Content
        widget.child,
      ],
    );
  }

  AppTheme _getThemeFromContext() {
    return const AppTheme(
      name: 'Default',
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF1A1A1A),
      primary: Color(0xFFFF0040),
      secondary: Color(0xFFFF3366),
      accent: Color(0xFF00FF88),
      text: Color(0xFFE0E0E0),
      textSecondary: Color(0xFF888888),
      error: Color(0xFFFF0040),
      success: Color(0xFF00FF88),
      warning: Color(0xFFFFAA00),
      border: Color(0xFF333333),
      hover: Color(0xFF2A2A2A),
      selected: Color(0xFFFF0040),
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  double direction;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.direction,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Update particle position
      particle.x += math.cos(particle.direction) * particle.speed * 0.01;
      particle.y += math.sin(particle.direction) * particle.speed * 0.01;

      // Wrap around edges
      if (particle.x < 0) particle.x = 1;
      if (particle.x > 1) particle.x = 0;
      if (particle.y < 0) particle.y = 1;
      if (particle.y > 1) particle.y = 0;

      // Draw particle
      final color = (particle.x + particle.y) % 2 < 1
          ? primaryColor
          : accentColor;
      
      paint.color = color.withOpacity(0.3);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

