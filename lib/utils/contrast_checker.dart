import 'package:flutter/material.dart';
import 'accessibility_utils.dart';
import '../design_system/app_colors.dart';

/// Utility class for validating color contrast compliance
class ContrastChecker {
  /// Validate all color combinations in the app's design system
  static Map<String, ContrastResult> validateDesignSystemContrast() {
    final results = <String, ContrastResult>{};
    
    // Primary text on backgrounds
    results['Primary text on white'] = _checkContrast(
      'Primary text on white background',
      AppColors.charcoalNavy,
      AppColors.primaryWhite,
    );
    
    results['Primary text on soft gray'] = _checkContrast(
      'Primary text on soft gray background',
      AppColors.charcoalNavy,
      AppColors.softGray,
    );
    
    results['Secondary text on white'] = _checkContrast(
      'Secondary text on white background',
      AppColors.textGray,
      AppColors.primaryWhite,
    );
    
    results['Secondary text on soft gray'] = _checkContrast(
      'Secondary text on soft gray background',
      AppColors.textGray,
      AppColors.softGray,
    );
    
    // Black theme button combinations
    results['Primary button text'] = _checkContrast(
      'White text on black button',
      AppColors.primaryWhite,
      AppColors.primaryAccent,
    );
    
    results['Secondary button text'] = _checkContrast(
      'Black text on white button',
      AppColors.primaryAccent,
      AppColors.primaryWhite,
    );
    
    results['Black hover state'] = _checkContrast(
      'White text on black hover state',
      AppColors.primaryWhite,
      AppColors.blackLight,
    );
    
    results['Black pressed state'] = _checkContrast(
      'White text on black pressed state',
      AppColors.primaryWhite,
      AppColors.blackDark,
    );
    
    results['Black disabled state'] = _checkContrast(
      'White text on black disabled state',
      AppColors.primaryWhite,
      AppColors.blackDisabled,
    );
    
    // Status colors
    results['Success text'] = _checkContrast(
      'Success green on white background',
      AppColors.successGreen,
      AppColors.primaryWhite,
    );
    
    results['Error text'] = _checkContrast(
      'Error red on white background',
      AppColors.errorRed,
      AppColors.primaryWhite,
    );
    
    results['Warning text'] = _checkContrast(
      'Warning amber on white background',
      AppColors.warningAmber,
      AppColors.primaryWhite,
    );
    
    results['Info text'] = _checkContrast(
      'Info blue on white background',
      AppColors.infoBlue,
      AppColors.primaryWhite,
    );
    
    // Navigation elements with black theme
    results['Active nav item'] = _checkContrast(
      'Active navigation item (black on white)',
      AppColors.primaryAccent,
      AppColors.primaryWhite,
    );
    
    results['Inactive nav item'] = _checkContrast(
      'Inactive navigation item (dark gray on white)',
      AppColors.darkGray,
      AppColors.primaryWhite,
    );
    
    // Black theme specific combinations
    results['Black on light gray'] = _checkContrast(
      'Black accent on light gray background',
      AppColors.primaryAccent,
      AppColors.lightGray,
    );
    
    results['Black on soft gray'] = _checkContrast(
      'Black accent on soft gray background',
      AppColors.primaryAccent,
      AppColors.softGray,
    );
    
    results['Text on black overlay'] = _checkContrast(
      'White text on black overlay',
      AppColors.primaryWhite,
      AppColors.hoverOverlay,
    );
    
    return results;
  }

  /// Check contrast between two specific colors
  static ContrastResult checkContrast(
    String description,
    Color foreground,
    Color background,
  ) {
    return _checkContrast(description, foreground, background);
  }

