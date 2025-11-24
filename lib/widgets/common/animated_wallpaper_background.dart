import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';

/// Applique le fond d'écran courant avec un fondu doux à chaque rotation.
class AnimatedWallpaperBackground extends StatelessWidget {
  final Widget child;
  final double darkness;

  const AnimatedWallpaperBackground({
    super.key,
    required this.child,
    this.darkness = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final wallpaperManager = context.watch<WallpaperManager>();
    final key = wallpaperManager.current;
    final image = wallpaperManager.currentImage ??
        NetworkImage(wallpaperManager.current);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeInOut,
      child: Container(
        key: ValueKey(key),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: image,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(darkness),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

