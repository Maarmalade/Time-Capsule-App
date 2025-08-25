import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// AppBars defines the complete app bar styling system for the Time Capsule app
/// following Material 3 principles with flat design and professional typography
class AppBars {
  // Private constructor to prevent instantiation
  AppBars._();

  /// Standard app bar theme configuration with flat design
  static AppBarTheme get appBarTheme => AppBarTheme(
        // Flat design with no elevation
        elevation: AppSpacing.elevation0,
        scrolledUnderElevation: AppSpacing.elevation1,
        
        // Background and surface colors
        backgroundColor: AppColors.surfacePrimary,
        surfaceTintColor: AppColors.surfacePrimary,
        foregroundColor: AppColors.textPrimary,
        
        // Title styling with professional typography
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTypography.medium,
        ),
        
        // Action and icon styling
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconSize,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconSize,
        ),
        
        // Center title for consistent layout
        centerTitle: false,
        
        // System UI overlay style for status bar
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        
        // Shape and border
        shape: const Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 0.5,
          ),
        ),
      );

  /// Large app bar theme for prominent pages
  static AppBarTheme get largeAppBarTheme => appBarTheme.copyWith(
        titleTextStyle: AppTypography.headlineLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTypography.semiBold,
        ),
      );

  /// Transparent app bar theme for overlay scenarios
  static AppBarTheme get transparentAppBarTheme => appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: AppSpacing.elevation0,
        scrolledUnderElevation: AppSpacing.elevation0,
        shape: null,
        foregroundColor: AppColors.primaryWhite,
        iconTheme: const IconThemeData(
          color: AppColors.primaryWhite,
          size: AppSpacing.iconSize,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primaryWhite,
          size: AppSpacing.iconSize,
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.primaryWhite,
          fontWeight: AppTypography.medium,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

  /// App bar with accent color theme for special pages
  static AppBarTheme get accentAppBarTheme => appBarTheme.copyWith(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.primaryWhite,
        iconTheme: const IconThemeData(
          color: AppColors.primaryWhite,
          size: AppSpacing.iconSize,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primaryWhite,
          size: AppSpacing.iconSize,
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.primaryWhite,
          fontWeight: AppTypography.medium,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

  /// Creates a custom app bar with consistent styling
  static PreferredSizeWidget createAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    AppBarTheme? theme,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
    );
  }

  /// Creates a large app bar with prominent title
  static PreferredSizeWidget createLargeAppBar({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    Widget? leading,
  }) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
      leading: leading,
      toolbarHeight: subtitle != null ? 80.0 : 64.0,
    );
  }

  /// Creates a search app bar with integrated search field
  static PreferredSizeWidget createSearchAppBar({
    required String hintText,
    required ValueChanged<String> onChanged,
    VoidCallback? onClear,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: TextField(
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                  iconSize: AppSpacing.iconSizeSmall,
                )
              : null,
        ),
      ),
      actions: actions,
    );
  }

  /// Creates an app bar with tab bar
  static PreferredSizeWidget createTabAppBar({
    required String title,
    required List<Tab> tabs,
    TabController? controller,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      bottom: TabBar(
        controller: controller,
        tabs: tabs,
        labelColor: AppColors.primaryAccent,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorColor: AppColors.primaryAccent,
        indicatorWeight: 2.0,
        dividerColor: AppColors.borderLight,
      ),
    );
  }

  /// Action button style for app bar actions
  static Widget createActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      color: color ?? AppColors.textPrimary,
      iconSize: AppSpacing.iconSize,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
    );
  }

  /// Menu button style for app bar leading
  static Widget createMenuButton({
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: onPressed,
      color: color ?? AppColors.textPrimary,
      iconSize: AppSpacing.iconSize,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
    );
  }

  /// Back button style for app bar leading
  static Widget createBackButton({
    VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onPressed,
      color: color ?? AppColors.textPrimary,
      iconSize: AppSpacing.iconSize,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
    );
  }
}