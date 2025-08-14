import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:time_capsule/pages/shared_folder/shared_folder_settings_page.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/shared_folder_data.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/friend_service.dart';

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
    late SharedFolderData testSharedData;
    late List<UserProfile> testContributors;

    setUp(() {
      mockFolderService = MockFolderService();
      mockFriendService = MockFriendService();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Setup test data
      testFolder = FolderModel(
        id: 'folder1',
        name: 'Test Shared Folder',
        userId: 'owner123',
        description: 'A test shared folder',
        createdAt: Timestamp.now(),
      );

      testSharedData = SharedFolderData(
        contributorIds: ['contributor1', 'contributor2'],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      testContributors = [
        UserProfile(
          id: 'contributor1',
          email: 'contributor1@test.com',
          username: 'contributor1',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'contributor2',
          email: 'contributor2@test.com',
          username: 'contributor2',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Setup auth mocks
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('owner123');
    });

    Widget createWidget() {
      return MaterialApp(
        home: SharedFolderSettingsPage(
          folderId: 'folder1',
          folder: testFolder,
        ),
      );
    }

    testWidgets('displays loading indicator initially', (tester) async {
      // Setup mocks to delay response
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) => Future.delayed(
                const Duration(seconds: 1),
                () => testSharedData,
              ));

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error when shared folder data fails to load', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenThrow(Exception('Failed to load'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Exception: Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays folder information for owner', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Folder Information'), findsOneWidget);
      expect(find.text('Test Shared Folder'), findsOneWidget);
      expect(find.text('A test shared folder'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
    });

    testWidgets('displays folder information for contributor', (tester) async {
      when(mockUser.uid).thenReturn('contributor1');
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Contributor'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsNothing); // No invite button for contributors
    });

    testWidgets('displays unlock status for unlocked folder', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Folder Status'), findsOneWidget);
      expect(find.text('This folder is unlocked. Contributors can add new content.'), findsOneWidget);
      expect(find.text('Lock Folder'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
    });

    testWidgets('displays lock status for locked folder', (tester) async {
      final lockedSharedData = SharedFolderData(
        contributorIds: ['contributor1'],
        ownerId: 'owner123',
        isLocked: true,
        isPublic: false,
        lockedAt: DateTime.now(),
      );

      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => lockedSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('This folder is locked. Contributors cannot add new content.'), findsOneWidget);
      expect(find.text('Unlock Folder'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('displays contributors list', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Contributors'), findsOneWidget);
      expect(find.text('contributor1'), findsOneWidget);
      expect(find.text('contributor2'), findsOneWidget);
    });

    testWidgets('displays empty state when no contributors', (tester) async {
      final emptySharedData = SharedFolderData(
        contributorIds: [],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => emptySharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No contributors yet'), findsOneWidget);
      expect(find.text('Invite Contributors'), findsOneWidget);
    });

    testWidgets('owner can invite contributors', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => [
            UserProfile(
              id: 'friend1',
              email: 'friend1@test.com',
              username: 'friend1',
              profilePictureUrl: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('owner can remove contributors', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2)); // One for each contributor
    });

    testWidgets('contributor cannot remove other contributors', (tester) async {
      when(mockUser.uid).thenReturn('contributor1');
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets('lock folder button works', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);
      when(mockFolderService.lockFolder('folder1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lock Folder'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Lock Folder'), findsNWidgets(2)); // Button and dialog title
      expect(find.text('Are you sure you want to lock this folder?'), findsOneWidget);

      await tester.tap(find.text('Lock').last);
      await tester.pumpAndSettle();

      verify(mockFolderService.lockFolder('folder1')).called(1);
    });

    testWidgets('unlock folder button works', (tester) async {
      final lockedSharedData = SharedFolderData(
        contributorIds: ['contributor1'],
        ownerId: 'owner123',
        isLocked: true,
        isPublic: false,
        lockedAt: DateTime.now(),
      );

      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => lockedSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);
      when(mockFolderService.unlockFolder('folder1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlock Folder'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Unlock Folder'), findsNWidgets(2)); // Button and dialog title
      expect(find.text('Are you sure you want to unlock this folder?'), findsOneWidget);

      await tester.tap(find.text('Unlock').last);
      await tester.pumpAndSettle();

      verify(mockFolderService.unlockFolder('folder1')).called(1);
    });

    testWidgets('shows success message after locking folder', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);
      when(mockFolderService.lockFolder('folder1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lock Folder'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lock').last);
      await tester.pumpAndSettle();

      expect(find.text('Folder locked successfully'), findsOneWidget);
    });

    testWidgets('shows error message when locking fails', (tester) async {
      when(mockFolderService.getSharedFolderData('folder1'))
          .thenAnswer((_) async => testSharedData);
      when(mockFriendService.getFriends())
          .thenAnswer((_) async => []);
      when(mockFolderService.lockFolder('folder1'))
          .thenThrow(Exception('Lock failed'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lock Folder'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lock').last);
      await tester.pumpAndSettle();

      expect(find.text('Failed to lock folder: Exception: Lock failed'), findsOneWidget);
    });
  });
}