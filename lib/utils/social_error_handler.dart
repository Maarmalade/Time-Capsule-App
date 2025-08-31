import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'error_handler.dart';
import '../design_system/app_colors.dart';

/// Enhanced error handling specifically for social features
class SocialErrorHandler extends ErrorHandler {
  /// Handles friend-related errors with specific messaging
  static String getFriendErrorMessage(dynamic error) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    // Check for specific friend-related error patterns
    if (baseMessage.contains('already sent you a friend request')) {
      return 'This user has already sent you a friend request. Check your pending requests.';
    }
    
    if (baseMessage.contains('Friend request already sent')) {
      return 'You have already sent a friend request to this user.';
    }
    
    if (baseMessage.contains('already friends')) {
      return 'You are already friends with this user.';
    }
    
    if (baseMessage.contains('User not found')) {
      return 'This user could not be found. They may have deleted their account.';
    }
    
    if (baseMessage.contains('Daily friend request limit')) {
      return 'You have reached the daily limit for friend requests. Try again tomorrow.';
    }
    
    return baseMessage;
  }

  /// Handles scheduled message errors with specific messaging
  static String getScheduledMessageErrorMessage(dynamic error) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    // Check for specific scheduled message error patterns
    if (baseMessage.contains('must be in the future')) {
      return 'Please select a future date and time for message delivery.';
    }
    
    if (baseMessage.contains('more than') && baseMessage.contains('years in the future')) {
      return 'Messages cannot be scheduled more than 10 years in the future.';
    }
    
    if (baseMessage.contains('at least') && baseMessage.contains('minutes in the future')) {
      return 'Messages must be scheduled at least 5 minutes in the future.';
    }
    
    if (baseMessage.contains('Maximum scheduled messages limit')) {
      return 'You have reached the maximum number of scheduled messages. Cancel some existing messages to create new ones.';
    }
    
    if (baseMessage.contains('cannot exceed') && baseMessage.contains('characters')) {
      return 'Message content is too long. Please shorten your message.';
    }
    
    return baseMessage;
  }

  /// Handles shared folder errors with specific messaging
  static String getSharedFolderErrorMessage(dynamic error) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    // Check for specific shared folder error patterns
    if (baseMessage.contains('more than') && baseMessage.contains('contributors')) {
      return 'A folder cannot have more than 20 contributors.';
    }
    
    if (baseMessage.contains('Owner cannot be added as a contributor')) {
      return 'The folder owner is automatically a contributor and cannot be added separately.';
    }
    
    if (baseMessage.contains('Duplicate contributors')) {
      return 'Each user can only be added as a contributor once.';
    }
    
    if (baseMessage.contains('folder is locked')) {
      return 'This folder has been locked and no longer accepts new contributions.';
    }
    
    if (baseMessage.contains('not a contributor')) {
      return 'You do not have permission to contribute to this folder.';
    }
    
    return baseMessage;
  }

  /// Handles public folder errors with specific messaging
  static String getPublicFolderErrorMessage(dynamic error) {
    final baseMessage = ErrorHandler.getErrorMessage(error);
    
    // Check for specific public folder error patterns
    if (baseMessage.contains('Maximum public folders limit')) {
      return 'You have reached the maximum number of public folders. Make some folders private to create new public ones.';
    }
    
    if (baseMessage.contains('cannot make folder public')) {
      return 'This folder cannot be made public. It may contain private content.';
    }
    
    return baseMessage;
  }

  /// Shows error with retry functionality
  static void showErrorWithRetry(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
    String retryText = 'Retry',
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: retryText,
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  /// Shows network error with specific retry options
  static void showNetworkError(
    BuildContext context, {
    required VoidCallback onRetry,
    String? customMessage,
  }) {
    final message = customMessage ?? 
        'Network connection failed. Please check your internet connection and try again.';
    
    showErrorWithRetry(
      context,
      message: message,
      onRetry: onRetry,
      retryText: 'Retry',
    );
  }

  /// Shows rate limit error with wait time
  static void showRateLimitError(
    BuildContext context, {
    required Duration waitTime,
    String? customMessage,
  }) {
    final minutes = waitTime.inMinutes;
    final seconds = waitTime.inSeconds % 60;
    
    String timeText;
    if (minutes > 0) {
      timeText = '${minutes}m ${seconds}s';
    } else {
      timeText = '${seconds}s';
    }
    
    final message = customMessage ?? 
        'Too many requests. Please wait $timeText before trying again.';
    
    ErrorHandler.showErrorSnackBar(context, message: message);
  }

  /// Shows permission error with helpful guidance
  static void showPermissionError(
    BuildContext context, {
    required String action,
    String? suggestion,
  }) {
    final message = 'You do not have permission to $action.';
    final fullMessage = suggestion != null ? '$message $suggestion' : message;
    
    ErrorHandler.showErrorSnackBar(context, message: fullMessage);
  }

  /// Shows validation error with field-specific messaging
  static void showValidationError(
    BuildContext context, {
    required String field,
    required String error,
  }) {
    final message = '$field: $error';
    ErrorHandler.showErrorSnackBar(context, message: message);
  }

  /// Handles and displays social operation errors
  static void handleSocialOperationError(
    BuildContext context, {
    required dynamic error,
    required String operation,
    VoidCallback? onRetry,
  }) {
    String message;
    
    switch (operation) {
      case 'friend_request':
        message = getFriendErrorMessage(error);
        break;
      case 'scheduled_message':
        message = getScheduledMessageErrorMessage(error);
        break;
      case 'shared_folder':
        message = getSharedFolderErrorMessage(error);
        break;
      case 'public_folder':
        message = getPublicFolderErrorMessage(error);
        break;
      default:
        message = ErrorHandler.getErrorMessage(error);
    }

    // Check if this is a network-related error
    if (_isNetworkError(error) && onRetry != null) {
      showNetworkError(context, onRetry: onRetry, customMessage: message);
    } else if (_isRateLimitError(error)) {
      showRateLimitError(context, waitTime: _extractWaitTime(error), customMessage: message);
    } else if (_isPermissionError(error)) {
      showPermissionError(context, action: operation, suggestion: _getPermissionSuggestion(operation));
    } else if (onRetry != null && _isRetryableError(error)) {
      showErrorWithRetry(context, message: message, onRetry: onRetry);
    } else {
      ErrorHandler.showErrorSnackBar(context, message: message);
    }
  }

  /// Checks if error is network-related
  static bool _isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' || 
             error.code == 'deadline-exceeded' ||
             error.code == 'network-request-failed';
    }
    
    final message = error.toString().toLowerCase();
    return message.contains('network') || 
           message.contains('connection') ||
           message.contains('timeout') ||
           message.contains('unreachable');
  }

  /// Checks if error is rate limit related
  static bool _isRateLimitError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'resource-exhausted' || error.code == 'too-many-requests';
    }
    
    final message = error.toString().toLowerCase();
    return message.contains('rate limit') || 
           message.contains('too many') ||
           message.contains('limit reached') ||
           message.contains('try again later');
  }

  /// Checks if error is permission-related
  static bool _isPermissionError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' || 
             error.code == 'unauthenticated' ||
             error.code == 'unauthorized';
    }
    
    final message = error.toString().toLowerCase();
    return message.contains('permission') || 
           message.contains('unauthorized') ||
           message.contains('not allowed');
  }

  /// Checks if error is retryable
  static bool _isRetryableError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'aborted' || 
             error.code == 'internal' ||
             error.code == 'unavailable' ||
             error.code == 'deadline-exceeded';
    }
    
    return _isNetworkError(error);
  }

  /// Extracts wait time from rate limit error
  static Duration _extractWaitTime(dynamic error) {
    final message = error.toString().toLowerCase();
    
    // Try to extract time from error message
    final minuteMatch = RegExp(r'(\d+)\s*minute').firstMatch(message);
    if (minuteMatch != null) {
      final minutes = int.tryParse(minuteMatch.group(1) ?? '0') ?? 0;
      return Duration(minutes: minutes);
    }
    
    final secondMatch = RegExp(r'(\d+)\s*second').firstMatch(message);
    if (secondMatch != null) {
      final seconds = int.tryParse(secondMatch.group(1) ?? '0') ?? 0;
      return Duration(seconds: seconds);
    }
    
    // Default wait time
    return const Duration(minutes: 1);
  }

  /// Gets permission suggestion based on operation
  static String? _getPermissionSuggestion(String operation) {
    switch (operation) {
      case 'friend_request':
        return 'Make sure you are logged in and the user exists.';
      case 'shared_folder':
        return 'Only folder contributors can upload content.';
      case 'public_folder':
        return 'Only the folder owner can change visibility settings.';
      case 'scheduled_message':
        return 'You can only create messages for yourself or your friends.';
      default:
        return null;
    }
  }

  /// Creates error state widget for social features
  static Widget buildErrorState({
    required String message,
    required VoidCallback onRetry,
    IconData icon = Icons.error_outline,
    String retryText = 'Try Again',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryText),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates network error state widget
  static Widget buildNetworkErrorState({
    required VoidCallback onRetry,
    String? customMessage,
  }) {
    return buildErrorState(
      message: customMessage ?? 
          'No internet connection.\nPlease check your network and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      retryText: 'Retry',
    );
  }

  /// Creates empty state widget for social features
  static Widget buildEmptyState({
    required String message,
    required String actionText,
    required VoidCallback onAction,
    IconData icon = Icons.inbox_outlined,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}