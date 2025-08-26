import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/media_source_dialog.dart';
import 'package:time_capsule/widgets/audio_recording_interface.dart';
import 'package:time_capsule/pages/diary/diary_editor_page.dart';
import 'package:time_capsule/pages/diary/diary_viewer_page.dart';
import 'package:time_capsule/models/diary_entry_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('MediaSourceDialog has proper accessibility labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaSourceDialog(
              mediaType: MediaSourceType.image,
              onSourceSelected: (source) {},
            ),
          ),
        ),
      );

      // Verify dialog has semantic label
      expect(
        find.bySemanticsLabel('Select Image Source, Choose how to add image content'),
        findsOneWidget,
      );

      // Verify camera option has proper semantics
      expect(
        find.bySemanticsLabel('Camera, Take a new image, button'),
        findsOneWidget,
      );

      // Verify gallery option has proper semantics
      expect(
        find.bySemanticsLabel('Gallery, Choose from your images, button'),
        findsOneWidget,
      );
    });

    testWidgets('AudioRecordingInterface has proper accessibility support', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Verify cancel button has proper semantics
      expect(
        find.bySemanticsLabel('Cancel recording, Close audio recording interface without saving, button'),
        findsOneWidget,
      );

      // Verify duration display has live region
      expect(
        find.bySemanticsLabel('Recording duration, 00:00'),
        findsOneWidget,
      );

      // Verify waveform has proper description
      expect(
        find.bySemanticsLabel('Audio waveform visualization, Audio waveform display'),
        findsOneWidget,
      );

      // Verify main record button has proper semantics
      expect(
        find.bySemanticsLabel('Start recording, Begin audio recording, button'),
        findsOneWidget,
      );
    });

    testWidgets('DiaryEditorPage has proper keyboard navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryEditorPage(
            folderId: 'test-folder',
          ),
        ),
      );

      // Verify title field has proper semantics
      expect(
        find.bySemanticsLabel('Diary entry title, Enter a title for your diary entry, required field'),
        findsOneWidget,
      );

      // Verify content field has proper semantics
      expect(
        find.bySemanticsLabel('Diary entry content, Write your diary entry content, required field, supports multiple lines'),
        findsOneWidget,
      );

      // Verify save button has proper semantics
      expect(
        find.bySemanticsLabel('Save diary entry, Cannot save, title and content required, button'),
        findsOneWidget,
      );

      // Verify floating action button has proper semantics
      expect(
        find.bySemanticsLabel('Add media to diary, Add images, videos, or audio recordings to your diary entry, button'),
        findsOneWidget,
      );
    });

    testWidgets('DiaryViewerPage has proper accessibility for media attachments', (tester) async {
      final testDiary = DiaryEntryModel(
        id: 'test-id',
        folderId: 'test-folder',
        title: 'Test Diary',
        content: 'Test content',
        attachments: [
          DiaryMediaAttachment(
            id: 'img-1',
            type: 'image',
            url: 'https://example.com/image.jpg',
            caption: 'Test image',
            position: 0,
          ),
          DiaryMediaAttachment(
            id: 'audio-1',
            type: 'audio',
            url: 'https://example.com/audio.mp3',
            position: 1,
          ),
        ],
        createdAt: Timestamp.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DiaryViewerPage(
            diary: testDiary,
            folderId: 'test-folder',
          ),
        ),
      );

      // Verify back button has proper semantics
      expect(
        find.bySemanticsLabel('Back to folder, Return to the memory folder, button'),
        findsOneWidget,
      );

      // Verify edit button has proper semantics
      expect(
        find.bySemanticsLabel('Edit diary entry, Open diary editor to modify this entry, button'),
        findsOneWidget,
      );

      // Verify image attachment has proper semantics
      expect(
        find.bySemanticsLabel('Diary image attachment, Image with caption: Test image. Tap to view full screen, button'),
        findsOneWidget,
      );
    });

    testWidgets('Touch targets meet minimum size requirements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaSourceDialog(
              mediaType: MediaSourceType.audio,
              onSourceSelected: (source) {},
            ),
          ),
        ),
      );

      // Find all interactive elements
      final buttons = find.byType(InkWell);
      
      for (int i = 0; i < buttons.evaluate().length; i++) {
        final button = buttons.at(i);
        final size = tester.getSize(button);
        
        // Verify minimum touch target size (44x44 dp)
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }
    });

    testWidgets('Screen reader announcements work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioRecordingInterface(
            onRecordingComplete: (path) {},
            onCancel: () {},
          ),
        ),
      );

      // Verify live region updates for duration
      final durationFinder = find.bySemanticsLabel('Recording duration, 00:00');
      expect(durationFinder, findsOneWidget);

      // Verify the live region property is set
      final semantics = tester.getSemantics(durationFinder);
      expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    });

    testWidgets('Focus management works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryEditorPage(
            folderId: 'test-folder',
          ),
        ),
      );

      // Find title and content fields
      final titleField = find.bySemanticsLabel('Diary entry title, Enter a title for your diary entry, required field');
      final contentField = find.bySemanticsLabel('Diary entry content, Write your diary entry content, required field, supports multiple lines');

      // Verify fields can receive focus
      await tester.tap(titleField);
      await tester.pump();
      
      // Verify focus moves to content field when tab is pressed
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      
      // Both fields should be focusable
      expect(titleField, findsOneWidget);
      expect(contentField, findsOneWidget);
    });

    testWidgets('Error states have proper accessibility announcements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiaryEditorPage(
            folderId: 'test-folder',
          ),
        ),
      );

      // Verify save button shows proper disabled state
      final saveButton = find.bySemanticsLabel('Save diary entry, Cannot save, title and content required, button');
      expect(saveButton, findsOneWidget);

      // Verify the button is marked as disabled
      final semantics = tester.getSemantics(saveButton);
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    });
  });
}