import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../models/media_file_model.dart';
import '../../services/folder_service.dart';
import '../../services/media_service.dart';
import 'create_folder_dialog.dart';
import 'media_viewer_page.dart';

class FolderDetailPage extends StatelessWidget {
  final FolderModel folder;
  final FolderService _folderService = FolderService();
  final MediaService _mediaService = MediaService();

  FolderDetailPage({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(folder.name),
      ),
      // ...existing code...
    );
  }
}

// Modal bottom sheet for add options (must be at file top level)
class _AddOptionsSheet extends StatelessWidget {
  final String parentFolderId;
  const _AddOptionsSheet({required this.parentFolderId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('Add Folder'),
            onTap: () async {
              Navigator.pop(context);
              await showDialog(
                context: context,
                builder: (_) => CreateFolderDialog(parentFolderId: parentFolderId),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Add Image'),
            onTap: () async {
              Navigator.pop(context);
              // TODO: Implement image picker and upload
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image picker not implemented')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Add Text'),
            onTap: () async {
              Navigator.pop(context);
              // TODO: Implement text input dialog
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text input not implemented')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Add Video'),
            onTap: () async {
              Navigator.pop(context);
              // TODO: Implement video picker and upload
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video picker not implemented')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.audiotrack),
            title: const Text('Add Audio'),
            onTap: () async {
              Navigator.pop(context);
              // TODO: Implement audio picker and upload
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio picker not implemented')));
            },
          ),
        ],
      ),
    );
  }
}


class _AddCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        child: const Center(
          child: Icon(Icons.add, size: 48, color: Colors.grey),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FolderModel folder;
  const _FolderCard({required this.folder});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FolderDetailPage(folder: folder)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        child: Center(
          child: Text(
            folder.name,
            style: const TextStyle(fontSize: 20, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaFileModel media;
  const _MediaCard({required this.media});
  @override
  Widget build(BuildContext context) {
    Widget content;
    if (media.type == 'image') {
      content = GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MediaViewerPage(media: media)),
          );
        },
        child: Image.network(media.url, width: 60, height: 60),
      );
    } else if (media.type == 'video') {
      content = GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MediaViewerPage(media: media)),
          );
        },
        child: Icon(Icons.videocam, size: 60),
      );
    } else if (media.type == 'text') {
      content = GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MediaViewerPage(media: media)),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              media.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Text(
              media.description ?? '',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      content = const Icon(Icons.insert_drive_file, size: 60);
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Center(child: content),
    );
  }
}