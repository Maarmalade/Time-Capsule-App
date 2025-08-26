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

  // Primary Accent Color - Black for highlights and CTAs
  static const Color primaryAccent = Color(0xFF000000);
  
  // Black Color Variations - For interactive states
  static const Color blackLight = Color(0xFF1A1A1A);    // Hover state
  static const Color blackDark = Color(0xFF0A0A0A);     // Pressed state
  static const Color blackDisabled = Color(0x61000000); // Disabled state (38% opacity)

  // Neutral Grays - Extended gray scale for various UI elements
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color mediumGray = Color(0xFFE9ECEF);
  static const Color darkGray = Color(0xFF6C757D);
  static const Color textGray = Color(0xFF495057);

  // Semantic Colors - Optimized for black theme integration and WCAG AA compliance
  static const Color successGreen = Color(0xFF198754); // Darker green for WCAG AA compliance
  static const Color warningAmber = Color(0xFF996F00); // Darker amber for WCAG AA compliance
  static const Color errorRed = Color(0xFFDC3545); // Maintained for consistency and visibility
  static const Color infoBlue = Color(0xFF495057); // Dark gray for WCAG AA compliance on white

  // Semantic Color Variations - For different backgrounds and contexts
  static const Color successGreenLight = Color(0xFFD4EDDA); // Light green background for success states
  static const Color successGreenDark = Color(0xFF155724); // Dark green text for success states
  static const Color warningAmberLight = Color(0xFFFFF3CD); // Light amber background for warning states
  static const Color warningAmberDark = Color(0xFF856404); // Dark amber text for warning states
  static const Color errorRedLight = Color(0xFFF8D7DA); // Light red background for error states
  static const Color errorRedDark = Color(0xFF721C24); // Dark red text for error states
  static const Color infoBlueLight = Color(0xFFD1ECF1); // Light blue background for info states
  static const Color infoBlueDark = Color(0xFF0C5460); // Dark blue text for info states

  // Favorite Colors - For favorite/starred content
  static const Color favoriteYellow = Color(0xFFFFD700); // Gold yellow for favorite stars
  static const Color favoriteYellowLight = Color(0xFFFFF8DC); // Light yellow background
  static const Color favoriteYellowDark = Color(0xFFB8860B); // Dark yellow for text/borders

  // Status Indicator Colors - Optimized for visibility with black elements
  static const Color statusActive = primaryAccent; // Black for active status
  static const Color statusInactive = Color(0xFF6C757D); // Gray for inactive status
  static const Color statusPending = warningAmber; // Amber for pending status
  static const Color statusSuccess = successGreen; // Green for success status
  static const Color statusError = errorRed; // Red for error status
  static const Color statusInfo = Color(0xFF17A2B8); // Bright blue for informational status visibility

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
  static const Color focusOverlay = Color(0x1F000000); // 12% black
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

  /// Returns the appropriate semantic color for the given status and context
  static Color getSemanticColor(String status, {bool isBackground = false}) {
    switch (status.toLowerCase()) {
      case 'success':
        return isBackground ? successGreenLight : successGreen;
      case 'warning':
        return isBackground ? warningAmberLight : warningAmber;
      case 'error':
        return isBackground ? errorRedLight : errorRed;
      case 'info':
        return isBackground ? infoBlueLight : infoBlue;
      default:
        return isBackground ? surfaceSecondary : textSecondary;
    }
  }

  /// Returns the appropriate text color for semantic backgrounds
  static Color getSemanticTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return successGreenDark;
      case 'warning':
        return warningAmberDark;
      case 'error':
        return errorRedDark;
      case 'info':
        return infoBlueDark;
      default:
        return textPrimary;
    }
  }

  /// Returns status indicator color that maintains visibility with black elements
  static Color getStatusIndicatorColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return statusActive;
      case 'inactive':
        return statusInactive;
      case 'pending':
        return statusPending;
      case 'success':
        return statusSuccess;
      case 'error':
        return statusError;
      case 'info':
        return statusInfo;
      default:
        return statusInactive;
    }
  }

  /// Validates that semantic colors maintain proper contrast with black elements
  static bool validateSemanticColorContrast(Color semanticColor, Color backgroundColor) {
    final luminance1 = semanticColor.computeLuminance();
    final luminance2 = backgroundColor.computeLuminance();
    final ratio = (luminance1 > luminance2) 
        ? (luminance1 + 0.05) / (luminance2 + 0.05)
        : (luminance2 + 0.05) / (luminance1 + 0.05);
    return ratio >= 4.5; // WCAG AA standard
  }

  /// Material 3 ColorScheme for light theme
  static ColorScheme get lightColorScheme => ColorScheme.light(
        primary: primaryAccent,
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