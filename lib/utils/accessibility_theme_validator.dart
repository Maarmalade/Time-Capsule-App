import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'black_theme_accessibility.dart';
import 'accessibility_utils.dart';
import '../design_system/app_colors.dart';

/// Runtime validator for theme accessibility compliance
class AccessibilityThemeValidator {
  static bool _hasValidated = false;
  static List<String> _validationErrors = [];
  static List<String> _validationWarnings = [];

  /// Validate the current theme for accessibility compliance
  static AccessibilityValidationResult validateCurrentTheme(ThemeData theme) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    // Validate color scheme
    _validateColorScheme(theme.colorScheme, errors, warnings);
    
    // Validate button themes
    _validateButtonThemes(theme, errors, warnings);
    
    // Validate form control themes
    _validateFormControlThemes(theme, errors, warnings);
    
    // Validate focus indicators
    _validateFocusIndicators(theme, errors, warnings);
    
    // Validate text selection
    _validateTextSelection(theme, errors, warnings);
    
    // Generate suggestions based on findings
    _generateSuggestions(errors, warnings, suggestions);

    return AccessibilityValidationResult(
      isCompliant: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      totalChecks: _getTotalCheckCount(),
      passedChecks: _getTotalCheckCount() - errors.length,
    );
  }

  /// Validate color scheme for accessibility
  static void _validateColorScheme(
    ColorScheme colorScheme,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check primary color contrast
    final primaryContrast = AccessibilityUtils.calculateContrastRatio(
      colorScheme.onPrimary,
      colorScheme.primary,
    );
    if (primaryContrast < AccessibilityUtils.wcagAAContrastRatio) {
      errors.add(
        'Primary color contrast ratio ${primaryContrast.toStringAsFixed(2)}:1 '
        'does not meet WCAG AA requirement (4.5:1)',
      );
    } else if (primaryContrast < AccessibilityUtils.wcagAAAContrastRatio) {
      warnings.add(
        'Primary color contrast ratio ${primaryContrast.toStringAsFixed(2)}:1 '
        'meets WCAG AA but not AAA (7:1)',
      );
    }

    // Check surface color contrast
    final surfaceContrast = AccessibilityUtils.calculateContrastRatio(
      colorScheme.onSurface,
      colorScheme.surface,
    );
    if (surfaceContrast < AccessibilityUtils.wcagAAContrastRatio) {
      errors.add(
        'Surface color contrast ratio ${surfaceContrast.toStringAsFixed(2)}:1 '
        'does not meet WCAG AA requirement (4.5:1)',
      );
    }

    // Check error color contrast
    final errorContrast = AccessibilityUtils.calculateContrastRatio(
      colorScheme.onError,
      colorScheme.error,
    );
    if (errorContrast < AccessibilityUtils.wcagAAContrastRatio) {
      errors.add(
        'Error color contrast ratio ${errorContrast.toStringAsFixed(2)}:1 '
        'does not meet WCAG AA requirement (4.5:1)',
      );
    }
  }

  /// Validate button themes for accessibility
  static void _validateButtonThemes(
    ThemeData theme,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check elevated button theme
    final elevatedButtonStyle = theme.elevatedButtonTheme.style;
    if (elevatedButtonStyle != null) {
      final backgroundColor = elevatedButtonStyle.backgroundColor?.resolve({});
      final foregroundColor = elevatedButtonStyle.foregroundColor?.resolve({});
      
      if (backgroundColor != null && foregroundColor != null) {
        final contrast = AccessibilityUtils.calculateContrastRatio(
          foregroundColor,
          backgroundColor,
        );
        if (contrast < AccessibilityUtils.wcagAAContrastRatio) {
          errors.add(
            'Elevated button contrast ratio ${contrast.toStringAsFixed(2)}:1 '
            'does not meet WCAG AA requirement (4.5:1)',
          );
        }
      }
    }

    // Check outlined button theme
    final outlinedButtonStyle = theme.outlinedButtonTheme.style;
    if (outlinedButtonStyle != null) {
      final foregroundColor = outlinedButtonStyle.foregroundColor?.resolve({});
      final backgroundColor = theme.scaffoldBackgroundColor;
      
      if (foregroundColor != null) {
        final contrast = AccessibilityUtils.calculateContrastRatio(
          foregroundColor,
          backgroundColor,
        );
        if (contrast < AccessibilityUtils.wcagAAContrastRatio) {
          errors.add(
            'Outlined button contrast ratio ${contrast.toStringAsFixed(2)}:1 '
            'does not meet WCAG AA requirement (4.5:1)',
          );
        }
      }
    }
  }

  /// Validate form control themes for accessibility
  static void _validateFormControlThemes(
    ThemeData theme,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check checkbox theme
    final checkboxTheme = theme.checkboxTheme;
    final checkboxFillColor = checkboxTheme.fillColor?.resolve({WidgetState.selected});
    if (checkboxFillColor != null) {
      final checkColor = checkboxTheme.checkColor?.resolve({}) ?? Colors.white;
      final contrast = AccessibilityUtils.calculateContrastRatio(
        checkColor,
        checkboxFillColor,
      );
      if (contrast < AccessibilityUtils.wcagAAContrastRatio) {
        errors.add(
          'Checkbox contrast ratio ${contrast.toStringAsFixed(2)}:1 '
          'does not meet WCAG AA requirement (4.5:1)',
        );
      }
    }

    // Check switch theme
    final switchTheme = theme.switchTheme;
    final switchThumbColor = switchTheme.thumbColor?.resolve({WidgetState.selected});
    final switchTrackColor = switchTheme.trackColor?.resolve({WidgetState.selected});
    if (switchThumbColor != null && switchTrackColor != null) {
      final contrast = AccessibilityUtils.calculateContrastRatio(
        switchThumbColor,
        switchTrackColor,
      );
      if (contrast < 3.0) { // Lower requirement for switch components
        warnings.add(
          'Switch contrast ratio ${contrast.toStringAsFixed(2)}:1 '
          'is below recommended 3:1 for UI components',
        );
      }
    }
  }

  /// Validate focus indicators for accessibility
  static void _validateFocusIndicators(
    ThemeData theme,
    List<String> errors,
    List<String> warnings,
  ) {
    final focusColor = theme.focusColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    
    final contrast = AccessibilityUtils.calculateContrastRatio(
      focusColor,
      backgroundColor,
    );
    if (contrast < 3.0) { // WCAG requirement for focus indicators
      errors.add(
        'Focus indicator contrast ratio ${contrast.toStringAsFixed(2)}:1 '
        'does not meet WCAG requirement (3:1)',
      );
    }
    }

  /// Validate text selection theme for accessibility
  static void _validateTextSelection(
    ThemeData theme,
    List<String> errors,
    List<String> warnings,
  ) {
    final textSelectionTheme = theme.textSelectionTheme;
    final selectionColor = textSelectionTheme.selectionColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    
    if (selectionColor != null) {
      // Text selection should be visible but not too high contrast
      final contrast = AccessibilityUtils.calculateContrastRatio(
        selectionColor,
        backgroundColor,
      );
      if (contrast < 1.5) {
        warnings.add(
          'Text selection color may be too subtle '
          '(contrast ratio: ${contrast.toStringAsFixed(2)}:1)',
        );
      }
    }

    final cursorColor = textSelectionTheme.cursorColor;
    if (cursorColor != null) {
      final contrast = AccessibilityUtils.calculateContrastRatio(
        cursorColor,
        backgroundColor,
      );
      if (contrast < AccessibilityUtils.wcagAAContrastRatio) {
        errors.add(
          'Cursor color contrast ratio ${contrast.toStringAsFixed(2)}:1 '
          'does not meet WCAG AA requirement (4.5:1)',
        );
      }
    }
  }

  /// Generate suggestions based on validation results
  static void _generateSuggestions(
    List<String> errors,
    List<String> warnings,
    List<String> suggestions,
  ) {
    if (errors.isNotEmpty) {
      suggestions.add('Address all contrast ratio errors before deployment');
      suggestions.add('Use BlackThemeAccessibility.getFallbackColors() for alternatives');
    }

    if (warnings.isNotEmpty) {
      suggestions.add('Consider improving AAA compliance for better accessibility');
      suggestions.add('Test with users who have visual impairments');
    }

    if (errors.isEmpty && warnings.isEmpty) {
      suggestions.add('Theme meets accessibility standards');
      suggestions.add('Consider regular accessibility testing with real users');
    }
  }

  /// Get total number of accessibility checks performed
  static int _getTotalCheckCount() {
    return 8; // Number of different validation checks
  }

  /// Validate theme and log results in debug mode
  static void validateAndLog(ThemeData theme) {
    if (!kDebugMode || _hasValidated) return;

    final result = validateCurrentTheme(theme);
    _hasValidated = true;
    _validationErrors = result.errors;
    _validationWarnings = result.warnings;

    if (result.errors.isNotEmpty) {
      debugPrint('🚨 ACCESSIBILITY ERRORS:');
      for (final error in result.errors) {
        debugPrint('  ❌ $error');
      }
    }

    if (result.warnings.isNotEmpty) {
      debugPrint('⚠️  ACCESSIBILITY WARNINGS:');
      for (final warning in result.warnings) {
        debugPrint('  ⚠️  $warning');
      }
    }

    if (result.isCompliant) {
      debugPrint('✅ Theme passes accessibility validation');
    } else {
      debugPrint('❌ Theme has accessibility issues that need to be addressed');
    }

    debugPrint('📊 Accessibility Score: ${result.passedChecks}/${result.totalChecks}');
  }

  /// Get cached validation results
  static AccessibilityValidationResult? getCachedResults() {
    if (!_hasValidated) return null;
    
    return AccessibilityValidationResult(
      isCompliant: _validationErrors.isEmpty,
      errors: _validationErrors,
      warnings: _validationWarnings,
      suggestions: [],
      totalChecks: _getTotalCheckCount(),
      passedChecks: _getTotalCheckCount() - _validationErrors.length,
    );
  }

  /// Reset validation cache
  static void resetValidation() {
    _hasValidated = false;
    _validationErrors.clear();
    _validationWarnings.clear();
  }
}

/// Result of accessibility theme validation
class AccessibilityValidationResult {
  final bool isCompliant;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;
  final int totalChecks;
  final int passedChecks;

  const AccessibilityValidationResult({
    required this.isCompliant,
    required this.errors,
    required this.warnings,
    required this.suggestions,
    required this.totalChecks,
    required this.passedChecks,
  });

  double get compliancePercentage => (passedChecks / totalChecks) * 100;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Accessibility Validation Result:');
    buffer.writeln('  Compliant: ${isCompliant ? "✅ Yes" : "❌ No"}');
    buffer.writeln('  Score: $passedChecks/$totalChecks (${compliancePercentage.toStringAsFixed(1)}%)');
    
    if (errors.isNotEmpty) {
      buffer.writeln('  Errors: ${errors.length}');
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('  Warnings: ${warnings.length}');
    }
    
    return buffer.toString();
  }
}