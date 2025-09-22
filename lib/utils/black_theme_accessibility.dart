import 'package:flutter/material.dart';
import 'accessibility_utils.dart';
import 'contrast_checker.dart';
import '../design_system/app_colors.dart';

/// Specialized accessibility utilities for black theme implementation
class BlackThemeAccessibility {
  /// Validate all black theme color combinations for WCAG compliance
  static BlackThemeValidationResult validateBlackTheme() {
    final results = <String, ContrastResult>{};
    final failures = <String>[];
    final warnings = <String>[];
    
    // Test all black theme combinations
    final blackThemeResults = ContrastChecker.validateBlackThemeContrast();
    results.addAll(blackThemeResults);
    
    // Test general design system with black theme
    final generalResults = ContrastChecker.validateDesignSystemContrast();
    results.addAll(generalResults);
    
    // Analyze results
    for (final entry in results.entries) {
      final result = entry.value;
      if (!result.meetsWCAGAA) {
        failures.add('${entry.key}: ${result.contrastRatio.toStringAsFixed(2)}:1 (requires 4.5:1)');
      } else if (!result.meetsWCAGAAA) {
        warnings.add('${entry.key}: ${result.contrastRatio.toStringAsFixed(2)}:1 (AA compliant, but not AAA)');
      }
    }
    
    return BlackThemeValidationResult(
      allResults: results,
      failures: failures,
      warnings: warnings,
      isCompliant: failures.isEmpty,
      totalCombinations: results.length,
      passedAA: results.values.where((r) => r.meetsWCAGAA).length,
      passedAAA: results.values.where((r) => r.meetsWCAGAAA).length,
    );
  }

  /// Get fallback colors for insufficient contrast scenarios
  static Map<String, Color> getFallbackColors() {
    return {
      'primaryAccentFallback': AppColors.charcoalNavy, // Fallback if pure black fails
      'lightBackgroundFallback': AppColors.lightGray, // Fallback for white backgrounds
      'textOnBlackFallback': AppColors.primaryWhite, // Ensure white text on black
      'focusIndicatorFallback': AppColors.charcoalNavy, // Fallback focus color
    };
  }

  /// Determine the best text color for a given background in black theme
  static Color getBestTextColorForBackground(Color backgroundColor) {
    final blackContrast = AccessibilityUtils.calculateContrastRatio(
      AppColors.primaryAccent,
      backgroundColor,
    );
    final whiteContrast = AccessibilityUtils.calculateContrastRatio(
      AppColors.primaryWhite,
      backgroundColor,
    );
    final charcoalContrast = AccessibilityUtils.calculateContrastRatio(
      AppColors.charcoalNavy,
      backgroundColor,
    );
    
    // Find the color with the best contrast that meets AA standards
    final candidates = [
      (AppColors.primaryAccent, blackContrast),
      (AppColors.primaryWhite, whiteContrast),
      (AppColors.charcoalNavy, charcoalContrast),
    ];
    
    // Sort by contrast ratio (highest first)
    candidates.sort((a, b) => b.$2.compareTo(a.$2));
    
    // Return the first color that meets AA standards
    for (final candidate in candidates) {
      if (candidate.$2 >= AccessibilityUtils.wcagAAContrastRatio) {
        return candidate.$1;
      }
    }
    
    // If none meet AA standards, return the one with the best contrast
    return candidates.first.$1;
  }

  /// Create focus indicator color with proper visibility
  static Color getFocusIndicatorColor(Color backgroundColor) {
    final blackFocusContrast = AccessibilityUtils.calculateContrastRatio(
      AppColors.primaryAccent,
      backgroundColor,
    );
    final whiteFocusContrast = AccessibilityUtils.calculateContrastRatio(
      AppColors.primaryWhite,
      backgroundColor,
    );
    
    // Use black focus indicator on light backgrounds, white on dark
    if (blackFocusContrast >= AccessibilityUtils.wcagAAContrastRatio) {
      return AppColors.primaryAccent;
    } else if (whiteFocusContrast >= AccessibilityUtils.wcagAAContrastRatio) {
      return AppColors.primaryWhite;
    } else {
      // Fallback to charcoal navy if neither black nor white works
      return AppColors.charcoalNavy;
    }
  }

