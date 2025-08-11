import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import 'create_folder_dialog.dart';
import 'folder_detail_page.dart';

class MemoryAlbumPage extends StatelessWidget {
  final FolderService _folderService = FolderService();

  MemoryAlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('My Memory Album'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: StreamBuilder<List<FolderModel>>(
        stream: _folderService.streamFolders(userId: user.uid),
        builder: (context, snapshot) {
          final folders = snapshot.data ?? [];
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              // "+" card
              GestureDetector(
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => CreateFolderDialog(parentFolderId: null),
                  );
                },
                child: _FolderCard(
                  name: '+',
                  isAdd: true,
                ),
              ),
              ...folders.map((folder) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FolderDetailPage(folder: folder),
                    ),
                  );
                },
                child: _FolderCard(
                  name: folder.name,
                  coverImageUrl: folder.coverImageUrl,
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final String? coverImageUrl;
  final bool isAdd;

  const _FolderCard({required this.name, this.coverImageUrl, this.isAdd = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: isAdd
              ? const Icon(Icons.add, size: 48, color: Colors.grey)
              : Text(
                  name,
                  style: const TextStyle(fontSize: 24, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}