import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/services/profile_picture_service.dart';

void main() {
  group('ProfilePictureService Stream Integration', () {
    setUp(() {
      // Clear any existing cache before each test
      ProfilePictureService.clearAllCache();
    });

    tearDown(() {
      // Clean up after each test
      ProfilePictureService.clearAllCache();
    });

    test('should receive stream updates when profile pictures are updated', () async {
      const userId1 = 'user123';
      const userId2 = 'user456';
      const imageUrl1 = 'https://example.com/profile1.jpg';
      const imageUrl2 = 'https://example.com/profile2.jpg';

      // Create a list to collect stream events
      final List<Map<String, String?>> streamEvents = [];
      
      // Listen to the stream
      final subscription = ProfilePictureService.profilePictureUpdates.listen((cache) {
        streamEvents.add(Map.from(cache));
      });

      // Wait a bit to ensure subscription is active
      await Future.delayed(Duration(milliseconds: 10));

      // Update first profile picture
      ProfilePictureService.updateProfilePictureGlobally(userId1, imageUrl1);
      
      // Wait for stream event
      await Future.delayed(Duration(milliseconds: 10));

      // Update second profile picture
      ProfilePictureService.updateProfilePictureGlobally(userId2, imageUrl2);
      
      // Wait for stream event
      await Future.delayed(Duration(milliseconds: 10));

      // Clear cache for first user
      ProfilePictureService.clearCacheForUser(userId1);
      
      // Wait for stream event
      await Future.delayed(Duration(milliseconds: 10));

      // Cancel subscription
      await subscription.cancel();

      // Verify we received the expected stream events
      expect(streamEvents.length, greaterThanOrEqualTo(3));
      
      // First event should have user1
      expect(streamEvents[0][userId1], equals(imageUrl1));
      
      // Second event should have both users
      expect(streamEvents[1][userId1], equals(imageUrl1));
      expect(streamEvents[1][userId2], equals(imageUrl2));
      
      // Third event should only have user2 (user1 was cleared)
      expect(streamEvents[2].containsKey(userId1), isFalse);
      expect(streamEvents[2][userId2], equals(imageUrl2));
    });

    test('should handle multiple listeners correctly', () async {
      const userId = 'user123';
      const imageUrl = 'https://example.com/profile.jpg';

      // Create multiple listeners
      final List<Map<String, String?>> listener1Events = [];
      final List<Map<String, String?>> listener2Events = [];
      
      final subscription1 = ProfilePictureService.profilePictureUpdates.listen((cache) {
        listener1Events.add(Map.from(cache));
      });
      
      final subscription2 = ProfilePictureService.profilePictureUpdates.listen((cache) {
        listener2Events.add(Map.from(cache));
      });

      // Wait a bit to ensure subscriptions are active
      await Future.delayed(Duration(milliseconds: 10));

      // Update profile picture
      ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
      
      // Wait for stream events
      await Future.delayed(Duration(milliseconds: 10));

      // Cancel subscriptions
      await subscription1.cancel();
      await subscription2.cancel();

      // Both listeners should have received the same event
      expect(listener1Events.length, equals(1));
      expect(listener2Events.length, equals(1));
      expect(listener1Events[0][userId], equals(imageUrl));
      expect(listener2Events[0][userId], equals(imageUrl));
    });

    test('should handle cache expiration correctly', () {
      const userId = 'user123';
      const imageUrl = 'https://example.com/profile.jpg';

      // Update profile picture
      ProfilePictureService.updateProfilePictureGlobally(userId, imageUrl);
      
      // Verify it's cached
      expect(ProfilePictureService.getProfilePictureFromCache(userId), equals(imageUrl));
      
      // Clear the specific user cache
      ProfilePictureService.clearCacheForUser(userId);
      
      // Verify cache is cleared
      expect(ProfilePictureService.getProfilePictureFromCache(userId), isNull);
    });
  });
}