import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:time_capsule/pages/friends/shared_folders_page.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/services/folder_service.dart';

// Generate mocks
@GenerateMocks([FolderService])
import 'shared_folders_page_test.mocks.dart';

void main() {
  group('SharedFoldersPage', () {
    late MockFolderService mockFolderService;
    late UserProfile testFriend;

    setUp(() {
      mockFolderService = MockFolderService();
      testFriend = UserProfile(
        id: 'friend123',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('displays friend name in app bar', (WidgetTester tester) async {
      // Arrange
      when(mockFolderService.getSharedFoldersBetweenUsers(any))
          .thenAnswer((_) async => <FolderModel>[]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SharedFoldersPage(friend: testFriend),
        ),
      );

      // Assert
      expect(find.text('Shared with testfriend'), findsOneWidget);
    });

    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      when(mockFolderService.getSharedFoldersBetweenUsers(any))
          .thenAnswer((_) async => <FolderModel>[]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SharedFoldersPage(friend: testFriend),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading shared folders...'), findsOneWidget);
    });

    testWidgets('displays empty state when no shared folders', (WidgetTester tester) async {
      // Arrange
      when(mockFolderService.getSharedFoldersBetweenUsers(any))
          .thenAnswer((_) async => <FolderModel>[]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SharedFoldersPage(friend: testFriend),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No Shared Folders'), findsOneWidget);
      expect(find.text('You don\'t have any folders shared with testfriend yet.'), findsOneWidget);
    });

    testWidgets('displays shared folders when available', (WidgetTester tester) async {
      // Arrange
      final testFolders = [
        FolderModel(
          id: 'folder1',
          name: 'Shared Memories',
          userId: 'user123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isShared: true,
          contributorIds: ['friend123'],
        ),
        FolderModel(
          id: 'folder2',
          name: 'Vacation Photos',
          userId: 'friend123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isShared: true,
          contributorIds: ['user123'],
        ),
      ];

      when(mockFolderService.getSharedFoldersBetweenUsers(any))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SharedFoldersPage(friend: testFriend),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2 shared folders'), findsOneWidget);
      expect(find.text('Shared Memories'), findsOneWidget);
      expect(find.text('Vacation Photos'), findsOneWidget);
    });
  });
}