import 'package:firebase_auth/firebase_auth.dart';
import 'profile_picture_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Sign out the current user
  Future<void> signOut() async {
    // Clear profile picture cache before signing out
    ProfilePictureService.clearAllCache();
    await _auth.signOut();
  }

  /// Listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}