import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTypography defines the complete typography system for the Time Capsule app
/// using Inter as primary font with Roboto as fallback, following Material 3 principles
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // Font Family Configuration
  static const String primaryFontFamily = 'Inter';
  static const String fallbackFontFamily = 'Roboto';

  // Font Weights - Professional weight scale
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Display Styles - For large, prominent text
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: semiBold,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: semiBold,
        height: 1.2,
        letterSpacing: -0.25,
      );

  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: medium,
        height: 1.3,
        letterSpacing: 0,
      );

  // Headline Styles - For section headers and page titles
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: semiBold,
        height: 1.3,
        letterSpacing: -0.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0,
      );

  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0,
      );

  // Title Styles - For card titles and component headers
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0.1,
      );

  // Body Styles - For main content and descriptions
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: regular,
        height: 1.5,
        letterSpacing: 0,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: regular,
        height: 1.5,
        letterSpacing: 0,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: regular,
        height: 1.4,
        letterSpacing: 0,
      );

  // Label Styles - For buttons, form labels, and captions
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0.1,
      );

  // Specialized Styles - For specific use cases
  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: regular,
        height: 1.4,
        letterSpacing: 0,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: medium,
        height: 1.4,
        letterSpacing: 0.5,
      );

  /// Complete Material 3 TextTheme configuration
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );

  /// Fallback TextTheme using Roboto when Inter is not available
  static TextTheme get fallbackTextTheme => TextTheme(
        displayLarge: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: semiBold,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: semiBold,
          height: 1.2,
          letterSpacing: -0.25,
        ),
        displaySmall: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: medium,
          height: 1.3,
          letterSpacing: 0,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: semiBold,
          height: 1.3,
          letterSpacing: -0.25,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0,
        ),
        headlineSmall: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        titleSmall: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: regular,
          height: 1.5,
          letterSpacing: 0,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: regular,
          height: 1.5,
          letterSpacing: 0,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: regular,
          height: 1.4,
          letterSpacing: 0,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: medium,
          height: 1.4,
          letterSpacing: 0.1,
        ),
      );
}