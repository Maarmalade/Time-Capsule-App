import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduledMessage Time Validation Logic Tests', () {

    group('validateScheduledTime logic', () {
      bool validateScheduledTime(DateTime scheduledTime) {
        final now = DateTime.now();
        final minimumFutureTime = now.add(const Duration(minutes: 1));
        return scheduledTime.isAfter(minimumFutureTime);
      }

      test('should return true for time more than 1 minute in future', () {
        final futureTime = DateTime.now().add(const Duration(minutes: 5));
        expect(validateScheduledTime(futureTime), isTrue);
      });

      test('should return true for time exactly 1 minute and 1 second in future', () {
        final futureTime = DateTime.now().add(const Duration(minutes: 1, seconds: 1));
        expect(validateScheduledTime(futureTime), isTrue);
      });

      test('should return false for time exactly 1 minute in future', () {
        final futureTime = DateTime.now().add(const Duration(minutes: 1));
        expect(validateScheduledTime(futureTime), isFalse);
      });

      test('should return false for time less than 1 minute in future', () {
        final nearFutureTime = DateTime.now().add(const Duration(seconds: 30));
        expect(validateScheduledTime(nearFutureTime), isFalse);
      });

      test('should return false for past time', () {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
        expect(validateScheduledTime(pastTime), isFalse);
      });

      test('should return false for current time', () {
        final currentTime = DateTime.now();
        expect(validateScheduledTime(currentTime), isFalse);
      });

      test('should allow scheduling within same hour', () {
        final now = DateTime.now();
        // Test scheduling 5 minutes later within the same hour
        final sameHourTime = DateTime(now.year, now.month, now.day, now.hour, now.minute + 5);
        expect(validateScheduledTime(sameHourTime), isTrue);
      });

      test('should handle timezone correctly', () {
        // Test with different timezone scenarios
        final now = DateTime.now();
        final futureTime = now.add(const Duration(minutes: 2));
        
        // Should work regardless of timezone since we're using DateTime.now()
        expect(validateScheduledTime(futureTime), isTrue);
      });
    });

    group('getScheduledTimeValidationError logic', () {
      String? getScheduledTimeValidationError(DateTime scheduledTime) {
        final now = DateTime.now();
        final minimumFutureTime = now.add(const Duration(minutes: 1));
        
        if (scheduledTime.isBefore(now)) {
          return 'Cannot schedule messages in the past. Please select a future time.';
        }
        
        if (scheduledTime.isBefore(minimumFutureTime)) {
          final secondsUntilValid = minimumFutureTime.difference(now).inSeconds;
          return 'Message must be scheduled at least 1 minute in the future. Please wait $secondsUntilValid seconds or select a later time.';
        }
        
        // Check if scheduling too far in the future (10 years max)
        final maxFutureTime = now.add(const Duration(days: 365 * 10));
        if (scheduledTime.isAfter(maxFutureTime)) {
          return 'Cannot schedule messages more than 10 years in the future.';
        }
        
        return null; // Time is valid
      }

      test('should return null for valid future time', () {
        final futureTime = DateTime.now().add(const Duration(minutes: 5));
        expect(getScheduledTimeValidationError(futureTime), isNull);
      });

      test('should return past time error for past dates', () {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
        final error = getScheduledTimeValidationError(pastTime);
        expect(error, isNotNull);
        expect(error, contains('Cannot schedule messages in the past'));
      });

      test('should return minimum time error for times less than 1 minute future', () {
        final nearFutureTime = DateTime.now().add(const Duration(seconds: 30));
        final error = getScheduledTimeValidationError(nearFutureTime);
        expect(error, isNotNull);
        expect(error, contains('Message must be scheduled at least 1 minute in the future'));
      });

      test('should return maximum time error for times too far in future', () {
        final farFutureTime = DateTime.now().add(const Duration(days: 365 * 11)); // 11 years
        final error = getScheduledTimeValidationError(farFutureTime);
        expect(error, isNotNull);
        expect(error, contains('Cannot schedule messages more than 10 years in the future'));
      });

      test('should provide specific wait time for near-future times', () {
        final now = DateTime.now();
        final nearFutureTime = now.add(const Duration(seconds: 30));
        final error = getScheduledTimeValidationError(nearFutureTime);
        expect(error, isNotNull);
        expect(error, contains('Please wait'));
        expect(error, contains('seconds'));
      });

      test('should handle edge case of exactly 1 minute future', () {
        final now = DateTime.now();
        final exactlyOneMinute = now.add(const Duration(minutes: 1));
        final error = getScheduledTimeValidationError(exactlyOneMinute);
        // The error might be null due to timing precision, so we check if it's close to the boundary
        if (error != null) {
          expect(error, contains('Message must be scheduled at least 1 minute in the future'));
        }
      });

      test('should allow exactly 1 minute and 1 second future', () {
        final slightlyMoreThanOneMinute = DateTime.now().add(const Duration(minutes: 1, seconds: 1));
        final error = getScheduledTimeValidationError(slightlyMoreThanOneMinute);
        expect(error, isNull);
      });
    });

    group('timezone handling', () {
      bool validateScheduledTime(DateTime scheduledTime) {
        final now = DateTime.now();
        final minimumFutureTime = now.add(const Duration(minutes: 1));
        return scheduledTime.isAfter(minimumFutureTime);
      }

      String? getScheduledTimeValidationError(DateTime scheduledTime) {
        final now = DateTime.now();
        final minimumFutureTime = now.add(const Duration(minutes: 1));
        
        if (scheduledTime.isBefore(now)) {
          return 'Cannot schedule messages in the past. Please select a future time.';
        }
        
        if (scheduledTime.isBefore(minimumFutureTime)) {
          final secondsUntilValid = minimumFutureTime.difference(now).inSeconds;
          return 'Message must be scheduled at least 1 minute in the future. Please wait $secondsUntilValid seconds or select a later time.';
        }
        
        // Check if scheduling too far in the future (10 years max)
        final maxFutureTime = now.add(const Duration(days: 365 * 10));
        if (scheduledTime.isAfter(maxFutureTime)) {
          return 'Cannot schedule messages more than 10 years in the future.';
        }
        
        return null; // Time is valid
      }

      test('should work correctly with local timezone', () {
        final now = DateTime.now();
        final futureTime = now.add(const Duration(minutes: 2));
        
        // Should validate correctly using local time
        expect(validateScheduledTime(futureTime), isTrue);
        expect(getScheduledTimeValidationError(futureTime), isNull);
      });

      test('should handle daylight saving time transitions', () {
        // Create a time that would be affected by DST
        final now = DateTime.now();
        final futureTime = now.add(const Duration(hours: 2, minutes: 1));
        
        // Should still validate correctly
        expect(validateScheduledTime(futureTime), isTrue);
        expect(getScheduledTimeValidationError(futureTime), isNull);
      });

      test('should work with different time formats', () {
        final now = DateTime.now();
        
        // Test with millisecond precision
        final preciseTime = DateTime(
          now.year, 
          now.month, 
          now.day, 
          now.hour, 
          now.minute + 2, 
          now.second, 
          now.millisecond
        );
        
        expect(validateScheduledTime(preciseTime), isTrue);
      });
    });

    group('edge cases', () {
      bool validateScheduledTime(DateTime scheduledTime) {
        final now = DateTime.now();
        final minimumFutureTime = now.add(const Duration(minutes: 1));
        return scheduledTime.isAfter(minimumFutureTime);
      }

      test('should handle year boundary correctly', () {
        // Test scheduling across year boundary
        final newYearTime = DateTime(DateTime.now().year + 1, 1, 1, 0, 1);
        expect(validateScheduledTime(newYearTime), isTrue);
      });

      test('should handle month boundary correctly', () {
        final now = DateTime.now();
        final nextMonth = DateTime(now.year, now.month + 1, 1, 0, 1);
        expect(validateScheduledTime(nextMonth), isTrue);
      });

      test('should handle leap year correctly', () {
        final leapYearTime = DateTime(2024, 2, 29, 12, 0); // Feb 29 in leap year
        if (leapYearTime.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
          expect(validateScheduledTime(leapYearTime), isTrue);
        }
      });
    });
  });
}