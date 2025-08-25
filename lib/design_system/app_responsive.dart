import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'design_constants.dart';

/// Screen size categories for more precise responsive behavior
enum ScreenSize {
  xSmall,  // < 360px
  small,   // 360px - 480px
  medium,  // 480px - 768px
  large,   // 768px - 1024px
  xLarge,  // 1024px - 1440px
  xxLarge, // > 1440px
}

/// Device type categories for different interaction patterns
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// AppResponsive provides comprehensive responsive design utilities
/// for creating adaptive layouts across different screen sizes
class AppResponsive {
  // Private constructor to prevent instantiation
  AppResponsive._();

  // Enhanced Breakpoints with more granular control
  static const double breakpointXSmall = 360;  // Small phones
  static const double breakpointSmall = 480;   // Large phones
  static const double breakpointMedium = 768;  // Small tablets
  static const double breakpointLarge = 1024;  // Large tablets
  static const double breakpointXLarge = 1440; // Desktop
  static const double breakpointXXLarge = 1920; // Large desktop

  /// Get current screen size category
  static ScreenSize getScreenSize(double width) {
    if (width < breakpointXSmall) return ScreenSize.xSmall;
    if (width < breakpointSmall) return ScreenSize.small;
    if (width < breakpointMedium) return ScreenSize.medium;
    if (width < breakpointLarge) return ScreenSize.large;
    if (width < breakpointXLarge) return ScreenSize.xLarge;
    return ScreenSize.xxLarge;
  }

