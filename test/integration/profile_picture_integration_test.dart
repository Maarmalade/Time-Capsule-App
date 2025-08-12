import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/profile_picture_widget.dart';
import 'package:time_capsule/models/user_profile.dart';

void main() {
  group('Profile Picture Integration', () {
    testWidgets('ProfilePictureWidget integrates correctly with different themes', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ProfilePictureWidget(
              userProfile: userProfile,
              size: 40.0,
              showBorder: true,
            ),
          ),
        ),
      );

      expect(find.byType(ProfilePictureWidget), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ProfilePictureWidget(
              userProfile: userProfile,
              size: 40.0,
              showBorder: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('ProfilePictureWidget handles different sizes correctly', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test different sizes
      for (final size in [24.0, 32.0, 48.0, 64.0, 120.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfilePictureWidget(
                userProfile: userProfile,
                size: size,
              ),
            ),
          ),
        );

        expect(find.byType(ProfilePictureWidget), findsOneWidget);
        expect(find.byType(CircleAvatar), findsOneWidget);
      }
    });

    testWidgets('ProfilePictureWidget handles various username formats', (WidgetTester tester) async {
      final testCases = [
        ('john_doe', 'JD'),
        ('alice', 'A'),
        ('user123', 'U'),
        ('test_user_name', 'TU'),
        ('a', 'A'),
        ('', ''), // Empty username should show icon
      ];

      for (final testCase in testCases) {
        final username = testCase.$1;
        final expectedInitials = testCase.$2;

        final userProfile = UserProfile(
          id: 'test-id',
          email: 'test@example.com',
          username: username,
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

        if (expectedInitials.isNotEmpty) {
          expect(find.text(expectedInitials), findsOneWidget);
        } else {
          expect(find.byIcon(Icons.person), findsOneWidget);
        }
      }
    });

    testWidgets('ProfilePictureIcon responds to tap events', (WidgetTester tester) async {
      bool tapped = false;
      final userProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePictureIcon(
              userProfile: userProfile,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProfilePictureIcon));
      expect(tapped, isTrue);
    });

    testWidgets('ProfilePictureWidget displays correctly in app bar context', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                ProfilePictureIcon(
                  userProfile: userProfile,
                  onTap: () {},
                ),
              ],
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );

      expect(find.byType(ProfilePictureIcon), findsOneWidget);
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });
  });
}