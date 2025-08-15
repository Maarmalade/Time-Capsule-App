import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/scheduled_message_model.dart';
import '../../lib/models/user_profile.dart';
import '../../lib/pages/scheduled_messages/scheduled_messages_page.dart';

void main() {
  group('ScheduledMessageCard', () {
    late List<UserProfile> friends;
    late ScheduledMessage testMessage;
    late ScheduledMessage testMessageWithMedia;

    setUp(() {
      
      friends = [
        UserProfile(
          id: 'friend-1',
          username: 'TestFriend',
          email: 'friend@test.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      testMessage = ScheduledMessage(
        id: 'test-message-1',
        senderId: 'test-user-id',
        recipientId: 'friend-1',
        textContent: 'This is a test scheduled message',
        scheduledFor: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      testMessageWithMedia = ScheduledMessage(
        id: 'test-message-2',
        senderId: 'test-user-id',
        recipientId: 'friend-1',
        textContent: 'This is a test message with media',
        imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        videoUrl: 'https://example.com/video.mp4',
        scheduledFor: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );
    });

    testWidgets('should display basic message information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: testMessage,
              friends: friends,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify message content is displayed
      expect(find.text('This is a test scheduled message'), findsOneWidget);
      
      // Verify recipient information
      expect(find.text('To: TestFriend'), findsOneWidget);
      
      // Verify status chip
      expect(find.text('Pending'), findsOneWidget);
      
      // Verify cancel button is present for pending messages
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should display media attachments when present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: testMessageWithMedia,
              friends: friends,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify message content is displayed
      expect(find.text('This is a test message with media'), findsOneWidget);
      
      // Verify attachments section is displayed
      expect(find.text('Attachments:'), findsOneWidget);
      
      // Verify horizontal scroll view for media is present
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show delivered status correctly', (WidgetTester tester) async {
      final deliveredMessage = testMessage.copyWith(
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: deliveredMessage,
              friends: friends,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify delivered status is shown
      expect(find.text('Delivered'), findsOneWidget);
      
      // Verify cancel button is not present for delivered messages
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('should show self message correctly', (WidgetTester tester) async {
      final selfMessage = testMessage.copyWith(
        recipientId: 'test-user-id', // Same as sender
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: selfMessage,
              friends: friends,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify self message indicator
      expect(find.text('To: Myself'), findsOneWidget);
    });

    testWidgets('should handle failed status correctly', (WidgetTester tester) async {
      final failedMessage = testMessage.copyWith(
        status: ScheduledMessageStatus.failed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: failedMessage,
              friends: friends,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify failed status is shown
      expect(find.text('Failed'), findsOneWidget);
      
      // Verify cancel button is not present for failed messages
      expect(find.text('Cancel'), findsNothing);
    });
  });

  group('ReceivedMessageCard', () {
    late List<UserProfile> friends;
    late ScheduledMessage testMessage;
    late ScheduledMessage testMessageWithMedia;

    setUp(() {
      friends = [
        UserProfile(
          id: 'sender-1',
          username: 'TestSender',
          email: 'sender@test.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      testMessage = ScheduledMessage(
        id: 'received-message-1',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'This is a received message',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      testMessageWithMedia = ScheduledMessage(
        id: 'received-message-2',
        senderId: 'sender-1',
        recipientId: 'test-user-id',
        textContent: 'This is a received message with media',
        imageUrls: ['https://example.com/image1.jpg'],
        videoUrl: 'https://example.com/video.mp4',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
    });

    testWidgets('should display received message information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceivedMessageCard(
              message: testMessage,
              friends: friends,
            ),
          ),
        ),
      );

      // Verify message content is displayed
      expect(find.text('This is a received message'), findsOneWidget);
      
      // Verify sender information
      expect(find.text('From: TestSender'), findsOneWidget);
      
      // Verify status chip
      expect(find.text('Delivered'), findsOneWidget);
      
      // Verify tap to read indicator
      expect(find.text('Tap to read'), findsOneWidget);
    });

    testWidgets('should display media attachments in received messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceivedMessageCard(
              message: testMessageWithMedia,
              friends: friends,
            ),
          ),
        ),
      );

      // Verify message content is displayed
      expect(find.text('This is a received message with media'), findsOneWidget);
      
      // Verify attachments section is displayed
      expect(find.text('Attachments:'), findsOneWidget);
      
      // Verify horizontal scroll view for media is present
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}