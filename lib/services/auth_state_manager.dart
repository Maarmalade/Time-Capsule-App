import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import '../utils/error_handler.dart';

/// Centralized authentication state manager for persistent authentication
/// 
/// This service provides a single source of truth for authentication state
/// and handles Firebase Auth stream integration for real-time auth changes.
class AuthStateManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Stream for real-time authentication state changes
  /// 
  /// This stream emits whenever the user's authentication state changes,
  /// including login, logout, and token refresh events.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Check if user is currently authenticated
  /// 
  /// Returns true if a user is signed in and has a valid authentication token.
  static bool get isAuthenticated => _auth.currentUser != null;
  
  /// Get the current authenticated user
  /// 
  /// Returns the current User object if authenticated, null otherwise.
  static User? get currentUser => _auth.currentUser;
  
  /// Get the current user's UID
  /// 
  /// Returns the user ID if authenticated, null otherwise.
  static String? get currentUserId => _auth.currentUser?.uid;
  
  /// Sign out the current user and clear all cached data
  /// 
  /// This method performs a complete logout by:
  /// 1. Clearing FCM tokens
  /// 2. Clearing profile picture cache
  /// 3. Signing out from Firebase Auth
  /// 4. Clearing any other cached user data
  /// 
  /// Throws [FirebaseAuthException] if sign out fails.
  static Future<void> signOut() async {
    try {
      // Use AuthService for complete sign out including FCM cleanup
      final authService = AuthService();
      await authService.signOut();
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthStateManager.signOut', e);
      // Re-throw Firebase auth exceptions for proper error handling
      throw FirebaseAuthException(
        code: e.code,
        message: 'Failed to sign out: ${e.message}',
      );
    } catch (e) {
      ErrorHandler.logError('AuthStateManager.signOut', e);
      // Wrap other exceptions in FirebaseAuthException for consistency
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'An unexpected error occurred during sign out: $e',
      );
    }
  }
  
  /// Check if the current authentication token is valid
  /// 
  /// This method verifies that the user is authenticated and the token
  /// hasn't expired. It can be used to validate auth state before
  /// performing sensitive operations.
  /// 
  /// Returns true if the token is valid, false otherwise.
  static Future<bool> isTokenValid() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Force token refresh to check validity
      await user.getIdToken(true);
      return true;
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthStateManager.isTokenValid', e);
      // Handle specific auth errors
      if (e.code == 'token-expired' || e.code == 'user-token-expired') {
        return false;
      }
      // For other auth errors, assume token is invalid
      return false;
    } catch (e) {
      ErrorHandler.logError('AuthStateManager.isTokenValid', e);
      // Token is invalid or expired
      return false;
    }
  }
  
  /// Refresh the current user's authentication token
  /// 
  /// This method forces a token refresh, which is useful for:
  /// - Ensuring the token is up to date
  /// - Checking if the user's account is still valid
  /// - Refreshing custom claims
  /// 
  /// Returns the new token if successful, null if user is not authenticated.
  /// Throws [FirebaseAuthException] if token refresh fails.
  static Future<String?> refreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      return await user.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthStateManager.refreshToken', e);
      throw FirebaseAuthException(
        code: e.code,
        message: 'Failed to refresh token: ${e.message}',
      );
    } catch (e) {
      ErrorHandler.logError('AuthStateManager.refreshToken', e);
      throw FirebaseAuthException(
        code: 'token-refresh-failed',
        message: 'An unexpected error occurred while refreshing token: $e',
      );
    }
  }
  
  /// Wait for the authentication state to be initialized
  /// 
  /// This method is useful during app startup to ensure Firebase Auth
  /// has finished initializing before making routing decisions.
  /// 
  /// Returns the current user once auth state is ready.
  static Future<User?> waitForAuthInitialization() async {
    // Get the first emission from the auth state stream
    return await _auth.authStateChanges().first;
  }
  
  /// Refresh FCM token for existing authenticated users
  /// 
  /// This method should be called when the app starts and a user is already
  /// authenticated to ensure their FCM token is up to date.
  /// 
  /// This handles the case where a user was already logged in and the app
  /// is restarted, ensuring their device token is current.
  static Future<void> refreshFCMTokenForExistingUser() async {
    if (!isAuthenticated) return;
    
    try {
      final authService = AuthService();
      await ErrorHandler.retryOperation(
        () => authService.refreshFCMToken(),
        maxRetries: 3,
        initialDelay: const Duration(seconds: 2),
      );
    } catch (e) {
      // Don't fail app startup if FCM token refresh fails
      ErrorHandler.logError('AuthStateManager.refreshFCMTokenForExistingUser', e);
    }
  }
}