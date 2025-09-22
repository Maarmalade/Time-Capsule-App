import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'validation_utils.dart';
import 'error_handler.dart';

/// Utility class for handling file uploads with progress tracking and retry mechanisms
class UploadUtils {
  /// Maximum number of retry attempts for failed uploads
  static const int maxRetryAttempts = 3;
  
  /// Delay between retry attempts (in seconds)
  static const int retryDelaySeconds = 2;

  /// Upload a file with progress tracking and retry mechanism
  static Future<String> uploadWithRetry({
    required Future<String> Function() uploadFunction,
    required Function(double progress)? onProgress,
    required Function(String message)? onStatusUpdate,
    int maxAttempts = maxRetryAttempts,
  }) async {
    int attemptCount = 0;
    Exception? lastException;

    while (attemptCount < maxAttempts) {
      try {
        attemptCount++;
        
        // Update status
        if (attemptCount > 1) {
          onStatusUpdate?.call('Retry attempt $attemptCount of $maxAttempts...');
        } else {
          onStatusUpdate?.call('Starting upload...');
        }

        // Simulate progress updates (in a real implementation, this would be handled by the upload function)
        _simulateProgress(onProgress);

        // Perform the upload
        final result = await uploadFunction();
        
        // Upload successful
        onProgress?.call(1.0);
        onStatusUpdate?.call('Upload completed successfully!');
        return result;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attemptCount >= maxAttempts) {
          // Max attempts reached, throw the last exception
          onStatusUpdate?.call('Upload failed after $maxAttempts attempts');
          throw lastException;
        }
        
        // Wait before retrying
        onStatusUpdate?.call('Upload failed, retrying in $retryDelaySeconds seconds...');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
      }
    }

    // This should never be reached, but just in case
    throw lastException ?? Exception('Upload failed for unknown reason');
  }

  /// Validate file before upload
  static String? validateBeforeUpload(File file, String expectedType) {
    try {
      // Check if file still exists
      if (!file.existsSync()) {
        return 'File no longer exists. Please select the file again.';
      }

      // Validate file type and size
      return ValidationUtils.validateFileUpload(file, expectedType: expectedType);
    } catch (e) {
      return 'Error accessing file: ${ErrorHandler.getErrorMessage(e)}';
    }
  }

  /// Get upload size category for progress estimation
  static UploadSizeCategory getUploadSizeCategory(int fileSizeBytes) {
    const smallFileThreshold = 1024 * 1024; // 1MB
    const mediumFileThreshold = 10 * 1024 * 1024; // 10MB
    const largeFileThreshold = 50 * 1024 * 1024; // 50MB

    if (fileSizeBytes < smallFileThreshold) {
      return UploadSizeCategory.small;
    } else if (fileSizeBytes < mediumFileThreshold) {
      return UploadSizeCategory.medium;
    } else if (fileSizeBytes < largeFileThreshold) {
      return UploadSizeCategory.large;
    } else {
      return UploadSizeCategory.extraLarge;
    }
  }

  /// Get estimated upload time based on file size
  static Duration getEstimatedUploadTime(int fileSizeBytes) {
    final category = getUploadSizeCategory(fileSizeBytes);
    
    switch (category) {
      case UploadSizeCategory.small:
        return const Duration(seconds: 5);
      case UploadSizeCategory.medium:
        return const Duration(seconds: 30);
      case UploadSizeCategory.large:
        return const Duration(minutes: 2);
      case UploadSizeCategory.extraLarge:
        return const Duration(minutes: 5);
    }
  }

  /// Check if upload should be retried based on error type
  static bool shouldRetryUpload(Exception error) {
    final errorMessage = error.toString().toLowerCase();
    
    // Don't retry for these types of errors
    final nonRetryableErrors = [
      'permission denied',
      'file not found',
      'invalid file type',
      'file too large',
      'quota exceeded',
      'unauthorized',
    ];

    for (final nonRetryable in nonRetryableErrors) {
      if (errorMessage.contains(nonRetryable)) {
        return false;
      }
    }

    // Retry for network-related errors
    final retryableErrors = [
      'network',
      'timeout',
      'connection',
      'unavailable',
      'internal error',
    ];

    for (final retryable in retryableErrors) {
      if (errorMessage.contains(retryable)) {
        return true;
      }
    }

    // Default to retry for unknown errors
    return true;
  }

  /// Clean up temporary files after upload
  static Future<void> cleanupTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Cleaned up temporary file: $filePath');
      }
    } catch (e) {
      debugPrint('Failed to cleanup temporary file $filePath: $e');
      // Don't throw error for cleanup failures
    }
  }

  /// Batch upload multiple files with progress tracking
  static Future<List<String>> batchUploadWithProgress({
    required List<Future<String> Function()> uploadFunctions,
    required Function(int completed, int total, double overallProgress)? onProgress,
    required Function(String message)? onStatusUpdate,
  }) async {
    final results = <String>[];
    final total = uploadFunctions.length;
    
    for (int i = 0; i < uploadFunctions.length; i++) {
      try {
        onStatusUpdate?.call('Uploading file ${i + 1} of $total...');
        
        final result = await uploadWithRetry(
          uploadFunction: uploadFunctions[i],
          onProgress: (fileProgress) {
            final overallProgress = (i + fileProgress) / total;
            onProgress?.call(i, total, overallProgress);
          },
          onStatusUpdate: onStatusUpdate,
        );
        
        results.add(result);
        onProgress?.call(i + 1, total, (i + 1) / total);
        
      } catch (e) {
        onStatusUpdate?.call('Failed to upload file ${i + 1}: ${ErrorHandler.getErrorMessage(e)}');
        rethrow;
      }
    }
    
    onStatusUpdate?.call('All files uploaded successfully!');
    return results;
  }

  /// Simulate progress updates for upload operations
  static void _simulateProgress(Function(double progress)? onProgress) {
    if (onProgress == null) return;
    
    // Simulate gradual progress updates
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final progress = (timer.tick * 0.1).clamp(0.0, 0.9);
      onProgress(progress);
      
      if (progress >= 0.9) {
        timer.cancel();
      }
    });
  }
}

/// Enum for categorizing upload file sizes
enum UploadSizeCategory {
  small,
  medium,
  large,
  extraLarge,
}

/// Class for tracking upload progress and state
class UploadProgress {
  final double progress;
  final String message;
  final UploadState state;
  final Exception? error;

  const UploadProgress({
    required this.progress,
    required this.message,
    required this.state,
    this.error,
  });

  UploadProgress copyWith({
    double? progress,
    String? message,
    UploadState? state,
    Exception? error,
  }) {
    return UploadProgress(
      progress: progress ?? this.progress,
      message: message ?? this.message,
      state: state ?? this.state,
      error: error ?? this.error,
    );
  }
}

/// Enum for upload states
enum UploadState {
  idle,
  preparing,
  uploading,
  completed,
  failed,
  retrying,
}