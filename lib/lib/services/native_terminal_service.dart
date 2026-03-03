import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service pour gérer les terminaux natifs avec PuTTY/Plink ou shell système
class NativeTerminalService extends ChangeNotifier {
  static final NativeTerminalService _instance = NativeTerminalService._internal();
  factory NativeTerminalService() => _instance;
  NativeTerminalService._internal();

  final Map<String, NativeTerminalSession> _sessions = {};

  /// Crée une nouvelle session terminal native
  NativeTerminalSession createSession(String sessionId, {
    String? host,
    String? user,
    String? password,
    int? port,
    bool useSSH = false,
  }) {
    if (_sessions.containsKey(sessionId)) {
      return _sessions[sessionId]!;
    }

    final session = NativeTerminalSession(
      sessionId: sessionId,
      host: host,
      user: user,
      password: password,
      port: port ?? 22,
      useSSH: useSSH,
    );

    _sessions[sessionId] = session;
    // Utiliser Future.microtask pour éviter notifyListeners pendant le build
    Future.microtask(() {
      notifyListeners();
    });
    return session;
  }

  /// Obtient une session existante
  NativeTerminalSession? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// Supprime une session
  Future<void> removeSession(String sessionId) async {
    final session = _sessions.remove(sessionId);
    if (session != null) {
      await session.close();
      notifyListeners();
    }
  }

  /// Ferme toutes les sessions
  Future<void> closeAll() async {
    final futures = _sessions.values.map((s) => s.close());
    await Future.wait(futures);
    _sessions.clear();
    notifyListeners();
  }
}

/// Session de terminal native (PuTTY/Plink ou shell local)
class NativeTerminalSession {
  final String sessionId;
  final String? host;
  final String? user;
  final String? password;
  final int port;
  final bool useSSH;

  Process? _process;
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final StreamController<String> _inputController = StreamController<String>.broadcast();

  bool _isInitialized = false;
  bool _isConnecting = false;

  NativeTerminalSession({
    required this.sessionId,
    this.host,
    this.user,
    this.password,
    this.port = 22,
    this.useSSH = false,
  });

  Stream<String> get output => _outputController.stream;
  Stream<String> get input => _inputController.stream;
  bool get isInitialized => _isInitialized;
  bool get isConnecting => _isConnecting;

  /// Initialise la session terminal
  Future<void> initialize() async {
    if (_isInitialized || _isConnecting) return;

    _isConnecting = true;

    try {
      if (useSSH && host != null) {
        // Utiliser PuTTY/Plink pour SSH
        await _initializeSSH();
      } else {
        // Utiliser le shell local
        await _initializeLocalShell();
      }

      _isInitialized = true;
      _isConnecting = false;
      debugPrint('✅ Native terminal session initialized: $sessionId');
    } catch (e) {
      _isConnecting = false;
      debugPrint('❌ Native terminal initialization error: $e');
      _outputController.addError(e);
    }
  }

  /// Initialise une connexion SSH via PuTTY/Plink
  Future<void> _initializeSSH() async {
    // Chercher plink.exe dans les chemins communs
    String plinkPath = _findPlinkPath();
    
    if (plinkPath.isEmpty) {
      throw Exception('Plink.exe non trouvé. Veuillez installer PuTTY.');
    }

    final List<String> args = [
      '-ssh',
      if (user != null) '$user@$host' else host!,
      '-P', port.toString(),
      if (password != null) '-pw', if (password != null) password!,
      '-batch', // Mode non-interactif pour automation
    ];

    _process = await Process.start(
      plinkPath,
      args,
      mode: ProcessStartMode.normal,
      runInShell: false,
    );

    _setupStreams();
  }

  /// Initialise un shell local
  Future<void> _initializeLocalShell() async {
    String shellCommand;
    List<String> shellArgs;

    if (Platform.isWindows) {
      shellCommand = 'powershell.exe';
      // -NoExit : garde la fenêtre ouverte
      // -Command - : prend stdin comme source de commandes
      shellArgs = ['-NoExit', '-Command', '-'];
    } else if (Platform.isMacOS) {
      shellCommand = '/bin/zsh';
      shellArgs = [];
    } else if (Platform.isLinux) {
      shellCommand = '/bin/bash';
      shellArgs = [];
    } else {
      throw UnsupportedError('Plateforme non supportée');
    }

    _process = await Process.start(
      shellCommand,
      shellArgs,
      mode: ProcessStartMode.normal,
      runInShell: Platform.isWindows, // runInShell nécessaire pour Windows
    );

    _setupStreams();
  }

  /// Configure les streams stdout/stderr
  void _setupStreams() {
    // Écouter stdout
    _stdoutSubscription = _process!.stdout.listen(
      (data) {
        final output = String.fromCharCodes(data);
        _outputController.add(output);
      },
      onError: (error) {
        debugPrint('❌ Terminal stdout error: $error');
        _outputController.addError(error);
      },
      onDone: () {
        debugPrint('✅ Terminal stdout closed');
      },
    );

    // Écouter stderr
    _stderrSubscription = _process!.stderr.listen(
      (data) {
        final output = String.fromCharCodes(data);
        _outputController.add(output);
      },
      onError: (error) {
        debugPrint('❌ Terminal stderr error: $error');
        _outputController.addError(error);
      },
      onDone: () {
        debugPrint('✅ Terminal stderr closed');
      },
    );

    // Écouter la fin du processus
    _process!.exitCode.then((code) {
      debugPrint('✅ Terminal process exited with code: $code');
      _isInitialized = false;
    });
  }

  /// Trouve le chemin de plink.exe
  String _findPlinkPath() {
    // Chemins communs pour PuTTY sur Windows
    final commonPaths = [
      r'C:\Program Files\PuTTY\plink.exe',
      r'C:\Program Files (x86)\PuTTY\plink.exe',
      r'C:\Windows\System32\plink.exe',
      'plink.exe', // Si dans PATH
    ];

    for (final path in commonPaths) {
      final file = File(path);
      if (file.existsSync()) {
        return path;
      }
    }

    // Essayer de trouver via PATH
    try {
      final result = Process.runSync('where', ['plink.exe']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim().split('\n').first;
      }
    } catch (_) {}

    return '';
  }

  /// Écrit des données dans le terminal
  Future<void> write(String data) async {
    if (!_isInitialized || _process == null) {
      debugPrint('⚠️ Terminal not initialized, cannot write');
      return;
    }

    try {
      _process!.stdin.add(data.codeUnits);
      await _process!.stdin.flush();
      _inputController.add(data);
    } catch (e) {
      debugPrint('❌ Terminal write error: $e');
    }
  }

  /// Écrit une ligne (avec \r\n pour Windows, \n pour Unix)
  Future<void> writeLine(String line) async {
    final lineEnding = Platform.isWindows ? '\r\n' : '\n';
    await write('$line$lineEnding');
  }

  /// Ferme la session
  Future<void> close() async {
    try {
      await _stdoutSubscription?.cancel();
      await _stderrSubscription?.cancel();
      _process?.kill();
      await _process?.exitCode;
      _process = null;
      _isInitialized = false;
      await _outputController.close();
      await _inputController.close();
      debugPrint('✅ Native terminal session closed: $sessionId');
    } catch (e) {
      debugPrint('❌ Terminal close error: $e');
    }
  }
}