  /// Validate black theme specific color combinations
  static Map<String, ContrastResult> validateBlackThemeContrast() {
    final results = <String, ContrastResult>{};
    
    // Black button states
    results['Black button normal'] = _checkContrast(
      'White text on black button (normal state)',
      AppColors.primaryWhite,
      AppColors.primaryAccent,
    );
    
    results['Black button hover'] = _checkContrast(
      'White text on black button (hover state)',
      AppColors.primaryWhite,
      AppColors.blackLight,
    );
    
    results['Black button pressed'] = _checkContrast(
      'White text on black button (pressed state)',
      AppColors.primaryWhite,
      AppColors.blackDark,
    );
    
    results['Black button disabled'] = _checkContrast(
      'White text on black button (disabled state)',
      AppColors.primaryWhite,
      AppColors.blackDisabled,
    );
    
    // Black text on various backgrounds
    results['Black text on white'] = _checkContrast(
      'Black text on white background',
      AppColors.primaryAccent,
      AppColors.primaryWhite,
    );
    
    results['Black text on light gray'] = _checkContrast(
      'Black text on light gray background',
      AppColors.primaryAccent,
      AppColors.lightGray,
    );
    
    results['Black text on soft gray'] = _checkContrast(
      'Black text on soft gray background',
      AppColors.primaryAccent,
      AppColors.softGray,
    );
    
    results['Black text on medium gray'] = _checkContrast(
      'Black text on medium gray background',
      AppColors.primaryAccent,
      AppColors.mediumGray,
    );
    
    // Focus indicators with black theme
    results['Black focus indicator'] = _checkContrast(
      'Black focus indicator on white background',
      AppColors.primaryAccent,
      AppColors.primaryWhite,
    );
    
    results['White focus on black'] = _checkContrast(
      'White focus indicator on black background',
      AppColors.primaryWhite,
      AppColors.primaryAccent,
    );
    
    return results;
  }

  /// Get the appropriate text color for black theme backgrounds
  static Color getAccessibleTextColorForBlackTheme(Color backgroundColor) {
    final whiteContrast = AccessibilityUtils.calculateContrastRatio(
      AppColors.primaryWhite,
      backgroundColor,
    );
    final blackContrast = AccessibilityUtils.calculateContrastRatio(
      AppColors.primaryAccent,
      backgroundColor,
    );
    
    // Return the color with better contrast, preferring black for light backgrounds
    if (blackContrast >= AccessibilityUtils.wcagAAContrastRatio) {
      return AppColors.primaryAccent;
    } else if (whiteContrast >= AccessibilityUtils.wcagAAContrastRatio) {
      return AppColors.primaryWhite;
    } else {
      // If neither meets AA standards, return the one with better contrast
      return blackContrast > whiteContrast ? AppColors.primaryAccent : AppColors.primaryWhite;
    }
  }

  /// Validate that black theme meets WCAG AA requirements
  static bool validateBlackThemeCompliance() {
    final results = validateBlackThemeContrast();
    return results.values.every((result) => result.meetsWCAGAA);
  }

  /// Get failing black theme combinations
  static List<ContrastResult> getFailingBlackThemeCombinations() {
    final results = validateBlackThemeContrast();
    return results.values.where((result) => !result.meetsWCAGAA).toList();
  }

  /// Internal method to check contrast and create result
  static ContrastResult _checkContrast(
    String description,
    Color foreground,
    Color background,
  ) {
    final ratio = AccessibilityUtils.calculateContrastRatio(foreground, background);
    final meetsAA = AccessibilityUtils.meetsWCAGAA(foreground, background);
    final meetsAAA = AccessibilityUtils.meetsWCAGAAA(foreground, background);
    
    return ContrastResult(
      description: description,
      foregroundColor: foreground,
      backgroundColor: background,
      contrastRatio: ratio,
      meetsWCAGAA: meetsAA,
      meetsWCAGAAA: meetsAAA,
    );
  }

