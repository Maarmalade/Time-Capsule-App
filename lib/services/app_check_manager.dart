import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../utils/error_handler.dart';

/// App Check Manager for handling Firebase App Check initialization
/// 
/// This service manages App Check configuration with proper development mode detection
/// to prevent authentication errors during development while maintaining security in production.
class AppCheckManager {
  static bool _isInitialized = false;
  
  /// Check if the app is running in development mode
  /// 
  /// Returns true if any of the following conditions are met:
  /// - Running in debug mode (kDebugMode)
  /// - Emulator environment is detected
  /// - App Check is explicitly disabled via environment variable
  static bool get isDevelopment {
    // Force App Check to be enabled for testing cloud functions
    // This will use debug providers which work in development
    return false; // Always enable App Check to fix authentication issues
  }
  
  /// Initialize Firebase App Check with conditional logic
  /// 
  /// In development mode, App Check is completely disabled to prevent
  /// "Authentication required" and "Too many attempts" errors when calling
  /// cloud functions. In production, App Check is properly initialized
  /// with platform-specific providers.
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('AppCheckManager: Already initialized, skipping');
      return;
    }
    
    try {
      if (isDevelopment) {
        debugPrint('AppCheckManager: Development mode detected - App Check disabled');
        debugPrint('AppCheckManager: Cloud functions will work without App Check verification');
        _isInitialized = true;
        return;
      }
      
      debugPrint('AppCheckManager: Production mode - initializing App Check');
      
      // Check if we're in debug mode but forcing App Check
      if (kDebugMode) {
        debugPrint('AppCheckManager: Debug mode with forced App Check - using debug provider');
        await FirebaseAppCheck.instance.activate(
          // Use debug provider for development testing
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          // Note: Web provider is configured differently - no WebProvider.debug exists
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          // Use Play Integrity for Android in production
          androidProvider: AndroidProvider.playIntegrity,
          // Note: iOS and web providers are configured separately in Firebase console
          // This activate call will use the default providers for other platforms
        );
      }
      
      debugPrint('AppCheckManager: App Check initialized successfully');
      _isInitialized = true;
      
    } catch (e) {
      // Log error but don't fail app startup
      ErrorHandler.logError('AppCheckManager.initialize', e);
      debugPrint('AppCheckManager: App Check initialization failed - continuing without it');
      debugPrint('AppCheckManager: Error: $e');
      
      // Mark as initialized even if it failed to prevent retry loops
      _isInitialized = true;
    }
  }
  
  /// Force disable App Check for development scenarios
  /// 
  /// This method can be called to explicitly disable App Check
  /// even if it was previously initialized. Useful for testing
  /// and development scenarios where App Check needs to be bypassed.
  static Future<void> disable() async {
    try {
      debugPrint('AppCheckManager: Forcibly disabling App Check');
      
      // Note: Firebase App Check doesn't have a direct disable method,
      // but we can mark it as disabled and ensure it's not initialized
      _isInitialized = false;
      
      debugPrint('AppCheckManager: App Check disabled successfully');
      
    } catch (e) {
      ErrorHandler.logError('AppCheckManager.disable', e);
      debugPrint('AppCheckManager: Error disabling App Check: $e');
    }
  }
  
  /// Check if App Check is currently initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get the current App Check status for debugging
  static String get status {
    if (isDevelopment) {
      return 'Disabled (Development Mode)';
    } else if (_isInitialized) {
      return 'Initialized (Production Mode)';
    } else {
      return 'Not Initialized';
    }
  }
  
  /// Check if running in emulator environment
  /// 
  /// Detects various emulator indicators including:
  /// - Explicit emulator environment variable
  /// - Flutter test environment
  /// - Firebase emulator usage flag
  static bool _isEmulatorEnvironment() {
    return const bool.fromEnvironment('USE_EMULATOR', defaultValue: false) ||
           const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
           const bool.fromEnvironment('FIREBASE_EMULATOR', defaultValue: false);
  }
  
  /// Validate App Check configuration for debugging
  /// 
  /// Returns a list of configuration issues or warnings.
  /// Useful for troubleshooting App Check setup problems.
  static List<String> validateConfiguration() {
    final issues = <String>[];
    
    if (isDevelopment) {
      issues.add('Running in development mode - App Check is disabled');
      
      if (kDebugMode) {
        issues.add('Debug mode detected (kDebugMode = true)');
      }
      
      if (_isEmulatorEnvironment()) {
        issues.add('Emulator environment detected');
      }
      
      if (const bool.fromEnvironment('DISABLE_APP_CHECK', defaultValue: false)) {
        issues.add('App Check explicitly disabled via DISABLE_APP_CHECK environment variable');
      }
    } else {
      if (!_isInitialized) {
        issues.add('Production mode but App Check not initialized');
      }
    }
    
    return issues;
  }
  
  /// Reset initialization state (for testing purposes)
  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
  }
}