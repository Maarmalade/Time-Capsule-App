import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../models/diary_entry_model.dart';
import '../../services/diary_service.dart';
import '../../services/media_service.dart';
import '../../widgets/video_player_widget.dart';
import '../../pages/video_player_page.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';
import '../../utils/accessibility_utils.dart';
import 'diary_editor_page.dart';

/// Dedicated viewer for diary entries with formatted display and media rendering
class DiaryViewerPage extends StatefulWidget {
  final DiaryEntryModel diary;
  final String folderId;
  final bool canEdit;
  final bool isSharedFolder;

  const DiaryViewerPage({
    super.key,
    required this.diary,
    required this.folderId,
    this.canEdit = true,
    this.isSharedFolder = false,
  });

  // Compatibility constructor for old DiaryEntry model
  DiaryViewerPage.fromLegacyEntry({
    super.key,
    required DiaryEntry entry,
    this.canEdit = true,
    this.isSharedFolder = false,
  }) : diary = DiaryEntryModel(
          id: entry.id,
          folderId: 'legacy', // Legacy entries don't have folder ID
          title: entry.title,
          content: entry.text,
          attachments: entry.media.map((media) => DiaryMediaAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString() + entry.media.indexOf(media).toString(),
            type: media.type,
            url: media.url,
            caption: null, // Legacy media doesn't have captions
            position: entry.media.indexOf(media),
          )).toList(),
          createdAt: entry.createdAt,
          diaryDate: entry.createdAt, // For legacy entries, diary date is same as creation date
          lastModified: entry.createdAt,
          uploadedBy: null,
        ),
        folderId = 'legacy';

  @override
  State<DiaryViewerPage> createState() => _DiaryViewerPageState();
}

