import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_inputs.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_spacing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppInputs', () {
    group('Input Decoration Theme', () {
      test('should have correct default properties', () {
        final theme = AppInputs.inputDecorationTheme;
        
        // Test fill properties
        expect(theme.filled, isTrue);
        expect(theme.fillColor, equals(AppColors.softGray));
        
        // Test content padding
        expect(theme.contentPadding, equals(AppInputs.inputPaddingMedium));
        
        // Test border radius consistency
        final border = theme.border as OutlineInputBorder?;
        expect(border?.borderRadius, equals(AppSpacing.inputRadius));
      });

      test('should have correct focus state styling', () {
        final theme = AppInputs.inputDecorationTheme;
        
        final focusedBorder = theme.focusedBorder as OutlineInputBorder?;
        expect(focusedBorder?.borderSide.color, equals(AppColors.accentBlue));
        expect(focusedBorder?.borderSide.width, equals(2.0));
        
        expect(theme.focusColor, equals(AppColors.accentBlue));
      });

      test('should have correct error state styling', () {
        final theme = AppInputs.inputDecorationTheme;
        
        final errorBorder = theme.errorBorder as OutlineInputBorder?;
        expect(errorBorder?.borderSide.color, equals(AppColors.errorRed));
        expect(errorBorder?.borderSide.width, equals(2.0));
        
        final focusedErrorBorder = theme.focusedErrorBorder as OutlineInputBorder?;
        expect(focusedErrorBorder?.borderSide.color, equals(AppColors.errorRed));
        expect(focusedErrorBorder?.borderSide.width, equals(2.0));
      });

      test('should have appropriate text styles', () {
        final theme = AppInputs.inputDecorationTheme;
        
        expect(theme.labelStyle?.fontSize, equals(14.0));
        expect(theme.labelStyle?.fontWeight, equals(FontWeight.w500));
        
        expect(theme.helperStyle?.fontSize, equals(12.0));
        expect(theme.errorStyle?.fontSize, equals(12.0));
      });
    });

    group('Standard Decoration', () {
      test('should have correct properties', () {
        final decoration = AppInputs.standardDecoration;
        
        expect(decoration.filled, isTrue);
        expect(decoration.fillColor, equals(AppColors.softGray));
        expect(decoration.contentPadding, equals(AppInputs.inputPaddingMedium));
        
        // Test border configuration
        final border = decoration.border as OutlineInputBorder?;
        expect(border?.borderSide, equals(BorderSide.none));
        expect(border?.borderRadius, equals(AppSpacing.inputRadius));
      });

      test('should have correct focus border', () {
        final decoration = AppInputs.standardDecoration;
        
        final focusedBorder = decoration.focusedBorder as OutlineInputBorder?;
        expect(focusedBorder?.borderSide.color, equals(AppColors.accentBlue));
        expect(focusedBorder?.borderSide.width, equals(2.0));
      });
    });

    group('Outlined Decoration', () {
      test('should have visible borders', () {
        final decoration = AppInputs.outlinedDecoration;
        
        expect(decoration.filled, isFalse);
        
        final border = decoration.border as OutlineInputBorder?;
        expect(border?.borderSide.color, equals(AppColors.borderMedium));
        expect(border?.borderSide.width, equals(1.0));
        
        final enabledBorder = decoration.enabledBorder as OutlineInputBorder?;
        expect(enabledBorder?.borderSide.color, equals(AppColors.borderMedium));
        expect(enabledBorder?.borderSide.width, equals(1.0));
      });

      test('should have correct disabled state', () {
        final decoration = AppInputs.outlinedDecoration;
        
        final disabledBorder = decoration.disabledBorder as OutlineInputBorder?;
        expect(disabledBorder?.borderSide.color, 
               equals(AppColors.borderMedium.withOpacity(0.5)));
      });
    });

    group('Search Decoration', () {
      test('should have rounded appearance', () {
        final decoration = AppInputs.searchDecoration;
        
        expect(decoration.filled, isTrue);
        expect(decoration.fillColor, equals(AppColors.lightGray));
        
        final border = decoration.border as OutlineInputBorder?;
        expect(border?.borderRadius, 
               equals(BorderRadius.circular(AppSpacing.radiusXl)));
      });

      test('should have search icon', () {
        final decoration = AppInputs.searchDecoration;
        
        final prefixIcon = decoration.prefixIcon as Icon?;
        expect(prefixIcon?.icon, equals(Icons.search));
        expect(prefixIcon?.color, equals(AppColors.textTertiary));
      });
    });

    group('Size Variants', () {
      test('large decoration should have increased padding', () {
        final baseDecoration = AppInputs.standardDecoration;
        final largeDecoration = AppInputs.getLargeInputDecoration(baseDecoration);
        
        expect(largeDecoration.contentPadding, equals(AppInputs.inputPaddingLarge));
      });

      test('small decoration should have decreased padding', () {
        final baseDecoration = AppInputs.standardDecoration;
        final smallDecoration = AppInputs.getSmallInputDecoration(baseDecoration);
        
        expect(smallDecoration.contentPadding, equals(AppInputs.inputPaddingSmall));
      });
    });

    group('Specialized Decorations', () {
      test('password decoration should have visibility toggle', () {
        bool obscureText = true;
        final decoration = AppInputs.getPasswordDecoration(
          obscureText: obscureText,
          onToggleVisibility: () => obscureText = !obscureText,
          labelText: 'Password',
        );
        
        expect(decoration.labelText, equals('Password'));
        expect(decoration.suffixIcon, isA<IconButton>());
      });

      test('email decoration should have email icon', () {
        final decoration = AppInputs.getEmailDecoration(
          labelText: 'Email',
          hintText: 'Enter your email',
        );
        
        expect(decoration.labelText, equals('Email'));
        expect(decoration.hintText, equals('Enter your email'));
        
        final prefixIcon = decoration.prefixIcon as Icon?;
        expect(prefixIcon?.icon, equals(Icons.email_outlined));
      });

      test('phone decoration should have phone icon', () {
        final decoration = AppInputs.getPhoneDecoration(
          labelText: 'Phone',
          hintText: 'Enter your phone number',
        );
        
        expect(decoration.labelText, equals('Phone'));
        expect(decoration.hintText, equals('Enter your phone number'));
        
        final prefixIcon = decoration.prefixIcon as Icon?;
        expect(prefixIcon?.icon, equals(Icons.phone_outlined));
      });

      test('multiline decoration should have proper alignment', () {
        final decoration = AppInputs.getMultilineDecoration(
          labelText: 'Description',
          hintText: 'Enter description',
        );
        
        expect(decoration.labelText, equals('Description'));
        expect(decoration.hintText, equals('Enter description'));
        expect(decoration.alignLabelWithHint, isTrue);
      });
    });

    group('Validation States', () {
      test('success decoration should have green styling', () {
        final baseDecoration = AppInputs.standardDecoration;
        final successDecoration = AppInputs.getSuccessDecoration(baseDecoration);
        
        final enabledBorder = successDecoration.enabledBorder as OutlineInputBorder?;
        expect(enabledBorder?.borderSide.color, equals(AppColors.successGreen));
        
        final focusedBorder = successDecoration.focusedBorder as OutlineInputBorder?;
        expect(focusedBorder?.borderSide.color, equals(AppColors.successGreen));
        
        final suffixIcon = successDecoration.suffixIcon as Icon?;
        expect(suffixIcon?.icon, equals(Icons.check_circle_outline));
        expect(suffixIcon?.color, equals(AppColors.successGreen));
      });

      test('warning decoration should have amber styling', () {
        final baseDecoration = AppInputs.standardDecoration;
        final warningDecoration = AppInputs.getWarningDecoration(baseDecoration);
        
        final enabledBorder = warningDecoration.enabledBorder as OutlineInputBorder?;
        expect(enabledBorder?.borderSide.color, equals(AppColors.warningAmber));
        
        final suffixIcon = warningDecoration.suffixIcon as Icon?;
        expect(suffixIcon?.icon, equals(Icons.warning_outlined));
        expect(suffixIcon?.color, equals(AppColors.warningAmber));
      });
    });

    group('Accessibility Compliance', () {
      test('input decorations should meet minimum touch target requirements', () {
        final decorations = [
          AppInputs.standardDecoration,
          AppInputs.outlinedDecoration,
          AppInputs.searchDecoration,
        ];
        
        for (final decoration in decorations) {
          final padding = decoration.contentPadding as EdgeInsets?;
          expect(padding, isNotNull);
          // Minimum touch target height should be achievable with padding + text height
          expect(padding!.vertical, greaterThanOrEqualTo(8.0));
        }
      });

      test('text styles should have appropriate contrast', () {
        final theme = AppInputs.inputDecorationTheme;
        
        // Label text should have sufficient contrast
        expect(theme.labelStyle?.color, isNotNull);
        expect(theme.helperStyle?.color, isNotNull);
        expect(theme.errorStyle?.color, equals(AppColors.errorRed));
      });

      test('error states should be clearly distinguishable', () {
        final theme = AppInputs.inputDecorationTheme;
        
        final errorBorder = theme.errorBorder as OutlineInputBorder?;
        final normalBorder = theme.enabledBorder as OutlineInputBorder?;
        
        // Error border should be visually distinct
        expect(errorBorder?.borderSide.color, isNot(equals(normalBorder?.borderSide.color)));
        expect(errorBorder?.borderSide.width, greaterThan(1.0));
      });
    });

    group('Visual Consistency', () {
      test('all decorations should use consistent border radius', () {
        final decorations = [
          AppInputs.standardDecoration,
          AppInputs.outlinedDecoration,
        ];
        
        for (final decoration in decorations) {
          final border = decoration.border as OutlineInputBorder?;
          expect(border?.borderRadius, equals(AppSpacing.inputRadius));
        }
      });

      test('focus states should use consistent accent color', () {
        final decorations = [
          AppInputs.standardDecoration,
          AppInputs.outlinedDecoration,
        ];
        
        for (final decoration in decorations) {
          final focusedBorder = decoration.focusedBorder as OutlineInputBorder?;
          expect(focusedBorder?.borderSide.color, equals(AppColors.accentBlue));
        }
      });

      test('text styles should be consistent across decorations', () {
        final decorations = [
          AppInputs.standardDecoration,
          AppInputs.outlinedDecoration,
        ];
        
        for (final decoration in decorations) {
          expect(decoration.labelStyle?.fontSize, equals(14.0));
          expect(decoration.helperStyle?.fontSize, equals(12.0));
        }
      });
    });

    testWidgets('createStandardTextField should render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppInputs.createStandardTextField(
              labelText: 'Test Label',
              hintText: 'Test Hint',
              helperText: 'Test Helper',
            ),
          ),
        ),
      );
      
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('createSearchField should render with search icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppInputs.createSearchField(
              hintText: 'Search here...',
            ),
          ),
        ),
      );
      
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('createFormField should render complete form structure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppInputs.createFormField(
              label: 'Required Field',
              hintText: 'Enter value',
              helperText: 'This field is required',
              required: true,
            ),
          ),
        ),
      );
      
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      // The form field structure is created correctly
    });

    group('Input Constants', () {
      test('should have appropriate height constants', () {
        expect(AppInputs.inputHeightLarge, equals(56.0));
        expect(AppInputs.inputHeightMedium, equals(48.0));
        expect(AppInputs.inputHeightSmall, equals(40.0));
        
        // Heights should be in descending order
        expect(AppInputs.inputHeightLarge, greaterThan(AppInputs.inputHeightMedium));
        expect(AppInputs.inputHeightMedium, greaterThan(AppInputs.inputHeightSmall));
      });

      test('should have appropriate padding constants', () {
        expect(AppInputs.inputPaddingLarge.horizontal, equals(40.0)); // 20 * 2
        expect(AppInputs.inputPaddingMedium.horizontal, equals(32.0)); // 16 * 2
        expect(AppInputs.inputPaddingSmall.horizontal, equals(24.0)); // 12 * 2
        
        // Padding should be in descending order
        expect(AppInputs.inputPaddingLarge.horizontal, 
               greaterThan(AppInputs.inputPaddingMedium.horizontal));
        expect(AppInputs.inputPaddingMedium.horizontal, 
               greaterThan(AppInputs.inputPaddingSmall.horizontal));
      });

      test('text styles should have appropriate properties', () {
        expect(AppInputs.inputTextStyle.fontSize, equals(16.0));
        expect(AppInputs.inputTextStyle.fontWeight, equals(FontWeight.w400));
        
        expect(AppInputs.labelTextStyle.fontSize, equals(14.0));
        expect(AppInputs.labelTextStyle.fontWeight, equals(FontWeight.w500));
        
        expect(AppInputs.helperTextStyle.fontSize, equals(12.0));
        expect(AppInputs.helperTextStyle.fontWeight, equals(FontWeight.w400));
      });
    });
  });
}