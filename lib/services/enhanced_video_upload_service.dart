import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/validation_utils.dart';

enum VideoUploadState {
  idle,
  preparing,
  uploading,
  processing,
  completed,
  cancelled,
  failed,
}

class VideoUploadProgress {
  final VideoUploadState state;
  final double progress;
  final String? message;
  final String? error;

  const VideoUploadProgress({
    required this.state,
    this.progress = 0.0,
    this.message,
    this.error,
  });

  VideoUploadProgress copyWith({
    VideoUploadState? state,
    double? progress,
    String? message,
    String? error,
  }) {
    return VideoUploadProgress(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

class EnhancedVideoUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Track active uploads
  final Map<String, UploadTask> _activeUploads = {};
  final Map<String, StreamSubscription> _uploadSubscriptions = {};
  final Map<String, StreamController<VideoUploadProgress>> _progressControllers = {};

  /// Upload a video with enhanced state management
  Future<String> uploadVideoWithStateManagement({
    required File videoFile,
    required String path,
    required String uploadId,
    Function(VideoUploadProgress)? onProgress,
  }) async {
    StreamController<VideoUploadProgress>? progressController;
    StreamSubscription? uploadSubscription;
    
    try {
      // Initialize progress tracking
      progressController = StreamController<VideoUploadProgress>.broadcast();
      _progressControllers[uploadId] = progressController;
      
      // Listen to progress updates
      if (onProgress != null) {
        progressController.stream.listen(onProgress);
      }

      // Emit preparing state
      _emitProgress(uploadId, VideoUploadProgress(
        state: VideoUploadState.preparing,
        message: 'Preparing video upload...',
      ));

      // Validate video file
      final validationError = ValidationUtils.validateFileUpload(videoFile, expectedType: 'video');
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Check authentication
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Sanitize path
      final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
      
      // Create storage reference
      final ref = _storage.ref().child(sanitizedPath);
      
      // Prepare metadata
      final metadata = SettableMetadata(
        contentType: _getVideoContentType(videoFile.path),
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'uploadId': uploadId,
        },
      );

      // Emit uploading state
      _emitProgress(uploadId, VideoUploadProgress(
        state: VideoUploadState.uploading,
        message: 'Starting video upload...',
      ));

      // Create upload task
      final uploadTask = ref.putFile(videoFile, metadata);
      _activeUploads[uploadId] = uploadTask;

      // Listen to upload progress with proper state management
      uploadSubscription = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          _handleUploadSnapshot(uploadId, snapshot);
        },
        onError: (error) {
          _emitProgress(uploadId, VideoUploadProgress(
            state: VideoUploadState.failed,
            error: 'Upload stream error: $error',
          ));
        },
        onDone: () {
          // Clean up subscription when done
          _uploadSubscriptions.remove(uploadId)?.cancel();
        },
      );
      
      _uploadSubscriptions[uploadId] = uploadSubscription;

      // Wait for upload completion
      final snapshot = await uploadTask;
      
      // Emit processing state
      _emitProgress(uploadId, VideoUploadProgress(
        state: VideoUploadState.processing,
        progress: 1.0,
        message: 'Processing video...',
      ));

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL after video upload');
      }

      // Emit completed state
      _emitProgress(uploadId, VideoUploadProgress(
        state: VideoUploadState.completed,
        progress: 1.0,
        message: 'Video upload completed successfully',
      ));

