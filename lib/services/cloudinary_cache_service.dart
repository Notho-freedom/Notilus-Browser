import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service de cache local pour les médias Cloudinary
class CloudinaryCacheService {
  static final CloudinaryCacheService _instance = CloudinaryCacheService._internal();
  factory CloudinaryCacheService() => _instance;
  CloudinaryCacheService._internal();

  Directory? _cacheDir;
  final Map<String, String> _cachedFiles = {}; // URL -> chemin local
  final Map<String, bool> _downloadingFiles = {}; // URL -> en cours de téléchargement

  /// Initialise le répertoire de cache
  /// Utilise getApplicationDocumentsDirectory() pour une persistance permanente
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'cloudinary_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    await _cleanOldCache();
  }

  /// Nettoie les fichiers de cache anciens (> 7 jours)
  Future<void> _cleanOldCache() async {
    if (_cacheDir == null) return;
    
    try {
      final now = DateTime.now();
      final files = _cacheDir!.listSync();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          if (age.inDays > 7) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage du cache: $e');
    }
  }

  /// Génère un nom de fichier de cache à partir d'une URL
  String _getCacheFileName(String url) {
    final bytes = utf8.encode(url);
    final hash = sha256.convert(bytes);
    final uri = Uri.parse(url);
    final extension = path.extension(uri.path).isEmpty 
        ? (url.contains('video') ? '.mp4' : '.jpg')
        : path.extension(uri.path);
    return '${hash.toString()}$extension';
  }

  /// Télécharge un fichier en streaming et le met en cache
  Future<File?> cacheFile(String url, {bool isVideo = false}) async {
    if (_cacheDir == null) await initialize();

    final cacheFileName = _getCacheFileName(url);
    final cacheFile = File(path.join(_cacheDir!.path, cacheFileName));

    // Vérifier si le fichier est déjà en cache
    if (await cacheFile.exists()) {
      _cachedFiles[url] = cacheFile.path;
      return cacheFile;
    }

    // Vérifier si le téléchargement est déjà en cours
    if (_downloadingFiles[url] == true) {
      // Attendre que le téléchargement se termine
      int attempts = 0;
      while (_downloadingFiles[url] == true && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
        if (await cacheFile.exists()) {
          _cachedFiles[url] = cacheFile.path;
          return cacheFile;
        }
      }
      return null;
    }

    // Démarrer le téléchargement
    _downloadingFiles[url] = true;

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        await cacheFile.writeAsBytes(response.bodyBytes);
        _cachedFiles[url] = cacheFile.path;
        return cacheFile;
      } else {
        debugPrint('Erreur lors du téléchargement: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors du cache du fichier: $e');
      return null;
    } finally {
      _downloadingFiles[url] = false;
    }
  }

  /// Télécharge un fichier en streaming (pour les vidéos)
  Future<File?> cacheFileStreaming(String url, {
    required Function(double progress) onProgress,
  }) async {
    if (_cacheDir == null) await initialize();

    final cacheFileName = _getCacheFileName(url);
    final cacheFile = File(path.join(_cacheDir!.path, cacheFileName));

    // Vérifier si le fichier est déjà en cache
    if (await cacheFile.exists()) {
      _cachedFiles[url] = cacheFile.path;
      onProgress(1.0);
      return cacheFile;
    }

    // Vérifier si le téléchargement est déjà en cours
    if (_downloadingFiles[url] == true) {
      int attempts = 0;
      while (_downloadingFiles[url] == true && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
        if (await cacheFile.exists()) {
          _cachedFiles[url] = cacheFile.path;
          onProgress(1.0);
          return cacheFile;
        }
      }
      return null;
    }

    _downloadingFiles[url] = true;

    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode == 200) {
        final contentLength = streamedResponse.contentLength ?? 0;
        final sink = cacheFile.openWrite();
        int receivedBytes = 0;

        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          
          if (contentLength > 0) {
            final progress = receivedBytes / contentLength;
            onProgress(progress);
          }
        }

        await sink.close();
        _cachedFiles[url] = cacheFile.path;
        return cacheFile;
      } else {
        debugPrint('Erreur lors du téléchargement: ${streamedResponse.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors du cache streaming: $e');
      return null;
    } finally {
      _downloadingFiles[url] = false;
    }
  }

  /// Récupère le fichier en cache s'il existe
  Future<File?> getCachedFile(String url) async {
    if (_cacheDir == null) await initialize();

    final cacheFileName = _getCacheFileName(url);
    final cacheFile = File(path.join(_cacheDir!.path, cacheFileName));

    if (await cacheFile.exists()) {
      _cachedFiles[url] = cacheFile.path;
      return cacheFile;
    }

    return null;
  }

  /// Génère l'URL de thumbnail Cloudinary
  static String getThumbnailUrl(String secureUrl, {int width = 300, int height = 300}) {
    try {
      final uri = Uri.parse(secureUrl);
      final pathSegments = uri.pathSegments;
      
      // Cloudinary URL format: https://res.cloudinary.com/{cloud_name}/{resource_type}/upload/{transformations}/{public_id}.{format}
      // Pour les vidéos, on peut aussi utiliser /video/upload/v{timestamp}/{transformations}/{public_id}
      
      if (pathSegments.length >= 3) {
        final resourceType = pathSegments[1]; // 'image', 'video', 'raw'
        final uploadIndex = pathSegments.indexOf('upload');
        
        if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
          // Extraire le public_id (tout après 'upload' jusqu'à la fin)
          final publicIdParts = pathSegments.sublist(uploadIndex + 1);
          
          // Vérifier si des transformations existent déjà
          bool hasTransformations = false;
          if (publicIdParts.isNotEmpty) {
            // Les transformations sont généralement des chaînes avec des underscores ou des caractères spéciaux
            final firstPart = publicIdParts[0];
            hasTransformations = firstPart.contains('_') || firstPart.contains(',') || 
                                firstPart.contains('w_') || firstPart.contains('h_');
          }
          
          String publicId;
          if (hasTransformations && publicIdParts.length > 1) {
            // Les transformations sont le premier élément, le public_id est le reste
            publicId = publicIdParts.sublist(1).join('/');
          } else if (hasTransformations) {
            // Pas de public_id visible, utiliser l'URL originale
            publicId = publicIdParts.join('/');
          } else {
            publicId = publicIdParts.join('/');
          }
          
          // Pour les vidéos, générer un thumbnail avec une transformation
          final transformation = resourceType == 'video'
              ? 'w_$width,h_$height,c_fill,q_auto,f_jpg' // f_jpg pour forcer une image
              : 'w_$width,h_$height,c_fill,q_auto,f_auto';
          
          // Construire la nouvelle URL
          final newPath = '/${pathSegments[0]}/$resourceType/upload/$transformation/$publicId';
          return '${uri.scheme}://${uri.host}$newPath';
        }
      }
      
      // Fallback : ajouter les transformations à la fin du chemin
      final transformation = 'w_$width,h_$height,c_fill,q_auto,f_auto';
      final path = uri.path;
      if (path.contains('/upload/')) {
        return path.replaceFirst('/upload/', '/upload/$transformation/');
      }
      
      return secureUrl;
    } catch (e) {
      debugPrint('Erreur lors de la génération du thumbnail: $e');
      return secureUrl;
    }
  }

  /// Nettoie le cache
  Future<void> clearCache() async {
    if (_cacheDir == null) return;
    
    try {
      final files = _cacheDir!.listSync();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      _cachedFiles.clear();
    } catch (e) {
      debugPrint('Erreur lors du nettoyage du cache: $e');
    }
  }
}

