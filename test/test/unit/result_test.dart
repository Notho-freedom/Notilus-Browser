import 'package:flutter_test/flutter_test.dart';
import 'package:notilus/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create a Success with value', () {
        final result = Result<int, String>.success(42);
        
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.valueOrNull, equals(42));
        expect(result.errorOrNull, isNull);
      });
      
      test('should return value with valueOrThrow', () {
        final result = Result<String, String>.success('test');
        
        expect(result.valueOrThrow, equals('test'));
      });
      
      test('should map value correctly', () {
        final result = Result<int, String>.success(10);
        final mapped = result.map((v) => v * 2);
        
        expect(mapped.valueOrNull, equals(20));
      });
      
      test('should flatMap correctly', () {
        final result = Result<int, String>.success(10);
        final flatMapped = result.flatMap((v) => Result.success(v.toString()));
        
        expect(flatMapped.valueOrNull, equals('10'));
      });
      
      test('should fold with onSuccess', () {
        final result = Result<int, String>.success(42);
        final folded = result.fold(
          onSuccess: (v) => 'Value: $v',
          onFailure: (e) => 'Error: $e',
        );
        
        expect(folded, equals('Value: 42'));
      });
      
      test('should return value with getOrElse', () {
        final result = Result<int, String>.success(42);
        
        expect(result.getOrElse(0), equals(42));
      });
    });
    
    group('Failure', () {
      test('should create a Failure with error', () {
        final result = Result<int, String>.failure('error');
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.errorOrNull, equals('error'));
      });
      
      test('should throw with valueOrThrow', () {
        final result = Result<int, String>.failure('error');
        
        expect(() => result.valueOrThrow, throwsException);
      });
      
      test('should not map value on failure', () {
        final result = Result<int, String>.failure('error');
        final mapped = result.map((v) => v * 2);
        
        expect(mapped.isFailure, isTrue);
        expect(mapped.errorOrNull, equals('error'));
      });
      
      test('should mapError correctly', () {
        final result = Result<int, String>.failure('error');
        final mapped = result.mapError((e) => 'Mapped: $e');
        
        expect(mapped.errorOrNull, equals('Mapped: error'));
      });
      
      test('should fold with onFailure', () {
        final result = Result<int, String>.failure('error');
        final folded = result.fold(
          onSuccess: (v) => 'Value: $v',
          onFailure: (e) => 'Error: $e',
        );
        
        expect(folded, equals('Error: error'));
      });
      
      test('should return default with getOrElse', () {
        final result = Result<int, String>.failure('error');
        
        expect(result.getOrElse(0), equals(0));
      });
      
      test('should compute default with getOrElseCompute', () {
        final result = Result<int, String>.failure('error');
        
        expect(result.getOrElseCompute((e) => e.length), equals(5));
      });
    });
    
    group('Equality', () {
      test('Success with same value should be equal', () {
        final a = Success<int, String>(42);
        final b = Success<int, String>(42);
        
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
      
      test('Failure with same error should be equal', () {
        final a = Failure<int, String>('error');
        final b = Failure<int, String>('error');
        
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
      
      test('Success and Failure should not be equal', () {
        final success = Success<int, int>(42);
        final failure = Failure<int, int>(42);
        
        expect(success, isNot(equals(failure)));
      });
    });
  });
  
  group('AuthError', () {
    test('should have correct messages', () {
      expect(
        AuthError.backendUnavailable.message,
        contains('backend'),
      );
      expect(
        AuthError.userCancelled.message,
        contains('annulée'),
      );
      expect(
        AuthError.networkError.message,
        contains('réseau'),
      );
    });
  });
  
  group('GitHubOAuthData', () {
    test('should store auth URL and state', () {
      const data = GitHubOAuthData(
        authUrl: 'https://github.com/login/oauth/authorize?...',
        state: 'notilus_123456',
      );
      
      expect(data.authUrl, startsWith('https://github.com'));
      expect(data.state, startsWith('notilus_'));
    });
  });
  
  group('GoogleDeviceFlowData', () {
    test('should store device flow data', () {
      const data = GoogleDeviceFlowData(
        deviceCode: 'device_123',
        userCode: 'ABC-DEF',
        verificationUrl: 'https://www.google.com/device',
        expiresIn: 1800,
        interval: 5,
      );
      
      expect(data.deviceCode, equals('device_123'));
      expect(data.userCode, equals('ABC-DEF'));
      expect(data.expiresIn, equals(1800));
    });
  });
}

