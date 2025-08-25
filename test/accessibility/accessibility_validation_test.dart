import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/utils/accessibility_utils.dart';
import 'package:time_capsule/utils/contrast_checker.dart';
import 'package:time_capsule/widgets/accessibility/accessible_button.dart';
import 'package:time_capsule/widgets/accessibility/accessible_text_field.dart';
import 'package:time_capsule/widgets/accessibility/accessible_card.dart';

void main() {
  group('Accessibility Validation Tests', () {
    group('Contrast Validation', () {
      test('should validate all design system colors meet WCAG AA', () {
        final results = ContrastChecker.validateDesignSystemContrast();
        final failingCombinations = results.values
            .where((result) => !result.meetsWCAGAA)
            .toList();
        
        if (failingCombinations.isNotEmpty) {
          print('Failing combinations:');
          for (final result in failingCombinations) {
            print('  ${result.description}: ${result.contrastRatio.toStringAsFixed(2)}:1');
          }
        }
        
        expect(
          failingCombinations,
          isEmpty,
          reason: 'All design system color combinations should meet WCAG AA standards',
        );
      });

      test('should generate comprehensive contrast report', () {
        final report = ContrastChecker.generateContrastReport();
        
        expect(report, contains('WCAG Contrast Compliance Report'));
        expect(report, contains('Summary'));
        expect(report, contains('Total combinations tested:'));
        
        // Print report for manual review
        print('\n$report');
      });
    });

    group('Touch Target Validation', () {
      testWidgets('should validate touch target sizes for accessible buttons', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AccessibleButton(
                    label: 'Primary Button',
                    onPressed: () {},
                  ),
                  AccessibleButton(
                    label: 'Secondary Button',
                    isPrimary: false,
                    onPressed: () {},
                  ),
                  AccessibleTextButton(
                    label: 'Text Button',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Check all buttons meet minimum touch target size
        final buttons = find.byType(ElevatedButton);
        for (int i = 0; i < buttons.evaluate().length; i++) {
          final size = tester.getSize(buttons.at(i));
          expect(
            AccessibilityUtils.validateTouchTargetSize(size),
            isTrue,
            reason: 'Button at index $i does not meet minimum touch target size (44x44dp)',
          );
        }

        final outlinedButtons = find.byType(OutlinedButton);
        for (int i = 0; i < outlinedButtons.evaluate().length; i++) {
          final size = tester.getSize(outlinedButtons.at(i));
          expect(
            AccessibilityUtils.validateTouchTargetSize(size),
            isTrue,
            reason: 'Outlined button at index $i does not meet minimum touch target size',
          );
        }

        final textButtons = find.byType(TextButton);
        for (int i = 0; i < textButtons.evaluate().length; i++) {
          final size = tester.getSize(textButtons.at(i));
          expect(
            AccessibilityUtils.validateTouchTargetSize(size),
            isTrue,
            reason: 'Text button at index $i does not meet minimum touch target size',
          );
        }
      });
    });

    group('Semantic Label Validation', () {
      testWidgets('should provide proper semantic labels for form elements', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AccessibleTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    required: true,
                  ),
                  AccessibleTextField(
                    label: 'Password',
                    obscureText: true,
                    required: true,
                  ),
                  AccessibleButton(
                    label: 'Submit Form',
                    hint: 'Submit the registration form',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify text fields have proper semantics
        final textFields = find.byType(TextFormField);
        expect(textFields.evaluate().length, equals(2));

        // Check email field
        final emailField = textFields.first;
        final emailSemantics = tester.getSemantics(emailField);
        expect(emailSemantics.label, contains('Email Address'));

        // Check password field
        final passwordField = textFields.at(1);
        final passwordSemantics = tester.getSemantics(passwordField);
        expect(passwordSemantics.label, contains('Password'));

        // Check submit button
        final submitButton = find.byType(ElevatedButton);
        final submitSemantics = tester.getSemantics(submitButton);
        expect(submitSemantics.label, contains('Submit Form'));
      });

      testWidgets('should provide proper semantic labels for cards', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AccessibleCard(
                    semanticLabel: 'Memory Card',
                    hint: 'Tap to view memory details',
                    onTap: () {},
                    child: const Text('Memory content'),
                  ),
                  AccessibleCard(
                    semanticLabel: 'Photo Album',
                    isSelectable: true,
                    isSelected: true,
                    child: const Text('Album content'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Check interactive card
        final cards = find.byType(AccessibleCard);
        expect(cards.evaluate().length, equals(2));

        final firstCard = cards.first;
        final firstCardSemantics = tester.getSemantics(firstCard);
        expect(firstCardSemantics.label, contains('Memory Card'));

        final secondCard = cards.at(1);
        final secondCardSemantics = tester.getSemantics(secondCard);
        expect(secondCardSemantics.label, contains('Photo Album'));
      });
    });

    group('Accessibility Utility Functions', () {
      test('should create proper semantic labels', () {
        final basicLabel = AccessibilityUtils.createSemanticLabel(
          label: 'Settings',
        );
        expect(basicLabel, equals('Settings'));

        final buttonLabel = AccessibilityUtils.createSemanticLabel(
          label: 'Save',
          isButton: true,
        );
        expect(buttonLabel, equals('Save, button'));

        final complexLabel = AccessibilityUtils.createSemanticLabel(
          label: 'Volume Control',
          value: '75%',
          hint: 'Adjust volume level',
          isSelected: true,
        );
        expect(complexLabel, contains('Volume Control'));
        expect(complexLabel, contains('75%'));
        expect(complexLabel, contains('selected'));
        expect(complexLabel, contains('Adjust volume level'));
      });

      test('should create proper accessibility hints', () {
        final basicHint = AccessibilityUtils.createAccessibilityHint(
          action: 'Double tap',
        );
        expect(basicHint, equals('Double tap'));

        final complexHint = AccessibilityUtils.createAccessibilityHint(
          action: 'Tap',
          result: 'save changes',
          navigation: 'home screen',
        );
        expect(complexHint, equals('Tap to save changes, navigates to home screen'));
      });

      test('should validate touch target sizes correctly', () {
        expect(
          AccessibilityUtils.validateTouchTargetSize(const Size(44, 44)),
          isTrue,
        );
        expect(
          AccessibilityUtils.validateTouchTargetSize(const Size(48, 48)),
          isTrue,
        );
        expect(
          AccessibilityUtils.validateTouchTargetSize(const Size(40, 40)),
          isFalse,
        );
        expect(
          AccessibilityUtils.validateTouchTargetSize(const Size(44, 40)),
          isFalse,
        );
      });
    });

    group('Color Contrast Utilities', () {
      test('should calculate contrast ratios correctly', () {
        final blackWhiteRatio = AccessibilityUtils.calculateContrastRatio(
          Colors.black,
          Colors.white,
        );
        expect(blackWhiteRatio, closeTo(21.0, 0.1));

        final sameColorRatio = AccessibilityUtils.calculateContrastRatio(
          Colors.blue,
          Colors.blue,
        );
        expect(sameColorRatio, closeTo(1.0, 0.1));
      });

      test('should identify WCAG compliance correctly', () {
        expect(
          AccessibilityUtils.meetsWCAGAA(Colors.black, Colors.white),
          isTrue,
        );
        expect(
          AccessibilityUtils.meetsWCAGAAA(Colors.black, Colors.white),
          isTrue,
        );
        expect(
          AccessibilityUtils.meetsWCAGAA(
            const Color(0xFFCCCCCC),
            Colors.white,
          ),
          isFalse,
        );
      });
    });

    group('Integration Validation', () {
      testWidgets('should validate complete accessible form', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Accessible Form'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccessibleTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    AccessibleTextField(
                      label: 'Email',
                      hint: 'Enter your email address',
                      keyboardType: TextInputType.emailAddress,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    AccessibleTextField(
                      label: 'Password',
                      hint: 'Create a secure password',
                      obscureText: true,
                      required: true,
                    ),
                    const SizedBox(height: 24),
                    AccessibleButton(
                      label: 'Create Account',
                      hint: 'Submit form to create your account',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 8),
                    AccessibleTextButton(
                      label: 'Already have an account? Sign in',
                      hint: 'Navigate to sign in page',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify all form elements are present and accessible
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);

        // Verify touch targets
        final allButtons = [
          ...find.byType(ElevatedButton).evaluate(),
          ...find.byType(TextButton).evaluate(),
        ];

        for (int i = 0; i < allButtons.length; i++) {
          final buttonFinder = find.byWidget(allButtons[i].widget);
          final size = tester.getSize(buttonFinder);
          expect(
            AccessibilityUtils.validateTouchTargetSize(size),
            isTrue,
            reason: 'Button at index $i does not meet touch target requirements',
          );
        }

        // Verify semantic labels exist
        final textFields = find.byType(TextFormField);
        for (int i = 0; i < textFields.evaluate().length; i++) {
          final semantics = tester.getSemantics(textFields.at(i));
          expect(semantics.label, isNotNull);
          expect(semantics.label.trim(), isNotEmpty);
        }

        final buttons = find.byType(ElevatedButton);
        for (int i = 0; i < buttons.evaluate().length; i++) {
          final semantics = tester.getSemantics(buttons.at(i));
          expect(semantics.label, isNotNull);
          expect(semantics.label.trim(), isNotEmpty);
        }
      });
    });
  });
}