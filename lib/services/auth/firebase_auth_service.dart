/// Service d'authentification Firebase pour Notilus
library firebase_auth_service;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Service d'authentification Firebase
class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

      // Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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

  /// Connexion avec GitHub (OAuth custom)
  Future<UserCredential?> signInWithGitHub() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Note: GitHub OAuth nécessite une configuration custom
      // Pour l'instant, on retourne null
      // TODO: Implémenter GitHub OAuth avec Firebase
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la connexion GitHub: $e');
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

      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

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

