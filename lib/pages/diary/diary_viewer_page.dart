import 'package:flutter/material.dart';
import '../../models/diary_entry_model.dart';
import '../../services/video_integration_service.dart';
import 'diary_entry_page.dart';

class DiaryViewerPage extends StatelessWidget {
  final DiaryEntry entry;
  const DiaryViewerPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${entry.date.day} ${_monthName(entry.date.month)} ${entry.date.year}';
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(dateStr),
        actions: [
          IconButton(
            icon: Icon(
              entry.isFavorite ? Icons.star : Icons.star_border,
              color: entry.isFavorite ? Colors.yellow : null,
            ),
            onPressed: () {}, // Could implement favorite toggle here
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DiaryEntryPage(date: entry.date, entry: entry),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(entry.text, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ...entry.media.map(
                  (m) => m.type == 'image'
                      ? GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: InteractiveViewer(
                                  child: Container(
                                    color: Colors.black,
                                    child: Image.network(
                                      m.url,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Image.network(m.url, width: 60, height: 60),
                        )
                      : GestureDetector(
                          onTap: () => _playVideo(context, m.url),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.videocam, size: 30),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, String videoUrl) {
    VideoIntegrationService.showFullScreenVideo(
      context,
      videoUrl,
      title: 'Diary Video',
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}
