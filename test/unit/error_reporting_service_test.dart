import 'package:flutter_test/flutter_test.dart';
import 'package:notilus/core/services/error_reporting_service.dart';

void main() {
  group('ErrorReportingService', () {
    late ErrorReportingService service;
    
    setUp(() {
      service = ErrorReportingService();
      service.clearHistory();
    });
    
    group('reportError', () {
      test('should add error to history', () {
        service.reportError(
          'Test error',
          category: ErrorCategory.unknown,
        );
        
        expect(service.errorHistory.length, equals(1));
        expect(service.errorHistory.first.message, equals('Test error'));
      });
      
      test('should extract message from Exception', () {
        service.reportError(
          Exception('Exception message'),
          category: ErrorCategory.unknown,
        );
        
        expect(service.errorHistory.first.message, equals('Exception message'));
      });
      
      test('should set correct category', () {
        service.reportError(
          'Network error',
          category: ErrorCategory.network,
        );
        
        expect(service.errorHistory.first.category, equals(ErrorCategory.network));
      });
      
      test('should set correct severity', () {
        service.reportError(
          'Critical error',
          category: ErrorCategory.unknown,
          severity: ErrorSeverity.critical,
        );
        
        expect(service.errorHistory.first.severity, equals(ErrorSeverity.critical));
      });
      
      test('should include context and metadata', () {
        service.reportError(
          'Error with context',
          category: ErrorCategory.storage,
          context: 'TestContext',
          metadata: {'key': 'value'},
        );
        
        final error = service.errorHistory.first;
        expect(error.context, equals('TestContext'));
        expect(error.metadata?['key'], equals('value'));
      });
      
      test('should notify listeners', () {
        AppError? receivedError;
        service.addErrorListener((error) {
          receivedError = error;
        });
        
        service.reportError('Listener test');
        
        expect(receivedError, isNotNull);
        expect(receivedError!.message, equals('Listener test'));
      });
      
      test('should limit history size', () {
        // Ajouter plus que la limite
        for (int i = 0; i < 150; i++) {
          service.reportError('Error $i');
        }
        
        expect(service.errorHistory.length, lessThanOrEqualTo(100));
      });
    });
    
    group('Specialized report methods', () {
      test('reportNetworkError should set network category', () {
        service.reportNetworkError(
          'Network failed',
          url: 'https://api.example.com',
          statusCode: 500,
        );
        
        final error = service.errorHistory.first;
        expect(error.category, equals(ErrorCategory.network));
        expect(error.metadata?['url'], equals('https://api.example.com'));
        expect(error.metadata?['statusCode'], equals(500));
      });
      
      test('reportAuthError should set authentication category', () {
        service.reportAuthError(
          'Auth failed',
          provider: 'github',
        );
        
        final error = service.errorHistory.first;
        expect(error.category, equals(ErrorCategory.authentication));
        expect(error.metadata?['provider'], equals('github'));
      });
      
      test('reportWebViewError should set webview category', () {
        service.reportWebViewError(
          'WebView error',
          url: 'https://example.com',
          tabId: 'tab_123',
        );
        
        final error = service.errorHistory.first;
        expect(error.category, equals(ErrorCategory.webview));
        expect(error.metadata?['tabId'], equals('tab_123'));
      });
      
      test('reportStorageError should set storage category', () {
        service.reportStorageError(
          'Storage error',
          operation: 'write',
          key: 'user_data',
        );
        
        final error = service.errorHistory.first;
        expect(error.category, equals(ErrorCategory.storage));
        expect(error.metadata?['operation'], equals('write'));
      });
    });
    
    group('getErrorsByCategory', () {
      test('should filter errors by category', () {
        service.reportError('Error 1', category: ErrorCategory.network);
        service.reportError('Error 2', category: ErrorCategory.storage);
        service.reportError('Error 3', category: ErrorCategory.network);
        
        final networkErrors = service.getErrorsByCategory(ErrorCategory.network);
        
        expect(networkErrors.length, equals(2));
        expect(networkErrors.every((e) => e.category == ErrorCategory.network), isTrue);
      });
    });
    
    group('getErrorsBySeverity', () {
      test('should filter errors by severity', () {
        service.reportError('Info', severity: ErrorSeverity.info);
        service.reportError('Error', severity: ErrorSeverity.error);
        service.reportError('Critical', severity: ErrorSeverity.critical);
        
        final criticalErrors = service.getErrorsBySeverity(ErrorSeverity.critical);
        
        expect(criticalErrors.length, equals(1));
        expect(criticalErrors.first.message, equals('Critical'));
      });
    });
    
    group('runGuarded', () {
      test('should return value on success', () async {
        final result = await service.runGuarded<int>(
          () async => 42,
          category: ErrorCategory.service,
        );
        
        expect(result, equals(42));
        expect(service.errorHistory, isEmpty);
      });
      
      test('should return default value on error', () async {
        final result = await service.runGuarded<int>(
          () async => throw Exception('Test error'),
          category: ErrorCategory.service,
          defaultValue: -1,
        );
        
        expect(result, equals(-1));
        expect(service.errorHistory.length, equals(1));
      });
      
      test('should report error with context', () async {
        await service.runGuarded<void>(
          () async => throw Exception('Test'),
          context: 'Test context',
        );
        
        expect(service.errorHistory.first.context, equals('Test context'));
      });
    });
    
    group('runGuardedSync', () {
      test('should return value on success', () {
        final result = service.runGuardedSync<int>(
          () => 42,
        );
        
        expect(result, equals(42));
      });
      
      test('should return default value on error', () {
        final result = service.runGuardedSync<int>(
          () => throw Exception('Test'),
          defaultValue: -1,
        );
        
        expect(result, equals(-1));
        expect(service.errorHistory.length, equals(1));
      });
    });
    
    group('clearHistory', () {
      test('should clear all errors', () {
        service.reportError('Error 1');
        service.reportError('Error 2');
        
        expect(service.errorHistory.length, equals(2));
        
        service.clearHistory();
        
        expect(service.errorHistory, isEmpty);
      });
    });
    
    group('Listener management', () {
      test('should remove listener', () {
        int callCount = 0;
        void listener(AppError _) {
          callCount++;
        }
        
        service.addErrorListener(listener);
        service.reportError('Error 1');
        
        expect(callCount, equals(1));
        
        service.removeErrorListener(listener);
        service.reportError('Error 2');
        
        expect(callCount, equals(1)); // Still 1, listener not called
      });
    });
  });
  
  group('AppError', () {
    test('toJson should contain all fields', () {
      final error = AppError(
        message: 'Test error',
        category: ErrorCategory.network,
        severity: ErrorSeverity.error,
        context: 'TestContext',
        metadata: {'key': 'value'},
        originalError: Exception('Original'),
      );
      
      final json = error.toJson();
      
      expect(json['message'], equals('Test error'));
      expect(json['category'], equals('network'));
      expect(json['severity'], equals('error'));
      expect(json['context'], equals('TestContext'));
      expect(json['metadata'], equals({'key': 'value'}));
      expect(json['originalError'], contains('Original'));
      expect(json['timestamp'], isNotNull);
    });
    
    test('toString should be readable', () {
      final error = AppError(
        message: 'Test error',
        category: ErrorCategory.network,
        context: 'TestContext',
      );
      
      final str = error.toString();
      
      expect(str, contains('Test error'));
      expect(str, contains('TestContext'));
    });
  });
}

