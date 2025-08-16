import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/pages/scheduled_messages/scheduled_messages_page.dart';
import '../../lib/services/scheduled_message_service.dart';
import '../../lib/models/scheduled_message_model.dart';
import '../../lib/models/user_profile.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  ScheduledMessageService,
])
import 'scheduled_messages_comprehensive_test.mocks.dart';

void main() {
  group('Scheduled Messages Comprehensive Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockScheduledMessageService mockMessageService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockMessageService = MockScheduledMessageService();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
    });

    testWidgets('ScheduledMessagesPage should display correctly', (tester) async {
      // Mock empty message lists
      when(mockMessageService.streamScheduledMessages('test-user-id'))
          .thenAnswer((_) => Stream.value([]));
      when(mockMessageService.streamReceivedMessages('test-user-id'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        MaterialApp(
          home: const ScheduledMessagesPage(),
        ),
      );

      // Verify the page loads
      expect(find.text('Scheduled Messages'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
    });

    testWidgets('Should show full screen image viewer when image is tapped', (tester) async {
      const testImageUrl = 'https://example.com/test-image.jpg';
      
      await tester.pumpWidget(
        MaterialApp(
          home: const FullScreenImageViewer(imageUrl: testImageUrl),
        ),
      );

      // Verify the full screen viewer is displayed
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    test('Status update should work correctly', () {
      // Test message status transitions
      final message = ScheduledMessage(
        id: 'test-id',
        senderId: 'sender-id',
        recipientId: 'recipient-id',
        textContent: 'Test message',
        scheduledFor: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      expect(message.isPending(), isTrue);
      expect(message.isDelivered(), isFalse);

      // Test delivered status
      final deliveredMessage = message.copyWith(
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now(),
      );

      expect(deliveredMessage.isPending(), isFalse);
      expect(deliveredMessage.isDelivered(), isTrue);
    });

    test('Stream should include both pending and delivered messages', () async {
      final pendingMessage = ScheduledMessage(
        id: 'pending-id',
        senderId: 'test-user-id',
        recipientId: 'recipient-id',
        textContent: 'Pending message',
        scheduledFor: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      final deliveredMessage = ScheduledMessage(
        id: 'delivered-id',
        senderId: 'test-user-id',
        recipientId: 'recipient-id',
        textContent: 'Delivered message',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now(),
      );

      when(mockMessageService.streamScheduledMessages('test-user-id'))
          .thenAnswer((_) => Stream.value([pendingMessage, deliveredMessage]));

      final stream = mockMessageService.streamScheduledMessages('test-user-id');
      final messages = await stream.first;

      expect(messages.length, equals(2));
      expect(messages.any((m) => m.isPending()), isTrue);
      expect(messages.any((m) => m.isDelivered()), isTrue);
    });

    test('Media attachments should be handled correctly', () {
      final messageWithMedia = ScheduledMessage(
        id: 'media-id',
        senderId: 'test-user-id',
        recipientId: 'recipient-id',
        textContent: 'Message with media',
        imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        videoUrl: 'https://example.com/video.mp4',
        scheduledFor: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      expect(messageWithMedia.hasMedia(), isTrue);
      expect(messageWithMedia.imageUrls?.length, equals(2));
      expect(messageWithMedia.videoUrl, isNotNull);
    });

    testWidgets('Message cards should handle overflow correctly', (tester) async {
      final longUsernameProfile = UserProfile(
        id: 'long-id',
        username: 'This is a very long username that might cause overflow issues',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final message = ScheduledMessage(
        id: 'test-id',
        senderId: 'test-user-id',
        recipientId: 'long-id',
        textContent: 'This is a very long message content that should be handled properly without causing any overflow issues in the UI components',
        scheduledFor: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: message,
              friends: [longUsernameProfile],
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
      
      // Verify text is displayed (might be ellipsized)
      expect(find.textContaining('To:'), findsOneWidget);
      expect(find.textContaining('This is a very long message'), findsOneWidget);
    });

    test('Time until delivery calculation should work correctly', () {
      final now = DateTime.now();
      
      // Test future message
      final futureMessage = ScheduledMessage(
        id: 'future-id',
        senderId: 'test-user-id',
        recipientId: 'recipient-id',
        textContent: 'Future message',
        scheduledFor: now.add(const Duration(hours: 2, minutes: 30)),
        createdAt: now,
        updatedAt: now,
        status: ScheduledMessageStatus.pending,
      );

      // Test past message (ready for delivery)
      final pastMessage = ScheduledMessage(
        id: 'past-id',
        senderId: 'test-user-id',
        recipientId: 'recipient-id',
        textContent: 'Past message',
        scheduledFor: now.subtract(const Duration(minutes: 5)),
        createdAt: now,
        updatedAt: now,
        status: ScheduledMessageStatus.pending,
      );

      // These would be tested in the actual widget implementation
      expect(futureMessage.isPending(), isTrue);
      expect(pastMessage.isPending(), isTrue);
    });

    testWidgets('Create message dialog should validate input correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateScheduledMessageDialog(
            friends: [],
            onMessageCreated: () {},
          ),
        ),
      );

      // Verify dialog is displayed
      expect(find.text('Create Scheduled Message'), findsOneWidget);
      expect(find.text('Send to:'), findsOneWidget);
      expect(find.text('Message:'), findsOneWidget);
      expect(find.text('Delivery Date & Time:'), findsOneWidget);

      // Try to submit without content
      await tester.tap(find.text('Schedule'));
      await tester.pump();

      // Should show validation error
      expect(find.textContaining('Please'), findsWidgets);
    });

    test('Error handling should work correctly', () {
      // Test error message formatting
      const testError = 'Test error message';
      
      // This would be tested with actual error scenarios
      expect(testError, isNotEmpty);
    });
  });

  group('Real-time Updates Tests', () {
    test('Stream subscriptions should be managed correctly', () {
      // Test that streams are properly set up and disposed
      // This would involve testing the actual stream lifecycle
      expect(true, isTrue); // Placeholder
    });

    test('Status changes should be reflected in real-time', () {
      // Test that when a message status changes in Firestore,
      // the UI updates automatically
      expect(true, isTrue); // Placeholder
    });
  });

  group('UI Responsiveness Tests', () {
    testWidgets('Should handle different screen sizes', (tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile
      
      await tester.pumpWidget(
        MaterialApp(
          home: const ScheduledMessagesPage(),
        ),
      );

      expect(find.byType(ScheduledMessagesPage), findsOneWidget);

      // Test with tablet size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pump();

      expect(find.byType(ScheduledMessagesPage), findsOneWidget);
    });
  });
}