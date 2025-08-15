import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/media_attachment_widget.dart';

void main() {
  group('MediaAttachmentWidget Integration Tests', () {
    testWidgets('widget renders without errors', (WidgetTester tester) async {
      List<File> selectedImages = [];
      File? selectedVideo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaAttachmentWidget(
              selectedImages: selectedImages,
              selectedVideo: selectedVideo,
              onImagesChanged: (images) {
                selectedImages = images;
              },
              onVideoChanged: (video) {
                selectedVideo = video;
              },
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(MediaAttachmentWidget), findsOneWidget);
      
      // Verify basic UI elements
      expect(find.text('Add Images (0/5)'), findsOneWidget);
      expect(find.text('Add Video'), findsOneWidget);
      
      // Verify no selected media section is shown initially
      expect(find.text('Selected Media:'), findsNothing);
    });

    testWidgets('shows selected media section when images are provided', (WidgetTester tester) async {
      final mockImages = [File('test_image.jpg')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaAttachmentWidget(
              selectedImages: mockImages,
              selectedVideo: null,
              onImagesChanged: (images) {},
              onVideoChanged: (video) {},
            ),
          ),
        ),
      );

      // Verify selected media section appears
      expect(find.text('Selected Media:'), findsOneWidget);
      expect(find.text('Add Images (1/5)'), findsOneWidget);
    });

    testWidgets('shows video selected state', (WidgetTester tester) async {
      final mockVideo = File('test_video.mp4');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaAttachmentWidget(
              selectedImages: const [],
              selectedVideo: mockVideo,
              onImagesChanged: (images) {},
              onVideoChanged: (video) {},
            ),
          ),
        ),
      );

      // Verify video button changes to remove
      expect(find.text('Remove Video'), findsOneWidget);
      expect(find.text('Selected Media:'), findsOneWidget);
      expect(find.text('Video Selected'), findsOneWidget);
    });

    testWidgets('respects max images limit', (WidgetTester tester) async {
      final mockImages = List.generate(3, (index) => File('test_image$index.jpg'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaAttachmentWidget(
              selectedImages: mockImages,
              selectedVideo: null,
              onImagesChanged: (images) {},
              onVideoChanged: (video) {},
              maxImages: 3,
            ),
          ),
        ),
      );

      expect(find.text('Add Images (3/3)'), findsOneWidget);
    });

    testWidgets('handles empty state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaAttachmentWidget(
              selectedImages: const [],
              selectedVideo: null,
              onImagesChanged: (images) {},
              onVideoChanged: (video) {},
            ),
          ),
        ),
      );

      expect(find.text('Add Images (0/5)'), findsOneWidget);
      expect(find.text('Add Video'), findsOneWidget);
      expect(find.text('Selected Media:'), findsNothing);
    });
  });
}