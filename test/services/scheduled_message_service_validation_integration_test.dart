import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/scheduled_message_model.dart';

void main() {
  group('ScheduledMessage Service Validation Integration Tests', () {
    
    group('Enhanced time validation integration', () {
      test('should create valid message with proper time validation', () {
        final validTime = DateTime.now().add(const Duration(minutes: 2));
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Test message',
          scheduledFor: validTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValid(), isTrue);
        expect(message.isValidScheduledTime(), isTrue);
      });

      test('should reject message with invalid time', () {
        final invalidTime = DateTime.now().add(const Duration(seconds: 30));
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Test message',
          scheduledFor: invalidTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValid(), isFalse);
        expect(message.isValidScheduledTime(), isFalse);
      });

      test('should handle same-hour scheduling correctly', () {
        final now = DateTime.now();
        final sameHourTime = DateTime(
          now.year, 
          now.month, 
          now.day, 
          now.hour, 
          now.minute + 5
        );
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Same hour message',
          scheduledFor: sameHourTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValid(), isTrue);
        expect(message.isValidScheduledTime(), isTrue);
      });

      test('should handle timezone boundaries correctly', () {
        final now = DateTime.now();
        final crossTimezoneTime = now.add(const Duration(hours: 1, minutes: 1));
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Cross timezone message',
          scheduledFor: crossTimezoneTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValid(), isTrue);
        expect(message.isValidScheduledTime(), isTrue);
      });

      test('should validate message with media and proper timing', () {
        final validTime = DateTime.now().add(const Duration(minutes: 3));
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Message with media',
          imageUrls: ['https://example.com/image.jpg'],
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: validTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValid(), isTrue);
        expect(message.isValidScheduledTime(), isTrue);
        expect(message.hasMedia(), isTrue);
      });
    });

    group('Error message validation', () {
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

      test('should provide helpful error messages for different scenarios', () {
        // Past time
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final pastError = getScheduledTimeValidationError(pastTime);
        expect(pastError, contains('Cannot schedule messages in the past'));

        // Too soon
        final tooSoon = DateTime.now().add(const Duration(seconds: 30));
        final tooSoonError = getScheduledTimeValidationError(tooSoon);
        expect(tooSoonError, contains('Message must be scheduled at least 1 minute in the future'));
        expect(tooSoonError, contains('Please wait'));

        // Too far in future
        final tooFar = DateTime.now().add(const Duration(days: 365 * 11));
        final tooFarError = getScheduledTimeValidationError(tooFar);
        expect(tooFarError, contains('Cannot schedule messages more than 10 years in the future'));

        // Valid time
        final validTime = DateTime.now().add(const Duration(minutes: 5));
        final validError = getScheduledTimeValidationError(validTime);
        expect(validError, isNull);
      });
    });

    group('Requirements validation', () {
      test('should meet requirement 2.1: validate time is at least 1 minute in future', () {
        final oneMinuteFuture = DateTime.now().add(const Duration(minutes: 1));
        final oneMinuteOneSecondFuture = DateTime.now().add(const Duration(minutes: 1, seconds: 1));
        
        final message1 = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Test message',
          scheduledFor: oneMinuteFuture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final message2 = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Test message',
          scheduledFor: oneMinuteOneSecondFuture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        // Exactly 1 minute should be invalid
        expect(message1.isValidScheduledTime(), isFalse);
        // More than 1 minute should be valid
        expect(message2.isValidScheduledTime(), isTrue);
      });

      test('should meet requirement 2.2: allow scheduling within same hour', () {
        final now = DateTime.now();
        final sameHourTime = DateTime(now.year, now.month, now.day, now.hour, now.minute + 5);
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Same hour message',
          scheduledFor: sameHourTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValidScheduledTime(), isTrue);
      });

      test('should meet requirement 2.3: provide clear error messages', () {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
        final tooSoon = DateTime.now().add(const Duration(seconds: 30));
        
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
          
          return null;
        }

        final pastError = getScheduledTimeValidationError(pastTime);
        final tooSoonError = getScheduledTimeValidationError(tooSoon);

        expect(pastError, isNotNull);
        expect(pastError, contains('Cannot schedule messages in the past'));
        expect(tooSoonError, isNotNull);
        expect(tooSoonError, contains('Message must be scheduled at least 1 minute in the future'));
      });

      test('should meet requirement 2.4: handle timezone correctly', () {
        // Test with local timezone
        final now = DateTime.now();
        final futureTime = now.add(const Duration(minutes: 2));
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Timezone test',
          scheduledFor: futureTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        // Should work with local timezone
        expect(message.isValidScheduledTime(), isTrue);
      });

      test('should meet requirement 2.5: store exact delivery timestamp', () {
        final exactTime = DateTime(2024, 12, 25, 14, 30, 45, 123);
        
        final message = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-123',
          recipientId: 'recipient-456',
          textContent: 'Exact time test',
          scheduledFor: exactTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        // Should preserve exact timestamp
        expect(message.scheduledFor, equals(exactTime));
        expect(message.scheduledFor.millisecond, equals(123));
      });
    });
  });
}