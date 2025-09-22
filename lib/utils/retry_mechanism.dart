import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

/// Retry mechanism for handling transient failures in social operations
class RetryMechanism {
  static const int defaultMaxRetries = 3;
  static const Duration defaultBaseDelay = Duration(seconds: 1);
  static const double defaultBackoffMultiplier = 2.0;
  static const Duration defaultMaxDelay = Duration(seconds: 30);

  /// Executes a function with exponential backoff retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = baseDelay;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // Check if we should retry this error
        if (!_shouldRetryError(error, shouldRetry)) {
          rethrow;
        }

        // If this was the last attempt, rethrow the error
        if (attempt > maxRetries) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(currentDelay);

        // Calculate next delay with jitter to avoid thundering herd
        final jitter = Random().nextDouble() * 0.1; // 10% jitter
        currentDelay = Duration(
          milliseconds: min(
            (currentDelay.inMilliseconds * backoffMultiplier * (1 + jitter))
                .round(),
            maxDelay.inMilliseconds,
          ),
        );
      }
    }

    // This should never be reached, but just in case
    throw Exception('Retry mechanism failed unexpectedly');
  }

  /// Executes a function with simple retry logic (no backoff)
  static Future<T> executeWithSimpleRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 2,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        if (!_shouldRetryError(error, shouldRetry) || attempt > maxRetries) {
          rethrow;
        }

        await Future.delayed(delay);
      }
    }

    throw Exception('Simple retry mechanism failed unexpectedly');
  }

  /// Determines if an error should be retried
  static bool _shouldRetryError(
    dynamic error,
    bool Function(dynamic error)? customShouldRetry,
  ) {
    // Use custom retry logic if provided
    if (customShouldRetry != null) {
      return customShouldRetry(error);
    }

    // Default retry logic for common transient errors
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'internal':
        case 'aborted':
        case 'resource-exhausted':
          return true;
        case 'permission-denied':
        case 'not-found':
        case 'already-exists':
        case 'invalid-argument':
        case 'unauthenticated':
          return false;
        default:
          return false;
      }
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
        case 'too-many-requests':
          return true;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-email':
        case 'user-disabled':
          return false;
        default:
          return false;
      }
    }

    // Check for network-related errors in the error message
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('unreachable')) {
      return true;
    }

    return false;
  }

  /// Creates a retry wrapper for social operations
  static Future<T> retrySocialOperation<T>(
    Future<T> Function() operation,
    String operationType,
  ) async {
    return executeWithRetry(
      operation,
      maxRetries: _getMaxRetriesForOperation(operationType),
      baseDelay: _getBaseDelayForOperation(operationType),
      shouldRetry: (error) => _shouldRetrySocialOperation(error, operationType),
    );
  }

  /// Gets max retries based on operation type
  static int _getMaxRetriesForOperation(String operationType) {
    switch (operationType) {
      case 'friend_request':
      case 'friend_search':
        return 2; // Quick operations, fewer retries
      case 'scheduled_message':
      case 'shared_folder':
        return 3; // Important operations, more retries
      case 'public_folder':
        return 2; // Medium priority
      default:
        return defaultMaxRetries;
    }
  }

  /// Gets base delay based on operation type
  static Duration _getBaseDelayForOperation(String operationType) {
    switch (operationType) {
      case 'friend_search':
        return const Duration(milliseconds: 500); // Fast retry for searches
      case 'friend_request':
      case 'scheduled_message':
        return const Duration(seconds: 1); // Standard delay
      case 'shared_folder':
      case 'public_folder':
        return const Duration(
          seconds: 2,
        ); // Longer delay for complex operations
      default:
        return defaultBaseDelay;
    }
  }

  /// Determines if a social operation error should be retried
  static bool _shouldRetrySocialOperation(dynamic error, String operationType) {
    // Use default retry logic first
    if (!_shouldRetryError(error, null)) {
      return false;
    }

    // Additional logic for specific social operations
    final errorMessage = error.toString().toLowerCase();

    switch (operationType) {
      case 'friend_request':
        // Don't retry validation errors or duplicate requests
        if (errorMessage.contains('already sent') ||
            errorMessage.contains('already friends') ||
            errorMessage.contains('limit reached')) {
          return false;
        }
        break;

      case 'scheduled_message':
        // Don't retry validation errors
        if (errorMessage.contains('must be in the future') ||
            errorMessage.contains('cannot exceed') ||
            errorMessage.contains('limit reached')) {
          return false;
        }
        break;

      case 'shared_folder':
      case 'public_folder':
        // Don't retry permission or validation errors
        if (errorMessage.contains('permission') ||
            errorMessage.contains('not a contributor') ||
            errorMessage.contains('limit reached')) {
          return false;
        }
        break;
    }

    return true;
  }
}

/// Specific retry configurations for different social features
class SocialRetryConfigs {
  /// Friend request retry configuration
  static Future<T> retryFriendRequest<T>(Future<T> Function() operation) {
    return RetryMechanism.retrySocialOperation(operation, 'friend_request');
  }

  /// Friend search retry configuration
  static Future<T> retryFriendSearch<T>(Future<T> Function() operation) {
    return RetryMechanism.retrySocialOperation(operation, 'friend_search');
  }

  /// Scheduled message retry configuration
  static Future<T> retryScheduledMessage<T>(Future<T> Function() operation) {
    return RetryMechanism.retrySocialOperation(operation, 'scheduled_message');
  }

  /// Shared folder retry configuration
  static Future<T> retrySharedFolder<T>(Future<T> Function() operation) {
    return RetryMechanism.retrySocialOperation(operation, 'shared_folder');
  }

  /// Public folder retry configuration
  static Future<T> retryPublicFolder<T>(Future<T> Function() operation) {
    return RetryMechanism.retrySocialOperation(operation, 'public_folder');
  }

  /// Network operation retry (for general network calls)
  static Future<T> retryNetworkOperation<T>(Future<T> Function() operation) {
    return RetryMechanism.executeWithRetry(
      operation,
      maxRetries: 3,
      baseDelay: const Duration(seconds: 1),
      shouldRetry: (error) {
        final errorMessage = error.toString().toLowerCase();
        return errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('timeout') ||
            errorMessage.contains('unavailable');
      },
    );
  }
}

/// Retry state management for UI components
class RetryState {
  final bool isRetrying;
  final int attemptCount;
  final Duration? nextRetryIn;
  final String? lastError;

  const RetryState({
    this.isRetrying = false,
    this.attemptCount = 0,
    this.nextRetryIn,
    this.lastError,
  });

  RetryState copyWith({
    bool? isRetrying,
    int? attemptCount,
    Duration? nextRetryIn,
    String? lastError,
  }) {
    return RetryState(
      isRetrying: isRetrying ?? this.isRetrying,
      attemptCount: attemptCount ?? this.attemptCount,
      nextRetryIn: nextRetryIn ?? this.nextRetryIn,
      lastError: lastError ?? this.lastError,
    );
  }

  bool get canRetry => !isRetrying && attemptCount < 3;
  bool get hasError => lastError != null;
}
