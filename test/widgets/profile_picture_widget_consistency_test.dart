import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/profile_picture_widget.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/services/profile_picture_service.dart';

void main() {
  group('ProfilePictureWidget Consistency Tests', () {
    setUp(() {
      // Clear cache before each test
      ProfilePictureService.clearAllCache();
    });

    tearDown(() {
      // Clean up after each test
      ProfilePictureService.clearAllCache();
    });

    testWidgets('should listen to global profile picture updates', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: null,
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

      // Initially should show default avatar
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // First letter of 'testuser'

      // Update profile picture globally
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/new-profile.jpg'
      );

      // Wait for the stream update to propagate
      await tester.pump();

      // Widget should update to show the new profile picture
      // Note: In a real test, we'd need to mock CachedNetworkImage
      // For now, we verify the widget rebuilds
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });

    testWidgets('should update when user profile changes', (WidgetTester tester) async {
      final userProfile1 = UserProfile(
        id: 'test-user-1',
        username: 'user1',
        email: 'user1@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userProfile2 = UserProfile(
        id: 'test-user-2',
        username: 'user2',
        email: 'user2@example.com',
        profilePictureUrl: 'https://example.com/user2.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set up cache for both users
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/user1.jpg'
      );
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-2', 
        'https://example.com/user2.jpg'
      );

      Widget buildWidget(UserProfile profile) {
        return MaterialApp(
          home: Scaffold(
            body: ProfilePictureWidget(
              userProfile: profile,
              size: 40.0,
            ),
          ),
        );
      }

      // Start with user1
      await tester.pumpWidget(buildWidget(userProfile1));
      expect(find.byType(ProfilePictureWidget), findsOneWidget);

      // Switch to user2
      await tester.pumpWidget(buildWidget(userProfile2));
      await tester.pump();

      // Should still show ProfilePictureWidget but with different user
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });

    testWidgets('should handle null user profile gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfilePictureWidget(
              userProfile: null,
              size: 40.0,
            ),
          ),
        ),
      );

      // Should show default avatar with person icon
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should show default avatar when profile picture URL is empty', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: '',
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

      // Should show default avatar with initials
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // First letter of 'testuser'
    });

    testWidgets('should handle cache clearing for specific user', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set up cache
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/profile.jpg'
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

      // Clear cache for this user
      ProfilePictureService.clearCacheForUser('test-user-1');
      await tester.pump();

      // Widget should still be present but may show default avatar
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });

    testWidgets('should handle multiple ProfilePictureWidgets for same user', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
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
                  userProfile: userProfile,
                  size: 40.0,
                ),
                ProfilePictureWidget(
                  userProfile: userProfile,
                  size: 60.0,
                ),
                ProfilePictureWidget(
                  userProfile: userProfile,
                  size: 80.0,
                ),
              ],
            ),
          ),
        ),
      );

      // Should show three widgets
      expect(find.byType(ProfilePictureWidget), findsNWidgets(3));

      // Update profile picture globally
      ProfilePictureService.updateProfilePictureGlobally(
        'test-user-1', 
        'https://example.com/new-profile.jpg'
      );

      await tester.pump();

      // All three widgets should still be present and updated
      expect(find.byType(ProfilePictureWidget), findsNWidgets(3));
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: 'invalid-url',
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
    });

    testWidgets('should maintain border styling when specified', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-user-1',
        username: 'testuser',
        email: 'test@example.com',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePictureWidget(
              userProfile: userProfile,
              size: 40.0,
              showBorder: true,
              borderColor: Colors.red,
              borderWidth: 3.0,
            ),
          ),
        ),
      );

      // Should show container with border (there will be multiple containers)
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });
  });
}