/// Service AI pour Notilus Browser
/// Communique avec l'API backend AI (Groq)
library ai_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

/// Service principal pour l'IA
class AiService extends ChangeNotifier {
  static const String _defaultBaseUrl = 'http://localhost:8000';
  
  final SettingsService _settings = SettingsService();
  String _baseUrl;
  bool _isConnected = false;
  String? _lastError;
  
  AiService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;
  
  // Getters
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  String get baseUrl => _baseUrl;
  
  set baseUrl(String url) {
    _baseUrl = url;
    notifyListeners();
  }
  
  /// Vérifie si le backend AI est disponible
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ai/status'),
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
  
  /// Récupère les headers avec la clé API
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    final apiKey = _settings.groqApiKey;
    if (apiKey.isNotEmpty) {
      headers['X-Groq-API-Key'] = apiKey;
    }
    
    return headers;
  }
  
  /// Chat avec l'IA
  Future<Map<String, dynamic>?> chat({
    required String prompt,
    Map<String, dynamic>? context,
    String type = 'general',
    String? model,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/chat'),
        headers: _getHeaders(),
        body: jsonEncode({
          'prompt': prompt,
          if (context != null) 'context': context,
          'type': type,
          if (model != null) 'model': model,
        }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        _lastError = null;
        _isConnected = true;
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Clé API Groq requise. Configurez-la dans les paramètres.';
        throw Exception(_lastError);
      } else {
        _lastError = 'Erreur ${response.statusCode}: ${response.body}';
        return null;
      }
    } catch (e) {
      _lastError = e.toString();
      _isConnected = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Analyse du code
  Future<Map<String, dynamic>?> analyzeCode({
    required String code,
    String? language,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/analyze-code'),
        headers: _getHeaders(),
        body: jsonEncode({
          'code': code,
          if (language != null) 'language': language,
        }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        _lastError = null;
        _isConnected = true;
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Clé API Groq requise. Configurez-la dans les paramètres.';
        throw Exception(_lastError);
      } else {
        _lastError = 'Erreur ${response.statusCode}: ${response.body}';
        return null;
      }
    } catch (e) {
      _lastError = e.toString();
      _isConnected = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Obtenir des suggestions
  Future<List<String>?> getSuggestions({
    required Map<String, dynamic> context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/suggest'),
        headers: _getHeaders(),
        body: jsonEncode({
          'context': context,
        }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastError = null;
        _isConnected = true;
        return List<String>.from(data['suggestions'] ?? []);
      } else if (response.statusCode == 401) {
        _lastError = 'Clé API Groq requise. Configurez-la dans les paramètres.';
        throw Exception(_lastError);
      } else {
        _lastError = 'Erreur ${response.statusCode}: ${response.body}';
        return null;
      }
    } catch (e) {
      _lastError = e.toString();
      _isConnected = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Récupère la liste des modèles disponibles depuis l'API Groq
  Future<List<String>?> getModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ai/models'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastError = null;
        _isConnected = true;
        
        // Extraire les modèles depuis la réponse
        final models = data['models'] as List?;
        if (models != null) {
          return List<String>.from(models.map((m) => m.toString()));
        }
        return [];
      } else {
        _lastError = 'Erreur ${response.statusCode}: ${response.body}';
        return null;
      }
    } catch (e) {
      _lastError = e.toString();
      _isConnected = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Test de connexion avec la clé API
  Future<bool> testConnection() async {
    if (_settings.groqApiKey.isEmpty) {
      _lastError = 'Clé API non configurée';
      return false;
    }
    
    try {
      // Faire un test simple
      final result = await chat(
        prompt: 'Test',
        type: 'general',
      );
      
      return result != null;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
}

