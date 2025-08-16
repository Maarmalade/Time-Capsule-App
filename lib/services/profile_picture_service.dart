import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../utils/comprehensive_error_handler.dart';
import 'user_profile_service.dart';

/// Cache entry for profile pictures with metadata
class ProfilePictureCacheEntry {
  final String? imageUrl;
  final DateTime lastUpdated;
  final DateTime lastAccessed;
  final bool isLoading;
  final int accessCount;

  ProfilePictureCacheEntry({
    required this.imageUrl,
    required this.lastUpdated,
    required this.lastAccessed,
    this.isLoading = false,
    this.accessCount = 1,
  });

  ProfilePictureCacheEntry copyWith({
    String? imageUrl,
    DateTime? lastUpdated,
    DateTime? lastAccessed,
    bool? isLoading,
    int? accessCount,
  }) {
    return ProfilePictureCacheEntry(
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isLoading: isLoading ?? this.isLoading,
      accessCount: accessCount ?? this.accessCount,
    );
  }

  bool isExpired() => DateTime.now().difference(lastUpdated) > Duration(minutes: 5);
  bool isStale() => DateTime.now().difference(lastUpdated) > Duration(minutes: 2);
}

class ProfilePictureService {
  static final ProfilePictureService _instance = ProfilePictureService._internal();
  factory ProfilePictureService() => _instance;
  ProfilePictureService._internal();

  final UserProfileService _userProfileService = UserProfileService();
  UserProfile? _cachedProfile;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  static const int _maxCacheSize = 100; // Maximum number of cached profile pictures

  // Enhanced global state management for profile pictures
  static final Map<String, ProfilePictureCacheEntry> _profilePictureCache = {};
  static final StreamController<Map<String, String?>> _profilePictureStreamController = 
      StreamController<Map<String, String?>>.broadcast();
  
  // Background refresh management
  static Timer? _backgroundRefreshTimer;
  static final Set<String> _refreshQueue = {};
  static bool _isBackgroundRefreshEnabled = true;

  /// Stream for broadcasting profile picture updates globally
  static Stream<Map<String, String?>> get profilePictureUpdates => 
      _profilePictureStreamController.stream;

  /// Gets the current user's profile with enhanced caching and error handling
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
        // Use fallback mechanism for profile fetching
        _cachedProfile = await ComprehensiveErrorHandler.withFallback<UserProfile?>(
          () async => await _userProfileService.getUserProfile(user.uid),
          () async {
            // Fallback: return cached profile if available
            if (_cachedProfile != null) {
              debugPrint('Using cached profile as fallback for user ${user.uid}');
              return _cachedProfile!;
            }
            throw Exception('No cached profile available');
          },
          operationName: 'Profile fetch for user ${user.uid}',
          maxRetries: 2,
          retryDelay: const Duration(seconds: 1),
        );
        
        _lastFetch = now;
        
