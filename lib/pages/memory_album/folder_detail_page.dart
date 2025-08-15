import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/folder_model.dart';
import '../../models/media_file_model.dart';
import '../../models/user_profile.dart';
import '../../models/shared_folder_data.dart';
import '../../services/folder_service.dart';
import '../../services/media_service.dart';
import '../../services/storage_service.dart';
import '../../services/profile_picture_service.dart';
import '../shared_folder/shared_folder_settings_page.dart';
import 'create_folder_dialog.dart';
import 'media_viewer_page.dart';
import '../../widgets/folder_card_widget.dart';
import '../../widgets/media_card_widget.dart';
import '../../widgets/edit_name_dialog.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/multi_select_manager.dart';
import '../../widgets/batch_action_bar.dart';
import '../../widgets/profile_picture_widget.dart';
import '../../widgets/folder_settings_dialog.dart';
import '../../constants/route_constants.dart';

class FolderDetailPage extends StatefulWidget {
  final FolderModel folder;
  final bool isReadOnly;
  const FolderDetailPage({
    super.key,
    required this.folder,
    this.isReadOnly = false,
  });

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
  SharedFolderData? _sharedData;
  bool _canContribute = false;
  bool _isOwner = false;
  Map<String, String> _contributorNames = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSharedFolderData();
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

  Future<void> _loadSharedFolderData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      _isOwner = widget.folder.userId == currentUser.uid;

      // Check if this is a shared folder
      final sharedData = await _folderService.getSharedFolderData(
        widget.folder.id,
      );
      final canContribute = await _folderService.canUserContribute(
        widget.folder.id,
        currentUser.uid,
      );

      // Load contributor names for shared folders
      Map<String, String> contributorNames = {};
      if (sharedData != null) {
        // Load owner name
        final ownerProfile = await _getUserProfile(sharedData.ownerId);
        if (ownerProfile != null) {
          contributorNames[sharedData.ownerId] = ownerProfile.username;
        }

        // Load contributor names
        for (final contributorId in sharedData.contributorIds) {
          final profile = await _getUserProfile(contributorId);
          if (profile != null) {
            contributorNames[contributorId] = profile.username;
          }
        }
      }

