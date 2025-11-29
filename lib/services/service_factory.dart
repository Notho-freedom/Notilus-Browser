import 'package:flutter/foundation.dart';
import 'studio/studio_service.dart';
import 'lighthouse/lighthouse_service.dart';

/// Factory pour créer et gérer les services lourds avec lazy loading
/// Évite l'initialisation inutile des services non utilisés
class ServiceFactory {
  static StudioService? _studioService;
  static LighthouseService? _lighthouseService;
  
  // Timestamps pour détacher les services inactifs
  static DateTime? _studioLastUsed;
  static DateTime? _lighthouseLastUsed;
  
  // Délai avant détachement (10 minutes)
  static const Duration _inactivityTimeout = Duration(minutes: 10);
  
  /// Récupère ou crée le StudioService (lazy loading)
  static StudioService getStudioService() {
    _studioLastUsed = DateTime.now();
    _studioService ??= StudioService();
    return _studioService!;
  }
  
  /// Récupère ou crée le LighthouseService (lazy loading)
  static LighthouseService getLighthouseService() {
    _lighthouseLastUsed = DateTime.now();
    _lighthouseService ??= LighthouseService();
    return _lighthouseService!;
  }
  
  /// Vérifie et détache les services inactifs
  static void checkAndDetachInactiveServices() {
    final now = DateTime.now();
    
    // Détacher StudioService si inactif
    if (_studioService != null && _studioLastUsed != null) {
      if (now.difference(_studioLastUsed!) > _inactivityTimeout) {
        _studioService!.detachEngine();
        debugPrint('🔌 StudioService détaché (inactivité > 10 min)');
      }
    }
    
    // Détacher LighthouseService si inactif
    if (_lighthouseService != null && _lighthouseLastUsed != null) {
      if (now.difference(_lighthouseLastUsed!) > _inactivityTimeout) {
        _lighthouseService!.detachEngine();
        debugPrint('🔌 LighthouseService détaché (inactivité > 10 min)');
      }
    }
  }
  
  /// Nettoie tous les services (pour tests ou shutdown)
  static void dispose() {
    _studioService?.dispose();
    _lighthouseService?.dispose();
    _studioService = null;
    _lighthouseService = null;
    _studioLastUsed = null;
    _lighthouseLastUsed = null;
  }
  
  /// Retourne true si un service est actif
  static bool hasActiveServices() {
    return _studioService != null || _lighthouseService != null;
  }
}

