import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/video_upload_test.dart';
import '../../services/video_integration_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class VideoTestPage extends StatefulWidget {
  const VideoTestPage({super.key});

  @override
  State<VideoTestPage> createState() => _VideoTestPageState();
}

class _VideoTestPageState extends State<VideoTestPage> {
  final List<String> _testResults = [];
  bool _isRunningTests = false;
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Upload Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            _buildUserInfo(),
            const SizedBox(height: 20),

            // Test buttons
            _buildTestButtons(),
            const SizedBox(height: 20),

            // Video selection
            _buildVideoSelection(),
            const SizedBox(height: 20),

            // Test results
            _buildTestResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Authentication Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (user != null) ...[
              Text('✅ Authenticated as: ${user.email}'),
              Text('User ID: ${user.uid}'),
            ] else ...[
              const Text('❌ Not authenticated'),
              const Text('Please log in to test video uploads'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Functions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunningTests ? null : _runAllTests,
                    child: _isRunningTests
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Running...'),
                            ],
                          )
                        : const Text('Run All Tests'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearResults,
                    child: const Text('Clear Results'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Upload Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Select Video'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedVideo != null ? _testVideoUpload : null,
                    icon: const Icon(Icons.upload),
                    label: const Text('Test Upload'),
                  ),
                ),
              ],
            ),
            if (_selectedVideo != null) ...[
              const SizedBox(height: 8),
              Text('Selected: ${_selectedVideo!.path.split('/').last}'),
              ElevatedButton(
                onPressed: () => _previewVideo(_selectedVideo!),
                child: const Text('Preview Video'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _testResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No test results yet.\nRun tests to see results here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _testResults.length,
                        itemBuilder: (context, index) {
                          final result = _testResults[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              result,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: result.startsWith('✅')
                                    ? Colors.green
                                    : result.startsWith('❌')
                                        ? Colors.red
                                        : result.startsWith('⚠️')
                                            ? Colors.orange
                                            : null,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    // Capture print statements
    final originalPrint = print;
    print = (Object? object) {
      setState(() {
        _testResults.add(object.toString());
      });
    };

    try {
      await VideoUploadTest.runAllTests();
    } catch (e) {
      setState(() {
        _testResults.add('❌ Test execution failed: $e');
      });
    } finally {
      print = originalPrint;
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _selectVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );

      if (pickedFile != null) {
        setState(() {
          _selectedVideo = File(pickedFile.path);
        });
        
        _addTestResult('✅ Video selected: ${pickedFile.name}');
      }
    } catch (e) {
      _addTestResult('❌ Video selection failed: $e');
    }
  }

  Future<void> _testVideoUpload() async {
    if (_selectedVideo == null) return;

    _addTestResult('🔄 Starting video upload test...');

    try {
      // Test upload using video integration service
      final testMessageId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final videoUrl = await VideoIntegrationService.uploadScheduledMessageVideo(
        _selectedVideo!,
        testMessageId,
      );

      _addTestResult('✅ Video upload successful!');
      _addTestResult('   URL: $videoUrl');

      // Test if we can access the uploaded video
      final isVideo = await VideoIntegrationService.isVideoUrl(videoUrl);
      _addTestResult('✅ Video URL validation: $isVideo');

      // Clean up - delete the test video
      try {
        await VideoIntegrationService.deleteVideo(videoUrl);
        _addTestResult('✅ Test video cleanup successful');
      } catch (e) {
        _addTestResult('⚠️ Cleanup failed (not critical): $e');
      }

    } catch (e) {
      _addTestResult('❌ Video upload failed: $e');
    }
  }

  void _previewVideo(File video) {
    VideoIntegrationService.showFullScreenVideo(
      context,
      video.path,
      title: 'Video Preview',
    );
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }
}