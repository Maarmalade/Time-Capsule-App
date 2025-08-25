import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppIcons provides consistent icon sizing, colors, and theme configuration
/// for Material Icons usage throughout the Time Capsule application.
/// 
/// This class ensures visual consistency and accessibility compliance
/// for all iconography in the app.
class AppIcons {
  AppIcons._();

  // Icon Sizes
  /// Extra small icon size for compact UI elements
  static const double sizeXs = 16.0;
  
  /// Small icon size for secondary actions and indicators
  static const double sizeSm = 20.0;
  
  /// Standard icon size for most UI elements
  static const double sizeMd = 24.0;
  
  /// Large icon size for prominent actions and headers
  static const double sizeLg = 32.0;
  
  /// Extra large icon size for hero elements and empty states
  static const double sizeXl = 48.0;

  // Icon Colors
  /// Primary icon color for main navigation and important actions
  static const Color primaryColor = AppColors.charcoalNavy;
  
  /// Secondary icon color for supporting elements and inactive states
  static const Color secondaryColor = AppColors.darkGray;
  
  /// Accent icon color for highlighted actions and active states
  static const Color accentColor = AppColors.accentBlue;
  
  /// Disabled icon color for non-interactive elements
  static const Color disabledColor = AppColors.mediumGray;
  
  /// Error icon color for validation and error states
  static const Color errorColor = AppColors.errorRed;
  
  /// Success icon color for confirmation and success states
  static const Color successColor = AppColors.successGreen;
  
  /// Warning icon color for caution and warning states
  static const Color warningColor = AppColors.warningAmber;
  
  /// Icon color for use on dark backgrounds
  static const Color onDarkColor = AppColors.primaryWhite;

  // Icon Theme Configuration
  /// Standard icon theme for consistent Material Icons usage
  static const IconThemeData iconTheme = IconThemeData(
    color: primaryColor,
    size: sizeMd,
  );

  /// Icon theme for app bars and navigation headers
  static const IconThemeData appBarIconTheme = IconThemeData(
    color: primaryColor,
    size: sizeMd,
  );

  /// Icon theme for bottom navigation
  static const IconThemeData bottomNavIconTheme = IconThemeData(
    size: sizeMd,
  );

  /// Icon theme for floating action buttons
  static const IconThemeData fabIconTheme = IconThemeData(
    color: onDarkColor,
    size: sizeMd,
  );

  // Utility Methods
  /// Creates an icon with consistent styling and accessibility
  /// 
  /// [iconData] The Material Icon to display
  /// [size] Optional custom size, defaults to standard size
  /// [color] Optional custom color, defaults to primary color
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget icon(
    IconData iconData, {
    double? size,
    Color? color,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: size ?? sizeMd,
      color: color ?? primaryColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates a small icon with consistent styling
  /// 
  /// [iconData] The Material Icon to display
  /// [color] Optional custom color, defaults to secondary color
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget smallIcon(
    IconData iconData, {
    Color? color,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: sizeSm,
      color: color ?? secondaryColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates a large icon with consistent styling
  /// 
  /// [iconData] The Material Icon to display
  /// [color] Optional custom color, defaults to primary color
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget largeIcon(
    IconData iconData, {
    Color? color,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: sizeLg,
      color: color ?? primaryColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates an accent-colored icon for highlighted actions
  /// 
  /// [iconData] The Material Icon to display
  /// [size] Optional custom size, defaults to standard size
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget accentIcon(
    IconData iconData, {
    double? size,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: size ?? sizeMd,
      color: accentColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates an error-colored icon for validation states
  /// 
  /// [iconData] The Material Icon to display
  /// [size] Optional custom size, defaults to standard size
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget errorIcon(
    IconData iconData, {
    double? size,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: size ?? sizeMd,
      color: errorColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates a success-colored icon for confirmation states
  /// 
  /// [iconData] The Material Icon to display
  /// [size] Optional custom size, defaults to standard size
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget successIcon(
    IconData iconData, {
    double? size,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: size ?? sizeMd,
      color: successColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates a warning-colored icon for caution states
  /// 
  /// [iconData] The Material Icon to display
  /// [size] Optional custom size, defaults to standard size
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget warningIcon(
    IconData iconData, {
    double? size,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: size ?? sizeMd,
      color: warningColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates a disabled icon for non-interactive elements
  /// 
  /// [iconData] The Material Icon to display
  /// [size] Optional custom size, defaults to standard size
  /// [semanticLabel] Required accessibility label for screen readers
  static Widget disabledIcon(
    IconData iconData, {
    double? size,
    required String semanticLabel,
  }) {
    return Icon(
      iconData,
      size: size ?? sizeMd,
      color: disabledColor,
      semanticLabel: semanticLabel,
    );
  }

  // Common Icon Definitions with Semantic Labels
  /// Navigation and UI Icons
  static Widget get backIcon => icon(
    Icons.arrow_back,
    semanticLabel: 'Go back',
  );

  static Widget get closeIcon => icon(
    Icons.close,
    semanticLabel: 'Close',
  );

  static Widget get menuIcon => icon(
    Icons.menu,
    semanticLabel: 'Open menu',
  );

  static Widget get moreVertIcon => icon(
    Icons.more_vert,
    semanticLabel: 'More options',
  );

  static Widget get searchIcon => icon(
    Icons.search,
    semanticLabel: 'Search',
  );

  static Widget get addIcon => accentIcon(
    Icons.add,
    semanticLabel: 'Add new item',
  );

  /// Memory and Content Icons
  static Widget get photoIcon => icon(
    Icons.photo,
    semanticLabel: 'Photo',
  );

  static Widget get videoIcon => icon(
    Icons.videocam,
    semanticLabel: 'Video',
  );

  static Widget get folderIcon => icon(
    Icons.folder,
    semanticLabel: 'Folder',
  );

  static Widget get shareIcon => icon(
    Icons.share,
    semanticLabel: 'Share',
  );

  static Widget get favoriteIcon => icon(
    Icons.favorite,
    color: errorColor,
    semanticLabel: 'Favorite',
  );

  static Widget get favoriteOutlineIcon => icon(
    Icons.favorite_border,
    semanticLabel: 'Add to favorites',
  );

  /// User and Social Icons
  static Widget get personIcon => icon(
    Icons.person,
    semanticLabel: 'Person',
  );

  static Widget get groupIcon => icon(
    Icons.group,
    semanticLabel: 'Group',
  );

  static Widget get notificationsIcon => icon(
    Icons.notifications,
    semanticLabel: 'Notifications',
  );

  static Widget get settingsIcon => icon(
    Icons.settings,
    semanticLabel: 'Settings',
  );

  /// Status and Feedback Icons
  static Widget get checkIcon => successIcon(
    Icons.check,
    semanticLabel: 'Success',
  );

  static Widget get errorOutlineIcon => errorIcon(
    Icons.error_outline,
    semanticLabel: 'Error',
  );

  static Widget get warningOutlineIcon => warningIcon(
    Icons.warning_outlined,
    semanticLabel: 'Warning',
  );

  static Widget get infoOutlineIcon => icon(
    Icons.info_outline,
    color: AppColors.infoBlue,
    semanticLabel: 'Information',
  );
}