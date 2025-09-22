import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateFolderDialog extends StatefulWidget {
  final String? parentFolderId;
  final FolderModel? folderToEdit;

  const CreateFolderDialog({super.key, this.parentFolderId, this.folderToEdit});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.folderToEdit != null) {
      _nameController.text = widget.folderToEdit!.name;
      _descController.text = widget.folderToEdit!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.folderToEdit == null ? 'Create Folder' : 'Rename Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Folder Name'),
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  final folder = FolderModel(
                    id: '', // Leave blank for new folder
                    name: _nameController.text,
                    userId: FirebaseAuth.instance.currentUser!.uid,
                    parentFolderId: widget.parentFolderId,
                    description: _descController.text,
                    coverImageUrl: widget.folderToEdit?.coverImageUrl,
                    createdAt: widget.folderToEdit?.createdAt ?? Timestamp.now(),
                  );
                  final service = FolderService();
                  if (widget.folderToEdit == null) {
                    await service.createFolder(folder);
                  } else {
                    await service.updateFolder(folder.id, {
                      'name': folder.name,
                      'description': folder.description,
                    });
                  }
                  if (mounted) Navigator.pop(context);
                },
          child: Text(widget.folderToEdit == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}