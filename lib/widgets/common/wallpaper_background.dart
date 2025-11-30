import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/video_background_service.dart';

/// Widget réutilisable pour afficher le wallpaper (image ou vidéo)
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
    final videoService = context.watch<VideoBackgroundService>();
    
    // Si c'est une vidéo et qu'elle est disponible
    if (wallpaperManager.isVideo && videoService.controller != null) {
      return Stack(
        children: [
          // Vidéo de fond
          Positioned.fill(
            child: FittedBox(
              fit: fit,
              alignment: alignment,
              child: SizedBox(
                width: videoService.controller!.value.size.width,
                height: videoService.controller!.value.size.height,
                child: VideoPlayer(videoService.controller!),
              ),
            ),
          ),
          // Overlay avec filtre de couleur si fourni
          if (colorFilter != null)
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: colorFilter!,
                child: Container(color: Colors.transparent),
              ),
            ),
          // Contenu
          child,
        ],
      );
    }
    
    // Sinon, afficher l'image
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(wallpaperManager.current),
          fit: fit,
          alignment: alignment,
          colorFilter: colorFilter,
        ),
      ),
      child: child,
    );
  }
}

