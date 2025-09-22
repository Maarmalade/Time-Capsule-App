import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';

/// Utility class for managing semantic colors in the black theme context
/// Provides consistent color selection and validation for status indicators,
/// notifications, and other semantic UI elements
class SemanticColorUtils {
  // Private constructor to prevent instantiation
  SemanticColorUtils._();

  /// Returns the appropriate semantic color combination for a given status
  /// Optimized for visibility and harmony with black theme elements
  static SemanticColorSet getSemanticColorSet(SemanticStatus status) {
    switch (status) {
      case SemanticStatus.success:
        return SemanticColorSet(
          primary: AppColors.successGreen,
          background: AppColors.successGreenLight,
          text: AppColors.successGreenDark,
          icon: AppColors.successGreen,
        );
      case SemanticStatus.warning:
        return SemanticColorSet(
          primary: AppColors.warningAmber,
          background: AppColors.warningAmberLight,
          text: AppColors.warningAmberDark,
          icon: AppColors.warningAmber,
        );
      case SemanticStatus.error:
        return SemanticColorSet(
          primary: AppColors.errorRed,
          background: AppColors.errorRedLight,
          text: AppColors.errorRedDark,
          icon: AppColors.errorRed,
        );
      case SemanticStatus.info:
        return SemanticColorSet(
          primary: AppColors.infoBlue,
          background: AppColors.infoBlueLight,
          text: AppColors.infoBlueDark,
          icon: AppColors.infoBlue,
        );
      case SemanticStatus.active:
        return SemanticColorSet(
          primary: AppColors.statusActive,
          background: AppColors.primaryAccent.withValues(alpha: 0.1),
          text: AppColors.primaryAccent,
          icon: AppColors.statusActive,
        );
      case SemanticStatus.inactive:
        return SemanticColorSet(
          primary: AppColors.statusInactive,
          background: AppColors.statusInactive.withValues(alpha: 0.1),
          text: AppColors.statusInactive,
          icon: AppColors.statusInactive,
        );
      case SemanticStatus.pending:
        return SemanticColorSet(
          primary: AppColors.statusPending,
          background: AppColors.warningAmberLight,
          text: AppColors.warningAmberDark,
          icon: AppColors.statusPending,
        );
    }
  }

  /// Returns the appropriate color for status indicators that maintain
  /// visibility when used alongside black theme elements
  static Color getStatusIndicatorColor(String status, {bool isActive = true}) {
    if (!isActive) {
      return AppColors.statusInactive;
    }

    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'delivered':
        return AppColors.statusSuccess;
      case 'warning':
      case 'pending':
      case 'scheduled':
        return AppColors.statusPending;
      case 'error':
      case 'failed':
      case 'cancelled':
        return AppColors.statusError;
      case 'info':
      case 'draft':
      case 'processing':
        return AppColors.statusInfo;
      case 'active':
      case 'online':
      case 'enabled':
        return AppColors.statusActive;
      default:
        return AppColors.statusInactive;
    }
  }

  /// Returns notification colors that work harmoniously with black theme
  static NotificationColorSet getNotificationColors(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return NotificationColorSet(
          backgroundColor: AppColors.successGreenLight,
          borderColor: AppColors.successGreen,
          iconColor: AppColors.successGreen,
          textColor: AppColors.successGreenDark,
        );
      case NotificationType.warning:
        return NotificationColorSet(
          backgroundColor: AppColors.warningAmberLight,
          borderColor: AppColors.warningAmber,
          iconColor: AppColors.warningAmber,
          textColor: AppColors.warningAmberDark,
        );
      case NotificationType.error:
        return NotificationColorSet(
          backgroundColor: AppColors.errorRedLight,
          borderColor: AppColors.errorRed,
          iconColor: AppColors.errorRed,
          textColor: AppColors.errorRedDark,
        );
      case NotificationType.info:
        return NotificationColorSet(
          backgroundColor: AppColors.infoBlueLight,
          borderColor: AppColors.infoBlue,
          iconColor: AppColors.infoBlue,
          textColor: AppColors.infoBlueDark,
        );
    }
  }

  /// Validates that semantic colors maintain proper contrast with black elements
  static bool validateSemanticColorAccessibility(Color semanticColor, Color backgroundColor) {
    return AppColors.validateSemanticColorContrast(semanticColor, backgroundColor);
  }

  /// Returns the best text color for a given semantic background
  static Color getBestTextColorForSemanticBackground(Color backgroundColor) {
    return AppColors.getTextColorForBackground(backgroundColor);
  }

  /// Returns alert/dialog colors that integrate well with black theme
  static AlertColorSet getAlertColors(AlertType type) {
    switch (type) {
      case AlertType.confirmation:
        return AlertColorSet(
          backgroundColor: AppColors.surfacePrimary,
          borderColor: AppColors.successGreen,
          buttonColor: AppColors.successGreen,
          buttonTextColor: AppColors.primaryWhite,
        );
      case AlertType.warning:
        return AlertColorSet(
          backgroundColor: AppColors.surfacePrimary,
          borderColor: AppColors.warningAmber,
          buttonColor: AppColors.warningAmber,
          buttonTextColor: AppColors.warningAmberDark,
        );
      case AlertType.destructive:
        return AlertColorSet(
          backgroundColor: AppColors.surfacePrimary,
          borderColor: AppColors.errorRed,
          buttonColor: AppColors.errorRed,
          buttonTextColor: AppColors.primaryWhite,
        );
      case AlertType.info:
        return AlertColorSet(
          backgroundColor: AppColors.surfacePrimary,
          borderColor: AppColors.infoBlue,
          buttonColor: AppColors.primaryAccent,
          buttonTextColor: AppColors.primaryWhite,
        );
    }
  }
}

/// Enumeration of semantic status types
enum SemanticStatus {
  success,
  warning,
  error,
  info,
  active,
  inactive,
  pending,
}

/// Enumeration of notification types
enum NotificationType {
  success,
  warning,
  error,
  info,
}

/// Enumeration of alert types
enum AlertType {
  confirmation,
  warning,
  destructive,
  info,
}

/// Data class for semantic color combinations
class SemanticColorSet {
  final Color primary;
  final Color background;
  final Color text;
  final Color icon;

  const SemanticColorSet({
    required this.primary,
    required this.background,
    required this.text,
    required this.icon,
  });
}

/// Data class for notification color combinations
class NotificationColorSet {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const NotificationColorSet({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}

/// Data class for alert/dialog color combinations
class AlertColorSet {
  final Color backgroundColor;
  final Color borderColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const AlertColorSet({
    required this.backgroundColor,
    required this.borderColor,
    required this.buttonColor,
    required this.buttonTextColor,
  });
}