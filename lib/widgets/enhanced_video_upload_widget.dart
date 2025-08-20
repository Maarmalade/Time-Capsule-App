import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/enhanced_video_upload_service.dart';
import '../utils/validation_utils.dart';

class EnhancedVideoUploadWidget extends StatefulWidget {
  final Function(String videoUrl) onVideoUploaded;
  final Function(String error)? onError;
  final String uploadPath;
  final bool allowCancel;
  final bool showProgress;

  const EnhancedVideoUploadWidget({
    super.key,
    required this.onVideoUploaded,
    required this.uploadPath,
    this.onError,
    this.allowCancel = true,
    this.showProgress = true,
  });

  @override
  State<EnhancedVideoUploadWidget> createState() => _EnhancedVideoUploadWidgetState();
}

class _EnhancedVideoUploadWidgetState extends State<EnhancedVideoUploadWidget> {
  final EnhancedVideoUploadService _uploadService = EnhancedVideoUploadService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedVideo;
  String? _currentUploadId;
  VideoUploadProgress? _uploadProgress;
  bool _isUploading = false;

  @override
  void dispose() {
    // Cancel any active uploads when widget is disposed
    if (_currentUploadId != null) {
      _uploadService.cancelUpload(_currentUploadId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video selection button
        if (!_isUploading) ...[
          ElevatedButton.icon(
            onPressed: _selectVideo,
            icon: const Icon(Icons.videocam),
            label: Text(_selectedVideo == null ? 'Select Video' : 'Change Video'),
          ),
        ],

        // Selected video preview
        if (_selectedVideo != null && !_isUploading) ...[
          const SizedBox(height: 16),
          _buildVideoPreview(),
        ],

        // Upload progress
        if (_isUploading && widget.showProgress) ...[
          const SizedBox(height: 16),
          _buildUploadProgress(),
        ],

        // Upload button
        if (_selectedVideo != null && !_isUploading) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _startUpload,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Video'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _clearSelection,
                child: const Text('Clear'),
              ),
            ],
          ),
        ],

        // Upload controls
        if (_isUploading && widget.allowCancel) ...[
          const SizedBox(height: 16),
          _buildUploadControls(),
        ],
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          // Video thumbnail placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Video Selected',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Play indicator
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                size: 30,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          
          // File info
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: FutureBuilder<int>(
              future: _selectedVideo!.length(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final sizeInMB = snapshot.data! / (1024 * 1024);
                  final fileName = _selectedVideo!.path.split('/').last;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${sizeInMB.toStringAsFixed(1)}MB',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    if (_uploadProgress == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State and message
            Row(
              children: [
                _getStateIcon(_uploadProgress!.state),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _uploadProgress!.message ?? _getStateMessage(_uploadProgress!.state),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress bar
            if (_uploadProgress!.state == VideoUploadState.uploading ||
                _uploadProgress!.state == VideoUploadState.processing) ...[
              LinearProgressIndicator(
                value: _uploadProgress!.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress!.progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            
            // Error message
            if (_uploadProgress!.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _uploadProgress!.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadControls() {
    return Row(
      children: [
        if (_uploadProgress?.state == VideoUploadState.uploading) ...[
          ElevatedButton.icon(
            onPressed: _pauseUpload,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
          const SizedBox(width: 8),
        ],
        
        if (_uploadProgress?.state == VideoUploadState.uploading && 
            _uploadProgress?.message?.contains('paused') == true) ...[
          ElevatedButton.icon(
            onPressed: _resumeUpload,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
          const SizedBox(width: 8),
        ],
        
        ElevatedButton.icon(
          onPressed: _cancelUpload,
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ],
    );
  }

  Widget _getStateIcon(VideoUploadState state) {
    switch (state) {
      case VideoUploadState.preparing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case VideoUploadState.uploading:
        return const Icon(Icons.cloud_upload, size: 16);
      case VideoUploadState.processing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case VideoUploadState.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case VideoUploadState.cancelled:
        return const Icon(Icons.cancel, color: Colors.orange, size: 16);
      case VideoUploadState.failed:
        return const Icon(Icons.error, color: Colors.red, size: 16);
      default:
        return const Icon(Icons.info, size: 16);
    }
  }

  String _getStateMessage(VideoUploadState state) {
    switch (state) {
      case VideoUploadState.preparing:
        return 'Preparing upload...';
      case VideoUploadState.uploading:
        return 'Uploading video...';
      case VideoUploadState.processing:
        return 'Processing video...';
      case VideoUploadState.completed:
        return 'Upload completed successfully';
      case VideoUploadState.cancelled:
        return 'Upload cancelled';
      case VideoUploadState.failed:
        return 'Upload failed';
      default:
        return 'Ready to upload';
    }
  }

  Future<void> _selectVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Validate video file
        final validationError = ValidationUtils.validateFileUpload(file, expectedType: 'video');
        if (validationError != null) {
          _showError(validationError);
          return;
        }

        setState(() {
          _selectedVideo = file;
        });
      }
    } catch (e) {
      _showError('Failed to select video: $e');
    }
  }

  Future<void> _startUpload() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isUploading = true;
      _currentUploadId = DateTime.now().millisecondsSinceEpoch.toString();
    });

    try {
      // Listen to upload progress
      final progressStream = _uploadService.getUploadProgressStream(_currentUploadId!);
      progressStream?.listen((progress) {
        setState(() {
          _uploadProgress = progress;
        });

        // Handle completion
        if (progress.state == VideoUploadState.completed) {
          setState(() {
            _isUploading = false;
            _selectedVideo = null;
            _uploadProgress = null;
          });
        }
      });

      // Start upload
      final videoUrl = await _uploadService.uploadVideoWithStateManagement(
        videoFile: _selectedVideo!,
        path: widget.uploadPath,
        uploadId: _currentUploadId!,
      );

      // Notify parent widget
      widget.onVideoUploaded(videoUrl);

    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showError('Upload failed: $e');
    }
  }

  Future<void> _pauseUpload() async {
    if (_currentUploadId != null) {
      await _uploadService.pauseUpload(_currentUploadId!);
    }
  }

  Future<void> _resumeUpload() async {
    if (_currentUploadId != null) {
      await _uploadService.resumeUpload(_currentUploadId!);
    }
  }

  Future<void> _cancelUpload() async {
    if (_currentUploadId != null) {
      await _uploadService.cancelUpload(_currentUploadId!);
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedVideo = null;
    });
  }

  void _showError(String error) {
    widget.onError?.call(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
  }
}