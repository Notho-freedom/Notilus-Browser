import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

enum NeonButtonVariant { primary, secondary, danger, accent }

class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final NeonButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = NeonButtonVariant.primary,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColor() {
    final theme = _getThemeFromContext();
    switch (widget.variant) {
      case NeonButtonVariant.primary:
        return theme.primary;
      case NeonButtonVariant.secondary:
        return theme.secondary;
      case NeonButtonVariant.danger:
        return theme.error;
      case NeonButtonVariant.accent:
        return theme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final isEnabled = widget.onPressed != null;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: isEnabled ? widget.onPressed : null,
            child: Container(
              width: widget.width,
              height: widget.height ?? 40,
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isEnabled
                    ? color.withOpacity(_isHovered ? 0.2 : 0.1)
                    : color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEnabled
                      ? color.withOpacity(
                          _isHovered ? 1.0 : _glowAnimation.value * 0.8,
                        )
                      : color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: isEnabled && _isHovered
                    ? [
                        BoxShadow(
                          color: color.withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: AppConstants.neonBlur * 2,
                          spreadRadius: AppConstants.neonSpread,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: isEnabled ? color : color.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: isEnabled ? color : color.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

