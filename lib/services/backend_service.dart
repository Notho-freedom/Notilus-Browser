/// Service pour gérer le backend Python Notilus
/// Lance et gère le processus backend au démarrage de l'application
library backend_service;

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class BackendService extends ChangeNotifier {
  static const String _defaultPort = '8000';
  static const String _defaultHost = '127.0.0.1';
  static const String _healthCheckEndpoint = '/api/health';
  
  Process? _process;
  String? _executablePath;
  bool _isRunning = false;
  bool _isInitialized = false;
  String? _lastError;
  Timer? _healthCheckTimer;
  
  String get baseUrl => 'http://$_defaultHost:$_defaultPort';
  bool get isRunning => _isRunning;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  
  /// Initialise et démarre le backend
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Backend déjà initialisé');
      return;
    }
    
    try {
      debugPrint('🚀 Initialisation du backend Notilus...');
      
      // Trouver ou copier l'exécutable
      _executablePath = await _getBackendExecutable();
      
      if (_executablePath == null || !File(_executablePath!).existsSync()) {
        throw Exception('Exécutable backend non trouvé: $_executablePath');
      }
      
      debugPrint('✅ Exécutable backend trouvé: $_executablePath');
      
      // Vérifier si le backend est déjà en cours d'exécution
      if (await _checkBackendRunning()) {
        debugPrint('✅ Backend déjà en cours d\'exécution');
        _isRunning = true;
        _isInitialized = true;
        _startHealthCheck();
        notifyListeners();
        return;
      }
      
      // Démarrer le backend
      await _startBackend();
      
      _isInitialized = true;
      _startHealthCheck();
      notifyListeners();
      
      debugPrint('✅ Backend initialisé et démarré avec succès');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Erreur lors de l\'initialisation du backend: $e');
      notifyListeners();
      rethrow;
    }
  }
  
  /// Trouve ou copie l'exécutable backend
  Future<String?> _getBackendExecutable() async {
    // Nom de l'exécutable selon la plateforme
    String executableName;
    if (Platform.isWindows) {
      executableName = 'notilus-backend.exe';
    } else if (Platform.isLinux) {
      executableName = 'notilus-backend';
    } else if (Platform.isMacOS) {
      executableName = 'notilus-backend';
    } else {
      throw UnsupportedError('Plateforme non supportée: ${Platform.operatingSystem}');
    }
    
    // 1. Vérifier dans le dossier de l'application (pour les builds)
    final appDir = await _getApplicationDirectory();
    final appExecutable = path.join(appDir.path, executableName);
    
    if (File(appExecutable).existsSync()) {
      debugPrint('📦 Exécutable trouvé dans le dossier de l\'app: $appExecutable');
      return appExecutable;
    }
    
    // 2. Vérifier dans le dossier backend/dist (pour le développement)
    final backendDistPath = path.join(
      Directory.current.path,
      'backend',
      'dist',
      executableName,
    );
    
    if (File(backendDistPath).existsSync()) {
      debugPrint('📦 Exécutable trouvé dans backend/dist: $backendDistPath');
      
      // Copier vers le dossier de l'application pour le build
      final targetPath = path.join(appDir.path, executableName);
      await File(backendDistPath).copy(targetPath);
      
      // Rendre exécutable sur Linux/macOS
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', targetPath]);
      }
      
      debugPrint('✅ Exécutable copié vers: $targetPath');
      return targetPath;
    }
    
    debugPrint('⚠️ Exécutable backend non trouvé');
    return null;
  }
  
  /// Obtient le répertoire de l'application
  Future<Directory> _getApplicationDirectory() async {
    // Utiliser le dossier de l'exécutable pour toutes les plateformes
    // Cela garantit que l'exécutable backend est dans le même dossier que l'app
    final exePath = Platform.resolvedExecutable;
    return Directory(path.dirname(exePath));
  }
  
  /// Vérifie si le backend est déjà en cours d'exécution
  Future<bool> _checkBackendRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$_healthCheckEndpoint'))
          .timeout(const Duration(seconds: 2));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Démarre le processus backend
  Future<void> _startBackend() async {
    if (_process != null) {
      debugPrint('⚠️ Backend déjà démarré');
      return;
    }
    
    final executable = _executablePath!;
    final workingDir = path.dirname(executable);
    
    debugPrint('🚀 Démarrage du backend: $executable');
    debugPrint('📁 Répertoire de travail: $workingDir');
    
    // Lancer le processus en arrière-plan
    _process = await Process.start(
      executable,
      [],
      mode: ProcessStartMode.detached,
      runInShell: false,
      workingDirectory: workingDir,
    );
    
    // Attendre un peu pour que le processus démarre
    await Future.delayed(const Duration(seconds: 2));
    
    // Vérifier que le processus est toujours actif
    int? exitCode;
    try {
      exitCode = await _process!.exitCode.timeout(
        const Duration(milliseconds: 100),
      );
    } catch (e) {
      // Timeout signifie que le processus est toujours en cours d'exécution
      exitCode = null;
    }
    
    if (exitCode != null) {
      throw Exception('Le backend s\'est arrêté immédiatement (code: $exitCode)');
    }
    
    // Vérifier que le backend répond
    int retries = 10;
    while (retries > 0) {
      if (await _checkBackendRunning()) {
        _isRunning = true;
        debugPrint('✅ Backend démarré et répond correctement');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      retries--;
    }
    
    throw Exception('Le backend ne répond pas après le démarrage');
  }
  
  /// Démarre la vérification périodique de santé
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final isHealthy = await _checkBackendRunning();
      if (isHealthy != _isRunning) {
        _isRunning = isHealthy;
        notifyListeners();
        
        if (!isHealthy) {
          debugPrint('⚠️ Backend ne répond plus, tentative de redémarrage...');
          try {
            await _startBackend();
          } catch (e) {
            debugPrint('❌ Échec du redémarrage: $e');
          }
        }
      }
    });
  }
  
  /// Arrête le backend
  Future<void> stop() async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    
    if (_process != null) {
      try {
        _process!.kill();
        await _process!.exitCode;
        debugPrint('✅ Backend arrêté');
      } catch (e) {
        debugPrint('⚠️ Erreur lors de l\'arrêt du backend: $e');
      }
      _process = null;
    }
    
    _isRunning = false;
    _isInitialized = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

