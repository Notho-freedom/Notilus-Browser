import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

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
  bool _isLoading = false;
  String? _error;

  List<CloudinaryMedia> get uploadedBackgrounds => _uploadedBackgrounds;
  List<CloudinaryMedia> get uploadedVideos => _uploadedVideos;
  List<CloudinaryMedia> get uploadedMusic => _uploadedMusic;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialise le service et charge les médias existants
  Future<void> initialize() async {
    await _loadMediaFromStorage();
  }

  /// Vérifie si Cloudinary est configuré
  bool get isConfigured {
    final cloudName = _settings.cloudinaryCloudName;
    final apiKey = _settings.cloudinaryApiKey;
    final apiSecret = _settings.cloudinaryApiSecret;
    return cloudName != null && cloudName.isNotEmpty &&
           apiKey != null && apiKey.isNotEmpty &&
           apiSecret != null && apiSecret.isNotEmpty;
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

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cloudName = _settings.cloudinaryCloudName!;
      final apiKey = _settings.cloudinaryApiKey!;
      final apiSecret = _settings.cloudinaryApiSecret!;

      // Générer le timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Préparer les paramètres
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'resource_type': resourceType.name,
      };

      if (folder != null && folder.isNotEmpty) {
        params['folder'] = folder;
      }

      // Ajouter les transformations si fournies
      if (transformation != null) {
        params['transformation'] = jsonEncode(transformation);
      }

      // Générer la signature
      final signature = _generateSignature(params, apiSecret);
      params['signature'] = signature;
      params['api_key'] = apiKey;

      // Créer la requête multipart
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/${resourceType.name}/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Ajouter les paramètres
      params.forEach((key, value) {
        request.fields[key] = value;
      });

      // Ajouter le fichier
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final media = CloudinaryMedia.fromJson(data);
        
        // Ajouter au cache approprié
        _addToCache(media, resourceType);
        
        // Sauvegarder dans le stockage local
        await _saveMediaToStorage();
        
        _isLoading = false;
        notifyListeners();
        return media;
      } else {
        _error = 'Erreur lors de l\'upload: ${response.statusCode} - ${response.body}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Erreur lors de l\'upload: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload depuis une URL
  Future<CloudinaryMedia?> uploadFromUrl({
    required String url,
    required CloudinaryResourceType resourceType,
    String? folder,
    Map<String, dynamic>? transformation,
  }) async {
    if (!isConfigured) {
      _error = 'Cloudinary n\'est pas configuré.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cloudName = _settings.cloudinaryCloudName!;
      final apiKey = _settings.cloudinaryApiKey!;
      final apiSecret = _settings.cloudinaryApiSecret!;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'resource_type': resourceType.name,
        'file': url,
      };

      if (folder != null && folder.isNotEmpty) {
        params['folder'] = folder;
      }

      if (transformation != null) {
        params['transformation'] = jsonEncode(transformation);
      }

      final signature = _generateSignature(params, apiSecret);
      params['signature'] = signature;
      params['api_key'] = apiKey;

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/${resourceType.name}/upload');
      final response = await http.post(uri, body: params);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final media = CloudinaryMedia.fromJson(data);
        
        _addToCache(media, resourceType);
        await _saveMediaToStorage();
        
        _isLoading = false;
        notifyListeners();
        return media;
      } else {
        _error = 'Erreur lors de l\'upload: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Erreur lors de l\'upload: $e';
      _isLoading = false;
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
      final cloudName = _settings.cloudinaryCloudName!;
      final apiKey = _settings.cloudinaryApiKey!;
      final apiSecret = _settings.cloudinaryApiSecret!;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'public_id': media.publicId,
        'resource_type': media.resourceType.name,
      };

      final signature = _generateSignature(params, apiSecret);
      params['signature'] = signature;
      params['api_key'] = apiKey;

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/${media.resourceType.name}/destroy');
      final response = await http.post(uri, body: params);

      if (response.statusCode == 200) {
        // Retirer du cache
        _removeFromCache(media);
        await _saveMediaToStorage();
        
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la suppression: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      notifyListeners();
      return false;
    }
  }

  /// Génère la signature Cloudinary
  String _generateSignature(Map<String, String> params, String apiSecret) {
    // Trier les paramètres par clé
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    // Créer la chaîne de signature
    final signatureString = sortedParams
        .where((e) => e.key != 'file' && e.key != 'api_key')
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
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
      // On considère que les fichiers audio sont uploadés en raw
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
  Future<void> refreshMedia() async {
    if (!isConfigured) return;

    _isLoading = true;
    notifyListeners();

    try {
      final cloudName = _settings.cloudinaryCloudName!;
      final apiKey = _settings.cloudinaryApiKey!;
      final apiSecret = _settings.cloudinaryApiSecret!;

      // Récupérer les images
      await _fetchResources(CloudinaryResourceType.image, 'backgrounds');
      // Récupérer les vidéos
      await _fetchResources(CloudinaryResourceType.video, 'videos');
      // Récupérer les fichiers audio (raw)
      await _fetchResources(CloudinaryResourceType.raw, 'music');

      await _saveMediaToStorage();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du rafraîchissement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les ressources depuis Cloudinary
  Future<void> _fetchResources(CloudinaryResourceType resourceType, String folder) async {
    try {
      final cloudName = _settings.cloudinaryCloudName!;
      final apiKey = _settings.cloudinaryApiKey!;
      final apiSecret = _settings.cloudinaryApiSecret!;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'type': 'upload',
        'resource_type': resourceType.name,
        'prefix': folder,
        'max_results': '500',
      };

      final signature = _generateSignature(params, apiSecret);
      params['signature'] = signature;
      params['api_key'] = apiKey;

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/resources/${resourceType.name}/upload')
          .replace(queryParameters: params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final resources = (data['resources'] as List<dynamic>?)
                ?.map((e) => CloudinaryMedia.fromJson(e as Map<String, dynamic>))
                .toList() ?? [];

        if (resourceType == CloudinaryResourceType.image) {
          _uploadedBackgrounds = resources;
        } else if (resourceType == CloudinaryResourceType.video) {
          _uploadedVideos = resources;
        } else if (resourceType == CloudinaryResourceType.raw) {
          _uploadedMusic = resources;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des ressources: $e');
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

