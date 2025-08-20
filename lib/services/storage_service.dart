import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
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
      print('Failed to initialize App Check: $e');
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

  /// Uploads a file to Firebase Storage with comprehensive error handling
  Future<String> uploadFile(File file, String path, {String? expectedType}) async {
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

      // Sanitize path to prevent directory traversal
      final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
      
      final ref = _storage.ref().child(sanitizedPath);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL after upload');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload file: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Uploads file bytes to Firebase Storage with comprehensive error handling
  Future<String> uploadFileBytes(Uint8List bytes, String path) async {
    try {
      // Validate inputs
      if (bytes.isEmpty) {
        throw Exception('File data is empty');
      }

      if (path.isEmpty) {
        throw Exception('Upload path cannot be empty');
      }

      // Check file size
      if (bytes.length > ValidationUtils.maxFileSize) {
        throw Exception('File size exceeds maximum allowed size');
      }

      // Sanitize path
      final sanitizedPath = path.replaceAll(RegExp(r'\.\.'), '').replaceAll('//', '/');
      
      final ref = _storage.ref().child(sanitizedPath);
      final uploadTask = await ref.putData(bytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL after upload');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload file: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Deletes a file from Firebase Storage with comprehensive error handling
  Future<void> deleteFile(String url) async {
    try {
      if (url.isEmpty) {
        throw Exception('File URL cannot be empty');
      }

      // Validate URL format
      if (!url.startsWith('https://') || !url.contains('firebasestorage.googleapis.com')) {
        throw Exception('Invalid Firebase Storage URL');
      }

      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Don't throw error if file doesn't exist
      if (e.code == 'object-not-found') {
        return; // File already deleted or never existed
      }
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete file: ${ErrorHandler.getErrorMessage(e)}');
    }
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