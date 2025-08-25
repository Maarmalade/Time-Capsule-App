import 'package:flutter/material.dart';

/// AppSpacing defines the complete spacing and elevation system for the Time Capsule app
/// following an 8px grid system and Material 3 elevation principles
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Base Grid Unit - 8px grid system foundation
  static const double _gridUnit = 8.0;

  // Spacing Scale - Based on 8px grid system
  static const double xs = _gridUnit * 0.5; // 4px - micro spacing
  static const double sm = _gridUnit * 1.0; // 8px - tight spacing
  static const double md = _gridUnit * 2.0; // 16px - standard spacing
  static const double lg = _gridUnit * 3.0; // 24px - comfortable spacing
  static const double xl = _gridUnit * 4.0; // 32px - generous spacing
  static const double xxl = _gridUnit * 6.0; // 48px - section spacing
  static const double xxxl = _gridUnit * 8.0; // 64px - page spacing

  // Padding Presets - Common padding configurations
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // Horizontal Padding Presets
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical Padding Presets
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // Margin Presets - Common margin configurations
  static const EdgeInsets marginXs = EdgeInsets.all(xs);
  static const EdgeInsets marginSm = EdgeInsets.all(sm);
  static const EdgeInsets marginMd = EdgeInsets.all(md);
  static const EdgeInsets marginLg = EdgeInsets.all(lg);
  static const EdgeInsets marginXl = EdgeInsets.all(xl);
  static const EdgeInsets marginXxl = EdgeInsets.all(xxl);

  // Page Layout Spacing - For consistent page margins
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pageVertical = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets pageAll = EdgeInsets.all(lg);

  // Component Spacing - For internal component spacing
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  // Gap Spacing - For spacing between elements
  static const double gapXs = xs;
  static const double gapSm = sm;
  static const double gapMd = md;
  static const double gapLg = lg;
  static const double gapXl = xl;
  static const double gapXxl = xxl;

  // Border Radius Scale - For consistent rounded corners
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;
  static const double radiusFull = 50.0; // For circular elements

  // Border Radius Presets
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl = BorderRadius.all(Radius.circular(radiusXxl));

  // Component-specific Border Radius
  static const BorderRadius buttonRadius = borderRadiusSm;
  static const BorderRadius cardRadius = borderRadiusMd;
  static const BorderRadius inputRadius = borderRadiusSm;
  static const BorderRadius imageRadius = borderRadiusMd;

  // Elevation Constants - Material 3 elevation system
  static const double elevation0 = 0.0; // Flat surfaces
  static const double elevation1 = 1.0; // Subtle lift
  static const double elevation2 = 3.0; // Cards, buttons
  static const double elevation3 = 6.0; // Floating elements
  static const double elevation4 = 8.0; // Navigation drawer
  static const double elevation5 = 12.0; // Modal surfaces
  static const double elevation6 = 16.0; // Dialogs
  static const double elevation7 = 24.0; // Tooltips, snackbars

  // Touch Target Sizes - For accessibility compliance
  static const double minTouchTarget = 44.0; // Minimum touch target size
  static const double iconSize = 24.0; // Standard icon size
  static const double iconSizeSmall = 20.0; // Small icon size
  static const double iconSizeLarge = 32.0; // Large icon size

  // Layout Constraints - For responsive design
  static const double maxContentWidth = 600.0; // Maximum content width
  static const double minContentWidth = 320.0; // Minimum content width
  static const double sidebarWidth = 280.0; // Navigation sidebar width

  // Animation Durations - For consistent motion
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Helper method to create custom padding with grid-aligned values
  static EdgeInsets customPadding({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    return EdgeInsets.only(
      top: _alignToGrid(top ?? 0),
      right: _alignToGrid(right ?? 0),
      bottom: _alignToGrid(bottom ?? 0),
      left: _alignToGrid(left ?? 0),
    );
  }

  /// Helper method to create custom margin with grid-aligned values
  static EdgeInsets customMargin({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    return EdgeInsets.only(
      top: _alignToGrid(top ?? 0),
      right: _alignToGrid(right ?? 0),
      bottom: _alignToGrid(bottom ?? 0),
      left: _alignToGrid(left ?? 0),
    );
  }

  /// Helper method to align values to the 8px grid
  static double _alignToGrid(double value) {
    return (value / _gridUnit).round() * _gridUnit;
  }

  /// Helper method to get responsive spacing based on screen width
  static double getResponsiveSpacing(double screenWidth, {
    double mobile = md,
    double tablet = lg,
    double desktop = xl,
  }) {
    if (screenWidth < 600) return mobile;
    if (screenWidth < 1200) return tablet;
    return desktop;
  }

  /// Helper method to get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double screenWidth) {
    final spacing = getResponsiveSpacing(screenWidth);
    return EdgeInsets.all(spacing);
  }
}