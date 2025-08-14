import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:time_capsule/main.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/media_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/media_file_model.dart';

// Generate mocks
@GenerateMocks([
  FolderService,
  MediaService,
])
import 'file_management_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('File Management Integration Tests', () {
    late MockFolderService mockFolderService;
    late MockMediaService mockMediaService;

    setUp(() {
      mockFolderService = MockFolderService();
      mockMediaService = MockMediaService();
    });

    testWidgets('Complete folder creation and management flow', (WidgetTester tester) async {
      // Setup mock data
      final testFolder = FolderModel(
        id: 'test-folder-id',
        name: 'Test Folder',
        userId: 'test-user-id',
        parentFolderId: null,
        description: 'Test description',
        coverImageUrl: null,
        createdAt: DateTime.now(),
      );

      when(mockFolderService.streamFolders(userId: anyNamed('userId')))
          .thenAnswer((_) => Stream.value([testFolder]));
      when(mockFolderService.createFolder(any))
          .thenAnswer((_) async => 'new-folder-id');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FolderService>.value(value: mockFolderService),
            Provider<MediaService>.value(value: mockMediaService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to memory album page
      await tester.tap(find.text('My Memories'));
      await tester.pumpAndSettle();

      // Should display existing folder
      expect(find.text('Test Folder'), findsOneWidget);

      // Test folder creation
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Folder'));
      await tester.pumpAndSettle();

      // Enter folder name
      await tester.enterText(find.byType(TextFormField), 'New Folder');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify folder creation was called
      verify(mockFolderService.createFolder(any)).called(1);
    });

    testWidgets('Folder options menu and editing flow', (WidgetTester tester) async {
      // Setup mock data
      final testFolder = FolderModel(
        id: 'test-folder-id',
        name: 'Test Folder',
        userId: 'test-user-id',
        parentFolderId: null,
        description: null,
        coverImageUrl: null,
        createdAt: DateTime.now(),
      );

      when(mockFolderService.streamFolders(userId: anyNamed('userId')))
          .thenAnswer((_) => Stream.value([testFolder]));
      when(mockFolderService.updateFolderName(any, any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FolderService>.value(value: mockFolderService),
            Provider<MediaService>.value(value: mockMediaService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to memory album page
      await tester.tap(find.text('My Memories'));
      await tester.pumpAndSettle();

      // Tap options menu on folder
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Should show options menu
      expect(find.text('Edit Name'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Test edit name
      await tester.tap(find.text('Edit Name'));
      await tester.pumpAndSettle();

      // Should show edit dialog
      expect(find.text('Edit Folder Name'), findsOneWidget);

      // Change name
      await tester.enterText(find.byType(TextFormField), 'Updated Folder Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify update was called
      verify(mockFolderService.updateFolderName('test-folder-id', 'Updated Folder Name')).called(1);
    });

    testWidgets('Multi-select and batch delete flow', (WidgetTester tester) async {
      // Setup mock data with multiple folders
      final testFolders = [
        FolderModel(
          id: 'folder-1',
          name: 'Folder 1',
          userId: 'test-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: DateTime.now(),
        ),
        FolderModel(
          id: 'folder-2',
          name: 'Folder 2',
          userId: 'test-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: DateTime.now(),
        ),
        FolderModel(
          id: 'folder-3',
          name: 'Folder 3',
          userId: 'test-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockFolderService.streamFolders(userId: anyNamed('userId')))
          .thenAnswer((_) => Stream.value(testFolders));
      when(mockFolderService.deleteFolders(any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FolderService>.value(value: mockFolderService),
            Provider<MediaService>.value(value: mockMediaService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to memory album page
      await tester.tap(find.text('My Memories'));
      await tester.pumpAndSettle();

      // Should display all folders
      expect(find.text('Folder 1'), findsOneWidget);
      expect(find.text('Folder 2'), findsOneWidget);
      expect(find.text('Folder 3'), findsOneWidget);

      // Long press on first folder to enter multi-select mode
      await tester.longPress(find.text('Folder 1'));
      await tester.pumpAndSettle();

      // Should enter multi-select mode
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap on second folder to add to selection
      await tester.tap(find.text('Folder 2'));
      await tester.pumpAndSettle();

      // Should show 2 selected
      expect(find.text('2 selected'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Items'), findsOneWidget);
      expect(find.text('Are you sure you want to delete 2 item(s)?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify batch delete was called
      verify(mockFolderService.deleteFolders(['folder-1', 'folder-2'])).called(1);
    });

    testWidgets('Media file management flow', (WidgetTester tester) async {
      // Setup mock data
      final testFolder = FolderModel(
        id: 'test-folder-id',
        name: 'Test Folder',
        userId: 'test-user-id',
        parentFolderId: null,
        description: null,
        coverImageUrl: null,
        createdAt: DateTime.now(),
      );

      final testMedia = [
        MediaFileModel(
          id: 'media-1',
          title: 'Photo 1',
          type: 'image',
          url: 'https://example.com/photo1.jpg',
          thumbnailUrl: null,
          content: null,
          createdAt: DateTime.now(),
        ),
        MediaFileModel(
          id: 'media-2',
          title: 'Video 1',
          type: 'video',
          url: 'https://example.com/video1.mp4',
          thumbnailUrl: null,
          content: null,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockFolderService.getFolder('test-folder-id'))
          .thenAnswer((_) async => testFolder);
      when(mockMediaService.streamMedia('test-folder-id'))
          .thenAnswer((_) => Stream.value(testMedia));
      when(mockMediaService.updateFileName(any, any, any))
          .thenAnswer((_) async {
            return;
          });
      when(mockMediaService.deleteFiles(any, any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FolderService>.value(value: mockFolderService),
            Provider<MediaService>.value(value: mockMediaService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to folder detail page
      // This would typically happen by tapping on a folder
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FolderService>.value(value: mockFolderService),
              Provider<MediaService>.value(value: mockMediaService),
            ],
            child: FolderDetailPage(folderId: 'test-folder-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display media files
      expect(find.text('Photo 1'), findsOneWidget);
      expect(find.text('Video 1'), findsOneWidget);

      // Test media file editing
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Name'));
      await tester.pumpAndSettle();

      // Change media name
      await tester.enterText(find.byType(TextFormField), 'Updated Photo Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify update was called
      verify(mockMediaService.updateFileName('test-folder-id', 'media-1', 'Updated Photo Name')).called(1);

      // Test multi-select for media files
      await tester.longPress(find.text('Photo 1'));
      await tester.pumpAndSettle();

      // Should enter multi-select mode
      expect(find.text('1 selected'), findsOneWidget);

      // Add second media to selection
      await tester.tap(find.text('Video 1'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      // Delete selected media
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify batch delete was called
      verify(mockMediaService.deleteFiles('test-folder-id', ['media-1', 'media-2'])).called(1);
    });

    testWidgets('Error handling in file operations', (WidgetTester tester) async {
      // Setup service to throw errors
      when(mockFolderService.streamFolders(userId: anyNamed('userId')))
          .thenAnswer((_) => Stream.error(Exception('Network error')));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FolderService>.value(value: mockFolderService),
            Provider<MediaService>.value(value: mockMediaService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to memory album page
      await tester.tap(find.text('My Memories'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Network error'), findsOneWidget);

      // Test retry functionality
      when(mockFolderService.streamFolders(userId: anyNamed('userId')))
          .thenAnswer((_) => Stream.value([]));

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show empty state or folders
      expect(find.text('No folders yet'), findsOneWidget);
    });

    testWidgets('File validation and error handling', (WidgetTester tester) async {
      // Setup mock data
      final testFolder = FolderModel(
        id: 'test-folder-id',
        name: 'Test Folder',
        userId: 'test-user-id',
        parentFolderId: null,
        description: null,
        coverImageUrl: null,
        createdAt: DateTime.now(),
      );

      when(mockFolderService.streamFolders(userId: anyNamed('userId')))
          .thenAnswer((_) => Stream.value([testFolder]));
      when(mockFolderService.updateFolderName(any, any))
          .thenThrow(Exception('Folder name contains invalid characters'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FolderService>.value(value: mockFolderService),
            Provider<MediaService>.value(value: mockMediaService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to memory album page
      await tester.tap(find.text('My Memories'));
      await tester.pumpAndSettle();

      // Try to edit folder with invalid name
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Name'));
      await tester.pumpAndSettle();

      // Enter invalid name
      await tester.enterText(find.byType(TextFormField), 'Invalid<>Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Folder name contains invalid characters'), findsOneWidget);
    });

    testWidgets('Nested folder navigation flow', (WidgetTester tester) async {
      // Setup nested folder structure
      final parentFolder = FolderModel(
        id: 'parent-folder-id',
        name: 'Parent Folder',
        userId: 'test-user-id',
        parentFolderId: null,
        description: null,
        coverImageUrl: null,
        createdAt: DateTime.now(),
      );

      final childFolder = FolderModel(
        id: 'child-folder-id',
        name: 'Child Folder',
        userId: 'test-user-id',
        parentFolderId: 'parent-folder-id',
        description: null,
        coverImageUrl: null,
        createdAt: DateTime.now(),
      );

      // Mock top-level folders
      when(mockFolderService.streamFolders(userId: anyNamed('userId'), parentFolderId: null))
          .thenAnswer((_) => Stream.value([parentFolder]));
      
      // Mock child folders
      when(mockFolderService.streamFolders(userId: anyNamed('userId'), parentFolderId: 'parent-folder-id'))
          .thenAnswer((_) => Stream.value([childFolder]));

      when(mockFolderService.getFolder('parent-folder-id'))
          .thenAnswer((_) async => parentFolder);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FolderService>.value(value: mockFolderService),
            Provider<MediaService>.value(value: mockMediaService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to memory album page
      await tester.tap(find.text('My Memories'));
      await tester.pumpAndSettle();

      // Should show parent folder
      expect(find.text('Parent Folder'), findsOneWidget);

      // Tap on parent folder to navigate into it
      await tester.tap(find.text('Parent Folder'));
      await tester.pumpAndSettle();

      // Should show child folder
      expect(find.text('Child Folder'), findsOneWidget);

      // Should show breadcrumb navigation
      expect(find.text('Parent Folder'), findsOneWidget); // In breadcrumb

      // Test navigation back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should be back to top level
      expect(find.text('Parent Folder'), findsOneWidget);
    });
  });
}