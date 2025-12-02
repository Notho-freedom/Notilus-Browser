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
  static const String _exeName = 'notilus_backend.exe';
  static const String _defaultPort = '8000';
  static const String _healthCheckUrl = 'http://localhost:8000/api/health';
  
  // Getters
  bool get isRunning => _isRunning;
  bool get isStarting => _isStarting;
  String? get error => _error;
  List<String> get logs => List.unmodifiable(_logs);
  
  String? _backendExe;
  
  /// Initialiser le chemin de l'exécutable backend
  void _initializePaths() {
    if (kDebugMode) {
      // En debug, chercher d'abord dans backend/dist/
      final backendDir = path.join(Directory.current.path, 'backend');
      final exePath = path.join(backendDir, 'dist', _exeName);
      if (File(exePath).existsSync()) {
        _backendExe = exePath;
        return;
      }
    }
    
    // Chercher à côté de l'exe Flutter (production ou fallback debug)
    final appDir = path.dirname(Platform.resolvedExecutable);
    final exePath = path.join(appDir, _exeName);
    if (File(exePath).existsSync()) {
      _backendExe = exePath;
      return;
    }
    
    // Exécutable non trouvé
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
      _error = 'Exécutable backend introuvable: $_exeName';
      LoggerService().error('Exécutable backend introuvable', context: 'BackendProcess', error: _error);
      notifyListeners();
      return false;
    }
    
    // Vérifier que l'exécutable existe
    if (!File(_backendExe!).existsSync()) {
      _error = 'Exécutable backend introuvable: $_backendExe';
      LoggerService().error('Exécutable backend introuvable', context: 'BackendProcess', error: _error);
      notifyListeners();
      return false;
    }
    
    _isStarting = true;
    _error = null;
    notifyListeners();
    
    try {
      LoggerService().info('Démarrage du backend: $_backendExe', context: 'BackendProcess');
      
      // ProcessStartMode.detached lance le processus sans console (furtif)
      // Définir le répertoire de travail à côté de l'exe
      final workingDirectory = path.dirname(_backendExe!);
      
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
      
      // Attendre un peu pour que le processus démarre
      LoggerService().info('Attente du démarrage du processus backend...', context: 'BackendProcess');
      await Future.delayed(const Duration(seconds: 2));
      
      // Vérifier que le processus est toujours en cours
      int? exitCode;
      try {
        exitCode = await _process!.exitCode.timeout(
          const Duration(milliseconds: 100),
        );
      } catch (e) {
        // Timeout = le processus est toujours en cours (c'est bon)
        exitCode = null;
      }
      
      if (exitCode != null) {
        _error = 'Le processus backend s\'est terminé immédiatement (code: $exitCode). Vérifiez que l\'exécutable fonctionne correctement.';
        LoggerService().error('Backend terminé immédiatement', context: 'BackendProcess', error: _error);
        _isStarting = false;
        _isRunning = false;
        notifyListeners();
        return false;
      }
      
      LoggerService().info('Processus actif (PID: ${_process!.pid}), vérification de la santé du backend...', context: 'BackendProcess');
      
      // Vérifier la santé du backend avec retry progressif (plus de tentatives et délai plus long)
      final isHealthy = await _checkHealth(maxRetries: 30, delay: const Duration(milliseconds: 1000));
      
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
  
  Future<bool> _checkHealth({required int maxRetries, required Duration delay}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        // Logger seulement toutes les 5 tentatives pour ne pas spammer
        if (i == 0) {
          LoggerService().info('Vérification de santé du backend (tentative ${i + 1}/$maxRetries)...', context: 'BackendProcess');
        } else if (i % 5 == 0) {
          LoggerService().info('Vérification de santé du backend (tentative ${i + 1}/$maxRetries)...', context: 'BackendProcess');
        }
        
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(_healthCheckUrl));
        request.headers.set('Connection', 'close');
        
        final response = await request.close().timeout(
          const Duration(seconds: 3), // Timeout plus long
          onTimeout: () {
            throw TimeoutException('Timeout lors de la vérification de santé');
          },
        );
        
        client.close();
        
        if (response.statusCode == 200) {
          LoggerService().info('✅ Backend répond correctement (HTTP 200)', context: 'BackendProcess');
          return true;
        } else {
          LoggerService().warning('Backend répond avec un code non-200: ${response.statusCode}', context: 'BackendProcess');
        }
      } catch (e) {
        // Logger seulement les erreurs importantes (pas les timeouts normaux)
        if (i == maxRetries - 1) {
          LoggerService().warning('Dernière tentative échouée: $e', context: 'BackendProcess');
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


