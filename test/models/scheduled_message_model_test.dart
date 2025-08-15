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
        imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        videoUrl: 'https://example.com/video.mp4',
        scheduledFor: futureDate,
        createdAt: testDate,
        updatedAt: testDate,
        status: ScheduledMessageStatus.pending,
      );
    });

    group('constructor', () {
      test('should create ScheduledMessage with all fields', () {
        expect(testScheduledMessage.id, equals('test-message-id'));
        expect(testScheduledMessage.senderId, equals('sender-id'));
        expect(testScheduledMessage.recipientId, equals('recipient-id'));
        expect(testScheduledMessage.textContent, equals('Hello from the past!'));
        expect(testScheduledMessage.imageUrls, equals(['https://example.com/image1.jpg', 'https://example.com/image2.jpg']));
        expect(testScheduledMessage.videoUrl, equals('https://example.com/video.mp4'));
        expect(testScheduledMessage.scheduledFor, equals(futureDate));
        expect(testScheduledMessage.createdAt, equals(testDate));
        expect(testScheduledMessage.updatedAt, equals(testDate));
        expect(testScheduledMessage.status, equals(ScheduledMessageStatus.pending));
        expect(testScheduledMessage.deliveredAt, isNull);
      });

      test('should create ScheduledMessage with null video URL and imageUrls', () {
        final message = ScheduledMessage(
          id: 'test-message-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello from the past!',
          scheduledFor: futureDate,
          createdAt: testDate,
          updatedAt: testDate,
          status: ScheduledMessageStatus.pending,
        );

        expect(message.videoUrl, isNull);
        expect(message.imageUrls, isNull);
      });
    });

    group('fromFirestore', () {
      test('should create ScheduledMessage from Firestore document', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'recipientId': 'recipient-id',
          'textContent': 'Hello from the past!',
          'imageUrls': ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
          'videoUrl': 'https://example.com/video.mp4',
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
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
        expect(message.imageUrls, equals(['https://example.com/image1.jpg', 'https://example.com/image2.jpg']));
        expect(message.videoUrl, equals('https://example.com/video.mp4'));
        expect(message.scheduledFor, equals(futureDate));
        expect(message.createdAt, equals(testDate));
        expect(message.updatedAt, equals(testDate));
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
          'updatedAt': Timestamp.fromDate(testDate),
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
          'updatedAt': Timestamp.fromDate(testDate),
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
          'updatedAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.senderId, equals(''));
        expect(message.recipientId, equals(''));
        expect(message.textContent, equals(''));
        expect(message.imageUrls, isNull);
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
          'updatedAt': Timestamp.fromDate(testDate),
          'status': 'invalid-status',
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.status, equals(ScheduledMessageStatus.pending));
      });

      test('should handle null imageUrls from Firestore', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'recipientId': 'recipient-id',
          'textContent': 'Hello from the past!',
          'imageUrls': null,
          'videoUrl': 'https://example.com/video.mp4',
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'status': 'pending',
        };

        when(mockDoc.id).thenReturn('test-message-id');
        when(mockDoc.data()).thenReturn(data);

        final message = ScheduledMessage.fromFirestore(mockDoc);

        expect(message.imageUrls, isNull);
        expect(message.videoUrl, equals('https://example.com/video.mp4'));
      });
    });

    group('toFirestore', () {
      test('should convert ScheduledMessage to Firestore map', () {
        final firestoreData = testScheduledMessage.toFirestore();

        expect(firestoreData['senderId'], equals('sender-id'));
        expect(firestoreData['recipientId'], equals('recipient-id'));
        expect(firestoreData['textContent'], equals('Hello from the past!'));
        expect(firestoreData['imageUrls'], equals(['https://example.com/image1.jpg', 'https://example.com/image2.jpg']));
        expect(firestoreData['videoUrl'], equals('https://example.com/video.mp4'));
        expect(firestoreData['status'], equals('pending'));
        expect(firestoreData['scheduledFor'], isA<Timestamp>());
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
        expect(firestoreData['deliveredAt'], isNull);
        expect((firestoreData['scheduledFor'] as Timestamp).toDate(), equals(futureDate));
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));
        expect((firestoreData['updatedAt'] as Timestamp).toDate(), equals(testDate));
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
        expect(copiedMessage.imageUrls, equals(testScheduledMessage.imageUrls));
        expect(copiedMessage.status, equals(testScheduledMessage.status));
      });

      test('should create copy with updated imageUrls', () {
        final newImageUrls = ['https://example.com/new-image.jpg'];
        final updatedMessage = testScheduledMessage.copyWith(imageUrls: newImageUrls);

        expect(updatedMessage.id, equals(testScheduledMessage.id));
        expect(updatedMessage.imageUrls, equals(newImageUrls));
        expect(updatedMessage.textContent, equals(testScheduledMessage.textContent));
        expect(updatedMessage.videoUrl, equals(testScheduledMessage.videoUrl));
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

      test('isValid should return false for time less than 1 minute in future', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(seconds: 30)),
        );
        expect(message.isValid(), isFalse);
      });

      test('isValid should return true for time more than 1 minute in future', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(minutes: 2)),
        );
        expect(message.isValid(), isTrue);
      });

      test('isValidScheduledTime should return true for time more than 1 minute in future', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(minutes: 2)),
        );
        expect(message.isValidScheduledTime(), isTrue);
      });

      test('isValidScheduledTime should return false for time less than 1 minute in future', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(seconds: 30)),
        );
        expect(message.isValidScheduledTime(), isFalse);
      });

      test('isValidScheduledTime should return false for past time', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(message.isValidScheduledTime(), isFalse);
      });

      test('isValidScheduledTime should return false for exactly 1 minute in future', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(minutes: 1)),
        );
        expect(message.isValidScheduledTime(), isFalse);
      });

      test('isValidScheduledTime should return true for exactly 1 minute and 1 second in future', () {
        final message = testScheduledMessage.copyWith(
          scheduledFor: DateTime.now().add(const Duration(minutes: 1, seconds: 1)),
        );
        expect(message.isValidScheduledTime(), isTrue);
      });

      test('isValidScheduledTime should allow scheduling within same hour', () {
        final now = DateTime.now();
        final sameHourTime = DateTime(now.year, now.month, now.day, now.hour, now.minute + 5);
        final message = testScheduledMessage.copyWith(scheduledFor: sameHourTime);
        expect(message.isValidScheduledTime(), isTrue);
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

    group('media validation methods', () {
      test('hasMedia should return true when message has images', () {
        final messageWithImages = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello!',
          imageUrls: ['https://example.com/image1.jpg'],
          videoUrl: null,
          scheduledFor: DateTime.now().add(Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(messageWithImages.hasMedia(), isTrue);
      });

      test('hasMedia should return true when message has video', () {
        final messageWithVideo = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello!',
          imageUrls: null,
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: DateTime.now().add(Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(messageWithVideo.hasMedia(), isTrue);
      });

      test('hasMedia should return true when message has both images and video', () {
        expect(testScheduledMessage.hasMedia(), isTrue);
      });

      test('hasMedia should return false when message has no media', () {
        final messageWithoutMedia = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello!',
          imageUrls: null,
          videoUrl: null,
          scheduledFor: DateTime.now().add(Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(messageWithoutMedia.hasMedia(), isFalse);
      });

      test('hasMedia should return false when imageUrls is empty list', () {
        final messageWithEmptyImages = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello!',
          imageUrls: [],
          videoUrl: null,
          scheduledFor: DateTime.now().add(Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(messageWithEmptyImages.hasMedia(), isFalse);
      });

      test('getAllMediaUrls should return all image and video URLs', () {
        final allUrls = testScheduledMessage.getAllMediaUrls();
        expect(allUrls, contains('https://example.com/image1.jpg'));
        expect(allUrls, contains('https://example.com/image2.jpg'));
        expect(allUrls, contains('https://example.com/video.mp4'));
        expect(allUrls.length, equals(3));
      });

      test('getAllMediaUrls should return only image URLs when no video', () {
        final messageWithOnlyImages = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello!',
          imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
          videoUrl: null,
          scheduledFor: DateTime.now().add(Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        final allUrls = messageWithOnlyImages.getAllMediaUrls();
        expect(allUrls, equals(['https://example.com/image1.jpg', 'https://example.com/image2.jpg']));
      });

      test('getAllMediaUrls should return only video URL when no images', () {
        final messageWithOnlyVideo = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello!',
          imageUrls: null,
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: DateTime.now().add(Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        final allUrls = messageWithOnlyVideo.getAllMediaUrls();
        expect(allUrls, equals(['https://example.com/video.mp4']));
      });

      test('getAllMediaUrls should return empty list when no media', () {
        final messageWithoutMedia = ScheduledMessage(
          id: 'test-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello!',
          imageUrls: null,
          videoUrl: null,
          scheduledFor: DateTime.now().add(Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        final allUrls = messageWithoutMedia.getAllMediaUrls();
        expect(allUrls, isEmpty);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final message1 = ScheduledMessage(
          id: 'test-message-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello from the past!',
          imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: futureDate,
          createdAt: testDate,
          updatedAt: testDate,
          status: ScheduledMessageStatus.pending,
        );

        final message2 = ScheduledMessage(
          id: 'test-message-id',
          senderId: 'sender-id',
          recipientId: 'recipient-id',
          textContent: 'Hello from the past!',
          imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: futureDate,
          createdAt: testDate,
          updatedAt: testDate,
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
        expect(stringRepresentation.length, lessThan(longText.length + 400)); // Increased limit due to additional fields
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