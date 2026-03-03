/// Service pour gérer le processus backend
library backend_process_service;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../core/services/logger_service.dart';

/// Service pour gérer le processus backend sidecar.
class BackendProcessService extends ChangeNotifier {
  static final BackendProcessService _instance =
      BackendProcessService._internal();
  factory BackendProcessService() => _instance;
  BackendProcessService._internal();

  static const String _exeName = 'notilus-backend.exe';
  static const String _backendExeEnvVar = 'NOTILUS_BACKEND_EXE';
  static const int _defaultPort = 8000;
  static const String _healthCheckUrl = 'http://127.0.0.1:8000/api/health';
  static const int _maxRestartAttempts = 3;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const int _startupHealthRetries = 40;
  static const Duration _startupHealthDelay = Duration(seconds: 1);

  Process? _process;
  bool _isRunning = false;
  bool _isStarting = false;
  bool _isStopping = false;
  String? _error;

  final List<String> _logs = [];
  static const int _maxLogs = 100;

  final List<String> _searchedPaths = [];
  String? _backendExe;

  Timer? _healthCheckTimer;
  int _restartAttempts = 0;
  DateTime? _lastSuccessfulHealthCheck;

  bool get isRunning => _isRunning;
  bool get isStarting => _isStarting;
  String? get error => _error;
  List<String> get logs => List.unmodifiable(_logs);
  DateTime? get lastSuccessfulHealthCheck => _lastSuccessfulHealthCheck;

  /// Diagnostic: resolved executable path (if found).
  String? get resolvedBackendPath => _backendExe;

  /// Diagnostic text for UI copy/debug.
  String get diagnosticSummary {
    return _buildDiagnostic(
      cause: _error ?? 'Aucune erreur backend enregistrée.',
    );
  }

  Future<bool> start({
    int startupRetries = _startupHealthRetries,
    Duration startupDelay = _startupHealthDelay,
  }) async {
    if (_isRunning || _isStarting) {
      LoggerService().info(
        'Backend déjà en cours d\'exécution ou démarrage',
        context: 'BackendProcess',
      );
      return _isRunning;
    }

    _isStarting = true;
    _error = null;
    notifyListeners();

    try {
      // If backend is already healthy on 127.0.0.1:8000, attach and do not relaunch.
      if (await checkHealth()) {
        _attachToRunningBackend('Backend déjà actif sur le port $_defaultPort');
        return true;
      }

      // If port is occupied but health check fails, clear stale backend and retry.
      if (await _isPortInUse(_defaultPort)) {
        LoggerService().warning(
          'Port $_defaultPort occupé sans backend sain, nettoyage des instances stale...',
          context: 'BackendProcess',
        );

        await _killExistingInstances();
        await Future.delayed(const Duration(milliseconds: 500));

        if (await checkHealth()) {
          _attachToRunningBackend(
              'Backend redevenu sain après nettoyage stale');
          return true;
        }

        if (await _isPortInUse(_defaultPort)) {
          _error = _buildDiagnostic(
            cause:
                'Le port $_defaultPort est déjà occupé par un processus non-sain. '
                'Libérez le port puis relancez.',
          );
          LoggerService().error(_error!, context: 'BackendProcess');
          _isStarting = false;
          notifyListeners();
          return false;
        }
      }

      _initializePaths();
      if (_backendExe == null) {
        _error = _buildDiagnostic(
          cause: 'Exécutable backend introuvable: $_exeName',
        );
        LoggerService().error(_error!, context: 'BackendProcess');
        _isStarting = false;
        notifyListeners();
        return false;
      }

      final backendFile = File(_backendExe!);
      if (!backendFile.existsSync()) {
        _error = _buildDiagnostic(
          cause:
              'Exécutable backend trouvé mais introuvable au lancement: $_backendExe',
        );
        LoggerService().error(_error!, context: 'BackendProcess');
        _isStarting = false;
        notifyListeners();
        return false;
      }

      final workingDirectory = _resolveWorkingDirectory(_backendExe!);
      LoggerService().info('Démarrage du backend: $_backendExe',
          context: 'BackendProcess');
      LoggerService().info('Répertoire de travail: $workingDirectory',
          context: 'BackendProcess');

      _process = await Process.start(
        _backendExe!,
        const [],
        mode: ProcessStartMode.normal,
        runInShell: false,
        workingDirectory: workingDirectory,
      );

      LoggerService().info('Processus backend lancé (PID: ${_process!.pid})',
          context: 'BackendProcess');

      _wireProcessOutput(_process!);
      unawaited(_watchProcessExit(_process!));

      final isHealthy = await _checkHealth(
        maxRetries: startupRetries,
        delay: startupDelay,
      );

      if (!isHealthy) {
        final exitCode = await _readExitCodeQuickly(_process!);
        if (exitCode != null) {
          _error = _buildDiagnostic(
            cause:
                'Le backend s\'est arrêté pendant le démarrage (code: $exitCode).',
          );
        } else {
          final totalSeconds =
              (startupRetries * startupDelay.inMilliseconds / 1000)
                  .toStringAsFixed(0);
          _error = _buildDiagnostic(
            cause:
                'Le backend ne répond pas à la santé après $startupRetries tentatives '
                '(${totalSeconds}s).',
          );
        }

        LoggerService().error(_error!, context: 'BackendProcess');
        await stop();
        _isStarting = false;
        notifyListeners();
        return false;
      }

      _isRunning = true;
      _isStarting = false;
      _error = null;
      _restartAttempts = 0;
      _lastSuccessfulHealthCheck = DateTime.now();
      startPeriodicHealthCheck();
      notifyListeners();

      LoggerService()
          .info('✅ Backend démarré avec succès', context: 'BackendProcess');
      return true;
    } catch (e, st) {
      _error = _buildDiagnostic(cause: 'Erreur lors du démarrage backend: $e');
      LoggerService()
          .error(_error!, context: 'BackendProcess', error: e, stackTrace: st);
      await stop();
      _isStarting = false;
      notifyListeners();
      return false;
    }
  }

