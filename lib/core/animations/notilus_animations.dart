import 'package:flutter/material.dart';

/// Constantes d'animation pour Notilus Browser
class NotilusAnimations {
  // Durées
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration panel = Duration(milliseconds: 350);
  
  // Courbes
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve sharpCurve = Curves.easeOutExpo;
  
  // Valeurs de scale
  static const double hoverScale = 1.05;
  static const double pressScale = 0.95;
  static const double popScale = 1.1;
}

/// Widget animé pour les effets hover
class AnimatedHoverScale extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final double pressScale;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  const AnimatedHoverScale({
    super.key,
    required this.child,
    this.hoverScale = 1.03,
    this.pressScale = 0.97,
    this.duration = const Duration(milliseconds: 150),
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.enabled = true,
  });

  @override
  State<AnimatedHoverScale> createState() => _AnimatedHoverScaleState();
}

class _AnimatedHoverScaleState extends State<AnimatedHoverScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.hoverScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool hover) {
    if (!widget.enabled) return;
    setState(() => _isHovered = hover);
    if (hover && !_isPressed) {
      _scaleAnimation = Tween<double>(begin: 1.0, end: widget.hoverScale).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward();
    } else if (!_isPressed) {
      _controller.reverse();
    }
  }

  void _handleTapDown(_) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0);
  }

  void _handleTapUp(_) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    if (_isHovered) {
      _scaleAnimation = Tween<double>(begin: widget.pressScale, end: widget.hoverScale).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
    } else {
      _scaleAnimation = Tween<double>(begin: widget.pressScale, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
    }
    _controller.forward(from: 0);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Widget avec effet de fade-in lors de l'apparition
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideOffset;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0, 10),
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
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
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Widget avec animation de slide pour les panneaux
class SlidePanel extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;
  final SlideDirection direction;

  const SlidePanel({
    super.key,
    required this.child,
    required this.isVisible,
    this.duration = const Duration(milliseconds: 300),
    this.direction = SlideDirection.left,
  });

  @override
  Widget build(BuildContext context) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.left:
        beginOffset = const Offset(-1, 0);
        break;
      case SlideDirection.right:
        beginOffset = const Offset(1, 0);
        break;
      case SlideDirection.top:
        beginOffset = const Offset(0, -1);
        break;
      case SlideDirection.bottom:
        beginOffset = const Offset(0, 1);
        break;
    }

    return AnimatedSlide(
      duration: duration,
      curve: Curves.easeOutCubic,
      offset: isVisible ? Offset.zero : beginOffset,
      child: AnimatedOpacity(
        duration: duration,
        opacity: isVisible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
}

enum SlideDirection { left, right, top, bottom }

/// Widget avec effet de pulse/glow
class PulseWidget extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool isPulsing;

  const PulseWidget({
    super.key,
    required this.child,
    required this.glowColor,
    this.isPulsing = true,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) return widget.child;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_animation.value * 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Widget animé pour les listes avec stagger effect
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration itemDelay;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 50),
    this.itemDelay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      delay: baseDelay + (itemDelay * index),
      slideOffset: const Offset(0, 15),
      child: child,
    );
  }
}

/// Transition de page personnalisée
class NotilusPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  NotilusPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
            );

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Widget avec shimmer effect pour loading
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF1A1A1E),
    this.highlightColor = const Color(0xFF2A2A2E),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Extension pour ajouter facilement des animations
extension AnimationExtensions on Widget {
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Offset slideOffset = const Offset(0, 10),
  }) {
    return FadeInWidget(
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: this,
    );
  }

  Widget hoverScale({
    double hoverScale = 1.03,
    double pressScale = 0.97,
    VoidCallback? onTap,
  }) {
    return AnimatedHoverScale(
      hoverScale: hoverScale,
      pressScale: pressScale,
      onTap: onTap,
      child: this,
    );
  }

  Widget pulse({
    required Color glowColor,
    bool isPulsing = true,
  }) {
    return PulseWidget(
      glowColor: glowColor,
      isPulsing: isPulsing,
      child: this,
    );
  }
}

