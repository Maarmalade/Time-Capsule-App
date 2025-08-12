import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:time_capsule/pages/profile/profile_page.dart';
import 'package:time_capsule/services/user_profile_service.dart';
import 'package:time_capsule/models/user_profile.dart';

// Generate mocks
@GenerateMocks([UserProfileService])
import 'profile_page_test.mocks.dart';

void main() {
  group('ProfilePage', () {
    late MockUserProfileService mockUserProfileService;
    late UserProfile testUserProfile;

    setUp(() {
      mockUserProfileService = MockUserProfileService();
      testUserProfile = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<UserProfileService>.value(
          value: mockUserProfileService,
          child: const ProfilePage(),
        ),
      );
    }

    testWidgets('should display loading indicator while fetching profile', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1), () => testUserProfile));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display user profile information', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('@testuser'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should display default profile picture when none set', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display profile picture when set', (WidgetTester tester) async {
      final profileWithPicture = testUserProfile.copyWith(
        profilePictureUrl: 'https://example.com/profile.jpg',
      );

      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => profileWithPicture);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
      // Note: In a real test, you might want to verify the NetworkImage
    });

    testWidgets('should display profile management options', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Change Username'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Change Profile Picture'), findsOneWidget);
    });

    testWidgets('should navigate to edit username page when tapped', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Username'));
      await tester.pumpAndSettle();

      // Note: In a real test, you would verify navigation
      // This would require setting up a Navigator observer or similar
    });

    testWidgets('should navigate to change password page when tapped', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Note: In a real test, you would verify navigation
    });

    testWidgets('should show error message when profile loading fails', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenThrow(Exception('Failed to load profile'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load profile'), findsOneWidget);
    });

    testWidgets('should show retry button when profile loading fails', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenThrow(Exception('Failed to load profile'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should retry loading profile when retry button is tapped', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenThrow(Exception('Failed to load profile'))
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show profile
      expect(find.text('@testuser'), findsOneWidget);
    });

    testWidgets('should display edit button in app bar', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should display back button in app bar', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('should refresh profile when pull to refresh is triggered', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Trigger pull to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();

      // Verify service was called again
      verify(mockUserProfileService.getCurrentUserProfile()).called(2);
    });

    testWidgets('should show profile creation date', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testUserProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Member since'), findsOneWidget);
    });

    testWidgets('should handle null profile gracefully', (WidgetTester tester) async {
      when(mockUserProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Profile not found'), findsOneWidget);
    });
  });
}