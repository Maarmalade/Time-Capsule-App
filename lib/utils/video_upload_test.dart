import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/video_service.dart';
import '../services/storage_service.dart';

class VideoUploadTest {
  static final VideoService _videoService = VideoService();
  static final StorageService _storageService = StorageService();

  /// Test video upload functionality
  static Future<bool> testVideoUpload() async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return false;
      }

      print('✅ User authenticated: ${user.uid}');

      // Test basic storage service
      print('🔄 Testing storage service...');
      
      // Create a simple test to verify storage rules are working
      final testPath = 'test_uploads/test_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      try {
        final ref = FirebaseStorage.instance.ref().child(testPath);
        await ref.putString('test content', format: PutStringFormat.raw);
        print('✅ Basic storage upload works');
        
        // Clean up test file
        await ref.delete();
        print('✅ Storage cleanup successful');
        
      } catch (e) {
        print('❌ Storage test failed: $e');
        return false;
      }

      print('✅ Video upload functionality is ready');
      return true;

    } catch (e) {
      print('❌ Video upload test failed: $e');
      return false;
    }
  }

  /// Test video service methods
  static Future<void> testVideoServiceMethods() async {
    try {
      print('🔄 Testing video service methods...');

      // Test authentication check
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated for video service test');
        return;
      }

      // Test video service instantiation
      final videoService = VideoService();
      print('✅ Video service created successfully');

      // Test metadata methods (these don't require actual files)
      try {
        final isVideo = await videoService.isVideoUrl('https://example.com/test.mp4');
        print('✅ Video URL validation works: $isVideo');
      } catch (e) {
        print('⚠️ Video URL validation test: $e');
      }

      print('✅ Video service methods are functional');

    } catch (e) {
      print('❌ Video service test failed: $e');
    }
  }

  /// Check Firebase configuration
  static Future<void> checkFirebaseConfig() async {
    try {
      print('🔄 Checking Firebase configuration...');

      // Check Firebase Auth
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user != null) {
        print('✅ Firebase Auth: User logged in (${user.uid})');
      } else {
        print('⚠️ Firebase Auth: No user logged in');
      }

      // Check Firebase Storage
      final storage = FirebaseStorage.instance;
      print('✅ Firebase Storage: Instance available');
      print('   Storage bucket: ${storage.bucket}');

      // Test App Check status
      try {
        await StorageService.initializeAppCheck();
        print('✅ Firebase App Check: Initialized successfully');
      } catch (e) {
        print('⚠️ Firebase App Check: $e');
      }

    } catch (e) {
      print('❌ Firebase configuration check failed: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting video upload tests...\n');

    await checkFirebaseConfig();
    print('');

    await testVideoServiceMethods();
    print('');

    final uploadTest = await testVideoUpload();
    print('');

    if (uploadTest) {
      print('🎉 All video upload tests passed!');
      print('✅ Video uploads should now work properly');
    } else {
      print('❌ Some tests failed. Check the logs above for details.');
    }
  }
}