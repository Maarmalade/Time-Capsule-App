import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Utility class for accessibility enhancements and testing
class AccessibilityUtils {
  /// WCAG AA contrast ratio requirement (4.5:1)
  static const double wcagAAContrastRatio = 4.5;
  
  /// WCAG AAA contrast ratio requirement (7:1)
  static const double wcagAAAContrastRatio = 7.0;

  /// Calculate the contrast ratio between two colors
  /// Returns a value between 1 and 21, where higher values indicate better contrast
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if color combination meets WCAG AA standards
  static bool meetsWCAGAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= wcagAAContrastRatio;
  }

  /// Check if color combination meets WCAG AAA standards
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= wcagAAAContrastRatio;
  }

  /// Calculate relative luminance of a color
  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round() / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round() / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round() / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return ((component + 0.055) / 1.055).pow(2.4);
    }
  }

  /// Create semantic label for interactive elements
  static String createSemanticLabel({
    required String label,
    String? hint,
    String? value,
    bool isButton = false,
    bool isSelected = false,
    bool isExpanded = false,
  }) {
    final buffer = StringBuffer(label);
    
    if (value != null && value.isNotEmpty) {
      buffer.write(', $value');
    }
    
    if (isButton) {
      buffer.write(', button');
    }
    
    if (isSelected) {
      buffer.write(', selected');
    }
    
    if (isExpanded) {
      buffer.write(', expanded');
    }
    
    if (hint != null && hint.isNotEmpty) {
      buffer.write(', $hint');
    }
    
    return buffer.toString();
  }

  /// Create accessibility hint for complex interactions
  static String createAccessibilityHint({
    required String action,
    String? result,
    String? navigation,
  }) {
    final buffer = StringBuffer(action);
    
    if (result != null) {
      buffer.write(' to $result');
    }
    
    if (navigation != null) {
      buffer.write(', navigates to $navigation');
    }
    
    return buffer.toString();
  }

  /// Validate minimum touch target size (44x44 dp)
  static bool validateTouchTargetSize(Size size) {
    const minTouchTarget = 44.0;
    return size.width >= minTouchTarget && size.height >= minTouchTarget;
  }

  /// Create semantics properties for interactive elements
  static SemanticsProperties createSemanticsProperties({
    required String label,
    String? hint,
    String? value,
    bool button = false,
    bool focusable = true,
    bool enabled = true,
    VoidCallback? onTap,
    String? increasedValue,
    String? decreasedValue,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
  }) {
    return SemanticsProperties(
      label: label,
      hint: hint,
      value: value,
      button: button,
      focusable: focusable,
      enabled: enabled,
      onTap: onTap,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
    );
  }
}

/// Extension to add pow method to double
extension DoubleExtension on double {
  double pow(double exponent) {
    return math.pow(this, exponent).toDouble();
  }
}