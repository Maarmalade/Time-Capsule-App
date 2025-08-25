import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// DesignConstants provides additional design system utilities and constants
/// that complement the core color, typography, and spacing systems
class DesignConstants {
  // Private constructor to prevent instantiation
  DesignConstants._();

  // Shadow Definitions - Consistent shadow styles for elevation
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Card Shadows - Specific shadow configurations for cards
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardShadowHover = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Border Definitions - Consistent border styles
  static const Border borderLight = Border.fromBorderSide(
    BorderSide(color: AppColors.borderLight, width: 1),
  );

  static const Border borderMedium = Border.fromBorderSide(
    BorderSide(color: AppColors.borderMedium, width: 1),
  );

  static const Border borderDark = Border.fromBorderSide(
    BorderSide(color: AppColors.borderDark, width: 1),
  );

  static const Border borderAccent = Border.fromBorderSide(
    BorderSide(color: AppColors.primaryAccent, width: 2),
  );

  // Gradient Definitions - For special visual effects
  static const LinearGradient overlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x80000000),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryAccent,
      AppColors.blackLight,
    ],
  );

  // Opacity Values - Consistent opacity levels
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.60;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // Z-Index Values - For layering elements
  static const int zIndexBase = 0;
  static const int zIndexCard = 1;
  static const int zIndexFloating = 10;
  static const int zIndexDrawer = 100;
  static const int zIndexModal = 1000;
  static const int zIndexTooltip = 10000;

  // Breakpoints - For responsive design
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;
  static const double breakpointLargeDesktop = 1600;

  // Component Sizes - Standard sizes for common components
  static const double buttonHeightSmall = 32;
  static const double buttonHeightMedium = 40;
  static const double buttonHeightLarge = 48;

  static const double inputHeightSmall = 32;
  static const double inputHeightMedium = 40;
  static const double inputHeightLarge = 48;

  static const double avatarSizeSmall = 24;
  static const double avatarSizeMedium = 32;
  static const double avatarSizeLarge = 48;
  static const double avatarSizeXLarge = 64;

  // App Bar Heights - For consistent navigation
  static const double appBarHeight = 56;
  static const double appBarHeightLarge = 64;
  static const double bottomNavHeight = 64;

  // Content Constraints - For optimal reading experience
  static const double maxLineLength = 600; // Optimal line length for readability
  static const double minContentPadding = 16;
  static const double maxContentPadding = 32;

  /// Helper method to determine if screen size is mobile
  static bool isMobile(double width) => width < breakpointMobile;

  /// Helper method to determine if screen size is tablet
  static bool isTablet(double width) => 
      width >= breakpointMobile && width < breakpointDesktop;

  /// Helper method to determine if screen size is desktop
  static bool isDesktop(double width) => width >= breakpointDesktop;

  /// Helper method to get appropriate content padding based on screen size
  static EdgeInsets getContentPadding(double screenWidth) {
    if (isMobile(screenWidth)) {
      return const EdgeInsets.all(AppSpacing.md);
    } else if (isTablet(screenWidth)) {
      return const EdgeInsets.all(AppSpacing.lg);
    } else {
      return const EdgeInsets.all(AppSpacing.xl);
    }
  }

  /// Helper method to get appropriate grid column count based on screen size
  static int getGridColumns(double screenWidth) {
    if (isMobile(screenWidth)) {
      return 2;
    } else if (isTablet(screenWidth)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Helper method to create a standard card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: cardShadow,
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      );

  /// Helper method to create a hover card decoration
  static BoxDecoration get cardDecorationHover => BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: cardShadowHover,
        border: Border.all(
          color: AppColors.borderMedium,
          width: 1,
        ),
      );

  /// Helper method to create input field decoration
  static BoxDecoration get inputDecoration => BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      );

  /// Helper method to create focused input field decoration
  static BoxDecoration get inputDecorationFocused => BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: AppColors.primaryAccent,
          width: 2,
        ),
      );
}