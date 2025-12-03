import 'package:flutter_test/flutter_test.dart';
import 'package:notilus/core/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService service;
    
    setUp(() {
      service = SecureStorageService();
    });
    
    group('Utility methods', () {
      test('hashString should produce consistent SHA-256 hash', () {
        const input = 'test_string';
        final hash1 = service.hashString(input);
        final hash2 = service.hashString(input);
        
        expect(hash1, equals(hash2));
        expect(hash1.length, equals(64)); // SHA-256 produces 64 hex chars
      });
      
      test('hashString should produce different hashes for different inputs', () {
        final hash1 = service.hashString('string1');
        final hash2 = service.hashString('string2');
        
        expect(hash1, isNot(equals(hash2)));
      });
      
      test('maskApiKey should mask middle of key', () {
        const apiKey = 'sk-1234567890abcdef';
        final masked = service.maskApiKey(apiKey);
        
        expect(masked, equals('sk-****cdef'));
        expect(masked.contains('1234567890ab'), isFalse);
      });
      
      test('maskApiKey should handle short keys', () {
        const shortKey = '12345678';
        final masked = service.maskApiKey(shortKey);
        
        expect(masked, equals('****'));
      });
      
      test('maskApiKey should handle very short keys', () {
        const veryShortKey = '123';
        final masked = service.maskApiKey(veryShortKey);
        
        expect(masked, equals('****'));
      });
      
      test('isValidApiKey should validate non-empty keys with min length', () {
        expect(service.isValidApiKey('sk-1234567890'), isTrue);
        expect(service.isValidApiKey('sk-123456789'), isFalse); // 9 chars < 10
        expect(service.isValidApiKey(''), isFalse);
        expect(service.isValidApiKey(null), isFalse);
      });
      
      test('isValidApiKey should respect custom minLength', () {
        expect(service.isValidApiKey('12345', minLength: 5), isTrue);
        expect(service.isValidApiKey('1234', minLength: 5), isFalse);
      });
    });
    
    group('Singleton', () {
      test('should return same instance', () {
        final instance1 = SecureStorageService();
        final instance2 = SecureStorageService();
        
        expect(identical(instance1, instance2), isTrue);
      });
    });
  });
}

