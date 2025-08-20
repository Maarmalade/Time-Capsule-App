import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:time_capsule/services/enhanced_video_upload_service.dart';
import 'package:time_capsule/widgets/enhanced_video_upload_widget.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Video Upload State Management Integration Tests', () {
    late EnhancedVideoUploadService uploadService;

    setUpAll(() async {
      await FirebaseTestHelper.initializeFirebase();
    });

    setUp(() {
      uploadService = EnhancedVideoUploadService();
    });

    tearDown(() async {
      await uploadService.dispose();
    });

    tearDownAll(() async {
      await FirebaseTestHelper.cleanup();
    });

    testWidgets('should handle upload service lifecycle correctly', (WidgetTester tester) async {
      // Test service initialization and disposal
      final service = EnhancedVideoUploadService();
      
      // Verify initial state
      expect(service.getActiveUploadIds(), isEmpty);
      
      // Test disposal
      await service.dispose();
      expect(service.getActiveUploadIds(), isEmpty);
    });

    testWidgets('should manage upload states properly', (WidgetTester tester) async {
      // Test upload state management
      const uploadId = 'test-upload-state';
      
      // Verify no active uploads initially
      expect(uploadService.isUploadActive(uploadId), isFalse);
      
      // Test cancel non-existent upload
      final cancelResult = await uploadService.cancelUpload(uploadId);
      expect(cancelResult, isFalse);
    });

    testWidgets('should handle multiple upload operations', (WidgetTester tester) async {
      // Test multiple upload management
      const uploadId1 = 'upload-1';
      const uploadId2 = 'upload-2';
      
      // Verify initial state
      expect(uploadService.getActiveUploadIds(), isEmpty);
      
      // Test pause/resume non-existent uploads
      expect(await uploadService.pauseUpload(uploadId1), isFalse);
      expect(await uploadService.resumeUpload(uploadId1), isFalse);
      expect(await uploadService.pauseUpload(uploadId2), isFalse);
      expect(await uploadService.resumeUpload(uploadId2), isFalse);
    });

    testWidgets('should render enhanced upload widget correctly', (WidgetTester tester) async {
      String? uploadedUrl;
      String? errorMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) => uploadedUrl = url,
              uploadPath: 'test/upload/path',
              onError: (error) => errorMessage = error,
              allowCancel: true,
              showProgress: true,
            ),
          ),
        ),
      );

      // Verify initial UI state
      expect(find.text('Select Video'), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      
      // Verify widget renders without errors
      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
    });

    testWidgets('should handle upload widget configuration', (WidgetTester tester) async {
      // Test different widget configurations
      
      // Configuration 1: With cancel and progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path1',
              allowCancel: true,
              showProgress: true,
            ),
          ),
        ),
      );
      
      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
      
      // Configuration 2: Without cancel and progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoUploadWidget(
              onVideoUploaded: (url) {},
              uploadPath: 'test/path2',
              allowCancel: false,
              showProgress: false,
            ),
          ),
        ),
      );
      
      expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
    });

    group('Upload Progress States', () {
      test('should create progress objects with all states', () {
        final states = [
          VideoUploadState.idle,
          VideoUploadState.preparing,
          VideoUploadState.uploading,
          VideoUploadState.processing,
          VideoUploadState.completed,
          VideoUploadState.cancelled,
          VideoUploadState.failed,
        ];

        for (final state in states) {
          final progress = VideoUploadProgress(
            state: state,
            progress: 0.5,
            message: 'Test message for $state',
          );
          
          expect(progress.state, state);
          expect(progress.progress, 0.5);
          expect(progress.message, 'Test message for $state');
        }
      });

      test('should handle progress copying correctly', () {
        const original = VideoUploadProgress(
          state: VideoUploadState.uploading,
          progress: 0.3,
          message: 'Original message',
        );

        // Test copying with state change
        final withNewState = original.copyWith(state: VideoUploadState.completed);
        expect(withNewState.state, VideoUploadState.completed);
        expect(withNewState.progress, 0.3); // Should remain unchanged
        expect(withNewState.message, 'Original message'); // Should remain unchanged

        // Test copying with progress change
        final withNewProgress = original.copyWith(progress: 0.8);
        expect(withNewProgress.state, VideoUploadState.uploading); // Should remain unchanged
        expect(withNewProgress.progress, 0.8);
        expect(withNewProgress.message, 'Original message'); // Should remain unchanged

        // Test copying with error
        final withError = original.copyWith(
          state: VideoUploadState.failed,
          error: 'Upload failed',
        );
        expect(withError.state, VideoUploadState.failed);
        expect(withError.error, 'Upload failed');
      });
    });

    group('Error Handling', () {
      testWidgets('should handle service errors gracefully', (WidgetTester tester) async {
        // Test error handling in upload service
        final service = EnhancedVideoUploadService();
        
        // Test operations on non-existent uploads
        expect(await service.cancelUpload('non-existent'), isFalse);
        expect(await service.pauseUpload('non-existent'), isFalse);
        expect(await service.resumeUpload('non-existent'), isFalse);
        
        await service.dispose();
      });

      testWidgets('should handle widget errors gracefully', (WidgetTester tester) async {
        String? capturedError;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnhancedVideoUploadWidget(
                onVideoUploaded: (url) {},
                uploadPath: 'test/error/path',
                onError: (error) => capturedError = error,
              ),
            ),
          ),
        );

        // Widget should render without throwing errors
        expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);
        expect(capturedError, isNull); // No errors should occur during rendering
      });
    });

    group('Resource Management', () {
      test('should clean up resources properly', () async {
        final service = EnhancedVideoUploadService();
        
        // Verify initial state
        expect(service.getActiveUploadIds(), isEmpty);
        
        // Test disposal
        await service.dispose();
        
        // Verify cleanup
        expect(service.getActiveUploadIds(), isEmpty);
      });

      testWidgets('should handle widget disposal correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnhancedVideoUploadWidget(
                onVideoUploaded: (url) {},
                uploadPath: 'test/disposal/path',
              ),
            ),
          ),
        );

        // Verify widget is rendered
        expect(find.byType(EnhancedVideoUploadWidget), findsOneWidget);

        // Navigate away to trigger disposal
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('New Page'),
            ),
          ),
        );

        // Verify navigation worked (widget should be disposed)
        expect(find.text('New Page'), findsOneWidget);
        expect(find.byType(EnhancedVideoUploadWidget), findsNothing);
      });
    });
  });
}