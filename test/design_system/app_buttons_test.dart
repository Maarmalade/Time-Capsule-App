import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_buttons.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_spacing.dart';

// Mock Google Fonts for testing
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    // Prevent Google Fonts from making HTTP requests during tests
    // This is handled by using fallback fonts in the design system
  });

  group('AppButtons', () {
    group('Primary Button Style', () {
      test('should have correct default properties', () {
        final style = AppButtons.primaryButtonStyle;
        
        // Test background color
        expect(
          style.backgroundColor?.resolve({}),
          equals(AppColors.accentBlue),
        );
        
        // Test foreground color
        expect(
          style.foregroundColor?.resolve({}),
          equals(AppColors.textOnAccent),
        );
        
        // Test elevation
        expect(
          style.elevation?.resolve({}),
          equals(AppSpacing.elevation2),
        );
        
        // Test minimum size
        expect(
          style.minimumSize?.resolve({}),
          equals(const Size(0, 44.0)),
        );
      });

      test('should have correct disabled state', () {
        final style = AppButtons.primaryButtonStyle;
        const disabledStates = {WidgetState.disabled};
        
        expect(
          style.backgroundColor?.resolve(disabledStates),
          equals(AppColors.accentBlue.withOpacity(0.38)),
        );
        
        expect(
          style.elevation?.resolve(disabledStates),
          equals(0),
        );
      });

      test('should have correct pressed state', () {
        final style = AppButtons.primaryButtonStyle;
        const pressedStates = {WidgetState.pressed};
        
        // Background should be darker when pressed
        final pressedColor = style.backgroundColor?.resolve(pressedStates);
        expect(pressedColor, isNotNull);
        expect(pressedColor, isNot(equals(AppColors.accentBlue)));
        
        // Elevation should be lower when pressed
        expect(
          style.elevation?.resolve(pressedStates),
          equals(AppSpacing.elevation1),
        );
      });

      test('should have correct hovered state', () {
        final style = AppButtons.primaryButtonStyle;
        const hoveredStates = {WidgetState.hovered};
        
        // Background should be darker when hovered
        final hoveredColor = style.backgroundColor?.resolve(hoveredStates);
        expect(hoveredColor, isNotNull);
        expect(hoveredColor, isNot(equals(AppColors.accentBlue)));
        
        // Elevation should be higher when hovered
        expect(
          style.elevation?.resolve(hoveredStates),
          equals(AppSpacing.elevation3),
        );
      });
    });

    group('Secondary Button Style', () {
      test('should have correct default properties', () {
        final style = AppButtons.secondaryButtonStyle;
        
        // Test background color (should be transparent)
        expect(
          style.backgroundColor?.resolve({}),
          equals(Colors.transparent),
        );
        
        // Test foreground color
        expect(
          style.foregroundColor?.resolve({}),
          equals(AppColors.accentBlue),
        );
        
        // Test border
        final border = style.side?.resolve({});
        expect(border?.color, equals(AppColors.accentBlue));
        expect(border?.width, equals(1.5));
      });

      test('should have correct disabled state', () {
        final style = AppButtons.secondaryButtonStyle;
        const disabledStates = {WidgetState.disabled};
        
        expect(
          style.foregroundColor?.resolve(disabledStates),
          equals(AppColors.accentBlue.withOpacity(0.38)),
        );
        
        final disabledBorder = style.side?.resolve(disabledStates);
        expect(
          disabledBorder?.color,
          equals(AppColors.accentBlue.withOpacity(0.38)),
        );
      });

      test('should have correct pressed state', () {
        final style = AppButtons.secondaryButtonStyle;
        const pressedStates = {WidgetState.pressed};
        
        // Background should have overlay when pressed
        expect(
          style.backgroundColor?.resolve(pressedStates),
          equals(AppColors.accentBlue.withOpacity(0.12)),
        );
        
        // Border should be thicker when pressed
        final pressedBorder = style.side?.resolve(pressedStates);
        expect(pressedBorder?.width, equals(2.0));
      });
    });

    group('Text Button Style', () {
      test('should have correct default properties', () {
        final style = AppButtons.textButtonStyle;
        
        // Test background color (should be transparent)
        expect(
          style.backgroundColor?.resolve({}),
          equals(Colors.transparent),
        );
        
        // Test foreground color
        expect(
          style.foregroundColor?.resolve({}),
          equals(AppColors.accentBlue),
        );
        
        // Test minimum size (should be smaller than other buttons)
        expect(
          style.minimumSize?.resolve({}),
          equals(const Size(0, 36.0)),
        );
      });

      test('should have correct state changes', () {
        final style = AppButtons.textButtonStyle;
        
        // Pressed state
        const pressedStates = {WidgetState.pressed};
        expect(
          style.backgroundColor?.resolve(pressedStates),
          equals(AppColors.accentBlue.withOpacity(0.12)),
        );
        
        // Hovered state
        const hoveredStates = {WidgetState.hovered};
        expect(
          style.backgroundColor?.resolve(hoveredStates),
          equals(AppColors.accentBlue.withOpacity(0.08)),
        );
      });
    });

    group('Destructive Button Style', () {
      test('should have correct default properties', () {
        final style = AppButtons.destructiveButtonStyle;
        
        expect(
          style.backgroundColor?.resolve({}),
          equals(AppColors.errorRed),
        );
        
        expect(
          style.foregroundColor?.resolve({}),
          equals(AppColors.textOnAccent),
        );
      });

      test('should have correct disabled state', () {
        final style = AppButtons.destructiveButtonStyle;
        const disabledStates = {WidgetState.disabled};
        
        expect(
          style.backgroundColor?.resolve(disabledStates),
          equals(AppColors.errorRed.withOpacity(0.38)),
        );
      });
    });

    group('Icon Button Style', () {
      test('should have correct default properties', () {
        final style = AppButtons.iconButtonStyle;
        
        expect(
          style.backgroundColor?.resolve({}),
          equals(Colors.transparent),
        );
        
        expect(
          style.foregroundColor?.resolve({}),
          equals(AppColors.textPrimary),
        );
        
        // Should meet minimum touch target size
        expect(
          style.minimumSize?.resolve({}),
          equals(const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget)),
        );
      });
    });

    group('Button Size Variants', () {
      test('large button should have increased dimensions', () {
        final baseStyle = AppButtons.primaryButtonStyle;
        final largeStyle = AppButtons.getLargeButtonStyle(baseStyle);
        
        expect(
          largeStyle.minimumSize?.resolve({}),
          equals(const Size(0, 48.0)),
        );
        
        final padding = largeStyle.padding?.resolve({});
        expect(padding, isNotNull);
        expect(padding!.horizontal, equals(48.0)); // 24 * 2
        expect(padding.vertical, equals(24.0)); // 12 * 2
      });

      test('small button should have decreased dimensions', () {
        final baseStyle = AppButtons.primaryButtonStyle;
        final smallStyle = AppButtons.getSmallButtonStyle(baseStyle);
        
        expect(
          smallStyle.minimumSize?.resolve({}),
          equals(const Size(0, 36.0)),
        );
        
        final padding = smallStyle.padding?.resolve({});
        expect(padding, isNotNull);
        expect(padding!.horizontal, equals(32.0)); // 16 * 2
        expect(padding.vertical, equals(16.0)); // 8 * 2
      });
    });

    group('Accessibility Compliance', () {
      test('all buttons should meet minimum touch target size', () {
        final styles = [
          AppButtons.primaryButtonStyle,
          AppButtons.secondaryButtonStyle,
          AppButtons.destructiveButtonStyle,
          AppButtons.iconButtonStyle,
        ];
        
        for (final style in styles) {
          final minSize = style.minimumSize?.resolve({});
          expect(minSize, isNotNull);
          expect(minSize!.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
        }
      });

      test('disabled buttons should have sufficient opacity reduction', () {
        final styles = [
          AppButtons.primaryButtonStyle,
          AppButtons.secondaryButtonStyle,
          AppButtons.textButtonStyle,
          AppButtons.destructiveButtonStyle,
        ];
        
        const disabledStates = {WidgetState.disabled};
        
        for (final style in styles) {
          final disabledColor = style.backgroundColor?.resolve(disabledStates) ??
              style.foregroundColor?.resolve(disabledStates);
          
          if (disabledColor != null && disabledColor != Colors.transparent) {
            // Should have reduced opacity for disabled state
            expect(disabledColor.opacity, lessThan(1.0));
          }
        }
      });

      test('button text should use appropriate typography', () {
        final styles = [
          AppButtons.primaryButtonStyle,
          AppButtons.secondaryButtonStyle,
          AppButtons.textButtonStyle,
        ];
        
        for (final style in styles) {
          final textStyle = style.textStyle?.resolve({});
          expect(textStyle, isNotNull);
          // Check that text style has appropriate properties without relying on Google Fonts
          expect(textStyle!.fontSize, equals(14.0));
          expect(textStyle.letterSpacing, equals(0.1));
        }
      });
    });

    group('Utility Methods', () {
      testWidgets('createLoadingButton shows loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButtons.createLoadingButton(
                text: 'Test Button',
                onPressed: () {},
                isLoading: true,
              ),
            ),
          ),
        );
        
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Test Button'), findsNothing);
      });

      testWidgets('createLoadingButton shows text when not loading', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButtons.createLoadingButton(
                text: 'Test Button',
                onPressed: () {},
                isLoading: false,
              ),
            ),
          ),
        );
        
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Test Button'), findsOneWidget);
      });

      testWidgets('createFullWidthButton has full width', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: AppButtons.createFullWidthButton(
                  text: 'Full Width Button',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );
        
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final minSize = button.style?.minimumSize?.resolve({});
        expect(minSize?.width, equals(double.infinity));
      });
    });

    group('Theme Integration', () {
      test('theme data should be properly configured', () {
        final elevatedTheme = AppButtons.elevatedButtonTheme;
        final outlinedTheme = AppButtons.outlinedButtonTheme;
        final textTheme = AppButtons.textButtonTheme;
        final iconTheme = AppButtons.iconButtonTheme;
        final fabTheme = AppButtons.floatingActionButtonTheme;
        
        // Test that theme objects are created without errors
        expect(elevatedTheme, isNotNull);
        expect(outlinedTheme, isNotNull);
        expect(textTheme, isNotNull);
        expect(iconTheme, isNotNull);
        expect(fabTheme.backgroundColor, equals(AppColors.accentBlue));
      });
    });

    group('Visual Consistency', () {
      test('all button styles should use consistent border radius', () {
        final styles = [
          AppButtons.primaryButtonStyle,
          AppButtons.secondaryButtonStyle,
          AppButtons.textButtonStyle,
          AppButtons.destructiveButtonStyle,
        ];
        
        for (final style in styles) {
          final shape = style.shape?.resolve({}) as RoundedRectangleBorder?;
          expect(shape, isNotNull);
          expect(shape!.borderRadius, equals(AppSpacing.buttonRadius));
        }
      });

      test('button colors should maintain proper contrast', () {
        // Primary button should have high contrast
        final primaryBg = AppButtons.primaryButtonStyle.backgroundColor?.resolve({});
        final primaryFg = AppButtons.primaryButtonStyle.foregroundColor?.resolve({});
        expect(primaryBg, equals(AppColors.accentBlue));
        expect(primaryFg, equals(AppColors.textOnAccent));
        
        // Secondary button should use accent color for text
        final secondaryFg = AppButtons.secondaryButtonStyle.foregroundColor?.resolve({});
        expect(secondaryFg, equals(AppColors.accentBlue));
      });
    });
  });
}