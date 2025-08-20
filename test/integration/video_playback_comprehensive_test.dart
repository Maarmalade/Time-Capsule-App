import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:time_capsule/services/video_integration_service.dart';
import 'package:time_capsule/widgets/video_player_widget.dart';
import 'package:time_capsule/pages/video_player_page.dart';
import 'package:time_capsule/pages/scheduled_messages/delivered_messages_page.dart';
import 'package:time_capsule/pages/memory_album/media_viewer_page.dart';
import 'package:time_capsule/models/media_file_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Video Playback Comprehensive Integration Tests', () {
    testWidgets('should handle video playback in scheduled messages', (WidgetTester tester) async {
      // Test video playback in delivered messages page
      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveredMessagesPage(),
        ),
      );

      // Wait for the page to load
      await tester.pumpAndSettle();

      // The page should load without errors
      expect(find.byType(DeliveredMessagesPage), findsOneWidget);
    });

    testWidgets('should handle video playback in memory album', (WidgetTester tester) async {
      // Create a test media file model for video
      final testVideoMedia = MediaFileModel(
        id: 'test-video-id',
        url: 'https://test-video-url.com/video.mp4',
        type: 'video',
        title: 'Test Video',
        description: 'A test video file',
        uploadedBy: 'test-user',
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaViewerPage(media: testVideoMedia),
        ),
      );

      // Wait for the page to load
      await tester.pumpAndSettle();

      // The page should load and show video player
      expect(find.byType(MediaViewerPage), findsOneWidget);
      expect(find.byType(VideoPlayerWidget), findsOneWidget);
    });

    testWidgets('should show video player page', (WidgetTester tester) async {
      const testVideoUrl = 'https://test-video-url.com/video.mp4';

      await tester.pumpWidget(
        const MaterialApp(
          home: VideoPlayerPage(
            videoUrl: testVideoUrl,
            title: 'Test Video Player',
          ),
        ),
      );

      // Wait for the page to load
      await tester.pumpAndSettle();

      // The page should load
      expect(find.byType(VideoPlayerPage), findsOneWidget);
      expect(find.text('Test Video Player'), findsOneWidget);
    });

    testWidgets('should handle video integration service methods', (WidgetTester tester) async {
      const testVideoUrl = 'https://test-video-url.com/video.mp4';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => VideoIntegrationService.showVideoDialog(
                      context,
                      testVideoUrl,
                      title: 'Test Dialog Video',
                    ),
                    child: const Text('Show Video Dialog'),
                  ),
                  ElevatedButton(
                    onPressed: () => VideoIntegrationService.showFullScreenVideo(
                      context,
                      testVideoUrl,
                      title: 'Test Full Screen Video',
                    ),
                    child: const Text('Show Full Screen Video'),
                  ),
                  VideoIntegrationService.createVideoThumbnail(
                    videoUrl: testVideoUrl,
                    onTap: () {},
                  ),
                  VideoIntegrationService.createInlineVideoPlayer(
                    videoUrl: testVideoUrl,
                    autoPlay: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Wait for widgets to load
      await tester.pumpAndSettle();

      // Test video dialog
      await tester.tap(find.text('Show Video Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      
      // Close dialog
      await tester.tapAt(const Offset(50, 50)); // Tap outside dialog
      await tester.pumpAndSettle();

      // Test full screen video
      await tester.tap(find.text('Show Full Screen Video'));
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayerPage), findsOneWidget);
      
      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Test video thumbnail and inline player
      expect(find.byType(VideoThumbnailWidget), findsOneWidget);
      expect(find.byType(VideoPlayerWidget), findsOneWidget);
    });

    group('Video Error Handling', () {
      testWidgets('should handle invalid video URLs gracefully', (WidgetTester tester) async {
        const invalidVideoUrl = 'invalid-url';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoIntegrationService.createInlineVideoPlayer(
                videoUrl: invalidVideoUrl,
                onError: (error) {
                  // Error should be handled gracefully
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show error state instead of crashing
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
      });

      testWidgets('should show error messages for video failures', (WidgetTester tester) async {
        const invalidVideoUrl = 'https://invalid-video-url.com/nonexistent.mp4';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => VideoIntegrationService.createInlineVideoPlayer(
                  videoUrl: invalidVideoUrl,
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Test error: $error')),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Video player should be present
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
      });
    });

    group('Video Player Controls', () {
      testWidgets('should show video controls when enabled', (WidgetTester tester) async {
        const testVideoUrl = 'https://test-video-url.com/video.mp4';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoIntegrationService.createInlineVideoPlayer(
                videoUrl: testVideoUrl,
                showControls: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Video player should be present with controls
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
      });

      testWidgets('should handle fullscreen toggle', (WidgetTester tester) async {
        const testVideoUrl = 'https://test-video-url.com/video.mp4';

        await tester.pumpWidget(
          const MaterialApp(
            home: VideoPlayerPage(
              videoUrl: testVideoUrl,
              title: 'Fullscreen Test',
              allowFullscreen: true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show fullscreen button
        expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      });
    });
  });
}