  /// Lance directement l'exécutable backend sans passer par le flux de relance.
  /// Utilisé comme action manuelle depuis l'UI quand l'auto-start échoue.
  Future<bool> launchExecutableDirectly({
    Duration healthTimeout = const Duration(seconds: 12),
  }) async {
    if (_isRunning) {
      return true;
    }
    if (_isStarting) {
      return false;
    }

    _isStarting = true;
    _error = null;
    notifyListeners();

    try {
      // Si le backend est déjà disponible, s'attacher sans relancer.
      if (await checkHealth()) {
        _attachToRunningBackend('Backend déjà actif avant lancement manuel');
        return true;
      }

      _initializePaths();
      if (_backendExe == null) {
        _error = _buildDiagnostic(
          cause: 'Exécutable backend introuvable: $_exeName',
        );
        _isStarting = false;
        notifyListeners();
        return false;
      }

      final backendFile = File(_backendExe!);
      if (!backendFile.existsSync()) {
        _error = _buildDiagnostic(
          cause:
              'Exécutable backend introuvable au lancement manuel: $_backendExe',
        );
        _isStarting = false;
        notifyListeners();
        return false;
      }

      final workingDirectory = _resolveWorkingDirectory(_backendExe!);
      LoggerService().info('Lancement manuel du backend: $_backendExe',
          context: 'BackendProcess');
      LoggerService().info('Répertoire de travail manuel: $workingDirectory',
          context: 'BackendProcess');

      _process = await Process.start(
        _backendExe!,
        const [],
        mode: ProcessStartMode.normal,
        runInShell: false,
        workingDirectory: workingDirectory,
      );

      _wireProcessOutput(_process!);
      unawaited(_watchProcessExit(_process!));

      final retries =
          healthTimeout.inSeconds <= 0 ? 1 : healthTimeout.inSeconds;
      final isHealthy = await _checkHealth(
        maxRetries: retries,
        delay: const Duration(seconds: 1),
      );

      if (!isHealthy) {
        final exitCode = await _readExitCodeQuickly(_process!);
        if (exitCode != null) {
          _error = _buildDiagnostic(
            cause:
                'Le backend manuel s\'est arrêté pendant le démarrage (code: $exitCode).',
          );
        } else {
          _error = _buildDiagnostic(
            cause:
                'Le backend lancé manuellement ne répond pas après ${healthTimeout.inSeconds}s.',
          );
        }

        await stop();
        _isStarting = false;
        notifyListeners();
        return false;
      }

      _isRunning = true;
      _isStarting = false;
      _error = null;
      _restartAttempts = 0;
      _lastSuccessfulHealthCheck = DateTime.now();
      startPeriodicHealthCheck();
      notifyListeners();
      return true;
    } catch (e, st) {
      _error = _buildDiagnostic(
        cause: 'Échec du lancement manuel backend: $e',
      );
      await stop();
      _isStarting = false;
      LoggerService().error(
        _error!,
        context: 'BackendProcess',
        error: e,
        stackTrace: st,
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    stopPeriodicHealthCheck();

    final process = _process;
    final pid = process?.pid;

    _isStopping = true;

    try {
      if (process != null) {
        LoggerService()
            .info('Arrêt du backend (PID: $pid)', context: 'BackendProcess');

        var stopped = false;
        try {
          stopped = process.kill(ProcessSignal.sigterm);
        } catch (_) {
          stopped = false;
        }

        if (!stopped && Platform.isWindows && pid != null) {
          await _killProcessByPid(pid);
        }

        try {
          await process.exitCode.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          if (Platform.isWindows && pid != null) {
            await _killProcessByPid(pid);
          }
        }
      }
    } catch (e) {
      LoggerService().warning('Erreur lors de l\'arrêt du backend: $e',
          context: 'BackendProcess');
    } finally {
      _process = null;
      _isRunning = false;
      _isStarting = false;
      _isStopping = false;
      notifyListeners();
    }
  }

  Future<bool> restart() async {
    LoggerService()
        .info('Redémarrage du backend...', context: 'BackendProcess');
    stopPeriodicHealthCheck();
    await stop();
    await Future.delayed(const Duration(seconds: 1));
    return start();
  }

  Future<bool> checkHealth() async {
    return _checkHealth(
        maxRetries: 1, delay: const Duration(milliseconds: 100));
  }

  void startPeriodicHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      if (!_isRunning) {
        return;
      }

      final isHealthy = await checkHealth();
      if (isHealthy) {
        _lastSuccessfulHealthCheck = DateTime.now();
        _restartAttempts = 0;
        return;
      }

      LoggerService()
          .warning('Backend health check failed', context: 'BackendProcess');
      await _handleUnhealthyBackend();
    });

