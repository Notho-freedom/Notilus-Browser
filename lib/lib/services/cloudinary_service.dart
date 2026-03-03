import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';
import 'cloudinary_cache_service.dart';

/// Service pour gérer les uploads vers Cloudinary
class CloudinaryService extends ChangeNotifier {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final SettingsService _settings = SettingsService();
  
  // Cache des médias uploadés
  List<CloudinaryMedia> _uploadedBackgrounds = [];
  List<CloudinaryMedia> _uploadedVideos = [];
  List<CloudinaryMedia> _uploadedMusic = [];
  
  // Gestion des uploads parallèles PAR TYPE
  final Map<CloudinaryResourceType, List<String>> _currentUploadsByType = {};
  final Map<String, UploadProgress> _uploadProgressMap = {};
  
  String? _error;

  List<CloudinaryMedia> get uploadedBackgrounds => _uploadedBackgrounds;
  List<CloudinaryMedia> get uploadedVideos => _uploadedVideos;
  List<CloudinaryMedia> get uploadedMusic => _uploadedMusic;
  String? get error => _error;
  
  // Getters pour les uploads en cours PAR TYPE
  List<String> getCurrentUploads(CloudinaryResourceType type) => 
      _currentUploadsByType[type] ?? [];
  
  Map<String, UploadProgress> get uploadProgressMap => _uploadProgressMap;
  
  bool isLoading(CloudinaryResourceType type) => 
      getCurrentUploads(type).isNotEmpty;
  
  double getUploadProgress(String fileName) => _uploadProgressMap[fileName]?.progress ?? 0.0;

  /// Initialise le service et charge les médias existants
  Future<void> initialize() async {
    await _loadMediaFromStorage();
    // Ajouter la musique par défaut si elle n'existe pas déjà
    _addDefaultMusicIfNeeded();
    // Initialiser le service de cache
    await CloudinaryCacheService().initialize();
  }
  
  /// Ajoute la musique par défaut de Notilus si elle n'existe pas déjà
  void _addDefaultMusicIfNeeded() {
    const defaultMusicUrl = 'https://res.cloudinary.com/dsslbg3v3/raw/upload/v1764459325/music/wozpjrnbmf7bnqceg9yw.mp3';
    const defaultMusicId = 'notilus_default_music';
    
    // Vérifier si la musique par défaut existe déjà
    final exists = _uploadedMusic.any((m) => m.publicId == defaultMusicId || m.secureUrl == defaultMusicUrl);
    
    if (!exists) {
      // Créer un objet CloudinaryMedia pour la musique par défaut
      final defaultMusic = CloudinaryMedia(
        publicId: defaultMusicId,
        secureUrl: defaultMusicUrl,
        resourceType: CloudinaryResourceType.raw,
        format: 'mp3',
        bytes: 0, // Taille inconnue
        createdAt: DateTime.now(),
        folder: 'music',
        width: 0,
        height: 0,
        url: defaultMusicUrl,
      );
      
      // Ajouter en première position
      _uploadedMusic.insert(0, defaultMusic);
      _saveMediaToStorage();
      notifyListeners();
    }
  }

  /// Vérifie si Cloudinary est configuré
  bool get isConfigured {
    final cloudName = _settings.cloudinaryCloudName;
    final uploadPreset = _settings.cloudinaryUploadPreset;
    return cloudName != null && cloudName.isNotEmpty &&
           uploadPreset != null && uploadPreset.isNotEmpty;
  }