  /// Get device type based on screen width
  static DeviceType getDeviceType(double width) {
    if (width < breakpointMedium) return DeviceType.mobile;
    if (width < breakpointXLarge) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Responsive spacing that adapts to screen size
  static double getResponsiveSpacing(double width, {
    double mobileSpacing = AppSpacing.md,
    double tabletSpacing = AppSpacing.lg,
    double desktopSpacing = AppSpacing.xl,
  }) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileSpacing;
      case DeviceType.tablet:
        return tabletSpacing;
      case DeviceType.desktop:
        return desktopSpacing;
    }
  }

  /// Responsive padding that adapts to screen size
  static EdgeInsets getResponsivePadding(double width, {
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
  }) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobilePadding ?? const EdgeInsets.all(AppSpacing.md);
      case DeviceType.tablet:
        return tabletPadding ?? const EdgeInsets.all(AppSpacing.lg);
      case DeviceType.desktop:
        return desktopPadding ?? const EdgeInsets.all(AppSpacing.xl);
    }
  }

  /// Responsive margin that adapts to screen size
  static EdgeInsets getResponsiveMargin(double width, {
    EdgeInsets? mobileMargin,
    EdgeInsets? tabletMargin,
    EdgeInsets? desktopMargin,
  }) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileMargin ?? const EdgeInsets.all(AppSpacing.sm);
      case DeviceType.tablet:
        return tabletMargin ?? const EdgeInsets.all(AppSpacing.md);
      case DeviceType.desktop:
        return desktopMargin ?? const EdgeInsets.all(AppSpacing.lg);
    }
  }

  /// Get responsive grid column count
  static int getGridColumns(double width, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileColumns;
      case DeviceType.tablet:
        return tabletColumns;
      case DeviceType.desktop:
        return desktopColumns;
    }
  }

  /// Get responsive list column count for memory grids
  static int getMemoryGridColumns(double width) {
    final screenSize = getScreenSize(width);
    switch (screenSize) {
      case ScreenSize.xSmall:
      case ScreenSize.small:
        return 2;
      case ScreenSize.medium:
        return 3;
      case ScreenSize.large:
        return 4;
      case ScreenSize.xLarge:
        return 5;
      case ScreenSize.xxLarge:
        return 6;
    }
  }

  /// Get responsive font size scaling
  static double getResponsiveFontSize(double width, double baseFontSize) {
    final screenSize = getScreenSize(width);
    switch (screenSize) {
      case ScreenSize.xSmall:
        return baseFontSize * 0.9;
      case ScreenSize.small:
        return baseFontSize * 0.95;
      case ScreenSize.medium:
        return baseFontSize;
      case ScreenSize.large:
        return baseFontSize * 1.05;
      case ScreenSize.xLarge:
        return baseFontSize * 1.1;
      case ScreenSize.xxLarge:
        return baseFontSize * 1.15;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(double width, {
    double baseSize = 24.0,
  }) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize;
      case DeviceType.tablet:
        return baseSize * 1.2;
      case DeviceType.desktop:
        return baseSize * 1.4;
    }
  }

  /// Get responsive button height
  static double getResponsiveButtonHeight(double width) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return DesignConstants.buttonHeightMedium;
      case DeviceType.tablet:
        return DesignConstants.buttonHeightLarge;
      case DeviceType.desktop:
        return DesignConstants.buttonHeightLarge;
    }
  }

  /// Get responsive app bar height
  static double getResponsiveAppBarHeight(double width) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return DesignConstants.appBarHeight;
      case DeviceType.tablet:
      case DeviceType.desktop:
        return DesignConstants.appBarHeightLarge;
    }
  }

  /// Get responsive content width with max constraints
  static double getResponsiveContentWidth(double screenWidth) {
    final deviceType = getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth - (AppSpacing.md * 2);
      case DeviceType.tablet:
        return (screenWidth * 0.8).clamp(400.0, 800.0);
      case DeviceType.desktop:
        return (screenWidth * 0.6).clamp(600.0, 1200.0);
    }
  }

  /// Get responsive card width for memory cards
  static double getResponsiveCardWidth(double screenWidth, int columns) {
    final contentWidth = getResponsiveContentWidth(screenWidth);
    final spacing = getResponsiveSpacing(screenWidth);
    final totalSpacing = spacing * (columns - 1);
    return (contentWidth - totalSpacing) / columns;
  }

  /// Check if device should use touch-friendly sizing
  static bool shouldUseTouchFriendlySizing(double width) {
    return getDeviceType(width) == DeviceType.mobile;
  }

  /// Get minimum touch target size based on device type
  static double getMinTouchTargetSize(double width) {
    return shouldUseTouchFriendlySizing(width) ? 44.0 : 32.0;
  }

  /// Get responsive border radius
  static BorderRadius getResponsiveBorderRadius(double width, {
    BorderRadius? mobileBorderRadius,
    BorderRadius? tabletBorderRadius,
    BorderRadius? desktopBorderRadius,
  }) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileBorderRadius ?? AppSpacing.borderRadiusSm;
      case DeviceType.tablet:
        return tabletBorderRadius ?? AppSpacing.borderRadiusMd;
      case DeviceType.desktop:
        return desktopBorderRadius ?? AppSpacing.borderRadiusLg;
    }
  }

  /// Responsive layout helper that returns different widgets based on screen size
  static Widget responsiveBuilder({
    required BuildContext context,
    Widget? mobile,
    Widget? tablet,
    Widget? desktop,
    required Widget fallback,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(screenWidth);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? fallback;
      case DeviceType.tablet:
        return tablet ?? mobile ?? fallback;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile ?? fallback;
    }
  }

  /// Responsive value helper that returns different values based on screen size
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(screenWidth);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive safe area padding
  static EdgeInsets getResponsiveSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safePadding = mediaQuery.padding;
    final deviceType = getDeviceType(screenWidth);

    // On desktop, we don't need as much safe area consideration
    if (deviceType == DeviceType.desktop) {
      return EdgeInsets.only(
        top: safePadding.top,
        bottom: safePadding.bottom,
      );
    }

    return safePadding;
  }

  /// Get responsive list item height
  static double getResponsiveListItemHeight(double width) {
    final deviceType = getDeviceType(width);
    switch (deviceType) {
      case DeviceType.mobile:
        return 72.0;
      case DeviceType.tablet:
        return 80.0;
      case DeviceType.desktop:
        return 88.0;
    }
  }

  /// Get responsive dialog width
  static double getResponsiveDialogWidth(double screenWidth) {
    final deviceType = getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth * 0.9;
      case DeviceType.tablet:
        return (screenWidth * 0.7).clamp(400.0, 600.0);
      case DeviceType.desktop:
        return (screenWidth * 0.5).clamp(500.0, 800.0);
    }
  }
}