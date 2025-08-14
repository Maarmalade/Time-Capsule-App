import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/media_model.dart';
import 'package:time_capsule/pages/public_folders/public_folders_page.dart';
import 'package:time_capsule/pages/memory_album/folder_detail_page.dart';

// Generate mocks
@GenerateMocks([FirebaseAuth, FirebaseFirestore, User, FolderService])
import 'public_folder_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Public Folder Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockFolderService mockFolderService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockFolderService = MockFolderService();

      // Setup basic user mock
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('Test folder visibility changes (private to public)', (
      WidgetTester tester,
    ) async {
      // Test data - private folder owned by current user
      final privateFolder = FolderModel(
        id: 'test-folder-id',
        name: 'My Private Memories',
        userId: 'test-user-id',
        parentFolderId: null,
        description: 'Personal vacation photos',
        coverImageUrl: 'https://example.com/cover.jpg',
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
      ).thenAnswer((_) async => privateFolder);

      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'test-folder-id')),
      );

      await tester.pumpAndSettle();

      // Verify private folder is displayed
      expect(find.text('My Private Memories'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);

      // Step 1: Open folder settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should show folder settings dialog
      expect(find.text('Folder Settings'), findsOneWidget);
      expect(find.text('Make Public'), findsOneWidget);

      // Step 2: Make folder public
      await tester.tap(find.text('Make Public'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Make Folder Public?'), findsOneWidget);
      expect(
        find.text('This folder will be visible to all users'),
        findsOneWidget,
      );

      // Mock make public service call
      final publicFolder = privateFolder.copyWith(isPublic: true);
      when(
        mockFolderService.makePublic('test-folder-id'),
      ).thenAnswer((_) async => publicFolder);

      // Confirm making public
      await tester.tap(find.text('Make Public'));
      await tester.pumpAndSettle();

      // Verify folder was made public
      verify(mockFolderService.makePublic('test-folder-id')).called(1);
      expect(find.text('Folder is now public'), findsOneWidget);

      // Verify public status is displayed
      expect(find.text('Public'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('Test folder visibility changes (public to private)', (
      WidgetTester tester,
    ) async {
      // Test data - public folder owned by current user
      final publicFolder = FolderModel(
        id: 'public-folder-id',
        name: 'My Public Memories',
        userId: 'test-user-id',
        parentFolderId: null,
        description: 'Shared vacation photos',
        coverImageUrl: 'https://example.com/cover.jpg',
        createdAt: DateTime.now(),
        isShared: false,
        isPublic: true,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

      // Mock service responses
      when(
        mockFolderService.getFolder('public-folder-id'),
      ).thenAnswer((_) async => publicFolder);

      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'public-folder-id')),
      );

      await tester.pumpAndSettle();

      // Verify public folder is displayed
      expect(find.text('My Public Memories'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);

      // Step 1: Open folder settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should show make private option
      expect(find.text('Make Private'), findsOneWidget);

      // Step 2: Make folder private
      await tester.tap(find.text('Make Private'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Make Folder Private?'), findsOneWidget);
      expect(
        find.text('This folder will no longer be visible to other users'),
        findsOneWidget,
      );

      // Mock make private service call
      final privateFolder = publicFolder.copyWith(isPublic: false);
      when(
        mockFolderService.makePrivate('public-folder-id'),
      ).thenAnswer((_) async => privateFolder);

      // Confirm making private
      await tester.tap(find.text('Make Private'));
      await tester.pumpAndSettle();

      // Verify folder was made private
      verify(mockFolderService.makePrivate('public-folder-id')).called(1);
      expect(find.text('Folder is now private'), findsOneWidget);

      // Verify private status is displayed
      expect(find.text('Private'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('Verify public folder discovery and viewing', (
      WidgetTester tester,
    ) async {
      // Test data - public folders from different users
      final publicFolders = [
        FolderModel(
          id: 'public1-id',
          name: 'Amazing Sunsets',
          userId: 'user1-id',
          parentFolderId: null,
          description: 'Beautiful sunset photos from around the world',
          coverImageUrl: 'https://example.com/sunset.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isShared: false,
          isPublic: true,
          isLocked: false,
          lockedAt: null,
          contributorIds: [],
        ),
        FolderModel(
          id: 'public2-id',
          name: 'City Adventures',
          userId: 'user2-id',
          parentFolderId: null,
          description: 'Urban exploration and city life',
          coverImageUrl: 'https://example.com/city.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isShared: false,
          isPublic: true,
          isLocked: false,
          lockedAt: null,
          contributorIds: [],
        ),
      ];

      // Mock service responses
      when(
        mockFolderService.getPublicFolders(),
      ).thenAnswer((_) async => publicFolders);

      await tester.pumpWidget(MaterialApp(home: PublicFoldersPage()));

      await tester.pumpAndSettle();

      // Verify public folders page
      expect(find.text('Public Folders'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);

      // Verify public folders are displayed
      expect(find.text('Amazing Sunsets'), findsOneWidget);
      expect(find.text('City Adventures'), findsOneWidget);
      expect(
        find.text('Beautiful sunset photos from around the world'),
        findsOneWidget,
      );
      expect(find.text('Urban exploration and city life'), findsOneWidget);

      // Verify owner information is shown
      expect(find.text('by @user1'), findsOneWidget);
      expect(find.text('by @user2'), findsOneWidget);

      // Step: View public folder details
      await tester.tap(find.text('Amazing Sunsets'));
      await tester.pumpAndSettle();

      // Mock folder detail data
      final mediaItems = [
        MediaModel(
          id: 'media1-id',
          folderId: 'public1-id',
          fileName: 'sunset1.jpg',
          filePath: 'path/to/sunset1.jpg',
          fileType: 'image',
          fileSize: 1024000,
          uploadedAt: DateTime.now(),
          uploadedBy: 'user1-id',
          description: 'Golden hour sunset',
          tags: ['sunset', 'nature'],
        ),
      ];

      when(
        mockFolderService.getFolder('public1-id'),
      ).thenAnswer((_) async => publicFolders[0]);
      when(
        mockFolderService.getMediaInFolder('public1-id'),
      ).thenAnswer((_) async => mediaItems);

      await tester.pumpAndSettle();

      // Verify public folder detail view
      expect(find.text('Amazing Sunsets'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('by @user1'), findsOneWidget);

      // Verify media is displayed
      expect(find.text('sunset1.jpg'), findsOneWidget);
      expect(find.text('Golden hour sunset'), findsOneWidget);

      // Verify read-only access (no upload button for non-owner)
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('Test access control for public vs private folders', (
      WidgetTester tester,
    ) async {
      // Test data - mix of public and private folders
      final publicFolder = FolderModel(
        id: 'public-folder-id',
        name: 'Public Memories',
        userId: 'other-user-id', // Different from current user
        parentFolderId: null,
        description: 'Public vacation photos',
        coverImageUrl: 'https://example.com/cover.jpg',
        createdAt: DateTime.now(),
        isShared: false,
        isPublic: true,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

      final privateFolder = FolderModel(
        id: 'private-folder-id',
        name: 'Private Memories',
        userId: 'other-user-id', // Different from current user
        parentFolderId: null,
        description: 'Private vacation photos',
        coverImageUrl: 'https://example.com/cover.jpg',
        createdAt: DateTime.now(),
        isShared: false,
        isPublic: false,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

      // Step 1: Test access to public folder (should work)
      when(
        mockFolderService.getFolder('public-folder-id'),
      ).thenAnswer((_) async => publicFolder);

      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'public-folder-id')),
      );

      await tester.pumpAndSettle();

      // Should be able to view public folder
      expect(find.text('Public Memories'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);

      // Should not have owner controls (settings, upload)
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);

      // Step 2: Test access to private folder (should be denied)
      when(
        mockFolderService.getFolder('private-folder-id'),
      ).thenThrow(Exception('Access denied'));

      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'private-folder-id')),
      );

      await tester.pumpAndSettle();

      // Should show access denied error
      expect(find.text('Access denied'), findsOneWidget);
      expect(
        find.text('You don\'t have permission to view this folder'),
        findsOneWidget,
      );
    });

    testWidgets('Test public folder search and filtering', (
      WidgetTester tester,
    ) async {
      // Test data - multiple public folders for search testing
      final allPublicFolders = [
        FolderModel(
          id: 'nature1-id',
          name: 'Nature Photography',
          userId: 'user1-id',
          parentFolderId: null,
          description: 'Beautiful nature shots',
          coverImageUrl: 'https://example.com/nature.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isShared: false,
          isPublic: true,
          isLocked: false,
          lockedAt: null,
          contributorIds: [],
        ),
        FolderModel(
          id: 'travel1-id',
          name: 'Travel Adventures',
          userId: 'user2-id',
          parentFolderId: null,
          description: 'Travel photos from Europe',
          coverImageUrl: 'https://example.com/travel.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isShared: false,
          isPublic: true,
          isLocked: false,
          lockedAt: null,
          contributorIds: [],
        ),
        FolderModel(
          id: 'nature2-id',
          name: 'Wildlife Encounters',
          userId: 'user3-id',
          parentFolderId: null,
          description: 'Amazing wildlife photography',
          coverImageUrl: 'https://example.com/wildlife.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          isShared: false,
          isPublic: true,
          isLocked: false,
          lockedAt: null,
          contributorIds: [],
        ),
      ];

      // Mock initial load of all public folders
      when(
        mockFolderService.getPublicFolders(),
      ).thenAnswer((_) async => allPublicFolders);

      await tester.pumpWidget(MaterialApp(home: PublicFoldersPage()));

      await tester.pumpAndSettle();

      // Verify all folders are initially displayed
      expect(find.text('Nature Photography'), findsOneWidget);
      expect(find.text('Travel Adventures'), findsOneWidget);
      expect(find.text('Wildlife Encounters'), findsOneWidget);

      // Step 1: Test search functionality
      await tester.enterText(find.byType(TextFormField), 'nature');
      await tester.pumpAndSettle();

      // Mock search results
      when(
        mockFolderService.searchPublicFolders('nature'),
      ).thenAnswer((_) async => [allPublicFolders[0], allPublicFolders[2]]);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Should show filtered results
      expect(find.text('Nature Photography'), findsOneWidget);
      expect(find.text('Wildlife Encounters'), findsOneWidget);
      expect(find.text('Travel Adventures'), findsNothing);

      // Step 2: Test filter by date
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should show filter options
      expect(find.text('Sort by Date'), findsOneWidget);
      expect(find.text('Sort by Name'), findsOneWidget);
      expect(find.text('Filter by Owner'), findsOneWidget);

      // Select sort by date
      await tester.tap(find.text('Sort by Date'));
      await tester.pumpAndSettle();

      // Clear search to show all folders again
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Folders should be sorted by date (most recent first)
      // In a real test, you would verify the order of widgets
    });

    testWidgets('Test public folder pagination', (WidgetTester tester) async {
      // Test data - simulate large number of public folders
      final firstPageFolders = List.generate(
        10,
        (index) => FolderModel(
          id: 'folder-$index',
          name: 'Public Folder $index',
          userId: 'user-$index',
          parentFolderId: null,
          description: 'Description for folder $index',
          coverImageUrl: 'https://example.com/cover$index.jpg',
          createdAt: DateTime.now().subtract(Duration(days: index)),
          isShared: false,
          isPublic: true,
          isLocked: false,
          lockedAt: null,
          contributorIds: [],
        ),
      );

      // Mock paginated response
      when(
        mockFolderService.getPublicFolders(page: 0, limit: 10),
      ).thenAnswer((_) async => firstPageFolders);

      await tester.pumpWidget(MaterialApp(home: PublicFoldersPage()));

      await tester.pumpAndSettle();

      // Verify first page folders are displayed
      expect(find.text('Public Folder 0'), findsOneWidget);
      expect(find.text('Public Folder 9'), findsOneWidget);

      // Scroll to bottom to trigger pagination
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Mock second page
      final secondPageFolders = List.generate(
        5,
        (index) => FolderModel(
          id: 'folder-${index + 10}',
          name: 'Public Folder ${index + 10}',
          userId: 'user-${index + 10}',
          parentFolderId: null,
          description: 'Description for folder ${index + 10}',
          coverImageUrl: 'https://example.com/cover${index + 10}.jpg',
          createdAt: DateTime.now().subtract(Duration(days: index + 10)),
          isShared: false,
          isPublic: true,
          isLocked: false,
          lockedAt: null,
          contributorIds: [],
        ),
      );

      when(
        mockFolderService.getPublicFolders(page: 1, limit: 10),
      ).thenAnswer((_) async => secondPageFolders);

      await tester.pumpAndSettle();

      // Should load more folders
      expect(find.text('Public Folder 10'), findsOneWidget);
      expect(find.text('Public Folder 14'), findsOneWidget);
    });

    testWidgets('Test error handling in public folder operations', (
      WidgetTester tester,
    ) async {
      // Mock network error
      when(
        mockFolderService.getPublicFolders(),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(MaterialApp(home: PublicFoldersPage()));

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test retry functionality
      when(mockFolderService.getPublicFolders()).thenAnswer((_) async => []);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show empty state
      expect(find.text('No public folders found'), findsOneWidget);
    });

    testWidgets('Test public folder owner controls', (
      WidgetTester tester,
    ) async {
      // Test data - public folder owned by current user
      final ownedPublicFolder = FolderModel(
        id: 'owned-public-folder-id',
        name: 'My Public Folder',
        userId: 'test-user-id', // Current user is owner
        parentFolderId: null,
        description: 'My public vacation photos',
        coverImageUrl: 'https://example.com/cover.jpg',
        createdAt: DateTime.now(),
        isShared: false,
        isPublic: true,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

      // Mock service responses
      when(
        mockFolderService.getFolder('owned-public-folder-id'),
      ).thenAnswer((_) async => ownedPublicFolder);

      await tester.pumpWidget(
        MaterialApp(home: FolderDetailPage(folderId: 'owned-public-folder-id')),
      );

      await tester.pumpAndSettle();

      // Verify owner has full controls
      expect(find.text('My Public Folder'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);

      // Should have owner controls
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Test settings access
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should show all owner options
      expect(find.text('Make Private'), findsOneWidget);
      expect(find.text('Edit Folder'), findsOneWidget);
      expect(find.text('Delete Folder'), findsOneWidget);
    });

    testWidgets('Test public folder empty state', (WidgetTester tester) async {
      // Mock empty public folders response
      when(mockFolderService.getPublicFolders()).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(home: PublicFoldersPage()));

      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('No public folders found'), findsOneWidget);
      expect(
        find.text('Be the first to share your memories publicly!'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.public_off), findsOneWidget);
    });

    testWidgets('Test public folder content preview', (
      WidgetTester tester,
    ) async {
      // Test data - public folder with media preview
      final publicFolder = FolderModel(
        id: 'preview-folder-id',
        name: 'Beach Vacation',
        userId: 'user1-id',
        parentFolderId: null,
        description: 'Amazing beach vacation memories',
        coverImageUrl: 'https://example.com/beach-cover.jpg',
        createdAt: DateTime.now(),
        isShared: false,
        isPublic: true,
        isLocked: false,
        lockedAt: null,
        contributorIds: [],
      );

      // Mock service responses
      when(
        mockFolderService.getPublicFolders(),
      ).thenAnswer((_) async => [publicFolder]);

      await tester.pumpWidget(MaterialApp(home: PublicFoldersPage()));

      await tester.pumpAndSettle();

      // Verify folder preview card
      expect(find.text('Beach Vacation'), findsOneWidget);
      expect(find.text('Amazing beach vacation memories'), findsOneWidget);
      expect(find.text('by @user1'), findsOneWidget);

      // Should show cover image
      expect(find.byType(Image), findsOneWidget);

      // Should show public indicator
      expect(find.byIcon(Icons.public), findsOneWidget);

      // Should show folder stats (if available)
      expect(find.text('5 photos'), findsOneWidget);
      expect(find.text('2 videos'), findsOneWidget);
    });
  });
}
