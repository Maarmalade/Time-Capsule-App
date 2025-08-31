import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_picture_service.dart';
import 'fcm_service.dart';
import '../utils/error_handler.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FCMService _fcmService;

  /// Constructor with dependency injection for testing
  AuthService({
    FirebaseAuth? auth,
    FCMService? fcmService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _fcmService = fcmService ?? FCMService.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Sign in with email and password with enhanced error handling and retry logic
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input parameters
      if (email.trim().isEmpty) {
        return AuthResult.failure('Please enter your email address');
      }
      if (password.isEmpty) {
        return AuthResult.failure('Please enter your password');
      }
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      // Attempt sign in with retry logic for network-related failures
      final credential = await ErrorHandler.retryAuthOperation(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );
      
      // Handle FCM token setup after successful login (non-blocking)
      _handleFCMTokenOnLoginSafely();
      
      return AuthResult.success(credential.user, message: 'Successfully signed in');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.signInWithEmailAndPassword', e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.signInWithEmailAndPassword', e);
      
      // Handle network errors specifically
      if (ErrorHandler.isNetworkError(e)) {
        return AuthResult.failure('Network error. Please check your internet connection and try again.');
      }
      
      return AuthResult.failure('An unexpected error occurred during sign in. Please try again.');
    }
  }

  /// Create user with email and password with enhanced error handling and retry logic
  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Validate input parameters
      if (email.trim().isEmpty) {
        return AuthResult.failure('Please enter your email address');
      }
      if (password.isEmpty) {
        return AuthResult.failure('Please enter a password');
      }
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }
      if (password.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters long');
      }

      // Attempt user creation with retry logic for network-related failures
      final credential = await ErrorHandler.retryAuthOperation(
        () => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );
      
      // Update display name if provided
      if (displayName != null && displayName.trim().isNotEmpty && credential.user != null) {
        try {
          await credential.user!.updateDisplayName(displayName.trim());
          await credential.user!.reload();
        } catch (e) {
          ErrorHandler.logError('AuthService.updateDisplayName', e);
          // Don't fail registration if display name update fails
        }
      }
      
      // Handle FCM token setup after successful registration (non-blocking)
      _handleFCMTokenOnLoginSafely();
      
      return AuthResult.success(credential.user, message: 'Account created successfully');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.createUserWithEmailAndPassword', e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.createUserWithEmailAndPassword', e);
      
      // Handle network errors specifically
      if (ErrorHandler.isNetworkError(e)) {
        return AuthResult.failure('Network error. Please check your internet connection and try again.');
      }
      
      return AuthResult.failure('An unexpected error occurred during registration. Please try again.');
    }
  }

  /// Sign in with Google with enhanced error handling
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google sign-in was cancelled');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await ErrorHandler.retryAuthOperation(
        () => _auth.signInWithCredential(credential),
      );
      
      // Handle FCM token setup after successful login (non-blocking)
      _handleFCMTokenOnLoginSafely();
      
      return AuthResult.success(userCredential.user, message: 'Successfully signed in with Google');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.signInWithGoogle', e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.signInWithGoogle', e);
      
      if (ErrorHandler.isNetworkError(e)) {
        return AuthResult.failure('Network error during Google sign-in. Please check your connection and try again.');
      }
      
      return AuthResult.failure('Google sign-in failed. Please try again.');
    }
  }

  /// Sign in anonymously with enhanced error handling
  Future<AuthResult> signInAnonymously() async {
    try {
      final credential = await ErrorHandler.retryAuthOperation(
        () => _auth.signInAnonymously(),
      );
      
      // Handle FCM token setup after successful login (non-blocking)
      _handleFCMTokenOnLoginSafely();
      
      return AuthResult.success(credential.user, message: 'Signed in as guest');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.signInAnonymously', e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.signInAnonymously', e);
      
      if (ErrorHandler.isNetworkError(e)) {
        return AuthResult.failure('Network error. Please check your connection and try again.');
      }
      
      return AuthResult.failure('Anonymous sign-in failed. Please try again.');
    }
  }

  /// Send password reset email with enhanced error handling
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      // Validate email
      if (email.trim().isEmpty) {
        return AuthResult.failure('Please enter your email address');
      }
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      await ErrorHandler.retryAuthOperation(
        () => _auth.sendPasswordResetEmail(email: email.trim()),
      );
      
      return AuthResult.success(null, message: 'Password reset email sent. Please check your inbox.');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.sendPasswordResetEmail', e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.sendPasswordResetEmail', e);
      
      if (ErrorHandler.isNetworkError(e)) {
        return AuthResult.failure('Network error. Please check your connection and try again.');
      }
      
      return AuthResult.failure('Failed to send password reset email. Please try again.');
    }
  }

  /// Delete user account with enhanced error handling
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }
      
      // Clear FCM tokens before deleting account
      try {
        await _fcmService.clearAllUserTokens();
      } catch (e) {
        ErrorHandler.logError('AuthService.deleteAccount.clearTokens', e);
        // Continue with account deletion even if token cleanup fails
      }
      
      await ErrorHandler.retryAuthOperation(
        () => user.delete(),
      );
      
      return AuthResult.success(null, message: 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.deleteAccount', e);
      
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure('For security reasons, please sign in again before deleting your account');
      }
      
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.deleteAccount', e);
      
      if (ErrorHandler.isNetworkError(e)) {
        return AuthResult.failure('Network error. Please check your connection and try again.');
      }
      
      return AuthResult.failure('Failed to delete account. Please try again.');
    }
  }

  /// Update user profile with enhanced error handling
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }
      
      // Validate inputs
      if (displayName != null && displayName.trim().isEmpty) {
        return AuthResult.failure('Display name cannot be empty');
      }
      
      await ErrorHandler.retryAuthOperation(
        () async {
          if (displayName != null) {
            await user.updateDisplayName(displayName.trim());
          }
          if (photoURL != null) {
            await user.updatePhotoURL(photoURL);
          }
          await user.reload();
        },
      );
      
      return AuthResult.success(user, message: 'Profile updated successfully');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.updateProfile', e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.updateProfile', e);
      
      if (ErrorHandler.isNetworkError(e)) {
        return AuthResult.failure('Network error. Please check your connection and try again.');
      }
      
      return AuthResult.failure('Failed to update profile. Please try again.');
    }
  }

  /// Verify authentication state for protected operations
  Future<bool> verifyAuthentication() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Reload user to ensure token is valid with retry logic
      await ErrorHandler.retryAuthOperation(
        () => user.reload(),
      );
      
      return _auth.currentUser != null;
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.verifyAuthentication', e);
      
      // If token is expired or invalid, user needs to re-authenticate
      if (e.code == 'token-expired' || e.code == 'user-token-expired' || e.code == 'invalid-credential') {
        return false;
      }
      
      // For other auth errors, assume authentication is invalid
      return false;
    } catch (e) {
      ErrorHandler.logError('AuthService.verifyAuthentication', e);
      return false;
    }
  }

  /// Handle FCM token on login/registration with enhanced error handling (non-blocking)
  void _handleFCMTokenOnLoginSafely() {
    // Run FCM token handling in the background without blocking authentication
    Future.microtask(() async {
      try {
        await ErrorHandler.retryFCMOperation(
          () async {
            final token = await _fcmService.getToken();
            if (token != null) {
              await _fcmService.storeTokenInFirestore(token);
              await _fcmService.sendTokenToBackend(token);
            }
          },
        );
      } catch (e) {
        // Don't fail login if FCM token handling fails
        ErrorHandler.logError('AuthService._handleFCMTokenOnLoginSafely', e);
        
        // Log specific FCM errors for debugging but don't surface to user
        if (e.toString().contains('permission')) {
          debugPrint('FCM: Notification permissions not granted during login');
        } else if (ErrorHandler.isNetworkError(e)) {
          debugPrint('FCM: Network error during token setup - will retry later');
        } else {
          debugPrint('FCM: Token setup failed during login: $e');
        }
      }
    });
  }

  /// Handle FCM token refresh for existing authenticated users with enhanced error handling
  Future<void> refreshFCMToken() async {
    if (!isLoggedIn) return;
    
    try {
      await ErrorHandler.retryFCMOperation(
        () async {
          final token = await _fcmService.getToken();
          if (token != null) {
            await _fcmService.storeTokenInFirestore(token);
            await _fcmService.sendTokenToBackend(token);
          }
        },
      );
    } catch (e) {
      ErrorHandler.logError('AuthService.refreshFCMToken', e);
      
      // Provide more specific logging for FCM token refresh failures
      if (e.toString().contains('permission')) {
        debugPrint('FCM: Token refresh failed - notification permissions may have been revoked');
      } else if (ErrorHandler.isNetworkError(e)) {
        debugPrint('FCM: Token refresh failed due to network issues - will retry automatically');
      } else {
        debugPrint('FCM: Token refresh failed: $e');
      }
    }
  }

  /// Sign out the current user with comprehensive error handling
  Future<AuthResult> signOut() async {
    try {
      // Clear FCM token before signing out with enhanced retry logic
      try {
        await ErrorHandler.retryFCMOperation(
          () => _fcmService.clearToken(),
        );
      } catch (e) {
        ErrorHandler.logError('AuthService.signOut.clearFCMToken', e);
        // Continue with sign out even if FCM token cleanup fails
      }
      
      // Clear profile picture cache before signing out
      try {
        ProfilePictureService.clearAllCache();
      } catch (e) {
        ErrorHandler.logError('AuthService.signOut.clearCache', e);
        // Continue with sign out even if cache cleanup fails
      }
      
      // Sign out from Google if signed in with Google
      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        ErrorHandler.logError('AuthService.signOut.googleSignOut', e);
        // Continue with Firebase sign out even if Google sign out fails
      }
      
      // Sign out from Firebase Auth with retry for network issues
      await ErrorHandler.retryAuthOperation(
        () => _auth.signOut(),
      );
      
      return AuthResult.success(null, message: 'Successfully signed out');
    } on FirebaseAuthException catch (e) {
      ErrorHandler.logError('AuthService.signOut', e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      ErrorHandler.logError('AuthService.signOut', e);
      
      // Even if cleanup fails, still try to sign out from Firebase Auth
      try {
        await ErrorHandler.retryAuthOperation(
          () => _auth.signOut(),
        );
        
        return AuthResult.success(null, message: 'Signed out (some cleanup operations failed)');
      } catch (signOutError) {
        ErrorHandler.logError('AuthService.signOut.fallback', signOutError);
        
        // If sign out completely fails, at least clear local data
        try {
          ProfilePictureService.clearAllCache();
        } catch (cacheError) {
          ErrorHandler.logError('AuthService.signOut.clearCache.fallback', cacheError);
        }
        
        if (ErrorHandler.isNetworkError(signOutError)) {
          return AuthResult.failure('Network error during sign out. Please check your connection and try again.');
        }
        
        return AuthResult.failure('Failed to sign out completely. Please restart the app if you continue to have issues.');
      }
    }
  }

  /// Listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Get user-friendly error messages for Firebase Auth exceptions
  String _getAuthErrorMessage(FirebaseAuthException e) {
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
      case 'user-token-expired':
        return 'Your session has expired. Please sign in again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials. Please try signing in with a different method.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      case 'missing-verification-code':
        return 'Please enter the verification code.';
      case 'missing-verification-id':
        return 'Verification ID is missing. Please try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-check-token-invalid':
        return 'Authentication verification failed. Please try again.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'invalid-app-credential':
        return 'Invalid app credential. Please contact support.';
      case 'invalid-api-key':
        return 'Invalid API key. Please contact support.';
      case 'app-not-authorized':
        return 'App not authorized. Please contact support.';
      case 'keychain-error':
        return 'Keychain error occurred. Please try again.';
      case 'internal-error':
        return 'An internal error occurred. Please try again later.';
      case 'invalid-custom-token':
        return 'Invalid custom token. Please contact support.';
      case 'custom-token-mismatch':
        return 'Custom token mismatch. Please contact support.';
      case 'invalid-user-token':
        return 'Invalid user token. Please sign in again.';
      case 'user-mismatch':
        return 'User mismatch error. Please try again.';
      case 'provider-already-linked':
        return 'This account is already linked with this provider.';
      case 'no-such-provider':
        return 'No such provider linked to this account.';
      case 'invalid-provider-id':
        return 'Invalid provider ID.';
      case 'web-storage-unsupported':
        return 'Web storage is not supported in this browser.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

/// Authentication result wrapper for enhanced error handling
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  final String? message;
  
  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.message,
  });
  
  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
    );
  }
  
  factory AuthResult.failure(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}