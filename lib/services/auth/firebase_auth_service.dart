/// Service d'authentification Firebase pour Notilus
library firebase_auth_service;

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/foundation.dart' as foundation;
import 'local_oauth_service.dart';

/// Service d'authentification Firebase
class FirebaseAuthService extends foundation.ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  final LocalOAuthService _localOAuth = LocalOAuthService();
  User? _currentUser;
  bool _isLoading = false;
  bool _useLocalBackend = false;
  
  FirebaseAuthService() {
    // google_sign_in n'est pas supporté sur Windows
    // Utiliser uniquement sur les plateformes supportées
    if (!Platform.isWindows) {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
    
    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
    
    // Vérifier si le backend local est disponible
    _checkLocalBackend();
  }
  
  /// Vérifie si le backend local OAuth est disponible
  Future<void> _checkLocalBackend() async {
    try {
      _useLocalBackend = await _localOAuth.isBackendAvailable();
      if (_useLocalBackend) {
        debugPrint('✅ Backend OAuth local disponible');
      } else {
        debugPrint('⚠️ Backend OAuth local non disponible');
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification du backend: $e');
      _useLocalBackend = false;
    }
  }

  /// Utilisateur actuel
  User? get currentUser => _currentUser;

  /// Vérifie si l'utilisateur est connecté
  bool get isSignedIn => _currentUser != null;

  /// État de chargement
  bool get isLoading => _isLoading;

  /// Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Sur Windows, utiliser un flux OAuth personnalisé via le navigateur
      if (Platform.isWindows) {
        return await _signInWithGoogleWindows();
      }

      // Sur les autres plateformes, utiliser google_sign_in
      if (_googleSignIn == null) {
        debugPrint('Google Sign-In non disponible sur cette plateforme');
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null; // L'utilisateur a annulé
      }

      // Obtenir les détails d'authentification de la demande
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer un nouveau credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Une fois connecté, retourner le UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      debugPrint('Erreur lors de la connexion Google: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Connexion Google sur Windows via Device Flow (backend local)
  Future<UserCredential?> _signInWithGoogleWindows() async {
    try {
      // Vérifier si le backend local est disponible
      if (!_useLocalBackend) {
        await _checkLocalBackend();
      }
      
      if (!_useLocalBackend) {
        debugPrint('⚠️ Backend OAuth local non disponible');
        debugPrint('💡 Démarrez le backend avec: cd backend && python main.py');
        debugPrint('💡 Ou utilisez l\'authentification par email/mot de passe');
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Initier le Device Flow
      final deviceFlow = await _localOAuth.initiateGoogleDeviceFlow();
      if (deviceFlow == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Retourner les informations du Device Flow pour que l'UI puisse les afficher
      // L'UI devra appeler pollGoogleTokenDeviceFlow() pour vérifier l'autorisation
      throw GoogleDeviceFlowException(deviceFlow);
      
    } catch (e) {
      if (e is GoogleDeviceFlowException) {
        rethrow; // Relancer pour que l'UI puisse gérer
      }
      debugPrint('Erreur lors de la connexion Google (Windows): $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Poll pour vérifier si Google Device Flow est complété
  Future<UserCredential?> pollGoogleTokenDeviceFlow(String deviceCode) async {
    try {
      final token = await _localOAuth.pollGoogleToken(deviceCode);
      
      if (token == null) {
        // En attente
        return null;
      }
      
      // Utiliser le token pour créer un credential Firebase
      // Pour Google, on a besoin de l'id_token pour Firebase
      if (token.idToken == null) {
        debugPrint('⚠️ id_token manquant dans la réponse OAuth');
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      final credential = GoogleAuthProvider.credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      debugPrint('Erreur lors du polling Google token: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Connexion avec GitHub (OAuth via backend local)
  Future<UserCredential?> signInWithGitHub() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Vérifier si le backend local est disponible
      if (!_useLocalBackend) {
        await _checkLocalBackend();
      }
      
      if (!_useLocalBackend) {
        throw UnsupportedError(
          'Backend OAuth local non disponible.\n'
          'Démarrez le backend avec: cd backend && python main.py\n'
          'Ou utilisez l\'authentification par email.'
        );
      }
      
      // Générer un state pour la sécurité (utiliser un token sécurisé)
      final state = _generateSecureState();
      
      // Retourner l'URL d'autorisation pour que l'UI puisse ouvrir une WebView
      final authUrl = _localOAuth.getGitHubAuthUrl(state);
      throw GitHubOAuthUrlException(authUrl, state);
      
    } catch (e) {
      if (e is GitHubOAuthUrlException) {
        rethrow; // Relancer pour que l'UI puisse gérer
      }
      debugPrint('Erreur lors de la connexion GitHub: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Récupère le token GitHub après autorisation dans WebView
  Future<UserCredential?> getGitHubTokenAfterAuth(String state) async {
    try {
      final token = await _localOAuth.getGitHubToken(state);
      
      if (token == null) {
        // En attente
        return null;
      }
      
      // Utiliser le token pour créer un credential Firebase
      final credential = OAuthProvider('github.com').credential(
        accessToken: token.accessToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token GitHub: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Connexion GitHub avec un access token (pour flux manuel ou backend)
  Future<UserCredential?> signInWithGitHubToken(String accessToken) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Créer un credential OAuth avec le token GitHub
      final credential = OAuthProvider('github.com').credential(
        accessToken: accessToken,
      );

      // Se connecter avec le credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      debugPrint('Erreur lors de la connexion GitHub avec token: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      final futures = <Future>[_auth.signOut()];
      if (_googleSignIn != null) {
        futures.add(_googleSignIn!.signOut());
      }
      
      await Future.wait(futures);

      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Connexion avec email et mot de passe
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      debugPrint('Erreur lors de la connexion email: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Création de compte avec email et mot de passe
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      debugPrint('Erreur lors de la création de compte: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Vérifie si Google Sign-In est disponible
  bool get isGoogleSignInAvailable => !Platform.isWindows && _googleSignIn != null;

  /// Obtient le token d'ID pour l'utilisateur actuel
  Future<String?> getIdToken() async {
    try {
      return await _currentUser?.getIdToken();
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token: $e');
      return null;
    }
  }
  
  /// Vérifie si le backend local est disponible
  bool get isLocalBackendAvailable => _useLocalBackend;
  
  /// Génère un state sécurisé pour OAuth
  String _generateSecureState() {
    // Utiliser un timestamp + random pour créer un state unique
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'notilus_${timestamp}_${random.substring(random.length - 8)}';
  }
}

/// Exception pour gérer le Device Flow Google
class GoogleDeviceFlowException implements Exception {
  final GoogleDeviceFlow deviceFlow;
  
  GoogleDeviceFlowException(this.deviceFlow);
  
  @override
  String toString() => 'Google Device Flow initié';
}

/// Exception pour gérer l'URL GitHub OAuth
class GitHubOAuthUrlException implements Exception {
  final String authUrl;
  final String state;
  
  GitHubOAuthUrlException(this.authUrl, this.state);
  
  @override
  String toString() => 'GitHub OAuth URL: $authUrl';
}


