import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Password Validation Tests', () {
    bool isPasswordValid(String password) {
      return password.length >= 6 &&
          password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[0-9]')) &&
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    }

    test('Valid password should pass validation', () {
      expect(isPasswordValid('Password123!'), true);
      expect(isPasswordValid('MyPass1@'), true);
      expect(isPasswordValid('Secure9#'), true);
    });

    test('Invalid passwords should fail validation', () {
      // Too short (5 characters)
      expect(isPasswordValid('Pas1!'), false);

      // No uppercase
      expect(isPasswordValid('password123!'), false);

      // No lowercase
      expect(isPasswordValid('PASSWORD123!'), false);

      // No number
      expect(isPasswordValid('Password!'), false);

      // No special character
      expect(isPasswordValid('Password123'), false);

      // Empty password
      expect(isPasswordValid(''), false);
    });

    test('Edge cases', () {
      // Exactly 6 characters with all requirements
      expect(isPasswordValid('Pass1!'), true);

      // Long password with all requirements
      expect(isPasswordValid('ThisIsAVeryLongPassword123!@#'), true);
    });
  });
}
