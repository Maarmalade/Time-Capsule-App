import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_capsule/models/scheduled_message_model.dart';

// Generate mocks
@GenerateMocks([DocumentSnapshot])
import 'scheduled_message_model_test.mocks.dart';

void main() {
  group('ScheduledMessage', () {
    late DateTime testDate;
    late DateTime futureDate;
    late DateTime deliveredDate;
    late ScheduledMessage testScheduledMessage;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      futureDate = DateTime(2024, 12, 31, 12, 0, 0);
      deliveredDate = DateTime(2024, 1, 2, 12, 0, 0);
      testScheduledMessage = ScheduledMessage(
        id: 'test-message-id',
        senderId: 'sender-id',
        recipientId: 'recipient-id',
        textContent: 'Hello from the past!',
        videoUrl: 'https://example.com/video.mp4',
        scheduledFor: futureDate,
        createdAt: testDate,
        status: ScheduledMessageStatus.pending,
      );
    });

    group('constructor', () {
      test('should create ScheduledMessage with all fields', () {
        expect(testScheduledMessage.id, equals('test-message-id'));
        expect(testScheduledMessage.senderId, equals('sender-id'));
        expect(testScheduledMessage.recipientId, equals('recipient-id'));
        expect(testScheduledMessage.textContent, equals('Hello from the past!'));
        expect(testScheduledMessage.videoUrl, equals('https://example.com/video.mp4'));
        expect(testScheduledMessage.scheduledFor, equals(futureDate));
        expect(testScheduledMessage.createdAt, equals(testDate));
        expect(testScheduledMessage.status, equals(ScheduledMessageStatus.pending));
        expect(testScheduledMessage.deliveredAt, isNull);
      });

      test('should create ScheduledMessage with null video URL', () {
        final message = ScheduledMessage(
          id: 'test-message-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello from the past!',
          scheduledFor: futureDate,
          createdAt: testDate,
          status: ScheduledMessageStatus.pending,
        );

        expect(message.videoUrl, isNull);
      });
    });

    group('fromFirestore', () {
      test('should create ScheduledMessage from Firestore document', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'recipientId': 'recipient-id',
          'textContent': 'Hello from the past!',
          'videoUrl': 'https://example.com/video.mp4',
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': Timestamp.fromDate(testDate),
          'status': 'pending',
          'deliveredAt': null,
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.id, equals('test-message-id'));
        expect(message.senderId, equals('sender-id'));
        expect(message.recipientId, equals('recipient-id'));
        expect(message.textContent, equals('Hello from the past!'));
        expect(message.videoUrl, equals('https://example.com/video.mp4'));
        expect(message.scheduledFor, equals(futureDate));
        expect(message.createdAt, equals(testDate));
        expect(message.status, equals(ScheduledMessageStatus.pending));
        expect(message.deliveredAt, isNull);
      });

      test('should handle delivered status with delivered date', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'recipientId': 'recipient-id',
          'textContent': 'Hello from the past!',
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': Timestamp.fromDate(testDate),
          'status': 'delivered',
          'deliveredAt': Timestamp.fromDate(deliveredDate),
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.status, equals(ScheduledMessageStatus.delivered));
        expect(message.deliveredAt, equals(deliveredDate));
      });

      test('should handle failed status', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'recipientId': 'recipient-id',
          'textContent': 'Hello from the past!',
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': Timestamp.fromDate(testDate),
          'status': 'failed',
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.status, equals(ScheduledMessageStatus.failed));
      });

      test('should handle missing fields with defaults', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.senderId, equals(''));
        expect(message.recipientId, equals(''));
        expect(message.textContent, equals(''));
        expect(message.videoUrl, isNull);
        expect(message.status, equals(ScheduledMessageStatus.pending));
      });

      test('should handle invalid status with default', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'recipientId': 'recipient-id',
          'textContent': 'Hello from the past!',
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': Timestamp.fromDate(testDate),
          'status': 'invalid-status',
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.status, equals(ScheduledMessageStatus.pending));
      });
    });

    group('toFirestore', () {
      test('should convert ScheduledMessage to Firestore map', () {
        final firestoreData = testScheduledMessage.toFirestore();

        expect(firestoreData['senderId'], equals('sender-id'));
        expect(firestoreData['recipientId'], equals('recipient-id'));
        expect(firestoreData['textContent'], equals('Hello from the past!'));
        expect(firestoreData['videoUrl'], equals('https://example.com/video.mp4'));
        expect(firestoreData['status'], equals('pending'));
        expect(firestoreData['scheduledFor'], isA<Timestamp>());
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['deliveredAt'], isNull);
        expect((firestoreData['scheduledFor'] as Timestamp).toDate(), equals(futureDate));
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));
      });

      test('should handle delivered status with delivered date', () {
        final message = testScheduledMessage.copyWith(
          status: ScheduledMessageStatus.delivered,
          deliveredAt: deliveredDate,
        );
        final firestoreData = message.toFirestore();

        expect(firestoreData['status'], equals('delivered'));
        expect(firestoreData['deliveredAt'], isA<Timestamp>());
        expect((firestoreData['deliveredAt'] as Timestamp).toDate(), equals(deliveredDate));
      });

      test('should not include id in Firestore data', () {
        final firestoreData = testScheduledMessage.toFirestore();

        expect(firestoreData.containsKey('id'), isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated status', () {
        final updatedMessage = testScheduledMessage.copyWith(
          status: ScheduledMessageStatus.delivered,
          deliveredAt: deliveredDate,
        );

        expect(updatedMessage.id, equals(testScheduledMessage.id));
        expect(updatedMessage.status, equals(ScheduledMessageStatus.delivered));
        expect(updatedMessage.deliveredAt, equals(deliveredDate));
        expect(updatedMessage.textContent, equals(testScheduledMessage.textContent));
      });

      test('should create identical copy when no parameters provided', () {
        final copiedMessage = testScheduledMessage.copyWith();

        expect(copiedMessage.id, equals(testScheduledMessage.id));
        expect(copiedMessage.senderId, equals(testScheduledMessage.senderId));
        expect(copiedMessage.recipientId, equals(testScheduledMessage.recipientId));
        expect(copiedMessage.status, equals(testScheduledMessage.status));
      });
    });

    group('validation methods', () {
      test('isValid should return true for valid message with future date', () {
        // Create a message with a future date
        final futureMessage = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
        );
        expect(futureMessage.isValid(), isTrue);
      });

      test('isValid should return false for empty senderId', () {
        final message = testScheduledMessage.copyWith(
          senderId: '',
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
        );
        expect(message.isValid(), isFalse);
      });

      test('isValid should return false for empty recipientId', () {
        final message = testScheduledMessage.copyWith(
          recipientId: '',
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
        );
        expect(message.isValid(), isFalse);
      });

      test('isValid should return false for empty textContent', () {
        final message = testScheduledMessage.copyWith(
          textContent: '',
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
        );
        expect(message.isValid(), isFalse);
      });

      test('isValid should return false for past scheduled date', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(message.isValid(), isFalse);
      });

      test('isPending should return true for pending status', () {
        expect(testScheduledMessage.isPending(), isTrue);
      });

      test('isDelivered should return true for delivered status', () {
        final message = testScheduledMessage.copyWith(status: ScheduledMessageStatus.delivered);
        expect(message.isDelivered(), isTrue);
      });

      test('isFailed should return true for failed status', () {
        final message = testScheduledMessage.copyWith(status: ScheduledMessageStatus.failed);
        expect(message.isFailed(), isTrue);
      });
    });

    group('helper methods', () {
      test('isScheduledForFuture should return true for future date', () {
        final futureMessage = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
        );
        expect(futureMessage.isScheduledForFuture(), isTrue);
      });

      test('isScheduledForFuture should return false for past date', () {
        final pastMessage = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(pastMessage.isScheduledForFuture(), isFalse);
      });

      test('isReadyForDelivery should return true for pending message with past scheduled date', () {
        final readyMessage = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().subtract(const Duration(minutes: 1)),
          status: ScheduledMessageStatus.pending,
        );
        expect(readyMessage.isReadyForDelivery(), isTrue);
      });

      test('isReadyForDelivery should return false for delivered message', () {
        final deliveredMessage = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().subtract(const Duration(minutes: 1)),
          status: ScheduledMessageStatus.delivered,
        );
        expect(deliveredMessage.isReadyForDelivery(), isFalse);
      });

      test('isSelfMessage should return true when sender and recipient are same', () {
        final selfMessage = testScheduledMessage.copyWith(recipientId: 'sender-id');
        expect(selfMessage.isSelfMessage(), isTrue);
      });

      test('isSelfMessage should return false when sender and recipient are different', () {
        expect(testScheduledMessage.isSelfMessage(), isFalse);
      });

      test('getTimeUntilDelivery should return duration for future pending message', () {
        final futureTime = DateTime.now().add(const Duration(hours: 2));
        final futureMessage = testScheduledMessage.copyWith(
          scheduledFor: futureTime,
          status: ScheduledMessageStatus.pending,
        );
        
        final timeUntilDelivery = futureMessage.getTimeUntilDelivery();
        expect(timeUntilDelivery, isNotNull);
        expect(timeUntilDelivery!.inHours, greaterThanOrEqualTo(1)); // Allow for some variance
        expect(timeUntilDelivery.inHours, lessThanOrEqualTo(2));
      });

      test('getTimeUntilDelivery should return null for delivered message', () {
        final deliveredMessage = testScheduledMessage.copyWith(
          status: ScheduledMessageStatus.delivered,
        );
        expect(deliveredMessage.getTimeUntilDelivery(), isNull);
      });

      test('getTimeUntilDelivery should return null for past scheduled message', () {
        final pastMessage = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(pastMessage.getTimeUntilDelivery(), isNull);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final message1 = ScheduledMessage(
          id: 'test-message-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello from the past!',
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: futureDate,
          createdAt: testDate,
          status: ScheduledMessageStatus.pending,
        );

        final message2 = ScheduledMessage(
          id: 'test-message-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello from the past!',
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: futureDate,
          createdAt: testDate,
          status: ScheduledMessageStatus.pending,
        );

        expect(message1, equals(message2));
        expect(message1.hashCode, equals(message2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final message1 = testScheduledMessage;
        final message2 = testScheduledMessage.copyWith(status: ScheduledMessageStatus.delivered);

        expect(message1, isNot(equals(message2)));
      });
    });

    group('toString', () {
      test('should return string representation of ScheduledMessage', () {
        final stringRepresentation = testScheduledMessage.toString();

        expect(stringRepresentation, contains('ScheduledMessage'));
        expect(stringRepresentation, contains('test-message-id'));
        expect(stringRepresentation, contains('sender-id'));
        expect(stringRepresentation, contains('recipient-id'));
        expect(stringRepresentation, contains('pending'));
      });

      test('should truncate long text content in string representation', () {
        final longText = 'a' * 100;
        final message = testScheduledMessage.copyWith(textContent: longText);
        final stringRepresentation = message.toString();

        expect(stringRepresentation, contains('...'));
        expect(stringRepresentation.length, lessThan(longText.length + 200));
      });
    });
  });

  group('ScheduledMessageStatus', () {
    test('should have correct enum values', () {
      expect(ScheduledMessageStatus.values.length, equals(3));
      expect(ScheduledMessageStatus.values, contains(ScheduledMessageStatus.pending));
      expect(ScheduledMessageStatus.values, contains(ScheduledMessageStatus.delivered));
      expect(ScheduledMessageStatus.values, contains(ScheduledMessageStatus.failed));
    });

    test('should have correct string names', () {
      expect(ScheduledMessageStatus.pending.name, equals('pending'));
      expect(ScheduledMessageStatus.delivered.name, equals('delivered'));
      expect(ScheduledMessageStatus.failed.name, equals('failed'));
    });
  });
}