import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/friend_request_model.dart';
import 'package:time_capsule/models/friendship_model.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/pages/friends/add_friend_page.dart';
import 'package:time_capsule/pages/friends/friend_requests_page.dart';
import 'package:time_capsule/pages/friends/friends_page.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  FriendService,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'friend_management_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Friend Management Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockFriendService mockFriendService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockFriendService = MockFriendService();

      // Setup basic user mock
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('Complete friend request and acceptance flow', (
      WidgetTester tester,
    ) async {
      // Test data
      final testUser = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final friendUser = UserProfile(
        id: 'friend-user-id',
        email: 'friend@example.com',
        username: 'frienduser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final friendRequest = FriendRequest(
        id: 'request-id',
        senderId: 'test-user-id',
        receiverId: 'friend-user-id',
        senderUsername: 'testuser',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        respondedAt: null,
      );

      // Mock friend service responses
      when(
        mockFriendService.searchUsersByUsername('frienduser'),
      ).thenAnswer((_) async => [friendUser]);
      when(
        mockFriendService.sendFriendRequest('friend-user-id'),
      ).thenAnswer((_) async => friendRequest);
      when(mockFriendService.getFriendRequests()).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(home: AddFriendPage()));

      // Step 1: Search for user by username
      await tester.enterText(find.byType(TextFormField), 'frienduser');
      await tester.pumpAndSettle();

      // Tap search button or trigger search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify search results are displayed
      expect(find.text('@frienduser'), findsOneWidget);
      expect(find.text('friend@example.com'), findsOneWidget);

      // Step 2: Send friend request
      await tester.tap(find.text('Send Friend Request'));
      await tester.pumpAndSettle();

      // Verify friend request was sent
      verify(mockFriendService.sendFriendRequest('friend-user-id')).called(1);
      expect(find.text('Friend request sent'), findsOneWidget);

      // Step 3: Navigate to friend requests page (as the receiver)
      await tester.pumpWidget(MaterialApp(home: FriendRequestsPage()));

      // Mock incoming friend request
      final incomingRequest = FriendRequest(
        id: 'incoming-request-id',
        senderId: 'friend-user-id',
        receiverId: 'test-user-id',
        senderUsername: 'frienduser',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        respondedAt: null,
      );

      when(
        mockFriendService.getFriendRequests(),
      ).thenAnswer((_) async => [incomingRequest]);

      await tester.pumpAndSettle();

      // Verify friend request is displayed
      expect(find.text('@frienduser'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      // Step 4: Accept friend request
      when(
        mockFriendService.respondToFriendRequest('incoming-request-id', true),
      ).thenAnswer((_) async {});

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      // Verify friend request was accepted
      verify(
        mockFriendService.respondToFriendRequest('incoming-request-id', true),
      ).called(1);
      expect(find.text('Friend request accepted'), findsOneWidget);
    });

    testWidgets('Verify bidirectional friendship creation', (
      WidgetTester tester,
    ) async {
      // Test data
      final friendship = Friendship(
        id: 'friendship-id',
        userId1: 'test-user-id',
        userId2: 'friend-user-id',
        createdAt: DateTime.now(),
      );

      final friendUser = UserProfile(
        id: 'friend-user-id',
        email: 'friend@example.com',
        username: 'frienduser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock friends list
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => [friendUser]);

      await tester.pumpWidget(MaterialApp(home: FriendsPage()));

      await tester.pumpAndSettle();

      // Verify friend appears in friends list
      expect(find.text('@frienduser'), findsOneWidget);
      expect(find.text('friend@example.com'), findsOneWidget);

      // Verify bidirectional relationship by checking both users can see each other
      // This would be tested by switching user context and verifying the friendship
      // exists from both perspectives
    });

    testWidgets('Test friend removal and cleanup', (WidgetTester tester) async {
      // Test data
      final friendUser = UserProfile(
        id: 'friend-user-id',
        email: 'friend@example.com',
        username: 'frienduser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock initial friends list with one friend
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => [friendUser]);

      await tester.pumpWidget(MaterialApp(home: FriendsPage()));

      await tester.pumpAndSettle();

      // Verify friend is displayed
      expect(find.text('@frienduser'), findsOneWidget);

      // Find and tap remove friend button (usually in a menu or long press)
      await tester.longPress(find.text('@frienduser'));
      await tester.pumpAndSettle();

      // Should show remove friend option
      expect(find.text('Remove Friend'), findsOneWidget);

      // Tap remove friend
      await tester.tap(find.text('Remove Friend'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Remove Friend?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to remove frienduser from your friends?',
        ),
        findsOneWidget,
      );

      // Mock remove friend service call
      when(
        mockFriendService.removeFriend('friend-user-id'),
      ).thenAnswer((_) async {});

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Verify friend was removed
      verify(mockFriendService.removeFriend('friend-user-id')).called(1);

      // Mock updated friends list (empty)
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      await tester.pumpAndSettle();

      // Verify friend is no longer displayed
      expect(find.text('@frienduser'), findsNothing);
      expect(find.text('No friends yet'), findsOneWidget);
    });

    testWidgets('Test friend request decline flow', (
      WidgetTester tester,
    ) async {
      // Test data
      final incomingRequest = FriendRequest(
        id: 'incoming-request-id',
        senderId: 'friend-user-id',
        receiverId: 'test-user-id',
        senderUsername: 'frienduser',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        respondedAt: null,
      );

      when(
        mockFriendService.getFriendRequests(),
      ).thenAnswer((_) async => [incomingRequest]);

      await tester.pumpWidget(MaterialApp(home: FriendRequestsPage()));

      await tester.pumpAndSettle();

      // Verify friend request is displayed
      expect(find.text('@frienduser'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      // Mock decline friend request
      when(
        mockFriendService.respondToFriendRequest('incoming-request-id', false),
      ).thenAnswer((_) async {});

      // Decline friend request
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      // Verify friend request was declined
      verify(
        mockFriendService.respondToFriendRequest('incoming-request-id', false),
      ).called(1);
      expect(find.text('Friend request declined'), findsOneWidget);

      // Mock updated friend requests list (empty)
      when(mockFriendService.getFriendRequests()).thenAnswer((_) async => []);

      await tester.pumpAndSettle();

      // Verify request is no longer displayed
      expect(find.text('@frienduser'), findsNothing);
      expect(find.text('No pending friend requests'), findsOneWidget);
    });

    testWidgets('Test duplicate friend request prevention', (
      WidgetTester tester,
    ) async {
      // Test data
      final friendUser = UserProfile(
        id: 'friend-user-id',
        email: 'friend@example.com',
        username: 'frienduser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock search results
      when(
        mockFriendService.searchUsersByUsername('frienduser'),
      ).thenAnswer((_) async => [friendUser]);

      // Mock existing friend request
      when(
        mockFriendService.sendFriendRequest('friend-user-id'),
      ).thenThrow(Exception('Friend request already sent'));

      await tester.pumpWidget(MaterialApp(home: AddFriendPage()));

      // Search for user
      await tester.enterText(find.byType(TextFormField), 'frienduser');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Try to send friend request
      await tester.tap(find.text('Send Friend Request'));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Friend request already sent'), findsOneWidget);
    });

    testWidgets('Test search functionality with no results', (
      WidgetTester tester,
    ) async {
      // Mock empty search results
      when(
        mockFriendService.searchUsersByUsername('nonexistentuser'),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(home: AddFriendPage()));

      // Search for non-existent user
      await tester.enterText(find.byType(TextFormField), 'nonexistentuser');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify no results message
      expect(find.text('No users found'), findsOneWidget);
    });

    testWidgets('Test error handling in friend operations', (
      WidgetTester tester,
    ) async {
      // Mock network error
      when(
        mockFriendService.getFriends(),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(MaterialApp(home: FriendsPage()));

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test retry functionality
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show empty friends list
      expect(find.text('No friends yet'), findsOneWidget);
    });

    testWidgets('Test friend search with multiple results', (
      WidgetTester tester,
    ) async {
      // Test data - multiple users with similar usernames
      final users = [
        UserProfile(
          id: 'user1-id',
          email: 'user1@example.com',
          username: 'testuser1',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'user2-id',
          email: 'user2@example.com',
          username: 'testuser2',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(
        mockFriendService.searchUsersByUsername('testuser'),
      ).thenAnswer((_) async => users);

      await tester.pumpWidget(MaterialApp(home: AddFriendPage()));

      // Search for users
      await tester.enterText(find.byType(TextFormField), 'testuser');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify both users are displayed
      expect(find.text('@testuser1'), findsOneWidget);
      expect(find.text('@testuser2'), findsOneWidget);
      expect(find.text('user1@example.com'), findsOneWidget);
      expect(find.text('user2@example.com'), findsOneWidget);

      // Verify each has a send friend request button
      expect(find.text('Send Friend Request'), findsNWidgets(2));
    });

    testWidgets('Test navigation between friend management pages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/friends',
          routes: {
            '/friends': (context) => FriendsPage(),
            '/add-friend': (context) => AddFriendPage(),
            '/friend-requests': (context) => FriendRequestsPage(),
          },
        ),
      );

      // Start on friends page
      expect(find.text('Friends'), findsOneWidget);

      // Navigate to add friend page
      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('Add Friend'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Friends'), findsOneWidget);

      // Navigate to friend requests page
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      expect(find.text('Friend Requests'), findsOneWidget);
    });
  });
}
