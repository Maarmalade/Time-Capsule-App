import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_capsule/pages/friends/add_friend_page.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/friend_request_model.dart';

import 'add_friend_page_test.mocks.dart';

// Generate mocks
@GenerateMocks([FriendService])
void main() {}

void main() {
  group('AddFriendPage', () {
    late MockFriendService mockFriendService;

    setUp(() {
      mockFriendService = MockFriendService();
    });

    testWidgets('displays initial state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddFriendPage(),
        ),
      );

      // Should display app bar
      expect(find.text('Add Friend'), findsOneWidget);
      
      // Should display search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter username...'), findsOneWidget);
      
      // Should display initial state
      expect(find.byIcon(Icons.person_search), findsOneWidget);
      expect(find.text('Search for friends'), findsNWidgets(2)); // Title and initial state
      expect(find.text('Enter a username to find and connect with friends'), findsOneWidget);
    });

    testWidgets('shows search icon and clear button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddFriendPage(),
        ),
      );

      // Should show search icon
      expect(find.byIcon(Icons.search), findsOneWidget);
      
      // Should not show clear button initially
      expect(find.byIcon(Icons.clear), findsNothing);
      
      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      
      // Should show clear button
      expect(find.byIcon(Icons.clear), findsOneWidget);
      
      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      
      // Should clear text and hide clear button
      expect(find.text('test'), findsNothing);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('displays empty state when no results found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddFriendPage(),
        ),
      );

      // Enter search text and submit
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      
      // Wait for search to complete (mocked to return empty list)
      await tester.pumpAndSettle();

      // Should display empty state
      expect(find.byIcon(Icons.person_off), findsOneWidget);
      expect(find.text('No users found'), findsOneWidget);
      expect(find.text('Try searching with a different username'), findsOneWidget);
    });

    testWidgets('displays search results correctly', (WidgetTester tester) async {
      final testUsers = [
        UserProfile(
          id: 'user1',
          email: 'user1@example.com',
          username: 'alice',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'user2',
          email: 'user2@example.com',
          username: 'bob',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Mock the search to return test users
      when(mockFriendService.searchUsersByUsername(argThat(isA<String>())))
          .thenAnswer((_) async => testUsers);

      await tester.pumpWidget(
        const MaterialApp(
          home: AddFriendPage(),
        ),
      );

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should display search results
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);
      expect(find.text('Add'), findsNWidgets(2));
      expect(find.byType(CircleAvatar), findsNWidgets(2));
    });

    testWidgets('shows loading state during search', (WidgetTester tester) async {
      // Mock search with delay
      when(mockFriendService.searchUsersByUsername(argThat(isA<String>())))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return <UserProfile>[];
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AddFriendPage(),
        ),
      );

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Should show loading indicator in search field
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('handles search error correctly', (WidgetTester tester) async {
      // Mock search to throw error
      when(mockFriendService.searchUsersByUsername(argThat(isA<String>())))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        const MaterialApp(
          home: AddFriendPage(),
        ),
      );

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should display error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Search Error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('sends friend request when Add button is tapped', (WidgetTester tester) async {
      final testUser = UserProfile(
        id: 'user1',
        email: 'user1@example.com',
        username: 'alice',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockFriendRequest = FriendRequest(
        id: 'request1',
        senderId: 'currentUser',
        receiverId: 'user1',
        senderUsername: 'currentUser',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        respondedAt: null,
      );

      // Mock successful search and friend request
      w
      // Search for user
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Friend request sent to alice'), findsOneWidget);
    });

    testWidgets('handles friend request error correctly', (WidgetTester tester) async {
      final testUser = UserProfile(
        id: 'user1',
        email: 'user1@example.com',
        username: 'alice',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock successful search but failed friend request
      when(mockFriendService.searchUsersByUsername(any))
          .thenAnswer((_) async => [testUser]);
      when(mockFriendService.sendFriendRequest(any))
          .thenThrow(Exception('Request failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: const AddFriendPage(),
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        ),
      );

      // Search for user
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.textContaining('Request failed'), findsOneWidget);
      
      // Add button should be available again
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('debounces search input correctly', (WidgetTester tester) async {
      when(mockFriendService.searchUsersByUsername(any))
          .thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(
        const MaterialApp(
          home: AddFriendPage(),
        ),
      );

      // Type multiple characters quickly
      await tester.enterText(find.byType(TextField), 't');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'te');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'test');
      
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));

      // Should only call search once with final text
      verify(mockFriendService.searchUsersByUsername('test')).called(1);
    });
  });
}