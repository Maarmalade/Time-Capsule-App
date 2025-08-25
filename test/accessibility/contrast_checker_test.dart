import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/utils/contrast_checker.dart';

void main() {
  group('ContrastChecker', () {
    group('Design System Validation', () {
      test('should validate all design system color combinations', () {
        final results = ContrastChecker.validateDesignSystemContrast();
        
        expect(results, isNotEmpty);
        expect(results.containsKey('Primary text on white'), isTrue);
        expect(results.containsKey('Primary button text'), isTrue);
        expect(results.containsKey('Success text'), isTrue);
      });

      test('should ensure primary text combinations meet WCAG AA', () {
        final results = ContrastChecker.validateDesignSystemContrast();
        
        // Primary text on white should pass
        final primaryOnWhite = results['Primary text on white']!;
        expect(primaryOnWhite.meetsWCAGAA, isTrue);
        expect(primaryOnWhite.contrastRatio, greaterThan(4.5));
        
        // Primary text on soft gray should pass
        final primaryOnGray = results['Primary text on soft gray']!;
        expect(primaryOnGray.meetsWCAGAA, isTrue);
      });

      test('should ensure button text combinations meet WCAG AA', () {
        final results = ContrastChecker.validateDesignSystemContrast();
        
        // Primary button (white on blue) should pass
        final primaryButton = results['Primary button text']!;
        expect(primaryButton.meetsWCAGAA, isTrue);
        
        // Secondary button (blue on white) should pass
        final secondaryButton = results['Secondary button text']!;
        expect(secondaryButton.meetsWCAGAA, isTrue);
      });

      test('should validate navigation element contrast', () {
        final results = ContrastChecker.validateDesignSystemContrast();
        
        // Active navigation items should be accessible
        final activeNav = results['Active nav item']!;
        expect(activeNav.meetsWCAGAA, isTrue);
        
        // Inactive navigation items should be accessible
        final inactiveNav = results['Inactive nav item']!;
        expect(inactiveNav.meetsWCAGAA, isTrue);
      });
    });

    group('Individual Contrast Checking', () {
      test('should check contrast between specific colors', () {
        final result = ContrastChecker.checkContrast(
          'Test combination',
          Colors.black,
          Colors.white,
        );
        
        expect(result.description, equals('Test combination'));
        expect(result.foregroundColor, equals(Colors.black));
        expect(result.backgroundColor, equals(Colors.white));
        expect(result.contrastRatio, closeTo(21.0, 0.1));
        expect(result.meetsWCAGAA, isTrue);
        expect(result.meetsWCAGAAA, isTrue);
      });

      test('should identify failing contrast combinations', () {
        final result = ContrastChecker.checkContrast(
          'Poor contrast',
          const Color(0xFFCCCCCC), // Light gray
          Colors.white,
        );
        
        expect(result.meetsWCAGAA, isFalse);
        expect(result.contrastRatio, lessThan(4.5));
      });
    });

    group('Contrast Report Generation', () {
      test('should generate comprehensive contrast report', () {
        final report = ContrastChecker.generateContrastReport();
        
        expect(report, contains('WCAG Contrast Compliance Report'));
        expect(report, contains('Contrast Ratio:'));
        expect(report, contains('WCAG AA:'));
        expect(report, contains('WCAG AAA:'));
        expect(report, contains('Summary'));
        expect(report, contains('Total combinations tested:'));
      });

      test('should identify failing combinations', () {
        final failing = ContrastChecker.getFailingCombinations();
        
        // Print any failing combinations for debugging
        if (failing.isNotEmpty) {
          print('Failing combinations:');
          for (final result in failing) {
            print('  ${result.description}: ${result.contrastRatio.toStringAsFixed(2)}:1');
          }
        }
        
        // All our design system combinations should pass WCAG AA
        expect(failing, isEmpty, 
          reason: 'All design system color combinations should meet WCAG AA standards');
      });
    });

    group('Color Suggestions', () {
      test('should suggest alternative colors for failing combinations', () {
        // Create a failing combination
        final failingResult = ContrastResult(
          description: 'Test failing combination',
          foregroundColor: const Color(0xFFCCCCCC),
          backgroundColor: Colors.white,
          contrastRatio: 2.0,
          meetsWCAGAA: false,
          meetsWCAGAAA: false,
        );
        
        final suggestions = ContrastChecker.suggestAlternativeColors(failingResult);
        
        // Suggestions might be empty if no good alternatives are found
        // but if they exist, they should improve contrast
        for (final suggestion in suggestions) {
          expect(suggestion.contrastRatio, greaterThan(4.5));
        }
        
        // At minimum, the method should not throw an error
        expect(suggestions, isA<List<ColorSuggestion>>());
      });

      test('should provide meaningful suggestion descriptions', () {
        final failingResult = ContrastResult(
          description: 'Test failing combination',
          foregroundColor: const Color(0xFFCCCCCC),
          backgroundColor: Colors.white,
          contrastRatio: 2.0,
          meetsWCAGAA: false,
          meetsWCAGAAA: false,
        );
        
        final suggestions = ContrastChecker.suggestAlternativeColors(failingResult);
        
        for (final suggestion in suggestions) {
          expect(suggestion.description, isNotEmpty);
          expect(
            suggestion.description,
            anyOf(
              contains('Darken'),
              contains('Lighten'),
            ),
          );
        }
      });
    });

    group('ContrastResult', () {
      test('should provide meaningful string representation', () {
        final result = ContrastResult(
          description: 'Test result',
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          contrastRatio: 21.0,
          meetsWCAGAA: true,
          meetsWCAGAAA: true,
        );
        
        final string = result.toString();
        expect(string, contains('Test result'));
        expect(string, contains('21.00:1'));
        expect(string, contains('AA: PASS'));
        expect(string, contains('AAA: PASS'));
      });
    });

    group('ColorSuggestion', () {
      test('should provide meaningful string representation', () {
        final suggestion = ColorSuggestion(
          description: 'Darken foreground',
          suggestedForeground: Colors.black,
          suggestedBackground: Colors.white,
          contrastRatio: 21.0,
        );
        
        final string = suggestion.toString();
        expect(string, contains('Darken foreground'));
        expect(string, contains('21.00:1'));
      });
    });
  });
}