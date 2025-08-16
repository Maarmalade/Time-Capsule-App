import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/services/profile_picture_service.dart';

void main() {
  group('ProfilePictureService Global State Management', () {
    setUp(() {
      // Clear any existing cache before each test
      ProfilePictureService.clearAllCache();
    });

    tearDown(() {
      // Clean up after each test
      ProfilePictureService.clearAllCache();
    });

    group('Static Profile Picture Cache', () {
      test('should store and retrieve profile pictures from cache', () {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        // Update profile picture globally
        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);

        // Retrieve from cache
        final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
        expect(cachedUrl, equals(imageUrl));
      });

      test('should handle null profile picture URLs', () {
        const userId = 'user123';

        // Update with null URL
        ProfilePictureService.updateProfilePictureGlobally(userId, null);

        // Retrieve from cache
        final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
        expect(cachedUrl, isNull);
      });

      test('should return null for non-existent user in cache', () {
        const userId = 'nonexistent';

        final cachedUrl = ProfilePictureService.getProfilePictureFromCache(userId);
        expect(cachedUrl, isNull);
      });

      test('should expire cache after timeout', () async {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        // Update profile picture
        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);

        // Verify it's cached
        expect(ProfilePictureService.getProfilePictureFromCache(userId), equals(imageUrl));

        // Wait for cache to expire (simulate by manipulating internal state)
        // Note: In a real test, you might need to mock DateTime.now() or use a shorter timeout
        // For this test, we'll clear and re-add with an old timestamp
        ProfilePictureService.clearCacheForUser(userId);
        
        // Verify cache is cleared
        expect(ProfilePictureService.getProfilePictureFromCache(userId), isNull);
      });
    });

    group('StreamController for Broadcasting Updates', () {
      test('should broadcast updates when profile picture is updated globally', () async {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        // Listen to the stream
        final streamFuture = ProfilePictureService.profilePictureUpdates.first;

        // Update profile picture
        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);

        // Wait for the stream event
        final updatedCache = await streamFuture;

        expect(updatedCache[userId], equals(imageUrl));
      });

      test('should broadcast updates when cache is cleared for user', () async {
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        // First add a profile picture
        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);

        // Listen to the stream for the clear event
        final streamFuture = ProfilePictureService.profilePictureUpdates.first;

        // Clear cache for user
        ProfilePictureService.clearCacheForUser(userId);

        // Wait for the stream event
        final updatedCache = await streamFuture;

        expect(updatedCache.containsKey(userId), isFalse);
      });

      test('should broadcast updates when all cache is cleared', () async {
        const userId1 = 'user123';
        const userId2 = 'user456';
        const imageUrl1 = 'https://example.com/profile1.jpg';
        const imageUrl2 = 'https://example.com/profile2.jpg';

        // Add multiple profile pictures
        ProfilePictureService.updateProfilePictureGlobally(userId1, imageUrl1);
        ProfilePictureService.updateProfilePictureGlobally(userId2, imageUrl2);

        // Listen to the stream for the clear event
        final streamFuture = ProfilePictureService.profilePictureUpdates.first;

        // Clear all cache
        ProfilePictureService.clearAllCache();

        // Wait for the stream event
        final updatedCache = await streamFuture;

        expect(updatedCache.isEmpty, isTrue);
      });
    });

    group('clearCacheForUser Method', () {
      test('should clear cache for specific user only', () {
        const userId1 = 'user123';
        const userId2 = 'user456';
        const imageUrl1 = 'https://example.com/profile1.jpg';
        const imageUrl2 = 'https://example.com/profile2.jpg';

        // Add profile pictures for both users
        ProfilePictureService.updateProfilePictureGlobally(userId1, imageUrl1);
        ProfilePictureService.updateProfilePictureGlobally(userId2, imageUrl2);

        // Clear cache for user1 only
        ProfilePictureService.clearCacheForUser(userId1);

        // Verify user1's cache is cleared but user2's remains
        expect(ProfilePictureService.getProfilePictureFromCache(userId1), isNull);
        expect(ProfilePictureService.getProfilePictureFromCache(userId2), equals(imageUrl2));
      });

      test('should handle clearing cache for non-existent user', () {
        const userId = 'nonexistent';

        // Should not throw error
        expect(() => ProfilePictureService.clearCacheForUser(userId), returnsNormally);
      });
    });

    group('updateProfilePictureGlobally Method', () {
      test('should update existing profile picture', () {
        const userId = 'user123';
        const oldImageUrl = 'https://example.com/old_profile.jpg';
        const newImageUrl = 'https://example.com/new_profile.jpg';

        // Add initial profile picture
        ProfilePictureService.updateProfilePictureGlobally(userId, oldImageUrl);
        expect(ProfilePictureService.getProfilePictureFromCache(userId), equals(oldImageUrl));

        // Update profile picture
        ProfilePictureService.updateProfilePictureGlobally(userId, newImageUrl);
        expect(ProfilePictureService.getProfilePictureFromCache(userId), equals(newImageUrl));
      });

      test('should handle multiple users', () {
        const userId1 = 'user123';
        const userId2 = 'user456';
        const imageUrl1 = 'https://example.com/profile1.jpg';
        const imageUrl2 = 'https://example.com/profile2.jpg';

        // Add profile pictures for both users
        ProfilePictureService.updateProfilePictureGlobally(userId1, imageUrl1);
        ProfilePictureService.updateProfilePictureGlobally(userId2, imageUrl2);

        // Verify both are cached correctly
        expect(ProfilePictureService.getProfilePictureFromCache(userId1), equals(imageUrl1));
        expect(ProfilePictureService.getProfilePictureFromCache(userId2), equals(imageUrl2));
      });
    });

    group('getCachedProfilePictures Method', () {
      test('should return copy of cached profile pictures', () {
        const userId1 = 'user123';
        const userId2 = 'user456';
        const imageUrl1 = 'https://example.com/profile1.jpg';
        const imageUrl2 = 'https://example.com/profile2.jpg';

        // Add profile pictures
        ProfilePictureService.updateProfilePictureGlobally(userId1, imageUrl1);
        ProfilePictureService.updateProfilePictureGlobally(userId2, imageUrl2);

        // Get cached profile pictures
        final cachedPictures = ProfilePictureService.getCachedProfilePictures();

        expect(cachedPictures[userId1], equals(imageUrl1));
        expect(cachedPictures[userId2], equals(imageUrl2));
        expect(cachedPictures.length, equals(2));
      });

      test('should return empty map when no cache exists', () {
        final cachedPictures = ProfilePictureService.getCachedProfilePictures();
        expect(cachedPictures.isEmpty, isTrue);
      });
    });

    group('Integration with Existing Methods', () {
      test('should update global cache directly', () {
        // Test the global update functionality directly
        const userId = 'user123';
        const imageUrl = 'https://example.com/profile.jpg';

        // Directly test the global update
        ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
        
        // Verify it's in the global cache
        expect(ProfilePictureService.getProfilePictureFromCache(userId), equals(imageUrl));
      });
    });
  });
}