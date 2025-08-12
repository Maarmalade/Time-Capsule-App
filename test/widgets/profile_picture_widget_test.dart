import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/profile_picture_widget.dart';
import 'package:time_capsule/models/user_profile.dart';

void main() {
  group('ProfilePictureWidget', () {
    testWidgets('displays default avatar when no profile picture', (WidgetTester tester) async {
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
            body: ProfilePictureWidget(
              userProfile: userProfile,
              size: 40.0,
            ),
          ),
        ),
      );

      // Should display a CircleAvatar with initials
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // First letter of username
    });

    testWidgets('displays default icon when no username', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: '',
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

      // Should display a CircleAvatar with person icon
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays default icon when userProfile is null', (WidgetTester tester) async {
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

      // Should display a CircleAvatar with person icon
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays border when showBorder is true', (WidgetTester tester) async {
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
            body: ProfilePictureWidget(
              userProfile: userProfile,
              size: 40.0,
              showBorder: true,
            ),
          ),
        ),
      );

      // Should display a Container with border decoration
      expect(find.byType(Container), findsWidgets);
      
      // Find the container with border decoration
      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.border != null;
        }
        return false;
      });
      
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('generates correct initials for username with underscore', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: 'john_doe',
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

      // Should display initials "JD" for "john_doe"
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('generates correct initials for simple username', (WidgetTester tester) async {
      final userProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: 'alice',
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

      // Should display initial "A" for "alice"
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('ProfilePictureIcon', () {
    testWidgets('displays profile picture with correct size', (WidgetTester tester) async {
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
            ),
          ),
        ),
      );

      // Should display a ProfilePictureWidget
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
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
  });
}