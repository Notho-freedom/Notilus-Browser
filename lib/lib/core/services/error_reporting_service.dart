import 'dart:async';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

/// Types d'erreurs pour la catégorisation
enum ErrorCategory {
  /// Erreurs réseau (API, connexion)
  network,
  /// Erreurs d'authentification
  authentication,
  /// Erreurs de stockage (lecture/écriture fichiers, preferences)
  storage,
  /// Erreurs WebView (chargement, JavaScript)
  webview,
  /// Erreurs UI (widgets, navigation)
  ui,
  /// Erreurs de service (logique métier)
  service,
  /// Erreurs inconnues
  unknown,
}

/// Niveau de sévérité d'une erreur
enum ErrorSeverity {
  /// Information (pour logging uniquement)
  info,
  /// Avertissement (fonctionnalité dégradée)
  warning,
  /// Erreur (fonctionnalité cassée)
  error,
  /// Critique (application instable)
  critical,
}

/// Modèle d'erreur centralisé
class AppError {
  final String message;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final String? context;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  
  AppError({
    required this.message,
    required this.category,
    this.severity = ErrorSeverity.error,
    this.originalError,
    this.stackTrace,
    this.context,
    this.metadata,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[$severity] $message');
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    if (originalError != null) {
      buffer.writeln('Original: $originalError');
    }
    return buffer.toString();
  }
  
  Map<String, dynamic> toJson() => {
    'message': message,
    'category': category.name,
    'severity': severity.name,
    'context': context,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    if (originalError != null) 'originalError': originalError.toString(),
  };
}

/// Service centralisé de gestion des erreurs
class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();
  
  final LoggerService _logger = LoggerService();
  
  /// Historique des erreurs récentes (limité à 100)
  final List<AppError> _errorHistory = [];
  static const int _maxHistorySize = 100;
  
  /// Callbacks pour les listeners d'erreurs
  final List<void Function(AppError)> _errorListeners = [];
  
  /// Callback pour afficher une notification à l'utilisateur
  void Function(AppError error)? onUserNotification;
  
  /// Enregistre et traite une erreur
  void reportError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorCategory category = ErrorCategory.unknown,
    ErrorSeverity severity = ErrorSeverity.error,
    String? context,
    Map<String, dynamic>? metadata,
    bool notifyUser = false,
  }) {
    final appError = AppError(
      message: _extractMessage(error),
      category: category,
      severity: severity,
      originalError: error,
      stackTrace: stackTrace,
      context: context,
      metadata: metadata,
    );
    
    // Ajouter à l'historique
    _addToHistory(appError);
    
    // Logger l'erreur
    _logError(appError);
    
    // Notifier les listeners
    for (final listener in _errorListeners) {
      try {
        listener(appError);
      } catch (e) {
        debugPrint('Erreur dans le listener d\'erreurs: $e');
      }
    }
    
    // Notifier l'utilisateur si demandé
    if (notifyUser && onUserNotification != null) {
      onUserNotification!(appError);
    }
  }
  
  /// Enregistre une erreur réseau
  void reportNetworkError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? url,
    int? statusCode,
  }) {
    reportError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.network,
      severity: statusCode != null && statusCode >= 500 
          ? ErrorSeverity.error 
          : ErrorSeverity.warning,
      context: context,
      metadata: {
        if (url != null) 'url': url,
        if (statusCode != null) 'statusCode': statusCode,
      },
      notifyUser: true,
    );
  }
  
  /// Enregistre une erreur d'authentification
  void reportAuthError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? provider,
  }) {
    reportError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.authentication,
      severity: ErrorSeverity.warning,
      context: context,
      metadata: {
        if (provider != null) 'provider': provider,
      },
      notifyUser: true,
    );
  }
  
  /// Enregistre une erreur WebView
  void reportWebViewError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? url,
    String? tabId,
  }) {
    reportError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.webview,
      severity: ErrorSeverity.warning,
      context: context,
      metadata: {
        if (url != null) 'url': url,
        if (tabId != null) 'tabId': tabId,
      },
    );
  }
  
  /// Enregistre une erreur de stockage
  void reportStorageError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? operation,
    String? key,
  }) {
    reportError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.storage,
      severity: ErrorSeverity.error,
      context: context,
      metadata: {
        if (operation != null) 'operation': operation,
        if (key != null) 'key': key,
      },
    );
  }
  
  /// Ajoute un listener pour les erreurs
  void addErrorListener(void Function(AppError) listener) {
    _errorListeners.add(listener);
  }
  
  /// Retire un listener
  void removeErrorListener(void Function(AppError) listener) {
    _errorListeners.remove(listener);
  }
  
  /// Récupère l'historique des erreurs
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);
  
  /// Récupère les erreurs par catégorie
  List<AppError> getErrorsByCategory(ErrorCategory category) {
    return _errorHistory.where((e) => e.category == category).toList();
  }
  
  /// Récupère les erreurs par sévérité
  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorHistory.where((e) => e.severity == severity).toList();
  }
  
  /// Efface l'historique des erreurs
  void clearHistory() {
    _errorHistory.clear();
  }
  
  /// Exécute une fonction avec gestion d'erreur automatique
  Future<T?> runGuarded<T>(
    Future<T> Function() fn, {
    ErrorCategory category = ErrorCategory.unknown,
    String? context,
    T? defaultValue,
    bool notifyUser = false,
  }) async {
    try {
      return await fn();
    } catch (e, stackTrace) {
      reportError(
        e,
        stackTrace: stackTrace,
        category: category,
        context: context,
        notifyUser: notifyUser,
      );
      return defaultValue;
    }
  }
  
  /// Version synchrone de runGuarded
  T? runGuardedSync<T>(
    T Function() fn, {
    ErrorCategory category = ErrorCategory.unknown,
    String? context,
    T? defaultValue,
    bool notifyUser = false,
  }) {
    try {
      return fn();
    } catch (e, stackTrace) {
      reportError(
        e,
        stackTrace: stackTrace,
        category: category,
        context: context,
        notifyUser: notifyUser,
      );
      return defaultValue;
    }
  }
  
  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    
    // Limiter la taille de l'historique
    while (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }
  }
  
  void _logError(AppError error) {
    final logMessage = '[${error.category.name}] ${error.message}';
    
    switch (error.severity) {
      case ErrorSeverity.info:
        _logger.info(logMessage, context: error.context);
        break;
      case ErrorSeverity.warning:
        _logger.warning(logMessage, context: error.context);
        break;
      case ErrorSeverity.error:
        _logger.error(logMessage, context: error.context, error: error.originalError);
        break;
      case ErrorSeverity.critical:
        _logger.error('CRITICAL: $logMessage', context: error.context, error: error.originalError);
        break;
    }
  }
  
  String _extractMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) {
      final str = error.toString();
      // Nettoyer le préfixe "Exception: " si présent
      if (str.startsWith('Exception: ')) {
        return str.substring(11);
      }
      return str;
    }
    if (error is Error) {
      return error.toString();
    }
    return error?.toString() ?? 'Erreur inconnue';
  }
}

/// Extension pour faciliter la gestion des erreurs dans les Futures
extension ErrorHandlingExtension<T> on Future<T> {
  /// Gère les erreurs automatiquement
  Future<T?> handleError({
    ErrorCategory category = ErrorCategory.unknown,
    String? context,
    T? defaultValue,
    bool notifyUser = false,
  }) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      ErrorReportingService().reportError(
        e,
        stackTrace: stackTrace,
        category: category,
        context: context,
        notifyUser: notifyUser,
      );
      return defaultValue;
    }
  }
}

