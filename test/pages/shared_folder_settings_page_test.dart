import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_capsule/pages/shared_folder/shared_folder_settings_page.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/shared_folder_data.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'shared_folder_settings_page_test.mocks.dart';

@GenerateMocks([
  FolderService,
  FriendService,
  FirebaseAuth,
  User,
])
void main() {
  group('SharedFolderSettingsPage', () {
    late MockFolderService mockFolderService;
    late MockFriendService mockFriendService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FolderModel testFolder;

    setUp(() {
      mockFolderService = MockFolderService();
      mockFriendService = MockFriendService();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Setup auth mocks
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('owner123');

      testFolder = FolderModel(
        id: 'folder123',
        name: 'Test Shared Folder',
        userId: 'owner123',
        createdAt: Timestamp.now(),
        isShared: true,
        contributorIds: ['user1', 'user2'],
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: SharedFolderSettingsPage(
          folderId: 'folder123',
          folder: testFolder,
        ),
      );
    }

    testWidgets('should display folder information correctly', (tester) async {
      // Arrange
      final sharedData = SharedFolderData(
        contributorIds: ['user1', 'user2'],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      final contributors = [
        UserProfile(
          id: 'user1',
          email: 'user1@example.com',
          username: 'User One',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'user2',
          email: 'user2@example.com',
          username: 'User Two',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async => sharedData);
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => contributors);
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Shared Folder Settings'), findsOneWidget);
      expect(find.text('Test Shared Folder'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('User One'), findsOneWidget);
      expect(find.text('User Two'), findsOneWidget);
    });

    testWidgets('should show unlock button when folder is locked', (tester) async {
      // Arrange
      final sharedData = SharedFolderData(
        contributorIds: ['user1'],
        ownerId: 'owner123',
        isLocked: true,
        isPublic: false,
      );

      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async => sharedData);
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => []);
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('This folder is locked. Contributors cannot add new content.'), findsOneWidget);
      expect(find.text('Unlock Folder'), findsOneWidget);
    });

    testWidgets('should show lock button when folder is unlocked', (tester) async {
      // Arrange
      final sharedData = SharedFolderData(
        contributorIds: ['user1'],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async => sharedData);
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => []);
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('This folder is unlocked. Contributors can add new content.'), findsOneWidget);
      expect(find.text('Lock Folder'), findsOneWidget);
    });

    testWidgets('should show invite contributors button for owner', (tester) async {
      // Arrange
      final sharedData = SharedFolderData(
        contributorIds: [],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async => sharedData);
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => []);
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No contributors yet'), findsOneWidget);
      expect(find.text('Invite Contributors'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsWidgets);
    });

    testWidgets('should show remove contributor buttons for owner', (tester) async {
      // Arrange
      final sharedData = SharedFolderData(
        contributorIds: ['user1'],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      final contributors = [
        UserProfile(
          id: 'user1',
          email: 'user1@example.com',
          username: 'User One',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async => sharedData);
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => contributors);
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('User One'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('should not show management buttons for non-owner', (tester) async {
      // Arrange - User is not the owner
      when(mockUser.uid).thenReturn('user1');
      
      final nonOwnerFolder = testFolder.copyWith(userId: 'owner123');
      
      final sharedData = SharedFolderData(
        contributorIds: ['user1'],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async => sharedData);
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(MaterialApp(
        home: SharedFolderSettingsPage(
          folderId: 'folder123',
          folder: nonOwnerFolder,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Contributor'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsNothing);
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      expect(find.text('Lock Folder'), findsNothing);
      expect(find.text('Unlock Folder'), findsNothing);
    });

    testWidgets('should handle remove contributor action', (tester) async {
      // Arrange
      final sharedData = SharedFolderData(
        contributorIds: ['user1'],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      final contributors = [
        UserProfile(
          id: 'user1',
          email: 'user1@example.com',
          username: 'User One',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async => sharedData);
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => contributors);
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);
      when(mockFolderService.removeContributor('folder123', 'user1'))
          .thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap remove contributor button
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      // Confirm removal in dialog
      expect(find.text('Remove Contributor'), findsOneWidget);
      expect(find.text('They will be notified about the removal'), findsOneWidget);
      
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockFolderService.removeContributor('folder123', 'user1')).called(1);
    });

    testWidgets('should display error message when loading fails', (tester) async {
      // Arrange
      when(mockFolderService.getSharedFolderData('folder123'))
          .thenThrow(Exception('Failed to load folder data'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Exception: Failed to load folder data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      // Arrange
      when(mockFolderService.getSharedFolderData('folder123'))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return SharedFolderData(
          contributorIds: [],
          ownerId: 'owner123',
          isLocked: false,
          isPublic: false,
        );
      });
      when(mockFolderService.getFolderContributors('folder123'))
          .thenAnswer((_) async => []);
      when(mockFriendService.getFriends()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}