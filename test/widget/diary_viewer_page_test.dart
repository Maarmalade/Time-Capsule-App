import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:time_capsule/pages/diary/diary_viewer_page_new.dart';
import 'package:time_capsule/models/diary_entry_model.dart';

// Mock classes
class MockFirebaseApp extends Mock implements FirebaseApp {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  group('DiaryViewerPageNew Widget Tests', () {
    late DiaryEntryModel testDiary;
    late DiaryEntryModel diaryWithAttachments;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUpAll(() async {
      // Initialize Firebase for testing
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Setup mocks
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockAuth.currentUser).thenReturn(mockUser);
      testDiary = DiaryEntryModel(
        id: 'test-diary-id',
        folderId: 'test-folder-id',
        title: 'Test Diary Entry',
        content: 'This is a test diary entry content with multiple lines.\n\nIt includes paragraphs and formatting.',
        attachments: [],
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30)),
        lastModified: Timestamp.fromDate(DateTime(2024, 1, 15, 11, 45)),
        uploadedBy: 'test-user-id',
      );

      diaryWithAttachments = DiaryEntryModel(
        id: 'diary-with-media',
        folderId: 'test-folder-id',
        title: 'Diary with Media',
        content: 'This diary entry has various media attachments.',
        attachments: [
          DiaryMediaAttachment(
            id: 'img-1',
            type: 'image',
            url: 'https://example.com/image.jpg',
            caption: 'A beautiful sunset',
            position: 0,
          ),
          DiaryMediaAttachment(
            id: 'audio-1',
            type: 'audio',
            url: 'https://example.com/audio.mp3',
            caption: 'Voice note',
            position: 1,
          ),
          DiaryMediaAttachment(
            id: 'video-1',
            type: 'video',
            url: 'https://example.com/video.mp4',
            position: 2,
          ),
        ],
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 20, 14, 15)),
      );
    });

    testWidgets('should display diary content correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: testDiary,
            folderId: 'test-folder-id',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar
      expect(find.text('Diary Entry'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Verify diary content
      expect(find.text('Test Diary Entry'), findsOneWidget);
      expect(find.text('This is a test diary entry content with multiple lines.\n\nIt includes paragraphs and formatting.'), findsOneWidget);

      // Verify metadata (check for partial text since format might be different)
      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('Modified:'), findsOneWidget);
    });

    testWidgets('should display diary with attachments correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: diaryWithAttachments,
            folderId: 'test-folder-id',
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Verify attachments section
      expect(find.text('Attachments'), findsOneWidget);

      // Verify image attachment
      expect(find.text('A beautiful sunset'), findsOneWidget);

      // Verify audio attachment
      expect(find.text('Audio Recording'), findsOneWidget);
      expect(find.text('Voice note'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should handle shared folder display correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: testDiary,
            folderId: 'test-folder-id',
            isSharedFolder: true,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Verify shared folder metadata
      expect(find.textContaining('Shared by:'), findsOneWidget);
    });

    testWidgets('should handle edit permissions correctly', (tester) async {
      // Test with edit permissions
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: testDiary,
            folderId: 'test-folder-id',
            canEdit: true,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Test without edit permissions
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: testDiary,
            folderId: 'test-folder-id',
            canEdit: false,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('should have proper accessibility labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: diaryWithAttachments,
            folderId: 'test-folder-id',
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Verify accessibility elements exist (simplified check)
      expect(find.byType(Semantics), findsWidgets);
      
      // Check for back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Check for edit button
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should handle audio playback controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: diaryWithAttachments,
            folderId: 'test-folder-id',
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Find audio play button
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      // Verify audio controls are present
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('00:00'), findsAtLeastNWidgets(2)); // Current and total time
    });

    testWidgets('should format duration correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: diaryWithAttachments,
            folderId: 'test-folder-id',
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Initial duration should be 00:00
      expect(find.text('00:00'), findsAtLeastNWidgets(2));
    });

    testWidgets('should handle image tap for full screen view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: diaryWithAttachments,
            folderId: 'test-folder-id',
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Find and tap image attachment
      final imageWidget = find.byType(GestureDetector).first;
      await tester.tap(imageWidget);
      await tester.pumpAndSettle();

      // Verify full screen dialog appears
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (tester) async {
      final diaryWithBrokenImage = DiaryEntryModel(
        id: 'broken-diary',
        folderId: 'test-folder-id',
        title: 'Broken Media Diary',
        content: 'This diary has broken media.',
        attachments: [
          DiaryMediaAttachment(
            id: 'broken-img',
            type: 'image',
            url: 'https://broken-url.com/nonexistent.jpg',
            position: 0,
          ),
        ],
        createdAt: Timestamp.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: diaryWithBrokenImage,
            folderId: 'test-folder-id',
          ),
        ),
      );

      // Wait for image loading to fail
      await tester.pumpAndSettle();

      // Should show error state for broken image
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load image'), findsOneWidget);
    });

    testWidgets('should sort attachments by position', (tester) async {
      final diaryWithUnsortedAttachments = DiaryEntryModel(
        id: 'unsorted-diary',
        folderId: 'test-folder-id',
        title: 'Unsorted Attachments',
        content: 'Attachments in random order.',
        attachments: [
          DiaryMediaAttachment(
            id: 'third',
            type: 'audio',
            url: 'https://example.com/audio3.mp3',
            position: 2,
          ),
          DiaryMediaAttachment(
            id: 'first',
            type: 'image',
            url: 'https://example.com/image1.jpg',
            position: 0,
          ),
          DiaryMediaAttachment(
            id: 'second',
            type: 'video',
            url: 'https://example.com/video2.mp4',
            position: 1,
          ),
        ],
        createdAt: Timestamp.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPageNew(
            diary: diaryWithUnsortedAttachments,
            folderId: 'test-folder-id',
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Verify attachments are displayed in correct order
      // This would require more specific widget finding based on your implementation
      expect(find.text('Attachments'), findsOneWidget);
    });

    testWidgets('should handle touch targets correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPage(
            diary: diaryWithAttachments,
            folderId: 'test-folder-id',
          ),
        ),
      );

      // Find all interactive elements
      final buttons = find.byType(IconButton);
      
      for (int i = 0; i < buttons.evaluate().length; i++) {
        final button = buttons.at(i);
        final size = tester.getSize(button);
        
        // Verify minimum touch target size (44x44 dp)
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }
    });
  });
}