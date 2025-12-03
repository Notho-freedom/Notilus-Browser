/// Service pour gérer le processus backend
library backend_process_service;

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../core/services/logger_service.dart';

/// Service pour gérer le processus backend
class BackendProcessService extends ChangeNotifier {
  static final BackendProcessService _instance = BackendProcessService._internal();
  factory BackendProcessService() => _instance;
  BackendProcessService._internal();

  Process? _process;
  bool _isRunning = false;
  bool _isStarting = false;
  String? _error;
  final List<String> _logs = [];
  static const int _maxLogs = 100;
  
  // Configuration
  static const String _exeName = 'notilus-backend.exe';
  static const String _defaultPort = '8000';
  static const String _healthCheckUrl = 'http://localhost:8000/api/health';
  static const int _maxRestartAttempts = 3;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  
  // État interne
  Timer? _healthCheckTimer;
  int _restartAttempts = 0;
  DateTime? _lastSuccessfulHealthCheck;
  
  // Getters
  bool get isRunning => _isRunning;
  DateTime? get lastSuccessfulHealthCheck => _lastSuccessfulHealthCheck;
  bool get isStarting => _isStarting;
  String? get error => _error;
  List<String> get logs => List.unmodifiable(_logs);
  
  String? _backendExe;
  
  /// Tuer les anciennes instances du backend
  Future<void> _killExistingInstances() async {
    try {
      // Sur Windows, utiliser taskkill pour tuer les processus notilus-backend
      if (Platform.isWindows) {
        final result = await Process.run(
          'taskkill',
          ['/F', '/IM', _exeName, '/T'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          LoggerService().info('Anciennes instances du backend arrêtées', context: 'BackendProcess');
        } else if (result.exitCode == 128) {
          // Code 128 = aucun processus trouvé, c'est normal
          LoggerService().debug('Aucune ancienne instance trouvée', context: 'BackendProcess');
        } else {
          LoggerService().debug('Tentative d\'arrêt des anciennes instances (code: ${result.exitCode})', context: 'BackendProcess');
        }
        
        // Attendre un peu pour que les processus se terminent
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // Ignorer les erreurs, ce n'est pas critique
      LoggerService().debug('Erreur lors du nettoyage des anciennes instances: $e', context: 'BackendProcess');
    }
  }
  
  /// Initialiser le chemin de l'exécutable backend
  void _initializePaths() {
    final searchPaths = <String>[];
    final currentDir = Directory.current.path;
    final executableDir = path.dirname(Platform.resolvedExecutable);
    
    // Toujours chercher dans plusieurs emplacements (debug et production)
    // 1. backend/dist/notilus_backend.exe (depuis le répertoire courant)
    searchPaths.add(path.join(currentDir, 'backend', 'dist', _exeName));
    
    // 2. backend/notilus_backend.exe (depuis le répertoire courant)
    searchPaths.add(path.join(currentDir, 'backend', _exeName));
    
    // 3. À côté de l'exe Flutter (production)
    searchPaths.add(path.join(executableDir, _exeName));
    
    // 4. Dans le répertoire courant
    searchPaths.add(path.join(currentDir, _exeName));
    
    // 5. Chercher aussi dans le répertoire parent (au cas où on serait dans un sous-dossier)
    final parentDir = path.dirname(currentDir);
    searchPaths.add(path.join(parentDir, 'backend', 'dist', _exeName));
    searchPaths.add(path.join(parentDir, 'backend', _exeName));
    
    // 6. Chercher dans build/windows/x64/runner/Release/backend/dist/ (pour les builds)
    if (executableDir.contains('build')) {
      final buildRoot = path.dirname(path.dirname(path.dirname(executableDir)));
      searchPaths.add(path.join(buildRoot, 'backend', 'dist', _exeName));
    }
    
    LoggerService().info('Recherche du backend (mode: ${kDebugMode ? "DEBUG" : "PRODUCTION"})...', context: 'BackendProcess');
    LoggerService().info('Répertoire courant: $currentDir', context: 'BackendProcess');
    LoggerService().info('Répertoire exécutable: $executableDir', context: 'BackendProcess');
    
    // Essayer chaque chemin
    for (final exePath in searchPaths) {
      final normalizedPath = path.normalize(exePath);
      LoggerService().info('Vérification: $normalizedPath', context: 'BackendProcess');
      if (File(normalizedPath).existsSync()) {
        _backendExe = normalizedPath;
        LoggerService().info('✅ Backend trouvé: $_backendExe', context: 'BackendProcess');
        return;
      } else {
        LoggerService().debug('❌ Non trouvé: $normalizedPath', context: 'BackendProcess');
      }
    }
    
    // Exécutable non trouvé - logger tous les chemins essayés
    LoggerService().error('Exécutable backend introuvable dans les emplacements suivants:', context: 'BackendProcess');
    for (final exePath in searchPaths) {
      LoggerService().error('  - ${path.normalize(exePath)}', context: 'BackendProcess');
    }
    LoggerService().error('Répertoire courant: $currentDir', context: 'BackendProcess');
    LoggerService().error('Exécutable Flutter: $executableDir', context: 'BackendProcess');
    
    _backendExe = null;
  }
  
  
  /// Démarrer le backend
  Future<bool> start() async {
    if (_isRunning || _isStarting) {
      LoggerService().info('Backend déjà en cours d\'exécution ou démarrage', context: 'BackendProcess');
      return _isRunning;
    }
    
    // Initialiser les chemins
    _initializePaths();
    
    if (_backendExe == null) {
      final currentDir = Directory.current.path;
      final executableDir = path.dirname(Platform.resolvedExecutable);
      _error = 'Exécutable backend introuvable: $_exeName\n'
          'Recherché dans:\n'
          '  - $currentDir/backend/dist/$_exeName\n'
          '  - $currentDir/backend/$_exeName\n'
          '  - $executableDir/$_exeName\n'
          '  - $currentDir/$_exeName\n'
          '\nVérifiez que l\'exécutable existe à l\'un de ces emplacements.';
      LoggerService().error('Exécutable backend introuvable', context: 'BackendProcess', error: _error);
      notifyListeners();
      return false;
    }
    
    // Vérifier que l'exécutable existe (double vérification)
    if (!File(_backendExe!).existsSync()) {
      _error = 'Exécutable backend introuvable: $_backendExe\n'
          'Le fichier a été trouvé mais n\'existe plus.';
      LoggerService().error('Exécutable backend introuvable', context: 'BackendProcess', error: _error);
      notifyListeners();
      return false;
    }
    
    LoggerService().info('✅ Exécutable backend trouvé: $_backendExe', context: 'BackendProcess');
    
    _isStarting = true;
    _error = null;
    notifyListeners();
    
    try {
      LoggerService().info('Démarrage du backend: $_backendExe', context: 'BackendProcess');
      
      // ProcessStartMode.detached lance le processus sans console (furtif)
      // Définir le répertoire de travail sur le répertoire backend/ (pas dist/)
      // car le backend pourrait avoir besoin d'accéder à des fichiers dans backend/
      final exeDir = path.dirname(_backendExe!); // backend/dist/
      final backendDir = path.dirname(exeDir); // backend/
      final workingDirectory = backendDir;
      
      LoggerService().info('Répertoire de travail: $workingDirectory', context: 'BackendProcess');
      
      _process = await Process.start(
        _backendExe!,
        [],
        mode: ProcessStartMode.detached,
        runInShell: false,
        workingDirectory: workingDirectory,
      );
      
      LoggerService().info('Processus backend lancé (PID: ${_process!.pid})', context: 'BackendProcess');
      
      // Essayer d'écouter les logs
      try {
        _process!.stdout.transform(utf8.decoder).listen(
          (data) {
            _addLog('OUT', data);
          },
          onError: (error) {
            // Ignorer silencieusement si stdio n'est pas connecté (mode furtif)
            if (!error.toString().contains('stdio is not connected')) {
              _addLog('ERR', 'Erreur stdout: $error');
            }
          },
        );
      } catch (e) {
        // Mode furtif: stdio n'est pas disponible, c'est normal
        LoggerService().info('Mode furtif: stdio non disponible', context: 'BackendProcess');
      }
      
      try {
        _process!.stderr.transform(utf8.decoder).listen(
          (data) {
            _addLog('ERR', data);
          },
          onError: (error) {
            // Ignorer silencieusement si stdio n'est pas connecté (mode furtif)
            if (!error.toString().contains('stdio is not connected')) {
              _addLog('ERR', 'Erreur stderr: $error');
            }
          },
        );
      } catch (e) {
        // Mode furtif: stdio n'est pas disponible, c'est normal
      }
      
      // Attendre un peu pour que le processus démarre (augmenté à 5 secondes)
      LoggerService().info('Attente du démarrage du processus backend (5 secondes)...', context: 'BackendProcess');
      await Future.delayed(const Duration(seconds: 5));
      
      // Vérifier que le processus est toujours en cours
      // Note: Pour un processus détaché, on ne peut pas vérifier exitCode facilement
      // On va directement vérifier la santé du backend
      LoggerService().info('Processus lancé (PID: ${_process!.pid}), vérification de la santé du backend...', context: 'BackendProcess');
      
      // Vérifier la santé du backend avec plus de tentatives et délai plus long
      // Le backend peut prendre du temps à démarrer, surtout s'il charge des dépendances
      final isHealthy = await _checkHealth(maxRetries: 60, delay: const Duration(milliseconds: 1500));
      
      if (isHealthy) {
        _isRunning = true;
        _isStarting = false;
        LoggerService().info('✅ Backend démarré avec succès et répond aux requêtes', context: 'BackendProcess');
        notifyListeners();
        return true;
      } else {
        // Vérifier si le processus est toujours actif
        bool processStillRunning = false;
        int? processExitCode;
        try {
          processExitCode = await _process!.exitCode.timeout(
            const Duration(milliseconds: 100),
          );
          // Si on obtient un exitCode, le processus s'est terminé
          processStillRunning = false;
          
          // Lire le fichier de log pour voir les erreurs
          final logFile = File(path.join(Directory.current.path, 'backend', 'logs', 'backend.log'));
          String? logContent;
          if (logFile.existsSync()) {
            try {
              logContent = logFile.readAsStringSync();
              final lastLines = logContent.split('\n').where((l) => l.trim().isNotEmpty).take(20).join('\n');
              LoggerService().error('Dernières lignes du log backend:\n$lastLines', context: 'BackendProcess');
            } catch (e) {
              LoggerService().warning('Impossible de lire le fichier de log: $e', context: 'BackendProcess');
            }
          }
          
          _error = 'Le processus backend s\'est terminé (code: $processExitCode). Vérifiez que l\'exécutable fonctionne correctement.';
          LoggerService().error('Backend terminé', context: 'BackendProcess', error: _error);
        } catch (e) {
          // Timeout = processus toujours en cours
          processStillRunning = true;
          
          // Lire le fichier de log pour voir les erreurs potentielles
          final logFile = File(path.join(Directory.current.path, 'backend', 'logs', 'backend.log'));
          if (logFile.existsSync()) {
            try {
              final logContent = logFile.readAsStringSync();
              final lastLines = logContent.split('\n').where((l) => l.trim().isNotEmpty).take(20).join('\n');
              LoggerService().info('Dernières lignes du log backend:\n$lastLines', context: 'BackendProcess');
            } catch (e) {
              // Ignorer
            }
          }
          
          _error = 'Le backend ne répond pas aux vérifications de santé après 30 tentatives (30 secondes). Le processus est toujours actif (PID: ${_process!.pid}). Vérifiez que le port 8000 n\'est pas utilisé.';
          LoggerService().error('Backend ne répond pas (processus actif)', context: 'BackendProcess', error: _error);
          LoggerService().info('Conseil: Vérifiez avec: netstat -ano | findstr :8000', context: 'BackendProcess');
        }
        
        await stop();
        _isStarting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur lors du démarrage: $e';
      LoggerService().error('Erreur démarrage backend', context: 'BackendProcess', error: e);
      _isStarting = false;
      _isRunning = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Arrêter le backend
  Future<void> stop() async {
    if (_process == null) return;
    
    try {
      LoggerService().info('Arrêt du backend (PID: ${_process!.pid})', context: 'BackendProcess');
      
      // Pour un processus détaché, on ne peut pas utiliser exitCode
      // On essaie de tuer le processus directement
      try {
        _process!.kill();
        
        // Attendre un peu pour voir si le processus se termine
        try {
          await _process!.exitCode.timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              // Timeout = processus toujours en cours, c'est normal pour un processus détaché
              return -1;
            },
          );
        } catch (e) {
          // Processus détaché, on ne peut pas attendre exitCode
          if (e.toString().contains('Process is detached')) {
            LoggerService().info('Processus détaché, arrêt demandé', context: 'BackendProcess');
          } else {
            rethrow;
          }
        }
      } catch (e) {
        // Si kill() échoue, le processus est peut-être déjà terminé
        if (!e.toString().contains('Process is detached')) {
          LoggerService().warning('Erreur lors de l\'arrêt: $e', context: 'BackendProcess');
        }
      }
    } catch (e) {
      // Ignorer les erreurs "Process is detached" car c'est normal pour un processus détaché
      if (!e.toString().contains('Process is detached')) {
        LoggerService().error('Erreur lors de l\'arrêt du backend', context: 'BackendProcess', error: e);
      }
    } finally {
      _process = null;
      _isRunning = false;
      _isStarting = false;
      notifyListeners();
    }
  }
  
  /// Vérifier la santé du backend
  Future<bool> checkHealth() async {
    return await _checkHealth(maxRetries: 1, delay: const Duration(milliseconds: 100));
  }

  /// Démarre le health check périodique
  void startPeriodicHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      if (!_isRunning) return;
      
      final isHealthy = await checkHealth();
      if (isHealthy) {
        _lastSuccessfulHealthCheck = DateTime.now();
        _restartAttempts = 0; // Réinitialiser les tentatives après un succès
      } else {
        LoggerService().warning('Backend health check failed', context: 'BackendProcess');
        await _handleUnhealthyBackend();
      }
    });
    LoggerService().info('Health check périodique démarré (intervalle: ${_healthCheckInterval.inSeconds}s)', context: 'BackendProcess');
  }

