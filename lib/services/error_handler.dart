import 'dart:async';
import 'package:flutter/foundation.dart';

/// Circuit breaker pour gérer les erreurs répétées
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;
  Timer? _resetTimer;
  
  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
  });
  
  /// Exécute une fonction avec circuit breaker
  Future<T> execute<T>(Future<T> Function() fn) async {
    if (_isOpen) {
      if (_lastFailureTime != null && 
          DateTime.now().difference(_lastFailureTime!) > timeout) {
        // Réessayer après le timeout
        _isOpen = false;
        _failureCount = 0;
        debugPrint('🔄 Circuit breaker $name: Tentative de réouverture');
      } else {
        throw CircuitBreakerOpenException('Circuit breaker $name est ouvert');
      }
    }
    
    try {
      final result = await fn();
      // Succès : réinitialiser le compteur
      _failureCount = 0;
      _isOpen = false;
      _resetTimer?.cancel();
      return result;
    } catch (e) {
      _failureCount++;
      _lastFailureTime = DateTime.now();
      
      if (_failureCount >= failureThreshold) {
        _isOpen = true;
        debugPrint('⚠️ Circuit breaker $name: Ouvert après $failureThreshold échecs');
        
        // Programmer la réouverture après le timeout
        _resetTimer?.cancel();
        _resetTimer = Timer(timeout, () {
          _isOpen = false;
          _failureCount = 0;
          debugPrint('✅ Circuit breaker $name: Réouvert après timeout');
        });
      }
      
      rethrow;
    }
  }
  
  void reset() {
    _isOpen = false;
    _failureCount = 0;
    _lastFailureTime = null;
    _resetTimer?.cancel();
  }
  
  void dispose() {
    _resetTimer?.cancel();
  }
}

/// Exception pour circuit breaker ouvert
class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => message;
}

/// Gestionnaire d'erreurs avec retry et backoff exponentiel
class ErrorHandler {
  /// Exécute une fonction avec retry automatique
  static Future<T> withRetry<T>({
    required Future<T> Function() fn,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt < maxRetries) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        
        // Vérifier si on doit réessayer
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }
        
        // Ne pas réessayer si c'était le dernier essai
        if (attempt >= maxRetries) {
          debugPrint('❌ Échec après $maxRetries tentatives: $e');
          rethrow;
        }
        
        // Backoff exponentiel
        debugPrint('🔄 Tentative $attempt/$maxRetries échouée, réessai dans ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 2).clamp(1000, 10000));
      }
    }
    
    throw Exception('Impossible d\'exécuter après $maxRetries tentatives');
  }
  
  /// Retry avec circuit breaker
  static Future<T> withRetryAndCircuitBreaker<T>({
    required Future<T> Function() fn,
    required CircuitBreaker circuitBreaker,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    return await circuitBreaker.execute(() async {
      return await withRetry(
        fn: fn,
        maxRetries: maxRetries,
        initialDelay: initialDelay,
      );
    });
  }
  
  /// Gère les erreurs avec fallback gracieux
  static Future<T> withFallback<T>({
    required Future<T> Function() fn,
    required T fallbackValue,
    String? errorMessage,
  }) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('⚠️ Erreur: ${errorMessage ?? e}, utilisation du fallback');
      return fallbackValue;
    }
  }
  
  /// Logging structuré des erreurs
  static void logError({
    required String context,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('❌ Erreur dans $context:');
    buffer.writeln('   Message: $error');
    
    if (stackTrace != null) {
      buffer.writeln('   StackTrace: $stackTrace');
    }
    
    if (additionalData != null && additionalData.isNotEmpty) {
      buffer.writeln('   Données additionnelles:');
      additionalData.forEach((key, value) {
        buffer.writeln('     $key: $value');
      });
    }
    
    debugPrint(buffer.toString());
  }
}

/// Recovery automatique pour WebViews corrompus
class WebViewRecovery {
  /// Tente de récupérer un WebView corrompu
  static Future<bool> recoverWebView({
    required Future<void> Function() recreateWebView,
    int maxAttempts = 2,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        await recreateWebView();
        debugPrint('✅ WebView récupéré avec succès');
        return true;
      } catch (e) {
        debugPrint('⚠️ Tentative de récupération $i/$maxAttempts échouée: $e');
        if (i < maxAttempts - 1) {
          await Future.delayed(Duration(seconds: i + 1));
        }
      }
    }
    
    debugPrint('❌ Impossible de récupérer le WebView après $maxAttempts tentatives');
    return false;
  }
}