  /// Generate a contrast report for debugging
  static String generateContrastReport() {
    final results = validateDesignSystemContrast();
    final buffer = StringBuffer();
    
    buffer.writeln('=== WCAG Contrast Compliance Report ===\n');
    
    var passedAA = 0;
    var passedAAA = 0;
    var total = results.length;
    
    for (final entry in results.entries) {
      final result = entry.value;
      buffer.writeln('${result.description}:');
      buffer.writeln('  Contrast Ratio: ${result.contrastRatio.toStringAsFixed(2)}:1');
      buffer.writeln('  WCAG AA: ${result.meetsWCAGAA ? "✓ PASS" : "✗ FAIL"}');
      buffer.writeln('  WCAG AAA: ${result.meetsWCAGAAA ? "✓ PASS" : "✗ FAIL"}');
      buffer.writeln();
      
      if (result.meetsWCAGAA) passedAA++;
      if (result.meetsWCAGAAA) passedAAA++;
    }
    
    buffer.writeln('=== Summary ===');
    buffer.writeln('Total combinations tested: $total');
    buffer.writeln('WCAG AA compliance: $passedAA/$total (${(passedAA / total * 100).toStringAsFixed(1)}%)');
    buffer.writeln('WCAG AAA compliance: $passedAAA/$total (${(passedAAA / total * 100).toStringAsFixed(1)}%)');
    
    return buffer.toString();
  }

  /// Get failing contrast combinations
  static List<ContrastResult> getFailingCombinations() {
    final results = validateDesignSystemContrast();
    return results.values.where((result) => !result.meetsWCAGAA).toList();
  }

  /// Suggest alternative colors for failing combinations
  static List<ColorSuggestion> suggestAlternativeColors(ContrastResult failingResult) {
    final suggestions = <ColorSuggestion>[];
    
    // Try darkening the foreground color
    final darkerForeground = _darkenColor(failingResult.foregroundColor, 0.2);
    if (AccessibilityUtils.meetsWCAGAA(darkerForeground, failingResult.backgroundColor)) {
      suggestions.add(ColorSuggestion(
        description: 'Darken foreground color',
        suggestedForeground: darkerForeground,
        suggestedBackground: failingResult.backgroundColor,
        contrastRatio: AccessibilityUtils.calculateContrastRatio(
          darkerForeground,
          failingResult.backgroundColor,
        ),
      ));
    }
    
    // Try lightening the background color
    final lighterBackground = _lightenColor(failingResult.backgroundColor, 0.2);
    if (AccessibilityUtils.meetsWCAGAA(failingResult.foregroundColor, lighterBackground)) {
      suggestions.add(ColorSuggestion(
        description: 'Lighten background color',
        suggestedForeground: failingResult.foregroundColor,
        suggestedBackground: lighterBackground,
        contrastRatio: AccessibilityUtils.calculateContrastRatio(
          failingResult.foregroundColor,
          lighterBackground,
        ),
      ));
    }
    
    return suggestions;
  }

  /// Darken a color by a given factor
  static Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * (1 - factor)).clamp(0.0, 1.0)).toColor();
  }

  /// Lighten a color by a given factor
  static Color _lightenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + factor).clamp(0.0, 1.0)).toColor();
  }
}

/// Result of a contrast check
class ContrastResult {
  final String description;
  final Color foregroundColor;
  final Color backgroundColor;
  final double contrastRatio;
  final bool meetsWCAGAA;
  final bool meetsWCAGAAA;

  const ContrastResult({
    required this.description,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.contrastRatio,
    required this.meetsWCAGAA,
    required this.meetsWCAGAAA,
  });

  @override
  String toString() {
    return '$description: ${contrastRatio.toStringAsFixed(2)}:1 '
           '(AA: ${meetsWCAGAA ? "PASS" : "FAIL"}, '
           'AAA: ${meetsWCAGAAA ? "PASS" : "FAIL"})';
  }
}

/// Color suggestion for improving contrast
class ColorSuggestion {
  final String description;
  final Color suggestedForeground;
  final Color suggestedBackground;
  final double contrastRatio;

  const ColorSuggestion({
    required this.description,
    required this.suggestedForeground,
    required this.suggestedBackground,
    required this.contrastRatio,
  });

  @override
  String toString() {
    return '$description: ${contrastRatio.toStringAsFixed(2)}:1';
  }
}