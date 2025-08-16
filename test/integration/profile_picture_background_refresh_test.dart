import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/services/profile_picture_service.dart';

void main() {
  group('ProfilePictureService Background Refresh Integration', () {
    setUp(() {
      // Reset service state before each test
      ProfilePictureService.reset();
      ProfilePictureService.setBackgroundRefreshEnabled(true);
    });

    tearDown(() {
      ProfilePictureService.reset();
    });

    test('should schedule background refresh for expired entries', () {
      const userId = 'user123';
      const imageUrl = 'https://example.com/profile.jpg';

      // Add initial cache entry
      ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
      
      // Verify initial cache
      expect(ProfilePictureService.getProfilePictureFromCache(userId), equals(imageUrl));

      // Invalidate cache to simulate expiration
      ProfilePictureService.invalidateCacheForUser(userId);

      // Access cache to trigger background refresh
      final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
      expect(cachedUrl, equals(imageUrl)); // Should return old value immediately

      // Verify refresh was scheduled
      final stats = ProfilePictureService.getCacheStatistics();
      expect(stats['refreshQueueSize'], greaterThan(0));
    });

    test('should handle refresh queue management', () {
      const userId = 'user123';
      const imageUrl = 'https://example.com/profile.jpg';

      // Add cache entry
      ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
      
      // Invalidate cache to trigger refresh
      ProfilePictureService.invalidateCacheForUser(userId);
      ProfilePictureService.getProfilePictureFromCache(userId);

      // Should still return cached value
      final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
      expect(cachedUrl, equals(imageUrl));
      
      // Verify refresh was scheduled
      final stats = ProfilePictureService.getCacheStatistics();
      expect(stats['refreshQueueSize'], greaterThan(0));
    });

    test('should process multiple refresh requests efficiently', () {
      const userIds = ['user1', 'user2', 'user3', 'user4', 'user5'];
      
      // Add cache entries for all users
      for (final userId in userIds) {
        ProfilePictureService.updateProfilePictureGlobally(
          userId, 
          'https://example.com/old_$userId.jpg'
        );
      }

      // Invalidate all caches to trigger refresh
      for (final userId in userIds) {
        ProfilePictureService.invalidateCacheForUser(userId);
        ProfilePictureService.getProfilePictureFromCache(userId);
      }

      // Verify all are scheduled for refresh
      var stats = ProfilePictureService.getCacheStatistics();
      expect(stats['refreshQueueSize'], equals(userIds.length));
    });

    test('should respect background refresh enabled/disabled state', () {
      const userId = 'user123';
      const imageUrl = 'https://example.com/profile.jpg';

      // Disable background refresh
      ProfilePictureService.setBackgroundRefreshEnabled(false);

      // Add cache entry and invalidate
      ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
      ProfilePictureService.invalidateCacheForUser(userId);
      ProfilePictureService.getProfilePictureFromCache(userId);

      // Should not schedule refresh when disabled
      var stats = ProfilePictureService.getCacheStatistics();
      expect(stats['refreshQueueSize'], equals(0));
      expect(stats['backgroundRefreshEnabled'], isFalse);

      // Re-enable background refresh
      ProfilePictureService.setBackgroundRefreshEnabled(true);
      
      // Now should schedule refresh
      ProfilePictureService.invalidateCacheForUser(userId);
      ProfilePictureService.getProfilePictureFromCache(userId);

      stats = ProfilePictureService.getCacheStatistics();
      expect(stats['refreshQueueSize'], greaterThan(0));
      expect(stats['backgroundRefreshEnabled'], isTrue);
    });

    test('should broadcast cache updates', () async {
      const userId = 'user123';
      const imageUrl = 'https://example.com/profile.jpg';

      final streamUpdates = <Map<String, String?>>[];
      
      final subscription = ProfilePictureService.profilePictureUpdates.listen(
        (update) => streamUpdates.add(Map.from(update))
      );

      // Add cache entry
      ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
      
      // Wait for stream update
      await Future.delayed(Duration(milliseconds: 10));

      // Should have received broadcast
      expect(streamUpdates.isNotEmpty, isTrue);
      final lastUpdate = streamUpdates.last;
      expect(lastUpdate[userId], equals(imageUrl));

      await subscription.cancel();
    });

    test('should handle memory management during background refresh', () {
      // Add many cache entries to trigger memory management
      for (int i = 0; i < 110; i++) {
        ProfilePictureService.updateProfilePictureGlobally(
          'user$i', 
          'https://example.com/profile$i.jpg'
        );
      }

      // Verify memory management occurred
      final stats = ProfilePictureService.getCacheStatistics();
      expect(stats['totalEntries'], lessThanOrEqualTo(100));
    });
  });
}