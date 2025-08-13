import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:time_capsule/pages/friends/friend_requests_page.dart';
import 'package:time_capsule/models/friend_request_model.dart';
import 'package:time_capsule/services/friend_service.dart';

import 'friend_requests_page_test.mocks.dart';

// Generate mocks
@GenerateMocks([FriendService])

void main() {
  group('FriendRequestsPage', () {
    late MockFriendService mockFriendService;

    setUp(() {
      mockFriendService = MockFriendService();
    });

    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Mock service to delay response
      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return <FriendRequest>[];
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      // Should display loading state
      expect(find.text('Friend Requests'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading friend requests...'), findsOneWidget);
    });

    testWidgets('displays empty state when no requests', (WidgetTester tester) async {
      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => <FriendRequest>[]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display empty state
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.text('No Friend Requests'), findsOneWidget);
      expect(find.text('You don\'t have any pending friend requests at the moment.'), findsOneWidget);
      expect(find.text('Find Friends'), findsOneWidget);
    });

    testWidgets('displays error state when loading fails', (WidgetTester tester) async {
      when(mockFriendService.getFriendRequests())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error Loading Requests'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('displays friend requests correctly', (WidgetTester tester) async {
      final testRequests = [
        FriendRequest(
          id: 'request1',
          senderId: 'sender1',
          receiverId: 'receiver1',
          senderUsername: 'alice',
          senderProfilePictureUrl: null,
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        FriendRequest(
          id: 'request2',
          senderId: 'sender2',
          receiverId: 'receiver1',
          senderUsername: 'bob',
          senderProfilePictureUrl: null,
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => testRequests);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display request count
      expect(find.text('2 pending requests'), findsOneWidget);
      
      // Should display friend request cards
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);
      expect(find.text('Accept'), findsNWidgets(2));
      expect(find.text('Decline'), findsNWidgets(2));
    });

    testWidgets('filters out non-pending requests', (WidgetTester tester) async {
      final testRequests = [
        FriendRequest(
          id: 'request1',
          senderId: 'sender1',
          receiverId: 'receiver1',
          senderUsername: 'alice',
          senderProfilePictureUrl: null,
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now(),
        ),
        FriendRequest(
          id: 'request2',
          senderId: 'sender2',
          receiverId: 'receiver1',
          senderUsername: 'bob',
          senderProfilePictureUrl: null,
          status: FriendRequestStatus.accepted,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => testRequests);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should only display pending request
      expect(find.text('1 pending request'), findsOneWidget);
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('bob'), findsNothing);
    });

    testWidgets('accepts friend request successfully', (WidgetTester tester) async {
      final testRequest = FriendRequest(
        id: 'request1',
        senderId: 'sender1',
        receiverId: 'receiver1',
        senderUsername: 'alice',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => [testRequest]);
      when(mockFriendService.respondToFriendRequest('request1', true))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: const FriendRequestsPage(),
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Accept button
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('You are now friends with alice'), findsOneWidget);
      expect(find.text('View Friends'), findsOneWidget);
      
      // Request should be removed from list
      expect(find.text('alice'), findsNothing);
      expect(find.text('No Friend Requests'), findsOneWidget);
    });

    testWidgets('declines friend request successfully', (WidgetTester tester) async {
      final testRequest = FriendRequest(
        id: 'request1',
        senderId: 'sender1',
        receiverId: 'receiver1',
        senderUsername: 'alice',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => [testRequest]);
      when(mockFriendService.respondToFriendRequest('request1', false))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: const FriendRequestsPage(),
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Decline button
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      // Should show decline message
      expect(find.text('Declined friend request from alice'), findsOneWidget);
      
      // Request should be removed from list
      expect(find.text('alice'), findsNothing);
      expect(find.text('No Friend Requests'), findsOneWidget);
    });

    testWidgets('handles accept request error', (WidgetTester tester) async {
      final testRequest = FriendRequest(
        id: 'request1',
        senderId: 'sender1',
        receiverId: 'receiver1',
        senderUsername: 'alice',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => [testRequest]);
      when(mockFriendService.respondToFriendRequest('request1', true))
          .thenThrow(Exception('Accept failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: const FriendRequestsPage(),
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Accept button
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Accept failed'), findsOneWidget);
      
      // Request should still be in list
      expect(find.text('alice'), findsOneWidget);
    });

    testWidgets('shows loading state during request processing', (WidgetTester tester) async {
      final testRequest = FriendRequest(
        id: 'request1',
        senderId: 'sender1',
        receiverId: 'receiver1',
        senderUsername: 'alice',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => [testRequest]);
      when(mockFriendService.respondToFriendRequest('request1', true))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Accept button
      await tester.tap(find.text('Accept'));
      await tester.pump();

      // Should show loading indicators in the card
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('refreshes requests when refresh button is tapped', (WidgetTester tester) async {
      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => <FriendRequest>[]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Should call getFriendRequests again
      verify(mockFriendService.getFriendRequests()).called(2);
    });

    testWidgets('supports pull to refresh', (WidgetTester tester) async {
      final testRequest = FriendRequest(
        id: 'request1',
        senderId: 'sender1',
        receiverId: 'receiver1',
        senderUsername: 'alice',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => [testRequest]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();

      // Should call getFriendRequests again
      verify(mockFriendService.getFriendRequests()).called(2);
    });

    testWidgets('navigates back when Find Friends is tapped', (WidgetTester tester) async {
      when(mockFriendService.getFriendRequests())
          .thenAnswer((_) async => <FriendRequest>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: Center(child: Text('Friends Page')),
          ),
          routes: {
            '/requests': (context) => const FriendRequestsPage(),
          },
        ),
      );

      // Navigate to requests page
      await tester.tap(find.text('Friends Page'));
      Navigator.of(tester.element(find.text('Friends Page'))).pushNamed('/requests');
      await tester.pumpAndSettle();

      // Tap Find Friends button
      await tester.tap(find.text('Find Friends'));
      await tester.pumpAndSettle();

      // Should navigate back
      expect(find.text('Friends Page'), findsOneWidget);
    });
  });
}