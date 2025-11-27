/// Service OAuth local pour communiquer avec le backend Notilus
library local_oauth_service;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service pour gérer l'OAuth via le backend local
class LocalOAuthService {
  static const String _baseUrl = 'http://localhost:8000/api/oauth';
  
  /// Vérifie si le backend est disponible
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/config'),
      ).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend OAuth non disponible: $e');
      return false;
    }
  }
  
  /// Initie le Device Flow pour Google
  Future<GoogleDeviceFlow?> initiateGoogleDeviceFlow() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/google/device-flow'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GoogleDeviceFlow.fromJson(data);
      } else {
        debugPrint('Erreur device flow: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initiation device flow: $e');
      return null;
    }
  }
  
  /// Poll pour vérifier si Google OAuth est complété
  Future<OAuthToken?> pollGoogleToken(String deviceCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/google/poll/$deviceCode'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OAuthToken.fromJson(data);
      } else if (response.statusCode == 202) {
        // En attente
        return null;
      } else {
        debugPrint('Erreur polling: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors du polling: $e');
      return null;
    }
  }
  
  /// Initie le flux GitHub OAuth avec un state spécifique
  String getGitHubAuthUrl(String state) {
    return '$_baseUrl/github/authorize?state=$state';
  }
  
  /// Récupère le token GitHub après autorisation
  Future<OAuthToken?> getGitHubToken(String state) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/github/token/$state'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OAuthToken.fromJson(data);
      } else if (response.statusCode == 202) {
        // En attente
        return null;
      } else {
        debugPrint('Erreur récupération token GitHub: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token GitHub: $e');
      return null;
    }
  }
}

/// Modèle pour le Device Flow Google
class GoogleDeviceFlow {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final String verificationUriComplete;
  final int expiresIn;
  final int interval;
  
  GoogleDeviceFlow({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.verificationUriComplete,
    required this.expiresIn,
    required this.interval,
  });
  
  factory GoogleDeviceFlow.fromJson(Map<String, dynamic> json) {
    return GoogleDeviceFlow(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUri: json['verification_uri'] as String,
      verificationUriComplete: json['verification_uri_complete'] as String,
      expiresIn: json['expires_in'] as int,
      interval: json['interval'] as int,
    );
  }
}

/// Modèle pour les tokens OAuth
class OAuthToken {
  final String accessToken;
  final String tokenType;
  final String? idToken; // Pour Google
  final String? refreshToken;
  
  OAuthToken({
    required this.accessToken,
    required this.tokenType,
    this.idToken,
    this.refreshToken,
  });
  
  factory OAuthToken.fromJson(Map<String, dynamic> json) {
    return OAuthToken(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      idToken: json['id_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
    );
  }
}

