import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:time_capsule/pages/friends/friends_page.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/services/friend_service.dart';

// Generate mocks
@GenerateMocks([FriendService])
import 'friends_page_dialog_test.mocks.dart';

void main() {
  group('FriendsPage Dialog', () {
    late MockFriendService mockFriendService;
    late UserProfile testFriend;

    setUp(() {
      mockFriendService = MockFriendService();
      testFriend = UserProfile(
        id: 'friend123',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('friend options dialog shows only Shared Folders and Remove Friend', (WidgetTester tester) async {
      // Arrange
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [testFriend]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const FriendsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on friend to open options
      await tester.tap(find.text('testfriend'));
      await tester.pumpAndSettle();

      // Assert - Check that only expected options are present
      expect(find.text('Shared Folders'), findsOneWidget);
      expect(find.text('Remove Friend'), findsOneWidget);
      
      // Assert - Check that Send Message option is NOT present
      expect(find.text('Send Message'), findsNothing);
      
      // Assert - Check icons are correct
      expect(find.byIcon(Icons.folder_shared), findsOneWidget);
      expect(find.byIcon(Icons.person_remove), findsOneWidget);
      expect(find.byIcon(Icons.message), findsNothing);
    });

    testWidgets('tapping Shared Folders navigates to SharedFoldersPage', (WidgetTester tester) async {
      // Arrange
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [testFriend]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const FriendsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on friend to open options
      await tester.tap(find.text('testfriend'));
      await tester.pumpAndSettle();

      // Tap on Shared Folders
      await tester.tap(find.text('Shared Folders'));
      await tester.pumpAndSettle();

      // Assert - Should navigate to SharedFoldersPage
      expect(find.text('Shared with testfriend'), findsOneWidget);
    });

    testWidgets('dialog contains exactly 2 action options', (WidgetTester tester) async {
      // Arrange
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [testFriend]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const FriendsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on friend to open options
      await tester.tap(find.text('testfriend'));
      await tester.pumpAndSettle();

      // Assert - Count the number of ListTile widgets in the dialog (excluding friend info)
      final actionTiles = find.byType(ListTile);
      expect(actionTiles, findsNWidgets(3)); // Friend info + 2 action options
    });
  });
}