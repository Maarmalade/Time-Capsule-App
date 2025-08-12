import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_capsule/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('should handle FirebaseAuthException correctly', () {
      final authException = FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found',
      );
      
      final result = ErrorHandler.getErrorMessage(authException);
      expect(result, 'No account found with this email address.');
    });

    test('should handle FirebaseException correctly', () {
      final firebaseException = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Permission denied',
      );
      
      final result = ErrorHandler.getErrorMessage(firebaseException);
      expect(result, 'You do not have permission to perform this action.');
    });

    test('should handle generic Exception correctly', () {
      final exception = Exception('Test error message');
      
      final result = ErrorHandler.getErrorMessage(exception);
      expect(result, 'Test error message');
    });

    test('should handle string errors correctly', () {
      const error = 'Simple string error';
      
      final result = ErrorHandler.getErrorMessage(error);
      expect(result, 'Simple string error');
    });

    test('should handle unknown auth error codes', () {
      final authException = FirebaseAuthException(
        code: 'unknown-error',
        message: 'Unknown error occurred',
      );
      
      final result = ErrorHandler.getErrorMessage(authException);
      expect(result, 'Authentication error: Unknown error occurred');
    });

    test('should handle unknown firebase error codes', () {
      final firebaseException = FirebaseException(
        plugin: 'firebase_storage',
        code: 'unknown-error',
        message: 'Unknown error occurred',
      );
      
      final result = ErrorHandler.getErrorMessage(firebaseException);
      expect(result, 'Service error: Unknown error occurred');
    });
  });
}