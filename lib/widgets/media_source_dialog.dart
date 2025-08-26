import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';
import '../utils/accessibility_utils.dart';

/// Enumeration for different media source types
enum MediaSourceType { image, video, audio }

/// Enumeration for media source options
enum MediaSource { camera, gallery, record, selectFile }

/// A reusable dialog component that presents source selection options for different media types
class MediaSourceDialog extends StatelessWidget {
  final MediaSourceType mediaType;
  final Function(MediaSource) onSourceSelected;

  const MediaSourceDialog({
    super.key,
    required this.mediaType,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: _getDialogTitle(),
        hint: 'Choose how to add ${mediaType.name} content',
      ),
      child: AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          _getDialogTitle(),
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildSourceOptions(context),
        ),
      ),
    );
  }

  String _getDialogTitle() {
    switch (mediaType) {
      case MediaSourceType.image:
        return 'Select Image Source';
      case MediaSourceType.video:
        return 'Select Video Source';
      case MediaSourceType.audio:
        return 'Select Audio Source';
    }
  }

  List<Widget> _buildSourceOptions(BuildContext context) {
    switch (mediaType) {
      case MediaSourceType.image:
      case MediaSourceType.video:
        return [
          _buildSourceOption(
            context: context,
            icon: Icons.camera_alt,
            title: 'Camera',
            subtitle: 'Take a new ${mediaType.name}',
            source: MediaSource.camera,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSourceOption(
            context: context,
            icon: Icons.photo_library,
            title: 'Gallery',
            subtitle: 'Choose from your ${mediaType.name}s',
            source: MediaSource.gallery,
          ),
        ];
      case MediaSourceType.audio:
        return [
          _buildSourceOption(
            context: context,
            icon: Icons.mic,
            title: 'Record Audio',
            subtitle: 'Record a new voice note',
            source: MediaSource.record,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSourceOption(
            context: context,
            icon: Icons.audio_file,
            title: 'Select Audio File',
            subtitle: 'Choose from your audio files',
            source: MediaSource.selectFile,
          ),
        ];
    }
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required MediaSource source,
  }) {
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: title,
        hint: subtitle,
        isButton: true,
      ),
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Simply call the callback - permission checking will be done later
            onSourceSelected(source);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderLight,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryAccent,
                    size: AppSpacing.iconSize,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textTertiary,
                  size: AppSpacing.iconSizeSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Static method to show the dialog and return the selected source
  static Future<MediaSource?> show({
    required BuildContext context,
    required MediaSourceType mediaType,
  }) async {
    return await showDialog<MediaSource?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MediaSourceDialog(
        mediaType: mediaType,
        onSourceSelected: (source) {
          Navigator.of(context).pop(source);
        },
      ),
    );
  }

  /// Helper method to convert MediaSource to ImageSource for image_picker
  static ImageSource? toImageSource(MediaSource source) {
    switch (source) {
      case MediaSource.camera:
        return ImageSource.camera;
      case MediaSource.gallery:
        return ImageSource.gallery;
      default:
        return null;
    }
  }
}