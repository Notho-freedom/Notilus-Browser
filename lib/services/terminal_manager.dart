import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Session de terminal pour un onglet
class TerminalSession {
  final String tabId;
  Process? _process;
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final StreamController<String> _inputController = StreamController<String>.broadcast();
  
  bool _isInitialized = false;
  String? _shellCommand;
  List<String>? _shellArgs;

  TerminalSession(this.tabId);

  Stream<String> get output => _outputController.stream;
  Stream<String> get input => _inputController.stream;

  bool get isInitialized => _isInitialized;
  bool get isRunning => _process != null;

  /// Initialise le terminal avec un shell
  Future<void> initialize({
    String? shell,
    List<String>? args,
  }) async {
    if (_isInitialized) return;

    try {
      // Détecter le shell par défaut selon la plateforme
      if (shell == null) {
        if (Platform.isWindows) {
          _shellCommand = 'powershell.exe';
          // -NoExit : garde la fenêtre ouverte
          // -Command - : prend stdin comme source de commandes
          _shellArgs = ['-NoExit', '-Command', '-'];
        } else if (Platform.isMacOS) {
          _shellCommand = '/bin/zsh';
          _shellArgs = [];
        } else if (Platform.isLinux) {
          _shellCommand = '/bin/bash';
          _shellArgs = [];
        } else {
          throw UnsupportedError('Plateforme non supportée');
        }
      } else {
        _shellCommand = shell;
        _shellArgs = args;
      }

      // Lancer le processus shell
      _process = await Process.start(
        _shellCommand!,
        _shellArgs ?? [],
        mode: ProcessStartMode.normal,
        runInShell: Platform.isWindows, // runInShell nécessaire pour Windows
      );

      // Écouter la sortie stdout
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

      // Écouter la sortie stderr
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

      _isInitialized = true;
      debugPrint('✅ Terminal session initialized for tab: $tabId');
    } catch (e) {
      debugPrint('❌ Terminal initialization error: $e');
      _outputController.addError(e);
      _isInitialized = false;
    }
  }

  /// Envoie une commande au terminal
  Future<void> write(String data) async {
    if (!_isInitialized || _process == null) {
      debugPrint('⚠️ Terminal not initialized, cannot write');
      return;
    }

    try {
      // Écrire les données dans stdin du processus
      _process!.stdin.add(data.codeUnits);
      await _process!.stdin.flush();
      _inputController.add(data);
      debugPrint('✅ Terminal write: ${data.length} bytes');
    } catch (e) {
      debugPrint('❌ Terminal write error: $e');
    }
  }

  /// Envoie une ligne de commande (avec \n)
  Future<void> writeLine(String line) async {
    await write('$line\n');
  }

  /// Redimensionne le terminal (pour l'instant non supporté par Process)
  void resize(int columns, int rows) {
    // Note: Process.start ne supporte pas directement le redimensionnement
    // Il faudrait utiliser un PTY pour cela
    debugPrint('⚠️ Terminal resize not yet supported');
  }

  /// Ferme le terminal
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
      debugPrint('✅ Terminal session closed for tab: $tabId');
    } catch (e) {
      debugPrint('❌ Terminal close error: $e');
    }
  }
}

/// Gestionnaire des sessions terminal (comme TabWebViewManager)
class TerminalManager extends ChangeNotifier {
  final Map<String, TerminalSession> _sessions = {};

  /// Obtient ou crée une session terminal pour un onglet
  TerminalSession getSessionForTab(String tabId, {String? shell, List<String>? args}) {
    if (_sessions.containsKey(tabId)) {
      return _sessions[tabId]!;
    }

    final session = TerminalSession(tabId);
    _sessions[tabId] = session;
    
    // Initialiser automatiquement
    session.initialize(shell: shell, args: args);
    
    notifyListeners();
    return session;
  }

  /// Obtient une session existante
  TerminalSession? getSession(String tabId) {
    return _sessions[tabId];
  }

  /// Supprime une session terminal
  Future<void> removeSession(String tabId) async {
    final session = _sessions.remove(tabId);
    if (session != null) {
      await session.close();
      notifyListeners();
    }
  }

  /// Ferme toutes les sessions
  Future<void> closeAll() async {
    final futures = _sessions.values.map((session) => session.close());
    await Future.wait(futures);
    _sessions.clear();
    notifyListeners();
  }

  /// Vérifie si une session existe
  bool hasSession(String tabId) {
    return _sessions.containsKey(tabId);
  }
}

