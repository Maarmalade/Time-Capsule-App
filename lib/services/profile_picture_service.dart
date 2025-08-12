import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'user_profile_service.dart';

class ProfilePictureService {
  static final ProfilePictureService _instance = ProfilePictureService._internal();
  factory ProfilePictureService() => _instance;
  ProfilePictureService._internal();

  final UserProfileService _userProfileService = UserProfileService();
  UserProfile? _cachedProfile;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Gets the current user's profile with caching
  Future<UserProfile?> getCurrentUserProfile({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Check if we need to refresh the cache
    final now = DateTime.now();
    final shouldRefresh = forceRefresh || 
                         _cachedProfile == null || 
                         _lastFetch == null || 
                         now.difference(_lastFetch!) > _cacheTimeout;

    if (shouldRefresh) {
      try {
        _cachedProfile = await _userProfileService.getUserProfile(user.uid);
        _lastFetch = now;
      } catch (e) {
        // If fetch fails, return cached profile if available
        // This provides better UX when offline or during network issues
      }
    }

    return _cachedProfile;
  }

  /// Clears the cached profile (useful after profile updates)
  void clearCache() {
    _cachedProfile = null;
    _lastFetch = null;
  }

  /// Updates the cached profile after a successful update
  void updateCachedProfile(UserProfile profile) {
    _cachedProfile = profile;
    _lastFetch = DateTime.now();
  }
}