      return downloadUrl;

    } on FirebaseException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'unauthorized':
          errorMessage = 'Unauthorized access to Firebase Storage. Please check your authentication.';
          break;
        case 'canceled':
          errorMessage = 'Video upload was canceled';
          _emitProgress(uploadId, VideoUploadProgress(
            state: VideoUploadState.cancelled,
            error: errorMessage,
          ));
          rethrow;
        case 'unknown':
          errorMessage = 'Unknown error occurred during video upload. Please try again.';
          break;
        case 'retry-limit-exceeded':
          errorMessage = 'Upload retry limit exceeded. Please try again later.';
          break;
        case 'invalid-checksum':
          errorMessage = 'File integrity check failed. Please try uploading again.';
          break;
        default:
          errorMessage = 'Firebase Storage error: ${e.message ?? e.code}';
      }
      
      _emitProgress(uploadId, VideoUploadProgress(
        state: VideoUploadState.failed,
        error: errorMessage,
      ));
      
      throw Exception(errorMessage);
      
    } catch (e) {
      final errorMessage = 'Failed to upload video: $e';
      _emitProgress(uploadId, VideoUploadProgress(
        state: VideoUploadState.failed,
        error: errorMessage,
      ));
      
      if (e is Exception) {
        rethrow;
      }
      throw Exception(errorMessage);
      
    } finally {
      // Clean up resources
      await _cleanupUpload(uploadId);
    }
  }

  /// Handle upload task snapshot events
  void _handleUploadSnapshot(String uploadId, TaskSnapshot snapshot) {
    final progress = snapshot.totalBytes > 0 
        ? snapshot.bytesTransferred / snapshot.totalBytes 
        : 0.0;

    switch (snapshot.state) {
      case TaskState.running:
        _emitProgress(uploadId, VideoUploadProgress(
          state: VideoUploadState.uploading,
          progress: progress,
          message: 'Uploading: ${(progress * 100).toStringAsFixed(1)}%',
        ));
        break;
        
      case TaskState.paused:
        _emitProgress(uploadId, VideoUploadProgress(
          state: VideoUploadState.uploading,
          progress: progress,
          message: 'Upload paused',
        ));
        break;
        
      case TaskState.success:
        _emitProgress(uploadId, VideoUploadProgress(
          state: VideoUploadState.processing,
          progress: 1.0,
          message: 'Upload completed, processing...',
        ));
        break;
        
      case TaskState.canceled:
        _emitProgress(uploadId, VideoUploadProgress(
          state: VideoUploadState.cancelled,
          progress: progress,
          message: 'Upload was canceled',
        ));
        break;
        
      case TaskState.error:
        _emitProgress(uploadId, VideoUploadProgress(
          state: VideoUploadState.failed,
          progress: progress,
          error: 'Upload failed during transfer',
        ));
        break;
    }
  }

  /// Cancel an active upload
  Future<bool> cancelUpload(String uploadId) async {
    try {
      final uploadTask = _activeUploads[uploadId];
      if (uploadTask != null) {
        final success = await uploadTask.cancel();
        
        if (success) {
          _emitProgress(uploadId, VideoUploadProgress(
            state: VideoUploadState.cancelled,
            message: 'Upload canceled by user',
          ));
        }
        
        await _cleanupUpload(uploadId);
        return success;
      }
      return false;
    } catch (e) {
      _emitProgress(uploadId, VideoUploadProgress(
        state: VideoUploadState.failed,
        error: 'Failed to cancel upload: $e',
      ));
      return false;
    }
  }

  /// Pause an active upload
  Future<bool> pauseUpload(String uploadId) async {
    try {
      final uploadTask = _activeUploads[uploadId];
      if (uploadTask != null) {
        final success = await uploadTask.pause();
        
        if (success) {
          _emitProgress(uploadId, VideoUploadProgress(
            state: VideoUploadState.uploading,
            message: 'Upload paused',
          ));
        }
        
        return success;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Resume a paused upload
  Future<bool> resumeUpload(String uploadId) async {
    try {
      final uploadTask = _activeUploads[uploadId];
      if (uploadTask != null) {
        final success = await uploadTask.resume();
        
        if (success) {
          _emitProgress(uploadId, VideoUploadProgress(
            state: VideoUploadState.uploading,
            message: 'Upload resumed',
          ));
        }
        
        return success;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get upload progress stream
  Stream<VideoUploadProgress>? getUploadProgressStream(String uploadId) {
    return _progressControllers[uploadId]?.stream;
  }

  /// Check if upload is active
  bool isUploadActive(String uploadId) {
    return _activeUploads.containsKey(uploadId);
  }

  /// Get active upload IDs
  List<String> getActiveUploadIds() {
    return _activeUploads.keys.toList();
  }

  /// Emit progress update
  void _emitProgress(String uploadId, VideoUploadProgress progress) {
    final controller = _progressControllers[uploadId];
    if (controller != null && !controller.isClosed) {
      controller.add(progress);
    }
  }

  /// Clean up upload resources
  Future<void> _cleanupUpload(String uploadId) async {
    // Cancel and remove subscription
    await _uploadSubscriptions.remove(uploadId)?.cancel();
    
    // Remove upload task
    _activeUploads.remove(uploadId);
    
    // Close and remove progress controller
    final controller = _progressControllers.remove(uploadId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  /// Get appropriate content type for video file
  String _getVideoContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4'; // Default fallback
    }
  }

  /// Clean up all active uploads (call on app dispose)
  Future<void> dispose() async {
    // Cancel all active uploads
    final uploadIds = List<String>.from(_activeUploads.keys);
    for (final uploadId in uploadIds) {
      await cancelUpload(uploadId);
    }
    
    // Clean up any remaining resources
    for (final subscription in _uploadSubscriptions.values) {
      await subscription.cancel();
    }
    _uploadSubscriptions.clear();
    
    for (final controller in _progressControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _progressControllers.clear();
    
    _activeUploads.clear();
  }
}