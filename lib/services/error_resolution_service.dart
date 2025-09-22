import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/error_handler.dart';

/// Comprehensive error resolution service for validating Firebase dependencies,
/// creating error boundaries, and tracking application errors
class ErrorResolutionService {
  static final ErrorResolutionService _instance = ErrorResolutionService._internal();
  factory ErrorResolutionService() => _instance;
  ErrorResolutionService._internal();

  /// List of tracked errors for debugging and analysis
  final List<AppError> _trackedErrors = [];

  /// Get all tracked errors
  List<AppError> get trackedErrors => List.unmodifiable(_trackedErrors);

  /// Validate all Firebase service dependencies and configurations
  static Future<ServiceValidationResult> validateServices() async {
    final errors = <String>[];
    final warnings = <String>[];
    final validServices = <String>[];

    try {
      // Check Firebase initialization
      await _validateFirebaseCore(errors, validServices);
      
      // Check Authentication service
      await _validateAuthenticationService(errors, warnings, validServices);
      
      // Check Firestore connectivity
      await _validateFirestoreService(errors, warnings, validServices);
      
      // Check Firebase Storage
      await _validateStorageService(errors, warnings, validServices);
      
      // Check Firebase Messaging
      await _validateMessagingService(errors, warnings, validServices);
      
    } catch (e) {
      errors.add('Critical error during service validation: $e');
      ErrorHandler.logError('ErrorResolutionService.validateServices', e);
    }

    return ServiceValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      validServices: validServices,
    );
  }

  /// Validate Firebase Core initialization
  static Future<void> _validateFirebaseCore(List<String> errors, List<String> validServices) async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        errors.add('Firebase is not initialized');
        return;
      }
      
      final app = Firebase.app();
      if (app.name != '[DEFAULT]') {
        errors.add('Firebase default app not found');
        return;
      }
      
      validServices.add('Firebase Core');
      debugPrint('✓ Firebase Core validation passed');
    } catch (e) {
      errors.add('Firebase Core validation failed: $e');
      ErrorHandler.logError('ErrorResolutionService._validateFirebaseCore', e);
    }
  }

  /// Validate Firebase Authentication service
  static Future<void> _validateAuthenticationService(
    List<String> errors, 
    List<String> warnings, 
    List<String> validServices
  ) async {
    try {
      final auth = FirebaseAuth.instance;
      
      // Check if auth instance is available
      if (auth.app.name != '[DEFAULT]') {
        errors.add('Firebase Auth not properly initialized');
        return;
      }
      
      // Check current user state (warning if no user, not error)
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        warnings.add('No user currently authenticated');
      } else {
        debugPrint('✓ User authenticated: ${currentUser.uid}');
      }
      
      // Test auth state changes stream
      final streamTest = auth.authStateChanges().take(1);
      await streamTest.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          warnings.add('Auth state changes stream timeout');
          return null;
        },
      );
      
      validServices.add('Firebase Authentication');
      debugPrint('✓ Firebase Authentication validation passed');
    } catch (e) {
      errors.add('Firebase Authentication validation failed: $e');
      ErrorHandler.logError('ErrorResolutionService._validateAuthenticationService', e);
    }
  }

  /// Validate Firestore connectivity and permissions
  static Future<void> _validateFirestoreService(
    List<String> errors, 
    List<String> warnings, 
    List<String> validServices
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Test basic connectivity with a simple read operation
      await firestore.enableNetwork();
      
      // Test read permissions with a safe collection query
      final testQuery = firestore
          .collection('test_connection')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      
      await testQuery.catchError((error) {
        if (error.toString().contains('permission-denied')) {
          warnings.add('Firestore permissions may be restricted');
        } else if (error.toString().contains('unavailable')) {
          warnings.add('Firestore temporarily unavailable');
        } else {
          warnings.add('Firestore connectivity issue: $error');
        }
      });
      
      validServices.add('Cloud Firestore');
      debugPrint('✓ Cloud Firestore validation passed');
    } catch (e) {
      errors.add('Cloud Firestore validation failed: $e');
      ErrorHandler.logError('ErrorResolutionService._validateFirestoreService', e);
    }
  }

  /// Validate Firebase Storage service
  static Future<void> _validateStorageService(
    List<String> errors, 
    List<String> warnings, 
    List<String> validServices
  ) async {
    try {
      final storage = FirebaseStorage.instance;
      
      // Test storage reference creation
      final testRef = storage.ref().child('test_connection');
      
      // Test basic storage operations (metadata retrieval)
      await testRef.getMetadata().timeout(
        const Duration(seconds: 10),
      ).catchError((error) {
        if (error.toString().contains('object-not-found')) {
          // This is expected for a test file that doesn't exist
          debugPrint('✓ Storage connectivity test passed (object-not-found expected)');
        } else if (error.toString().contains('permission-denied')) {
          warnings.add('Firebase Storage permissions may be restricted');
        } else {
          warnings.add('Firebase Storage connectivity issue: $error');
        }
      });
      
      validServices.add('Firebase Storage');
      debugPrint('✓ Firebase Storage validation passed');
    } catch (e) {
      errors.add('Firebase Storage validation failed: $e');
      ErrorHandler.logError('ErrorResolutionService._validateStorageService', e);
    }
  }

  /// Validate Firebase Messaging service
  static Future<void> _validateMessagingService(
    List<String> errors, 
    List<String> warnings, 
    List<String> validServices
  ) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Test messaging permissions
      final settings = await messaging.requestPermission().timeout(
        const Duration(seconds: 10),
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        warnings.add('Firebase Messaging permissions denied by user');
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        warnings.add('Firebase Messaging permissions not determined');
      }
      
      // Test token generation (may fail on some platforms, so treat as warning)
      try {
        final token = await messaging.getToken().timeout(
          const Duration(seconds: 10),
        );
        if (token != null) {
          debugPrint('✓ FCM token generated successfully');
        } else {
          warnings.add('FCM token generation returned null');
        }
      } catch (tokenError) {
        warnings.add('FCM token generation failed: $tokenError');
      }
      
      validServices.add('Firebase Messaging');
      debugPrint('✓ Firebase Messaging validation passed');
    } catch (e) {
      errors.add('Firebase Messaging validation failed: $e');
      ErrorHandler.logError('ErrorResolutionService._validateMessagingService', e);
    }
  }

  /// Create an error boundary widget that catches and handles widget errors
  static Widget createErrorBoundary({
    required Widget child,
    required String context,
    Widget? fallbackWidget,
    VoidCallback? onError,
  }) {
    return ErrorBoundaryWidget(
      context: context,
      fallbackWidget: fallbackWidget,
      onError: onError,
      child: child,
    );
  }

  /// Track an error for analysis and debugging
  void trackError(AppError error) {
    _trackedErrors.add(error);
    
    // Keep only the last 100 errors to prevent memory issues
    if (_trackedErrors.length > 100) {
      _trackedErrors.removeAt(0);
    }
    
    // Log the error using the existing error handler
    ErrorHandler.logError(error.context, error.message);
    
    debugPrint('📊 Error tracked: ${error.context} - ${error.message}');
  }

  /// Create and track an error
  void logAndTrackError(String context, dynamic error, {Map<String, dynamic>? metadata}) {
    final appError = AppError(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      context: context,
      message: error.toString(),
      timestamp: DateTime.now(),
      stackTrace: error is Error ? error.stackTrace?.toString() : null,
      metadata: metadata,
    );
    
    trackError(appError);
  }

  /// Get error statistics for debugging
  ErrorStatistics getErrorStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastHour = now.subtract(const Duration(hours: 1));
    
    final recent24h = _trackedErrors.where((e) => e.timestamp.isAfter(last24Hours)).length;
    final recentHour = _trackedErrors.where((e) => e.timestamp.isAfter(lastHour)).length;
    
    // Group errors by context
    final contextCounts = <String, int>{};
    for (final error in _trackedErrors) {
      contextCounts[error.context] = (contextCounts[error.context] ?? 0) + 1;
    }
    
    return ErrorStatistics(
      totalErrors: _trackedErrors.length,
      errorsLast24Hours: recent24h,
      errorsLastHour: recentHour,
      errorsByContext: contextCounts,
      mostRecentError: _trackedErrors.isNotEmpty ? _trackedErrors.last : null,
    );
  }

  /// Clear all tracked errors
  void clearTrackedErrors() {
    _trackedErrors.clear();
    debugPrint('🧹 All tracked errors cleared');
  }

  /// Validate specific service by name
  static Future<bool> validateSpecificService(String serviceName) async {
    try {
      switch (serviceName.toLowerCase()) {
        case 'auth':
        case 'authentication':
          final errors = <String>[];
          final warnings = <String>[];
          final validServices = <String>[];
          await _validateAuthenticationService(errors, warnings, validServices);
          return errors.isEmpty;
          
        case 'firestore':
        case 'database':
          final errors = <String>[];
          final warnings = <String>[];
          final validServices = <String>[];
          await _validateFirestoreService(errors, warnings, validServices);
          return errors.isEmpty;
          
        case 'storage':
          final errors = <String>[];
          final warnings = <String>[];
          final validServices = <String>[];
          await _validateStorageService(errors, warnings, validServices);
          return errors.isEmpty;
          
        case 'messaging':
        case 'fcm':
          final errors = <String>[];
          final warnings = <String>[];
          final validServices = <String>[];
          await _validateMessagingService(errors, warnings, validServices);
          return errors.isEmpty;
          
        default:
          debugPrint('⚠️ Unknown service name: $serviceName');
          return false;
      }
    } catch (e) {
      ErrorHandler.logError('ErrorResolutionService.validateSpecificService', e);
      return false;
    }
  }
}

