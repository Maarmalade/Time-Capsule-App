import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// AppInputs defines the complete input field styling system for the Time Capsule app
/// following Material 3 principles with professional styling and accessibility compliance
class AppInputs {
  // Private constructor to prevent instantiation
  AppInputs._();

  // Input Field Height Constants
  static const double inputHeightLarge = 56.0;
  static const double inputHeightMedium = 48.0;
  static const double inputHeightSmall = 40.0;

  // Input Field Padding Constants
  static const EdgeInsets inputPaddingLarge = EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
  static const EdgeInsets inputPaddingMedium = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets inputPaddingSmall = EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);

  // Input Text Style
  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle helperTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Standard Input Decoration Theme
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.softGray,
        contentPadding: inputPaddingMedium,
        
        // Border configurations
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide.none,
        ),
        
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide.none,
        ),
        
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 2.0,
          ),
        ),
        
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 2.0,
          ),
        ),
        
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 2.0,
          ),
        ),
        
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide.none,
        ),
        
        // Text styles
        labelStyle: labelTextStyle.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: labelTextStyle.copyWith(color: AppColors.primaryAccent),
        hintStyle: inputTextStyle.copyWith(color: AppColors.textTertiary),
        helperStyle: helperTextStyle.copyWith(color: AppColors.textSecondary),
        errorStyle: helperTextStyle.copyWith(color: AppColors.errorRed),
        
        // Colors
        focusColor: AppColors.primaryAccent,
        hoverColor: AppColors.hoverOverlay,
        
        // Icon theme
        iconColor: AppColors.textSecondary,
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      );

  /// Standard Text Field Decoration
  static InputDecoration get standardDecoration => InputDecoration(
        filled: true,
        fillColor: AppColors.softGray,
        contentPadding: inputPaddingMedium,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 2.0,
          ),
        ),
        labelStyle: labelTextStyle.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: labelTextStyle.copyWith(color: AppColors.primaryAccent),
        hintStyle: inputTextStyle.copyWith(color: AppColors.textTertiary),
        helperStyle: helperTextStyle.copyWith(color: AppColors.textSecondary),
        errorStyle: helperTextStyle.copyWith(color: AppColors.errorRed),
      );

  /// Outlined Input Decoration - Alternative style with visible borders
  static InputDecoration get outlinedDecoration => InputDecoration(
        filled: false,
        contentPadding: inputPaddingMedium,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.borderMedium,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.borderMedium,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 2.0,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(
            color: AppColors.borderMedium.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        labelStyle: labelTextStyle.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: labelTextStyle.copyWith(color: AppColors.primaryAccent),
        hintStyle: inputTextStyle.copyWith(color: AppColors.textTertiary),
        helperStyle: helperTextStyle.copyWith(color: AppColors.textSecondary),
        errorStyle: helperTextStyle.copyWith(color: AppColors.errorRed),
      );

  /// Search Input Decoration - Specialized for search fields
  static InputDecoration get searchDecoration => InputDecoration(
        filled: true,
        fillColor: AppColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 2.0,
          ),
        ),
        hintStyle: inputTextStyle.copyWith(color: AppColors.textTertiary),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textTertiary,
          size: 20.0,
        ),
      );

  // Input Size Variants

  /// Large Input Decoration
  static InputDecoration getLargeInputDecoration(InputDecoration baseDecoration) {
    return baseDecoration.copyWith(
      contentPadding: inputPaddingLarge,
    );
  }

  /// Small Input Decoration
  static InputDecoration getSmallInputDecoration(InputDecoration baseDecoration) {
    return baseDecoration.copyWith(
      contentPadding: inputPaddingSmall,
    );
  }

  // Specialized Input Decorations

  /// Password Input Decoration with visibility toggle
  static InputDecoration getPasswordDecoration({
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? labelText,
    String? hintText,
  }) {
    return standardDecoration.copyWith(
      labelText: labelText,
      hintText: hintText,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility : Icons.visibility_off,
          color: AppColors.textSecondary,
          size: 20.0,
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }

  /// Email Input Decoration with email icon
  static InputDecoration getEmailDecoration({
    String? labelText,
    String? hintText,
  }) {
    return standardDecoration.copyWith(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: AppColors.textSecondary,
        size: 20.0,
      ),
    );
  }

  /// Phone Input Decoration with phone icon
  static InputDecoration getPhoneDecoration({
    String? labelText,
    String? hintText,
  }) {
    return standardDecoration.copyWith(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: const Icon(
        Icons.phone_outlined,
        color: AppColors.textSecondary,
        size: 20.0,
      ),
    );
  }

  /// Multiline Input Decoration for text areas
  static InputDecoration getMultilineDecoration({
    String? labelText,
    String? hintText,
    int maxLines = 4,
  }) {
    return standardDecoration.copyWith(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    );
  }

  // Validation States

  /// Success Input Decoration
  static InputDecoration getSuccessDecoration(InputDecoration baseDecoration) {
    return baseDecoration.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(
          color: AppColors.successGreen,
          width: 2.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(
          color: AppColors.successGreen,
          width: 2.0,
        ),
      ),
      suffixIcon: const Icon(
        Icons.check_circle_outline,
        color: AppColors.successGreen,
        size: 20.0,
      ),
    );
  }

  /// Warning Input Decoration
  static InputDecoration getWarningDecoration(InputDecoration baseDecoration) {
    return baseDecoration.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(
          color: AppColors.warningAmber,
          width: 2.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(
          color: AppColors.warningAmber,
          width: 2.0,
        ),
      ),
      suffixIcon: const Icon(
        Icons.warning_outlined,
        color: AppColors.warningAmber,
        size: 20.0,
      ),
    );
  }

  // Utility Methods

  /// Creates a TextFormField with standard styling
  static Widget createStandardTextField({
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    int? maxLines = 1,
    int? maxLength,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      style: inputTextStyle.copyWith(
        color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
      ),
      decoration: standardDecoration.copyWith(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        fillColor: enabled ? AppColors.softGray : AppColors.lightGray,
      ),
    );
  }

  /// Creates a search TextField with specialized styling
  static Widget createSearchField({
    String? hintText = 'Search...',
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: inputTextStyle,
      decoration: searchDecoration.copyWith(
        hintText: hintText,
        suffixIcon: controller?.text.isNotEmpty == true && onClear != null
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.textTertiary,
                  size: 20.0,
                ),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }

  // Dropdown and Selection Themes

  /// Dropdown Button Theme for black theme integration
  static ButtonStyle get dropdownButtonStyle => ButtonStyle(
        textStyle: WidgetStateProperty.all(
          inputTextStyle.copyWith(color: AppColors.textPrimary),
        ),
        foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        backgroundColor: WidgetStateProperty.all(AppColors.surfacePrimary),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.hoverOverlay;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.pressedOverlay;
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(
            color: AppColors.borderMedium,
            width: 1.0,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: AppSpacing.inputRadius,
          ),
        ),
      );

  /// Dropdown Menu Theme for black theme integration
  static MenuThemeData get dropdownMenuTheme => MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surfacePrimary),
          elevation: WidgetStateProperty.all(8.0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: AppSpacing.inputRadius,
            ),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(
              color: AppColors.borderLight,
              width: 1.0,
            ),
          ),
        ),
      );

  /// Selection colors for text fields and dropdowns
  static Color get selectionColor => AppColors.primaryAccent.withValues(alpha: 0.3);
  static Color get cursorColor => AppColors.primaryAccent;
  static Color get selectionHandleColor => AppColors.primaryAccent;

  // Accessibility Helpers

  /// Ensures input field meets accessibility requirements
  static InputDecoration ensureAccessibility(InputDecoration decoration) {
    return decoration.copyWith(
      // Ensure sufficient contrast for all text elements
      labelStyle: decoration.labelStyle?.copyWith(
        color: _ensureContrast(decoration.labelStyle?.color ?? AppColors.textSecondary),
      ),
      hintStyle: decoration.hintStyle?.copyWith(
        color: _ensureContrast(decoration.hintStyle?.color ?? AppColors.textTertiary),
      ),
      helperStyle: decoration.helperStyle?.copyWith(
        color: _ensureContrast(decoration.helperStyle?.color ?? AppColors.textSecondary),
      ),
    );
  }

  /// Helper method to ensure color contrast meets accessibility standards
  static Color _ensureContrast(Color color) {
    // Simple contrast check - in a real implementation, you'd use a proper contrast ratio calculation
    final luminance = color.computeLuminance();
    if (luminance < 0.5) {
      return color;
    }
    return AppColors.textSecondary;
  }

  // Form Field Builders

  /// Creates a complete form field with label, input, and helper text
  static Widget createFormField({
    required String label,
    String? hintText,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool required = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: RichText(
            text: TextSpan(
              text: label,
              style: labelTextStyle.copyWith(color: AppColors.textPrimary),
              children: required
                  ? [
                      TextSpan(
                        text: ' *',
                        style: labelTextStyle.copyWith(color: AppColors.errorRed),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        
        // Input field
        createStandardTextField(
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }
}