  /// Upload un fichier vers Cloudinary
  Future<CloudinaryMedia?> uploadFile({
    required File file,
    required CloudinaryResourceType resourceType,
    String? folder,
    Map<String, dynamic>? transformation,
  }) async {
    if (!isConfigured) {
      _error = 'Cloudinary n\'est pas configuré. Veuillez configurer vos credentials dans les paramètres.';
      notifyListeners();
      return null;
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final uploadId = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    // Ajouter aux uploads en cours POUR CE TYPE SEULEMENT
    _currentUploadsByType[resourceType] ??= [];
    _currentUploadsByType[resourceType]!.add(uploadId);
    _uploadProgressMap[uploadId] = UploadProgress(
      fileName: fileName, 
      progress: 0.0,
      resourceType: resourceType,
    );
    notifyListeners();

    try {
      final cloudName = _settings.cloudinaryCloudName!;
      final uploadPreset = _settings.cloudinaryUploadPreset!;

      // Préparer les paramètres pour l'upload UNSIGNED avec preset
      // Avec un Upload Preset UNSIGNED, pas besoin de signature ni d'API key/secret
      final params = <String, String>{
        'upload_preset': uploadPreset,
      };

      // Le folder peut être défini dans le preset, mais on peut aussi le surcharger
      if (folder != null && folder.isNotEmpty) {
        params['folder'] = folder;
      }

      // Ajouter les transformations si fournies
      if (transformation != null) {
        params['transformation'] = jsonEncode(transformation);
      }

      // Créer la requête multipart
      // NOTE: resource_type fait partie de l'URL, pas des paramètres
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/${resourceType.name}/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Ajouter les paramètres (seulement upload_preset et folder, pas de signature)
      params.forEach((key, value) {
        request.fields[key] = value;
      });

      // Obtenir la taille du fichier pour la progression
      final fileLength = await file.length();
      
      // Créer le multipart file avec progression personnalisée
      final multipartFile = await _createMultipartFileWithProgress(
        file: file,
        fileName: fileName,
        fileLength: fileLength,
        uploadId: uploadId,
        resourceType: resourceType,
      );

      request.files.add(multipartFile);

      // Mettre à jour la progression à 80% (début de l'envoi)
      _uploadProgressMap[uploadId] = UploadProgress(
        fileName: fileName,
        progress: 0.80,
        resourceType: resourceType,
      );
      notifyListeners();
      
      // Envoyer la requête sans timeout
      final streamedResponse = await request.send();
      
      // Mettre à jour la progression à 90% (en attente de réponse)
      _uploadProgressMap[uploadId] = UploadProgress(
        fileName: fileName,
        progress: 0.90,
        resourceType: resourceType,
      );
      notifyListeners();
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final media = CloudinaryMedia.fromJson(data);
        
        // Mettre à jour la progression à 100%
        _uploadProgressMap[uploadId] = UploadProgress(
          fileName: fileName,
          progress: 1.0,
          resourceType: resourceType,
        );
        notifyListeners();
        
        // Ajouter au cache approprié
        _addToCache(media, resourceType);
        
        // Sauvegarder dans le stockage local
        await _saveMediaToStorage();
        
        // Petit délai pour afficher le 100%
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Nettoyer l'upload
        _cleanupUpload(uploadId, resourceType);
        
        return media;
      } else {
        _error = 'Erreur lors de l\'upload: ${response.statusCode} - ${response.body}';
        _cleanupUpload(uploadId, resourceType);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Erreur lors de l\'upload: $e';
      _cleanupUpload(uploadId, resourceType);
      notifyListeners();
      return null;
    }
  }

  /// Créer un MultipartFile avec suivi de progression
  Future<http.MultipartFile> _createMultipartFileWithProgress({
    required File file,
    required String fileName,
    required int fileLength,
    required String uploadId,
    required CloudinaryResourceType resourceType,
  }) async {
    // Lire le fichier en chunks pour suivre la progression réelle
    final stream = file.openRead();
    int totalBytesRead = 0;
    final List<List<int>> chunks = [];
    
    // Suivre la progression pendant la lecture
    await for (final chunk in stream) {
      totalBytesRead += chunk.length;
      chunks.add(chunk);
      
      // Mettre à jour la progression (max 70% pendant la lecture du fichier)
      final progress = (totalBytesRead / fileLength * 0.7).clamp(0.0, 0.7);
      _uploadProgressMap[uploadId] = UploadProgress(
        fileName: fileName,
        progress: progress,
        resourceType: resourceType,
      );
      notifyListeners();
    }
    
    // Combiner tous les chunks
    final bytes = chunks.expand((chunk) => chunk).toList();
    
    // Mettre à jour à 75% après la lecture complète
    _uploadProgressMap[uploadId] = UploadProgress(
      fileName: fileName,
      progress: 0.75,
      resourceType: resourceType,
    );
    notifyListeners();
    
    return http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );
  }

  /// Nettoyer un upload terminé
  void _cleanupUpload(String uploadId, CloudinaryResourceType resourceType) {
    _currentUploadsByType[resourceType]?.remove(uploadId);
    _uploadProgressMap.remove(uploadId);
    notifyListeners();
  }

  /// Upload depuis une URL (méthode simplifiée sans progression)
  Future<CloudinaryMedia?> uploadFromUrl({
    required String url,
    required CloudinaryResourceType resourceType,
    String? folder,
    Map<String, dynamic>? transformation,
  }) async {
    return uploadFromUrlWithProgress(
      url: url,
      resourceType: resourceType,
      folder: folder,
      transformation: transformation,
    );
  }
  
