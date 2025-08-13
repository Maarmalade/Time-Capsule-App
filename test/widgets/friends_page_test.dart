import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:time_capsule/pages/friends/friends_page.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/services/friend_service.dart';

// Mock class for FriendService
class MockFriendService extends Mock implements FriendService {}

void main() {
  group('FriendsPage', () {
    late MockFriendService mockFriendService;

    setUp(() {
      mockFriendService = MockFriendService();
    });

    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Mock service to delay response
      when(mockFriendService.getFriends())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return <UserProfile>[];
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      // Should display loading state
      expect(find.text('Friends'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading friends...'), findsOneWidget);
    });

    testWidgets('displays empty state when no friends', (WidgetTester tester) async {
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display empty state
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.text('No Friends Yet'), findsOneWidget);
      expect(find.text('Start building your network by adding friends!'), findsOneWidget);
      expect(find.text('Add Friends'), findsOneWidget);
      expect(find.text('Check Requests'), findsOneWidget);
    });

    testWidgets('displays error state when loading fails', (WidgetTester tester) async {
      when(mockFriendService.getFriends())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error Loading Friends'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('displays friends list correctly', (WidgetTester tester) async {
      final testFriends = [
        UserProfile(
          id: 'friend1',
          email: 'alice@example.com',
          username: 'alice',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'friend2',
          email: 'bob@example.com',
          username: 'bob',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => testFriends);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display friends count
      expect(find.text('2 friends'), findsOneWidget);
      
      // Should display friend tiles
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);
      
      // Should display search field
      expect(find.text('Search friends...'), findsOneWidget);
    });

    testWidgets('filters friends based on search query', (WidgetTester tester) async {
      final testFriends = [
        UserProfile(
          id: 'friend1',
          email: 'alice@example.com',
          username: 'alice',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'friend2',
          email: 'bob@example.com',
          username: 'bob',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => testFriends);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();

      // Should only show alice
      expect(find.text('alice'), findsOneWidget);
      expect(find.text('bob'), findsNothing);
    });

    testWidgets('shows no search results state', (WidgetTester tester) async {
      final testFriends = [
        UserProfile(
          id: 'friend1',
          email: 'alice@example.com',
          username: 'alice',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => testFriends);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query that doesn't match
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();

      // Should show no results state
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No Results Found'), findsOneWidget);
      expect(find.text('No friends match "nonexistent"'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);
    });

    testWidgets('clears search when clear button is tapped', (WidgetTester tester) async {
      final testFriends = [
        UserProfile(
          id: 'friend1',
          email: 'alice@example.com',
          username: 'alice',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => testFriends);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Should show clear button
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Should clear search and show all friends
      expect(find.text('alice'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('removes friend successfully', (WidgetTester tester) async {
      final testFriend = UserProfile(
        id: 'friend1',
        email: 'alice@example.com',
        username: 'alice',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [testFriend]);
      when(mockFriendService.removeFriend('friend1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: const FriendsPage(),
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap more options on friend tile
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap remove friend
      await tester.tap(find.text('Remove Friend'));
      await tester.pumpAndSettle();

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Removed alice from friends'), findsOneWidget);
      
      // Friend should be removed from list
      expect(find.text('alice'), findsNothing);
      expect(find.text('No Friends Yet'), findsOneWidget);
    });

    testWidgets('handles remove friend error', (WidgetTester tester) async {
      final testFriend = UserProfile(
        id: 'friend1',
        email: 'alice@example.com',
        username: 'alice',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [testFriend]);
      when(mockFriendService.removeFriend('friend1'))
          .thenThrow(Exception('Remove failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: const FriendsPage(),
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap more options on friend tile
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap remove friend
      await tester.tap(find.text('Remove Friend'));
      await tester.pumpAndSettle();

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Remove failed'), findsOneWidget);
      
      // Friend should still be in list
      expect(find.text('alice'), findsOneWidget);
    });

    testWidgets('shows friend options bottom sheet', (WidgetTester tester) async {
      final testFriend = UserProfile(
        id: 'friend1',
        email: 'alice@example.com',
        username: 'alice',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [testFriend]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on friend tile
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Should show bottom sheet with options
      expect(find.text('Shared Folders'), findsOneWidget);
      expect(find.text('Send Message'), findsOneWidget);
      expect(find.text('Remove Friend'), findsOneWidget);
    });

    testWidgets('navigates to add friend page', (WidgetTester tester) async {
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: const FriendsPage(),
          routes: {
            '/add-friend': (context) => const Scaffold(
              body: Center(child: Text('Add Friend Page')),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap add friend button in app bar
      await tester.tap(find.byIcon(Icons.person_add).first);
      await tester.pumpAndSettle();

      // Should navigate to add friend page
      expect(find.text('Add Friend Page'), findsOneWidget);
    });

    testWidgets('navigates to friend requests page', (WidgetTester tester) async {
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: const FriendsPage(),
          routes: {
            '/friend-requests': (context) => const Scaffold(
              body: Center(child: Text('Friend Requests Page')),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap notifications button in app bar
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      // Should navigate to friend requests page
      expect(find.text('Friend Requests Page'), findsOneWidget);
    });

    testWidgets('refreshes friends when refresh button is tapped', (WidgetTester tester) async {
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Should call getFriends again
      verify(mockFriendService.getFriends()).called(2);
    });

    testWidgets('supports pull to refresh', (WidgetTester tester) async {
      final testFriend = UserProfile(
        id: 'friend1',
        email: 'alice@example.com',
        username: 'alice',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [testFriend]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();

      // Should call getFriends again
      verify(mockFriendService.getFriends()).called(2);
    });

    testWidgets('shows floating action button', (WidgetTester tester) async {
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => <UserProfile>[]);

      await tester.pumpWidget(
        const MaterialApp(
          home: FriendsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show floating action button
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsNWidgets(2)); // One in app bar, one in FAB
    });
  });
}