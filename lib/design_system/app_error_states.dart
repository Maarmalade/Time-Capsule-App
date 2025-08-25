import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// AppErrorStates provides standardized error message components with consistent styling
/// following the professional design system principles
class AppErrorStates {
  // Private constructor to prevent instantiation
  AppErrorStates._();

  /// Standard error message widget for form validation errors
  static Widget validationError(String message) {
    return Container(
      padding: AppSpacing.paddingVerticalXs,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: AppColors.errorRed,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Network error component for connection and API errors
  static Widget networkError({
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border.all(
          color: AppColors.errorRed.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_outlined,
            size: 32,
            color: AppColors.errorRed,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            title ?? 'Connection Error',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
              child: Text(
                'Try Again',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Generic error card for general error states
  static Widget errorCard({
    required String title,
    String? message,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border.all(
          color: AppColors.errorRed.withOpacity(0.3),
          width: 1,
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 32,
              color: AppColors.errorRed,
            ),
            SizedBox(height: AppSpacing.sm),
          ],
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
              child: Text(
                actionLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Empty state component for when no data is available
  static Widget emptyState({
    required String title,
    String? message,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Container(
      padding: AppSpacing.paddingXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 48,
            color: AppColors.mediumGray,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                elevation: AppSpacing.elevation2,
              ),
              child: Text(
                actionLabel,
                style: AppTypography.labelLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Inline error message for form fields
  static Widget inlineError(String message) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.errorRed,
        ),
      ),
    );
  }

  /// Error banner for page-level errors
  static Widget errorBanner({
    required String message,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
        border: Border(
          left: BorderSide(
            color: AppColors.errorRed,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.errorRed,
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentBlue,
                padding: AppSpacing.paddingHorizontalSm,
              ),
              child: Text(
                actionLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                size: 20,
                color: AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Snackbar error styling
  static SnackBar errorSnackBar({
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return SnackBar(
      content: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textOnAccent,
        ),
      ),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.textOnAccent,
              onPressed: onAction,
            )
          : null,
    );
  }
}