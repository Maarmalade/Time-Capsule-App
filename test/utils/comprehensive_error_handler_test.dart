import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/utils/comprehensive_error_handler.dart';

void main() {
  group('ComprehensiveErrorHandler', () {
    group('Media Upload Error Handling', () {
      test('should return specific error for file size issues', () {
        final error = 'File is too large (15.5MB > 10MB)';
        final result = ComprehensiveErrorHandler.getMediaUploadErrorMessage(error, mediaType: 'image');
        
        expect(result, contains('too large'));
        expect(result, contains('smaller file'));
      });

      test('should return specific error for unsupported file types', () {
        final error = 'Unsupported file type: .txt';
        final result = ComprehensiveErrorHandler.getMediaUploadErrorMessage(error, mediaType: 'image');
        
        expect(result, contains('not supported'));
        expect(result, contains('valid image'));
      });

      test('should return network error for connection issues', () {
        final error = 'Network connection failed';
        final result = ComprehensiveErrorHandler.getMediaUploadErrorMessage(error);
        
        expect(result, contains('network issues'));
        expect(result, contains('internet connection'));
      });
    });

    group('Scheduled Time Validation', () {
      test('should return specific error for past times', () {
        final error = 'Cannot schedule messages in the past';
        final result = ComprehensiveErrorHandler.getScheduledTimeValidationErrorMessage(error);
        
        expect(result, contains('past dates'));
        expect(result, contains('future date'));
      });

      test('should return specific error for minimum time requirement', () {
        final error = 'Message must be scheduled at least 1 minute in the future';
        final result = ComprehensiveErrorHandler.getScheduledTimeValidationErrorMessage(error);
        
        expect(result, contains('at least 1 minute'));
        expect(result, contains('processing time'));
      });
    });

    group('Shared Folder Access Errors', () {
      test('should return specific error for deleted folders', () {
        final error = 'Folder not found';
        final result = ComprehensiveErrorHandler.getSharedFolderAccessErrorMessage(error);
        
        expect(result, contains('no longer exists'));
        expect(result, contains('deleted by the owner'));
      });

      test('should return specific error for permission denied', () {
        final error = 'Permission denied - not a contributor';
        final result = ComprehensiveErrorHandler.getSharedFolderAccessErrorMessage(error);
        
        expect(result, contains('no longer have access'));
        expect(result, contains('removed your access'));
      });
    });

    group('Profile Picture Errors', () {
      test('should return cache-specific error messages', () {
        final error = 'Cache expired';
        final result = ComprehensiveErrorHandler.getProfilePictureErrorMessage(error, isCacheError: true);
        
        expect(result, contains('cache'));
        expect(result, contains('Refreshing'));
      });

      test('should return network error for loading issues', () {
        final error = 'Network timeout';
        final result = ComprehensiveErrorHandler.getProfilePictureErrorMessage(error);
        
        expect(result, contains('timed out'));
        expect(result, contains('cached version'));
      });
    });
  });
}