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
  group('Scheduled Message Status Synchronization Tests', () {
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

    test('getReceivedMessages shows consistent status for delivered messages', () async {
      // Create a delivered message
      final deliveredMessage = ScheduledMessage(
        id: 'delivered-msg-1',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'This is a delivered message',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      // Add to Firestore
      await fakeFirestore
          .collection('scheduledMessages')
          .doc(deliveredMessage.id)
          .set(deliveredMessage.toFirestore());

      // Get received messages
      final receivedMessages = await messageService.getReceivedMessages('test-user-id');

      expect(receivedMessages.length, equals(1));
      expect(receivedMessages.first.status, equals(ScheduledMessageStatus.delivered));
      expect(receivedMessages.first.deliveredAt, isNotNull);
      expect(receivedMessages.first.isDelivered(), isTrue);
    });

    test('getReceivedMessages shows ready messages as available for viewing', () async {
      // Create a message that's ready for delivery (pending but past scheduled time)
      final readyMessage = ScheduledMessage(
        id: 'ready-msg-1',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'This message is ready for delivery',
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

      // Get received messages
      final receivedMessages = await messageService.getReceivedMessages('test-user-id');

      expect(receivedMessages.length, equals(1));
      expect(receivedMessages.first.status, equals(ScheduledMessageStatus.pending));
      expect(receivedMessages.first.deliveredAt, isNull);
      expect(receivedMessages.first.isPending(), isTrue);
      expect(receivedMessages.first.isReadyForDelivery(), isTrue);
    });

    test('getReceivedMessages sorts delivered messages before ready messages', () async {
      // Create a delivered message
      final deliveredMessage = ScheduledMessage(
        id: 'delivered-msg-1',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'Delivered message',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      // Create a ready message (more recent but still pending)
      final readyMessage = ScheduledMessage(
        id: 'ready-msg-1',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'Ready message',
        scheduledFor: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: ScheduledMessageStatus.pending,
      );

      // Add both to Firestore
      await Future.wait([
        fakeFirestore
            .collection('scheduledMessages')
            .doc(deliveredMessage.id)
            .set(deliveredMessage.toFirestore()),
        fakeFirestore
            .collection('scheduledMessages')
            .doc(readyMessage.id)
            .set(readyMessage.toFirestore()),
      ]);

      // Get received messages
      final receivedMessages = await messageService.getReceivedMessages('test-user-id');

      expect(receivedMessages.length, equals(2));
      // Delivered message should come first
      expect(receivedMessages.first.isDelivered(), isTrue);
      expect(receivedMessages.last.isPending(), isTrue);
    });

    test('updateMessageStatus properly sets deliveredAt timestamp', () async {
      // Create a pending message
      final pendingMessage = ScheduledMessage(
        id: 'pending-msg-1',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'Pending message',
        scheduledFor: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ScheduledMessageStatus.pending,
      );

      // Add to Firestore
      await fakeFirestore
          .collection('scheduledMessages')
          .doc(pendingMessage.id)
          .set(pendingMessage.toFirestore());

      // Update status to delivered
      final deliveryTime = DateTime.now();
      await messageService.updateMessageStatus(
        pendingMessage.id,
        ScheduledMessageStatus.delivered,
        deliveredAt: deliveryTime,
      );

      // Verify the update
      final updatedMessage = await messageService.getScheduledMessage(pendingMessage.id);
      expect(updatedMessage, isNotNull);
      expect(updatedMessage!.status, equals(ScheduledMessageStatus.delivered));
      expect(updatedMessage.deliveredAt, isNotNull);
      expect(updatedMessage.deliveredAt!.difference(deliveryTime).inSeconds, lessThan(2));
    });

    test('refreshMessageStatus gets latest data from server', () async {
      // Create a message
      final message = ScheduledMessage(
        id: 'refresh-msg-1',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'Message to refresh',
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

      // Simulate external status update (like from Cloud Function)
      await fakeFirestore
          .collection('scheduledMessages')
          .doc(message.id)
          .update({
        'status': 'delivered',
        'deliveredAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Refresh message status
      final refreshedMessage = await messageService.refreshMessageStatus(message.id);

      expect(refreshedMessage, isNotNull);
      expect(refreshedMessage!.status, equals(ScheduledMessageStatus.delivered));
      expect(refreshedMessage.deliveredAt, isNotNull);
    });

    test('streamReceivedMessages filters and sorts correctly', () async {
      // Create multiple messages with different statuses
      final messages = [
        ScheduledMessage(
          id: 'delivered-1',
          senderId: 'sender-1',
          recipientId: 'test-user-id',
          textContent: 'Delivered message 1',
          scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 60)),
          status: ScheduledMessageStatus.delivered,
          deliveredAt: DateTime.now().subtract(const Duration(minutes: 60)),
        ),
        ScheduledMessage(
          id: 'ready-1',
          senderId: 'sender-1',
          recipientId: 'test-user-id',
          textContent: 'Ready message 1',
          scheduledFor: DateTime.now().subtract(const Duration(minutes: 5)),
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          status: ScheduledMessageStatus.pending,
        ),
        ScheduledMessage(
          id: 'future-1',
          senderId: 'sender-1',
          recipientId: 'test-user-id',
          textContent: 'Future message 1',
          scheduledFor: DateTime.now().add(const Duration(hours: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        ),
      ];

      // Add all messages to Firestore
      for (final message in messages) {
        await fakeFirestore
            .collection('scheduledMessages')
            .doc(message.id)
            .set(message.toFirestore());
      }

      // Stream received messages
      final stream = messageService.streamReceivedMessages('test-user-id');
      final receivedMessages = await stream.first;

      // Should only include delivered and ready messages (not future ones)
      expect(receivedMessages.length, equals(2));
      
      // Should be sorted with delivered first
      expect(receivedMessages.first.isDelivered(), isTrue);
      expect(receivedMessages.last.isPending(), isTrue);
      expect(receivedMessages.last.isReadyForDelivery(), isTrue);
    });
  });
}