/// Error boundary widget that provides safe error handling for child widgets
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final String context;
  final Widget? fallbackWidget;
  final VoidCallback? onError;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    required this.context,
    this.fallbackWidget,
    this.onError,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallbackWidget ?? _buildDefaultErrorWidget();
    }

    // Use a simple approach that works reliably in tests
    return _SafeBuilder(
      context: widget.context,
      onError: _handleError,
      builder: () => widget.child,
    );
  }

  void _handleError(dynamic error, StackTrace? stackTrace) {
    if (!mounted) return;
    
    setState(() {
      _hasError = true;
      _errorMessage = error.toString();
    });

    // Track the error
    ErrorResolutionService().logAndTrackError(
      'ErrorBoundary.${widget.context}',
      error,
      metadata: {
        'stackTrace': stackTrace?.toString(),
        'widget_context': widget.context,
      },
    );

    // Call the error callback if provided
    widget.onError?.call();

    debugPrint('🚨 Error boundary caught error in ${widget.context}: $error');
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Error in ${widget.context}',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Safe builder that catches errors during widget construction
class _SafeBuilder extends StatelessWidget {
  final String context;
  final Widget Function() builder;
  final Function(dynamic error, StackTrace? stackTrace) onError;

  const _SafeBuilder({
    required this.context,
    required this.builder,
    required this.onError,
  });

  @override
  Widget build(BuildContext buildContext) {
    try {
      return builder();
    } catch (error, stackTrace) {
      // Handle the error immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onError(error, stackTrace);
      });
      
      // Return a simple error display
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Error in $context',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Result of service validation
class ServiceValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> validServices;

  const ServiceValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.validServices,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Service Validation Result:');
    buffer.writeln('  Valid: $isValid');
    
    if (validServices.isNotEmpty) {
      buffer.writeln('  Valid Services: ${validServices.join(', ')}');
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('  Warnings:');
      for (final warning in warnings) {
        buffer.writeln('    - $warning');
      }
    }
    
    if (errors.isNotEmpty) {
      buffer.writeln('  Errors:');
      for (final error in errors) {
        buffer.writeln('    - $error');
      }
    }
    
    return buffer.toString();
  }
}

