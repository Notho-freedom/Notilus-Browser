/// Service d'authentification Firebase pour Notilus
library firebase_auth_service;

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/foundation.dart' as foundation;

/// Service d'authentification Firebase
class FirebaseAuthService extends foundation.ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  User? _currentUser;
  bool _isLoading = false;
  
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
      // (Settings > Authentication > Sign-in method > Add new provider > GitHub)
      
      final provider = OAuthProvider('github.com');
      
      // Configurer les scopes GitHub
      provider.setCustomParameters({
        'allow_signup': 'true',
      });
      provider.addScope('read:user');
      provider.addScope('user:email');
      
      // Note: signInWithPopup/signInWithRedirect ne sont pas disponibles dans firebase_auth Flutter
      // Il faut utiliser un flux OAuth personnalisé avec un serveur backend
      // ou utiliser signInWithCredential avec un token obtenu manuellement
      
      throw UnsupportedError(
        'GitHub OAuth nécessite une configuration backend OAuth.\n'
        'Pour l\'instant, utilisez l\'authentification par email.\n'
        'GitHub doit être activé dans Firebase Console (Authentication > Sign-in method).\n'
        'Pour implémenter GitHub OAuth, configurez un serveur backend qui gère le flux OAuth.'
      );
    } catch (e) {
      debugPrint('Erreur lors de la connexion GitHub: $e');
      _isLoading = false;
      notifyListeners();
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
}