  /// Upload depuis une URL avec suivi de progression
  Future<CloudinaryMedia?> uploadFromUrlWithProgress({
    required String url,
    required CloudinaryResourceType resourceType,
    String? folder,
    Map<String, dynamic>? transformation,
    void Function(double progress)? onProgress,
  }) async {
    if (!isConfigured) {
      _error = 'Cloudinary n\'est pas configuré.';
      notifyListeners();
      return null;
    }

    _error = null;
    final fileName = url.split('/').last.split('?').first;
    final uploadId = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    // Initialiser la progression
    _uploadProgressMap[uploadId] = UploadProgress(
      fileName: fileName,
      progress: 0.0,
      resourceType: resourceType,
    );
    onProgress?.call(0.0);
    notifyListeners();

    try {
      final cloudName = _settings.cloudinaryCloudName!;
      final uploadPreset = _settings.cloudinaryUploadPreset!;
      
      final params = <String, String>{
        'upload_preset': uploadPreset,
        'file': url,
      };

      if (folder != null && folder.isNotEmpty) {
        params['folder'] = folder;
      }

      if (transformation != null) {
        params['transformation'] = jsonEncode(transformation);
      }

      // Mettre à jour la progression à 30% (début de l'envoi)
      _uploadProgressMap[uploadId] = UploadProgress(
        fileName: fileName,
        progress: 0.30,
        resourceType: resourceType,
      );
      onProgress?.call(0.30);
      notifyListeners();

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/${resourceType.name}/upload');
      
      // Mettre à jour la progression à 60% (envoi en cours)
      _uploadProgressMap[uploadId] = UploadProgress(
        fileName: fileName,
        progress: 0.60,
        resourceType: resourceType,
      );
      onProgress?.call(0.60);
      notifyListeners();
      
      // Pas de timeout pour les uploads depuis URL
      final response = await http.post(uri, body: params);

      // Mettre à jour la progression à 90% (réponse reçue)
      _uploadProgressMap[uploadId] = UploadProgress(
        fileName: fileName,
        progress: 0.90,
        resourceType: resourceType,
      );
      onProgress?.call(0.90);
      notifyListeners();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final media = CloudinaryMedia.fromJson(data);
        
        // Mettre à jour la progression à 100%
        _uploadProgressMap[uploadId] = UploadProgress(
          fileName: fileName,
          progress: 1.0,
          resourceType: resourceType,
        );
        onProgress?.call(1.0);
        notifyListeners();
        
        _addToCache(media, resourceType);
        await _saveMediaToStorage();
        
        // Petit délai pour afficher le 100%
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Nettoyer l'upload
        _uploadProgressMap.remove(uploadId);
        notifyListeners();
        
        return media;
      } else {
        _error = 'Erreur lors de l\'upload: ${response.statusCode}';
        _uploadProgressMap.remove(uploadId);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Erreur lors de l\'upload: $e';
      _uploadProgressMap.remove(uploadId);
      notifyListeners();
      return null;
    }
  }

  /// Supprime un média de Cloudinary
  Future<bool> deleteMedia(CloudinaryMedia media) async {
    if (!isConfigured) {
      _error = 'Cloudinary n\'est pas configuré.';
      notifyListeners();
      return false;
    }

    try {
      // Retirer du cache local uniquement
      // La suppression réelle nécessite l'Admin API avec api_key/api_secret
      _removeFromCache(media);
      await _saveMediaToStorage();
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      notifyListeners();
      return false;
    }
  }

