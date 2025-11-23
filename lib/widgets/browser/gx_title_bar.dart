import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

/// Title bar personnalisée style Opera GX
class GXTitleBar extends StatelessWidget {
  const GXTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 32,
      color: const Color(0xFF1C1C20),
      child: Stack(
        children: [
          // Zone draggable pour déplacer la fenêtre
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) {
              windowManager.startDragging();
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          
          // Contenu
          Row(
            children: [
              const SizedBox(width: 8),
              
              // Logo Notilus avec style GX
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFA2F55),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      color: Color(0xFFFA2F55),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Titre
              Text(
                'Notilus Browser',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              
              const Spacer(),
              
              // Contrôles de fenêtre
              const _WindowControls(),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowControls extends StatefulWidget {
  const _WindowControls();

  @override
  State<_WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<_WindowControls> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'maximize' || eventName == 'unmaximize') {
      _checkMaximized();
    }
  }

  Future<void> _checkMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Minimize
        _WindowButton(
          icon: Icons.minimize,
          iconSize: 14,
          onPressed: () => windowManager.minimize(),
          hoverColor: Colors.white.withOpacity(0.1),
        ),
        
        // Maximize/Restore
        _WindowButton(
          icon: _isMaximized 
              ? Icons.crop_square 
              : Icons.stop_outlined,
          iconSize: 14,
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.restore();
            } else {
              await windowManager.maximize();
            }
          },
          hoverColor: Colors.white.withOpacity(0.1),
        ),
        
        // Close
        _WindowButton(
          icon: Icons.close,
          iconSize: 16,
          onPressed: () => windowManager.close(),
          hoverColor: const Color(0xFFE81123),
          iconColor: Colors.white.withOpacity(0.9),
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color? iconColor;

  const _WindowButton({
    required this.icon,
    required this.iconSize,
    required this.onPressed,
    required this.hoverColor,
    this.iconColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.iconColor ?? Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