  /// Arrête le health check périodique
  void stopPeriodicHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Gère un backend non-sain
  Future<void> _handleUnhealthyBackend() async {
    if (_restartAttempts >= _maxRestartAttempts) {
      _error = 'Le backend a échoué à redémarrer après $_maxRestartAttempts tentatives';
      LoggerService().error(_error!, context: 'BackendProcess');
      notifyListeners();
      return;
    }

    _restartAttempts++;
    final backoffDelay = Duration(seconds: _restartAttempts * 2); // Backoff exponentiel simplifié
    
    LoggerService().info('Tentative de redémarrage du backend (attempt $_restartAttempts/$_maxRestartAttempts) après ${backoffDelay.inSeconds}s', context: 'BackendProcess');
    
    await Future.delayed(backoffDelay);
    await restart();
  }

  /// Redémarre le backend
  Future<bool> restart() async {
    LoggerService().info('Redémarrage du backend...', context: 'BackendProcess');
    stopPeriodicHealthCheck();
    await stop();
    await Future.delayed(const Duration(seconds: 1));
    final success = await start();
    if (success) {
      startPeriodicHealthCheck();
    }
    return success;
  }
  
  Future<bool> _checkHealth({required int maxRetries, required Duration delay}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        // Logger seulement toutes les 10 tentatives pour ne pas spammer
        if (i == 0) {
          LoggerService().info('Vérification de santé du backend (tentative ${i + 1}/$maxRetries)...', context: 'BackendProcess');
        } else if (i % 10 == 0) {
          LoggerService().info('Vérification de santé du backend (tentative ${i + 1}/$maxRetries)...', context: 'BackendProcess');
        }
        
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        final request = await client.getUrl(Uri.parse(_healthCheckUrl));
        request.headers.set('Connection', 'close');
        
        final response = await request.close().timeout(
          const Duration(seconds: 5), // Timeout augmenté à 5 secondes
          onTimeout: () {
            client.close(force: true);
            throw TimeoutException('Timeout lors de la vérification de santé');
          },
        );
        
        final statusCode = response.statusCode;
        client.close();
        
        if (statusCode == 200) {
          LoggerService().info('✅ Backend répond correctement (HTTP 200)', context: 'BackendProcess');
          return true;
        } else {
          LoggerService().warning('Backend répond avec un code non-200: $statusCode', context: 'BackendProcess');
        }
      } catch (e) {
        // Logger seulement les erreurs importantes (pas les timeouts normaux pendant le démarrage)
        if (i == maxRetries - 1) {
          LoggerService().warning('Dernière tentative échouée: $e', context: 'BackendProcess');
        } else if (i > 0 && i % 10 == 0) {
          // Logger toutes les 10 tentatives pour suivre la progression
          LoggerService().debug('Tentative ${i + 1}/$maxRetries échouée: ${e.toString().split('\n').first}', context: 'BackendProcess');
        }
        
        if (i < maxRetries - 1) {
          await Future.delayed(delay);
        }
      }
    }
    
    return false;
  }
  
  void _addLog(String type, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$type] $message';
    
    _logs.add(logEntry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    
    // Logger aussi dans le service de logging
    if (type == 'ERR') {
      LoggerService().error('Backend: $message', context: 'BackendProcess');
    } else {
      LoggerService().debug('Backend: $message', context: 'BackendProcess');
    }
    
    notifyListeners();
  }
  
  /// Nettoyer les logs
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    stop();
    super.dispose();
  }
}


