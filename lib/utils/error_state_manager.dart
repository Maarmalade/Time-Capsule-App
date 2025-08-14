import 'package:flutter/material.dart';
import 'social_error_handler.dart';
import 'retry_mechanism.dart';

/// Manages error states for social features with user feedback
class ErrorStateManager extends ChangeNotifier {
  final Map<String, ErrorState> _errorStates = {};
  final Map<String, RetryState> _retryStates = {};

  /// Gets the current error state for an operation
  ErrorState? getErrorState(String operationKey) {
    return _errorStates[operationKey];
  }

  /// Gets the current retry state for an operation
  RetryState? getRetryState(String operationKey) {
    return _retryStates[operationKey];
  }

  /// Sets an error state for an operation
  void setError(String operationKey, dynamic error, {String? context}) {
    _errorStates[operationKey] = ErrorState(
      error: error,
      context: context,
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }

  /// Clears an error state for an operation
  void clearError(String operationKey) {
    _errorStates.remove(operationKey);
    _retryStates.remove(operationKey);
    notifyListeners();
  }

  /// Sets a retry state for an operation
  void setRetryState(String operationKey, RetryState state) {
    _retryStates[operationKey] = state;
    notifyListeners();
  }

  /// Executes an operation with error handling and retry logic
  Future<T> executeWithErrorHandling<T>(
    String operationKey,
    Future<T> Function() operation, {
    String? operationType,
    int maxRetries = 3,
    bool showUserFeedback = true,
    BuildContext? context,
  }) async {
    // Clear previous error state
    clearError(operationKey);

    // Set initial retry state
    setRetryState(operationKey, const RetryState(isRetrying: true));

    try {
      T result;
      
      if (operationType != null) {
        result = await RetryMechanism.retrySocialOperation(operation, operationType);
      } else {
        result = await RetryMechanism.executeWithRetry(operation, maxRetries: maxRetries);
      }

      // Clear retry state on success
      setRetryState(operationKey, const RetryState());
      
      return result;
    } catch (error) {
      // Set error state
      setError(operationKey, error, context: operationType);
      
      // Set final retry state
      setRetryState(operationKey, RetryState(
        isRetrying: false,
        attemptCount: maxRetries + 1,
        lastError: error.toString(),
      ));

      // Show user feedback if context is provided
      if (showUserFeedback && context != null && context.mounted) {
        _showErrorFeedback(context, error, operationType ?? operationKey);
      }

      rethrow;
    }
  }

  /// Retries a failed operation
  Future<T> retryOperation<T>(
    String operationKey,
    Future<T> Function() operation, {
    String? operationType,
    BuildContext? context,
  }) async {
    final currentRetryState = _retryStates[operationKey];
    if (currentRetryState == null || !currentRetryState.canRetry) {
      throw Exception('Cannot retry operation');
    }

    return executeWithErrorHandling(
      operationKey,
      operation,
      operationType: operationType,
      context: context,
    );
  }

  /// Shows appropriate error feedback to the user
  void _showErrorFeedback(BuildContext context, dynamic error, String operationType) {
    if (!context.mounted) return;

    final canRetry = _canRetryError(error);
    
    if (canRetry) {
      SocialErrorHandler.showErrorWithRetry(
        context,
        message: _getErrorMessage(error, operationType),
        onRetry: () => _handleRetryFromUI(context, operationType),
      );
    } else {
      SocialErrorHandler.handleSocialOperationError(
        context,
        error: error,
        operation: operationType,
      );
    }
  }

  /// Handles retry action from UI
  void _handleRetryFromUI(BuildContext context, String operationType) {
    // This would typically trigger a retry in the calling widget
    // The widget should listen to this manager and retry the operation
    notifyListeners();
  }

  /// Gets appropriate error message for the error and operation type
  String _getErrorMessage(dynamic error, String operationType) {
    switch (operationType) {
      case 'friend_request':
        return SocialErrorHandler.getFriendErrorMessage(error);
      case 'scheduled_message':
        return SocialErrorHandler.getScheduledMessageErrorMessage(error);
      case 'shared_folder':
        return SocialErrorHandler.getSharedFolderErrorMessage(error);
      case 'public_folder':
        return SocialErrorHandler.getPublicFolderErrorMessage(error);
      default:
        return error.toString();
    }
  }

  /// Determines if an error can be retried
  bool _canRetryError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    // Don't retry validation errors
    if (errorMessage.contains('validation') ||
        errorMessage.contains('invalid') ||
        errorMessage.contains('required') ||
        errorMessage.contains('limit reached') ||
        errorMessage.contains('already exists') ||
        errorMessage.contains('already sent') ||
        errorMessage.contains('already friends')) {
      return false;
    }

    // Retry network and transient errors
    return errorMessage.contains('network') ||
           errorMessage.contains('connection') ||
           errorMessage.contains('timeout') ||
           errorMessage.contains('unavailable') ||
           errorMessage.contains('internal') ||
           errorMessage.contains('aborted');
  }

