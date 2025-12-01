import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Niveaux de log
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Service de logging unifié pour Notilus
/// Remplace tous les debugPrint par un système de logging structuré
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _enableFileLogging = false;
  File? _logFile;
  IOSink? _logSink;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// Initialise le service de logging
  Future<void> initialize({bool enableFileLogging = false}) async {
    _enableFileLogging = enableFileLogging;
    
    if (_enableFileLogging) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final logDirectory = Directory('${directory.path}/logs');
        if (!await logDirectory.exists()) {
          await logDirectory.create(recursive: true);
        }
        
        final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _logFile = File('${logDirectory.path}/notilus_$timestamp.log');
        _logSink = _logFile!.openWrite(mode: FileMode.append);
      } catch (e) {
        debugPrint('⚠️ Impossible d\'initialiser le logging fichier: $e');
        _enableFileLogging = false;
      }
    }
  }

  /// Définit le niveau minimum de log
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log un message de debug
  void debug(String message, {String? context, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, context: context, data: data);
  }

  /// Log un message d'information
  void info(String message, {String? context, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, context: context, data: data);
  }

  /// Log un avertissement
  void warning(String message, {String? context, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, context: context, data: data);
  }

  /// Log une erreur
  void error(String message, {String? context, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.error, message, context: context, error: error, stackTrace: stackTrace, data: data);
  }

  /// Méthode interne de logging
  void _log(
    LogLevel level,
    String message, {
    String? context,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Vérifier le niveau minimum
    if (level.index < _minLevel.index) {
      return;
    }

    final timestamp = _dateFormat.format(DateTime.now());
    final levelStr = level.name.toUpperCase().padRight(7);
    final contextStr = context != null ? '[$context] ' : '';
    final emoji = _getEmoji(level);
    
    // Construire le message
    final buffer = StringBuffer();
    buffer.write('$emoji $timestamp $levelStr $contextStr$message');
    
    if (error != null) {
      buffer.write('\n   Erreur: $error');
    }
    
    if (stackTrace != null) {
      buffer.write('\n   StackTrace: $stackTrace');
    }
    
    if (data != null && data.isNotEmpty) {
      buffer.write('\n   Données:');
      data.forEach((key, value) {
        buffer.write('\n     $key: $value');
      });
    }

    final logMessage = buffer.toString();

    // Afficher dans la console
    debugPrint(logMessage);

    // Écrire dans le fichier si activé
    if (_enableFileLogging && _logSink != null) {
      try {
        _logSink!.writeln(logMessage);
        _logSink!.flush();
      } catch (e) {
        // Ignorer les erreurs d'écriture fichier
      }
    }
  }

  /// Retourne l'emoji correspondant au niveau
  String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// Ferme le service de logging
  Future<void> dispose() async {
    await _logSink?.flush();
    await _logSink?.close();
    _logSink = null;
    _logFile = null;
  }

  /// Obtient le chemin du fichier de log actuel
  String? getLogFilePath() => _logFile?.path;
}

/// Extension pour faciliter l'utilisation
extension LoggerExtension on Object {
  LoggerService get logger => LoggerService();
}

