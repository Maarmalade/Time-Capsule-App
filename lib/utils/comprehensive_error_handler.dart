import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'error_handler.dart';

/// Comprehensive error handling utility for media uploads, scheduled messages,
/// shared folders, and profile pictures with enhanced validation and fallback mechanisms
class ComprehensiveErrorHandler {
  
  /// Enhanced media upload error handling with specific validation feedback
  static String getMediaUploadErrorMessage(dynamic error, {String? mediaType}) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    // File validation errors
    if (baseMessage.contains('does not exist')) {
      return 'Selected file no longer exists. Please select a different file.';
    }
    
    if (baseMessage.contains('too large') || baseMessage.contains('size must be less than')) {
      final type = mediaType ?? 'file';
      return 'The selected $type is too large. Please choose a smaller file or compress it before uploading.';
    }
    
    if (baseMessage.contains('invalid characters') || baseMessage.contains('Unsupported file type')) {
      return 'This file type is not supported. Please select a valid image (JPG, PNG, GIF, WebP) or video (MP4, MOV, AVI, MKV, WebM) file.';
    }
    
    // Network and upload errors
    if (baseMessage.contains('network') || baseMessage.contains('connection')) {
      return 'Upload failed due to network issues. Please check your internet connection and try again.';
    }
    
    if (baseMessage.contains('timeout') || baseMessage.contains('deadline-exceeded')) {
      return 'Upload timed out. The file may be too large or your connection is slow. Please try again with a smaller file.';
    }
    
    if (baseMessage.contains('storage') || baseMessage.contains('bucket')) {
      return 'Storage service is temporarily unavailable. Please try again in a few minutes.';
    }
    
    if (baseMessage.contains('quota') || baseMessage.contains('limit')) {
      return 'Storage quota exceeded. Please delete some old files or contact support.';
    }
    
    // Permission errors
    if (baseMessage.contains('permission') || baseMessage.contains('unauthorized')) {
      return 'You do not have permission to upload files. Please log in again and try.';
    }
    
    // Retry-specific errors
    if (baseMessage.contains('after') && baseMessage.contains('attempts')) {
      return 'Upload failed after multiple attempts. Please check your file and internet connection, then try again.';
    }
    
