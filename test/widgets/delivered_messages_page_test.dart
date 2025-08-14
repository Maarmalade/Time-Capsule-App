import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:time_capsule/pages/scheduled_messages/delivered_messages_page.dart';
import 'package:time_capsule/services/scheduled_message_service.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/scheduled_message_model.dart';
import 'package:time_capsule/models/user_profile.dart';

import 'scheduled_messages_page_test.mocks.dart';

@GenerateMocks([ScheduledMessageService, FriendService, FirebaseAuth, User])
void main() {
  group('DeliveredMessagesPage', () {
    late MockScheduledMessageService mockMessageService;
    late MockFriendService mockFriendService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockMessageService = MockScheduledMessageService();
      mockFriendService = MockFriendService();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Setup default auth mock
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
    });

    Widget createTestWidget() {
      return MaterialApp(home: const DeliveredMessagesPage());
    }

    testWidgets('displays loading state initially', (
      WidgetTester tester,
    ) async {
      // Setup mocks to delay response
      when(mockMessageService.getReceivedMessages(any)).thenAnswer(
        (_) async => Future.delayed(
          const Duration(seconds: 1),
          () => <ScheduledMessage>[],
        ),
      );
      when(mockFriendService.getFriends()).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(seconds: 1), () => <UserProfile>[]),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays search bar and filter button', (
      WidgetTester tester,
    ) async {
      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => <ScheduledMessage>[]);
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Search messages...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('displays empty state when no messages', (
      WidgetTester tester,
    ) async {
      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => <ScheduledMessage>[]);
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Delivered Messages'), findsOneWidget);
      expect(
        find.text(
          'Messages sent to you will appear here when they are delivered',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('displays delivered messages list', (
      WidgetTester tester,
    ) async {
      final message1 = ScheduledMessage(
        id: 'msg1',
        senderId: 'friend-id',
        recipientId: 'test-user-id',
        textContent: 'Hello from friend!',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final message2 = ScheduledMessage(
        id: 'msg2',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent: 'Message to myself',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final friend = UserProfile(
        id: 'friend-id',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
      );

      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => [message1, message2]);
      when(mockFriendService.getFriends()).thenAnswer((_) async => [friend]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('From: testfriend'), findsOneWidget);
      expect(find.text('From: Myself'), findsOneWidget);
      expect(find.text('Hello from friend!'), findsOneWidget);
      expect(find.text('Message to myself'), findsOneWidget);
      expect(find.text('Tap to read full message'), findsNWidgets(2));
    });

    testWidgets('filters messages by search query', (
      WidgetTester tester,
    ) async {
      final message1 = ScheduledMessage(
        id: 'msg1',
        senderId: 'friend-id',
        recipientId: 'test-user-id',
        textContent: 'Hello from friend!',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final message2 = ScheduledMessage(
        id: 'msg2',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent: 'Important reminder',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final friend = UserProfile(
        id: 'friend-id',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
      );

      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => [message1, message2]);
      when(mockFriendService.getFriends()).thenAnswer((_) async => [friend]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially both messages should be visible
      expect(find.text('Hello from friend!'), findsOneWidget);
      expect(find.text('Important reminder'), findsOneWidget);

      // Search for "friend"
      await tester.enterText(find.byType(TextField), 'friend');
      await tester.pumpAndSettle();

      // Only the message from friend should be visible
      expect(find.text('Hello from friend!'), findsOneWidget);
      expect(find.text('Important reminder'), findsNothing);
    });

    testWidgets('shows filter dialog when filter button is tapped', (
      WidgetTester tester,
    ) async {
      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => <ScheduledMessage>[]);
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('Filter Messages'), findsOneWidget);
      expect(find.text('All Messages'), findsOneWidget);
      expect(find.text('From Myself'), findsOneWidget);
      expect(find.text('From Friends'), findsOneWidget);
    });

    testWidgets('filters messages by sender type', (WidgetTester tester) async {
      final message1 = ScheduledMessage(
        id: 'msg1',
        senderId: 'friend-id',
        recipientId: 'test-user-id',
        textContent: 'Hello from friend!',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final message2 = ScheduledMessage(
        id: 'msg2',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent: 'Message to myself',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final friend = UserProfile(
        id: 'friend-id',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
      );

      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => [message1, message2]);
      when(mockFriendService.getFriends()).thenAnswer((_) async => [friend]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially both messages should be visible
      expect(find.text('Hello from friend!'), findsOneWidget);
      expect(find.text('Message to myself'), findsOneWidget);

      // Open filter dialog and select "From Myself"
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('From Myself'));
      await tester.pumpAndSettle();

      // Only self message should be visible
      expect(find.text('Hello from friend!'), findsNothing);
      expect(find.text('Message to myself'), findsOneWidget);
    });

    testWidgets('shows message details dialog when message is tapped', (
      WidgetTester tester,
    ) async {
      final message = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent:
            'Detailed message content for testing the dialog functionality',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => [message]);
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on the message card
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Message from Myself'), findsOneWidget);
      expect(
        find.text(
          'Detailed message content for testing the dialog functionality',
        ),
        findsOneWidget,
      );
      expect(find.text('Message Details'), findsOneWidget);
      expect(find.text('Originally scheduled for'), findsOneWidget);
      expect(find.text('Delivered at'), findsOneWidget);
      expect(find.text('Created on'), findsOneWidget);
    });

    testWidgets('displays error state when loading fails', (
      WidgetTester tester,
    ) async {
      when(
        mockMessageService.getReceivedMessages(any),
      ).thenThrow(Exception('Network error'));
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error Loading Messages'), findsOneWidget);
      expect(find.text('Exception: Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows video indicator for messages with video', (
      WidgetTester tester,
    ) async {
      final messageWithVideo = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent: 'Message with video',
        videoUrl: 'https://example.com/video.mp4',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      when(
        mockMessageService.getReceivedMessages(any),
      ).thenAnswer((_) async => [messageWithVideo]);
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.text('Video attached'), findsOneWidget);
    });
  });

  group('DeliveredMessageCard', () {
    testWidgets('displays message content and sender info', (
      WidgetTester tester,
    ) async {
      final message = ScheduledMessage(
        id: 'msg1',
        senderId: 'friend-id',
        recipientId: 'test-user-id',
        textContent: 'Test message content',
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
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveredMessageCard(
              message: message,
              senderProfile: sender,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('From: testfriend'), findsOneWidget);
      expect(find.text('Test message content'), findsOneWidget);
      expect(find.text('Tap to read full message'), findsOneWidget);
    });

    testWidgets('truncates long message content', (WidgetTester tester) async {
      final longMessage = ScheduledMessage(
        id: 'msg1',
        senderId: 'test-user-id',
        recipientId: 'test-user-id',
        textContent:
            'This is a very long message content that should be truncated when displayed in the card preview because it exceeds the maximum length allowed for preview display',
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveredMessageCard(
              message: longMessage,
              senderProfile: null,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should find truncated text with ellipsis
      expect(find.textContaining('...'), findsOneWidget);
    });
  });

  group('MessageDetailsDialog', () {
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
                  builder: (context) => MessageDetailsDialog(
                    message: message,
                    senderProfile: null,
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

      expect(find.text('Message from Myself'), findsOneWidget);
      expect(
        find.text('Full message content for detailed view'),
        findsOneWidget,
      );
      expect(find.text('Message Details'), findsOneWidget);
      expect(find.text('Originally scheduled for'), findsOneWidget);
      expect(find.text('Delivered at'), findsOneWidget);
      expect(find.text('Created on'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
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
                  builder: (context) => MessageDetailsDialog(
                    message: messageWithVideo,
                    senderProfile: null,
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

      expect(find.text('Video Message'), findsOneWidget);
      expect(find.text('Tap to play'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });
  });
}