        // Update global profile picture cache
        if (_cachedProfile != null) {
          updateProfilePictureGlobally(user.uid, _cachedProfile!.profilePictureUrl);
        }
      } catch (e) {
        // Enhanced error handling - log the error but don't throw
        debugPrint('Profile fetch failed for user ${user.uid}: ${ComprehensiveErrorHandler.getProfilePictureErrorMessage(e)}');
        
        // Return cached profile if available, otherwise null
        // This provides better UX when offline or during network issues
      }
    }

    return _cachedProfile;
  }

  /// Clears the cached profile (useful after profile updates)
  void clearCache() {
    _cachedProfile = null;
    _lastFetch = null;
    
    // Also clear from global cache if current user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      clearCacheForUser(user.uid);
    }
  }

  /// Updates the cached profile after a successful update
  void updateCachedProfile(UserProfile profile) {
    _cachedProfile = profile;
    _lastFetch = DateTime.now();
    
    // Update global profile picture cache
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      updateProfilePictureGlobally(user.uid, profile.profilePictureUrl);
    }
  }

  /// Gets profile picture URL from global cache with intelligent caching
  static String? getProfilePictureFromCache(String userId) {
    final cacheEntry = _profilePictureCache[userId];
    
    if (cacheEntry == null) {
      return null;
    }
    
    // Update access information
    _profilePictureCache[userId] = cacheEntry.copyWith(
      lastAccessed: DateTime.now(),
      accessCount: cacheEntry.accessCount + 1,
    );
    
    // Check if cache is expired
    if (cacheEntry.isExpired()) {
      // Schedule background refresh for expired entries
      _scheduleBackgroundRefresh(userId);
      
      // Return cached value while refreshing in background
      return cacheEntry.imageUrl;
    }
    
    // Check if cache is stale and schedule refresh
    if (cacheEntry.isStale()) {
      _scheduleBackgroundRefresh(userId);
    }
    
    return cacheEntry.imageUrl;
  }

  /// Updates profile picture globally and broadcasts the change
  static void updateProfilePictureGlobally(String userId, String? imageUrl) {
    final now = DateTime.now();
    final existingEntry = _profilePictureCache[userId];
    
    _profilePictureCache[userId] = ProfilePictureCacheEntry(
      imageUrl: imageUrl,
      lastUpdated: now,
      lastAccessed: now,
      accessCount: existingEntry?.accessCount ?? 1,
    );
    
    // Remove from refresh queue if it was scheduled
    _refreshQueue.remove(userId);
    
    // Perform memory management
    _performMemoryManagement();
    
    // Broadcast the update to all listeners
    _broadcastCacheUpdate();
  }

  /// Clears cache for a specific user (useful for user switching scenarios)
  static void clearCacheForUser(String userId) {
    _profilePictureCache.remove(userId);
    _refreshQueue.remove(userId);
    
    // Broadcast the update to all listeners
    _broadcastCacheUpdate();
  }

  /// Clears all cached profile pictures
  static void clearAllCache() {
    _profilePictureCache.clear();
    _refreshQueue.clear();
    
    // Broadcast the update to all listeners
    _broadcastCacheUpdate();
  }

  /// Gets the current cached profile pictures map
  static Map<String, String?> getCachedProfilePictures() {
    return _profilePictureCache.map((key, entry) => MapEntry(key, entry.imageUrl));
  }

  /// Schedules background refresh for a specific user
  static void _scheduleBackgroundRefresh(String userId) {
    if (!_isBackgroundRefreshEnabled || _refreshQueue.contains(userId)) {
      return;
    }
    
    _refreshQueue.add(userId);
    
    // Start background refresh timer if not already running
    if (_backgroundRefreshTimer == null || !_backgroundRefreshTimer!.isActive) {
      _startBackgroundRefreshTimer();
    }
  }

  /// Starts the background refresh timer
  static void _startBackgroundRefreshTimer() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _processBackgroundRefresh();
    });
  }

  /// Processes background refresh queue
  static void _processBackgroundRefresh() async {
    if (_refreshQueue.isEmpty) {
      _backgroundRefreshTimer?.cancel();
      return;
    }

    // Process up to 3 refreshes per cycle to avoid overwhelming the system
    final usersToRefresh = _refreshQueue.take(3).toList();
    
    for (final userId in usersToRefresh) {
      _refreshQueue.remove(userId);
      await _refreshProfilePictureInBackground(userId);
    }
  }

  /// Refreshes a profile picture in the background with enhanced error handling
  static Future<void> _refreshProfilePictureInBackground(String userId) async {
    try {
      final userProfileService = UserProfileService();
      
      // Use fallback mechanism for background refresh
      final profile = await ComprehensiveErrorHandler.withFallback<UserProfile?>(
        () async => await userProfileService.getUserProfile(userId),
        () async {
          // Fallback: keep existing cached value
          final existingEntry = _profilePictureCache[userId];
          if (existingEntry != null) {
            debugPrint('Background refresh failed for $userId, keeping cached value');
            return UserProfile(
              id: userId,
              username: 'Unknown',
              email: '',
              profilePictureUrl: existingEntry.imageUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          throw Exception('No cached profile available for background refresh');
        },
        operationName: 'Background profile refresh for $userId',
        maxRetries: 1, // Fewer retries for background operations
        retryDelay: const Duration(seconds: 2),
      );
      
      if (profile != null) {
        updateProfilePictureGlobally(userId, profile.profilePictureUrl);
      }
    } catch (e) {
      // Enhanced error handling for background refresh
      debugPrint('Background profile picture refresh failed for $userId: ${ComprehensiveErrorHandler.getProfilePictureErrorMessage(e, isCacheError: true)}');
      
      // Mark cache entry as having failed refresh (but don't remove it)
      final existingEntry = _profilePictureCache[userId];
      if (existingEntry != null) {
        _profilePictureCache[userId] = existingEntry.copyWith(
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)), // Mark as stale
        );
      }
    }
  }

  /// Performs memory management to keep cache size under control
  static void _performMemoryManagement() {
    if (_profilePictureCache.length <= _maxCacheSize) {
      return;
    }

    // Remove least recently used entries
    final entries = _profilePictureCache.entries.toList();
    entries.sort((a, b) {
      // Sort by last accessed time (oldest first)
      final accessComparison = a.value.lastAccessed.compareTo(b.value.lastAccessed);
      if (accessComparison != 0) return accessComparison;
      
      // If access times are equal, sort by access count (least used first)
      return a.value.accessCount.compareTo(b.value.accessCount);
    });

    // Remove oldest 20% of entries
    final entriesToRemove = (_profilePictureCache.length * 0.2).ceil();
    for (int i = 0; i < entriesToRemove && i < entries.length; i++) {
      _profilePictureCache.remove(entries[i].key);
      _refreshQueue.remove(entries[i].key);
    }
  }

  /// Broadcasts cache updates to all listeners
  static void _broadcastCacheUpdate() {
    if (!_profilePictureStreamController.isClosed) {
      final cacheMap = _profilePictureCache.map((key, entry) => MapEntry(key, entry.imageUrl));
      _profilePictureStreamController.add(Map.from(cacheMap));
    }
  }

  /// Invalidates cache for a specific user (forces refresh on next access)
  static void invalidateCacheForUser(String userId) {
    final entry = _profilePictureCache[userId];
    if (entry != null) {
      _profilePictureCache[userId] = entry.copyWith(
        lastUpdated: DateTime.now().subtract(Duration(hours: 1)), // Force expiration
      );
      _scheduleBackgroundRefresh(userId);
    }
  }

  /// Enables or disables background refresh
  static void setBackgroundRefreshEnabled(bool enabled) {
    _isBackgroundRefreshEnabled = enabled;
    if (!enabled) {
      _backgroundRefreshTimer?.cancel();
      _refreshQueue.clear();
    }
  }

  /// Gets cache statistics for debugging
  static Map<String, dynamic> getCacheStatistics() {
    int expiredCount = 0;
    int staleCount = 0;
    int totalAccessCount = 0;

    for (final entry in _profilePictureCache.values) {
      if (entry.isExpired()) expiredCount++;
      if (entry.isStale()) staleCount++;
      totalAccessCount += entry.accessCount;
    }

    return {
      'totalEntries': _profilePictureCache.length,
      'expiredEntries': expiredCount,
      'staleEntries': staleCount,
      'refreshQueueSize': _refreshQueue.length,
      'totalAccessCount': totalAccessCount,
      'backgroundRefreshEnabled': _isBackgroundRefreshEnabled,
    };
  }

  /// Disposes the stream controller and timers (call this when app is closing)
  static void dispose() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
    _refreshQueue.clear();
    
    // Don't close the stream controller in dispose as it may be called multiple times
    // The stream controller will be garbage collected when the app closes
  }

  /// Resets the service state (useful for testing)
  static void reset() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
    _profilePictureCache.clear();
    _refreshQueue.clear();
    _isBackgroundRefreshEnabled = true;
  }
}