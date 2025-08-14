import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/models/media_model.dart';
import 'package:time_capsule/pages/shared_folder/shared_folder_settings_page.dart';
import 'package:time_capsule/pages/memory_album/folder_detail_page.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  FolderService,
  FriendService,
])
import 'shared_folder_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Folder Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockFolderService mockFolderService;
    late MockFriendService mockFriendService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockFolderService = MockFolderService();
      mockFriendService = MockFriendService();

      // Setup basic user mock
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('Test shared folder creation and contributor invitation', (
      WidgetTester tester,
    ) async {
      // Test data
      final testFolder = FolderModel(
        id: 'test-folder-id',
        name: 'Vacation Memories',
        userId: 'test-user-id',
        parentFolderId: null,
        description: 'Our amazing vacation',
        coverImageUrl: null,
        createdAt: DateTime.now(),
        isShared: false,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

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
      when(
        mockFolderService.getFolder('test-folder-id'),
      ).thenAnswer((_) async => testFolder);
      when(mockFriendService.getFriends()).thenAnswer((_) async => friends);

      await tester.pumpWidget(
        MaterialApp(home: SharedFolderSettingsPage(folderId: 'test-folder-id')),
      );

      await tester.pumpAndSettle();

      // Verify folder information is displayed
      expect(find.text('Vacation Memories'), findsOneWidget);
      expect(find.text('Our amazing vacation'), findsOneWidget);

      // Step 1: Make folder shared
      expect(find.text('Make Shared'), findsOneWidget);
      await tester.tap(find.text('Make Shared'));
      await tester.pumpAndSettle();

      // Should show contributor selection
      expect(find.text('Select Contributors'), findsOneWidget);
      expect(find.text('@friend1'), findsOneWidget);
      expect(find.text('@friend2'), findsOneWidget);

      // Step 2: Select contributors
      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      // Mock shared folder creation
      final sharedFolder = testFolder.copyWith(
        isShared: true,
        contributorIds: ['friend1-id', 'friend2-id'],
      );

      when(
        mockFolderService.createSharedFolder(any, ['friend1-id', 'friend2-id']),
      ).thenAnswer((_) async => sharedFolder);

      // Step 3: Create shared folder
      await tester.tap(find.text('Create Shared Folder'));
      await tester.pumpAndSettle();

      // Verify shared folder was created
      verify(
        mockFolderService.createSharedFolder(any, ['friend1-id', 'friend2-id']),
      ).called(1);

      expect(find.text('Shared folder created successfully'), findsOneWidget);

      // Verify contributors are displayed
      expect(find.text('Contributors (2)'), findsOneWidget);
      expect(find.text('@friend1'), findsOneWidget);
      expect(find.text('@friend2'), findsOneWidget);
    });

    testWidgets('Test contributor upload permissions and attribution', (
      WidgetTester tester,
    ) async {
      // Test data - shared folder with contributors
      final sharedFolder = FolderModel(
        id: 'shared-folder-id',
        name: 'Shared Memories',
        userId: 'owner-id',
        parentFolderId: null,
        description: 'Shared vacation folder',
        coverImageUrl: null,
        createdAt: DateTime.now(),
        isShared: true,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: ['test-user-id', 'friend1-id'],
      );

      final mediaItems = [
        MediaModel(
          id: 'media1-id',
          folderId: 'shared-folder-id',
          fileName: 'beach.jpg',
          filePath: 'path/to/beach.jpg',
          fileType: 'image',
          fileSize: 1024000,
          uploadedAt: DateTime.now(),
          uploadedBy: 'test-user-id',
          description: 'Beautiful beach',
          tags: [],
        ),
        MediaModel(
          id: 'media2-id',
          folderId: 'shared-folder-id',
          fileName: 'sunset.jpg',
          filePath: 'path/to/sunset.jpg',
          fileType: 'image',
          fileSize: 2048000,
          uploadedAt: DateTime.now(),
          uploadedBy: 'friend1-id',
          description: 'Amazing sunset',
          tags: [],
        ),
      ];

      // Mock service responses
      when(
        mockFolderService.getFolder('shared-folder-id'),
      ).thenAnswer((_) async => sharedFolder);
      when(
        mockFolderService.getMediaInFolder('shared-folder-id'),
      ).thenAnswer((_) async => mediaItems);

      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'shared-folder-id')),
      );

      await tester.pumpAndSettle();

      // Verify shared folder is displayed
      expect(find.text('Shared Memories'), findsOneWidget);
      expect(find.text('Shared'), findsOneWidget);

      // Verify media items are displayed with attribution
      expect(find.text('beach.jpg'), findsOneWidget);
      expect(find.text('sunset.jpg'), findsOneWidget);

      // Verify upload attribution is shown
      expect(find.text('Uploaded by you'), findsOneWidget);
      expect(find.text('Uploaded by @friend1'), findsOneWidget);

      // Test contributor upload permissions
      // As a contributor, should be able to upload
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap add media button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show upload options
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Mock media upload
      final newMedia = MediaModel(
        id: 'new-media-id',
        folderId: 'shared-folder-id',
        fileName: 'new-photo.jpg',
        filePath: 'path/to/new-photo.jpg',
        fileType: 'image',
        fileSize: 1500000,
        uploadedAt: DateTime.now(),
        uploadedBy: 'test-user-id',
        description: 'New shared photo',
        tags: [],
      );

      when(
        mockFolderService.uploadMedia(any, any),
      ).thenAnswer((_) async => newMedia);

      // Select gallery option (in real test, would need to mock file picker)
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Verify upload was successful (would need proper file picker mocking)
      // For now, just verify the upload method would be called
    });

    testWidgets('Test folder locking and access control', (
      WidgetTester tester,
    ) async {
      // Test data - shared folder owned by current user
      final sharedFolder = FolderModel(
        id: 'shared-folder-id',
        name: 'Shared Memories',
        userId: 'test-user-id', // Current user is owner
        parentFolderId: null,
        description: 'Shared vacation folder',
        coverImageUrl: null,
        createdAt: DateTime.now(),
        isShared: true,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: ['friend1-id', 'friend2-id'],
      );

      // Mock service responses
      when(
        mockFolderService.getFolder('shared-folder-id'),
      ).thenAnswer((_) async => sharedFolder);

      await tester.pumpWidget(
        MaterialApp(
          home: SharedFolderSettingsPage(folderId: 'shared-folder-id'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify folder settings are displayed
      expect(find.text('Shared Memories'), findsOneWidget);
      expect(find.text('Lock Folder'), findsOneWidget);

      // Step 1: Lock the folder (only owner can do this)
      await tester.tap(find.text('Lock Folder'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Lock Folder?'), findsOneWidget);
      expect(
        find.text(
          'Once locked, contributors will no longer be able to add content.',
        ),
        findsOneWidget,
      );

      // Mock lock folder service call
      final lockedFolder = sharedFolder.copyWith(
        isLocked: true,
        lockedAt: DateTime.now(),
      );

      when(
        mockFolderService.lockFolder('shared-folder-id'),
      ).thenAnswer((_) async => lockedFolder);

      // Confirm lock
      await tester.tap(find.text('Lock'));
      await tester.pumpAndSettle();

      // Verify folder was locked
      verify(mockFolderService.lockFolder('shared-folder-id')).called(1);
      expect(find.text('Folder locked successfully'), findsOneWidget);

      // Verify lock status is displayed
      expect(find.text('Locked'), findsOneWidget);
      expect(
        find.text('This folder is locked and no longer accepts new content'),
        findsOneWidget,
      );

      // Step 2: Test access control for locked folder
      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'shared-folder-id')),
      );

      when(
        mockFolderService.getFolder('shared-folder-id'),
      ).thenAnswer((_) async => lockedFolder);

      await tester.pumpAndSettle();

      // Verify locked folder shows lock indicator
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);

      // Verify add button is not available (folder is locked)
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('Test contributor management (add/remove)', (
      WidgetTester tester,
    ) async {
      // Test data
      final sharedFolder = FolderModel(
        id: 'shared-folder-id',
        name: 'Shared Memories',
        userId: 'test-user-id',
        parentFolderId: null,
        description: 'Shared vacation folder',
        coverImageUrl: null,
        createdAt: DateTime.now(),
        isShared: true,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: ['friend1-id'],
      );

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
      when(
        mockFolderService.getFolder('shared-folder-id'),
      ).thenAnswer((_) async => sharedFolder);
      when(mockFriendService.getFriends()).thenAnswer((_) async => friends);

      await tester.pumpWidget(
        MaterialApp(
          home: SharedFolderSettingsPage(folderId: 'shared-folder-id'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify current contributors are displayed
      expect(find.text('Contributors (1)'), findsOneWidget);
      expect(find.text('@friend1'), findsOneWidget);

      // Step 1: Add new contributor
      await tester.tap(find.text('Add Contributors'));
      await tester.pumpAndSettle();

      // Should show available friends (excluding current contributors)
      expect(find.text('@friend2'), findsOneWidget);
      expect(find.text('@friend1'), findsNothing); // Already a contributor

      // Select new contributor
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Mock invite contributors service call
      when(
        mockFolderService.inviteContributors('shared-folder-id', [
          'friend2-id',
        ]),
      ).thenAnswer((_) async {});

      // Confirm invitation
      await tester.tap(find.text('Invite'));
      await tester.pumpAndSettle();

      // Verify contributor was added
      verify(
        mockFolderService.inviteContributors('shared-folder-id', [
          'friend2-id',
        ]),
      ).called(1);
      expect(find.text('Contributors invited successfully'), findsOneWidget);

      // Step 2: Remove contributor
      // Long press on contributor to show remove option
      await tester.longPress(find.text('@friend1'));
      await tester.pumpAndSettle();

      // Should show remove option
      expect(find.text('Remove Contributor'), findsOneWidget);

      // Tap remove
      await tester.tap(find.text('Remove Contributor'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Remove Contributor?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to remove @friend1 from this folder?'),
        findsOneWidget,
      );

      // Mock remove contributor service call
      when(
        mockFolderService.removeContributor('shared-folder-id', 'friend1-id'),
      ).thenAnswer((_) async {});

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Verify contributor was removed
      verify(
        mockFolderService.removeContributor('shared-folder-id', 'friend1-id'),
      ).called(1);
      expect(find.text('Contributor removed successfully'), findsOneWidget);
    });

    testWidgets('Test non-owner contributor permissions', (
      WidgetTester tester,
    ) async {
      // Test data - shared folder where current user is contributor, not owner
      final sharedFolder = FolderModel(
        id: 'shared-folder-id',
        name: 'Shared Memories',
        userId: 'owner-id', // Different from current user
        parentFolderId: null,
        description: 'Shared vacation folder',
        coverImageUrl: null,
        createdAt: DateTime.now(),
        isShared: true,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: ['test-user-id'], // Current user is contributor
      );

      // Mock service responses
      when(
        mockFolderService.getFolder('shared-folder-id'),
      ).thenAnswer((_) async => sharedFolder);

      await tester.pumpWidget(
        MaterialApp(
          home: SharedFolderSettingsPage(folderId: 'shared-folder-id'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify contributor view (limited permissions)
      expect(find.text('Shared Memories'), findsOneWidget);

      // Should NOT see owner-only controls
      expect(find.text('Lock Folder'), findsNothing);
      expect(find.text('Add Contributors'), findsNothing);
      expect(find.text('Remove Contributor'), findsNothing);

      // Should see contributor status
      expect(find.text('You are a contributor'), findsOneWidget);

      // Test folder detail view as contributor
      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'shared-folder-id')),
      );

      await tester.pumpAndSettle();

      // Should be able to upload (contributor permission)
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Should see shared folder indicator
      expect(find.text('Shared'), findsOneWidget);
    });

    testWidgets('Test error handling in shared folder operations', (
      WidgetTester tester,
    ) async {
      // Mock network error
      when(
        mockFolderService.getFolder('shared-folder-id'),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(
          home: SharedFolderSettingsPage(folderId: 'shared-folder-id'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test retry functionality
      final sharedFolder = FolderModel(
        id: 'shared-folder-id',
        name: 'Shared Memories',
        userId: 'test-user-id',
        parentFolderId: null,
        description: 'Shared vacation folder',
        coverImageUrl: null,
        createdAt: DateTime.now(),
        isShared: true,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

      when(
        mockFolderService.getFolder('shared-folder-id'),
      ).thenAnswer((_) async => sharedFolder);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show folder settings
      expect(find.text('Shared Memories'), findsOneWidget);
    });

    testWidgets('Test shared folder creation validation', (
      WidgetTester tester,
    ) async {
      // Test data
      final testFolder = FolderModel(
        id: 'test-folder-id',
        name: 'Test Folder',
        userId: 'test-user-id',
        parentFolderId: null,
        description: 'Test folder',
        coverImageUrl: null,
        createdAt: DateTime.now(),
        isShared: false,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

      // Mock service responses
      when(
        mockFolderService.getFolder('test-folder-id'),
      ).thenAnswer((_) async => testFolder);
      when(
        mockFriendService.getFriends(),
      ).thenAnswer((_) async => []); // No friends

      await tester.pumpWidget(
        MaterialApp(home: SharedFolderSettingsPage(folderId: 'test-folder-id')),
      );

      await tester.pumpAndSettle();

      // Try to make folder shared without friends
      await tester.tap(find.text('Make Shared'));
      await tester.pumpAndSettle();

      // Should show message about no friends
      expect(
        find.text('You need friends to create a shared folder'),
        findsOneWidget,
      );
      expect(find.text('Add friends first'), findsOneWidget);
    });
  });
}