  /// Validate button color combinations for black theme
  static List<ButtonContrastResult> validateButtonContrast() {
    final results = <ButtonContrastResult>[];
    
    // Primary button (black background, white text)
    results.add(ButtonContrastResult(
      buttonType: 'Primary Button',
      backgroundColor: AppColors.primaryAccent,
      textColor: AppColors.primaryWhite,
      contrastRatio: AccessibilityUtils.calculateContrastRatio(
        AppColors.primaryWhite,
        AppColors.primaryAccent,
      ),
      meetsWCAGAA: AccessibilityUtils.meetsWCAGAA(
        AppColors.primaryWhite,
        AppColors.primaryAccent,
      ),
    ));
    
    // Secondary button (white background, black text)
    results.add(ButtonContrastResult(
      buttonType: 'Secondary Button',
      backgroundColor: AppColors.primaryWhite,
      textColor: AppColors.primaryAccent,
      contrastRatio: AccessibilityUtils.calculateContrastRatio(
        AppColors.primaryAccent,
        AppColors.primaryWhite,
      ),
      meetsWCAGAA: AccessibilityUtils.meetsWCAGAA(
        AppColors.primaryAccent,
        AppColors.primaryWhite,
      ),
    ));
    
    // Hover states
    results.add(ButtonContrastResult(
      buttonType: 'Primary Button Hover',
      backgroundColor: AppColors.blackLight,
      textColor: AppColors.primaryWhite,
      contrastRatio: AccessibilityUtils.calculateContrastRatio(
        AppColors.primaryWhite,
        AppColors.blackLight,
      ),
      meetsWCAGAA: AccessibilityUtils.meetsWCAGAA(
        AppColors.primaryWhite,
        AppColors.blackLight,
      ),
    ));
    
    // Pressed states
    results.add(ButtonContrastResult(
      buttonType: 'Primary Button Pressed',
      backgroundColor: AppColors.blackDark,
      textColor: AppColors.primaryWhite,
      contrastRatio: AccessibilityUtils.calculateContrastRatio(
        AppColors.primaryWhite,
        AppColors.blackDark,
      ),
      meetsWCAGAA: AccessibilityUtils.meetsWCAGAA(
        AppColors.primaryWhite,
        AppColors.blackDark,
      ),
    ));
    
    // Disabled states
    results.add(ButtonContrastResult(
      buttonType: 'Primary Button Disabled',
      backgroundColor: AppColors.blackDisabled,
      textColor: AppColors.primaryWhite,
      contrastRatio: AccessibilityUtils.calculateContrastRatio(
        AppColors.primaryWhite,
        AppColors.blackDisabled,
      ),
      meetsWCAGAA: AccessibilityUtils.calculateContrastRatio(
        AppColors.primaryWhite,
        AppColors.blackDisabled,
      ) >= 3.0, // Disabled elements need 3:1 minimum
    ));
    
    return results;
  }

  /// Generate comprehensive accessibility report for black theme
  static String generateBlackThemeAccessibilityReport() {
    final validation = validateBlackTheme();
    final buttonResults = validateButtonContrast();
    final buffer = StringBuffer();
    
    buffer.writeln('=== Black Theme Accessibility Report ===\n');
    
    // Overall compliance
    buffer.writeln('Overall WCAG AA Compliance: ${validation.isCompliant ? "✓ PASS" : "✗ FAIL"}');
    buffer.writeln('Total combinations tested: ${validation.totalCombinations}');
    buffer.writeln('WCAG AA compliant: ${validation.passedAA}/${validation.totalCombinations}');
    buffer.writeln('WCAG AAA compliant: ${validation.passedAAA}/${validation.totalCombinations}');
    buffer.writeln();
    
    // Failures
    if (validation.failures.isNotEmpty) {
      buffer.writeln('=== FAILURES (WCAG AA) ===');
      for (final failure in validation.failures) {
        buffer.writeln('✗ $failure');
      }
      buffer.writeln();
    }
    
    // Warnings
    if (validation.warnings.isNotEmpty) {
      buffer.writeln('=== WARNINGS (WCAG AAA) ===');
      for (final warning in validation.warnings) {
        buffer.writeln('⚠ $warning');
      }
      buffer.writeln();
    }
    
    // Button specific results
    buffer.writeln('=== BUTTON CONTRAST ANALYSIS ===');
    for (final result in buttonResults) {
      buffer.writeln('${result.buttonType}:');
      buffer.writeln('  Contrast: ${result.contrastRatio.toStringAsFixed(2)}:1');
      buffer.writeln('  WCAG AA: ${result.meetsWCAGAA ? "✓ PASS" : "✗ FAIL"}');
      buffer.writeln();
    }
    
    // Recommendations
    buffer.writeln('=== RECOMMENDATIONS ===');
    if (validation.failures.isNotEmpty) {
      buffer.writeln('• Address failing color combinations before deployment');
      buffer.writeln('• Consider using fallback colors for insufficient contrast');
      buffer.writeln('• Test with actual users who have visual impairments');
    } else {
      buffer.writeln('• All critical combinations meet WCAG AA standards');
      buffer.writeln('• Consider improving AAA compliance for better accessibility');
    }
    
    return buffer.toString();
  }
}

/// Result of black theme validation
class BlackThemeValidationResult {
  final Map<String, ContrastResult> allResults;
  final List<String> failures;
  final List<String> warnings;
  final bool isCompliant;
  final int totalCombinations;
  final int passedAA;
  final int passedAAA;

  const BlackThemeValidationResult({
    required this.allResults,
    required this.failures,
    required this.warnings,
    required this.isCompliant,
    required this.totalCombinations,
    required this.passedAA,
    required this.passedAAA,
  });

  double get aaCompliancePercentage => (passedAA / totalCombinations) * 100;
  double get aaaCompliancePercentage => (passedAAA / totalCombinations) * 100;
}

/// Result of button contrast validation
class ButtonContrastResult {
  final String buttonType;
  final Color backgroundColor;
  final Color textColor;
  final double contrastRatio;
  final bool meetsWCAGAA;

  const ButtonContrastResult({
    required this.buttonType,
    required this.backgroundColor,
    required this.textColor,
    required this.contrastRatio,
    required this.meetsWCAGAA,
  });

  @override
  String toString() {
    return '$buttonType: ${contrastRatio.toStringAsFixed(2)}:1 '
           '(${meetsWCAGAA ? "PASS" : "FAIL"})';
  }
}