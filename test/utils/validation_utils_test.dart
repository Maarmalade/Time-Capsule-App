import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    group('validateUsername', () {
      test('should return null for valid usernames', () {
        expect(ValidationUtils.validateUsername('validuser'), isNull);
        expect(ValidationUtils.validateUsername('user123'), isNull);
        expect(ValidationUtils.validateUsername('user_name'), isNull);
        expect(ValidationUtils.validateUsername('123user'), isNull);
      });

      test('should return error for invalid usernames', () {
        expect(ValidationUtils.validateUsername(''), isNotNull);
        expect(ValidationUtils.validateUsername('ab'), isNotNull); // Too short
        expect(ValidationUtils.validateUsername('a' * 21), isNotNull); // Too long
        expect(ValidationUtils.validateUsername('user-name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateUsername('user name'), isNotNull); // Space
        expect(ValidationUtils.validateUsername('user@name'), isNotNull); // Special character
      });

      test('should handle null input', () {
        expect(ValidationUtils.validateUsername(null), isNotNull);
      });
    });

    group('validatePassword', () {
      test('should return null for valid passwords', () {
        expect(ValidationUtils.validatePassword('password123'), isNull);
        expect(ValidationUtils.validatePassword('123456'), isNull);
        expect(ValidationUtils.validatePassword('a' * 6), isNull);
      });

      test('should return error for invalid passwords', () {
        expect(ValidationUtils.validatePassword(''), isNotNull);
        expect(ValidationUtils.validatePassword('12345'), isNotNull); // Too short
        expect(ValidationUtils.validatePassword('a' * 129), isNotNull); // Too long
      });

      test('should handle null input', () {
        expect(ValidationUtils.validatePassword(null), isNotNull);
      });
    });

    group('validatePasswordConfirmation', () {
      test('should return null when passwords match', () {
        expect(ValidationUtils.validatePasswordConfirmation('password', 'password'), isNull);
      });

      test('should return error when passwords do not match', () {
        expect(ValidationUtils.validatePasswordConfirmation('password1', 'password2'), isNotNull);
      });

      test('should return error for empty confirmation', () {
        expect(ValidationUtils.validatePasswordConfirmation('password', ''), isNotNull);
        expect(ValidationUtils.validatePasswordConfirmation('password', null), isNotNull);
      });
    });

    group('validateEmail', () {
      test('should return null for valid emails', () {
        expect(ValidationUtils.validateEmail('test@example.com'), isNull);
        expect(ValidationUtils.validateEmail('user.name@domain.co.uk'), isNull);
        expect(ValidationUtils.validateEmail('user+tag@example.org'), isNull);
      });

      test('should return error for invalid emails', () {
        expect(ValidationUtils.validateEmail(''), isNotNull);
        expect(ValidationUtils.validateEmail('invalid-email'), isNotNull);
        expect(ValidationUtils.validateEmail('@example.com'), isNotNull);
        expect(ValidationUtils.validateEmail('test@'), isNotNull);
        expect(ValidationUtils.validateEmail('test@.com'), isNotNull);
      });

      test('should handle null input', () {
        expect(ValidationUtils.validateEmail(null), isNotNull);
      });
    });

    group('validateFileName', () {
      test('should return null for valid file names', () {
        expect(ValidationUtils.validateFileName('document.txt'), isNull);
        expect(ValidationUtils.validateFileName('My File'), isNull);
        expect(ValidationUtils.validateFileName('file_name'), isNull);
      });

      test('should return error for invalid file names', () {
        expect(ValidationUtils.validateFileName(''), isNotNull);
        expect(ValidationUtils.validateFileName('   '), isNotNull); // Only spaces
        expect(ValidationUtils.validateFileName('a' * 101), isNotNull); // Too long
        expect(ValidationUtils.validateFileName('file<name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file>name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file:name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file"name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file/name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file\\name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file|name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file?name'), isNotNull); // Invalid character
        expect(ValidationUtils.validateFileName('file*name'), isNotNull); // Invalid character
      });

      test('should handle null input', () {
        expect(ValidationUtils.validateFileName(null), isNotNull);
      });
    });

    group('validateBatchOperation', () {
      test('should return null for valid batch operations', () {
        expect(ValidationUtils.validateBatchOperation(['item1', 'item2']), isNull);
        expect(ValidationUtils.validateBatchOperation(List.generate(50, (i) => 'item$i')), isNull);
      });

      test('should return error for invalid batch operations', () {
        expect(ValidationUtils.validateBatchOperation([]), isNotNull); // Empty list
        expect(ValidationUtils.validateBatchOperation(List.generate(51, (i) => 'item$i')), isNotNull); // Too many items
      });
    });

    group('isSafeForDisplay', () {
      test('should return true for safe text', () {
        expect(ValidationUtils.isSafeForDisplay('Normal text'), isTrue);
        expect(ValidationUtils.isSafeForDisplay('Text with numbers 123'), isTrue);
        expect(ValidationUtils.isSafeForDisplay('Text with symbols !@#'), isTrue);
      });

      test('should return false for unsafe text', () {
        expect(ValidationUtils.isSafeForDisplay('<script>alert("xss")</script>'), isFalse);
        expect(ValidationUtils.isSafeForDisplay('javascript:alert("xss")'), isFalse);
        expect(ValidationUtils.isSafeForDisplay('data:text/html,<script>alert("xss")</script>'), isFalse);
      });
    });

    group('sanitizeText', () {
      test('should remove dangerous content', () {
        expect(ValidationUtils.sanitizeText('<script>alert("xss")</script>normal text'), 'normal text');
        expect(ValidationUtils.sanitizeText('javascript:alert("xss")'), 'alert("xss")');
        expect(ValidationUtils.sanitizeText('data:text/html,content'), 'content');
      });

      test('should preserve safe content', () {
        expect(ValidationUtils.sanitizeText('Normal text'), 'Normal text');
        expect(ValidationUtils.sanitizeText('  Text with spaces  '), 'Text with spaces');
      });
    });

    group('getFileSizeString', () {
      test('should format file sizes correctly', () {
        expect(ValidationUtils.getFileSizeString(500), '500 B');
        expect(ValidationUtils.getFileSizeString(1024), '1.0 KB');
        expect(ValidationUtils.getFileSizeString(1024 * 1024), '1.0 MB');
        expect(ValidationUtils.getFileSizeString(1024 * 1024 * 1024), '1.0 GB');
      });
    });
  });
}