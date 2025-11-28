/// Service d'authentification Firebase pour Notilus
library firebase_auth_service;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/foundation.dart' as foundation;
import 'package:http/http.dart' as http;
import 'local_oauth_service.dart';

/// Service d'authentification Firebase
class FirebaseAuthService extends foundation.ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  final LocalOAuthService _localOAuth = LocalOAuthService();
  User? _currentUser;
  bool _isLoading = false;
  bool _useLocalBackend = false;
  final Map<String, Timer> _pollingTimers = {}; // Map pour stocker les timers de polling par state
  
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
      
      // Démarrer le polling automatiquement pour ce state
      _startGitHubPolling(state);
      
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
  
  /// Démarre le polling pour récupérer le token GitHub
  void _startGitHubPolling(String state) {
    // Annuler le polling précédent pour ce state s'il existe
    _pollingTimers[state]?.cancel();
    
    debugPrint('🔄 Démarrage du polling GitHub pour state: $state');
    
    _pollingTimers[state] = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        try {
          final result = await getGitHubTokenAfterAuth(state);
          
          if (result != null) {
            // Authentification réussie, arrêter le polling
            timer.cancel();
            _pollingTimers.remove(state);
            debugPrint('✅ Polling GitHub arrêté avec succès pour state: $state');
            return;
          }
          
          // Continuer le polling si le résultat est null (en attente)
        } catch (e) {
          debugPrint('❌ Erreur lors du polling GitHub: $e');
          // Continuer le polling même en cas d'erreur (sauf si c'est une erreur fatale)
          // Ne pas arrêter le polling si c'est juste une erreur temporaire
        }
        
        // Limiter le polling à 5 minutes maximum (150 tentatives)
        // Pour éviter un polling infini
        if (timer.tick > 150) {
          timer.cancel();
          _pollingTimers.remove(state);
          debugPrint('⏱️ Polling GitHub arrêté après timeout (5 minutes) pour state: $state');
        }
      },
    );
  }
  
  /// Arrête le polling pour un state donné
  void stopGitHubPolling(String state) {
    _pollingTimers[state]?.cancel();
    _pollingTimers.remove(state);
    debugPrint('🛑 Polling GitHub arrêté pour state: $state');
  }
  
  /// Récupère le token GitHub après autorisation dans WebView
  Future<UserCredential?> getGitHubTokenAfterAuth(String state) async {
    try {
      debugPrint('🔍 getGitHubTokenAfterAuth appelé avec state: $state');
      final token = await _localOAuth.getGitHubToken(state);
      
      if (token == null) {
        // En attente
        debugPrint('⏳ Token GitHub en attente...');
        return null;
      }
      
      debugPrint('✅ Token GitHub reçu, récupération des infos utilisateur...');
      
      // Obtenir les informations utilisateur depuis l'API GitHub
      final userInfo = await _getGitHubUserInfo(token.accessToken!);
      if (userInfo == null) {
        throw Exception('Impossible de récupérer les informations utilisateur GitHub');
      }
      
      final email = userInfo['email'] as String?;
      final login = userInfo['login'] as String?;
      final name = userInfo['name'] as String?;
      
      if (email == null || email.isEmpty) {
        // Si l'email n'est pas public, essayer de récupérer les emails privés
        final emails = await _getGitHubUserEmails(token.accessToken!);
        if (emails != null && emails.isNotEmpty) {
          final primaryEmail = emails.firstWhere(
            (e) => e['primary'] == true,
            orElse: () => emails.first,
          );
          final userEmail = primaryEmail['email'] as String?;
          if (userEmail != null && userEmail.isNotEmpty) {
            return await _signInOrCreateWithEmail(userEmail, name ?? login ?? 'GitHub User', token.accessToken!);
          }
        }
        throw Exception('Aucun email trouvé pour le compte GitHub');
      }
      
      // Créer ou connecter avec l'email
      return await _signInOrCreateWithEmail(email, name ?? login ?? 'GitHub User', token.accessToken!);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du token GitHub: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Récupère les informations utilisateur depuis l'API GitHub
  Future<Map<String, dynamic>?> _getGitHubUserInfo(String accessToken) async {
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
      } else {
        debugPrint('❌ Erreur API GitHub: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des infos GitHub: $e');
      return null;
    }
  }
  
  /// Récupère les emails de l'utilisateur GitHub (y compris privés)
  Future<List<Map<String, dynamic>>?> _getGitHubUserEmails(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user/emails'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        debugPrint('❌ Erreur API GitHub emails: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des emails GitHub: $e');
      return null;
    }
  }
  
  /// Crée ou connecte un compte Firebase avec l'email GitHub
  Future<UserCredential> _signInOrCreateWithEmail(String email, String displayName, String githubToken) async {
    try {
      // Essayer de se connecter avec l'email
      try {
        // Générer un mot de passe temporaire basé sur le token GitHub
        // Note: Ce n'est pas idéal, mais Firebase nécessite un mot de passe pour email/password
        // Une meilleure solution serait d'utiliser un custom token généré par le backend
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: githubToken.substring(0, 20), // Utiliser les 20 premiers caractères comme mot de passe temporaire
        );
        
        _currentUser = userCredential.user;
        if (_currentUser != null && _currentUser!.displayName != displayName) {
          await _currentUser!.updateDisplayName(displayName);
        }
        
        debugPrint('✅ Connexion GitHub réussie (compte existant): $email');
        _isLoading = false;
        notifyListeners();
        
        return userCredential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Créer un nouveau compte
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: githubToken.substring(0, 20), // Mot de passe temporaire
          );
          
          _currentUser = userCredential.user;
          if (_currentUser != null) {
            await _currentUser!.updateDisplayName(displayName);
          }
          
          debugPrint('✅ Compte GitHub créé avec succès: $email');
          _isLoading = false;
          notifyListeners();
          
          return userCredential;
        } else if (e.code == 'wrong-password') {
          // Le compte existe mais avec un autre mot de passe
          // Dans ce cas, on ne peut pas se connecter automatiquement
          throw Exception('Un compte existe déjà avec cet email mais avec un autre mot de passe. Veuillez utiliser la connexion par email.');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la création/connexion avec email: $e');
      rethrow;
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


