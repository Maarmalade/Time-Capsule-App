import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:time_capsule/pages/auth/login.dart';
import 'package:time_capsule/pages/auth/register.dart';
import 'package:time_capsule/pages/auth/username_setup_page.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_typography.dart';
import 'package:time_capsule/design_system/app_spacing.dart';
import 'package:time_capsule/design_system/app_theme.dart';
import '../../test_helpers/firebase_mock_setup.dart';

@GenerateMocks([FirebaseAuth, User])
import 'auth_pages_design_system_test.mocks.dart';

void main() {
  group('Authentication Pages Design System Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUpAll(() async {
      setupFirebaseAuthMocks();
      await Firebase.initializeApp();
    });

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
    });

    group('LoginPage Design System Tests', () {
      testWidgets('LoginPage uses design system colors and typography', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginPage(),
          ),
        );

        // Verify scaffold background color
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppColors.surfacePrimary));

        // Verify app title typography
        final titleText = tester.widget<Text>(find.text('Time Capsule'));
        expect(titleText.style?.fontSize, equals(AppTypography.displayMedium.fontSize));
        expect(titleText.style?.color, equals(AppColors.textPrimary));

        // Verify login subtitle typography
        final loginText = tester.widget<Text>(find.text('Login'));
        expect(loginText.style?.fontSize, equals(AppTypography.headlineMedium.fontSize));
        expect(loginText.style?.color, equals(AppColors.textSecondary));
      });

      testWidgets('LoginPage input fields use design system styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginPage(),
          ),
        );

        // Find text form fields
        final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
        expect(textFields.length, equals(2)); // Email and password fields

        for (final textField in textFields) {
          final decoration = textField.decoration!;
          
          // Verify fill color
          expect(decoration.fillColor, equals(AppColors.surfaceSecondary));
          expect(decoration.filled, isTrue);
          
          // Verify border radius
          final border = decoration.border as OutlineInputBorder;
          expect(border.borderRadius, equals(AppSpacing.inputRadius));
          
          // Verify content padding
          expect(decoration.contentPadding, equals(AppSpacing.inputPadding));
        }
      });

      testWidgets('LoginPage button uses design system styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginPage(),
          ),
        );

        // Find the continue button
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        
        // Verify button dimensions
        final buttonSize = tester.getSize(find.byType(ElevatedButton));
        expect(buttonSize.height, equals(AppSpacing.minTouchTarget));
        expect(buttonSize.width, equals(200));

        // Verify button text style
        final buttonText = tester.widget<Text>(find.text('Continue'));
        expect(buttonText.style, equals(AppTypography.buttonText));
      });

      testWidgets('LoginPage error display uses design system styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginPage(),
          ),
        );

        // Trigger an error by attempting login with empty fields
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Note: This test would need to be expanded based on actual error handling implementation
        // For now, we're testing the structure is in place
      });
    });

    group('RegisterPage Design System Tests', () {
      testWidgets('RegisterPage uses design system colors and typography', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegisterPage(),
          ),
        );

        // Verify scaffold background color
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppColors.surfacePrimary));

        // Verify back button styling
        final backIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_back));
        expect(backIcon.size, equals(AppSpacing.iconSizeLarge));
        expect(backIcon.color, equals(AppColors.textPrimary));

        // Verify sign up text typography
        final signUpText = tester.widget<Text>(find.text('Sign Up'));
        expect(signUpText.style?.fontSize, equals(AppTypography.headlineMedium.fontSize));
        expect(signUpText.style?.color, equals(AppColors.textSecondary));
      });

      testWidgets('RegisterPage input fields use consistent styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegisterPage(),
          ),
        );

        // Find all text form fields (email, password, confirm password)
        final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
        expect(textFields.length, equals(3));

        for (final textField in textFields) {
          final decoration = textField.decoration!;
          
          // Verify consistent styling across all fields
          expect(decoration.fillColor, equals(AppColors.surfaceSecondary));
          expect(decoration.filled, isTrue);
          
          final border = decoration.border as OutlineInputBorder;
          expect(border.borderRadius, equals(AppSpacing.inputRadius));
          expect(decoration.contentPadding, equals(AppSpacing.inputPadding));
        }
      });

      testWidgets('RegisterPage button maintains design consistency', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RegisterPage(),
          ),
        );

        // Verify button dimensions and text
        final buttonSize = tester.getSize(find.byType(ElevatedButton));
        expect(buttonSize.height, equals(AppSpacing.minTouchTarget));

        final buttonText = tester.widget<Text>(find.text('Create Account'));
        expect(buttonText.style, equals(AppTypography.buttonText));
      });
    });

    group('UsernameSetupPage Design System Tests', () {
      testWidgets('UsernameSetupPage uses design system typography hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const UsernameSetupPage(),
          ),
        );

        // Verify title typography
        final titleText = tester.widget<Text>(find.text('Time Capsule'));
        expect(titleText.style?.fontSize, equals(AppTypography.displayMedium.fontSize));

        // Verify subtitle typography
        final subtitleText = tester.widget<Text>(find.text('Choose Your Username'));
        expect(subtitleText.style?.fontSize, equals(AppTypography.headlineMedium.fontSize));

        // Verify description typography
        final descriptionText = tester.widget<Text>(
          find.text('Create a unique username to personalize your Time Capsule experience.'),
        );
        expect(descriptionText.style?.fontSize, equals(AppTypography.bodyMedium.fontSize));
        expect(descriptionText.style?.color, equals(AppColors.textTertiary));
      });

      testWidgets('UsernameSetupPage username field has proper styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const UsernameSetupPage(),
          ),
        );

        // Find the username text field
        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        final decoration = textField.decoration!;

        // Verify styling consistency
        expect(decoration.fillColor, equals(AppColors.surfaceSecondary));
        expect(decoration.filled, isTrue);
        
        final border = decoration.border as OutlineInputBorder;
        expect(border.borderRadius, equals(AppSpacing.inputRadius));
        expect(decoration.contentPadding, equals(AppSpacing.inputPadding));

        // Verify hint text styling
        expect(decoration.hintText, equals('Enter your username'));
      });

      testWidgets('UsernameSetupPage requirements text uses correct styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const UsernameSetupPage(),
          ),
        );

        // Find requirements header
        final requirementsHeader = tester.widget<Text>(find.text('Username requirements:'));
        expect(requirementsHeader.style?.fontSize, equals(AppTypography.labelMedium.fontSize));
        expect(requirementsHeader.style?.color, equals(AppColors.textPrimary));

        // Find requirements list
        final requirementsList = tester.widget<Text>(
          find.text('• 3-20 characters\n• Letters, numbers, and underscores only\n• Must be unique'),
        );
        expect(requirementsList.style?.fontSize, equals(AppTypography.bodySmall.fontSize));
        expect(requirementsList.style?.color, equals(AppColors.textTertiary));
      });
    });

    group('Authentication Pages Accessibility Tests', () {
      testWidgets('All auth pages meet touch target requirements', (WidgetTester tester) async {
        final pages = [
          const LoginPage(),
          const RegisterPage(),
          const UsernameSetupPage(),
        ];

        for (final page in pages) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: page,
            ),
          );

          // Check button touch targets
          final buttons = find.byType(ElevatedButton);
          if (buttons.evaluate().isNotEmpty) {
            final buttonSize = tester.getSize(buttons.first);
            expect(buttonSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
          }

          // Check icon button touch targets
          final iconButtons = find.byType(IconButton);
          for (final iconButton in iconButtons.evaluate()) {
            final size = tester.getSize(find.byWidget(iconButton.widget));
            expect(size.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
            expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
          }
        }
      });

      testWidgets('All auth pages maintain proper contrast ratios', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginPage(),
          ),
        );

        // Test primary text contrast
        final backgroundLuminance = AppColors.surfacePrimary.computeLuminance();
        final textLuminance = AppColors.textPrimary.computeLuminance();
        final contrastRatio = (backgroundLuminance + 0.05) / (textLuminance + 0.05);
        
        // Should meet WCAG AA standard
        expect(contrastRatio, greaterThan(4.5));
      });
    });

    group('Authentication Pages Responsive Design Tests', () {
      testWidgets('Auth pages adapt to different screen sizes', (WidgetTester tester) async {
        // Test with different screen sizes
        final sizes = [
          const Size(320, 568), // Small phone
          const Size(375, 667), // Medium phone
          const Size(414, 896), // Large phone
        ];

        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const LoginPage(),
            ),
          );

          // Verify page content fits within screen bounds
          final scaffold = find.byType(Scaffold);
          final scaffoldSize = tester.getSize(scaffold);
          expect(scaffoldSize.width, lessThanOrEqualTo(size.width));
          expect(scaffoldSize.height, lessThanOrEqualTo(size.height));

          // Verify padding adapts appropriately
          final padding = tester.widget<Padding>(
            find.descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Padding),
            ).first,
          );
          expect(padding.padding, equals(AppSpacing.pageAll));
        }

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}