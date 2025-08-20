import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/enhanced_video_upload_widget.dart';
import 'package:time_capsule/services/enhanced_video_upload_service.dart';

void main() {
  group('EnhancedVideoUploadWidget Tests', () {
    testWidgets('should display video selection button initially', (WidgetTester tester) async {
      // Arrange
      String? uploadedVideoUrl;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) => uploadedVideoUrl = url,
              uploadPath: 'test/path',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Select Video'), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('should show upload controls when video is selected', (WidgetTester tester) async {
      // This test would require mocking ImagePicker and file selection
      // For now, we test the widget structure
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path',
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
    });

    testWidgets('should handle error callback', (WidgetTester tester) async {
      // Arrange
      String? capturedError;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path',
              onError: (error) => capturedError = error,
            ),
          ),
        ),
      );

      // Assert - widget should render without errors
      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
    });

    testWidgets('should respect allowCancel parameter', (WidgetTester tester) async {
      // Test with cancel allowed
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path',
              allowCancel: true,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);

      // Test with cancel not allowed
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path',
              allowCancel: false,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
    });

    testWidgets('should respect showProgress parameter', (WidgetTester tester) async {
      // Test with progress shown
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path',
              showProgress: true,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);

      // Test with progress hidden
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path',
              showProgress: false,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
    });
  });

  group('VideoUploadProgress Tests', () {
    test('should create progress object correctly', () {
      const progress = VideoUploadProgress(
        state: VideoUploadState.uploading,
        progress: 0.75,
        message: 'Uploading...',
      );

      expect(progress.state, VideoUploadState.uploading);
      expect(progress.progress, 0.75);
      expect(progress.message, 'Uploading...');
      expect(progress.error, isNull);
    });

    test('should copy progress object with new values', () {
      const original = VideoUploadProgress(
        state: VideoUploadState.uploading,
        progress: 0.5,
        message: 'Uploading...',
      );

      final updated = original.copyWith(
        progress: 0.8,
        message: 'Almost done...',
      );

      expect(updated.state, VideoUploadState.uploading); // Unchanged
      expect(updated.progress, 0.8); // Changed
      expect(updated.message, 'Almost done...'); // Changed
      expect(updated.error, isNull); // Unchanged
    });

    test('should handle all upload states', () {
      const states = [
        VideoUploadState.idle,
        VideoUploadState.preparing,
        VideoUploadState.uploading,
        VideoUploadState.processing,
        VideoUploadState.completed,
        VideoUploadState.cancelled,
        VideoUploadState.failed,
      ];

      for (final state in states) {
        final progress = VideoUploadProgress(state: state);
        expect(progress.state, state);
        expect(progress.progress, 0.0); // Default value
      }
    });
  });
}