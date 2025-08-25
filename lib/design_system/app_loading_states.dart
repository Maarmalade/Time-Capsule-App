import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// AppLoadingStates provides standardized loading indicators and skeleton components
/// with consistent styling following the professional design system principles
class AppLoadingStates {
  // Private constructor to prevent instantiation
  AppLoadingStates._();

  /// Primary circular loading indicator with accent blue color
  static Widget circularLoader({
    double? size,
    double? strokeWidth,
    Color? color,
  }) {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primaryAccent,
        ),
      ),
    );
  }

  /// Linear loading indicator for progress bars
  static Widget linearLoader({
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double? minHeight,
  }) {
    return SizedBox(
      height: minHeight ?? 4,
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: backgroundColor ?? AppColors.lightGray,
        valueColor: AlwaysStoppedAnimation<Color>(
          valueColor ?? AppColors.primaryAccent,
        ),
      ),
    );
  }

  /// Button loading state that maintains button dimensions
  static Widget loadingButton({
    required String text,
    bool isLoading = false,
    VoidCallback? onPressed,
    bool isPrimary = true,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height ?? 44,
      child: isPrimary
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textOnAccent,
                disabledBackgroundColor: AppColors.primaryAccent,
                disabledForegroundColor: AppColors.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                elevation: AppSpacing.elevation2,
              ),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textOnAccent,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Loading...',
                          style: AppTypography.labelLarge,
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: AppTypography.labelLarge,
                    ),
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isLoading ? AppColors.mediumGray : AppColors.primaryAccent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccent,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Loading...',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryAccent,
                      ),
                    ),
            ),
    );
  }

  /// Skeleton loading component for content areas
  static Widget skeleton({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height ?? 16,
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusXs,
      ),
      child: _SkeletonShimmer(),
    );
  }

  /// Skeleton text lines for text content loading
  static Widget skeletonText({
    int lines = 3,
    double? lineHeight,
    double? lastLineWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < lines - 1 ? AppSpacing.xs : 0,
          ),
          child: skeleton(
            width: isLastLine && lastLineWidth != null 
                ? lastLineWidth 
                : double.infinity,
            height: lineHeight ?? 16,
          ),
        );
      }),
    );
  }

  /// Skeleton card for card content loading
  static Widget skeletonCard({
    double? width,
    double? height,
    bool includeImage = true,
    bool includeTitle = true,
    bool includeSubtitle = true,
  }) {
    return Container(
      width: width,
      height: height,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeImage) ...[
            skeleton(
              width: double.infinity,
              height: 120,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            SizedBox(height: AppSpacing.sm),
          ],
          if (includeTitle) ...[
            skeleton(
              width: double.infinity,
              height: 20,
            ),
            SizedBox(height: AppSpacing.xs),
          ],
          if (includeSubtitle) ...[
            skeleton(
              width: 200,
              height: 16,
            ),
          ],
        ],
      ),
    );
  }

  /// Skeleton list item for list content loading
  static Widget skeletonListItem({
    bool includeAvatar = true,
    bool includeTrailing = false,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      child: Row(
        children: [
          if (includeAvatar) ...[
            skeleton(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                skeleton(
                  width: double.infinity,
                  height: 16,
                ),
                SizedBox(height: AppSpacing.xs),
                skeleton(
                  width: 150,
                  height: 14,
                ),
              ],
            ),
          ),
          if (includeTrailing) ...[
            SizedBox(width: AppSpacing.sm),
            skeleton(
              width: 24,
              height: 24,
            ),
          ],
        ],
      ),
    );
  }

  /// Full page loading overlay
  static Widget pageLoader({
    String? message,
    bool showBackground = true,
  }) {
    return Container(
      color: showBackground 
          ? AppColors.surfacePrimary.withOpacity(0.8)
          : Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circularLoader(size: 32),
            if (message != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Loading state for images with placeholder
  static Widget imageLoader({
    double? width,
    double? height,
    BorderRadius? borderRadius,
    IconData? placeholderIcon,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            placeholderIcon ?? Icons.image_outlined,
            size: 32,
            color: AppColors.mediumGray,
          ),
          SizedBox(height: AppSpacing.sm),
          circularLoader(size: 20),
        ],
      ),
    );
  }

  /// Refresh indicator for pull-to-refresh
  static Widget refreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color? color,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primaryAccent,
      backgroundColor: AppColors.surfacePrimary,
      child: child,
    );
  }
}

/// Internal shimmer animation widget for skeleton loading
class _SkeletonShimmer extends StatefulWidget {
  @override
  _SkeletonShimmerState createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.softGray,
                AppColors.lightGray,
                AppColors.softGray,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}