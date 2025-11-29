/// Service de synchronisation des configurations Notilus avec Firestore
library config_sync_service;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../settings_service.dart';
import 'firebase_auth_service.dart';

/// Service de synchronisation des configurations
class ConfigSyncService extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final SettingsService _settingsService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSyncing = false;
  bool _lastSyncSuccess = false;
  DateTime? _lastSyncTime;

  ConfigSyncService(this._authService, this._settingsService) {
    // Écouter les changements d'authentification
    _authService.addListener(_onAuthStateChanged);
  }

  /// État de synchronisation
  bool get isSyncing => _isSyncing;
  bool get lastSyncSuccess => _lastSyncSuccess;
  DateTime? get lastSyncTime => _lastSyncTime;

  void _onAuthStateChanged() {
    if (_authService.isSignedIn) {
      // Automatiquement restaurer les configs au login
      restoreConfigs();
    }
  }

  /// Exporte les configurations vers Firestore
  Future<bool> exportConfigs() async {
    if (!_authService.isSignedIn) {
      debugPrint('Utilisateur non connecté, impossible d\'exporter');
      return false;
    }

    try {
      _isSyncing = true;
      notifyListeners();

      final user = _authService.currentUser;
      if (user == null) {
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      // Préparer les données de configuration
      final configs = {
        'themeMode': _settingsService.themeMode.toString(),
        'colorTheme': _settingsService.colorTheme,
        'wallpaperEnabled': _settingsService.wallpaperEnabled,
        'wallpaperRotationEnabled': _settingsService.wallpaperRotationEnabled,
        'wallpaperIntervalMinutes': _settingsService.wallpaperIntervalMinutes,
        'restoreTabsOnStartup': _settingsService.restoreTabsOnStartup,
        'startOnHomePage': _settingsService.startOnHomePage,
        'newTabBehavior': _settingsService.newTabBehavior,
        'downloadFolder': _settingsService.downloadFolder,
        'askDownloadLocation': _settingsService.askDownloadLocation,
        'autoOpenDownloads': _settingsService.autoOpenDownloads,
        'terminalInterfaceType': _settingsService.terminalInterfaceType,
        'terminalFontSize': _settingsService.terminalFontSize,
        'widgetTransparency': _settingsService.widgetTransparency,
        'panelTransparency': _settingsService.panelTransparency,
        'overlayTransparency': _settingsService.overlayTransparency,
        'glassBlurIntensity': _settingsService.glassBlurIntensity,
        'homePageStyle': _settingsService.homePageStyle,
        'devProfile': _settingsService.devProfile,
        'lastSync': FieldValue.serverTimestamp(),
      };

      // Sauvegarder dans Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('configs')
          .doc('notilus_settings')
          .set(configs, SetOptions(merge: true));

      _lastSyncSuccess = true;
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'export des configurations: $e');
      _lastSyncSuccess = false;
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Restaure les configurations depuis Firestore
  Future<bool> restoreConfigs() async {
    if (!_authService.isSignedIn) {
      debugPrint('Utilisateur non connecté, impossible de restaurer');
      return false;
    }

    try {
      _isSyncing = true;
      notifyListeners();

      final user = _authService.currentUser;
      if (user == null) {
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      // Récupérer les configurations depuis Firestore
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('configs')
          .doc('notilus_settings')
          .get();

      if (!doc.exists) {
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final data = doc.data()!;

      // Restaurer les configurations
      if (data.containsKey('themeMode')) {
        final modeStr = data['themeMode'] as String;
        if (modeStr.contains('light')) {
          await _settingsService.setThemeMode(ThemeMode.light);
        } else if (modeStr.contains('dark')) {
          await _settingsService.setThemeMode(ThemeMode.dark);
        } else {
          await _settingsService.setThemeMode(ThemeMode.system);
        }
      }

      if (data.containsKey('colorTheme')) {
        await _settingsService.setColorTheme(data['colorTheme'] as String);
      }

      if (data.containsKey('wallpaperEnabled')) {
        await _settingsService.setWallpaperEnabled(data['wallpaperEnabled'] as bool);
      }

      if (data.containsKey('wallpaperRotationEnabled')) {
        await _settingsService.setWallpaperRotationEnabled(data['wallpaperRotationEnabled'] as bool);
      }

      if (data.containsKey('wallpaperIntervalMinutes')) {
        await _settingsService.setWallpaperIntervalMinutes(data['wallpaperIntervalMinutes'] as int);
      }

      if (data.containsKey('restoreTabsOnStartup')) {
        await _settingsService.setRestoreTabsOnStartup(data['restoreTabsOnStartup'] as bool);
      }

      if (data.containsKey('startOnHomePage')) {
        await _settingsService.setStartOnHomePage(data['startOnHomePage'] as bool);
      }

      if (data.containsKey('newTabBehavior')) {
        await _settingsService.setNewTabBehavior(data['newTabBehavior'] as String);
      }

      if (data.containsKey('downloadFolder')) {
        await _settingsService.setDownloadFolder(data['downloadFolder'] as String?);
      }

      if (data.containsKey('askDownloadLocation')) {
        await _settingsService.setAskDownloadLocation(data['askDownloadLocation'] as bool);
      }

      if (data.containsKey('autoOpenDownloads')) {
        await _settingsService.setAutoOpenDownloads(data['autoOpenDownloads'] as bool);
      }

      if (data.containsKey('terminalInterfaceType')) {
        await _settingsService.setTerminalInterfaceType(data['terminalInterfaceType'] as String);
      }

      if (data.containsKey('terminalFontSize')) {
        await _settingsService.setTerminalFontSize((data['terminalFontSize'] as num).toDouble());
      }

      if (data.containsKey('widgetTransparency')) {
        await _settingsService.setWidgetTransparency((data['widgetTransparency'] as num).toDouble());
      }

      if (data.containsKey('panelTransparency')) {
        await _settingsService.setPanelTransparency((data['panelTransparency'] as num).toDouble());
      }

      if (data.containsKey('overlayTransparency')) {
        await _settingsService.setOverlayTransparency((data['overlayTransparency'] as num).toDouble());
      }

      if (data.containsKey('glassBlurIntensity')) {
        await _settingsService.setGlassBlurIntensity((data['glassBlurIntensity'] as num).toDouble());
      }

      if (data.containsKey('homePageStyle')) {
        await _settingsService.setHomePageStyle(data['homePageStyle'] as String);
      }

      if (data.containsKey('devProfile')) {
        await _settingsService.setDevProfile(data['devProfile'] as String);
      }

      _lastSyncSuccess = true;
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la restauration des configurations: $e');
      _lastSyncSuccess = false;
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}

