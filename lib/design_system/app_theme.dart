import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_buttons.dart';
import 'app_inputs.dart';
import 'app_bars.dart';
import 'app_navigation.dart';

/// AppTheme provides the comprehensive theme configuration for the Time Capsule app
/// combining all design system components into a cohesive Material 3 theme
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Main light theme configuration for the Time Capsule app
  static ThemeData get lightTheme {
    return ThemeData(
      // Material 3 configuration
      useMaterial3: true,
      
      // Color scheme configuration with custom palette
      colorScheme: ColorScheme.light(
        primary: AppColors.accentBlue,
        onPrimary: AppColors.primaryWhite,
        secondary: AppColors.textGray,
        onSecondary: AppColors.primaryWhite,
        surface: AppColors.surfacePrimary,
        onSurface: AppColors.textPrimary,
        error: AppColors.errorRed,
        onError: AppColors.primaryWhite,
      ),
      
      // Typography configuration with Inter/Roboto fonts
      fontFamily: AppTypography.primaryFontFamily,
      textTheme: AppTypography.textTheme,
      
      // Primary color for legacy Material components
      primaryColor: AppColors.accentBlue,
      
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
        labelColor: AppColors.accentBlue,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: AppTypography.medium,
        ),
        unselectedLabelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: AppTypography.regular,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.accentBlue,
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
        selectedColor: AppColors.accentBlue.withValues(alpha: 0.12),
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
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoalNavy,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.primaryWhite,
        ),
        actionTextColor: AppColors.accentBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppSpacing.elevation3,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBlue,
        linearTrackColor: AppColors.surfaceSecondary,
        circularTrackColor: AppColors.surfaceSecondary,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return AppColors.surfaceSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue.withValues(alpha: 0.5);
          }
          return AppColors.borderMedium;
        }),
      ),
      
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.primaryWhite),
        side: const BorderSide(
          color: AppColors.borderMedium,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
      
      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return AppColors.borderMedium;
        }),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentBlue,
        inactiveTrackColor: AppColors.surfaceSecondary,
        thumbColor: AppColors.accentBlue,
        overlayColor: AppColors.accentBlue.withValues(alpha: 0.12),
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
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surfacePrimary),
          elevation: WidgetStateProperty.all(AppSpacing.elevation3),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
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
      splashColor: AppColors.accentBlue.withValues(alpha: 0.12),
      highlightColor: AppColors.accentBlue.withValues(alpha: 0.08),
      
      // Focus color
      focusColor: AppColors.accentBlue.withValues(alpha: 0.12),
      hoverColor: AppColors.hoverOverlay,
      
      // Disabled color
      disabledColor: AppColors.textTertiary.withValues(alpha: 0.38),
      
      // Unselected widget color
      unselectedWidgetColor: AppColors.textTertiary,
      
      // Secondary header color
      secondaryHeaderColor: AppColors.surfaceSecondary,
      
      // Text selection theme
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accentBlue,
        selectionColor: AppColors.accentBlue.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.accentBlue,
      ),
      
      // Extensions for Material 3
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(
          successColor: AppColors.successGreen,
          warningColor: AppColors.warningAmber,
          infoColor: AppColors.infoBlue,
        ),
      ],
    );
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



  /// System UI overlay style for light theme
  static SystemUiOverlayStyle get lightSystemUiOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfacePrimary,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.borderLight,
    );
  }

  /// System UI overlay style for dark theme
  static SystemUiOverlayStyle get darkSystemUiOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.charcoalNavy,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: AppColors.borderDark,
    );
  }

  /// Applies the appropriate system UI overlay style
  static void setSystemUIOverlayStyle({bool isDark = false}) {
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? darkSystemUiOverlayStyle : lightSystemUiOverlayStyle,
    );
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
}

/// Custom theme extension for additional colors not covered by Material 3
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color successColor;
  final Color warningColor;
  final Color infoColor;

  const AppThemeExtension({
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
  });

  @override
  AppThemeExtension copyWith({
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
  }) {
    return AppThemeExtension(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
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
    );
  }
}

/// Extension to access custom theme colors
extension AppThemeExtensionGetter on ThemeData {
  AppThemeExtension? get appColors => extension<AppThemeExtension>();
}