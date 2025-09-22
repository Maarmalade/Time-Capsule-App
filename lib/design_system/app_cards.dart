import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// AppCards defines the complete card and container styling system for the Time Capsule app
/// following Material 3 principles with professional styling and consistent elevation
class AppCards {
  // Private constructor to prevent instantiation
  AppCards._();

  // Card Padding Constants
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets cardPaddingMedium = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(AppSpacing.sm);

  // Card Margin Constants
  static const EdgeInsets cardMarginLarge = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets cardMarginMedium = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets cardMarginSmall = EdgeInsets.all(AppSpacing.xs);

  // Memory Card Aspect Ratios
  static const double memoryCardAspectRatio16x9 = 16.0 / 9.0;
  static const double memoryCardAspectRatio1x1 = 1.0;
  static const double memoryCardAspectRatio4x3 = 4.0 / 3.0;

  /// Standard Card Theme for Material theme integration
  static CardTheme get cardTheme => CardTheme(
        color: AppColors.surfacePrimary,
        shadowColor: AppColors.shadowMedium,
        elevation: AppSpacing.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
        margin: cardMarginMedium,
        clipBehavior: Clip.antiAlias,
      );

  /// Standard Card Decoration
  static BoxDecoration get standardCardDecoration => BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8.0,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  /// Elevated Card Decoration - Higher elevation for prominent cards
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12.0,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6.0,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  /// Flat Card Decoration - No shadow for subtle cards
  static BoxDecoration get flatCardDecoration => BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.0,
        ),
      );

  /// Secondary Card Decoration - Using secondary surface color
  static BoxDecoration get secondaryCardDecoration => BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6.0,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      );

  /// Memory Card Decoration - Specialized for photo/video content
  static BoxDecoration get memoryCardDecoration => BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8.0,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      );

  /// Interactive Card Decoration - For clickable cards with hover effects
  static BoxDecoration getInteractiveCardDecoration({bool isHovered = false}) {
    return BoxDecoration(
      color: AppColors.surfacePrimary,
      borderRadius: AppSpacing.cardRadius,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: isHovered ? 12.0 : 8.0,
          offset: Offset(0, isHovered ? 4 : 2),
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Card Size Variants

  /// Large Card Container
  static Widget createLargeCard({
    required Widget child,
    BoxDecoration? decoration,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? cardMarginLarge,
      decoration: decoration ?? standardCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: padding ?? cardPaddingLarge,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Medium Card Container (Standard)
  static Widget createStandardCard({
    required Widget child,
    BoxDecoration? decoration,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? cardMarginMedium,
      decoration: decoration ?? standardCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: padding ?? cardPaddingMedium,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Small Card Container
  static Widget createSmallCard({
    required Widget child,
    BoxDecoration? decoration,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? cardMarginSmall,
      decoration: decoration ?? standardCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: padding ?? cardPaddingSmall,
            child: child,
          ),
        ),
      ),
    );
  }

  // Specialized Card Types

  /// Memory Card for displaying photos/videos with overlay support
  static Widget createMemoryCard({
    required Widget content,
    Widget? overlay,
    double? aspectRatio,
    VoidCallback? onTap,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? cardMarginMedium,
      decoration: memoryCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.cardRadius,
          child: ClipRRect(
            borderRadius: AppSpacing.cardRadius,
            child: AspectRatio(
              aspectRatio: aspectRatio ?? memoryCardAspectRatio16x9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  if (overlay != null) overlay,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Info Card for displaying information with icon and text
  static Widget createInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return createStandardCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primaryAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primaryAccent,
              size: 24.0,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Action Card with primary action button
  static Widget createActionCard({
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
    IconData? icon,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return createStandardCard(
      padding: padding,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppColors.primaryAccent,
              size: 32.0,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textOnAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              child: Text(actionText),
            ),
          ),
        ],
      ),
    );
  }

  /// Status Card for displaying status information with color coding
  static Widget createStatusCard({
    required String title,
    required String message,
    required StatusType status,
    IconData? icon,
    VoidCallback? onTap,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    final statusConfig = _getStatusConfig(status);
    
    return Container(
      margin: margin ?? cardMarginMedium,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: statusConfig.color,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6.0,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: padding ?? cardPaddingMedium,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    icon ?? statusConfig.icon,
                    color: statusConfig.color,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Container Utilities

  /// Creates a simple container with consistent styling
  static Widget createContainer({
    required Widget child,
    Color? backgroundColor,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      margin: margin,
      padding: padding ?? cardPaddingMedium,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfacePrimary,
        borderRadius: borderRadius ?? AppSpacing.cardRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }

  /// Creates a section container for grouping related content
  static Widget createSection({
    required String title,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return createContainer(
      padding: padding,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  // Helper Methods

  /// Gets configuration for status cards
  static _StatusConfig _getStatusConfig(StatusType status) {
    switch (status) {
      case StatusType.success:
        return _StatusConfig(
          color: AppColors.successGreen,
          icon: Icons.check_circle_outline,
        );
      case StatusType.warning:
        return _StatusConfig(
          color: AppColors.warningAmber,
          icon: Icons.warning_outlined,
        );
      case StatusType.error:
        return _StatusConfig(
          color: AppColors.errorRed,
          icon: Icons.error_outline,
        );
      case StatusType.info:
        return _StatusConfig(
          color: AppColors.infoBlue,
          icon: Icons.info_outline,
        );
    }
  }
}

/// Status types for status cards
enum StatusType {
  success,
  warning,
  error,
  info,
}

/// Internal configuration for status cards
class _StatusConfig {
  final Color color;
  final IconData icon;

  const _StatusConfig({
    required this.color,
    required this.icon,
  });
}