  /// Génère la signature Cloudinary
  /// Format: param1=value1&param2=value2&...&api_secret
  /// Pour les uploads multipart, excludeFile doit être true (le fichier est envoyé séparément)
  /// Pour les uploads depuis URL, excludeFile doit être false (le paramètre 'file' doit être signé)
  /// NOTE: resource_type ne doit JAMAIS être dans la signature car il fait partie de l'URL
  String _generateSignature(Map<String, String> params, String apiSecret, {bool excludeFile = true}) {
    final paramsToSign = <String, String>{};
    params.forEach((key, value) {
      // Toujours exclure api_key et signature
      if (key == 'api_key' || key == 'signature') return;
      
      // Exclure 'file' seulement si excludeFile est true (pour multipart)
      if (excludeFile && key == 'file') return;
      
      // NE JAMAIS signer resource_type - il fait partie de l'URL
      if (key == 'resource_type') return;
      
      // Inclure tous les autres paramètres non vides
      if (value.isNotEmpty) {
        paramsToSign[key] = value;
      }
    });
    
    // Trier les paramètres par clé (ordre alphabétique)
    final sortedKeys = paramsToSign.keys.toList()..sort();
    
    // Créer la chaîne de signature: key1=value1&key2=value2&...
    final signatureString = sortedKeys
        .map((key) => '$key=${paramsToSign[key]}')
        .join('&');
    
    // Ajouter l'API secret à la fin
    final fullString = '$signatureString$apiSecret';
    
    // Générer le hash SHA1
    final bytes = utf8.encode(fullString);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// Ajoute un média au cache approprié
  void _addToCache(CloudinaryMedia media, CloudinaryResourceType resourceType) {
    if (resourceType == CloudinaryResourceType.image) {
      _uploadedBackgrounds.add(media);
    } else if (resourceType == CloudinaryResourceType.video) {
      _uploadedVideos.add(media);
    } else if (resourceType == CloudinaryResourceType.raw) {
      _uploadedMusic.add(media);
    }
  }

  /// Retire un média du cache
  void _removeFromCache(CloudinaryMedia media) {
    _uploadedBackgrounds.removeWhere((m) => m.publicId == media.publicId);
    _uploadedVideos.removeWhere((m) => m.publicId == media.publicId);
    _uploadedMusic.removeWhere((m) => m.publicId == media.publicId);
  }

  /// Charge les médias depuis le stockage local
  Future<void> _loadMediaFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final backgroundsJson = prefs.getString('cloudinary_backgrounds');
      if (backgroundsJson != null) {
        final List<dynamic> backgrounds = jsonDecode(backgroundsJson);
        _uploadedBackgrounds = backgrounds
            .map((e) => CloudinaryMedia.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final videosJson = prefs.getString('cloudinary_videos');
      if (videosJson != null) {
        final List<dynamic> videos = jsonDecode(videosJson);
        _uploadedVideos = videos
            .map((e) => CloudinaryMedia.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final musicJson = prefs.getString('cloudinary_music');
      if (musicJson != null) {
        final List<dynamic> music = jsonDecode(musicJson);
        _uploadedMusic = music
            .map((e) => CloudinaryMedia.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des médias: $e');
    }
  }

  /// Sauvegarde les médias dans le stockage local
  Future<void> _saveMediaToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(
        'cloudinary_backgrounds',
        jsonEncode(_uploadedBackgrounds.map((m) => m.toJson()).toList()),
      );
      
      await prefs.setString(
        'cloudinary_videos',
        jsonEncode(_uploadedVideos.map((m) => m.toJson()).toList()),
      );
      
      await prefs.setString(
        'cloudinary_music',
        jsonEncode(_uploadedMusic.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des médias: $e');
    }
  }

  /// Rafraîchit la liste des médias depuis Cloudinary
  /// NOTE: Le refresh nécessite l'Admin API qui requiert api_key/api_secret
  /// Avec un preset UNSIGNED, on utilise le cache local uniquement
  /// L'utilisateur peut recharger la page pour voir les nouveaux uploads
  Future<void> refreshMedia() async {
    if (!isConfigured) return;
    notifyListeners();
  }

  /// Efface les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Annule tous les uploads en cours POUR UN TYPE
  void cancelUploadsForType(CloudinaryResourceType type) {
    final uploads = _currentUploadsByType[type] ?? [];
    for (final uploadId in uploads) {
      _uploadProgressMap.remove(uploadId);
    }
    _currentUploadsByType[type]?.clear();
    notifyListeners();
  }
  
  /// Annule tous les uploads en cours (tous types)
  void cancelAllUploads() {
    for (final type in CloudinaryResourceType.values) {
      cancelUploadsForType(type);
    }
  }
}

/// Type de ressource Cloudinary
enum CloudinaryResourceType {
  image,
  video,
  raw,
  auto,
}

/// Modèle pour un média Cloudinary
class CloudinaryMedia {
  final String publicId;
  final String secureUrl;
  final String url;
  final CloudinaryResourceType resourceType;
  final int bytes;
  final int width;
  final int height;
  final String format;
  final DateTime createdAt;
  final String? folder;

  CloudinaryMedia({
    required this.publicId,
    required this.secureUrl,
    required this.url,
    required this.resourceType,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    required this.createdAt,
    this.folder,
  });

  factory CloudinaryMedia.fromJson(Map<String, dynamic> json) {
    CloudinaryResourceType resourceType;
    final rt = json['resource_type'] as String? ?? 'image';
    switch (rt) {
      case 'image':
        resourceType = CloudinaryResourceType.image;
        break;
      case 'video':
        resourceType = CloudinaryResourceType.video;
        break;
      case 'raw':
        resourceType = CloudinaryResourceType.raw;
        break;
      default:
        resourceType = CloudinaryResourceType.auto;
    }

    return CloudinaryMedia(
      publicId: json['public_id'] as String,
      secureUrl: json['secure_url'] as String? ?? json['url'] as String,
      url: json['url'] as String? ?? json['secure_url'] as String,
      resourceType: resourceType,
      bytes: json['bytes'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      format: json['format'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      folder: json['folder'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'secure_url': secureUrl,
      'url': url,
      'resource_type': resourceType.name,
      'bytes': bytes,
      'width': width,
      'height': height,
      'format': format,
      'created_at': createdAt.toIso8601String(),
      'folder': folder,
    };
  }
}

/// Modèle pour suivre la progression d'un upload
class UploadProgress {
  final String fileName;
  final double progress;
  final CloudinaryResourceType resourceType;

  UploadProgress({
    required this.fileName,
    required this.progress,
    required this.resourceType,
  });
}