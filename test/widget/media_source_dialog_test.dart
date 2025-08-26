import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/media_source_dialog.dart';

void main() {
  group('MediaSourceDialog Widget Tests', () {
    testWidgets('should display image source options correctly', (tester) async {
      MediaSource? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaSourceDialog(
              mediaType: MediaSourceType.image,
              onSourceSelected: (source) {
                selectedSource = source;
              },
            ),
          ),
        ),
      );

      // Verify dialog title
      expect(find.text('Select Image Source'), findsOneWidget);

      // Verify camera option
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Take a new image'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // Verify gallery option
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Choose from your images'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);

      // Test camera selection
      await tester.tap(find.text('Camera'));
      await tester.pump();

      expect(selectedSource, equals(MediaSource.camera));
    });

    testWidgets('should display video source options correctly', (tester) async {
      MediaSource? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaSourceDialog(
              mediaType: MediaSourceType.video,
              onSourceSelected: (source) {
                selectedSource = source;
              },
            ),
          ),
        ),
      );

      // Verify dialog title
      expect(find.text('Select Video Source'), findsOneWidget);

      // Verify camera option
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Take a new video'), findsOneWidget);

      // Verify gallery option
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Choose from your videos'), findsOneWidget);

      // Test gallery selection
      await tester.tap(find.text('Gallery'));
      await tester.pump();

      expect(selectedSource, equals(MediaSource.gallery));
    });

    testWidgets('should display audio source options correctly', (tester) async {
      MediaSource? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaSourceDialog(
              mediaType: MediaSourceType.audio,
              onSourceSelected: (source) {
                selectedSource = source;
              },
            ),
          ),
        ),
      );

      // Verify dialog title
      expect(find.text('Select Audio Source'), findsOneWidget);

      // Verify record option
      expect(find.text('Record Audio'), findsOneWidget);
      expect(find.text('Record a new voice note'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      // Verify select file option
      expect(find.text('Select Audio File'), findsOneWidget);
      expect(find.text('Choose from your audio files'), findsOneWidget);
      expect(find.byIcon(Icons.audio_file), findsOneWidget);

      // Test record selection
      await tester.tap(find.text('Record Audio'));
      await tester.pump();

      expect(selectedSource, equals(MediaSource.record));
    });

    testWidgets('should have proper accessibility labels', (tester) async {
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

      // Verify semantic labels exist
      expect(
        find.bySemanticsLabel('Select Image Source, Choose how to add image content'),
        findsOneWidget,
      );

      expect(
        find.bySemanticsLabel('Camera, Take a new image, button'),
        findsOneWidget,
      );

      expect(
        find.bySemanticsLabel('Gallery, Choose from your images, button'),
        findsOneWidget,
      );
    });

    testWidgets('should handle touch targets correctly', (tester) async {
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
      final inkWells = find.byType(InkWell);
      
      for (int i = 0; i < inkWells.evaluate().length; i++) {
        final inkWell = inkWells.at(i);
        final size = tester.getSize(inkWell);
        
        // Verify minimum touch target size (44x44 dp)
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }
    });

    testWidgets('should show static method correctly', (tester) async {
      MediaSource? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await MediaSourceDialog.show(
                    context: context,
                    mediaType: MediaSourceType.image,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Select Image Source'), findsOneWidget);

      // Select camera option
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, equals(MediaSource.camera));
    });

    testWidgets('should convert MediaSource to ImageSource correctly', (tester) async {
      expect(
        MediaSourceDialog.toImageSource(MediaSource.camera),
        equals(ImageSource.camera),
      );

      expect(
        MediaSourceDialog.toImageSource(MediaSource.gallery),
        equals(ImageSource.gallery),
      );

      expect(
        MediaSourceDialog.toImageSource(MediaSource.record),
        isNull,
      );

      expect(
        MediaSourceDialog.toImageSource(MediaSource.selectFile),
        isNull,
      );
    });
  });
}