import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants/notilus_colors.dart';
import 'notilus_tooltip.dart';

class CollapseMenu extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onClose;
  final double? width;
  final double? height;

  const CollapseMenu({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onClose,
    this.width,
    this.height,
  });

  @override
  State<CollapseMenu> createState() => _CollapseMenuState();
}

class _CollapseMenuState extends State<CollapseMenu>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double width = widget.width ?? (media.size.width * 0.36).clamp(320.0, media.size.width * 0.55);
    final double maxHeight = widget.height ?? (media.size.height * 0.72).clamp(360.0, media.size.height - 140);

    return Material(
      color: Colors.transparent,
      elevation: 8,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight: maxHeight + 54, // Header height + content
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: NotilusColors.chromeLight.withOpacity(0.96),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NotilusColors.neonRed.withOpacity(0.85),
                    NotilusColors.neonRedDark.withOpacity(0.85),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  NotilusTooltip(
                    message: _isExpanded ? 'Réduire' : 'Développer',
                    child: IconButton(
                      onPressed: _toggle,
                      icon: Icon(
                        _isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_up,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  if (widget.onClose != null)
                    NotilusTooltip(
                      message: 'Fermer',
                      child: IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(
                          CupertinoIcons.xmark_circle,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            AnimatedBuilder(
              animation: _heightAnimation,
              builder: (context, child) {
                final contentHeight = maxHeight * _heightAnimation.value;
                if (contentHeight <= 0.1) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  height: contentHeight,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      color: Colors.black.withOpacity(0.08),
                      child: widget.child,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

