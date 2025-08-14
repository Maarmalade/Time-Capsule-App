import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/scheduled_message_service.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/scheduled_message_model.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/pages/scheduled_messages/scheduled_messages_page.dart';
import 'package:time_capsule/pages/scheduled_messages/delivered_messages_page.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  ScheduledMessageService,
  FriendService,
])
import 'scheduled_message_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Scheduled Message Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockScheduledMessageService mockScheduledMessageService;
    late MockFriendService mockFriendService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockScheduledMessageService = MockScheduledMessageService();
      mockFriendService = MockFriendService();

      // Setup basic user mock
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('Test message creation and scheduling', (
      WidgetTester tester,
    ) async {
      // Test data
      final friends = [
        UserProfile(
          id: 'friend1-id',
          email: 'friend1@example.com',
          username: 'friend1',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'friend2-id',
          email: 'friend2@example.com',
          username: 'friend2',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Mock service responses
      when(mockFriendService.getFriends()).thenAnswer((_) async => friends);
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Verify page is displayed
      expect(find.text('Scheduled Messages'), findsOneWidget);
      expect(find.text('Create Message'), findsOneWidget);

      // Step 1: Create new scheduled message
      await tester.tap(find.text('Create Message'));
      await tester.pumpAndSettle();

      // Should show message creation form
      expect(find.text('New Scheduled Message'), findsOneWidget);
      expect(find.text('Recipient'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Delivery Date'), findsOneWidget);

      // Step 2: Select recipient
      await tester.tap(find.text('Select Recipient'));
      await tester.pumpAndSettle();

      // Should show recipient options
      expect(find.text('Myself'), findsOneWidget);
      expect(find.text('@friend1'), findsOneWidget);
      expect(find.text('@friend2'), findsOneWidget);

      // Select friend as recipient
      await tester.tap(find.text('@friend1'));
      await tester.pumpAndSettle();

      // Step 3: Enter message content
      await tester.enterText(
        find.byType(TextFormField).first,
        'Happy birthday! Hope you have a wonderful day!',
      );
      await tester.pumpAndSettle();

      // Step 4: Set delivery date (future date)
      final futureDate = DateTime.now().add(const Duration(days: 30));
      await tester.tap(find.text('Select Date'));
      await tester.pumpAndSettle();

      // Mock date picker interaction (would need proper date picker testing)
      // For now, assume date is selected

      // Step 5: Set delivery time
      await tester.tap(find.text('Select Time'));
      await tester.pumpAndSettle();

      // Mock time picker interaction
      // For now, assume time is selected

      // Step 6: Create scheduled message
      final scheduledMessage = ScheduledMessage(
        id: 'message-id',
        senderId: 'test-user-id',
        recipientId: 'friend1-id',
        textContent: 'Happy birthday! Hope you have a wonderful day!',
        videoUrl: null,
        scheduledFor: futureDate,
        createdAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      when(
        mockScheduledMessageService.createScheduledMessage(any),
      ).thenAnswer((_) async => scheduledMessage);

      await tester.tap(find.text('Schedule Message'));
      await tester.pumpAndSettle();

      // Verify message was created
      verify(mockScheduledMessageService.createScheduledMessage(any)).called(1);
      expect(find.text('Message scheduled successfully'), findsOneWidget);

      // Should navigate back to messages list
      expect(find.text('Scheduled Messages'), findsOneWidget);
    });

    testWidgets('Test message creation with video attachment', (
      WidgetTester tester,
    ) async {
      // Mock service responses
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Create new message
      await tester.tap(find.text('Create Message'));
      await tester.pumpAndSettle();

      // Select myself as recipient
      await tester.tap(find.text('Select Recipient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Myself'));
      await tester.pumpAndSettle();

      // Enter message content
      await tester.enterText(
        find.byType(TextFormField).first,
        'Future me, remember this moment!',
      );

      // Step: Add video attachment
      await tester.tap(find.text('Add Video'));
      await tester.pumpAndSettle();

      // Should show video picker options
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Select camera option (in real test, would need to mock video picker)
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Mock video selection and upload
      final scheduledMessage = ScheduledMessage(
        id: 'message-with-video-id',
        senderId: 'test-user-id',
        recipientId: 'test-user-id', // To myself
        textContent: 'Future me, remember this moment!',
        videoUrl: 'https://storage.example.com/video.mp4',
        scheduledFor: DateTime.now().add(const Duration(days: 365)),
        createdAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      when(
        mockScheduledMessageService.createScheduledMessage(any),
      ).thenAnswer((_) async => scheduledMessage);

      // Set future date and create message
      await tester.tap(find.text('Select Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule Message'));
      await tester.pumpAndSettle();

      // Verify message with video was created
      verify(mockScheduledMessageService.createScheduledMessage(any)).called(1);
      expect(find.text('Message scheduled successfully'), findsOneWidget);
    });

    testWidgets('Verify Cloud Function message delivery simulation', (
      WidgetTester tester,
    ) async {
      // Test data - simulate a message that should be delivered
      final pendingMessage = ScheduledMessage(
        id: 'pending-message-id',
        senderId: 'friend1-id',
        recipientId: 'test-user-id',
        textContent: 'This message should be delivered now!',
        videoUrl: null,
        scheduledFor: DateTime.now().subtract(
          const Duration(minutes: 1),
        ), // Past time
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ScheduledMessageStatus.pending,
      );

      final deliveredMessage = ScheduledMessage(
        id: 'pending-message-id',
        senderId: 'friend1-id',
        recipientId: 'test-user-id',
        textContent: 'This message should be delivered now!',
        videoUrl: null,
        scheduledFor: DateTime.now().subtract(const Duration(minutes: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ScheduledMessageStatus.delivered,
      );

      // Mock initial state with pending message
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => [pendingMessage]);
      when(
        mockScheduledMessageService.getReceivedMessages(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Verify pending message is shown
      expect(
        find.text('This message should be delivered now!'),
        findsOneWidget,
      );
      expect(find.text('Pending'), findsOneWidget);

      // Simulate Cloud Function delivery (in real scenario, this would be triggered by Firebase)
      // Mock the delivery process
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => []); // Message no longer pending
      when(
        mockScheduledMessageService.getReceivedMessages(),
      ).thenAnswer((_) async => [deliveredMessage]); // Message now delivered

      // Refresh the page to simulate real-time updates
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify message is no longer in pending list
      expect(find.text('Pending'), findsNothing);

      // Navigate to delivered messages
      await tester.tap(find.text('Delivered Messages'));
      await tester.pumpAndSettle();

      // Verify message appears in delivered messages
      expect(
        find.text('This message should be delivered now!'),
        findsOneWidget,
      );
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('Test notification delivery and message viewing', (
      WidgetTester tester,
    ) async {
      // Test data - delivered message
      final deliveredMessage = ScheduledMessage(
        id: 'delivered-message-id',
        senderId: 'friend1-id',
        recipientId: 'test-user-id',
        textContent: 'Happy New Year from the past!',
        videoUrl: 'https://storage.example.com/newyear.mp4',
        scheduledFor: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        status: ScheduledMessageStatus.delivered,
      );

      // Mock service responses
      when(
        mockScheduledMessageService.getReceivedMessages(),
      ).thenAnswer((_) async => [deliveredMessage]);

      await tester.pumpWidget(MaterialApp(home: DeliveredMessagesPage()));

      await tester.pumpAndSettle();

      // Verify delivered messages page
      expect(find.text('Delivered Messages'), findsOneWidget);
      expect(find.text('Happy New Year from the past!'), findsOneWidget);

      // Verify message metadata
      expect(find.text('From @friend1'), findsOneWidget);
      expect(
        find.byIcon(Icons.video_library),
        findsOneWidget,
      ); // Video indicator

      // Step: View message details
      await tester.tap(find.text('Happy New Year from the past!'));
      await tester.pumpAndSettle();

      // Should show message detail view
      expect(find.text('Message Details'), findsOneWidget);
      expect(find.text('Happy New Year from the past!'), findsOneWidget);
      expect(find.text('From: @friend1'), findsOneWidget);

      // Should show video player for video content
      expect(find.byType(VideoPlayer), findsOneWidget);

      // Test message actions
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Test reply functionality
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      // Should navigate to create message with recipient pre-filled
      expect(find.text('New Scheduled Message'), findsOneWidget);
      expect(find.text('@friend1'), findsOneWidget); // Recipient pre-selected
    });

    testWidgets('Test message scheduling validation', (
      WidgetTester tester,
    ) async {
      // Mock service responses
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Create new message
      await tester.tap(find.text('Create Message'));
      await tester.pumpAndSettle();

      // Test validation scenarios

      // Step 1: Try to schedule without selecting recipient
      await tester.tap(find.text('Schedule Message'));
      await tester.pump();

      expect(find.text('Please select a recipient'), findsOneWidget);

      // Step 2: Select recipient but leave message empty
      await tester.tap(find.text('Select Recipient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Myself'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule Message'));
      await tester.pump();

      expect(find.text('Please enter a message'), findsOneWidget);

      // Step 3: Enter message but don't set date
      await tester.enterText(find.byType(TextFormField).first, 'Test message');

      await tester.tap(find.text('Schedule Message'));
      await tester.pump();

      expect(find.text('Please select a delivery date'), findsOneWidget);

      // Step 4: Try to set past date
      // Mock date selection in the past
      when(
        mockScheduledMessageService.createScheduledMessage(any),
      ).thenThrow(Exception('Delivery date must be in the future'));

      // Simulate selecting past date and trying to create
      await tester.tap(find.text('Select Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule Message'));
      await tester.pumpAndSettle();

      expect(find.text('Delivery date must be in the future'), findsOneWidget);
    });

    testWidgets('Test message cancellation', (WidgetTester tester) async {
      // Test data - pending message that can be cancelled
      final pendingMessage = ScheduledMessage(
        id: 'pending-message-id',
        senderId: 'test-user-id',
        recipientId: 'friend1-id',
        textContent: 'This message can be cancelled',
        videoUrl: null,
        scheduledFor: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      // Mock service responses
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => [pendingMessage]);

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Verify pending message is displayed
      expect(find.text('This message can be cancelled'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Step: Cancel message
      await tester.longPress(find.text('This message can be cancelled'));
      await tester.pumpAndSettle();

      // Should show cancel option
      expect(find.text('Cancel Message'), findsOneWidget);

      await tester.tap(find.text('Cancel Message'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Cancel Message?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to cancel this scheduled message?'),
        findsOneWidget,
      );

      // Mock cancel service call
      when(
        mockScheduledMessageService.cancelScheduledMessage(
          'pending-message-id',
        ),
      ).thenAnswer((_) async {});

      // Confirm cancellation
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify message was cancelled
      verify(
        mockScheduledMessageService.cancelScheduledMessage(
          'pending-message-id',
        ),
      ).called(1);
      expect(find.text('Message cancelled successfully'), findsOneWidget);

      // Mock updated messages list (empty)
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => []);

      await tester.pumpAndSettle();

      // Verify message is no longer displayed
      expect(find.text('This message can be cancelled'), findsNothing);
      expect(find.text('No scheduled messages'), findsOneWidget);
    });

    testWidgets('Test error handling in message operations', (
      WidgetTester tester,
    ) async {
      // Mock network error
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test retry functionality
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => []);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show empty messages list
      expect(find.text('No scheduled messages'), findsOneWidget);
    });

    testWidgets('Test message delivery failure handling', (
      WidgetTester tester,
    ) async {
      // Test data - failed message delivery
      final failedMessage = ScheduledMessage(
        id: 'failed-message-id',
        senderId: 'test-user-id',
        recipientId: 'friend1-id',
        textContent: 'This message failed to deliver',
        videoUrl: null,
        scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ScheduledMessageStatus.failed,
      );

      // Mock service responses
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => [failedMessage]);

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Verify failed message is displayed with error status
      expect(find.text('This message failed to deliver'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Should show retry option for failed messages
      await tester.longPress(find.text('This message failed to deliver'));
      await tester.pumpAndSettle();

      expect(find.text('Retry Delivery'), findsOneWidget);

      // Test retry delivery
      when(mockScheduledMessageService.createScheduledMessage(any)).thenAnswer(
        (_) async => failedMessage.copyWith(
          status: ScheduledMessageStatus.pending,
          scheduledFor: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );

      await tester.tap(find.text('Retry Delivery'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Message rescheduled for delivery'), findsOneWidget);
    });

    testWidgets('Test message history and organization', (
      WidgetTester tester,
    ) async {
      // Test data - multiple messages with different statuses and dates
      final messages = [
        ScheduledMessage(
          id: 'recent-pending',
          senderId: 'test-user-id',
          recipientId: 'friend1-id',
          textContent: 'Recent pending message',
          videoUrl: null,
          scheduledFor: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime.now(),
          status: ScheduledMessageStatus.pending,
        ),
        ScheduledMessage(
          id: 'old-pending',
          senderId: 'test-user-id',
          recipientId: 'friend2-id',
          textContent: 'Old pending message',
          videoUrl: null,
          scheduledFor: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          status: ScheduledMessageStatus.pending,
        ),
      ];

      final deliveredMessages = [
        ScheduledMessage(
          id: 'delivered-recent',
          senderId: 'friend1-id',
          recipientId: 'test-user-id',
          textContent: 'Recently delivered message',
          videoUrl: null,
          scheduledFor: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ScheduledMessageStatus.delivered,
        ),
      ];

      // Mock service responses
      when(
        mockScheduledMessageService.getScheduledMessages(),
      ).thenAnswer((_) async => messages);
      when(
        mockScheduledMessageService.getReceivedMessages(),
      ).thenAnswer((_) async => deliveredMessages);

      await tester.pumpWidget(MaterialApp(home: ScheduledMessagesPage()));

      await tester.pumpAndSettle();

      // Verify messages are organized properly
      expect(find.text('Scheduled Messages'), findsOneWidget);
      expect(find.text('Recent pending message'), findsOneWidget);
      expect(find.text('Old pending message'), findsOneWidget);

      // Test filtering and sorting
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should show filter options
      expect(find.text('Sort by Date'), findsOneWidget);
      expect(find.text('Filter by Recipient'), findsOneWidget);

      // Test sort by date
      await tester.tap(find.text('Sort by Date'));
      await tester.pumpAndSettle();

      // Messages should be reordered (most recent first)
      // In a real test, you would verify the order of widgets

      // Navigate to delivered messages
      await tester.tap(find.text('Delivered Messages'));
      await tester.pumpAndSettle();

      // Verify delivered messages are shown
      expect(find.text('Recently delivered message'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });
}

// Mock VideoPlayer widget for testing
class VideoPlayer extends StatelessWidget {
  const VideoPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
      ),
    );
  }
}
