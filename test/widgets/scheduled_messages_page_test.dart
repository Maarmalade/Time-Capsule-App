import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:time_capsule/pages/scheduled_messages/scheduled_messages_page.dart';
import 'package:time_capsule/services/scheduled_message_service.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/scheduled_message_model.dart';
import 'package:time_capsule/models/user_profile.dart';

// Generate mocks
@GenerateMocks([ScheduledMessageService, FriendService, FirebaseAuth, User])
void main() {
  group('ScheduledMessagesPage', () {
    testWidgets('displays loading state initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ScheduledMessagesPage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays tabs after loading', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScheduledMessagesPage()));

      // Wait for the initial loading to complete
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('displays empty state for scheduled messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ScheduledMessagesPage()));

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('No Scheduled Messages'), findsOneWidget);
      expect(
        find.text(
          'Create your first scheduled message to send to yourself or friends in the future',
        ),
        findsOneWidget,
      );
      expect(find.text('Create Message'), findsOneWidget);
    });

    testWidgets('displays empty state for received messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ScheduledMessagesPage()));

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 2));

      // Switch to received tab
      await tester.tap(find.text('Received'));
      await tester.pumpAndSettle();

      expect(find.text('No Received Messages'), findsOneWidget);
      expect(
        find.text(
          'Messages sent to you will appear here when they are delivered',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows create message dialog when FAB is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ScheduledMessagesPage()));

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Create Scheduled Message'), findsOneWidget);
      expect(find.text('Send to:'), findsOneWidget);
      expect(find.text('Message:'), findsOneWidget);
      expect(find.text('Delivery Date & Time:'), findsOneWidget);
    });
  });

  group('CreateScheduledMessageDialog', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => CreateScheduledMessageDialog(
                  friends: [],
                  onMessageCreated: () {},
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays create message form', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Scheduled Message'), findsOneWidget);
      expect(find.text('Send to:'), findsOneWidget);
      expect(find.text('Message:'), findsOneWidget);
      expect(find.text('Delivery Date & Time:'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('shows validation error for empty message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to schedule without entering message
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a message'), findsOneWidget);
    });

    testWidgets('shows error for missing date/time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter message but no date/time
      await tester.enterText(find.byType(TextFormField), 'Test message');
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please select a delivery date and time'),
        findsOneWidget,
      );
    });

    testWidgets('includes friends in recipient dropdown', (
      WidgetTester tester,
    ) async {
      final friends = [
        UserProfile(
          id: 'friend1',
          username: 'friend1',
          email: 'friend1@test.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'friend2',
          username: 'friend2',
          email: 'friend2@test.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => CreateScheduledMessageDialog(
                    friends: friends,
                    onMessageCreated: () {},
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<UserProfile?>));
      await tester.pumpAndSettle();

      expect(find.text('Myself'), findsOneWidget);
      expect(find.text('friend1'), findsOneWidget);
      expect(find.text('friend2'), findsOneWidget);
    });
  });

  group('ScheduledMessageCard', () {
    testWidgets('displays message content and recipient info', (
      WidgetTester tester,
    ) async {
      final message = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'friend-id',
        textContent: 'Test message content',
        scheduledFor: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      final friend = UserProfile(
        id: 'friend-id',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: message,
              friends: [friend],
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('To: testfriend'), findsOneWidget);
      expect(find.text('Test message content'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('truncates long message content', (WidgetTester tester) async {
      final longMessage = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent:
            'This is a very long message content that should be truncated when displayed in the card preview because it exceeds the maximum length allowed for preview display',
        scheduledFor: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduledMessageCard(
              message: longMessage,
              friends: [],
              onCancel: () {},
            ),
          ),
        ),
      );

      // Should find truncated text with ellipsis
      expect(find.textContaining('...'), findsOneWidget);
    });
  });

  group('ReceivedMessageCard', () {
    testWidgets('displays message content and sender info', (
      WidgetTester tester,
    ) async {
      final message = ScheduledMessage(
        id: 'msg1',
        senderId: 'friend-id',
        recipientId: 'test-user-id',
        textContent: 'Test received message',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final sender = UserProfile(
        id: 'friend-id',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceivedMessageCard(message: message, friends: [sender]),
          ),
        ),
      );

      expect(find.text('From: testfriend'), findsOneWidget);
      expect(find.text('Test received message'), findsOneWidget);
      expect(find.text('Tap to read'), findsOneWidget);
    });

    testWidgets('shows message view dialog when tapped', (
      WidgetTester tester,
    ) async {
      final message = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent: 'Test message from myself',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceivedMessageCard(message: message, friends: []),
          ),
        ),
      );

      // Tap on the message card
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('Message from Myself'), findsOneWidget);
      expect(find.text('Test message from myself'), findsOneWidget);
      expect(find.text('Message Details'), findsOneWidget);
    });
  });

  group('MessageViewDialog', () {
    testWidgets('displays full message content and metadata', (
      WidgetTester tester,
    ) async {
      final message = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent: 'Full message content for detailed view',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) =>
                      MessageViewDialog(message: message, friends: []),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Message from Myself'), findsOneWidget);
      expect(
        find.text('Full message content for detailed view'),
        findsOneWidget,
      );
      expect(find.text('Message Details'), findsOneWidget);
      expect(find.text('Scheduled for'), findsOneWidget);
      expect(find.text('Delivered at'), findsOneWidget);
      expect(find.text('Created on'), findsOneWidget);
    });

    testWidgets('shows video section when message has video', (
      WidgetTester tester,
    ) async {
      final messageWithVideo = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent: 'Message with video attachment',
        videoUrl: 'https://example.com/video.mp4',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) =>
                      MessageViewDialog(message: messageWithVideo, friends: []),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Video Message'), findsOneWidget);
      expect(find.text('Tap to play'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });
  });
}
