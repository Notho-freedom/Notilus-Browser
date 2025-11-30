import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/wallpaper_manager.dart';

/// Widget réutilisable pour afficher le wallpaper (images uniquement)
class WallpaperBackground extends StatelessWidget {
  final Widget child;
  final ColorFilter? colorFilter;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  const WallpaperBackground({
    super.key,
    required this.child,
    this.colorFilter,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final wallpaperManager = context.watch<WallpaperManager>();
    final currentUrl = wallpaperManager.current;
    
    // S'assurer que l'URL n'est pas vide
    if (currentUrl.isEmpty) {
      return Container(
        color: Colors.black,
        child: child,
      );
    }
    
    // Vérification : s'assurer que l'URL n'est pas une vidéo (filtrage de sécurité)
    final isVideoUrl = currentUrl.contains('.mp4') || 
                       currentUrl.contains('video/upload') ||
                       currentUrl.endsWith('.webm') ||
                       currentUrl.endsWith('.mov') ||
                       currentUrl.endsWith('.avi');
    
    if (isVideoUrl) {
      // Si c'est une URL vidéo, afficher un placeholder
      debugPrint('⚠️ WallpaperBackground: URL vidéo détectée, ignorée: $currentUrl');
      return Container(
        color: Colors.black,
        child: child,
      );
    }
    
    try {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(currentUrl),
            fit: fit,
            alignment: alignment,
            colorFilter: colorFilter,
            onError: (exception, stackTrace) {
              debugPrint('Erreur chargement image wallpaper: $exception');
            },
          ),
        ),
        child: child,
      );
    } catch (e) {
      debugPrint('Erreur création DecorationImage: $e');
      return Container(
        color: Colors.black,
        child: child,
      );
    }
  }
}

