import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/services/profile_picture_service.dart';

void main() {
  group('ProfilePictureService Caching and Refresh Logic', () {
    setUp(() {
      // Reset service state before each test
      ProfilePictureService.reset();
      ProfilePictureService.setBackgroundRefreshEnabled(true);
    });

    tearDown(() {
      ProfilePictureService.reset();
    });

    group('Intelligent Caching', () {
      test('should cache profile picture with metadata', () {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);

        final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
        expect(cachedUrl, equals(imageUrl));
      });

      test('should track access count and last accessed time', () {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);

        // Access multiple times
        ProfilePictureService.getProfilePictureFromCache(userId);
        ProfilePictureService.getProfilePictureFromCache(userId);
        ProfilePictureService.getProfilePictureFromCache(userId);

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['totalEntries'], equals(1));
        expect(stats['totalAccessCount'], greaterThan(1));
      });

      test('should return cached value for expired entries while scheduling refresh', () {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        
        // Invalidate cache to simulate expiration
        ProfilePictureService.invalidateCacheForUser(userId);

        final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
        expect(cachedUrl, equals(imageUrl)); // Should still return cached value

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['refreshQueueSize'], greaterThan(0)); // Should be scheduled for refresh
      });

      test('should schedule background refresh for stale entries', () async {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        
        // Simulate stale entry by invalidating
        ProfilePictureService.invalidateCacheForUser(userId);
        
        ProfilePictureService.getProfilePictureFromCache(userId);

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['refreshQueueSize'], greaterThan(0));
      });
    });

    group('Memory Management', () {
      test('should perform memory management when cache exceeds max size', () {
        // Add entries beyond max cache size (100)
        for (int i = 0; i < 120; i++) {
          ProfilePictureService.updateProfilePictureGlobally(
            'user$i', 
            'https://example.com/profile$i.jpg'
          );
        }

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['totalEntries'], lessThanOrEqualTo(100));
      });

      test('should remove least recently used entries during memory management', () {
        // Add multiple entries
        for (int i = 0; i < 10; i++) {
          ProfilePictureService.updateProfilePictureGlobally(
            'user$i', 
            'https://example.com/profile$i.jpg'
          );
        }

        // Access some entries to make them more recently used
        ProfilePictureService.getProfilePictureFromCache('user5');
        ProfilePictureService.getProfilePictureFromCache('user6');
        ProfilePictureService.getProfilePictureFromCache('user7');

        // Force memory management by adding many more entries
        for (int i = 10; i < 120; i++) {
          ProfilePictureService.updateProfilePictureGlobally(
            'user$i', 
            'https://example.com/profile$i.jpg'
          );
        }

        // Recently accessed entries should still be in cache
        expect(ProfilePictureService.getProfilePictureFromCache('user5'), isNotNull);
        expect(ProfilePictureService.getProfilePictureFromCache('user6'), isNotNull);
        expect(ProfilePictureService.getProfilePictureFromCache('user7'), isNotNull);
      });
    });

    group('Cache Invalidation', () {
      test('should invalidate cache for specific user', () {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        ProfilePictureService.invalidateCacheForUser(userId);

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['expiredEntries'], greaterThan(0));
        expect(stats['refreshQueueSize'], greaterThan(0));
      });

      test('should clear cache for specific user', () {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        ProfilePictureService.clearCacheForUser(userId);

        final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
        expect(cachedUrl, isNull);
      });

      test('should clear all cache', () {
        // Add multiple entries
        for (int i = 0; i < 5; i++) {
          ProfilePictureService.updateProfilePictureGlobally(
            'user$i', 
            'https://example.com/profile$i.jpg'
          );
        }

        ProfilePictureService.clearAllCache();

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['totalEntries'], equals(0));
        expect(stats['refreshQueueSize'], equals(0));
      });
    });

    group('Background Refresh', () {
      test('should enable and disable background refresh', () {
        ProfilePictureService.setBackgroundRefreshEnabled(false);
        
        var stats = ProfilePictureService.getCacheStatistics();
        expect(stats['backgroundRefreshEnabled'], isFalse);

        ProfilePictureService.setBackgroundRefreshEnabled(true);
        
        stats = ProfilePictureService.getCacheStatistics();
        expect(stats['backgroundRefreshEnabled'], isTrue);
      });

      test('should not schedule refresh when background refresh is disabled', () {
        ProfilePictureService.setBackgroundRefreshEnabled(false);
        
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        ProfilePictureService.invalidateCacheForUser(userId);
        ProfilePictureService.getProfilePictureFromCache(userId);

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['refreshQueueSize'], equals(0));
      });

      test('should not duplicate entries in refresh queue', () {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        ProfilePictureService.invalidateCacheForUser(userId);
        
        // Access multiple times to trigger multiple refresh attempts
        ProfilePictureService.getProfilePictureFromCache(userId);
        ProfilePictureService.getProfilePictureFromCache(userId);
        ProfilePictureService.getProfilePictureFromCache(userId);

        final stats = ProfilePictureService.getCacheStatistics();
        expect(stats['refreshQueueSize'], equals(1)); // Should only have one entry
      });
    });

    group('Cache Statistics', () {
      test('should provide accurate cache statistics', () {
        // Add some entries
        for (int i = 0; i < 5; i++) {
          ProfilePictureService.updateProfilePictureGlobally(
            'user$i', 
            'https://example.com/profile$i.jpg'
          );
        }

        // Access some entries
        ProfilePictureService.getProfilePictureFromCache('user0');
        ProfilePictureService.getProfilePictureFromCache('user1');

        // Invalidate some entries
        ProfilePictureService.invalidateCacheForUser('user2');
        ProfilePictureService.invalidateCacheForUser('user3');

        final stats = ProfilePictureService.getCacheStatistics();
        
        expect(stats['totalEntries'], equals(5));
        expect(stats['expiredEntries'], equals(2));
        expect(stats['totalAccessCount'], greaterThan(0));
        expect(stats['refreshQueueSize'], equals(2));
        expect(stats['backgroundRefreshEnabled'], isTrue);
      });
    });

    group('Stream Broadcasting', () {
      test('should broadcast cache updates', () async {
        final streamUpdates = <Map<String, String?>>[];
        
        final subscription = ProfilePictureService.profilePictureUpdates.listen(
          (update) => streamUpdates.add(update)
        );

        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        
        // Wait for stream update
        await Future.delayed(Duration(milliseconds: 10));

        expect(streamUpdates.isNotEmpty, isTrue);
        expect(streamUpdates.last[userId], equals(imageUrl));

        await subscription.cancel();
      });

      test('should broadcast cache clearing', () async {
        final streamUpdates = <Map<String, String?>>[];
        
        final subscription = ProfilePictureService.profilePictureUpdates.listen(
          (update) => streamUpdates.add(update)
        );

        // Add entry
        ProfilePictureService.updateProfilePictureGlobally('user123', 'url');
        await Future.delayed(Duration(milliseconds: 10));

        // Clear cache
        ProfilePictureService.clearAllCache();
        await Future.delayed(Duration(milliseconds: 10));

        expect(streamUpdates.last.isEmpty, isTrue);

        await subscription.cancel();
      });
    });
  });
}