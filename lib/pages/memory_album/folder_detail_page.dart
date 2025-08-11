import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/folder_model.dart';
import '../../models/media_file_model.dart';
import '../../services/folder_service.dart';
import '../../services/media_service.dart';
import '../../services/storage_service.dart';
import 'create_folder_dialog.dart';
import 'media_viewer_page.dart';

class FolderDetailPage extends StatefulWidget {
  final FolderModel folder;
  const FolderDetailPage({super.key, required this.folder});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  final FolderService _folderService = FolderService();
  final MediaService _mediaService = MediaService();
  final StorageService _storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(widget.folder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<FolderModel>>(
              stream: _folderService.streamFolders(
                userId: FirebaseAuth.instance.currentUser!.uid,
                parentFolderId: widget.folder.id,
              ),
              builder: (context, folderSnap) {
                final subfolders = folderSnap.data ?? [];
                return StreamBuilder<List<MediaFileModel>>(
                  stream: _mediaService.streamMedia(widget.folder.id),
                  builder: (context, mediaSnap) {
                    final media = mediaSnap.data ?? [];
                    final items = [
                      // "+" card at the top left
                      GestureDetector(
                        onTap: () => _showAddMenu(context),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 4,
                          child: const Center(
                            child: Icon(Icons.add, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                      ...subfolders.map((f) => _FolderCard(folder: f)),
                      ...media.map((m) => _MediaCard(media: m)),
                    ];
                    return GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: items,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Add Text File'),
                onTap: () async {
                  Navigator.pop(context);
                  await _addTextFile(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Add Image'),
                onTap: () async {
                  Navigator.pop(context);
                  await _addImage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Add Video'),
                onTap: () async {
                  Navigator.pop(context);
                  await _addVideo(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('Add Nested Folder'),
                onTap: () async {
                  Navigator.pop(context);
                  await showDialog(
                    context: context,
                    builder: (_) => CreateFolderDialog(parentFolderId: widget.folder.id),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTextFile(BuildContext context) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty) {
      final media = MediaFileModel(
        id: '',
        folderId: widget.folder.id,
        type: 'text',
        url: '', // No file URL for text
        title: titleController.text.trim(),
        description: descController.text.trim(),
        createdAt: Timestamp.now(),
      );
      await _mediaService.createMedia(widget.folder.id, media);
    }
  }

  Future<void> _addImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final file = await picked.readAsBytes();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storagePath = 'users/$userId/folders/${widget.folder.id}/images/$fileName.jpg';
    final url = await _storageService.uploadFileBytes(file, storagePath);
    final media = MediaFileModel(
      id: '',
      folderId: widget.folder.id,
      type: 'image',
      url: url,
      title: 'Image',
      description: '',
      createdAt: Timestamp.now(),
    );
    await _mediaService.createMedia(widget.folder.id, media);
  }

  Future<void> _addVideo(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = await picked.readAsBytes();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storagePath = 'users/$userId/folders/${widget.folder.id}/videos/$fileName.mp4';
    final url = await _storageService.uploadFileBytes(file, storagePath);
    final media = MediaFileModel(
      id: '',
      folderId: widget.folder.id,
      type: 'video',
      url: url,
      title: 'Video',
      description: '',
      createdAt: Timestamp.now(),
    );
    await _mediaService.createMedia(widget.folder.id, media);
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