      if (mounted) {
        setState(() {
          _sharedData = sharedData;
          _canContribute = canContribute;
          _contributorNames = contributorNames;
        });
      }
    } catch (e) {
      // Handle error silently - shared folder data is not critical for basic functionality
      debugPrint('Failed to load shared folder data: $e');
    }
  }

  Future<UserProfile?> _getUserProfile(String userId) async {
    // This is a simplified version - in a real app you'd have a user service
    // For now, we'll create a basic profile
    return UserProfile(
      id: userId,
      email: 'user@example.com',
      username: 'User $userId',
      profilePictureUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _navigateToSharedFolderSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedFolderSettingsPage(
          folderId: widget.folder.id,
          folder: widget.folder,
        ),
      ),
    ).then((_) {
      // Refresh shared folder data when returning from settings
      _loadSharedFolderData();
    });
  }

  void _showFolderSettings() {
    showDialog(
      context: context,
      builder: (context) => FolderSettingsDialog(
        folder: widget.folder,
        isOwner: _isOwner,
        isSharedFolder: _sharedData != null,
        onSettingsChanged: () {
          // Refresh folder data when settings change
          _loadSharedFolderData();
        },
      ),
    );
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
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(widget.folder.name)),
                          if (_sharedData != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                          // Add public indicator
                          FutureBuilder<bool>(
                            future: _folderService.isFolderPublic(
                              widget.folder.id,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data == true) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.public,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      if (_sharedData != null) ...[
                        Text(
                          _sharedData!.isLocked
                              ? 'Locked • ${_isOwner ? 'Owner' : 'Contributor'}'
                              : _isOwner
                              ? 'Owner'
                              : 'Contributor',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _sharedData!.isLocked
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
            actions: _multiSelectManager.isMultiSelectMode
                ? []
                : [
                    if (_sharedData != null && _isOwner) ...[
                      IconButton(
                        icon: const Icon(Icons.people_alt),
                        onPressed: () => _navigateToSharedFolderSettings(),
                        tooltip: 'Shared Folder Settings',
                      ),
                    ],
                    if (_isOwner) ...[
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => _showFolderSettings(),
                        tooltip: 'Folder Settings',
                      ),
                    ],
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
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                    ),
                  ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<FolderModel>>(
                  stream: _folderService.streamUserAccessibleFolders(
                    FirebaseAuth.instance.currentUser!.uid,
                    parentFolderId: widget.folder.id,
                  ),
                  builder: (context, folderSnap) {
                    final subfolders = folderSnap.data ?? [];
                    return StreamBuilder<List<MediaFileModel>>(
                      stream: _mediaService.streamMedia(widget.folder.id),
                      builder: (context, mediaSnap) {
                        final media = mediaSnap.data ?? [];
                        final items = [
                          // "+" card at the top left (hidden in multi-select mode and when user can't contribute)
                          if (!_multiSelectManager.isMultiSelectMode &&
                              _canContribute)
                            GestureDetector(
                              onTap: () => _showAddMenu(context),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 48,
                                        color: _sharedData?.isLocked == true
                                            ? Colors.grey.withValues(alpha: 0.5)
                                            : Colors.grey,
                                      ),
                                      if (_sharedData?.isLocked == true) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Locked',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Show locked message if user can't contribute
                          if (!_multiSelectManager.isMultiSelectMode &&
                              !_canContribute &&
                              _sharedData != null)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 4,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _sharedData!.isLocked
                                          ? Icons.lock
                                          : Icons.visibility,
                                      size: 48,
                                      color: Colors.grey.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _sharedData!.isLocked
                                          ? 'Locked'
                                          : 'View Only',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ...subfolders.map(
                            (f) => FolderCardWidget(
                              folder: f,
                              isSelected: _multiSelectManager.isFolderSelected(
                                f.id,
                              ),
                              isMultiSelectMode:
                                  _multiSelectManager.isMultiSelectMode,
                              onTap: () => _handleFolderTap(f),
                              onLongPress: () => _handleFolderLongPress(f),
                              onEditName: () => _editFolderName(f),
                              onDelete: () => _deleteFolder(f),
                            ),
                          ),
                          ...media.map((m) {
                            // Get contributor name for shared folders
                            String? contributorName;
                            if (_sharedData != null) {
                              // Try to get uploadedBy from media data (this would need to be added to MediaFileModel)
                              // For now, we'll use a placeholder approach
                              contributorName =
                                  _contributorNames.values.isNotEmpty
                                  ? _contributorNames.values.first
                                  : 'Unknown';
                            }

                            return MediaCardWidget(
                              media: m,
                              isSelected: _multiSelectManager.isMediaSelected(
                                m.id,
                              ),
                              isMultiSelectMode:
                                  _multiSelectManager.isMultiSelectMode,
                              isSharedFolder: _sharedData != null,
                              contributorName: contributorName,
                              onTap: () => _handleMediaTap(m),
                              onLongPress: () => _handleMediaLongPress(m),
                              onEditName: () => _editMediaName(m),
                              onDelete: () => _deleteMedia(m),
                            );
                          }),
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
      message:
          'Are you sure you want to delete $itemDescription? This action cannot be undone and will delete all contents.',
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
            duration: Duration(
              seconds: 30,
            ), // Long duration for deletion process
          ),
        );
      }

      try {
        final List<String> errors = [];

        // Delete selected folders using batch operation
        if (_multiSelectManager.selectedFolderIds.isNotEmpty) {
          try {
            await _folderService.deleteFolders(
              _multiSelectManager.selectedFolderIds.toList(),
            );
          } catch (e) {
            errors.add('Folder deletion error: $e');
          }
        }

        // Delete selected media using batch operation
        if (_multiSelectManager.selectedMediaIds.isNotEmpty) {
          try {
            await _mediaService.deleteFiles(
              widget.folder.id,
              _multiSelectManager.selectedMediaIds.toList(),
            );
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
                content: Text(
                  'Deletion completed with some errors: ${errors.join('; ')}',
                ),
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
    // Check if folder is locked
    if (_sharedData?.isLocked == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This folder is locked and cannot accept new content'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_sharedData != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Adding to shared folder',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
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
                    builder: (_) =>
                        CreateFolderDialog(parentFolderId: widget.folder.id),
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
      final currentUser = FirebaseAuth.instance.currentUser!;
      final media = MediaFileModel(
        id: '',
        folderId: widget.folder.id,
        type: 'text',
        url: '', // No file URL for text
        title: titleController.text.trim(),
        description: descController.text.trim(),
        createdAt: Timestamp.now(),
      );

      // Create media with contributor attribution for shared folders
      await _mediaService.createMediaWithAttribution(
        widget.folder.id,
        media,
        currentUser.uid,
        _sharedData != null,
      );
    }
  }

  Future<void> _addImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final file = await picked.readAsBytes();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storagePath =
        'users/$userId/folders/${widget.folder.id}/images/$fileName.jpg';
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

    // Create media with contributor attribution for shared folders
    await _mediaService.createMediaWithAttribution(
      widget.folder.id,
      media,
      userId,
      _sharedData != null,
    );
  }

  Future<void> _addVideo(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = await picked.readAsBytes();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storagePath =
        'users/$userId/folders/${widget.folder.id}/videos/$fileName.mp4';
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

    // Create media with contributor attribution for shared folders
    await _mediaService.createMediaWithAttribution(
      widget.folder.id,
      media,
      userId,
      _sharedData != null,
    );
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
      message:
          'Are you sure you want to delete "${folder.name}"? This action cannot be undone and will delete all contents.',
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
        await _mediaService.updateFileName(
          widget.folder.id,
          media.id,
          newName.trim(),
        );
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
      message:
          'Are you sure you want to delete "${media.title ?? 'this file'}"? This action cannot be undone.',
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete file: $e')));
        }
      }
    }
  }
}
