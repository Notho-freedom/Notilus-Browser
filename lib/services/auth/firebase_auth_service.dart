/// Service d'authentification Firebase pour Notilus
library firebase_auth_service;

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service d'authentification Firebase
class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  
  FirebaseAuthService() {
    // google_sign_in n'est pas supporté sur Windows
    // Utiliser uniquement sur les plateformes supportées
    if (!Platform.isWindows) {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }

  User? _currentUser;
  bool _isLoading = false;

  FirebaseAuthService() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
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

  /// Connexion Google sur Windows via OAuth personnalisé
  Future<UserCredential?> _signInWithGoogleWindows() async {
    try {
      // Note: Pour Windows, il faut configurer OAuth dans Firebase Console
      // et utiliser un flux personnalisé. Pour l'instant, on affiche un message.
      debugPrint('⚠️ Google Sign-In sur Windows nécessite une configuration OAuth personnalisée');
      debugPrint('💡 Utilisez l\'authentification par email/mot de passe pour Windows');
      
      _isLoading = false;
      notifyListeners();
      
      // Retourner null pour indiquer que la méthode n'est pas disponible
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la connexion Google (Windows): $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Connexion avec GitHub (OAuth via Firebase)
  Future<UserCredential?> signInWithGitHub() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Utiliser Firebase Auth avec OAuthProvider pour GitHub
      // Cela nécessite que GitHub soit configuré dans Firebase Console
      final provider = OAuthProvider('github.com');
      
      // Configurer les scopes GitHub
      provider.addScope('read:user');
      provider.addScope('user:email');
      
      // Sur Windows, utiliser signInWithPopup n'est pas disponible
      // Utiliser signInWithRedirect qui ouvre le navigateur
      if (Platform.isWindows) {
        return await _signInWithGitHubWindows(provider);
      }
      
      // Sur les autres plateformes, essayer signInWithPopup
      try {
        final userCredential = await _auth.signInWithPopup(provider);
        _currentUser = userCredential.user;
        _isLoading = false;
        notifyListeners();
        return userCredential;
      } catch (e) {
        // Si signInWithPopup échoue, utiliser signInWithRedirect
        debugPrint('signInWithPopup échoué, utilisation de signInWithRedirect: $e');
        return await _signInWithGitHubWindows(provider);
      }
    } catch (e) {
      debugPrint('Erreur lors de la connexion GitHub: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Connexion GitHub sur Windows via OAuth redirect
  Future<UserCredential?> _signInWithGitHubWindows(OAuthProvider provider) async {
    try {
      // Note: signInWithRedirect nécessite une configuration spéciale
      // Pour Windows, on va utiliser un flux OAuth personnalisé via le navigateur
      
      // Récupérer l'authDomain depuis Firebase
      final authDomain = _auth.app.options.authDomain ?? 'notilus-browser.firebaseapp.com';
      
      // Construire l'URL OAuth GitHub via Firebase
      final redirectUri = 'https://$authDomain/__/auth/handler';
      final clientId = _getGitHubClientId(); // À configurer
      
      if (clientId == null) {
        debugPrint('⚠️ GitHub OAuth non configuré. Veuillez configurer GitHub dans Firebase Console.');
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Construire l'URL d'authentification GitHub
      final authUrl = Uri.parse(
        'https://github.com/login/oauth/authorize'
        '?client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&scope=read:user user:email'
        '&state=${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Ouvrir le navigateur pour l'authentification
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        
        // Note: Le flux OAuth complet nécessite un serveur backend ou
        // une configuration spéciale pour capturer le callback
        // Pour l'instant, on guide l'utilisateur
        debugPrint('🌐 Navigateur ouvert pour l\'authentification GitHub');
        debugPrint('💡 Après authentification, utilisez le token reçu pour vous connecter');
        
        _isLoading = false;
        notifyListeners();
        
        // Retourner null car le flux n'est pas complètement automatisé
        // L'utilisateur devra entrer le token manuellement ou utiliser un backend
        return null;
      } else {
        throw Exception('Impossible d\'ouvrir le navigateur');
      }
    } catch (e) {
      debugPrint('Erreur lors de la connexion GitHub (Windows): $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Récupère le Client ID GitHub depuis la configuration
  /// Note: Ceci devrait être stocké de manière sécurisée (variables d'environnement, etc.)
  String? _getGitHubClientId() {
    // Pour l'instant, retourner null - l'utilisateur doit configurer cela
    // Dans un environnement de production, cela devrait être dans les variables d'environnement
    // ou dans la configuration Firebase
    return null; // TODO: Configurer le Client ID GitHub
  }
  
  /// Connexion GitHub avec un access token (pour flux manuel)
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
}

