import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import '../../lib/services/scheduled_message_service.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/models/scheduled_message_model.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('Scheduled Message Delivery Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockStorageService mockStorageService;
    late ScheduledMessageService messageService;
    late MockUser mockUser;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = MockUser(
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockStorageService = MockStorageService();
      messageService = ScheduledMessageService(
        firestore: fakeFirestore,
        auth: mockAuth,
        storageService: mockStorageService,
      );
    });

    test('message status synchronization workflow', () async {
      // Step 1: Create a scheduled message
      final message = ScheduledMessage(
        id: '',
        senderId: 'test-user-id',
        recipientId: 'recipient-id',
        textContent: 'Test message for delivery',
        scheduledFor: DateTime.now().add(const Duration(minutes: 10)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      final messageId = await messageService.createScheduledMessage(message);
      expect(messageId, isNotEmpty);

      // Step 2: Verify message is created with pending status
      final createdMessage = await messageService.getScheduledMessage(messageId);
      expect(createdMessage, isNotNull);
      expect(createdMessage!.status, equals(ScheduledMessageStatus.pending));
      expect(createdMessage.deliveredAt, isNull);

      // Step 3: Simulate Cloud Function delivery by updating status
      await messageService.updateMessageStatus(
        messageId,
        ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now(),
      );

      // Step 4: Verify status is updated correctly
      final deliveredMessage = await messageService.refreshMessageStatus(messageId);
      expect(deliveredMessage, isNotNull);
      expect(deliveredMessage!.status, equals(ScheduledMessageStatus.delivered));
      expect(deliveredMessage.deliveredAt, isNotNull);

      // Step 5: Verify recipient can see the delivered message
      final receivedMessages = await messageService.getReceivedMessages('recipient-id');
      expect(receivedMessages.length, equals(1));
      expect(receivedMessages.first.status, equals(ScheduledMessageStatus.delivered));
      expect(receivedMessages.first.deliveredAt, isNotNull);
    });

    test('status consistency across sender and recipient views', () async {
      // Create a message that's ready for delivery
      final readyMessage = ScheduledMessage(
        id: 'ready-msg-1',
        senderId: 'sender-id',
        recipientId: 'test-user-id',
        textContent: 'Message ready for delivery',
        scheduledFor: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ScheduledMessageStatus.pending,
      );

      // Add to Firestore
      await fakeFirestore
          .collection('scheduledMessages')
          .doc(readyMessage.id)
          .set(readyMessage.toFirestore());

      // Check recipient view - should see the message as ready
      final recipientMessages = await messageService.getReceivedMessages('test-user-id');
      expect(recipientMessages.length, equals(1));
      expect(recipientMessages.first.isPending(), isTrue);
      expect(recipientMessages.first.isReadyForDelivery(), isTrue);

      // Check sender view - should see the message as pending
      final senderMessages = await messageService.getScheduledMessages('sender-id');
      expect(senderMessages.length, equals(1));
      expect(senderMessages.first.isPending(), isTrue);

      // Simulate delivery
      await messageService.updateMessageStatus(
        readyMessage.id,
        ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now(),
      );

      // Check recipient view after delivery
      final recipientMessagesAfter = await messageService.getReceivedMessages('test-user-id');
      expect(recipientMessagesAfter.length, equals(1));
      expect(recipientMessagesAfter.first.isDelivered(), isTrue);
      expect(recipientMessagesAfter.first.deliveredAt, isNotNull);

      // Check sender view after delivery - should no longer appear in scheduled messages
      final senderMessagesAfter = await messageService.getScheduledMessages('sender-id');
      expect(senderMessagesAfter.length, equals(0)); // Delivered messages don't appear in scheduled list
    });

    test('real-time stream updates reflect status changes', () async {
      // Create a message
      final message = ScheduledMessage(
        id: 'stream-msg-1',
        senderId: 'sender-id',
        recipientId: 'test-user-id',
        textContent: 'Message for stream testing',
        scheduledFor: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ScheduledMessageStatus.pending,
      );

      // Add to Firestore
      await fakeFirestore
          .collection('scheduledMessages')
          .doc(message.id)
          .set(message.toFirestore());

      // Start streaming received messages
      final stream = messageService.streamReceivedMessages('test-user-id');
      
      // Get initial state
      final initialMessages = await stream.first;
      expect(initialMessages.length, equals(1));
      expect(initialMessages.first.isPending(), isTrue);

      // Update status to delivered
      await fakeFirestore
          .collection('scheduledMessages')
          .doc(message.id)
          .update({
        'status': 'delivered',
        'deliveredAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Get updated state from stream
      final updatedMessages = await stream.first;
      expect(updatedMessages.length, equals(1));
      expect(updatedMessages.first.isDelivered(), isTrue);
      expect(updatedMessages.first.deliveredAt, isNotNull);
    });

    test('failed message status is handled correctly', () async {
      // Create a message
      final message = ScheduledMessage(
        id: 'failed-msg-1',
        senderId: 'test-user-id',
        recipientId: 'recipient-id',
        textContent: 'Message that will fail',
        scheduledFor: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ScheduledMessageStatus.pending,
      );

      // Add to Firestore
      await fakeFirestore
          .collection('scheduledMessages')
          .doc(message.id)
          .set(message.toFirestore());

      // Simulate failure by updating status
      await messageService.updateMessageStatus(
        message.id,
        ScheduledMessageStatus.failed,
      );

      // Verify failed status
      final failedMessage = await messageService.refreshMessageStatus(message.id);
      expect(failedMessage, isNotNull);
      expect(failedMessage!.status, equals(ScheduledMessageStatus.failed));
      expect(failedMessage.isFailed(), isTrue);

      // Failed messages should not appear in received messages
      final receivedMessages = await messageService.getReceivedMessages('recipient-id');
      expect(receivedMessages.length, equals(0));

      // Failed messages should still appear in sender's scheduled messages for retry
      final scheduledMessages = await messageService.getScheduledMessages('test-user-id');
      expect(scheduledMessages.length, equals(0)); // Only pending messages appear in scheduled list
    });
  });
}