    LoggerService().info(
      'Health check périodique démarré (intervalle: ${_healthCheckInterval.inSeconds}s)',
      context: 'BackendProcess',
    );
  }

  void stopPeriodicHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  Future<void> _handleUnhealthyBackend() async {
    if (_restartAttempts >= _maxRestartAttempts) {
      _error =
          'Le backend a échoué à redémarrer après $_maxRestartAttempts tentatives';
      LoggerService().error(_error!, context: 'BackendProcess');
      notifyListeners();
      return;
    }

    _restartAttempts++;
    final backoffDelay = Duration(seconds: _restartAttempts * 2);

    LoggerService().info(
      'Tentative de redémarrage backend ($_restartAttempts/$_maxRestartAttempts) '
      'dans ${backoffDelay.inSeconds}s',
      context: 'BackendProcess',
    );

    await Future.delayed(backoffDelay);
    await restart();
  }

  Future<bool> _checkHealth(
      {required int maxRetries, required Duration delay}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        if (i == 0 || i % 10 == 0) {
          LoggerService().info(
            'Vérification santé backend (${i + 1}/$maxRetries)...',
            context: 'BackendProcess',
          );
        }

        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 3);
        final request = await client.getUrl(Uri.parse(_healthCheckUrl));
        request.headers.set('Connection', 'close');

        final response = await request.close().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            client.close(force: true);
            throw TimeoutException('Health check timeout');
          },
        );

        final statusCode = response.statusCode;
        client.close(force: true);

        if (statusCode == 200) {
          LoggerService().info('✅ Backend répond correctement (HTTP 200)',
              context: 'BackendProcess');
          return true;
        }

        LoggerService().warning(
            'Backend répond avec un code non-200: $statusCode',
            context: 'BackendProcess');
      } catch (e) {
        if (i == maxRetries - 1) {
          LoggerService().warning('Dernière tentative de santé échouée: $e',
              context: 'BackendProcess');
        } else if (i > 0 && i % 10 == 0) {
          LoggerService().debug(
            'Tentative santé ${i + 1}/$maxRetries échouée: ${e.toString().split('\n').first}',
            context: 'BackendProcess',
          );
        }

        if (i < maxRetries - 1) {
          await Future.delayed(delay);
        }
      }
    }

    return false;
  }

  Future<bool> _isPortInUse(int port) async {
    try {
      final socket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await socket.close();
      return false;
    } catch (_) {
      return true;
    }
  }

  void _initializePaths() {
    _backendExe = null;
    _searchedPaths.clear();

    final currentDir = Directory.current.path;
    final executableDir = path.dirname(Platform.resolvedExecutable);
    final parentDir = path.dirname(currentDir);

    final candidates = <String>[];
    final fromEnv = _sanitizeEnvPath(Platform.environment[_backendExeEnvVar]);

    if (fromEnv != null && fromEnv.isNotEmpty) {
      candidates.add(fromEnv);
    }

    // Strict lookup order.
    candidates.add(path.join(executableDir, _exeName));
    candidates.add(path.join(currentDir, 'backend', 'dist', _exeName));
    candidates
        .add(path.join(currentDir, '.bin', 'backend_builds', 'dist', _exeName));
    candidates.add(path.join(parentDir, 'backend', 'dist', _exeName));

    final seen = <String>{};
    for (final rawPath in candidates) {
      final normalizedPath = path.normalize(rawPath);
      if (!seen.add(normalizedPath)) {
        continue;
      }

      _searchedPaths.add(normalizedPath);
      LoggerService().info('Vérification backend: $normalizedPath',
          context: 'BackendProcess');

      if (File(normalizedPath).existsSync()) {
        _backendExe = normalizedPath;
        LoggerService()
            .info('✅ Backend trouvé: $_backendExe', context: 'BackendProcess');
        return;
      }
    }

    LoggerService().warning(
        'Backend introuvable après recherche des chemins connus',
        context: 'BackendProcess');
  }

  String? _sanitizeEnvPath(String? value) {
    if (value == null) {
      return null;
    }

    var normalized = value.trim();
    if (normalized.startsWith('"') &&
        normalized.endsWith('"') &&
        normalized.length >= 2) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
    return normalized;
  }

  String _resolveWorkingDirectory(String backendExePath) {
    final exeDir = path.dirname(backendExePath);
    final normalized =
        path.normalize(backendExePath).replaceAll('\\', '/').toLowerCase();
    const suffix = '/backend/dist/$_exeName';

    if (normalized.endsWith(suffix)) {
      return path.dirname(exeDir);
    }

    return exeDir;
  }

  Future<void> _watchProcessExit(Process process) async {
    final exitCode = await process.exitCode;

    if (!identical(_process, process)) {
      return;
    }

    if (_isStopping) {
      return;
    }

    LoggerService().warning('Processus backend terminé (code: $exitCode)',
        context: 'BackendProcess');
    _process = null;
    _isRunning = false;
    _isStarting = false;
    stopPeriodicHealthCheck();

    _error = _buildDiagnostic(
      cause:
          'Le backend s\'est arrêté de manière inattendue (code: $exitCode).',
    );

    notifyListeners();
  }

  Future<int?> _readExitCodeQuickly(Process process) async {
    try {
      final code =
          await process.exitCode.timeout(const Duration(milliseconds: 150));
      return code;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _killExistingInstances() async {
    if (!Platform.isWindows) {
      return;
    }

    try {
      final result = await Process.run(
        'taskkill',
        ['/F', '/IM', _exeName, '/T'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        LoggerService().info('Instances backend stale arrêtées',
            context: 'BackendProcess');
      } else {
        LoggerService().debug(
          'taskkill stale instances code=${result.exitCode}',
          context: 'BackendProcess',
        );
      }
    } catch (e) {
      LoggerService()
          .debug('Erreur kill stale instances: $e', context: 'BackendProcess');
    }
  }

  Future<void> _killProcessByPid(int pid) async {
    if (!Platform.isWindows) {
      return;
    }

    try {
      await Process.run(
        'taskkill',
        ['/F', '/PID', pid.toString(), '/T'],
        runInShell: true,
      );
    } catch (e) {
      LoggerService()
          .debug('Impossible de tuer PID $pid: $e', context: 'BackendProcess');
    }
  }

  void _wireProcessOutput(Process process) {
    process.stdout.transform(utf8.decoder).listen(
          (data) => _addLog('OUT', data),
          onError: (error) => _addLog('ERR', 'Erreur stdout: $error'),
        );

    process.stderr.transform(utf8.decoder).listen(
          (data) => _addLog('ERR', data),
          onError: (error) => _addLog('ERR', 'Erreur stderr: $error'),
        );
  }

  void _attachToRunningBackend(String reason) {
    _process = null;
    _isRunning = true;
    _isStarting = false;
    _error = null;
    _restartAttempts = 0;
    _lastSuccessfulHealthCheck = DateTime.now();
    startPeriodicHealthCheck();
    notifyListeners();

    LoggerService().info('Backend attaché sans relance: $reason',
        context: 'BackendProcess');
  }

  String _buildDiagnostic({required String cause}) {
    final buffer = StringBuffer();
    buffer.writeln(cause);
    buffer.writeln('Health URL: $_healthCheckUrl');
    buffer.writeln('Port attendu: $_defaultPort');
    buffer.writeln('Backend résolu: ${_backendExe ?? "<non résolu>"}');
    buffer.writeln('Répertoire courant: ${Directory.current.path}');
    buffer.writeln(
        'Répertoire exécutable: ${path.dirname(Platform.resolvedExecutable)}');

    if (_searchedPaths.isNotEmpty) {
      buffer.writeln('Chemins testés:');
      for (final searched in _searchedPaths) {
        buffer.writeln('  - $searched');
      }
    }

    return buffer.toString().trimRight();
  }

  void _addLog(String type, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$type] $message';

    _logs.add(logEntry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    if (type == 'ERR') {
      LoggerService().error('Backend: $message', context: 'BackendProcess');
    } else {
      LoggerService().debug('Backend: $message', context: 'BackendProcess');
    }

    notifyListeners();
  }

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
