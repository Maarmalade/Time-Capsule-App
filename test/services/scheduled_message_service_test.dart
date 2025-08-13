import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:time_capsule/models/scheduled_message_model.dart';
import 'package:time_capsule/services/scheduled_message_service.dart';

void main() {
  group('ScheduledMessageService Tests', () {
    late ScheduledMessageService service;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = ScheduledMessageService(firestore: fakeFirestore);
    });

    group('createScheduledMessage', () {
      test('should create scheduled message with valid data', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Hello future!',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final messageId = await service.createScheduledMessage(message);

        expect(messageId, isNotEmpty);

        // Verify message was stored in Firestore
        final doc = await fakeFirestore
            .collection('scheduledMessages')
            .doc(messageId)
            .get();
        
        expect(doc.exists, isTrue);
        final storedMessage = ScheduledMessage.fromFirestore(doc);
        expect(storedMessage.senderId, equals('sender123'));
        expect(storedMessage.recipientId, equals('recipient456'));
        expect(storedMessage.textContent, equals('Hello future!'));
        expect(storedMessage.status, equals(ScheduledMessageStatus.pending));
      });

      test('should throw exception for empty sender ID', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: '',
          senderId: '',
          recipientId: 'recipient456',
          textContent: 'Hello future!',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(
          () => service.createScheduledMessage(message),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sender ID is required'),
          )),
        );
      });

      test('should throw exception for empty recipient ID', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: '',
          textContent: 'Hello future!',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(
          () => service.createScheduledMessage(message),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Recipient ID is required'),
          )),
        );
      });

      test('should throw exception for empty text content', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: '',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(
          () => service.createScheduledMessage(message),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Message content is required'),
          )),
        );
      });

      test('should throw exception for past scheduled date', () async {
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Hello past!',
          scheduledFor: pastDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(
          () => service.createScheduledMessage(message),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Scheduled delivery date must be in the future'),
          )),
        );
      });

      test('should throw exception for date too far in future', () async {
        final farFutureDate = DateTime.now().add(const Duration(days: 365 * 11)); // 11 years
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Hello far future!',
          scheduledFor: farFutureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(
          () => service.createScheduledMessage(message),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('cannot be more than 10 years in the future'),
          )),
        );
      });

      test('should throw exception for content too long', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final longContent = 'A' * 5001; // Exceeds 5000 character limit
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: longContent,
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(
          () => service.createScheduledMessage(message),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('cannot exceed 5000 characters'),
          )),
        );
      });

      test('should sanitize text content', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: '  Hello future!  \n\n  ',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final messageId = await service.createScheduledMessage(message);

        final doc = await fakeFirestore
            .collection('scheduledMessages')
            .doc(messageId)
            .get();
        
        final storedMessage = ScheduledMessage.fromFirestore(doc);
        expect(storedMessage.textContent, equals('Hello future!'));
      });

      test('should handle video URL correctly', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: '',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Message with video',
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final messageId = await service.createScheduledMessage(message);

        final doc = await fakeFirestore
            .collection('scheduledMessages')
            .doc(messageId)
            .get();
        
        final storedMessage = ScheduledMessage.fromFirestore(doc);
        expect(storedMessage.videoUrl, equals('https://example.com/video.mp4'));
      });
    });

    group('getScheduledMessages', () {
      test('should return scheduled messages for user', () async {
        // Create test messages
        final futureDate1 = DateTime.now().add(const Duration(days: 1));
        final futureDate2 = DateTime.now().add(const Duration(days: 2));
        
        final message1 = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Message 1',
          scheduledFor: futureDate1,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final message2 = ScheduledMessage(
          id: 'msg2',
          senderId: 'user123',
          recipientId: 'recipient789',
          textContent: 'Message 2',
          scheduledFor: futureDate2,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        // Store messages in fake Firestore
        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message1.toFirestore());
        await fakeFirestore.collection('scheduledMessages').doc('msg2').set(message2.toFirestore());

        final messages = await service.getScheduledMessages('user123');

        expect(messages, hasLength(2));
        expect(messages[0].id, equals('msg1'));
        expect(messages[1].id, equals('msg2'));
        expect(messages[0].senderId, equals('user123'));
        expect(messages[1].senderId, equals('user123'));
      });

      test('should return empty list for user with no messages', () async {
        final messages = await service.getScheduledMessages('user123');
        expect(messages, isEmpty);
      });

      test('should throw exception for empty user ID', () async {
        expect(
          () => service.getScheduledMessages(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID is required'),
          )),
        );
      });

      test('should only return messages sent by the user', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        
        final message1 = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Message from user123',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final message2 = ScheduledMessage(
          id: 'msg2',
          senderId: 'user456',
          recipientId: 'user123',
          textContent: 'Message from user456',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message1.toFirestore());
        await fakeFirestore.collection('scheduledMessages').doc('msg2').set(message2.toFirestore());

        final messages = await service.getScheduledMessages('user123');

        expect(messages, hasLength(1));
        expect(messages[0].id, equals('msg1'));
        expect(messages[0].senderId, equals('user123'));
      });
    });

    group('getReceivedMessages', () {
      test('should return delivered messages for user', () async {
        final deliveredDate = DateTime.now().subtract(const Duration(hours: 1));
        
        final message1 = ScheduledMessage(
          id: 'msg1',
          senderId: 'sender123',
          recipientId: 'user456',
          textContent: 'Delivered message 1',
          scheduledFor: deliveredDate,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.delivered,
          deliveredAt: deliveredDate,
        );

        final message2 = ScheduledMessage(
          id: 'msg2',
          senderId: 'sender789',
          recipientId: 'user456',
          textContent: 'Delivered message 2',
          scheduledFor: deliveredDate,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          status: ScheduledMessageStatus.delivered,
          deliveredAt: deliveredDate,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message1.toFirestore());
        await fakeFirestore.collection('scheduledMessages').doc('msg2').set(message2.toFirestore());

        final messages = await service.getReceivedMessages('user456');

        expect(messages, hasLength(2));
        expect(messages[0].recipientId, equals('user456'));
        expect(messages[1].recipientId, equals('user456'));
        expect(messages[0].status, equals(ScheduledMessageStatus.delivered));
        expect(messages[1].status, equals(ScheduledMessageStatus.delivered));
      });

      test('should not return pending messages', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        
        final pendingMessage = ScheduledMessage(
          id: 'msg1',
          senderId: 'sender123',
          recipientId: 'user456',
          textContent: 'Pending message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(pendingMessage.toFirestore());

        final messages = await service.getReceivedMessages('user456');
        expect(messages, isEmpty);
      });

      test('should throw exception for empty user ID', () async {
        expect(
          () => service.getReceivedMessages(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID is required'),
          )),
        );
      });
    });

    group('cancelScheduledMessage', () {
      test('should cancel pending message', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Message to cancel',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        await service.cancelScheduledMessage('msg1');

        final doc = await fakeFirestore.collection('scheduledMessages').doc('msg1').get();
        expect(doc.exists, isFalse);
      });

      test('should throw exception for non-existent message', () async {
        expect(
          () => service.cancelScheduledMessage('nonexistent'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Scheduled message not found'),
          )),
        );
      });

      test('should throw exception for delivered message', () async {
        final deliveredDate = DateTime.now().subtract(const Duration(hours: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Delivered message',
          scheduledFor: deliveredDate,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.delivered,
          deliveredAt: deliveredDate,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        expect(
          () => service.cancelScheduledMessage('msg1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Can only cancel pending messages'),
          )),
        );
      });

      test('should throw exception for empty message ID', () async {
        expect(
          () => service.cancelScheduledMessage(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Message ID is required'),
          )),
        );
      });
    });

    group('getScheduledMessage', () {
      test('should return message by ID', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        final retrievedMessage = await service.getScheduledMessage('msg1');

        expect(retrievedMessage, isNotNull);
        expect(retrievedMessage!.id, equals('msg1'));
        expect(retrievedMessage.textContent, equals('Test message'));
      });

      test('should return null for non-existent message', () async {
        final retrievedMessage = await service.getScheduledMessage('nonexistent');
        expect(retrievedMessage, isNull);
      });

      test('should return null for empty message ID', () async {
        final retrievedMessage = await service.getScheduledMessage('');
        expect(retrievedMessage, isNull);
      });
    });

    group('getPendingMessagesForDelivery', () {
      test('should return messages ready for delivery', () async {
        final pastDate = DateTime.now().subtract(const Duration(minutes: 30));
        final futureDate = DateTime.now().add(const Duration(days: 1));
        
        final readyMessage = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Ready for delivery',
          scheduledFor: pastDate,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.pending,
        );

        final notReadyMessage = ScheduledMessage(
          id: 'msg2',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Not ready yet',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(readyMessage.toFirestore());
        await fakeFirestore.collection('scheduledMessages').doc('msg2').set(notReadyMessage.toFirestore());

        final messages = await service.getPendingMessagesForDelivery();

        expect(messages, hasLength(1));
        expect(messages[0].id, equals('msg1'));
        expect(messages[0].isReadyForDelivery(), isTrue);
      });

      test('should not return delivered messages', () async {
        final pastDate = DateTime.now().subtract(const Duration(minutes: 30));
        
        final deliveredMessage = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Already delivered',
          scheduledFor: pastDate,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.delivered,
          deliveredAt: pastDate,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(deliveredMessage.toFirestore());

        final messages = await service.getPendingMessagesForDelivery();
        expect(messages, isEmpty);
      });
    });

    group('updateMessageStatus', () {
      test('should update message status to delivered', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        final deliveredAt = DateTime.now();
        await service.updateMessageStatus('msg1', ScheduledMessageStatus.delivered, deliveredAt: deliveredAt);

        final doc = await fakeFirestore.collection('scheduledMessages').doc('msg1').get();
        final updatedMessage = ScheduledMessage.fromFirestore(doc);
        
        expect(updatedMessage.status, equals(ScheduledMessageStatus.delivered));
        expect(updatedMessage.deliveredAt, isNotNull);
      });

      test('should update message status to failed', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        await service.updateMessageStatus('msg1', ScheduledMessageStatus.failed);

        final doc = await fakeFirestore.collection('scheduledMessages').doc('msg1').get();
        final updatedMessage = ScheduledMessage.fromFirestore(doc);
        
        expect(updatedMessage.status, equals(ScheduledMessageStatus.failed));
      });

      test('should throw exception for empty message ID', () async {
        expect(
          () => service.updateMessageStatus('', ScheduledMessageStatus.delivered),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Message ID is required'),
          )),
        );
      });
    });

    group('getMessageCounts', () {
      test('should return correct message counts', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));
        
        // Scheduled message
        final scheduledMessage = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Scheduled message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        // Received message
        final receivedMessage = ScheduledMessage(
          id: 'msg2',
          senderId: 'sender789',
          recipientId: 'user123',
          textContent: 'Received message',
          scheduledFor: pastDate,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.delivered,
          deliveredAt: pastDate,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(scheduledMessage.toFirestore());
        await fakeFirestore.collection('scheduledMessages').doc('msg2').set(receivedMessage.toFirestore());

        final counts = await service.getMessageCounts('user123');

        expect(counts['scheduled'], equals(1));
        expect(counts['received'], equals(1));
      });

      test('should return zero counts for user with no messages', () async {
        final counts = await service.getMessageCounts('user123');

        expect(counts['scheduled'], equals(0));
        expect(counts['received'], equals(0));
      });

      test('should throw exception for empty user ID', () async {
        expect(
          () => service.getMessageCounts(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID is required'),
          )),
        );
      });
    });

    group('canUserAccessMessage', () {
      test('should return true for sender', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        final canAccess = await service.canUserAccessMessage('msg1', 'user123');
        expect(canAccess, isTrue);
      });

      test('should return true for recipient', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        final canAccess = await service.canUserAccessMessage('msg1', 'recipient456');
        expect(canAccess, isTrue);
      });

      test('should return false for other users', () async {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'msg1',
          senderId: 'user123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        await fakeFirestore.collection('scheduledMessages').doc('msg1').set(message.toFirestore());

        final canAccess = await service.canUserAccessMessage('msg1', 'otheruser789');
        expect(canAccess, isFalse);
      });

      test('should return false for non-existent message', () async {
        final canAccess = await service.canUserAccessMessage('nonexistent', 'user123');
        expect(canAccess, isFalse);
      });
    });

    group('Model Validation Tests', () {
    group('Message validation logic', () {
      test('should validate message with valid future date', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Hello future!',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValid(), isTrue);
        expect(message.isScheduledForFuture(), isTrue);
        expect(message.isPending(), isTrue);
        expect(message.isSelfMessage(), isFalse);
      });

      test('should invalidate message with past date', () {
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));
        final message = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Hello past!',
          scheduledFor: pastDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(message.isValid(), isFalse);
        expect(message.isScheduledForFuture(), isFalse);
      });

      test('should invalidate message with empty required fields', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        
        // Empty sender ID
        final messageEmptySender = ScheduledMessage(
          id: 'test_id',
          senderId: '',
          recipientId: 'recipient456',
          textContent: 'Hello future!',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(messageEmptySender.isValid(), isFalse);

        // Empty recipient ID
        final messageEmptyRecipient = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: '',
          textContent: 'Hello future!',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(messageEmptyRecipient.isValid(), isFalse);

        // Empty text content
        final messageEmptyContent = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: '',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(messageEmptyContent.isValid(), isFalse);
      });

      test('should detect self messages', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final selfMessage = ScheduledMessage(
          id: 'test_id',
          senderId: 'user123',
          recipientId: 'user123',
          textContent: 'Note to self',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(selfMessage.isSelfMessage(), isTrue);
        expect(selfMessage.isValid(), isTrue);
      });

      test('should detect ready for delivery messages', () {
        final pastDate = DateTime.now().subtract(const Duration(minutes: 1));
        final readyMessage = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Ready for delivery',
          scheduledFor: pastDate,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.pending,
        );

        expect(readyMessage.isReadyForDelivery(), isTrue);
        expect(readyMessage.isPending(), isTrue);
        expect(readyMessage.isScheduledForFuture(), isFalse);
      });

      test('should calculate time until delivery', () {
        final futureDate = DateTime.now().add(const Duration(hours: 2));
        final message = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Future message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final timeUntilDelivery = message.getTimeUntilDelivery();
        expect(timeUntilDelivery, isNotNull);
        expect(timeUntilDelivery!.inHours, greaterThan(0)); // Should be positive
        expect(timeUntilDelivery!.inHours, lessThanOrEqualTo(2)); // Should be at most 2 hours
      });

      test('should return null time until delivery for past messages', () {
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));
        final message = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Past message',
          scheduledFor: pastDate,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.pending,
        );

        final timeUntilDelivery = message.getTimeUntilDelivery();
        expect(timeUntilDelivery, isNull);
      });

      test('should handle different message statuses', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        
        final pendingMessage = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Pending message',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );
        expect(pendingMessage.isPending(), isTrue);
        expect(pendingMessage.isDelivered(), isFalse);
        expect(pendingMessage.isFailed(), isFalse);

        final deliveredMessage = pendingMessage.copyWith(
          status: ScheduledMessageStatus.delivered,
          deliveredAt: DateTime.now(),
        );
        expect(deliveredMessage.isPending(), isFalse);
        expect(deliveredMessage.isDelivered(), isTrue);
        expect(deliveredMessage.isFailed(), isFalse);

        final failedMessage = pendingMessage.copyWith(
          status: ScheduledMessageStatus.failed,
        );
        expect(failedMessage.isPending(), isFalse);
        expect(failedMessage.isDelivered(), isFalse);
        expect(failedMessage.isFailed(), isTrue);
      });

      test('should handle video URL correctly', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        
        final messageWithVideo = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Message with video',
          videoUrl: 'https://example.com/video.mp4',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(messageWithVideo.videoUrl, equals('https://example.com/video.mp4'));
        expect(messageWithVideo.isValid(), isTrue);

        final messageWithoutVideo = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Message without video',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        expect(messageWithoutVideo.videoUrl, isNull);
        expect(messageWithoutVideo.isValid(), isTrue);
      });

      test('should handle copyWith correctly', () {
        final originalDate = DateTime.now().add(const Duration(days: 1));
        final original = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Original message',
          scheduledFor: originalDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final updated = original.copyWith(
          textContent: 'Updated message',
          status: ScheduledMessageStatus.delivered,
          deliveredAt: DateTime.now(),
        );

        expect(updated.id, equals(original.id));
        expect(updated.senderId, equals(original.senderId));
        expect(updated.recipientId, equals(original.recipientId));
        expect(updated.textContent, equals('Updated message'));
        expect(updated.scheduledFor, equals(original.scheduledFor));
        expect(updated.status, equals(ScheduledMessageStatus.delivered));
        expect(updated.deliveredAt, isNotNull);
      });

      test('should handle equality correctly', () {
        final date = DateTime.now().add(const Duration(days: 1));
        final createdAt = DateTime.now();
        
        final message1 = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: date,
          createdAt: createdAt,
          status: ScheduledMessageStatus.pending,
        );

        final message2 = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Test message',
          scheduledFor: date,
          createdAt: createdAt,
          status: ScheduledMessageStatus.pending,
        );

        final message3 = message1.copyWith(textContent: 'Different message');

        expect(message1, equals(message2));
        expect(message1, isNot(equals(message3)));
        expect(message1.hashCode, equals(message2.hashCode));
        expect(message1.hashCode, isNot(equals(message3.hashCode)));
      });

      test('should generate meaningful toString', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final message = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: 'Test message for toString',
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final stringRepresentation = message.toString();
        expect(stringRepresentation, contains('test_id'));
        expect(stringRepresentation, contains('sender123'));
        expect(stringRepresentation, contains('recipient456'));
        expect(stringRepresentation, contains('Test message for toString'));
        expect(stringRepresentation, contains('pending'));
      });

      test('should truncate long content in toString', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final longContent = 'A' * 100; // Long content that should be truncated
        final message = ScheduledMessage(
          id: 'test_id',
          senderId: 'sender123',
          recipientId: 'recipient456',
          textContent: longContent,
          scheduledFor: futureDate,
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        );

        final stringRepresentation = message.toString();
        expect(stringRepresentation, contains('...'));
        expect(stringRepresentation.length, lessThan(longContent.length + 200));
      });
    });
  });
}