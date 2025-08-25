import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:time_capsule/design_system/app_responsive.dart';
import 'package:time_capsule/design_system/app_spacing.dart';

void main() {
  group('AppResponsive', () {
    group('Screen Size Detection', () {
      test('should correctly identify screen sizes', () {
        expect(AppResponsive.getScreenSize(300), ScreenSize.xSmall);
        expect(AppResponsive.getScreenSize(400), ScreenSize.small);
        expect(AppResponsive.getScreenSize(600), ScreenSize.medium);
        expect(AppResponsive.getScreenSize(900), ScreenSize.large);
        expect(AppResponsive.getScreenSize(1200), ScreenSize.xLarge);
        expect(AppResponsive.getScreenSize(1600), ScreenSize.xxLarge);
      });

      test('should correctly identify device types', () {
        expect(AppResponsive.getDeviceType(400), DeviceType.mobile); // < 768
        expect(AppResponsive.getDeviceType(800), DeviceType.tablet); // 768-1440
        expect(AppResponsive.getDeviceType(1500), DeviceType.desktop); // >= 1440
      });
    });

    group('Responsive Spacing', () {
      test('should return correct spacing for different screen sizes', () {
        // Mobile spacing
        expect(
          AppResponsive.getResponsiveSpacing(400),
          AppSpacing.md,
        );

        // Tablet spacing
        expect(
          AppResponsive.getResponsiveSpacing(800),
          AppSpacing.lg,
        );

        // Desktop spacing (1200 is tablet, not desktop)
        expect(
          AppResponsive.getResponsiveSpacing(1200),
          AppSpacing.lg, // Tablet spacing
        );
      });

      test('should allow custom spacing values', () {
        expect(
          AppResponsive.getResponsiveSpacing(
            400,
            mobileSpacing: 8.0,
            tabletSpacing: 16.0,
            desktopSpacing: 24.0,
          ),
          8.0,
        );
      });
    });

    group('Responsive Padding', () {
      test('should return correct padding for different screen sizes', () {
        // Mobile padding
        final mobilePadding = AppResponsive.getResponsivePadding(400);
        expect(mobilePadding, const EdgeInsets.all(AppSpacing.md));

        // Tablet padding
        final tabletPadding = AppResponsive.getResponsivePadding(800);
        expect(tabletPadding, const EdgeInsets.all(AppSpacing.lg));

        // Desktop padding (1200 is tablet, not desktop)
        final tabletPadding2 = AppResponsive.getResponsivePadding(1200);
        expect(tabletPadding2, const EdgeInsets.all(AppSpacing.lg));
      });

      test('should allow custom padding values', () {
        const customMobilePadding = EdgeInsets.all(8.0);
        const customTabletPadding = EdgeInsets.all(16.0);
        const customDesktopPadding = EdgeInsets.all(24.0);

        expect(
          AppResponsive.getResponsivePadding(
            400,
            mobilePadding: customMobilePadding,
            tabletPadding: customTabletPadding,
            desktopPadding: customDesktopPadding,
          ),
          customMobilePadding,
        );
      });
    });

    group('Grid Columns', () {
      test('should return correct column count for different screen sizes', () {
        // Default values
        expect(AppResponsive.getGridColumns(400), 1); // Mobile
        expect(AppResponsive.getGridColumns(800), 2); // Tablet
        expect(AppResponsive.getGridColumns(1200), 2); // Tablet (1200 < 1440)
      });

      test('should allow custom column counts', () {
        expect(
          AppResponsive.getGridColumns(
            400,
            mobileColumns: 2,
            tabletColumns: 4,
            desktopColumns: 6,
          ),
          2,
        );
      });

      test('should return correct memory grid columns', () {
        expect(AppResponsive.getMemoryGridColumns(300), 2); // xSmall
        expect(AppResponsive.getMemoryGridColumns(400), 2); // Small
        expect(AppResponsive.getMemoryGridColumns(600), 3); // Medium
        expect(AppResponsive.getMemoryGridColumns(900), 4); // Large
        expect(AppResponsive.getMemoryGridColumns(1200), 5); // xLarge
        expect(AppResponsive.getMemoryGridColumns(1600), 6); // xxLarge
      });
    });

    group('Font Size Scaling', () {
      test('should scale font sizes correctly for different screen sizes', () {
        const baseFontSize = 16.0;

        expect(
          AppResponsive.getResponsiveFontSize(300, baseFontSize),
          baseFontSize * 0.9,
        ); // xSmall

        expect(
          AppResponsive.getResponsiveFontSize(400, baseFontSize),
          baseFontSize * 0.95,
        ); // Small

        expect(
          AppResponsive.getResponsiveFontSize(600, baseFontSize),
          baseFontSize,
        ); // Medium

        expect(
          AppResponsive.getResponsiveFontSize(900, baseFontSize),
          baseFontSize * 1.05,
        ); // Large

        expect(
          AppResponsive.getResponsiveFontSize(1200, baseFontSize),
          baseFontSize * 1.1,
        ); // xLarge

        expect(
          AppResponsive.getResponsiveFontSize(1600, baseFontSize),
          baseFontSize * 1.15,
        ); // xxLarge
      });
    });

    group('Icon Sizing', () {
      test('should return correct icon sizes for different device types', () {
        const baseSize = 24.0;

        expect(
          AppResponsive.getResponsiveIconSize(400, baseSize: baseSize),
          baseSize,
        ); // Mobile

        expect(
          AppResponsive.getResponsiveIconSize(800, baseSize: baseSize),
          baseSize * 1.2,
        ); // Tablet

        expect(
          AppResponsive.getResponsiveIconSize(1200, baseSize: baseSize),
          baseSize * 1.2,
        ); // Tablet (1200 < 1440)
      });
    });

    group('Button Heights', () {
      test('should return correct button heights for different device types', () {
        expect(AppResponsive.getResponsiveButtonHeight(400), 40.0); // Mobile
        expect(AppResponsive.getResponsiveButtonHeight(800), 48.0); // Tablet
        expect(AppResponsive.getResponsiveButtonHeight(1200), 48.0); // Desktop
      });
    });

    group('App Bar Heights', () {
      test('should return correct app bar heights for different device types', () {
        expect(AppResponsive.getResponsiveAppBarHeight(400), 56.0); // Mobile
        expect(AppResponsive.getResponsiveAppBarHeight(800), 64.0); // Tablet
        expect(AppResponsive.getResponsiveAppBarHeight(1200), 64.0); // Desktop
      });
    });

    group('Content Width', () {
      test('should return appropriate content widths for different screen sizes', () {
        // Mobile: full width minus padding
        final mobileWidth = AppResponsive.getResponsiveContentWidth(400);
        expect(mobileWidth, 400 - (AppSpacing.md * 2));

        // Tablet: 80% of screen width, clamped
        final tabletWidth = AppResponsive.getResponsiveContentWidth(800);
        expect(tabletWidth, (800 * 0.8).clamp(400.0, 800.0));

        // Tablet: 80% of screen width, clamped (1200 < 1440)
        final tabletWidth2 = AppResponsive.getResponsiveContentWidth(1200);
        expect(tabletWidth2, (1200 * 0.8).clamp(400.0, 800.0));
      });
    });

    group('Card Width Calculation', () {
      test('should calculate correct card widths for grid layouts', () {
        const screenWidth = 800.0;
        const columns = 3;
        
        final contentWidth = AppResponsive.getResponsiveContentWidth(screenWidth);
        final spacing = AppResponsive.getResponsiveSpacing(screenWidth);
        final expectedCardWidth = (contentWidth - (spacing * (columns - 1))) / columns;
        
        final actualCardWidth = AppResponsive.getResponsiveCardWidth(screenWidth, columns);
        expect(actualCardWidth, expectedCardWidth);
      });
    });

    group('Touch Target Sizing', () {
      test('should determine touch-friendly sizing correctly', () {
        expect(AppResponsive.shouldUseTouchFriendlySizing(400), true); // Mobile
        expect(AppResponsive.shouldUseTouchFriendlySizing(800), false); // Tablet
        expect(AppResponsive.shouldUseTouchFriendlySizing(1200), false); // Desktop
      });

      test('should return correct minimum touch target sizes', () {
        expect(AppResponsive.getMinTouchTargetSize(400), 44.0); // Mobile
        expect(AppResponsive.getMinTouchTargetSize(800), 32.0); // Tablet
        expect(AppResponsive.getMinTouchTargetSize(1200), 32.0); // Desktop
      });
    });

    group('Border Radius', () {
      test('should return appropriate border radius for different screen sizes', () {
        // Mobile
        final mobileBorderRadius = AppResponsive.getResponsiveBorderRadius(400);
        expect(mobileBorderRadius, AppSpacing.borderRadiusSm);

        // Tablet
        final tabletBorderRadius = AppResponsive.getResponsiveBorderRadius(800);
        expect(tabletBorderRadius, AppSpacing.borderRadiusMd);

        // Tablet (1200 < 1440)
        final tabletBorderRadius2 = AppResponsive.getResponsiveBorderRadius(1200);
        expect(tabletBorderRadius2, AppSpacing.borderRadiusMd);
      });

      test('should allow custom border radius values', () {
        const customMobileBorderRadius = BorderRadius.all(Radius.circular(4.0));
        const customTabletBorderRadius = BorderRadius.all(Radius.circular(8.0));
        const customDesktopBorderRadius = BorderRadius.all(Radius.circular(12.0));

        expect(
          AppResponsive.getResponsiveBorderRadius(
            400,
            mobileBorderRadius: customMobileBorderRadius,
            tabletBorderRadius: customTabletBorderRadius,
            desktopBorderRadius: customDesktopBorderRadius,
          ),
          customMobileBorderRadius,
        );
      });
    });

    group('List Item Heights', () {
      test('should return correct list item heights for different device types', () {
        expect(AppResponsive.getResponsiveListItemHeight(400), 72.0); // Mobile
        expect(AppResponsive.getResponsiveListItemHeight(800), 80.0); // Tablet
        expect(AppResponsive.getResponsiveListItemHeight(1200), 80.0); // Tablet (1200 < 1440)
      });
    });

    group('Dialog Width', () {
      test('should return appropriate dialog widths for different screen sizes', () {
        // Mobile: 90% of screen width
        final mobileDialogWidth = AppResponsive.getResponsiveDialogWidth(400);
        expect(mobileDialogWidth, 400 * 0.9);

        // Tablet: 70% of screen width, clamped
        final tabletDialogWidth = AppResponsive.getResponsiveDialogWidth(800);
        expect(tabletDialogWidth, (800 * 0.7).clamp(400.0, 600.0));

        // Desktop: 50% of screen width, clamped
        final desktopDialogWidth = AppResponsive.getResponsiveDialogWidth(1200);
        expect(desktopDialogWidth, (1200 * 0.5).clamp(500.0, 800.0));
      });
    });
  });
}