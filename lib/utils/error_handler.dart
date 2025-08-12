import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized error handling utility for the Time Capsule app
class ErrorHandler {
  /// Converts various exception types to user-friendly error messages
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    } else if (error is Exception) {
      final message = error.toString();
      if (message.startsWith('Exception: ')) {
        return message.substring(11); // Remove 'Exception: ' prefix
      }
      return message;
    } else {
      return error.toString();
    }
  }

  /// Shows an error snackbar with consistent styling
  static void showErrorSnackBar(BuildContext context, String message) {
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
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a success snackbar with consistent styling
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
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
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Handles Firebase Auth specific errors
  static String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Current password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return 'Authentication error: ${error.message ?? 'Unknown error'}';
    }
  }

  /// Handles Firebase (Firestore/Storage) specific errors
  static String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'The requested item was not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'resource-exhausted':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed due to invalid conditions.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid input provided.';
      case 'unimplemented':
        return 'This feature is not yet available.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'data-loss':
        return 'Data corruption detected. Please contact support.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'deadline-exceeded':
        return 'Operation timed out. Please try again.';
      case 'cancelled':
        return 'Operation was cancelled.';
      case 'invalid-argument':
        return 'Invalid input provided.';
      case 'object-not-found':
        return 'File not found in storage.';
      case 'bucket-not-found':
        return 'Storage bucket not found.';
      case 'project-not-found':
        return 'Project configuration error.';
      case 'quota-exceeded':
        return 'Storage quota exceeded.';
      case 'unauthenticated':
        return 'Authentication required.';
      case 'unauthorized':
        return 'You are not authorized to perform this action.';
      case 'retry-limit-exceeded':
        return 'Too many attempts. Please try again later.';
      case 'invalid-checksum':
        return 'File upload failed due to corruption.';
      case 'canceled':
        return 'Upload was cancelled.';
      default:
        return 'Service error: ${error.message ?? 'Unknown error'}';
    }
  }
}