import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';
import '../utils/accessibility_utils.dart';

/// A full-screen confirmation interface for captured photos and videos
class CameraConfirmationScreen extends StatefulWidget {
  final XFile capturedMedia;
  final String mediaType; // 'image' or 'video'
  final Function(bool confirmed) onConfirmation;

  const CameraConfirmationScreen({
    super.key,
    required this.capturedMedia,
    required this.mediaType,
    required this.onConfirmation,
  });

  @override
  State<CameraConfirmationScreen> createState() => _CameraConfirmationScreenState();
}

class _CameraConfirmationScreenState extends State<CameraConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoalNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with close button
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: AccessibilityUtils.createSemanticLabel(
                      label: 'Retake ${widget.mediaType}',
                      hint: 'Discard current ${widget.mediaType} and return to camera',
                      isButton: true,
                    ),
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleRetake(),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.charcoalNavy.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryWhite.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.primaryWhite,
                            size: AppSpacing.iconSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    widget.mediaType == 'image' ? 'Photo Preview' : 'Video Preview',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primaryWhite,
                    ),
                  ),
                  Semantics(
                    label: AccessibilityUtils.createSemanticLabel(
                      label: 'Confirm ${widget.mediaType}',
                      hint: 'Use this ${widget.mediaType} and continue',
                      isButton: true,
                    ),
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleConfirm(),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryWhite.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.primaryWhite,
                            size: AppSpacing.iconSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Media preview area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: _buildMediaPreview(),
                ),
              ),
            ),
            
            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    label: 'Retake',
                    onTap: _handleRetake,
                    backgroundColor: AppColors.charcoalNavy.withValues(alpha: 0.7),
                    foregroundColor: AppColors.primaryWhite,
                  ),
                  _buildActionButton(
                    icon: Icons.check,
                    label: 'Use ${widget.mediaType == 'image' ? 'Photo' : 'Video'}',
                    onTap: _handleConfirm,
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.primaryWhite,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.mediaType == 'image') {
      return Semantics(
        label: 'Captured photo preview',
        image: true,
        child: Image.file(
          File(widget.capturedMedia.path),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.charcoalNavy,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.primaryWhite,
                      size: AppSpacing.iconSizeLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Unable to load image',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryWhite,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // For video, show a placeholder with play icon
      // In a full implementation, you'd use a video player widget
      return Semantics(
        label: 'Captured video preview',
        child: Container(
          color: AppColors.charcoalNavy,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: AppColors.primaryWhite,
                    size: AppSpacing.iconSizeLarge * 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Video Preview',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primaryWhite,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap to play video',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryWhite.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: label,
        isButton: true,
      ),
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primaryWhite.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: foregroundColor,
                  size: AppSpacing.iconSize,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: foregroundColor,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRetake() {
    widget.onConfirmation(false);
  }

  void _handleConfirm() {
    widget.onConfirmation(true);
  }

  /// Static method to show the confirmation screen and return the result
  static Future<bool> show({
    required BuildContext context,
    required XFile capturedMedia,
    required String mediaType,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CameraConfirmationScreen(
          capturedMedia: capturedMedia,
          mediaType: mediaType,
          onConfirmation: (confirmed) => Navigator.of(context).pop(confirmed),
        ),
        fullscreenDialog: true,
      ),
    );
    return result ?? false;
  }
}