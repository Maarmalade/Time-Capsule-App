import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Comprehensive error handler for the Time Capsule application
/// 
/// This utility provides centralized error handling, user-friendly error messages,
/// and retry logic for various Firebase operations and app-specific errors.
class ErrorHandler {
  /// Show user-friendly error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar for less critical errors
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show success snackbar for positive feedback
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: duration,
      ),
    );
  }

  /// Get user-friendly error message for Firebase Auth exceptions
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password with at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment before trying again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'requires-recent-login':
        return 'This action requires recent authentication. Please sign in again.';
      case 'token-expired':
        return 'Your session has expired. Please sign in again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  /// Get user-friendly error message for Firestore exceptions
  static String getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this data. Please sign in and try again.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This data already exists.';
      case 'resource-exhausted':
        return 'Service is temporarily overloaded. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed due to invalid conditions. Please refresh and try again.';
      case 'aborted':
        return 'Operation was aborted due to a conflict. Please try again.';
      case 'out-of-range':
        return 'Invalid data range provided.';
      case 'unimplemented':
        return 'This feature is not yet available.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'data-loss':
        return 'Data corruption detected. Please contact support.';
      case 'unauthenticated':
        return 'Authentication required. Please sign in and try again.';
      default:
        return 'Database error: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  /// Get user-friendly error message for FCM/notification errors
  static String getNotificationErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'permission-denied':
        return 'Notification permissions are required to receive updates. Please enable notifications in your device settings by going to Settings > Apps > Time Capsule > Notifications.';
      case 'permission-blocked':
        return 'Notification permissions have been permanently denied. Please enable them manually in your device settings: Settings > Apps > Time Capsule > Notifications.';
      case 'permission-provisional':
        return 'Notifications are enabled but may be delivered quietly. You can change this in Settings > Notifications > Time Capsule.';
      case 'token-not-available':
        return 'Unable to register for notifications. This may be due to network issues or device restrictions. Please check your internet connection and try again.';
      case 'service-unavailable':
        return 'Notification service is temporarily unavailable. You may not receive push notifications until this is resolved. The app will retry automatically.';
      case 'invalid-token':
        return 'Notification registration has expired. The app will attempt to re-register automatically in the background.';
      case 'network-error':
        return 'Network error while setting up notifications. Please check your internet connection and try again.';
      case 'initialization-failed':
        return 'Failed to initialize notification system. Some features may not work properly. Please restart the app.';
      case 'show-failed':
        return 'Unable to display notification. This may be due to system restrictions or low memory.';
      case 'fcm-initialization-failed':
        return 'Push notification setup failed. You may not receive notifications for scheduled messages. The app will retry automatically.';
      case 'fcm-token-retrieval-failed':
        return 'Unable to set up push notifications. You may not receive notifications for new messages. Please check your internet connection.';
      default:
        return 'Notification setup encountered an issue: $errorCode. Some notification features may not work properly.';
    }
  }

  /// Handle notification permission errors with user guidance
  static Future<void> handleNotificationPermissionError(
    BuildContext context,
    String errorCode, {
    VoidCallback? onRetry,
    VoidCallback? onSkip,
  }) async {
    final message = getNotificationErrorMessage(errorCode);
    
    if (errorCode == 'permission-denied' || errorCode == 'permission-blocked') {
      showErrorDialog(
        context,
        title: 'Notification Permissions Required',
        message: '$message\n\nWithout notifications, you won\'t receive alerts for scheduled messages and other important updates.',
        onRetry: () async {
          // Guide user to settings
          await _showNotificationSettingsGuidance(context);
          onRetry?.call();
        },
        onDismiss: onSkip,
      );
    } else {
      showErrorDialog(
        context,
        title: 'Notification Setup Issue',
        message: message,
        onRetry: onRetry,
        onDismiss: onSkip,
      );
    }
  }

  /// Show guidance for enabling notifications in device settings
  static Future<void> _showNotificationSettingsGuidance(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To enable notifications for Time Capsule:'),
            SizedBox(height: 8),
            Text('1. Go to your device Settings'),
            Text('2. Find "Apps" or "Application Manager"'),
            Text('3. Select "Time Capsule"'),
            Text('4. Tap "Notifications"'),
            Text('5. Enable "Allow notifications"'),
            SizedBox(height: 16),
            Text(
              'This will allow you to receive alerts for scheduled messages and other important updates.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Handle authentication token expiration with comprehensive error handling
  static Future<bool> handleTokenExpiration(
    BuildContext context, {
    bool showDialog = true,
    VoidCallback? onTokenExpired,
  }) async {
    try {
      // Try to refresh the token with retry logic
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (showDialog) {
          _showTokenExpirationDialog(context, onTokenExpired);
        }
        return false;
      }

      // Attempt token refresh with retry logic
      await retryOperation(
        () => user.getIdToken(true),
        maxRetries: 2,
        initialDelay: const Duration(seconds: 1),
      );
      
      return true; // Token refreshed successfully
    } on FirebaseAuthException catch (e) {
      logError('ErrorHandler.handleTokenExpiration', e);
      
      // Handle specific auth errors
      if (_isTokenExpiredError(e)) {
        if (showDialog) {
          _showTokenExpirationDialog(context, onTokenExpired);
        }
        return false;
      }
      
      // Handle other auth errors
      if (showDialog) {
        showErrorDialog(
          context,
          title: 'Authentication Error',
          message: getAuthErrorMessage(e),
          onDismiss: () {
            onTokenExpired?.call();
            _navigateToLogin(context);
          },
        );
      }
      return false;
    } catch (e) {
      logError('ErrorHandler.handleTokenExpiration', e);
      
      if (isNetworkError(e)) {
        if (showDialog) {
          showErrorDialog(
            context,
            title: 'Network Error',
            message: 'Unable to verify your session due to network issues. Please check your connection and try again.',
            onRetry: () => handleTokenExpiration(context, showDialog: false),
            onDismiss: () {
              // Allow user to continue with potentially stale token
            },
          );
        }
        return false;
      }
      
      // Unknown error during token refresh
      if (showDialog) {
        _showTokenExpirationDialog(context, onTokenExpired);
      }
      return false;
    }
  }

  /// Show token expiration dialog with user-friendly messaging
  static void _showTokenExpirationDialog(
    BuildContext context,
    VoidCallback? onTokenExpired,
  ) {
    showErrorDialog(
      context,
      title: 'Session Expired',
      message: 'Your session has expired for security reasons. Please sign in again to continue using the app.',
      onDismiss: () {
        onTokenExpired?.call();
        _navigateToLogin(context);
      },
    );
  }

  /// Check if the error indicates token expiration
  static bool _isTokenExpiredError(FirebaseAuthException e) {
    return e.code == 'token-expired' ||
           e.code == 'user-token-expired' ||
           e.code == 'requires-recent-login' ||
           e.code == 'invalid-credential';
  }

  /// Navigate to login page safely
  static void _navigateToLogin(BuildContext context) {
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      logError('ErrorHandler._navigateToLogin', e);
      // If named route fails, try direct navigation
      try {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Scaffold(
            body: Center(
              child: Text('Please restart the app to continue.'),
            ),
          )),
          (route) => false,
        );
      } catch (fallbackError) {
        logError('ErrorHandler._navigateToLogin.fallback', fallbackError);
      }
    }
  }

  /// Enhanced retry logic with exponential backoff and error classification
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    dynamic lastError;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        attempts++;
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          logError('RetryOperation.nonRetryableError', e);
          rethrow; // Don't retry this type of error
        }
        
        if (attempts >= maxRetries) {
          logError('RetryOperation.maxRetriesExceeded', e);
          rethrow; // Re-throw the last exception
        }

        // Log retry attempt
        logError('RetryOperation.attempt$attempts', e);
        onRetry?.call(attempts, e);

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw Exception('Operation failed after $maxRetries attempts. Last error: $lastError');
  }

  /// Retry FCM token operations with specific error handling
  static Future<T> retryFCMOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    return retryOperation(
      operation,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      backoffMultiplier: 2.0,
      shouldRetry: (error) {
        // Don't retry permission errors or authentication errors
        if (error.toString().contains('permission')) return false;
        if (error.toString().contains('unauthenticated')) return false;
        if (error.toString().contains('invalid-credential')) return false;
        
        // Retry network errors and temporary failures
        return isNetworkError(error) || 
               error.toString().contains('unavailable') ||
               error.toString().contains('timeout') ||
               error.toString().contains('service-unavailable');
      },
      onRetry: (attempt, error) {
        debugPrint('FCM operation retry attempt $attempt: $error');
      },
    );
  }

  /// Retry authentication operations with specific error handling
  static Future<T> retryAuthOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 2,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    return retryOperation(
      operation,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      backoffMultiplier: 1.5,
      shouldRetry: (error) {
        // Don't retry user errors or permanent auth failures
        if (error is FirebaseAuthException) {
          switch (error.code) {
            case 'user-not-found':
            case 'wrong-password':
            case 'invalid-email':
            case 'user-disabled':
            case 'email-already-in-use':
            case 'weak-password':
              return false; // Don't retry user input errors
            case 'network-request-failed':
            case 'too-many-requests':
              return true; // Retry network and rate limit errors
            default:
              return false;
          }
        }
        
        // Retry network errors
        return isNetworkError(error);
      },
      onRetry: (attempt, error) {
        debugPrint('Auth operation retry attempt $attempt: $error');
      },
    );
  }

  /// Handle navigation errors with comprehensive fallback handling
  static Future<bool> handleNavigationError(
    BuildContext context,
    String targetRoute, {
    String fallbackRoute = '/home',
    Map<String, dynamic>? arguments,
    bool showErrorOnFailure = true,
  }) async {
    try {
      // Attempt primary navigation
      await Navigator.of(context).pushNamed(targetRoute, arguments: arguments);
      return true;
    } catch (e) {
      logError('ErrorHandler.handleNavigationError.primary', e);
      
      // Try fallback route
      try {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          fallbackRoute,
          (route) => false,
        );
        
        if (showErrorOnFailure) {
          showErrorSnackBar(
            context,
            message: 'Redirected to home due to navigation issue.',
          );
        }
        return false;
      } catch (fallbackError) {
        logError('ErrorHandler.handleNavigationError.fallback', fallbackError);
        
        // Try direct route navigation as last resort
        try {
          await _navigateToSafeRoute(context);
          
          if (showErrorOnFailure) {
            showErrorSnackBar(
              context,
              message: 'Navigation error occurred. Redirected to safe location.',
            );
          }
          return false;
        } catch (lastResortError) {
          logError('ErrorHandler.handleNavigationError.lastResort', lastResortError);
          
          // Complete navigation failure
          if (showErrorOnFailure) {
            showErrorDialog(
              context,
              title: 'Navigation Error',
              message: 'Unable to navigate properly. Please restart the app if this continues.',
              onDismiss: () {
                // Try to at least pop to a previous route
                try {
                  Navigator.of(context).pop();
                } catch (_) {
                  // Even pop failed - app is in bad state
                }
              },
            );
          }
          return false;
        }
      }
    }
  }

  /// Navigate to a safe route when all else fails
  static Future<void> _navigateToSafeRoute(BuildContext context) async {
    // Try to navigate to a basic scaffold as absolute fallback
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Time Capsule')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, size: 64),
                SizedBox(height: 16),
                Text(
                  'Welcome back to Time Capsule',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Please use the menu to navigate.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }

  /// Safe navigation wrapper that handles errors automatically
  static Future<bool> safeNavigate(
    BuildContext context,
    String routeName, {
    Map<String, dynamic>? arguments,
    bool replace = false,
    String fallbackRoute = '/home',
  }) async {
    try {
      if (replace) {
        await Navigator.of(context).pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
      } else {
        await Navigator.of(context).pushNamed(
          routeName,
          arguments: arguments,
        );
      }
      return true;
    } catch (e) {
      logError('ErrorHandler.safeNavigate', e);
      return await handleNavigationError(
        context,
        routeName,
        fallbackRoute: fallbackRoute,
        arguments: arguments,
      );
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'network-request-failed' ||
             error.code == 'unavailable' ||
             error.code == 'deadline-exceeded';
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable');
  }

  /// Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      return true;
    }
    
    if (error is FirebaseException) {
      return error.code == 'unauthenticated' ||
             error.code == 'permission-denied';
    }
    
    return false;
  }

  /// Get user-friendly error message for any error type (backward compatibility)
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  /// Log error for debugging (in development) or crash reporting (in production)
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
  }) {
    // In development, print to console
    debugPrint('ERROR [$context]: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
    
    // In production, this would send to crash reporting service
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Handle generic exceptions with comprehensive error analysis and user messaging
  static Future<void> handleGenericError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    String? contextInfo,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showDialog = false,
  }) async {
    final errorContext = _analyzeError(error);
    String message;
    
    if (customMessage != null) {
      message = customMessage;
    } else if (error is FirebaseAuthException) {
      message = getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      message = getFirestoreErrorMessage(error);
    } else {
      message = errorContext.userMessage;
    }

    // Add context information if provided
    if (contextInfo != null) {
      message = '$message\n\nContext: $contextInfo';
    }

    // Log the error with full context
    logError(
      'Generic Error Handler${contextInfo != null ? " ($contextInfo)" : ""}',
      error,
    );

    // Handle based on error type and severity
    if (errorContext.isAuthError) {
      await handleTokenExpiration(context, onTokenExpired: onDismiss);
    } else if (errorContext.isNetworkError) {
      if (showDialog) {
        showErrorDialog(
          context,
          title: 'Network Error',
          message: 'Please check your internet connection and try again.',
          onRetry: onRetry,
          onDismiss: onDismiss,
        );
      } else {
        showErrorSnackBar(
          context,
          message: 'Network error. Please check your connection and try again.',
          onRetry: onRetry,
        );
      }
    } else if (errorContext.isCritical) {
      showErrorDialog(
        context,
        title: 'Error',
        message: message,
        onRetry: onRetry,
        onDismiss: onDismiss,
      );
    } else {
      if (showDialog) {
        showErrorDialog(
          context,
          title: 'Error',
          message: message,
          onRetry: onRetry,
          onDismiss: onDismiss,
        );
      } else {
        showErrorSnackBar(
          context,
          message: message,
          onRetry: onRetry,
        );
      }
    }
  }

  /// Analyze error to determine appropriate handling strategy
  static ErrorContext _analyzeError(dynamic error) {
    if (error is FirebaseAuthException) {
      return ErrorContext(
        isAuthError: true,
        isNetworkError: isNetworkError(error),
        isCritical: _isTokenExpiredError(error),
        userMessage: getAuthErrorMessage(error),
        errorType: 'FirebaseAuth',
      );
    }
    
    if (error is FirebaseException) {
      final isPermissionError = error.code == 'permission-denied' || 
                               error.code == 'unauthenticated';
      return ErrorContext(
        isAuthError: isPermissionError,
        isNetworkError: isNetworkError(error),
        isCritical: false,
        userMessage: getFirestoreErrorMessage(error),
        errorType: 'Firebase',
      );
    }
    
    final errorString = error.toString().toLowerCase();
    final isNetwork = isNetworkError(error);
    
    return ErrorContext(
      isAuthError: false,
      isNetworkError: isNetwork,
      isCritical: false,
      userMessage: isNetwork 
          ? 'Network connection issue. Please check your internet and try again.'
          : 'An unexpected error occurred. Please try again.',
      errorType: 'Generic',
    );
  }

  /// Comprehensive error recovery with multiple strategies
  static Future<T?> recoverFromError<T>(
    Future<T> Function() operation,
    BuildContext context, {
    String? operationName,
    int maxRetries = 2,
    T? fallbackValue,
    bool showUserError = true,
  }) async {
    try {
      return await retryOperation(
        operation,
        maxRetries: maxRetries,
        shouldRetry: (error) {
          // Only retry recoverable errors
          return isNetworkError(error) && !isAuthError(error);
        },
      );
    } catch (e) {
      logError('ErrorRecovery${operationName != null ? ".$operationName" : ""}', e);
      
      if (showUserError) {
        await handleGenericError(
          context,
          e,
          contextInfo: operationName,
        );
      }
      
      return fallbackValue;
    }
  }
}

/// Error context information for comprehensive error handling
class ErrorContext {
  final bool isAuthError;
  final bool isNetworkError;
  final bool isCritical;
  final String userMessage;
  final String errorType;
  
  const ErrorContext({
    required this.isAuthError,
    required this.isNetworkError,
    required this.isCritical,
    required this.userMessage,
    required this.errorType,
  });
}