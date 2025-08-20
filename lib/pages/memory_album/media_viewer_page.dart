import 'package:flutter/material.dart';
import '../../models/media_file_model.dart';
import '../../services/video_integration_service.dart';

class MediaViewerPage extends StatelessWidget {
  final MediaFileModel media;
  const MediaViewerPage({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (media.type == 'image') {
      content = InteractiveViewer(
        child: Image.network(media.url),
      );
    } else if (media.type == 'video') {
      content = VideoIntegrationService.createInlineVideoPlayer(
        videoUrl: media.url,
        autoPlay: false,
        showControls: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video playback error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } else if (media.type == 'text') {
      content = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              media.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 16),
            Text(media.description ?? '', style: const TextStyle(fontSize: 18)),
          ],
        ),
      );
    } else if (media.type == 'audio') {
      content = const Center(child: Icon(Icons.volume_up, size: 120));
    } else {
      content = const Center(child: Icon(Icons.insert_drive_file, size: 120));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(media.title ?? 'Media'),
      ),
      body: Center(child: content),
    );
  }
}