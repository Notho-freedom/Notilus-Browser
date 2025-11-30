import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
    
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run3',
        'hypothesisId': 'E',
        'location': 'wallpaper_background.dart:27',
        'message': 'wallpaper_background build',
        'data': {
          'isVideo': wallpaperManager.isVideo,
          'controllerIsNull': videoService.controller == null,
          'currentVideoUrl': videoService.currentVideoUrl ?? 'null',
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
      logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    // Si c'est une vidéo et qu'elle est disponible
    if (wallpaperManager.isVideo && videoService.controller != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo de fond (media_kit)
          Positioned.fill(
            child: Video(
              controller: videoService.controller!,
              controls: null,
              fill: Colors.black,
              alignment: alignment is Alignment ? alignment as Alignment : Alignment.center,
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
    // Vérifier que ce n'est pas une vidéo (double vérification)
    if (wallpaperManager.isVideo) {
      // Si c'est une vidéo mais qu'on n'a pas de controller, afficher un placeholder
      return Container(
        color: Colors.black,
        child: child,
      );
    }
    
    final currentUrl = wallpaperManager.current;
    
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'B',
        'location': 'wallpaper_background.dart:65',
        'message': 'wallpaper_background currentUrl retrieved',
        'data': {
          'currentUrl': currentUrl.isEmpty ? 'EMPTY' : (currentUrl.length > 100 ? '${currentUrl.substring(0, 100)}...' : currentUrl),
          'isVideo': wallpaperManager.isVideo,
          'isVideoUrl': currentUrl.contains('.mp4') || currentUrl.contains('video/upload'),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
      logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    // S'assurer que l'URL n'est pas vide
    if (currentUrl.isEmpty) {
      return Container(
        color: Colors.black,
        child: child,
      );
    }
    
    // Vérification supplémentaire : s'assurer que l'URL n'est pas une vidéo
    final isVideoUrl = currentUrl.contains('.mp4') || 
                       currentUrl.contains('video/upload') ||
                       currentUrl.endsWith('.webm') ||
                       currentUrl.endsWith('.mov') ||
                       currentUrl.endsWith('.avi');
    
    if (isVideoUrl) {
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'B',
          'location': 'wallpaper_background.dart:82',
          'message': 'video URL detected in wallpaper_background, returning placeholder',
          'data': {'currentUrl': currentUrl.length > 100 ? '${currentUrl.substring(0, 100)}...' : currentUrl},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
        logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      // Si c'est une URL vidéo, afficher un placeholder
      return Container(
        color: Colors.black,
        child: child,
      );
    }
    
    try {
      // Triple vérification avant de créer le provider
      if (isVideoUrl) {
        debugPrint('⚠️ WallpaperBackground: URL vidéo détectée alors que isVideo est false: $currentUrl');
        return Container(
          color: Colors.black,
          child: child,
        );
      }
      
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'C',
          'location': 'wallpaper_background.dart:103',
          'message': 'creating CachedNetworkImageProvider',
          'data': {'currentUrl': currentUrl.length > 100 ? '${currentUrl.substring(0, 100)}...' : currentUrl},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        final logFile = File(r'c:\Users\bobim\Notilus-Browser\.cursor\debug.log');
        logFile.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
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

