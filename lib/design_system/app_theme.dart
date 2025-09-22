import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_buttons.dart';
import 'app_inputs.dart';
import 'app_bars.dart';
import 'app_navigation.dart';
import '../utils/black_theme_accessibility.dart';
import '../utils/accessibility_theme_validator.dart';

/// AppTheme provides the comprehensive theme configuration for the Time Capsule app
/// combining all design system components into a cohesive Material 3 theme
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Main light theme configuration for the Time Capsule app
  static ThemeData get lightTheme {
    final theme = ThemeData(
      // Material 3 configuration
      useMaterial3: true,
      
      // Color scheme configuration with black primary color
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryAccent, // Black primary color
        onPrimary: AppColors.primaryWhite, // White text on black
        primaryContainer: AppColors.blackLight, // Light black for containers
        onPrimaryContainer: AppColors.primaryWhite, // White text on light black
        secondary: AppColors.textGray,
        onSecondary: AppColors.primaryWhite,
        secondaryContainer: AppColors.surfaceSecondary,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.darkGray,
        onTertiary: AppColors.primaryWhite,
        tertiaryContainer: AppColors.mediumGray,
        onTertiaryContainer: AppColors.textPrimary,
        surface: AppColors.surfacePrimary,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceSecondary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.borderMedium,
        outlineVariant: AppColors.borderLight,
        shadow: AppColors.shadowMedium,
        scrim: AppColors.shadowDark,
        inverseSurface: AppColors.charcoalNavy,
        onInverseSurface: AppColors.primaryWhite,
        inversePrimary: AppColors.primaryWhite,
        error: AppColors.errorRed,
        onError: AppColors.primaryWhite,
        errorContainer: AppColors.errorRedLight,
        onErrorContainer: AppColors.errorRedDark,
        brightness: Brightness.light,
      ),
      
      // Typography configuration with Inter/Roboto fonts
      fontFamily: AppTypography.primaryFontFamily,
      textTheme: AppTypography.textTheme,
      
      // Primary color for legacy Material components
      primaryColor: AppColors.primaryAccent,
      
      // Surface and background colors
      scaffoldBackgroundColor: AppColors.surfacePrimary,
      canvasColor: AppColors.surfacePrimary,
      cardColor: AppColors.surfacePrimary,
      
      // Divider and border colors
      dividerColor: AppColors.borderLight,
      
      // Button themes
      elevatedButtonTheme: AppButtons.elevatedButtonTheme,
      outlinedButtonTheme: AppButtons.outlinedButtonTheme,
      textButtonTheme: AppButtons.textButtonTheme,
      iconButtonTheme: AppButtons.iconButtonTheme,
      floatingActionButtonTheme: AppButtons.floatingActionButtonTheme,
      
      // Input field themes
      inputDecorationTheme: AppInputs.inputDecorationTheme,
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.surfacePrimary,
        shadowColor: AppColors.shadowMedium,
        elevation: AppSpacing.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
        margin: const EdgeInsets.all(AppSpacing.sm),
        clipBehavior: Clip.antiAlias,
      ),
      
      // App bar theme
      appBarTheme: AppBars.appBarTheme,
      
      // Navigation themes
      bottomNavigationBarTheme: AppNavigation.bottomNavTheme,
      navigationRailTheme: AppNavigation.navigationRailTheme,
      drawerTheme: AppNavigation.drawerTheme,
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryAccent,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: AppTypography.medium,
        ),
        unselectedLabelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: AppTypography.regular,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primaryAccent,
            width: 2.0,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.borderLight,
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        minLeadingWidth: AppSpacing.minTouchTarget,
        minVerticalPadding: AppSpacing.xs,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondary,
        selectedColor: AppColors.primaryAccent.withValues(alpha: 0.12),
        disabledColor: AppColors.surfaceSecondary.withValues(alpha: 0.38),
        deleteIconColor: AppColors.textSecondary,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        brightness: Brightness.light,
        elevation: AppSpacing.elevation1,
        pressElevation: AppSpacing.elevation2,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfacePrimary,
        elevation: AppSpacing.elevation5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      
      // Snackbar theme with black accent
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoalNavy,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.primaryWhite,
        ),
        actionTextColor: AppColors.primaryWhite, // White action text for better contrast on dark background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppSpacing.elevation3,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryAccent,
        linearTrackColor: AppColors.surfaceSecondary,
        circularTrackColor: AppColors.surfaceSecondary,
      ),
      
      // Switch theme with accessibility considerations
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.blackDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent;
          }
          return AppColors.surfaceSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.borderLight;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent.withValues(alpha: 0.5);
          }
          return AppColors.borderMedium;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.primaryAccent.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.hoverOverlay;
          }
          return Colors.transparent;
        }),
      ),
      
      // Checkbox theme with accessibility considerations
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.blackDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.primaryWhite.withValues(alpha: 0.38);
          }
          return AppColors.primaryWhite;
        }),
        side: const BorderSide(
          color: AppColors.borderMedium,
          width: 2.0,
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.primaryAccent.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.hoverOverlay;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
      
      // Radio theme with accessibility considerations
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.blackDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent;
          }
          return AppColors.borderMedium;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.primaryAccent.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.hoverOverlay;
          }
          return Colors.transparent;
        }),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryAccent,
        inactiveTrackColor: AppColors.surfaceSecondary,
        thumbColor: AppColors.primaryAccent,
        overlayColor: AppColors.primaryAccent.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.charcoalNavy,
        valueIndicatorTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.primaryWhite,
        ),
      ),
      
      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.charcoalNavy,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.primaryWhite,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
        preferBelow: true,
        verticalOffset: AppSpacing.sm,
      ),
      
      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfacePrimary,
        elevation: AppSpacing.elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      
      // Menu theme
      menuTheme: AppInputs.dropdownMenuTheme,
      
      // Dropdown button theme
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surfacePrimary),
          elevation: WidgetStateProperty.all(AppSpacing.elevation3),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(
              color: AppColors.borderLight,
              width: 1.0,
            ),
          ),
        ),
        inputDecorationTheme: AppInputs.inputDecorationTheme,
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfacePrimary,
        elevation: AppSpacing.elevation4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusLg),
            topRight: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Expansion tile theme
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: AppColors.surfacePrimary,
        collapsedBackgroundColor: AppColors.surfacePrimary,
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        collapsedTextColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      
      // Visual density for touch targets
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Material tap target size
      materialTapTargetSize: MaterialTapTargetSize.padded,
      
      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      
      // Splash color for ripple effects
      splashColor: AppColors.primaryAccent.withValues(alpha: 0.12),
      highlightColor: AppColors.primaryAccent.withValues(alpha: 0.08),
      
      // Focus color with accessibility considerations
      focusColor: AppColors.primaryAccent.withValues(alpha: 0.12),
      hoverColor: AppColors.hoverOverlay,
      
      // Disabled color
      disabledColor: AppColors.textTertiary.withValues(alpha: 0.38),
      
      // Unselected widget color
      unselectedWidgetColor: AppColors.textTertiary,
      
      // Secondary header color
      secondaryHeaderColor: AppColors.surfaceSecondary,
      
      // Text selection theme
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primaryAccent,
        selectionColor: AppColors.primaryAccent.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.primaryAccent,
      ),
      
      // Extensions for Material 3 with black theme integration
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(
          successColor: AppColors.successGreen,
          warningColor: AppColors.warningAmber,
          infoColor: AppColors.infoBlue,
          successBackgroundColor: AppColors.successGreenLight,
          warningBackgroundColor: AppColors.warningAmberLight,
          infoBackgroundColor: AppColors.infoBlueLight,
          successTextColor: AppColors.successGreenDark,
          warningTextColor: AppColors.warningAmberDark,
          infoTextColor: AppColors.infoBlueDark,
        ),
      ],
    );
    
    // Validate theme accessibility in debug mode
    AccessibilityThemeValidator.validateAndLog(theme);
    
    return theme;
  }

  /// Dark theme configuration (placeholder for future implementation)
  static ThemeData get darkTheme {
    // For now, return light theme as placeholder
    // This can be expanded later with proper dark mode colors
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      // Add dark theme specific configurations here when needed
    );
  }



  /// System UI overlay style for light theme with black accent integration
  static SystemUiOverlayStyle get lightSystemUiOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Dark icons on light status bar
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfacePrimary, // White navigation bar
      systemNavigationBarIconBrightness: Brightness.dark, // Dark icons on white nav bar
      systemNavigationBarDividerColor: AppColors.borderLight, // Light border for subtle separation
    );
  }

  /// System UI overlay style for dark theme with black accent integration
  static SystemUiOverlayStyle get darkSystemUiOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Light icons on dark status bar
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.charcoalNavy, // Dark navigation bar
      systemNavigationBarIconBrightness: Brightness.light, // Light icons on dark nav bar
      systemNavigationBarDividerColor: AppColors.borderDark, // Dark border for separation
    );
  }

  /// Applies the appropriate system UI overlay style
  static void setSystemUIOverlayStyle({bool isDark = false}) {
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? darkSystemUiOverlayStyle : lightSystemUiOverlayStyle,
    );
  }

  /// Applies system UI overlay style optimized for black theme
  static void setBlackThemeSystemUIOverlayStyle({bool isDark = false}) {
    final style = isDark ? darkSystemUiOverlayStyle : lightSystemUiOverlayStyle;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  /// Helper method to get the current theme mode
  static ThemeMode getThemeMode() {
    // For now, always return light mode
    // This can be expanded to read from user preferences
    return ThemeMode.light;
  }

  /// Helper method to determine if current theme is dark
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Helper method to get theme-appropriate colors
  static Color getAdaptiveColor(
    BuildContext context, {
    required Color lightColor,
    required Color darkColor,
  }) {
    return isDarkMode(context) ? darkColor : lightColor;
  }

  /// Helper method to get theme-appropriate text color
  static Color getAdaptiveTextColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: AppColors.textPrimary,
      darkColor: AppColors.primaryWhite,
    );
  }

  /// Helper method to get theme-appropriate surface color
  static Color getAdaptiveSurfaceColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: AppColors.surfacePrimary,
      darkColor: AppColors.charcoalNavy,
    );
  }

  /// Get accessible text color for a given background color
  static Color getAccessibleTextColor(Color backgroundColor) {
    return BlackThemeAccessibility.getBestTextColorForBackground(backgroundColor);
  }

  /// Get accessible focus indicator color for a given background
  static Color getAccessibleFocusColor(Color backgroundColor) {
    return BlackThemeAccessibility.getFocusIndicatorColor(backgroundColor);
  }

  /// Validate that the current theme meets accessibility standards
  static bool validateThemeAccessibility() {
    return BlackThemeAccessibility.validateBlackTheme().isCompliant;
  }

  /// Get fallback colors for insufficient contrast scenarios
  static Map<String, Color> getAccessibilityFallbackColors() {
    return BlackThemeAccessibility.getFallbackColors();
  }

  /// Generate accessibility report for the current theme
  static String generateAccessibilityReport() {
    return BlackThemeAccessibility.generateBlackThemeAccessibilityReport();
  }
}

