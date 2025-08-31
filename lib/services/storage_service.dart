import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  /// Initialize App Check to avoid placeholder token warnings
  static Future<void> initializeAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
    } catch (e) {
      debugPrint('Failed to initialize App Check: $e');
      // Continue without App Check in case of initialization failure
    }
  }

  /// Uploads a video file with enhanced state management
  Future<String> uploadVideo(File videoFile, String path, {Function(double)? onProgress}) async {
    StreamSubscription<TaskSnapshot>? subscription;
    
    try {
      // Validate video file
      final validationError = ValidationUtils.validateFileUpload(videoFile, expectedType: 'video');
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Sanitize path
      final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
      
      final ref = _storage.ref().child(sanitizedPath);
      
      // Add metadata to help with storage rules
      final metadata = SettableMetadata(
        contentType: _getVideoContentType(videoFile.path),
        customMetadata: {
          'uploadedBy': _auth.currentUser?.uid ?? 'unknown',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putFile(videoFile, metadata);
      
      // Listen to upload progress with proper subscription management
      subscription = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.totalBytes > 0 
              ? snapshot.bytesTransferred / snapshot.totalBytes 
              : 0.0;
          
          onProgress?.call(progress);
          
          // Handle state transitions properly without causing conflicts
          switch (snapshot.state) {
            case TaskState.running:
              // Only log significant progress updates to avoid spam
              if (progress == 0.0 || progress >= 1.0 || (progress * 100) % 10 == 0) {
                debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
              }
              break;
            case TaskState.paused:
              debugPrint('Upload paused at ${(progress * 100).toStringAsFixed(1)}%');
              break;
            case TaskState.success:
              debugPrint('Upload completed successfully');
              break;
            case TaskState.canceled:
              debugPrint('Upload was canceled');
              break;
            case TaskState.error:
              debugPrint('Upload failed');
              break;
          }
        },
        onError: (error) {
          debugPrint('Upload stream error: $error');
        },
        onDone: () {
          debugPrint('Upload stream completed');
        },
      );
      
      // Wait for upload completion
      final snapshot = await uploadTask;
      
      // Clean up subscription
      await subscription.cancel();
      subscription = null;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL after video upload');
      }
      
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      // Handle specific Firebase Storage errors
      String errorMessage;
      switch (e.code) {
        case 'unauthorized':
          errorMessage = 'Unauthorized access to Firebase Storage. Please check your authentication.';
          break;
        case 'canceled':
          errorMessage = 'Video upload was canceled';
          break;
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
      
      throw Exception(errorMessage);
      
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload video: ${ErrorHandler.getErrorMessage(e)}');
      
    } finally {
      // Ensure subscription is always cleaned up
      await subscription?.cancel();
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

  /// Get appropriate content type for any file
  String _getContentType(String filePath, String? expectedType) {
    final extension = filePath.toLowerCase().split('.').last;
    
    // If expected type is provided, use specific logic
    if (expectedType != null) {
      switch (expectedType.toLowerCase()) {
        case 'video':
          return _getVideoContentType(filePath);
        case 'image':
          return _getImageContentType(extension);
        case 'audio':
          return _getAudioContentType(extension);
        default:
          break;
      }
    }
    
    // General content type detection
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      
      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      
      default:
        return 'application/octet-stream';
    }
  }

  /// Get image content type
  String _getImageContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Get audio content type
  String _getAudioContentType(String extension) {
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/mp4';
    }
  }

  /// Handle Firebase Storage specific errors
  String _handleFirebaseStorageError(FirebaseException e) {
    switch (e.code) {
      case 'storage/unauthorized':
        return 'Unauthorized access to storage. Please check your authentication.';
      case 'storage/canceled':
        return 'Upload was canceled';
      case 'storage/unknown':
        return 'Unknown storage error occurred. Please try again.';
      case 'storage/invalid-format':
        return 'Invalid file format. Please check the file type.';
      case 'storage/invalid-event-name':
        return 'Invalid storage operation';
      case 'storage/invalid-url':
        return 'Invalid storage URL';
      case 'storage/invalid-argument':
        return 'Invalid argument provided to storage operation';
      case 'storage/no-default-bucket':
        return 'No default storage bucket configured';
      case 'storage/cannot-slice-blob':
        return 'File processing error occurred';
      case 'storage/server-file-wrong-size':
        return 'File size mismatch during upload';
      case 'storage/quota-exceeded':
        return 'Storage quota exceeded. Please free up space or upgrade your plan.';
      case 'storage/unauthenticated':
        return 'Authentication required for storage access';
      case 'storage/retry-limit-exceeded':
        return 'Upload retry limit exceeded. Please try again later.';
      case 'storage/invalid-checksum':
        return 'File integrity check failed. Please try uploading again.';
      case 'storage/object-not-found':
        return 'File not found in storage';
      default:
        return 'Storage error: ${e.message ?? e.code}';
    }
  }

  /// Determine if upload should be retried based on error
  bool _shouldRetryUpload(FirebaseException e) {
    // Don't retry for these error types
    final nonRetryableErrors = [
      'storage/unauthorized',
      'storage/unauthenticated',
      'storage/invalid-format',
      'storage/invalid-argument',
      'storage/quota-exceeded',
      'storage/object-not-found',
      'storage/no-default-bucket',
    ];
    
    return !nonRetryableErrors.contains(e.code);
  }

  /// Uploads a file to Firebase Storage with comprehensive error handling and retry logic
  Future<String> uploadFile(File file, String path, {
    String? expectedType,
    Function(double progress)? onProgress,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < maxRetries) {
      try {
        // Validate file before upload
        final validationError = ValidationUtils.validateFileUpload(file, expectedType: expectedType);
        if (validationError != null) {
          throw Exception(validationError);
        }

        // Validate path
        if (path.isEmpty) {
          throw Exception('Upload path cannot be empty');
        }

        // Check authentication
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('User must be authenticated to upload files');
        }

        // Sanitize path to prevent directory traversal
        final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
        
        final ref = _storage.ref().child(sanitizedPath);
        
        // Add metadata for better tracking
        final metadata = SettableMetadata(
          contentType: _getContentType(file.path, expectedType),
          customMetadata: {
            'uploadedBy': currentUser.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': file.path.split('/').last,
          },
        );
        
        final uploadTask = ref.putFile(file, metadata);
        
        // Track upload progress
        StreamSubscription<TaskSnapshot>? subscription;
        if (onProgress != null) {
          subscription = uploadTask.snapshotEvents.listen((snapshot) {
            final progress = snapshot.totalBytes > 0 
                ? snapshot.bytesTransferred / snapshot.totalBytes 
                : 0.0;
            onProgress(progress);
          });
        }
        
        try {
          final snapshot = await uploadTask;
          await subscription?.cancel();
          
          final downloadUrl = await snapshot.ref.getDownloadURL();
          
          if (downloadUrl.isEmpty) {
            throw Exception('Failed to get download URL after upload');
          }
          
          return downloadUrl;
        } finally {
          await subscription?.cancel();
        }
        
      } on FirebaseException catch (e) {
        lastException = Exception(_handleFirebaseStorageError(e));
        
        // Don't retry for certain error types
        if (!_shouldRetryUpload(e)) {
          throw lastException;
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Upload attempt $retryCount failed, retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
        
      } catch (e) {
        if (e is Exception) {
          lastException = e;
        } else {
          lastException = Exception('Failed to upload file: ${ErrorHandler.getErrorMessage(e)}');
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Upload attempt $retryCount failed, retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }

    throw lastException ?? Exception('Upload failed after $maxRetries attempts');
  }

  /// Uploads file bytes to Firebase Storage with comprehensive error handling and retry logic
  Future<String> uploadFileBytes(
    Uint8List bytes, 
    String path, {
    Function(double progress)? onProgress,
    int maxRetries = 3,
    String? contentType,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < maxRetries) {
      try {
        // Validate inputs
        if (bytes.isEmpty) {
          throw Exception('File data is empty');
        }

        if (path.isEmpty) {
          throw Exception('Upload path cannot be empty');
        }

        // Check authentication
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('User must be authenticated to upload files');
        }

        // Check file size against different limits based on file type
        final fileExtension = path.toLowerCase().split('.').last;
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension);
        final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(fileExtension);
        final isAudio = ['mp3', 'm4a', 'wav', 'aac', 'ogg'].contains(fileExtension);

        int maxSize = ValidationUtils.maxFileSize;
        if (isImage) {
          maxSize = ValidationUtils.maxImageSize;
        } else if (isVideo) {
          maxSize = ValidationUtils.maxVideoSize;
        } else if (isAudio) {
          maxSize = ValidationUtils.maxAudioSize;
        }

        if (bytes.length > maxSize) {
          final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(0);
          throw Exception('File size exceeds maximum allowed size of ${maxSizeMB}MB');
        }

        // Sanitize path
        final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
        
        final ref = _storage.ref().child(sanitizedPath);
        
        // Add metadata
        final metadata = SettableMetadata(
          contentType: contentType ?? _getContentType(path, null),
          customMetadata: {
            'uploadedBy': currentUser.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'fileSize': bytes.length.toString(),
          },
        );
        
        final uploadTask = ref.putData(bytes, metadata);
        
        // Track upload progress
        StreamSubscription<TaskSnapshot>? subscription;
        if (onProgress != null) {
          subscription = uploadTask.snapshotEvents.listen((snapshot) {
            final progress = snapshot.totalBytes > 0 
                ? snapshot.bytesTransferred / snapshot.totalBytes 
                : 0.0;
            onProgress(progress);
          });
        }
        
        try {
          final snapshot = await uploadTask;
          await subscription?.cancel();
          
          final downloadUrl = await snapshot.ref.getDownloadURL();
          
          if (downloadUrl.isEmpty) {
            throw Exception('Failed to get download URL after upload');
          }
          
          return downloadUrl;
        } finally {
          await subscription?.cancel();
        }
        
      } on FirebaseException catch (e) {
        lastException = Exception(_handleFirebaseStorageError(e));
        
        // Don't retry for certain error types
        if (!_shouldRetryUpload(e)) {
          throw lastException;
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Upload bytes attempt $retryCount failed, retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
        
      } catch (e) {
        if (e is Exception) {
          lastException = e;
        } else {
          lastException = Exception('Failed to upload file: ${ErrorHandler.getErrorMessage(e)}');
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Upload bytes attempt $retryCount failed, retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }

    throw lastException ?? Exception('Upload failed after $maxRetries attempts');
  }

  /// Deletes a file from Firebase Storage with comprehensive error handling and retry logic
  Future<void> deleteFile(String url, {int maxRetries = 2}) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < maxRetries) {
      try {
        if (url.isEmpty) {
          throw Exception('File URL cannot be empty');
        }

        // Validate URL format
        if (!url.startsWith('https://') || !url.contains('firebasestorage.googleapis.com')) {
          throw Exception('Invalid Firebase Storage URL');
        }

        // Check authentication
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('User must be authenticated to delete files');
        }

        final ref = _storage.refFromURL(url);
        await ref.delete();
        return; // Success
        
      } on FirebaseException catch (e) {
        // Don't throw error if file doesn't exist
        if (e.code == 'storage/object-not-found') {
          return; // File already deleted or never existed
        }
        
        lastException = Exception(_handleFirebaseStorageError(e));
        
        // Don't retry for certain error types
        if (!_shouldRetryDelete(e)) {
          throw lastException;
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Delete attempt $retryCount failed, retrying in $retryCount seconds...');
          await Future.delayed(Duration(seconds: retryCount));
        }
        
      } catch (e) {
        if (e is Exception) {
          lastException = e;
        } else {
          lastException = Exception('Failed to delete file: ${ErrorHandler.getErrorMessage(e)}');
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Delete attempt $retryCount failed, retrying in $retryCount seconds...');
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    }

    throw lastException ?? Exception('Delete failed after $maxRetries attempts');
  }

  /// Determine if delete operation should be retried based on error
  bool _shouldRetryDelete(FirebaseException e) {
    // Don't retry for these error types
    final nonRetryableErrors = [
      'storage/unauthorized',
      'storage/unauthenticated',
      'storage/object-not-found',
      'storage/invalid-url',
      'storage/invalid-argument',
    ];
    
    return !nonRetryableErrors.contains(e.code);
  }

  /// Deletes multiple files with error handling for each file
  Future<List<String>> deleteFiles(List<String> urls) async {
    final errors = <String>[];
    
    for (final url in urls) {
      try {
        await deleteFile(url);
      } catch (e) {
        errors.add('Failed to delete file $url: ${ErrorHandler.getErrorMessage(e)}');
      }
    }
    
    return errors;
  }

  /// Gets file metadata with error handling
  Future<FullMetadata?> getFileMetadata(String url) async {
    try {
      if (url.isEmpty) {
        throw Exception('File URL cannot be empty');
      }

      final ref = _storage.refFromURL(url);
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null; // File doesn't exist
      }
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to get file metadata: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Gets a video download URL with proper authentication and error handling
  Future<String> getVideoDownloadUrl(String videoPath) async {
    try {
      if (videoPath.isEmpty) {
        throw Exception('Video path cannot be empty');
      }

      final ref = _storage.ref().child(videoPath);
      final downloadUrl = await ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get video download URL');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        throw Exception('Video file not found');
      } else if (e.code == 'unauthorized') {
        throw Exception('Unauthorized access to video file');
      }
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to get video URL: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Validates if a URL is a video file based on Firebase Storage metadata
  Future<bool> isVideoFile(String url) async {
    try {
      final metadata = await getFileMetadata(url);
      return metadata?.contentType?.startsWith('video/') ?? false;
    } catch (e) {
      return false;
    }
  }
}