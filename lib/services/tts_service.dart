/// Service TTS (Text-to-Speech) pour Notilus Browser
/// Communique avec l'API backend TTS
library tts_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service principal pour le TTS
class TtsService extends ChangeNotifier {
  static const String _defaultBaseUrl = 'http://localhost:8000';
  
  String _baseUrl;
  bool _isConnected = false;
  String? _lastError;
  
  // Cache des voix
  List<Map<String, dynamic>> _voices = [];
  List<Map<String, dynamic>> _languages = [];
  bool _isLoading = false;
  
  TtsService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;
  
  // Getters
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  List<Map<String, dynamic>> get voices => _voices;
  List<Map<String, dynamic>> get languages => _languages;
  bool get isLoading => _isLoading;
  String get baseUrl => _baseUrl;
  
  set baseUrl(String url) {
    _baseUrl = url;
    notifyListeners();
  }
  
  /// Vérifie si le backend TTS est disponible
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tts/status'),
      ).timeout(const Duration(seconds: 3));
      
      _isConnected = response.statusCode == 200;
      _lastError = _isConnected ? null : 'Backend non disponible';
      notifyListeners();
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Récupère la liste des voix disponibles
  Future<List<Map<String, dynamic>>> getVoices({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tts/voices?force_refresh=$forceRefresh'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _voices = List<Map<String, dynamic>>.from(data['voices'] ?? []);
        _lastError = null;
        _isConnected = true;
      } else {
        _lastError = 'Erreur ${response.statusCode}';
      }
    } catch (e) {
      _lastError = e.toString();
      _isConnected = false;
    }
    
    _isLoading = false;
    notifyListeners();
    return _voices;
  }
  
  /// Récupère les langues supportées
  Future<List<Map<String, dynamic>>> getLanguages() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tts/languages'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _languages = List<Map<String, dynamic>>.from(data['languages'] ?? []);
        _lastError = null;
        _isConnected = true;
      } else {
        _lastError = 'Erreur ${response.statusCode}';
      }
    } catch (e) {
      _lastError = e.toString();
      _isConnected = false;
    }
    
    _isLoading = false;
    notifyListeners();
    return _languages;
  }
  
  /// Vérifie si une voix est disponible
  Future<bool> checkVoice(String voiceName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tts/check-voice/$voiceName'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] == true;
      }
      return false;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
  
  /// Récupère les voix pour une langue
  Future<Map<String, dynamic>?> getVoicesByLanguage(String languageCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tts/voices-by-language/$languageCode'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }
  
  /// Récupère les voix recommandées
  Future<List<Map<String, dynamic>>> getRecommendedVoices({String? language, int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/tts/recommended-voices')
          .replace(queryParameters: {
            if (language != null) 'language': language,
            'limit': limit.toString(),
          });
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['voices'] ?? []);
      }
      return [];
    } catch (e) {
      _lastError = e.toString();
      return [];
    }
  }
  
  /// Recherche des voix
  Future<List<Map<String, dynamic>>> searchVoices({
    String? query,
    String? language,
    String? gender,
    String? locale,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (query != null) queryParams['query'] = query;
      if (language != null) queryParams['language'] = language;
      if (gender != null) queryParams['gender'] = gender;
      if (locale != null) queryParams['locale'] = locale;
      
      final uri = Uri.parse('$_baseUrl/api/tts/search-voices')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['voices'] ?? []);
      }
      return [];
    } catch (e) {
      _lastError = e.toString();
      return [];
    }
  }
  
  /// Génère un audio TTS
  Future<Uint8List?> generateTts({
    required String text,
    required String voice,
    String? provider,
    String? gcpApiKey,
    String? gcpProjectId,
    String? gcpLocation,
  }) async {
    try {
      final body = <String, dynamic>{
        'text': text,
        'voice': voice,
      };
      
      if (provider != null) {
        body['provider'] = provider;
        if (provider == 'gcp') {
          if (gcpApiKey != null) body['gcp_api_key'] = gcpApiKey;
          if (gcpProjectId != null) body['gcp_project_id'] = gcpProjectId;
          if (gcpLocation != null) body['gcp_location'] = gcpLocation;
        }
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tts/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      _lastError = 'Erreur ${response.statusCode}';
      return null;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }
  
  /// Récupère la liste des voix Google Cloud TTS
  Future<List<Map<String, dynamic>>> getGcpVoices({
    required String apiKey,
    required String projectId,
    String location = 'global',
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tts/gcp/voices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': apiKey,
          'project_id': projectId,
          'location': location,
          'force_refresh': forceRefresh,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final voices = List<Map<String, dynamic>>.from(data['voices'] ?? []);
        _lastError = null;
        _isConnected = true;
        _isLoading = false;
        notifyListeners();
        return voices;
      } else {
        _lastError = 'Erreur ${response.statusCode}';
      }
    } catch (e) {
      _lastError = e.toString();
      _isConnected = false;
    }
    
    _isLoading = false;
    notifyListeners();
    return [];
  }
  
  /// Génère un TTS avec détection automatique
  Future<Uint8List?> generateTtsAuto({
    required String text,
    String preferredGender = 'Female',
    String? preferredVoice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tts/generate-auto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'preferred_gender': preferredGender,
          if (preferredVoice != null) 'preferred_voice': preferredVoice,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      _lastError = 'Erreur ${response.statusCode}';
      return null;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }
  
  /// Prévisualise une voix
  Future<Uint8List?> previewVoice({
    required String voice,
    String? sampleText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tts/preview-voice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voice': voice,
          if (sampleText != null) 'sample_text': sampleText,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      _lastError = 'Erreur ${response.statusCode}';
      return null;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }
}

