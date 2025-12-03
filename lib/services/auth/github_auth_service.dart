/// GitHub Auth Service - Authentification GitHub simplifiée via Firebase
/// Remplace firebase_auth_service.dart avec uniquement GitHub comme provider
library github_auth_service;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/secure_storage_service.dart';
import '../../core/utils/result.dart';

/// Modèle utilisateur GitHub simplifié
class GitHubUserProfile {
  final String id;
  final String login;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String accessToken;
  final DateTime connectedAt;

  const GitHubUserProfile({
    required this.id,
    required this.login,
    this.name,
    this.email,
    this.avatarUrl,
    required this.accessToken,
    required this.connectedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'login': login,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'accessToken': accessToken,
    'connectedAt': connectedAt.toIso8601String(),
  };

  factory GitHubUserProfile.fromJson(Map<String, dynamic> json) {
    return GitHubUserProfile(
      id: json['id'] as String,
      login: json['login'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      accessToken: json['accessToken'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
    );
  }

  String get displayName => name ?? login;
}

/// Service d'authentification GitHub simplifié
class GitHubAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecureStorageService _secureStorage = SecureStorageService();
  
  User? _firebaseUser;
  GitHubUserProfile? _githubUser;
  bool _isLoading = false;
  String? _error;

  GitHubAuthService() {
    // Écouter les changements Firebase
    _auth.authStateChanges().listen((user) {
      _firebaseUser = user;
      notifyListeners();
    });
    
    // Charger l'utilisateur GitHub sauvegardé
    _loadSavedUser();
  }

  // Getters
  bool get isAuthenticated => _githubUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get firebaseUser => _firebaseUser;
  GitHubUserProfile? get githubUser => _githubUser;
  String? get displayName => _githubUser?.displayName;
  String? get avatarUrl => _githubUser?.avatarUrl;
  String? get email => _githubUser?.email ?? _firebaseUser?.email;

  /// Charge l'utilisateur sauvegardé depuis le stockage sécurisé
  Future<void> _loadSavedUser() async {
    try {
      final userJson = await _secureStorage.getGitHubUser();
      if (userJson != null) {
        _githubUser = GitHubUserProfile.fromJson(userJson);
        notifyListeners();
        debugPrint('✅ Utilisateur GitHub chargé: ${_githubUser?.login}');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement utilisateur: $e');
    }
  }

  /// Sauvegarde l'utilisateur dans le stockage sécurisé
  Future<void> _saveUser(GitHubUserProfile user) async {
    await _secureStorage.saveGitHubUser(user.toJson());
    await _secureStorage.saveGitHubToken(user.accessToken);
  }

  /// Connexion avec GitHub via Firebase OAuth
  Future<AuthResult<GitHubUserProfile>> signInWithGitHub() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Créer le provider GitHub
      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');
      githubProvider.addScope('repo');

      // Authentification via popup
      final userCredential = await _auth.signInWithPopup(githubProvider);
      
      if (userCredential.user == null) {
        _isLoading = false;
        notifyListeners();
        return const Failure(AuthError.unknown);
      }

      // Récupérer le token GitHub
      final credential = userCredential.credential as OAuthCredential?;
      final accessToken = credential?.accessToken;

      if (accessToken == null) {
        _isLoading = false;
        notifyListeners();
        return const Failure(AuthError.invalidToken);
      }

      // Récupérer les infos GitHub
      final githubProfile = await _fetchGitHubProfile(accessToken);
      
      if (githubProfile == null) {
        _isLoading = false;
        notifyListeners();
        return const Failure(AuthError.networkError);
      }

      // Créer le profil utilisateur
      _githubUser = GitHubUserProfile(
        id: githubProfile['id'].toString(),
        login: githubProfile['login'] as String,
        name: githubProfile['name'] as String?,
        email: githubProfile['email'] as String? ?? userCredential.user!.email,
        avatarUrl: githubProfile['avatar_url'] as String?,
        accessToken: accessToken,
        connectedAt: DateTime.now(),
      );

      // Sauvegarder
      await _saveUser(_githubUser!);

      _isLoading = false;
      notifyListeners();
      
      debugPrint('✅ Connexion GitHub réussie: ${_githubUser?.login}');
      return Success(_githubUser!);

    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      
      debugPrint('❌ Erreur Firebase: ${e.code} - ${e.message}');
      
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        return const Failure(AuthError.userCancelled);
      }
      return const Failure(AuthError.unknown);
      
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      
      debugPrint('❌ Erreur connexion GitHub: $e');
      return const Failure(AuthError.unknown);
    }
  }

  /// Récupère le profil GitHub via l'API
  Future<Map<String, dynamic>?> _fetchGitHubProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur API GitHub: $e');
      return null;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      await _secureStorage.deleteGitHubUser();
      await _secureStorage.deleteGitHubToken();
      
      _githubUser = null;
      _firebaseUser = null;
      _error = null;
      
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur déconnexion: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Rafraîchit le token si nécessaire
  Future<String?> getValidToken() async {
    if (_githubUser == null) return null;
    
    // Vérifier si le token est encore valide
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer ${_githubUser!.accessToken}',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        return _githubUser!.accessToken;
      }
      
      // Token invalide, déconnecter
      await signOut();
      return null;
    } catch (e) {
      return _githubUser?.accessToken;
    }
  }

  /// Vérifie si connecté
  Future<bool> checkAuthStatus() async {
    if (_githubUser == null) return false;
    final token = await getValidToken();
    return token != null;
  }
}

