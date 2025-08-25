import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';
import '../utils/semantic_color_utils.dart';

/// Example widget demonstrating proper usage of semantic colors with black theme
/// This widget shows how to use semantic colors for status indicators, notifications,
/// and alerts that work harmoniously with the black theme
class SemanticColorExampleWidget extends StatelessWidget {
  const SemanticColorExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semantic Colors with Black Theme'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Indicators Section
            _buildSectionTitle('Status Indicators'),
            const SizedBox(height: AppSpacing.sm),
            _buildStatusIndicators(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Notification Examples Section
            _buildSectionTitle('Notification Examples'),
            const SizedBox(height: AppSpacing.sm),
            _buildNotificationExamples(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Alert Examples Section
            _buildSectionTitle('Alert Button Examples'),
            const SizedBox(height: AppSpacing.sm),
            _buildAlertExamples(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Semantic Color Combinations Section
            _buildSectionTitle('Semantic Color Combinations'),
            const SizedBox(height: AppSpacing.sm),
            _buildSemanticColorCombinations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.headlineSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: AppTypography.semiBold,
      ),
    );
  }

  Widget _buildStatusIndicators() {
    final statuses = [
      {'label': 'Active', 'status': 'active'},
      {'label': 'Success', 'status': 'success'},
      {'label': 'Pending', 'status': 'pending'},
      {'label': 'Error', 'status': 'error'},
      {'label': 'Info', 'status': 'info'},
      {'label': 'Inactive', 'status': 'inactive'},
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: statuses.map((status) {
        final color = SemanticColorUtils.getStatusIndicatorColor(
          status['status']!,
          isActive: status['status'] != 'inactive',
        );
        
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                status['label']!,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationExamples() {
    return Column(
      children: [
        _buildNotificationCard(NotificationType.success, 'Operation completed successfully!'),
        const SizedBox(height: AppSpacing.sm),
        _buildNotificationCard(NotificationType.warning, 'Please review your settings.'),
        const SizedBox(height: AppSpacing.sm),
        _buildNotificationCard(NotificationType.error, 'An error occurred. Please try again.'),
        const SizedBox(height: AppSpacing.sm),
        _buildNotificationCard(NotificationType.info, 'New features are available.'),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationType type, String message) {
    final colors = SemanticColorUtils.getNotificationColors(type);
    IconData icon;
    
    switch (type) {
      case NotificationType.success:
        icon = Icons.check_circle;
        break;
      case NotificationType.warning:
        icon = Icons.warning;
        break;
      case NotificationType.error:
        icon = Icons.error;
        break;
      case NotificationType.info:
        icon = Icons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border.all(color: colors.borderColor, width: 1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.iconColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertExamples() {
    return Column(
      children: [
        _buildAlertButton(AlertType.confirmation, 'Confirm Action'),
        const SizedBox(height: AppSpacing.sm),
        _buildAlertButton(AlertType.warning, 'Warning Action'),
        const SizedBox(height: AppSpacing.sm),
        _buildAlertButton(AlertType.destructive, 'Delete Item'),
        const SizedBox(height: AppSpacing.sm),
        _buildAlertButton(AlertType.info, 'More Info'),
      ],
    );
  }

  Widget _buildAlertButton(AlertType type, String label) {
    final colors = SemanticColorUtils.getAlertColors(type);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.buttonColor,
          foregroundColor: colors.buttonTextColor,
          side: BorderSide(color: colors.borderColor, width: 1),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: AppTypography.medium,
          ),
        ),
      ),
    );
  }

  Widget _buildSemanticColorCombinations() {
    final semanticStatuses = [
      SemanticStatus.success,
      SemanticStatus.warning,
      SemanticStatus.error,
      SemanticStatus.info,
      SemanticStatus.active,
      SemanticStatus.inactive,
      SemanticStatus.pending,
    ];

    return Column(
      children: semanticStatuses.map((status) {
        final colorSet = SemanticColorUtils.getSemanticColorSet(status);
        final statusName = status.name.toUpperCase();
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorSet.background,
            border: Border.all(color: colorSet.primary, width: 1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Icon(
                _getIconForStatus(status),
                color: colorSet.icon,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusName,
                      style: AppTypography.labelLarge.copyWith(
                        color: colorSet.text,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    Text(
                      'This demonstrates the $statusName color combination',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorSet.text,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorSet.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForStatus(SemanticStatus status) {
    switch (status) {
      case SemanticStatus.success:
        return Icons.check_circle;
      case SemanticStatus.warning:
        return Icons.warning;
      case SemanticStatus.error:
        return Icons.error;
      case SemanticStatus.info:
        return Icons.info;
      case SemanticStatus.active:
        return Icons.radio_button_checked;
      case SemanticStatus.inactive:
        return Icons.radio_button_unchecked;
      case SemanticStatus.pending:
        return Icons.schedule;
    }
  }
}