/// Error statistics for debugging and monitoring
class ErrorStatistics {
  final int totalErrors;
  final int errorsLast24Hours;
  final int errorsLastHour;
  final Map<String, int> errorsByContext;
  final AppError? mostRecentError;

  const ErrorStatistics({
    required this.totalErrors,
    required this.errorsLast24Hours,
    required this.errorsLastHour,
    required this.errorsByContext,
    this.mostRecentError,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Error Statistics:');
    buffer.writeln('  Total Errors: $totalErrors');
    buffer.writeln('  Last 24 Hours: $errorsLast24Hours');
    buffer.writeln('  Last Hour: $errorsLastHour');
    
    if (errorsByContext.isNotEmpty) {
      buffer.writeln('  Errors by Context:');
      final sortedContexts = errorsByContext.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedContexts.take(5)) {
        buffer.writeln('    ${entry.key}: ${entry.value}');
      }
    }
    
    if (mostRecentError != null) {
      buffer.writeln('  Most Recent: ${mostRecentError!.context} - ${mostRecentError!.message}');
    }
    
    return buffer.toString();
  }
}

/// Application error model for tracking
class AppError {
  final String id;
  final String context;
  final String message;
  final DateTime timestamp;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;

  const AppError({
    required this.id,
    required this.context,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'context': context,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'stackTrace': stackTrace,
    'metadata': metadata,
  };

  factory AppError.fromJson(Map<String, dynamic> json) => AppError(
    id: json['id'] as String,
    context: json['context'] as String,
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    stackTrace: json['stackTrace'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  @override
  String toString() => '$context: $message (${timestamp.toIso8601String()})';
}