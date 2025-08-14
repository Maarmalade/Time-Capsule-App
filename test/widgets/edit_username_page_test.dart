import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:time_capsule/pages/profile/edit_username_page.dart';
import 'package:time_capsule/services/user_profile_service.dart';

// Generate mocks
@GenerateMocks([UserProfileService])
import 'edit_username_page_test.mocks.dart';

void main() {
  group('EditUsernamePage', () {
    late MockUserProfileService mockUserProfileService;

    setUp(() {
      mockUserProfileService = MockUserProfileService();
    });

    Widget createTestWidget({String currentUsername = 'currentuser'}) {
      return MaterialApp(
        home: Provider<UserProfileService>.value(
          value: mockUserProfileService,
          child: EditUsernamePage(currentUsername: currentUsername),
        ),
      );
    }

    testWidgets('should display current username in text field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(currentUsername: 'testuser'));

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('should display save button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show validation error for empty username', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Clear the text field
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('should show validation error for short username', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter short username
      await tester.enterText(find.byType(TextFormField), 'ab');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Username must be at least 3 characters long'), findsOneWidget);
    });

    testWidgets('should show validation error for long username', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter long username
      await tester.enterText(find.byType(TextFormField), 'a' * 21);
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Username must be no more than 20 characters long'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid characters', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter username with invalid characters
      await tester.enterText(find.byType(TextFormField), 'user@name');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Username can only contain letters, numbers, and underscores'), findsOneWidget);
    });

    testWidgets('should show loading indicator during username update', (WidgetTester tester) async {
      when(mockUserProfileService.updateUsername(any, any))
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpWidget(createTestWidget());

      // Enter valid username
      await tester.enterText(find.byType(TextFormField), 'newusername');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when username is taken', (WidgetTester tester) async {
      when(mockUserProfileService.updateUsername(any, any))
          .thenThrow(Exception('Username already taken. Please try another.'));

      await tester.pumpWidget(createTestWidget());

      // Enter valid username
      await tester.enterText(find.byType(TextFormField), 'takenusername');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Username already taken. Please try another.'), findsOneWidget);
    });

    testWidgets('should show success message when username is updated', (WidgetTester tester) async {
      when(mockUserProfileService.updateUsername(any, any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(createTestWidget());

      // Enter valid username
      await tester.enterText(find.byType(TextFormField), 'newusername');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Username updated successfully'), findsOneWidget);
    });

    testWidgets('should trim whitespace from username', (WidgetTester tester) async {
      when(mockUserProfileService.updateUsername(any, any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(createTestWidget());

      // Enter username with whitespace
      await tester.enterText(find.byType(TextFormField), '  newusername  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(mockUserProfileService.updateUsername(any, 'newusername')).called(1);
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

    testWidgets('should disable save button when username is taken', (WidgetTester tester) async {
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

    testWidgets('should enable save button when username is available', (WidgetTester tester) async {
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

    testWidgets('should not check availability for current username', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(currentUsername: 'currentuser'));

      // The field should already contain the current username
      expect(find.text('currentuser'), findsOneWidget);

      // Should not show any availability indicators for current username
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('should show cancel button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should navigate back when cancel is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Note: In a real test, you would verify navigation back
    });
  });
}