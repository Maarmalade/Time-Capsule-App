import 'dart:io';
import 'package:flutter/material.dart';
import 'media_attachment_widget.dart';

/// Example usage of MediaAttachmentWidget for scheduled messages
class MediaAttachmentExample extends StatefulWidget {
  const MediaAttachmentExample({super.key});

  @override
  State<MediaAttachmentExample> createState() => _MediaAttachmentExampleState();
}

class _MediaAttachmentExampleState extends State<MediaAttachmentExample> {
  List<File> _selectedImages = [];
  File? _selectedVideo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Attachment Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Scheduled Message with Media',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Text input field
            const TextField(
              decoration: InputDecoration(
                labelText: 'Message Text',
                border: OutlineInputBorder(),
                hintText: 'Enter your message here...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Media attachment widget
            MediaAttachmentWidget(
              selectedImages: _selectedImages,
              selectedVideo: _selectedVideo,
              onImagesChanged: (images) {
                setState(() {
                  _selectedImages = images;
                });
              },
              onVideoChanged: (video) {
                setState(() {
                  _selectedVideo = video;
                });
              },
              maxImages: 5,
              maxImageSizeMB: 10,
              maxVideoSizeMB: 50,
            ),
            
            const Spacer(),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasContent() ? _createScheduledMessage : null,
                    child: const Text('Schedule Message'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAll,
                    child: const Text('Clear All'),
                  ),
                ),
              ],
            ),
            
            // Status display
            if (_hasContent()) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to schedule:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${_selectedImages.length} image(s)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (_selectedVideo != null)
                      Text(
                        '• 1 video',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasContent() {
    return _selectedImages.isNotEmpty || _selectedVideo != null;
  }

  void _createScheduledMessage() {
    // This would integrate with ScheduledMessageService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Would create scheduled message with ${_selectedImages.length} images'
          '${_selectedVideo != null ? ' and 1 video' : ''}',
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _selectedImages = [];
      _selectedVideo = null;
    });
  }
}