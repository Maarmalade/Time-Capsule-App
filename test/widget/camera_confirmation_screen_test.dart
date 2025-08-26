import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:time_capsule/widgets/camera_confirmation_screen.dart';

void main() {
  group('CameraConfirmationScreen Widget Tests', () {
    late XFile testImageFile;
    late XFile testVideoFile;

    setUp(() {
      testImageFile = XFile('test/assets/test_image.jpg');
      testVideoFile = XFile('test/assets/test_video.mp4');
    });

    testWidgets('should display image confirmation screen correctly', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: CameraConfirmationScreen(
            capturedMedia: testImageFile,
            mediaType: 'image',
            onConfirmation: (result) {
              confirmed = result;
            },
          ),
        ),
      );

      // Verify app bar elements
      expect(find.text('Photo Preview'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Verify bottom action buttons
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Use Photo'), findsOneWidget);

      // Test confirm action
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(confirmed, isTrue);
    });

    testWidgets('should display video confirmation screen correctly', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: CameraConfirmationScreen(
            capturedMedia: testVideoFile,
            mediaType: 'video',
            onConfirmation: (result) {
              confirmed = result;
            },
          ),
        ),
      );

      // Verify video-specific elements
      expect(find.text('Video Preview'), findsOneWidget);
      expect(find.text('Use Video'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Test retake action
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(confirmed, isFalse);
    });

    testWidgets('should have proper accessibility labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraConfirmationScreen(
            capturedMedia: testImageFile,
            mediaType: 'image',
            onConfirmation: (result) {},
          ),
        ),
      );

      // Verify retake button accessibility
      expect(
        find.bySemanticsLabel('Retake image, Discard current image and return to camera, button'),
        findsOneWidget,
      );

      // Verify confirm button accessibility
      expect(
        find.bySemanticsLabel('Confirm image, Use this image and continue, button'),
        findsOneWidget,
      );

      // Verify action buttons accessibility
      expect(
        find.bySemanticsLabel('Retake, button'),
        findsOneWidget,
      );

      expect(
        find.bySemanticsLabel('Use Photo, button'),
        findsOneWidget,
      );
    });

    testWidgets('should handle touch targets correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraConfirmationScreen(
            capturedMedia: testImageFile,
            mediaType: 'image',
            onConfirmation: (result) {},
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

    testWidgets('should display image preview with error handling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraConfirmationScreen(
            capturedMedia: XFile('nonexistent/path/image.jpg'),
            mediaType: 'image',
            onConfirmation: (result) {},
          ),
        ),
      );

      // Wait for image loading to complete (and fail)
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Unable to load image'), findsOneWidget);
    });

    testWidgets('should show static method correctly', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CameraConfirmationScreen.show(
                    context: context,
                    capturedMedia: testImageFile,
                    mediaType: 'image',
                  );
                },
                child: const Text('Show Confirmation'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show confirmation screen
      await tester.tap(find.text('Show Confirmation'));
      await tester.pumpAndSettle();

      // Verify confirmation screen is shown
      expect(find.text('Photo Preview'), findsOneWidget);

      // Confirm the image
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isTrue);
    });

    testWidgets('should handle both confirm and retake actions', (tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: CameraConfirmationScreen(
            capturedMedia: testImageFile,
            mediaType: 'image',
            onConfirmation: (result) {
              confirmed = result;
            },
          ),
        ),
      );

      // Test retake from top bar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(confirmed, isFalse);

      // Reset for next test
      confirmed = null;

      // Test confirm from bottom buttons
      await tester.tap(find.text('Use Photo'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('should display video placeholder correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraConfirmationScreen(
            capturedMedia: testVideoFile,
            mediaType: 'video',
            onConfirmation: (result) {},
          ),
        ),
      );

      // Verify video placeholder elements
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Video Preview'), findsAtLeastNWidgets(1));
      expect(find.text('Tap to play video'), findsOneWidget);
    });
  });
}