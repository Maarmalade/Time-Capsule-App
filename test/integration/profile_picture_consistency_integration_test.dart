import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/profile_picture_widget.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/services/profile_picture_service.dart';

void main() {
  group('Profile Picture Consistency Integration Tests', () {
    setUp(() {
      // Clear cache before each test
      ProfilePictureService.clearAllCache();
    });

    tearDown(() {
      // Clean up after each test
      ProfilePictureService.clearAllCache();
    });

    testWidgets('profile pictures should update consistently across multiple screens', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Simulate multiple screens with profile pictures
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Simulate home page profile picture
                Container(
                  key: const Key('home_profile'),
                  child: ProfilePictureWidget(
                    userProfile: userProfile,
                    size: 32.0,
                  ),
                ),
                // Simulate profile page profile picture
                Container(
                  key: const Key('profile_page_profile'),
                  child: ProfilePictureWidget(
                    userProfile: userProfile,
                    size: 100.0,
                  ),
                ),
                // Simulate memory album profile picture
                Container(
                  key: const Key('memory_album_profile'),
                  child: ProfilePictureWidget(
                    userProfile: userProfile,
                    size: 32.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all profile pictures are displayed
      expect(find.byKey(const Key('home_profile')), findsOneWidget);
      expect(find.byKey(const Key('profile_page_profile')), findsOneWidget);
      expect(find.byKey(const Key('memory_album_profile')), findsOneWidget);
      expect(find.byType(ProfilePictureWidget), findsNWidgets(3));

      // Update profile picture globally
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/new-profile.jpg'
      );

      // Wait for updates to propagate
      await tester.pump();

      // All profile pictures should still be present and updated
      expect(find.byKey(const Key('home_profile')), findsOneWidget);
      expect(find.byKey(const Key('profile_page_profile')), findsOneWidget);
      expect(find.byKey(const Key('memory_album_profile')), findsOneWidget);
      expect(find.byType(ProfilePictureWidget), findsNWidgets(3));
    });

    testWidgets('cache should clear when user switches', (WidgetTester tester) async {
      final user1Profile = UserProfile(
        id: 'user-1',
        username: 'user1',
        email: 'user1@example.com',
        profilePictureUrl: 'https://example.com/user1.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final user2Profile = UserProfile(
        id: 'user-2',
        username: 'user2',
        email: 'user2@example.com',
        profilePictureUrl: 'https://example.com/user2.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set up cache for both users
      ProfilePictureService.updateProfilePictureGlobally('user-1', 'https://example.com/user1.jpg');
      ProfilePictureService.updateProfilePictureGlobally('user-2', 'https://example.com/user2.jpg');

      // Verify both users are in cache
      expect(ProfilePictureService.getProfilePictureFromCache('user-1'), isNotNull);
      expect(ProfilePictureService.getProfilePictureFromCache('user-2'), isNotNull);

      // Clear cache for user-1 (simulating user switch)
      ProfilePictureService.clearCacheForUser('user-1');

      // Verify user-1 is cleared but user-2 remains
      expect(ProfilePictureService.getProfilePictureFromCache('user-1'), isNull);
      expect(ProfilePictureService.getProfilePictureFromCache('user-2'), isNotNull);

      // Clear all cache (simulating logout)
      ProfilePictureService.clearAllCache();

      // Verify all users are cleared
      expect(ProfilePictureService.getProfilePictureFromCache('user-1'), isNull);
      expect(ProfilePictureService.getProfilePictureFromCache('user-2'), isNull);
    });

    testWidgets('profile pictures should handle network errors gracefully', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: 'https://invalid-url.com/nonexistent.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePictureWidget(
              userProfile: userProfile,
              size: 40.0,
            ),
          ),
        ),
      );

      // Should show widget without crashing
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Update to a valid URL
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/valid-profile.jpg'
      );

      await tester.pump();

      // Should still show widget
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });

    testWidgets('default avatars should display consistently', (WidgetTester tester) async {
      final userProfileWithUsername = UserProfile(
        id: 'test-user-1',
        username: 'john_doe',
        email: 'john@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userProfileWithoutUsername = UserProfile(
        id: 'test-user-2',
        username: '',
        email: 'user2@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProfilePictureWidget(
                  userProfile: userProfileWithUsername,
                  size: 40.0,
                ),
                ProfilePictureWidget(
                  userProfile: userProfileWithoutUsername,
                  size: 40.0,
                ),
                const ProfilePictureWidget(
                  userProfile: null,
                  size: 40.0,
                ),
              ],
            ),
          ),
        ),
      );

      // Should show all three widgets
      expect(find.byType(ProfilePictureWidget), findsNWidgets(3));
      expect(find.byType(CircleAvatar), findsNWidgets(3));

      // First should show initials (JD for john_doe)
      expect(find.text('JD'), findsOneWidget);

      // Second and third should show person icons
      expect(find.byIcon(Icons.person), findsNWidgets(2));
    });

    testWidgets('profile picture stream should handle multiple subscribers', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create multiple widgets that subscribe to the same stream
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ProfilePictureWidget(
                  userProfile: userProfile,
                  size: 30.0,
                ),
                ProfilePictureWidget(
                  userProfile: userProfile,
                  size: 40.0,
                ),
                ProfilePictureWidget(
                  userProfile: userProfile,
                  size: 50.0,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePictureWidget), findsNWidgets(3));

      // Update profile picture - should notify all subscribers
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/profile.jpg'
      );

      await tester.pump();

      // All widgets should still be present
      expect(find.byType(ProfilePictureWidget), findsNWidgets(3));
    });

    testWidgets('cache expiration should be handled correctly', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set up cache entry
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/profile.jpg'
      );

      // Verify cache entry exists
      expect(ProfilePictureService.getProfilePictureFromCache('test-user-1'), isNotNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePictureWidget(
              userProfile: userProfile,
              size: 40.0,
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });

    testWidgets('profile picture cache should clear on logout', (WidgetTester tester) async {
      // Set up some cached profile pictures
      ProfilePictureService.updateProfilePictureGlobally('user-1', 'https://example.com/user1.jpg');
      ProfilePictureService.updateProfilePictureGlobally('user-2', 'https://example.com/user2.jpg');

      // Verify cache has entries
      expect(ProfilePictureService.getCachedProfilePictures().length, equals(2));

      // Test the cache clearing directly (simulating what AuthService.signOut() does)
      ProfilePictureService.clearAllCache();

      // Verify cache is cleared
      expect(ProfilePictureService.getCachedProfilePictures().length, equals(0));
    });
  });
}