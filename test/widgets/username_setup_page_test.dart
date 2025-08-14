import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:time_capsule/pages/auth/username_setup_page.dart';
import 'package:time_capsule/services/user_profile_service.dart';

// Generate mocks
@GenerateMocks([UserProfileService])
import 'username_setup_page_test.mocks.dart';

void main() {
  group('UsernameSetupPage', () {
    late MockUserProfileService mockUserProfileService;

    setUp(() {
      mockUserProfileService = MockUserProfileService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<UserProfileService>.value(
          value: mockUserProfileService,
          child: const UsernameSetupPage(),
        ),
      );
    }

    testWidgets('should display username input field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
    });

    testWidgets('should display create button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Create Username'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show validation error for empty username', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to submit with empty username
      await tester.tap(find.text('Create Username'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('should show validation error for short username', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter short username
      await tester.enterText(find.byType(TextFormField), 'ab');
      await tester.tap(find.text('Create Username'));
      await tester.pump();

      expect(find.text('Username must be at least 3 characters long'), findsOneWidget);
    });

    testWidgets('should show validation error for long username', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter long username
      await tester.enterText(find.byType(TextFormField), 'a' * 21);
      await tester.tap(find.text('Create Username'));
      await tester.pump();

      expect(find.text('Username must be no more than 20 characters long'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid characters', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter username with invalid characters
      await tester.enterText(find.byType(TextFormField), 'user@name');
      await tester.tap(find.text('Create Username'));
      await tester.pump();

      expect(find.text('Username can only contain letters, numbers, and underscores'), findsOneWidget);
    });

    testWidgets('should show loading indicator during username creation', (WidgetTester tester) async {
      when(mockUserProfileService.createUserProfile(any, any, any))
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpWidget(createTestWidget());

      // Enter valid username
      await tester.enterText(find.byType(TextFormField), 'validusername');
      await tester.tap(find.text('Create Username'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when username is taken', (WidgetTester tester) async {
      when(mockUserProfileService.createUserProfile(any, any, any))
          .thenThrow(Exception('Username already taken. Please try another.'));

      await tester.pumpWidget(createTestWidget());

      // Enter valid username
      await tester.enterText(find.byType(TextFormField), 'takenusername');
      await tester.tap(find.text('Create Username'));
      await tester.pumpAndSettle();

      expect(find.text('Username already taken. Please try another.'), findsOneWidget);
    });

    testWidgets('should trim whitespace from username', (WidgetTester tester) async {
      when(mockUserProfileService.createUserProfile(any, any, any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(createTestWidget());

      // Enter username with whitespace
      await tester.enterText(find.byType(TextFormField), '  validusername  ');
      await tester.tap(find.text('Create Username'));
      await tester.pumpAndSettle();

      verify(mockUserProfileService.createUserProfile(any, 'validusername', any)).called(1);
    });

    testWidgets('should show availability checking indicator', (WidgetTester tester) async {
      when(mockUserProfileService.isUsernameAvailable(any))
          .thenAnswer((_) async => Future.delayed(const Duration(milliseconds: 500), () => true));

      await tester.pumpWidget(createTestWidget());

      // Enter username to trigger availability check
      await tester.enterText(find.byType(TextFormField), 'checkusername');
      await tester.pump(const Duration(milliseconds: 300)); // Wait for debounce

      // Should show checking indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show username available indicator', (WidgetTester tester) async {
      when(mockUserProfileService.isUsernameAvailable(any))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget());

      // Enter username
      await tester.enterText(find.byType(TextFormField), 'availableusername');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Username available'), findsOneWidget);
    });

    testWidgets('should show username taken indicator', (WidgetTester tester) async {
      when(mockUserProfileService.isUsernameAvailable(any))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());

      // Enter username
      await tester.enterText(find.byType(TextFormField), 'takenusername');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Username taken'), findsOneWidget);
    });

    testWidgets('should disable create button when username is taken', (WidgetTester tester) async {
      when(mockUserProfileService.isUsernameAvailable(any))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());

      // Enter taken username
      await tester.enterText(find.byType(TextFormField), 'takenusername');
      await tester.pumpAndSettle();

      // Button should be disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should enable create button when username is available', (WidgetTester tester) async {
      when(mockUserProfileService.isUsernameAvailable(any))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget());

      // Enter available username
      await tester.enterText(find.byType(TextFormField), 'availableusername');
      await tester.pumpAndSettle();

      // Button should be enabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });
}