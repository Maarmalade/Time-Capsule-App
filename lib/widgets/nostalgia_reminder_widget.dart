import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/media_service.dart';
import '../services/nostalgia_reminder_service.dart';
import '../models/diary_entry_model.dart';
import '../pages/diary/diary_viewer_page.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';
import '../utils/accessibility_utils.dart';

class NostalgiaReminderWidget extends StatefulWidget {
  final MediaService mediaService;
  final String personalDiaryFolderId;
  const NostalgiaReminderWidget({
    super.key, 
    required this.mediaService,
    required this.personalDiaryFolderId,
  });

  @override
  State<NostalgiaReminderWidget> createState() => _NostalgiaReminderWidgetState();
}

class _NostalgiaReminderWidgetState extends State<NostalgiaReminderWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAudio;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showThrowbackMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Icon(
              Icons.history,
              color: AppColors.primaryAccent,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Throwback',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          NostalgiaReminderService.getThrowbackMessage(),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playAudio(String audioUrl, String entryId) async {
    try {
      if (_currentlyPlayingAudio == entryId) {
        // Stop if already playing this audio
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingAudio = null;
        });
      } else {
        // Stop any currently playing audio and play new one
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(audioUrl));
        setState(() {
          _currentlyPlayingAudio = entryId;
        });
        
        // Listen for completion
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _currentlyPlayingAudio = null;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildMediaPreview(DiaryEntryModel entry) {
    // Check for different media types in order of preference
    final audioMedia = entry.attachments.where((m) => m.type == 'audio').firstOrNull;
    final imageMedia = entry.attachments.where((m) => m.type == 'image').firstOrNull;
    final videoMedia = entry.attachments.where((m) => m.type == 'video').firstOrNull;

    if (audioMedia != null) {
      // Audio preview with play button
      return Container(
        width: 156,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.audiotrack,
              size: 32,
              color: AppColors.primaryAccent,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _playAudio(audioMedia.url, entry.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentlyPlayingAudio == entry.id 
                        ? Icons.stop 
                        : Icons.play_arrow,
                    size: 16,
                    color: AppColors.primaryWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (imageMedia != null) {
      // Image preview
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageMedia.url,
          width: 156,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 156,
              height: 70,
              color: AppColors.surfaceSecondary,
              child: Icon(
                Icons.broken_image,
                size: 32,
                color: AppColors.textSecondary,
              ),
            );
          },
        ),
      );
    } else if (videoMedia != null) {
      // Video preview with play icon
      return Container(
        width: 156,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 32,
              color: AppColors.textSecondary,
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                size: 16,
                color: AppColors.primaryWhite,
              ),
            ),
          ],
        ),
      );
    } else {
      // Default diary icon
      return Container(
        width: 156,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.book,
          size: 32,
          color: AppColors.textSecondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<DiaryEntryModel>>(
      stream: widget.mediaService.getFavoriteEntriesForToday(widget.personalDiaryFolderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: AppSpacing.paddingMd,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryAccent,
              ),
            ),
          );
        }
        
        final entries = snapshot.data ?? [];
        
        // Show throwback card when no favorites exist
        if (entries.isEmpty) {
          return Semantics(
            label: AccessibilityUtils.createSemanticLabel(
              label: 'Throwback',
              hint: 'No favourited entries from past years. Tap to learn more',
              isButton: true,
            ),
            button: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: AppColors.favoriteYellow,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Throwback',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () => _showThrowbackMessage(context),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surfacePrimary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: AppColors.favoriteYellow.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 32,
                            color: AppColors.favoriteYellow,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No favourited memories yet',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Tap to learn more',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        }

        return Semantics(
          label: AccessibilityUtils.createSemanticLabel(
            label: 'Nostalgia reminders',
            hint: 'Favourite entries from this day in previous years',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.favoriteYellow,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Favourite from this day',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    final yearsAgo = DateTime.now().year - entry.diaryDate.toDate().year;
                    
                    return Semantics(
                      label: AccessibilityUtils.createSemanticLabel(
                        label: 'Favourite: ${entry.title?.isNotEmpty == true ? entry.title! : 'Untitled'}',
                        hint: '$yearsAgo year${yearsAgo > 1 ? 's' : ''} ago. Tap to view full favourite',
                        isButton: true,
                      ),
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiaryViewerPage(
                                diary: entry,
                                folderId: widget.personalDiaryFolderId,
                                canEdit: true,
                                isSharedFolder: false,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 180,
                          decoration: BoxDecoration(
                            color: AppColors.surfacePrimary,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Media preview
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: _buildMediaPreview(entry),
                              ),
                              
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.sm,
                                    0,
                                    AppSpacing.sm,
                                    AppSpacing.sm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title?.isNotEmpty == true ? entry.title! : 'Untitled Favourite',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.titleSmall.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '$yearsAgo year${yearsAgo > 1 ? 's' : ''} ago',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.favoriteYellow,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (entry.content.isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            entry.content,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}