/// Custom theme extension for additional colors not covered by Material 3
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final Color successBackgroundColor;
  final Color warningBackgroundColor;
  final Color infoBackgroundColor;
  final Color successTextColor;
  final Color warningTextColor;
  final Color infoTextColor;

  const AppThemeExtension({
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.successBackgroundColor,
    required this.warningBackgroundColor,
    required this.infoBackgroundColor,
    required this.successTextColor,
    required this.warningTextColor,
    required this.infoTextColor,
  });

  @override
  AppThemeExtension copyWith({
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? successBackgroundColor,
    Color? warningBackgroundColor,
    Color? infoBackgroundColor,
    Color? successTextColor,
    Color? warningTextColor,
    Color? infoTextColor,
  }) {
    return AppThemeExtension(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      successBackgroundColor: successBackgroundColor ?? this.successBackgroundColor,
      warningBackgroundColor: warningBackgroundColor ?? this.warningBackgroundColor,
      infoBackgroundColor: infoBackgroundColor ?? this.infoBackgroundColor,
      successTextColor: successTextColor ?? this.successTextColor,
      warningTextColor: warningTextColor ?? this.warningTextColor,
      infoTextColor: infoTextColor ?? this.infoTextColor,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      successBackgroundColor: Color.lerp(successBackgroundColor, other.successBackgroundColor, t)!,
      warningBackgroundColor: Color.lerp(warningBackgroundColor, other.warningBackgroundColor, t)!,
      infoBackgroundColor: Color.lerp(infoBackgroundColor, other.infoBackgroundColor, t)!,
      successTextColor: Color.lerp(successTextColor, other.successTextColor, t)!,
      warningTextColor: Color.lerp(warningTextColor, other.warningTextColor, t)!,
      infoTextColor: Color.lerp(infoTextColor, other.infoTextColor, t)!,
    );
  }
}

/// Extension to access custom theme colors
extension AppThemeExtensionGetter on ThemeData {
  AppThemeExtension? get appColors => extension<AppThemeExtension>();
}