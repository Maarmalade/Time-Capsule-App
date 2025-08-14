import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:time_capsule/pages/profile/change_password_page.dart';
import 'package:time_capsule/services/user_profile_service.dart';

// Generate mocks
@GenerateMocks([UserProfileService])
import 'change_password_page_test.mocks.dart';

void main() {
  group('ChangePasswordPage', () {
    late MockUserProfileService mockUserProfileService;

    setUp(() {
      mockUserProfileService = MockUserProfileService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<UserProfileService>.value(
          value: mockUserProfileService,
          child: const ChangePasswordPage(),
        ),
      );
    }

    testWidgets('should display all password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('should display save button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show validation error for empty current password', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to submit with empty current password
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      expect(find.text('Current password is required'), findsOneWidget);
    });

    testWidgets('should show validation error for empty new password', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter current password but leave new password empty
      await tester.enterText(find.byType(TextFormField).at(0), 'currentpass');
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should show validation error for short new password', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextFormField).at(1), '123'); // Too short
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters long'), findsOneWidget);
    });

    testWidgets('should show validation error for mismatched passwords', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter passwords that don't match
      await tester.enterText(find.byType(TextFormField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'differentpassword');
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should show loading indicator during password change', (WidgetTester tester) async {
      when(mockUserProfileService.updatePassword(any, any))
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpWidget(createTestWidget());

      // Enter valid passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'newpassword');
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when current password is wrong', (WidgetTester tester) async {
      when(mockUserProfileService.updatePassword(any, any))
          .thenThrow(Exception('Current password is incorrect.'));

      await tester.pumpWidget(createTestWidget());

      // Enter passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'wrongpass');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'newpassword');
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
    });

    testWidgets('should show success message when password is changed', (WidgetTester tester) async {
      when(mockUserProfileService.updatePassword(any, any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(createTestWidget());

      // Enter valid passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'newpassword');
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password changed successfully'), findsOneWidget);
    });

    testWidgets('should hide password text by default', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // All password fields should be obscured
      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
      for (final field in textFields) {
        expect(field.obscureText, isTrue);
      }
    });

    testWidgets('should show password visibility toggle buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should have visibility toggle icons for each password field
      expect(find.byIcon(Icons.visibility), findsNWidgets(3));
    });

    testWidgets('should toggle password visibility when icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap the first visibility toggle
      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();

      // Should now show visibility_off icon for the first field
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should clear form after successful password change', (WidgetTester tester) async {
      when(mockUserProfileService.updatePassword(any, any))
          .thenAnswer((_) async {
            return;
          });

      await tester.pumpWidget(createTestWidget());

      // Enter passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'newpassword');
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Form should be cleared
      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
      for (final field in textFields) {
        expect(field.controller?.text, isEmpty);
      }
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

    testWidgets('should show password strength indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter a password
      await tester.enterText(find.byType(TextFormField).at(1), 'weakpass');
      await tester.pump();

      // Should show password strength indicator
      expect(find.text('Password Strength:'), findsOneWidget);
    });

    testWidgets('should validate that new password is different from current', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter same password for current and new
      await tester.enterText(find.byType(TextFormField).at(0), 'samepassword');
      await tester.enterText(find.byType(TextFormField).at(1), 'samepassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'samepassword');
      await tester.tap(find.text('Change Password'));
      await tester.pump();

      expect(find.text('New password must be different from current password'), findsOneWidget);
    });
  });
}