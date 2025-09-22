import 'package:flutter/material.dart';
import '../../widgets/home_panel_card.dart';
import '../../services/media_service.dart';
import '../../services/nostalgia_reminder_service.dart';
import '../../models/diary_entry_model.dart';
import '../diary/diary_viewer_page.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';

class HomePanelGrid extends StatelessWidget {
  final MediaService mediaService;
  final String personalDiaryFolderId;
  final void Function(BuildContext, String, String) navigate;
  const HomePanelGrid({
    required this.mediaService,
    required this.personalDiaryFolderId,
    required this.navigate,
    super.key,
  });

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
            Icon(Icons.history, color: AppColors.primaryAccent, size: 24),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DiaryEntryModel>>(
      stream: mediaService.getFavoriteEntriesForToday(personalDiaryFolderId),
      builder: (context, snapshot) {
        final favoriteEntries = snapshot.data ?? [];
        final hasFavorites = favoriteEntries.isNotEmpty;
        final favoriteEntry = hasFavorites ? favoriteEntries.first : null;
        final List<Widget> cards = [
          HomePanelCard(
            text: 'Memory Album',
            onTap: () => navigate(context, '/memory_album', 'Memory Album'),
          ),
          HomePanelCard(
            text: 'Friends',
            onTap: () => navigate(context, '/friends', 'Friends'),
          ),
          HomePanelCard(
            text: 'Scheduled Messages',
            onTap: () =>
                navigate(context, '/scheduled_messages', 'Scheduled Messages'),
          ),
          HomePanelCard(
            text: 'Community Album',
            onTap: () => navigate(context, '/public_folders', 'Public Folders'),
          ),
          HomePanelCard(
            text: 'Take Digital Diary',
            onTap: () => navigate(context, '/digital_diary', 'Digital Diary'),
          ),
        ];

        if (hasFavorites && favoriteEntry != null) {
          // Show favorite entry (existing logic)
          final imageAttachment = favoriteEntry.attachments
              .where((a) => a.type == 'image')
              .firstOrNull;

          cards.add(
            HomePanelCard(
              text: favoriteEntry.title?.isNotEmpty == true
                  ? favoriteEntry.title!
                  : '${DateTime.now().year - favoriteEntry.diaryDate.toDate().year} year${DateTime.now().year - favoriteEntry.diaryDate.toDate().year > 1 ? 's' : ''} ago',
              image: imageAttachment != null
                  ? NetworkImage(imageAttachment.url)
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryViewerPage(
                      diary: favoriteEntry,
                      folderId: personalDiaryFolderId,
                      canEdit: true,
                      isSharedFolder: false,
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          // Show throwback card when no favorites exist
          cards.add(
            HomePanelCard(
              text: 'Throwback',
              onTap: () => _showThrowbackMessage(context),
            ),
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 1.0,
          children: cards,
        );
      },
    );
  }
}
