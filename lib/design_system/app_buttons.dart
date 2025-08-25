import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// AppButtons defines the complete button styling system for the Time Capsule app
/// following Material 3 principles with professional styling and accessibility compliance
class AppButtons {
  // Private constructor to prevent instantiation
  AppButtons._();

  // Button Height Constants
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightSmall = 36.0;

  // Button Padding Constants
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
  static const EdgeInsets buttonPaddingMedium = EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

  // Button Text Style
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  /// Primary Button Style - Main call-to-action buttons
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textOnAccent,
        elevation: AppSpacing.elevation2,
        shadowColor: AppColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        padding: buttonPaddingMedium,
        minimumSize: const Size(0, buttonHeightMedium),
        textStyle: buttonTextStyle,
        // State-specific styling
      ).copyWith(
        // Hover state
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.accentBlue.withOpacity(0.38);
          }
          if (states.contains(WidgetState.pressed)) {
            return _darkenColor(AppColors.accentBlue, 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return _darkenColor(AppColors.accentBlue, 0.08);
          }
          return AppColors.accentBlue;
        }),
        // Elevation states
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          if (states.contains(WidgetState.disabled)) return 0;
          if (states.contains(WidgetState.pressed)) return AppSpacing.elevation1;
          if (states.contains(WidgetState.hovered)) return AppSpacing.elevation3;
          return AppSpacing.elevation2;
        }),
        // Overlay color for ripple effect
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.pressedOverlay;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.hoverOverlay;
          }
          return Colors.transparent;
        }),
      );

  /// Secondary Button Style - Alternative actions
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.accentBlue,
        side: const BorderSide(
          color: AppColors.accentBlue,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        padding: buttonPaddingMedium,
        minimumSize: const Size(0, buttonHeightMedium),
        textStyle: buttonTextStyle,
      ).copyWith(
        // Background color states
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentBlue.withOpacity(0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.accentBlue.withOpacity(0.08);
          }
          return Colors.transparent;
        }),
        // Foreground color states
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.accentBlue.withOpacity(0.38);
          }
          return AppColors.accentBlue;
        }),
        // Border color states
        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: AppColors.accentBlue.withOpacity(0.38),
              width: 1.5,
            );
          }
          if (states.contains(WidgetState.pressed)) {
            return const BorderSide(
              color: AppColors.accentBlue,
              width: 2.0,
            );
          }
          return const BorderSide(
            color: AppColors.accentBlue,
            width: 1.5,
          );
        }),
      );

  /// Text Button Style - Subtle actions and links
  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.accentBlue,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        minimumSize: const Size(0, 36.0),
        textStyle: buttonTextStyle,
      ).copyWith(
        // Background color states
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentBlue.withOpacity(0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.accentBlue.withOpacity(0.08);
          }
          return Colors.transparent;
        }),
        // Foreground color states
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.accentBlue.withOpacity(0.38);
          }
          return AppColors.accentBlue;
        }),
      );

  /// Destructive Button Style - For delete/remove actions
  static ButtonStyle get destructiveButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.errorRed,
        foregroundColor: AppColors.textOnAccent,
        elevation: AppSpacing.elevation2,
        shadowColor: AppColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        padding: buttonPaddingMedium,
        minimumSize: const Size(0, buttonHeightMedium),
        textStyle: buttonTextStyle,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.errorRed.withOpacity(0.38);
          }
          if (states.contains(WidgetState.pressed)) {
            return _darkenColor(AppColors.errorRed, 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return _darkenColor(AppColors.errorRed, 0.08);
          }
          return AppColors.errorRed;
        }),
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          if (states.contains(WidgetState.disabled)) return 0;
          if (states.contains(WidgetState.pressed)) return AppSpacing.elevation1;
          if (states.contains(WidgetState.hovered)) return AppSpacing.elevation3;
          return AppSpacing.elevation2;
        }),
      );

  /// Icon Button Style - For icon-only buttons
  static ButtonStyle get iconButtonStyle => IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.pressedOverlay;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.hoverOverlay;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textPrimary.withOpacity(0.38);
          }
          return AppColors.textPrimary;
        }),
      );

  /// Floating Action Button Style
  static ButtonStyle get fabStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textOnAccent,
        elevation: AppSpacing.elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        padding: const EdgeInsets.all(16.0),
        minimumSize: const Size(56.0, 56.0),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return _darkenColor(AppColors.accentBlue, 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return _darkenColor(AppColors.accentBlue, 0.08);
          }
          return AppColors.accentBlue;
        }),
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          if (states.contains(WidgetState.pressed)) return AppSpacing.elevation2;
          if (states.contains(WidgetState.hovered)) return AppSpacing.elevation4;
          return AppSpacing.elevation3;
        }),
      );

  // Button Size Variants

  /// Large Button Style - For prominent actions
  static ButtonStyle getLargeButtonStyle(ButtonStyle baseStyle) {
    return baseStyle.copyWith(
      padding: WidgetStateProperty.all(buttonPaddingLarge),
      minimumSize: WidgetStateProperty.all(const Size(0, buttonHeightLarge)),
      textStyle: WidgetStateProperty.all(
        buttonTextStyle.copyWith(fontSize: 16),
      ),
    );
  }

  /// Small Button Style - For compact layouts
  static ButtonStyle getSmallButtonStyle(ButtonStyle baseStyle) {
    return baseStyle.copyWith(
      padding: WidgetStateProperty.all(buttonPaddingSmall),
      minimumSize: WidgetStateProperty.all(const Size(0, buttonHeightSmall)),
      textStyle: WidgetStateProperty.all(
        buttonTextStyle.copyWith(fontSize: 12),
      ),
    );
  }

  // Utility Methods

  /// Creates a button with loading state
  static Widget createLoadingButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
    ButtonStyle? style,
    Widget? icon,
  }) {
    final buttonStyle = style ?? primaryButtonStyle;
    
    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: buttonStyle,
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              buttonStyle.foregroundColor?.resolve({}) ?? AppColors.textOnAccent,
            ),
          ),
        ),
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: buttonStyle,
        icon: icon,
        label: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(text),
    );
  }

  /// Creates a button with custom width
  static Widget createFullWidthButton({
    required String text,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    Widget? icon,
  }) {
    final buttonStyle = (style ?? primaryButtonStyle).copyWith(
      minimumSize: WidgetStateProperty.all(const Size(double.infinity, buttonHeightMedium)),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: buttonStyle,
        icon: icon,
        label: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(text),
    );
  }

  // Helper Methods

  /// Darkens a color by the specified amount (0.0 to 1.0)
  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Lightens a color by the specified amount (0.0 to 1.0)
  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }

  // Theme Integration

  /// ElevatedButtonThemeData for Material theme
  static ElevatedButtonThemeData get elevatedButtonTheme => ElevatedButtonThemeData(
        style: primaryButtonStyle,
      );

  /// OutlinedButtonThemeData for Material theme
  static OutlinedButtonThemeData get outlinedButtonTheme => OutlinedButtonThemeData(
        style: secondaryButtonStyle,
      );

  /// TextButtonThemeData for Material theme
  static TextButtonThemeData get textButtonTheme => TextButtonThemeData(
        style: textButtonStyle,
      );

  /// IconButtonThemeData for Material theme
  static IconButtonThemeData get iconButtonTheme => IconButtonThemeData(
        style: iconButtonStyle,
      );

  /// FloatingActionButtonThemeData for Material theme
  static FloatingActionButtonThemeData get floatingActionButtonTheme => 
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textOnAccent,
        elevation: AppSpacing.elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      );
}