  /// Clears all error states
  void clearAllErrors() {
    _errorStates.clear();
    _retryStates.clear();
    notifyListeners();
  }

  /// Gets all current errors
  Map<String, ErrorState> get allErrors => Map.unmodifiable(_errorStates);

  /// Gets all current retry states
  Map<String, RetryState> get allRetryStates => Map.unmodifiable(_retryStates);

  /// Checks if there are any active errors
  bool get hasErrors => _errorStates.isNotEmpty;

  /// Checks if any operations are currently retrying
  bool get isRetrying => _retryStates.values.any((state) => state.isRetrying);
}

/// Represents an error state for an operation
class ErrorState {
  final dynamic error;
  final String? context;
  final DateTime timestamp;

  const ErrorState({
    required this.error,
    this.context,
    required this.timestamp,
  });

  String get message => error.toString();
  
  bool get isNetworkError {
    final errorMessage = message.toLowerCase();
    return errorMessage.contains('network') ||
           errorMessage.contains('connection') ||
           errorMessage.contains('timeout');
  }

  bool get isValidationError {
    final errorMessage = message.toLowerCase();
    return errorMessage.contains('validation') ||
           errorMessage.contains('invalid') ||
           errorMessage.contains('required');
  }

  bool get isPermissionError {
    final errorMessage = message.toLowerCase();
    return errorMessage.contains('permission') ||
           errorMessage.contains('unauthorized') ||
           errorMessage.contains('not allowed');
  }

  bool get isRateLimitError {
    final errorMessage = message.toLowerCase();
    return errorMessage.contains('rate limit') ||
           errorMessage.contains('too many') ||
           errorMessage.contains('limit reached');
  }
}

/// Widget that provides error state management to its children
class ErrorStateProvider extends InheritedNotifier<ErrorStateManager> {
  const ErrorStateProvider({
    super.key,
    required ErrorStateManager errorStateManager,
    required super.child,
  }) : super(notifier: errorStateManager);

  static ErrorStateManager of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<ErrorStateProvider>()!.notifier!;
    } else {
      return (context.getElementForInheritedWidgetOfExactType<ErrorStateProvider>()!.widget as ErrorStateProvider).notifier!;
    }
  }
}

/// Mixin for widgets that need error state management
mixin ErrorStateHandling<T extends StatefulWidget> on State<T> {
  late ErrorStateManager _errorStateManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _errorStateManager = ErrorStateProvider.of(context, listen: false);
  }

  /// Executes an operation with error handling
  Future<R> executeWithErrorHandling<R>(
    String operationKey,
    Future<R> Function() operation, {
    String? operationType,
    bool showUserFeedback = true,
  }) {
    return _errorStateManager.executeWithErrorHandling(
      operationKey,
      operation,
      operationType: operationType,
      showUserFeedback: showUserFeedback,
      context: context,
    );
  }

  /// Retries a failed operation
  Future<R> retryOperation<R>(
    String operationKey,
    Future<R> Function() operation, {
    String? operationType,
  }) {
    return _errorStateManager.retryOperation(
      operationKey,
      operation,
      operationType: operationType,
      context: context,
    );
  }

  /// Gets the current error state for an operation
  ErrorState? getErrorState(String operationKey) {
    return _errorStateManager.getErrorState(operationKey);
  }

  /// Gets the current retry state for an operation
  RetryState? getRetryState(String operationKey) {
    return _errorStateManager.getRetryState(operationKey);
  }

  /// Clears an error state
  void clearError(String operationKey) {
    _errorStateManager.clearError(operationKey);
  }
}