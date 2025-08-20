import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/video_player_widget.dart';

void main() {
  group('VideoPlayerWidget Tests', () {
    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      // Arrange
      const testVideoUrl = 'https://test-video-url.com/video.mp4';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(videoUrl: testVideoUrl),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading video...'), findsOneWidget);
    });

    testWidgets('should show error message for empty URL', (WidgetTester tester) async {
      // Arrange
      const emptyUrl = '';
      String? capturedError;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(
              videoUrl: emptyUrl,
              onError: (error) => capturedError = error,
            ),
          ),
        ),
      );

      // Wait for error to be processed
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to load video'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should show error message for invalid URL format', (WidgetTester tester) async {
      // Arrange
      const invalidUrl = 'invalid-url';
      String? capturedError;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(
              videoUrl: invalidUrl,
              onError: (error) => capturedError = error,
            ),
          ),
        ),
      );

      // Wait for error to be processed
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to load video'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should allow retry on error', (WidgetTester tester) async {
      // Arrange
      const invalidUrl = 'invalid-url';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(videoUrl: invalidUrl),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap retry button
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);
      
      await tester.tap(retryButton);
      await tester.pump();

      // Assert - should show loading again
      expect(find.text('Loading video...'), findsOneWidget);
    });
  });

  group('VideoThumbnailWidget Tests', () {
    testWidgets('should display video thumbnail with play button', (WidgetTester tester) async {
      // Arrange
      const testVideoUrl = 'https://test-video-url.com/video.mp4';
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoThumbnailWidget(
              videoUrl: testVideoUrl,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(VideoThumbnailWidget));
      expect(tapped, isTrue);
    });

    testWidgets('should respect custom dimensions', (WidgetTester tester) async {
      // Arrange
      const testVideoUrl = 'https://test-video-url.com/video.mp4';
      const customWidth = 200.0;
      const customHeight = 150.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoThumbnailWidget(
              videoUrl: testVideoUrl,
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.constraints?.maxWidth, customWidth);
    });
  });
}