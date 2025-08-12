import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}