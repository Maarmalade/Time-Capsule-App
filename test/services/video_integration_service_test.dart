import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/services/video_integration_service.dart';
import 'package:time_capsule/widgets/video_player_widget.dart';

void main() {
  group('VideoIntegrationService Tests', () {
    testWidgets('should create video thumbnail widget', (WidgetTester tester) async {
      // Arrange
      const testVideoUrl = 'https://test-video-url.com/video.mp4';
      bool tapped = false;

      // Act
      final thumbnail = VideoIntegrationService.createVideoThumbnail(
        videoUrl: testVideoUrl,
        onTap: () => tapped = true,
        width: 150,
        height: 100,
        title: 'Test Video',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: thumbnail),
        ),
      );

      // Assert
      expect(find.byType(VideoThumbnailWidget), findsOneWidget);
      
      // Test tap functionality
      await tester.tap(find.byType(VideoThumbnailWidget));
      expect(tapped, isTrue);
    });

    testWidgets('should create inline video player widget', (WidgetTester tester) async {
      // Arrange
      const testVideoUrl = 'https://test-video-url.com/video.mp4';
      String? capturedError;

      // Act
      final videoPlayer = VideoIntegrationService.createInlineVideoPlayer(
        videoUrl: testVideoUrl,
        autoPlay: false,
        showControls: true,
        onError: (error) => capturedError = error,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: videoPlayer),
        ),
      );

      // Assert
      expect(find.byType(VideoPlayerWidget), findsOneWidget);
    });

    testWidgets('should show video dialog', (WidgetTester tester) async {
      // Arrange
      const testVideoUrl = 'https://test-video-url.com/video.mp4';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VideoIntegrationService.showVideoDialog(
                  context,
                  testVideoUrl,
                  title: 'Test Video',
                ),
                child: const Text('Show Video'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Video'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(VideoPlayerWidget), findsOneWidget);
    });

    testWidgets('should show video options bottom sheet', (WidgetTester tester) async {
      // Arrange
      const testVideoUrl = 'https://test-video-url.com/video.mp4';
      bool sharePressed = false;
      bool deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VideoIntegrationService.showVideoOptionsBottomSheet(
                  context,
                  videoUrl: testVideoUrl,
                  title: 'Test Video',
                  onShare: () => sharePressed = true,
                  onDelete: () => deletePressed = true,
                ),
                child: const Text('Show Options'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Options'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Play Video'), findsOneWidget);
      expect(find.text('Play in Dialog'), findsOneWidget);
      expect(find.text('Share Video'), findsOneWidget);
      expect(find.text('Delete Video'), findsOneWidget);

      // Test share functionality
      await tester.tap(find.text('Share Video'));
      await tester.pumpAndSettle();
      expect(sharePressed, isTrue);
    });

    group('Video Upload Methods', () {
      test('should have upload methods for different features', () {
        // Test that all upload methods exist and are callable
        expect(VideoIntegrationService.uploadScheduledMessageVideo, isA<Function>());
        expect(VideoIntegrationService.uploadDiaryVideo, isA<Function>());
        expect(VideoIntegrationService.uploadMemoryAlbumVideo, isA<Function>());
        expect(VideoIntegrationService.uploadFolderVideo, isA<Function>());
      });

      test('should have utility methods', () {
        // Test that utility methods exist
        expect(VideoIntegrationService.isVideoUrl, isA<Function>());
        expect(VideoIntegrationService.deleteVideo, isA<Function>());
        expect(VideoIntegrationService.getVideoMetadata, isA<Function>());
      });
    });
  });
}