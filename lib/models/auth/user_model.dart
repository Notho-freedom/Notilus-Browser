/// Modèle utilisateur pour l'authentification
library user_model;

import 'package:firebase_auth/firebase_auth.dart';

/// Modèle utilisateur étendu
class NotilusUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? providerId;

  NotilusUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.providerId,
  });

  factory NotilusUser.fromFirebaseUser(User user) {
    return NotilusUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      providerId: user.providerData.isNotEmpty ? user.providerData.first.providerId : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'providerId': providerId,
    };
  }
}

