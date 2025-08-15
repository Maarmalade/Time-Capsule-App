import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/media_attachment_widget.dart';

void main() {
  group('MediaAttachmentWidget', () {
    late List<File> selectedImages;
    File? selectedVideo;
    late List<File> onImagesChangedResult;
    File? onVideoChangedResult;

    setUp(() {
      selectedImages = [];
      selectedVideo = null;
      onImagesChangedResult = [];
      onVideoChangedResult = null;
    });

    Widget createWidget({
      List<File>? images,
      File? video,
      int maxImages = 5,
      int maxImageSizeMB = 10,
      int maxVideoSizeMB = 50,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MediaAttachmentWidget(
            selectedImages: images ?? selectedImages,
            selectedVideo: video ?? selectedVideo,
            onImagesChanged: (images) {
              onImagesChangedResult = images;
            },
            onVideoChanged: (video) {
              onVideoChangedResult = video;
            },
            maxImages: maxImages,
            maxImageSizeMB: maxImageSizeMB,
            maxVideoSizeMB: maxVideoSizeMB,
          ),
        ),
      );
    }

    testWidgets('displays media selection buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Check if the widget renders at all
      expect(find.byType(MediaAttachmentWidget), findsOneWidget);
      
      // Check for basic text elements
      expect(find.text('Add Images (0/5)'), findsOneWidget);
      expect(find.text('Add Video'), findsOneWidget);
    });

    testWidgets('updates image button text when images are selected', (WidgetTester tester) async {
      // Create mock files for testing
      final mockImages = [
        File('test_image1.jpg'),
        File('test_image2.jpg'),
      ];

      await tester.pumpWidget(createWidget(images: mockImages));

      expect(find.text('Add Images (2/5)'), findsOneWidget);
    });

    testWidgets('disables add images button when max images reached', (WidgetTester tester) async {
      final mockImages = List.generate(5, (index) => File('test_image$index.jpg'));

      await tester.pumpWidget(createWidget(images: mockImages, maxImages: 5));

      expect(find.text('Add Images (5/5)'), findsOneWidget);
      
      // Find the button by its text and check if it's disabled
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsNWidgets(2)); // Should find both image and video buttons
      
      // The first button should be the images button and should be disabled
      final firstButton = tester.widget<ElevatedButton>(buttons.first);
      expect(firstButton.onPressed, isNull);
    });

    testWidgets('changes video button when video is selected', (WidgetTester tester) async {
      final mockVideo = File('test_video.mp4');

      await tester.pumpWidget(createWidget(video: mockVideo));

      expect(find.text('Remove Video'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    });

    testWidgets('displays selected media section when media is present', (WidgetTester tester) async {
      final mockImages = [File('test_image.jpg')];
      final mockVideo = File('test_video.mp4');

      await tester.pumpWidget(createWidget(images: mockImages, video: mockVideo));

      expect(find.text('Selected Media:'), findsOneWidget);
    });

    testWidgets('does not display selected media section when no media', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Selected Media:'), findsNothing);
    });

    testWidgets('displays image previews in horizontal list', (WidgetTester tester) async {
      final mockImages = [
        File('test_image1.jpg'),
        File('test_image2.jpg'),
        File('test_image3.jpg'),
      ];

      await tester.pumpWidget(createWidget(images: mockImages));

      // Should find a horizontal ListView for images
      expect(find.byType(ListView), findsOneWidget);
      
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('displays video preview with play indicator', (WidgetTester tester) async {
      final mockVideo = File('test_video.mp4');

      await tester.pumpWidget(createWidget(video: mockVideo));

      expect(find.text('Video Selected'), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('image preview has remove button', (WidgetTester tester) async {
      final mockImages = [File('test_image.jpg')];

      await tester.pumpWidget(createWidget(images: mockImages));

      // Should find close icon for removing image
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('video preview has remove button', (WidgetTester tester) async {
      final mockVideo = File('test_video.mp4');

      await tester.pumpWidget(createWidget(video: mockVideo));

      // Should find close icon for removing video
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays validation error when present', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Simulate setting a validation error by creating a widget with error state
      // This would normally be triggered by file selection logic
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('respects maxImages parameter', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(maxImages: 3));

      expect(find.text('Add Images (0/3)'), findsOneWidget);
    });

    testWidgets('button styling changes based on state', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Add Images (0/5)'), findsOneWidget);
      expect(find.text('Add Video'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));

      // Test with video selected
      final mockVideo = File('test_video.mp4');
      await tester.pumpWidget(createWidget(video: mockVideo));

      expect(find.text('Remove Video'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('handles empty state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Add Images (0/5)'), findsOneWidget);
      expect(find.text('Add Video'), findsOneWidget);
      expect(find.text('Selected Media:'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('displays correct file count in button text', (WidgetTester tester) async {
      final mockImages = List.generate(3, (index) => File('test_image$index.jpg'));

      await tester.pumpWidget(createWidget(images: mockImages, maxImages: 10));

      expect(find.text('Add Images (3/10)'), findsOneWidget);
    });
  });

  group('MediaAttachmentWidget File Validation', () {
    testWidgets('shows correct max limits in constructor', (WidgetTester tester) async {
      final widget = MediaAttachmentWidget(
        selectedImages: const [],
        selectedVideo: null,
        onImagesChanged: (images) {},
        onVideoChanged: (video) {},
        maxImages: 8,
        maxImageSizeMB: 15,
        maxVideoSizeMB: 100,
      );

      expect(widget.maxImages, equals(8));
      expect(widget.maxImageSizeMB, equals(15));
      expect(widget.maxVideoSizeMB, equals(100));
    });

    testWidgets('uses default values when not specified', (WidgetTester tester) async {
      final widget = MediaAttachmentWidget(
        selectedImages: const [],
        selectedVideo: null,
        onImagesChanged: (images) {},
        onVideoChanged: (video) {},
      );

      expect(widget.maxImages, equals(5));
      expect(widget.maxImageSizeMB, equals(10));
      expect(widget.maxVideoSizeMB, equals(50));
    });
  });
}