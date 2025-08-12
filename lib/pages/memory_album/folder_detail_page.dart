import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/folder_model.dart';
import '../../models/media_file_model.dart';
import '../../models/user_profile.dart';
import '../../services/folder_service.dart';
import '../../services/media_service.dart';
import '../../services/storage_service.dart';
import '../../services/profile_picture_service.dart';
import 'create_folder_dialog.dart';
import 'media_viewer_page.dart';
import '../../widgets/folder_card_widget.dart';
import '../../widgets/media_card_widget.dart';
import '../../widgets/edit_name_dialog.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/multi_select_manager.dart';
import '../../widgets/batch_action_bar.dart';
import '../../widgets/profile_picture_widget.dart';
import '../../routes.dart';

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
  final MultiSelectManager _multiSelectManager = MultiSelectManager();
  final ProfilePictureService _profileService = ProfilePictureService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _multiSelectManager.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      // Handle error silently - profile picture is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _multiSelectManager,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            leading: _multiSelectManager.isMultiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _multiSelectManager.exitMultiSelectMode(),
                )
              : const BackButton(),
            title: _multiSelectManager.isMultiSelectMode
              ? Text('${_multiSelectManager.selectedCount} selected')
              : Text(widget.folder.name),
            actions: _multiSelectManager.isMultiSelectMode
              ? []
              : [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, Routes.profile),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ProfilePictureWidget(
                        userProfile: _userProfile,
                        size: 32.0,
                        showBorder: true,
                      ),
                    ),
                  ),
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
                          // "+" card at the top left (hidden in multi-select mode)
                          if (!_multiSelectManager.isMultiSelectMode)
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
                          ...subfolders.map((f) => FolderCardWidget(
                            folder: f,
                            isSelected: _multiSelectManager.isFolderSelected(f.id),
                            isMultiSelectMode: _multiSelectManager.isMultiSelectMode,
                            onTap: () => _handleFolderTap(f),
                            onLongPress: () => _handleFolderLongPress(f),
                            onEditName: () => _editFolderName(f),
                            onDelete: () => _deleteFolder(f),
                          )),
                          ...media.map((m) => MediaCardWidget(
                            media: m,
                            isSelected: _multiSelectManager.isMediaSelected(m.id),
                            isMultiSelectMode: _multiSelectManager.isMultiSelectMode,
                            onTap: () => _handleMediaTap(m),
                            onLongPress: () => _handleMediaLongPress(m),
                            onEditName: () => _editMediaName(m),
                            onDelete: () => _deleteMedia(m),
                          )),
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
              
              // Batch action bar
              if (_multiSelectManager.isMultiSelectMode)
                BatchActionBar(
                  selectedCount: _multiSelectManager.selectedCount,
                  onDelete: _handleBatchDelete,
                  onCancel: () => _multiSelectManager.exitMultiSelectMode(),
                ),
            ],
          ),
        );
      },
    );
  }

  // Multi-select handlers
  void _handleFolderTap(FolderModel folder) {
    if (_multiSelectManager.isMultiSelectMode) {
      _multiSelectManager.toggleFolderSelection(folder.id);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FolderDetailPage(folder: folder)),
      );
    }
  }

  void _handleFolderLongPress(FolderModel folder) {
    if (!_multiSelectManager.isMultiSelectMode) {
      _multiSelectManager.startWithFolder(folder.id);
    }
  }

  void _handleMediaTap(MediaFileModel media) {
    if (_multiSelectManager.isMultiSelectMode) {
      _multiSelectManager.toggleMediaSelection(media.id);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MediaViewerPage(media: media)),
      );
    }
  }

  void _handleMediaLongPress(MediaFileModel media) {
    if (!_multiSelectManager.isMultiSelectMode) {
      _multiSelectManager.startWithMedia(media.id);
    }
  }

  Future<void> _handleBatchDelete() async {
    final selectedCount = _multiSelectManager.selectedCount;
    final folderCount = _multiSelectManager.selectedFolderIds.length;
    final mediaCount = _multiSelectManager.selectedMediaIds.length;
    
    // Create a more detailed confirmation message
    String itemDescription;
    if (folderCount > 0 && mediaCount > 0) {
      itemDescription = '$folderCount folder(s) and $mediaCount file(s)';
    } else if (folderCount > 0) {
      itemDescription = '$folderCount folder(s)';
    } else {
      itemDescription = '$mediaCount file(s)';
    }
    
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Items',
      message: 'Are you sure you want to delete $itemDescription? This action cannot be undone and will delete all contents.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.delete_forever,
    );

    if (confirmed) {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Deleting items...'),
              ],
            ),
            duration: Duration(seconds: 30), // Long duration for deletion process
          ),
        );
      }

      try {
        final List<String> errors = [];

        // Delete selected folders using batch operation
        if (_multiSelectManager.selectedFolderIds.isNotEmpty) {
          try {
            await _folderService.deleteFolders(_multiSelectManager.selectedFolderIds.toList());
          } catch (e) {
            errors.add('Folder deletion error: $e');
          }
        }

        // Delete selected media using batch operation
        if (_multiSelectManager.selectedMediaIds.isNotEmpty) {
          try {
            await _mediaService.deleteFiles(widget.folder.id, _multiSelectManager.selectedMediaIds.toList());
          } catch (e) {
            errors.add('File deletion error: $e');
          }
        }

        _multiSelectManager.exitMultiSelectMode();

        if (mounted) {
          // Hide loading indicator
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (errors.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$selectedCount item(s) deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deletion completed with some errors: ${errors.join('; ')}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        _multiSelectManager.exitMultiSelectMode();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete items: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
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

  // Edit folder name functionality
  Future<void> _editFolderName(FolderModel folder) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => EditNameDialog(
        currentName: folder.name,
        title: 'Edit Folder Name',
        hintText: 'Enter folder name',
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        await _folderService.updateFolderName(folder.id, newName.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder name updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update folder name: $e')),
          );
        }
      }
    }
  }

  // Delete folder functionality
  Future<void> _deleteFolder(FolderModel folder) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Folder',
      message: 'Are you sure you want to delete "${folder.name}"? This action cannot be undone and will delete all contents.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.delete_forever,
    );

    if (confirmed) {
      try {
        await _folderService.deleteFolder(folder.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete folder: $e')),
          );
        }
      }
    }
  }

  // Edit media name functionality
  Future<void> _editMediaName(MediaFileModel media) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => EditNameDialog(
        currentName: media.title ?? '',
        title: 'Edit File Name',
        hintText: 'Enter file name',
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        await _mediaService.updateFileName(widget.folder.id, media.id, newName.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File name updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update file name: $e')),
          );
        }
      }
    }
  }

  // Delete media functionality
  Future<void> _deleteMedia(MediaFileModel media) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete File',
      message: 'Are you sure you want to delete "${media.title ?? 'this file'}"? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.delete_forever,
    );

    if (confirmed) {
      try {
        await _mediaService.deleteMedia(widget.folder.id, media.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete file: $e')),
          );
        }
      }
    }
  }
}

