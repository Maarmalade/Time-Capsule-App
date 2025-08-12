import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_folder_dialog.dart';
import 'folder_detail_page.dart';
import '../../models/folder_model.dart';
import '../../models/user_profile.dart';
import '../../services/folder_service.dart';
import '../../services/profile_picture_service.dart';
import '../../routes.dart';
import '../../widgets/folder_card_widget.dart';
import '../../widgets/edit_name_dialog.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/multi_select_manager.dart';
import '../../widgets/batch_action_bar.dart';
import '../../widgets/profile_picture_widget.dart';
import '../../utils/error_handler.dart';
import '../../widgets/error_display_widget.dart';

class MemoryAlbumPage extends StatefulWidget {
  const MemoryAlbumPage({super.key});

  @override
  State<MemoryAlbumPage> createState() => _MemoryAlbumPageState();
}

class _MemoryAlbumPageState extends State<MemoryAlbumPage> {
  final FolderService _folderService = FolderService();
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
    final userId = FirebaseAuth.instance.currentUser!.uid;
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
              : const Text('My Memory Album'),
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
                  stream: _folderService.streamFolders(userId: userId, parentFolderId: null),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorDisplayWidget(
                        message: ErrorHandler.getErrorMessage(snapshot.error),
                        onRetry: () {
                          setState(() {}); // Trigger rebuild to retry
                        },
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final folders = snapshot.data ?? [];
                    final items = [
                      // "+" card at the top left (hidden in multi-select mode)
                      if (!_multiSelectManager.isMultiSelectMode)
                        GestureDetector(
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (_) => CreateFolderDialog(parentFolderId: null),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 4,
                            child: const Center(
                              child: Icon(Icons.add, size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ...folders.map((folder) => FolderCardWidget(
                        folder: folder,
                        isSelected: _multiSelectManager.isFolderSelected(folder.id),
                        isMultiSelectMode: _multiSelectManager.isMultiSelectMode,
                        onTap: () => _handleFolderTap(folder),
                        onLongPress: () => _handleFolderLongPress(folder),
                        onEditName: () => _editFolderName(folder),
                        onDelete: () => _deleteFolder(folder),
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
        MaterialPageRoute(
          builder: (_) => FolderDetailPage(folder: folder),
        ),
      );
    }
  }

  void _handleFolderLongPress(FolderModel folder) {
    if (!_multiSelectManager.isMultiSelectMode) {
      _multiSelectManager.startWithFolder(folder.id);
    }
  }

  Future<void> _handleBatchDelete() async {
    final selectedCount = _multiSelectManager.selectedCount;
    final folderCount = _multiSelectManager.selectedFolderIds.length;
    
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Folders',
      message: 'Are you sure you want to delete $folderCount folder(s)? This action cannot be undone and will delete all contents.',
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
                Text('Deleting folders...'),
              ],
            ),
            duration: Duration(seconds: 30), // Long duration for deletion process
          ),
        );
      }

      try {
        // Delete selected folders using batch operation
        await _folderService.deleteFolders(_multiSelectManager.selectedFolderIds.toList());

        _multiSelectManager.exitMultiSelectMode();

        if (mounted) {
          // Hide loading indicator
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          ErrorHandler.showSuccessSnackBar(context, '$selectedCount folder(s) deleted successfully');
        }
      } catch (e) {
        _multiSelectManager.exitMultiSelectMode();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
        }
      }
    }
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
          ErrorHandler.showSuccessSnackBar(context, 'Folder name updated successfully');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
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
          ErrorHandler.showSuccessSnackBar(context, 'Folder deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
        }
      }
    }
  }
}