    return 'Upload failed: $baseMessage';
  }

  /// Enhanced scheduled message time validation with detailed feedback
  static String getScheduledTimeValidationErrorMessage(dynamic error) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    if (baseMessage.contains('in the past')) {
      return 'Cannot schedule messages for past dates. Please select a future date and time.';
    }
    
    if (baseMessage.contains('at least') && baseMessage.contains('minute')) {
      return 'Messages must be scheduled at least 1 minute in the future to allow for processing time.';
    }
    
    if (baseMessage.contains('more than') && baseMessage.contains('years')) {
      return 'Messages cannot be scheduled more than 10 years in the future. Please select an earlier date.';
    }
    
    if (baseMessage.contains('invalid') && baseMessage.contains('time')) {
      return 'The selected date and time is invalid. Please choose a valid future date and time.';
    }
    
    if (baseMessage.contains('timezone')) {
      return 'There was an issue with timezone handling. Please try selecting the time again.';
    }
    
    return 'Invalid scheduled time: $baseMessage';
  }

  /// Enhanced shared folder access error handling with fallback suggestions
  static String getSharedFolderAccessErrorMessage(dynamic error) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    if (baseMessage.contains('not found')) {
      return 'This shared folder no longer exists or has been deleted by the owner.';
    }
    
    if (baseMessage.contains('permission denied') || baseMessage.contains('not a contributor')) {
      return 'You no longer have access to this folder. The owner may have removed your access.';
    }
    
    if (baseMessage.contains('locked')) {
      return 'This folder has been locked by the owner and no longer accepts new content.';
    }
    
    if (baseMessage.contains('network') || baseMessage.contains('unavailable')) {
      return 'Cannot access shared folder due to network issues. Please check your connection and try again.';
    }
    
    if (baseMessage.contains('sync') || baseMessage.contains('update')) {
      return 'Folder access information is being updated. Please wait a moment and try again.';
    }
    
    return 'Shared folder access error: $baseMessage';
  }

  /// Enhanced profile picture error handling with caching fallbacks
  static String getProfilePictureErrorMessage(dynamic error, {bool isCacheError = false}) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    if (isCacheError) {
      if (baseMessage.contains('expired') || baseMessage.contains('stale')) {
        return 'Profile picture cache is outdated. Refreshing...';
      }
      
      if (baseMessage.contains('memory') || baseMessage.contains('cache full')) {
        return 'Profile picture cache is full. Clearing old entries...';
      }
      
      return 'Profile picture cache error. Using default avatar.';
    }
    
    // Loading errors
    if (baseMessage.contains('network') || baseMessage.contains('connection')) {
      return 'Cannot load profile picture due to network issues. Using cached version if available.';
    }
    
    if (baseMessage.contains('not found') || baseMessage.contains('404')) {
      return 'Profile picture not found. It may have been deleted or moved.';
    }
    
    if (baseMessage.contains('timeout')) {
      return 'Profile picture loading timed out. Using cached version if available.';
    }
    
    // Upload errors
    if (baseMessage.contains('too large')) {
      return 'Profile picture is too large. Please select an image smaller than 5MB.';
    }
    
    if (baseMessage.contains('invalid format') || baseMessage.contains('unsupported')) {
      return 'Invalid image format. Please select a JPG, PNG, GIF, or WebP image.';
    }
    
    return 'Profile picture error: $baseMessage';
  }

  /// Shows enhanced error dialog with retry and fallback options
  static Future<void> showEnhancedErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String operation,
    VoidCallback? onRetry,
    VoidCallback? onFallback,
    String? fallbackText,
    bool showTechnicalDetails = false,
    dynamic originalError,
  }) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (showTechnicalDetails && originalError != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      originalError.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (onFallback != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onFallback();
              },
              child: Text(fallbackText ?? 'Use Fallback'),
            ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows progressive error feedback with escalating severity
  static void showProgressiveError(
    BuildContext context, {
    required String operation,
    required dynamic error,
    required int attemptCount,
    int maxAttempts = 3,
    VoidCallback? onRetry,
    VoidCallback? onGiveUp,
  }) {
    if (!context.mounted) return;
    
    String message;
    Color backgroundColor;
    IconData icon;
    
    if (attemptCount == 1) {
      message = 'First attempt failed. Retrying...';
      backgroundColor = Colors.orange.shade600;
      icon = Icons.warning_outlined;
    } else if (attemptCount < maxAttempts) {
      message = 'Attempt $attemptCount failed. Trying again...';
      backgroundColor = Colors.orange.shade700;
      icon = Icons.error_outline;
    } else {
      message = 'All attempts failed. Please try again later.';
      backgroundColor = Colors.red.shade600;
      icon = Icons.error;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: attemptCount < maxAttempts ? 2 : 4),
        action: attemptCount >= maxAttempts && onGiveUp != null
            ? SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: onGiveUp,
              )
            : null,
      ),
    );
  }

  /// Validates file before upload with comprehensive checks
  static Future<String?> validateFileForUpload(
    File file, {
    required String expectedType,
    int? maxSizeBytes,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return 'Selected file no longer exists. Please select a different file.';
      }

      // Check file size
      final fileSize = await file.length();
      if (maxSizeBytes != null && fileSize > maxSizeBytes) {
        final maxSizeMB = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
        final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        return 'File is too large (${fileSizeMB}MB). Maximum size is ${maxSizeMB}MB.';
      }

      // Check file extension
      final fileName = file.path.toLowerCase();
      final extension = fileName.substring(fileName.lastIndexOf('.'));
      
      if (allowedExtensions != null && !allowedExtensions.contains(extension)) {
        return 'Unsupported file type ($extension). Allowed types: ${allowedExtensions.join(', ')}.';
      }

      // Check if file is readable
      try {
        await file.readAsBytes();
      } catch (e) {
        return 'Cannot read the selected file. It may be corrupted or in use by another application.';
      }

      return null; // File is valid
    } catch (e) {
      return 'Error validating file: ${e.toString()}';
    }
  }

  /// Creates fallback mechanism for failed operations
  static Future<T?> withFallback<T>(
    Future<T> Function() primaryOperation,
    Future<T> Function()? fallbackOperation, {
    required String operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    Exception? lastError;
    
    // Try primary operation with retries
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await primaryOperation();
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt); // Exponential backoff
        }
      }
    }
    
    // Try fallback operation if available
    if (fallbackOperation != null) {
      try {
        return await fallbackOperation();
      } catch (e) {
        // If fallback also fails, throw the original error
        throw lastError ?? Exception('$operationName failed');
      }
    }
    
    throw lastError ?? Exception('$operationName failed after $maxRetries attempts');
  }

  /// Creates error boundary widget for handling widget-level errors
  static Widget buildErrorBoundary({
    required Widget child,
    required String context,
    Widget Function(String error)? errorBuilder,
  }) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          final errorMessage = ErrorHandler.getErrorMessage(e);
          
          if (errorBuilder != null) {
            return errorBuilder(errorMessage);
          }
          
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error in $context',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// Handles async operations with loading states and error handling
  static Future<T?> handleAsyncOperation<T>(
    BuildContext context, {
    required Future<T> Function() operation,
    required String operationName,
    String? loadingMessage,
    String? successMessage,
    bool showLoadingDialog = false,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    if (!context.mounted) return null;
    
    // Show loading dialog if requested
    if (showLoadingDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(loadingMessage ?? 'Processing...'),
              ),
            ],
          ),
        ),
      );
    }
    
    try {
      final result = await operation();
      
      if (showLoadingDialog && context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      
      if (successMessage != null && context.mounted) {
        ErrorHandler.showSuccessSnackBar(context, successMessage);
      }
      
      onSuccess?.call();
      return result;
    } catch (e) {
      if (showLoadingDialog && context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      
      final errorMessage = ErrorHandler.getErrorMessage(e);
      
      if (onError != null) {
        onError(errorMessage);
      } else if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, errorMessage);
      }
      
      return null;
    }
  }

  /// Validates network connectivity before operations
  static Future<bool> validateNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Shows network connectivity error with retry option
  static void showNetworkConnectivityError(
    BuildContext context, {
    required VoidCallback onRetry,
    String? customMessage,
  }) {
    if (!context.mounted) return;
    
    final message = customMessage ?? 
        'No internet connection detected. Please check your network settings and try again.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Check Again',
          onPressed: onRetry,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
      ),
    );
  }
}