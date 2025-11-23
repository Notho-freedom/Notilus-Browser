import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

/// Titlebar personnalisée style Opera GX
class CustomTitleBar extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool showTitle;

  const CustomTitleBar({
    super.key,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor ?? 
            (isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A)),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF0040).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Zone de glissement (pour déplacer la fenêtre)
          Expanded(
            child: GestureDetector(
              onPanStart: (_) {
                // Permet de déplacer la fenêtre en glissant
                if (Platform.isWindows) {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual);
                }
              },
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    
                    // Logo avec effet néon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0040),
                            Color(0xFFFF3366),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0040).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto Mono',
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Titre de l'application
                    if (showTitle)
                      Text(
                        'NOTILUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto Mono',
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Color(0xFFFF0040).withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // Widgets personnalisés (trailing)
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ),
          
          // Boutons de contrôle de fenêtre
          if (Platform.isWindows || Platform.isLinux)
            _WindowControls(),
        ],
      ),
    );
  }
}

class _WindowControls extends StatefulWidget {
  @override
  State<_WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<_WindowControls> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
    // Écouter les changements d'état de la fenêtre
    windowManager.addListener(_onWindowEvent);
  }

  @override
  void dispose() {
    windowManager.removeListener(_onWindowEvent);
    super.dispose();
  }

  void _onWindowEvent() {
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    final isMax = await windowManager.isMaximized();
    if (mounted && isMax != _isMaximized) {
      setState(() {
        _isMaximized = isMax;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton Minimiser
        _WindowControlButton(
          icon: CupertinoIcons.minus,
          onPressed: () async {
            await windowManager.minimize();
          },
          hoverColor: const Color(0xFF00FF88).withOpacity(0.2),
        ),
        
        // Bouton Maximiser/Restaurer
        _WindowControlButton(
          icon: _isMaximized 
              ? CupertinoIcons.rectangle_on_rectangle
              : CupertinoIcons.rectangle_expand_vertical,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.restore();
              setState(() {
                _isMaximized = false;
              });
            } else {
              await windowManager.maximize();
              setState(() {
                _isMaximized = true;
              });
            }
          },
          hoverColor: const Color(0xFFFFAA00).withOpacity(0.2),
        ),
        
        // Bouton Fermer
        _WindowControlButton(
          icon: CupertinoIcons.xmark,
          onPressed: () async {
            await windowManager.close();
          },
          hoverColor: const Color(0xFFFF0040).withOpacity(0.3),
          isCloseButton: true,
        ),
      ],
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final bool isCloseButton;

  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
    this.isCloseButton = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.hoverColor
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: widget.isCloseButton ? 14 : 12,
            color: _isHovered
                ? Colors.white
                : Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}

