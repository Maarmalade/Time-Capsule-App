import 'package:flutter/material.dart';
import '../../widgets/home_panel_card.dart';
// import removed: '../../widgets/nostalgia_reminder_widget.dart';
import '../../services/diary_service.dart';
import '../diary/diary_viewer_page.dart';
import '../../models/diary_entry_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePanelGrid extends StatelessWidget {
  final DiaryService diaryService;
  final void Function(BuildContext, String, String) navigate;
  const HomePanelGrid({required this.diaryService, required this.navigate, super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<DiaryEntry>>(
      stream: diaryService.getNostalgiaEntriesForToday(userId),
      builder: (context, snapshot) {
        final nostalgiaEntries = snapshot.data ?? [];
        final hasNostalgia = nostalgiaEntries.isNotEmpty;
        final nostalgiaEntry = hasNostalgia ? nostalgiaEntries.first : null;
        final List<Widget> cards = [
          HomePanelCard(
            text: 'Access Memory',
            onTap: () => navigate(context, '/memory_album', 'Memory Album'),
          ),
          HomePanelCard(
            text: 'Sent Time Leap Messages',
            onTap: () => navigate(context, '/time_leap_messages', 'Time Leap Messages'),
          ),
          HomePanelCard(
            text: 'Take Digital Diary',
            onTap: () => navigate(context, '/digital_diary', 'Digital Diary'),
          ),
        ];
        if (hasNostalgia && nostalgiaEntry != null) {
          cards.add(
            HomePanelCard(
              text: nostalgiaEntry.title.isNotEmpty ? nostalgiaEntry.title : '${DateTime.now().year - nostalgiaEntry.createdAt.toDate().year} year ago',
              image: (nostalgiaEntry.imageUrl != null && nostalgiaEntry.imageUrl!.isNotEmpty)
                  ? NetworkImage(nostalgiaEntry.imageUrl!)
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryViewerPage(entry: nostalgiaEntry),
                  ),
                );
              },
            ),
          );
        } else {
          // Add a blank card if no nostalgia
          cards.add(
            HomePanelCard(
              text: '',
              onTap: () {},
            ),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          children: cards,
        );
      },
    );
  }
}