class _DiaryViewerPageState extends State<DiaryViewerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MediaService _mediaService = MediaService();
  String? _currentlyPlayingAudio;
  bool _isAudioLoading = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    // Listen to audio duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _audioDuration = duration;
      });
    });

    // Listen to audio position changes
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _audioPosition = position;
      });
    });

    // Listen to audio completion
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _currentlyPlayingAudio = null;
        _audioPosition = Duration.zero;
      });
    });
  }

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get _canUserEdit {
    if (!widget.canEdit) return false;

    // In shared folders, only the creator or uploader can edit
    if (widget.isSharedFolder) {
      return widget.diary.uploadedBy == _userId;
    }

    // In personal folders, user can edit their own entries
    return true;
  }

  Future<void> _editDiary() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          folderId: widget.folderId,
          existingEntry: widget.diary,
          isSharedFolder: widget.isSharedFolder,
        ),
      ),
    );

    if (result == true && mounted) {
      // Diary was updated, pop back to refresh the parent
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final newFavoriteStatus = !widget.diary.isFavorite;
      
      await _mediaService.toggleDiaryFavorite(
        folderId: widget.folderId,
        diaryId: widget.diary.id,
        isFavorite: newFavoriteStatus,
      );

      if (mounted) {
        setState(() {
          // Trigger UI rebuild to reflect the favorite status change
          // The UI will read the updated status from Firestore
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus 
                ? 'Added to favorites! This entry will appear in nostalgia reminders.'
                : 'Removed from favorites.',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        
        // Pop back to refresh the parent
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite status: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _playAudio(DiaryMediaAttachment attachment) async {
    if (_currentlyPlayingAudio == attachment.id) {
      // Stop current audio
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingAudio = null;
        _audioPosition = Duration.zero;
      });
      return;
    }

    setState(() {
      _isAudioLoading = true;
      _currentlyPlayingAudio = attachment.id;
    });

    try {
      await _audioPlayer.play(UrlSource(attachment.url));
    } catch (e) {
      _showErrorSnackBar('Failed to play audio: $e');
      setState(() {
        _currentlyPlayingAudio = null;
      });
    } finally {
      setState(() {
        _isAudioLoading = false;
      });
    }
  }

  Future<void> _seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _showFullScreenImage(String imageUrl, String? caption) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.errorRed,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Failed to load image',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.primaryWhite,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.primaryWhite,
                    size: 24,
                  ),
                  tooltip: 'Close image',
                ),
              ),
            ),

            // Caption overlay
            if (caption?.isNotEmpty ?? false)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    caption!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenVideo(String videoUrl, String? caption) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          videoUrl: videoUrl,
          title: caption ?? 'Diary Video',
          allowFullscreen: true,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildImageAttachment(DiaryMediaAttachment attachment) {
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: 'Diary image attachment',
        hint: attachment.caption?.isNotEmpty == true
            ? 'Image with caption: ${attachment.caption}. Tap to view full screen'
            : 'Tap to view image in full screen',
        isButton: true,
      ),
      button: true,
      image: true,
      child: GestureDetector(
        onTap: () => _showFullScreenImage(attachment.url, attachment.caption),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Semantics(
                  label: 'Diary image',
                  image: true,
                  child: Image.network(
                    attachment.url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: AppColors.surfaceSecondary,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryAccent,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: AppColors.surfaceSecondary,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.errorRed,
                              size: 48,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Failed to load image',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Caption
                if (attachment.caption?.isNotEmpty ?? false)
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMd,
                    color: AppColors.surfacePrimary,
                    child: Text(
                      attachment.caption!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(DiaryMediaAttachment attachment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail with play button
            GestureDetector(
              onTap: () =>
                  _showFullScreenVideo(attachment.url, attachment.caption),
              child: VideoThumbnailWidget(
                videoUrl: attachment.url,
                width: double.infinity,
                height: 200,
                onTap: () =>
                    _showFullScreenVideo(attachment.url, attachment.caption),
              ),
            ),

            // Caption
            if (attachment.caption?.isNotEmpty ?? false)
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingMd,
                color: AppColors.surfacePrimary,
                child: Text(
                  attachment.caption!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioAttachment(DiaryMediaAttachment attachment) {
    final isPlaying = _currentlyPlayingAudio == attachment.id;
    final isLoading =
        _isAudioLoading && _currentlyPlayingAudio == attachment.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.audiotrack,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Recording',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    if (attachment.caption?.isNotEmpty ?? false)
                      Text(
                        attachment.caption!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Audio controls
          Row(
            children: [
              // Play/Pause button
              Semantics(
                label: AccessibilityUtils.createSemanticLabel(
                  label: isLoading
                      ? 'Loading audio'
                      : isPlaying
                      ? 'Pause audio'
                      : 'Play audio',
                  hint: isLoading
                      ? 'Audio is loading, please wait'
                      : isPlaying
                      ? 'Pause the audio playback'
                      : 'Start playing the audio recording',
                  isButton: !isLoading,
                ),
                button: !isLoading,
                enabled: !isLoading,
                child: IconButton(
                  onPressed: isLoading ? null : () => _playAudio(attachment),
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppColors.primaryAccent,
                          size: 28,
                        ),
                  tooltip: isPlaying ? 'Pause audio' : 'Play audio',
                ),
              ),

              // Progress slider
              Expanded(
                child: Column(
                  children: [
                    Semantics(
                      label: AccessibilityUtils.createSemanticLabel(
                        label: 'Audio progress',
                        hint: isPlaying
                            ? 'Drag to seek to different position in audio'
                            : 'Audio progress slider, play audio to enable seeking',
                      ),
                      slider: true,
                      enabled: isPlaying,
                      value: _formatDuration(_audioPosition),
                      increasedValue: _formatDuration(_audioDuration),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primaryAccent,
                          inactiveTrackColor: AppColors.borderMedium,
                          thumbColor: AppColors.primaryAccent,
                          overlayColor: AppColors.primaryAccent.withValues(
                            alpha: 0.2,
                          ),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: _audioDuration.inMilliseconds > 0
                              ? _audioPosition.inMilliseconds /
                                    _audioDuration.inMilliseconds
                              : 0.0,
                          onChanged: isPlaying
                              ? (value) {
                                  final position = Duration(
                                    milliseconds:
                                        (value * _audioDuration.inMilliseconds)
                                            .round(),
                                  );
                                  _seekAudio(position);
                                }
                              : null,
                        ),
                      ),
                    ),

                    // Time display
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_audioPosition),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _formatDuration(_audioDuration),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdDate = widget.diary.createdAt.toDate();
    final lastModified = widget.diary.lastModified?.toDate();

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePrimary,
        elevation: 0,
        leading: Semantics(
          label: AccessibilityUtils.createSemanticLabel(
            label: 'Back to folder',
            hint: 'Return to the memory folder',
            isButton: true,
          ),
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back to folder',
          ),
        ),
        title: Text(
          'Diary Entry',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Favorite toggle button
          Semantics(
            label: AccessibilityUtils.createSemanticLabel(
              label: widget.diary.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              hint: widget.diary.isFavorite 
                ? 'Remove this diary entry from favorites'
                : 'Add this diary entry to favorites for nostalgia reminders',
              isButton: true,
            ),
            button: true,
            child: IconButton(
              icon: Icon(
                widget.diary.isFavorite ? Icons.star : Icons.star_outline,
                color: widget.diary.isFavorite ? AppColors.favoriteYellow : AppColors.textSecondary,
              ),
              onPressed: _toggleFavorite,
              tooltip: widget.diary.isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
          ),
          if (_canUserEdit)
            Semantics(
              label: AccessibilityUtils.createSemanticLabel(
                label: 'Edit diary entry',
                hint: 'Open diary editor to modify this entry',
                isButton: true,
              ),
              button: true,
              child: IconButton(
                icon: Icon(Icons.edit, color: AppColors.primaryAccent),
                onPressed: _editDiary,
                tooltip: 'Edit diary entry',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            if (widget.diary.title?.isNotEmpty ?? false) ...[
              Text(
                widget.diary.title!,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Metadata
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Created: ${createdDate.day}/${createdDate.month}/${createdDate.year} at ${createdDate.hour.toString().padLeft(2, '0')}:${createdDate.minute.toString().padLeft(2, '0')}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  if (lastModified != null && lastModified != createdDate) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Modified: ${lastModified.day}/${lastModified.month}/${lastModified.year} at ${lastModified.hour.toString().padLeft(2, '0')}:${lastModified.minute.toString().padLeft(2, '0')}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (widget.isSharedFolder &&
                      widget.diary.uploadedBy != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Shared by: ${widget.diary.uploadedBy}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Content
            Text(
              widget.diary.content,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),

            // Attachments
            if (widget.diary.attachments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Attachments',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.medium,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Sort attachments by position
              ...(widget.diary.attachments
                    ..sort((a, b) => a.position.compareTo(b.position)))
                  .map((attachment) {
                    switch (attachment.type) {
                      case 'image':
                        return _buildImageAttachment(attachment);
                      case 'video':
                        return _buildVideoAttachment(attachment);
                      case 'audio':
                        return _buildAudioAttachment(attachment);
                      default:
                        return const SizedBox.shrink();
                    }
                  }),
            ],

            // Bottom spacing
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}