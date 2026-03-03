import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Service de stockage sécurisé pour les données sensibles
/// Utilise flutter_secure_storage pour le chiffrement natif Windows (DPAPI)
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Configuration Windows pour utiliser DPAPI (Data Protection API)
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(),
  );

  // Clés de stockage
  static const String _keyGitHubToken = 'notilus_github_token';
  static const String _keyGitHubUser = 'notilus_github_user';
  static const String _keyGroqApiKey = 'notilus_groq_api_key';
  static const String _keyGcpTtsApiKey = 'notilus_gcp_tts_api_key';
  static const String _keyFirebaseToken = 'notilus_firebase_token';
  static const String _keyCloudinaryApiKey = 'notilus_cloudinary_api_key';

  // ============================================
  // MÉTHODES GÉNÉRIQUES
  // ============================================

  /// Stocke une valeur de manière sécurisée
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('✅ Secure storage: $key saved');
    } catch (e) {
      debugPrint('❌ Secure storage write error for $key: $e');
      rethrow;
    }
  }

  /// Lit une valeur stockée de manière sécurisée
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('❌ Secure storage read error for $key: $e');
      return null;
    }
  }

  /// Supprime une valeur stockée
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('✅ Secure storage: $key deleted');
    } catch (e) {
      debugPrint('❌ Secure storage delete error for $key: $e');
    }
  }

  /// Vérifie si une clé existe
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('❌ Secure storage containsKey error for $key: $e');
      return false;
    }
  }

  /// Supprime toutes les données sécurisées
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ Secure storage: all data deleted');
    } catch (e) {
      debugPrint('❌ Secure storage deleteAll error: $e');
    }
  }

  // ============================================
  // GITHUB TOKEN
  // ============================================

  /// Stocke le token GitHub de manière sécurisée
  Future<void> saveGitHubToken(String token) async {
    await write(_keyGitHubToken, token);
  }

  /// Récupère le token GitHub
  Future<String?> getGitHubToken() async {
    return await read(_keyGitHubToken);
  }

  /// Supprime le token GitHub
  Future<void> deleteGitHubToken() async {
    await delete(_keyGitHubToken);
  }

  // ============================================
  // GITHUB USER (JSON sérialisé)
  // ============================================

  /// Stocke les informations utilisateur GitHub
  Future<void> saveGitHubUser(Map<String, dynamic> userJson) async {
    await write(_keyGitHubUser, jsonEncode(userJson));
  }

  /// Récupère les informations utilisateur GitHub
  Future<Map<String, dynamic>?> getGitHubUser() async {
    final json = await read(_keyGitHubUser);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error parsing GitHub user JSON: $e');
      return null;
    }
  }

  /// Supprime les informations utilisateur GitHub
  Future<void> deleteGitHubUser() async {
    await delete(_keyGitHubUser);
  }

  // ============================================
  // GROQ API KEY
  // ============================================

  /// Stocke la clé API Groq
  Future<void> saveGroqApiKey(String apiKey) async {
    await write(_keyGroqApiKey, apiKey);
  }

  /// Récupère la clé API Groq
  Future<String?> getGroqApiKey() async {
    return await read(_keyGroqApiKey);
  }

  /// Supprime la clé API Groq
  Future<void> deleteGroqApiKey() async {
    await delete(_keyGroqApiKey);
  }

  // ============================================
  // GCP TTS API KEY
  // ============================================

  /// Stocke la clé API GCP TTS
  Future<void> saveGcpTtsApiKey(String apiKey) async {
    await write(_keyGcpTtsApiKey, apiKey);
  }

  /// Récupère la clé API GCP TTS
  Future<String?> getGcpTtsApiKey() async {
    return await read(_keyGcpTtsApiKey);
  }

  /// Supprime la clé API GCP TTS
  Future<void> deleteGcpTtsApiKey() async {
    await delete(_keyGcpTtsApiKey);
  }

  // ============================================
  // FIREBASE TOKEN
  // ============================================

  /// Stocke le token Firebase
  Future<void> saveFirebaseToken(String token) async {
    await write(_keyFirebaseToken, token);
  }

  /// Récupère le token Firebase
  Future<String?> getFirebaseToken() async {
    return await read(_keyFirebaseToken);
  }

  /// Supprime le token Firebase
  Future<void> deleteFirebaseToken() async {
    await delete(_keyFirebaseToken);
  }

  // ============================================
  // CLOUDINARY API KEY
  // ============================================

  /// Stocke la clé API Cloudinary
  Future<void> saveCloudinaryApiKey(String apiKey) async {
    await write(_keyCloudinaryApiKey, apiKey);
  }

  /// Récupère la clé API Cloudinary
  Future<String?> getCloudinaryApiKey() async {
    return await read(_keyCloudinaryApiKey);
  }

  /// Supprime la clé API Cloudinary
  Future<void> deleteCloudinaryApiKey() async {
    await delete(_keyCloudinaryApiKey);
  }

  // ============================================
  // UTILITAIRES
  // ============================================

  /// Génère un hash SHA-256 d'une chaîne (pour vérification d'intégrité)
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Masque une clé API pour l'affichage (ex: "sk-****1234")
  String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) {
      return '****';
    }
    final prefix = apiKey.substring(0, 3);
    final suffix = apiKey.substring(apiKey.length - 4);
    return '$prefix****$suffix';
  }

  /// Vérifie si une clé API a un format valide (non vide et longueur minimale)
  bool isValidApiKey(String? apiKey, {int minLength = 10}) {
    return apiKey != null && apiKey.isNotEmpty && apiKey.length >= minLength;
  }
}

