import 'package:flutter/material.dart';
import '../../models/diary_entry_model.dart';
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
            icon: Icon(entry.isFavorite ? Icons.star : Icons.star_border,
                color: entry.isFavorite ? Colors.yellow : null),
            onPressed: () {}, // Could implement favorite toggle here
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiaryEntryPage(date: entry.date, entry: entry),
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            Text(entry.text, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ...entry.media.map((m) => m.type == 'image'
                    ? Image.network(m.url, width: 60, height: 60)
                    : Icon(Icons.videocam, size: 60)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}