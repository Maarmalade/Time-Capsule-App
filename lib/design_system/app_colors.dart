import 'package:flutter/material.dart';

/// AppColors defines the complete color palette for the Time Capsule app
/// following Material 3 principles with a professional neutral palette
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Base Colors - Primary neutral palette
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGray = Color(0xFFF5F5F7);
  static const Color charcoalNavy = Color(0xFF1A1A2E);

  // Accent Color - Deep blue for highlights and CTAs
  static const Color accentBlue = Color(0xFF2E5BFF);

  // Neutral Grays - Extended gray scale for various UI elements
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color mediumGray = Color(0xFFE9ECEF);
  static const Color darkGray = Color(0xFF6C757D);
  static const Color textGray = Color(0xFF495057);

  // Semantic Colors - WCAG AA compliant versions for status indicators
  static const Color successGreen = Color(0xFF198754); // Darker green for better contrast
  static const Color warningAmber = Color(0xFF996F00); // Darker amber for better contrast
  static const Color errorRed = Color(0xFFDC3545);
  static const Color infoBlue = Color(0xFF0F5132);

  // Surface Colors - For different background levels
  static const Color surfacePrimary = primaryWhite;
  static const Color surfaceSecondary = softGray;
  static const Color surfaceTertiary = lightGray;

  // Text Colors - Semantic text color definitions
  static const Color textPrimary = charcoalNavy;
  static const Color textSecondary = textGray;
  static const Color textTertiary = darkGray;
  static const Color textOnAccent = primaryWhite;

  // Border Colors - For dividers and container borders
  static const Color borderLight = lightGray;
  static const Color borderMedium = mediumGray;
  static const Color borderDark = darkGray;

  // State Colors - For interactive element states
  static const Color hoverOverlay = Color(0x14000000); // 8% black
  static const Color pressedOverlay = Color(0x1F000000); // 12% black
  static const Color focusOverlay = Color(0x1F2E5BFF); // 12% accent blue
  static const Color disabledOverlay = Color(0x61000000); // 38% black

  // Shadow Colors - For elevation and depth
  static const Color shadowLight = Color(0x14000000); // 8% black
  static const Color shadowMedium = Color(0x1F000000); // 12% black
  static const Color shadowDark = Color(0x29000000); // 16% black

  /// Returns the appropriate text color for the given background color
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : primaryWhite;
  }

  /// Returns the appropriate overlay color for interactive states
  static Color getOverlayColor(Color baseColor, {required bool isPressed}) {
    return isPressed ? pressedOverlay : hoverOverlay;
  }

  /// Material 3 ColorScheme for light theme
  static ColorScheme get lightColorScheme => ColorScheme.light(
        primary: accentBlue,
        onPrimary: textOnAccent,
        secondary: textGray,
        onSecondary: primaryWhite,
        surface: surfacePrimary,
        onSurface: textPrimary,
        error: errorRed,
        onError: primaryWhite,
        brightness: Brightness.light,
      );
}