import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_folder_dialog.dart';
import 'folder_detail_page.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import '../../widgets/folder_card_widget.dart';
import '../../widgets/edit_name_dialog.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/multi_select_manager.dart';
import '../../widgets/batch_action_bar.dart';
import '../../utils/error_handler.dart';
import '../../widgets/error_display_widget.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';

class MemoryAlbumPage extends StatefulWidget {
  const MemoryAlbumPage({super.key});

  @override
  State<MemoryAlbumPage> createState() => _MemoryAlbumPageState();
}

class _MemoryAlbumPageState extends State<MemoryAlbumPage> {
  final FolderService _folderService = FolderService();
  final MultiSelectManager _multiSelectManager = MultiSelectManager();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _multiSelectManager.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return ListenableBuilder(
      listenable: _multiSelectManager,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.surfacePrimary,
          appBar: AppBar(
            leading: _multiSelectManager.isMultiSelectMode
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _multiSelectManager.exitMultiSelectMode(),
                  )
                : BackButton(
                    color: AppColors.textPrimary,
                  ),
            title: _multiSelectManager.isMultiSelectMode
                ? Text(
                    '${_multiSelectManager.selectedCount} selected',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  )
                : Text(
                    'My Memory Album',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
            actions: _multiSelectManager.isMultiSelectMode
                ? []
                : [
                    IconButton(
                      icon: Icon(
                        Icons.home,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                    ),
                  ],
            bottom: _multiSelectManager.isMultiSelectMode
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search Memory Album',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.cardRadius,
                          ),
                          filled: true,
                          fillColor: AppColors.surfacePrimary,
                        ),
                      ),
                    ),
                  ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<FolderModel>>(
                  stream: _folderService.streamUserAccessibleFolders(
                    userId,
                    parentFolderId: null,
                    searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                  ),
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
                    
                    // Show empty state if no folders found and search is active
                    if (folders.isEmpty && _searchQuery.isNotEmpty) {
                      return _buildEmptySearchState();
                    }
                    
                    final items = [
                      // "+" card at the top left (hidden in multi-select mode and search mode)
                      if (!_multiSelectManager.isMultiSelectMode && _searchQuery.isEmpty)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await showDialog(
                                context: context,
                                builder: (_) =>
                                    CreateFolderDialog(parentFolderId: null),
                              );
                            },
                            borderRadius: AppSpacing.cardRadius,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfacePrimary,
                                borderRadius: AppSpacing.cardRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowMedium,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  size: 48,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ...folders.map(
                        (folder) => FolderCardWidget(
                          folder: folder,
                          isSelected: _multiSelectManager.isFolderSelected(
                            folder.id,
                          ),
                          isMultiSelectMode:
                              _multiSelectManager.isMultiSelectMode,
                          onTap: () => _handleFolderTap(folder),
                          onLongPress: () => _handleFolderLongPress(folder),
                          onEditName: () => _editFolderName(folder),
                          onDelete: () => _deleteFolder(folder),
                        ),
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: 2,
                      padding: AppSpacing.paddingMd,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.0,
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
        MaterialPageRoute(builder: (_) => FolderDetailPage(folder: folder)),
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
      message:
          'Are you sure you want to delete $folderCount folder(s)? This action cannot be undone and will delete all contents.',
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
            duration: Duration(
              seconds: 30,
            ), // Long duration for deletion process
          ),
        );
      }

      try {
        // Delete selected folders using batch operation
        await _folderService.deleteFolders(
          _multiSelectManager.selectedFolderIds.toList(),
        );

        _multiSelectManager.exitMultiSelectMode();

        if (mounted) {
          // Hide loading indicator
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ErrorHandler.showSuccessSnackBar(
            context,
            '$selectedCount folder(s) deleted successfully',
          );
        }
      } catch (e) {
        _multiSelectManager.exitMultiSelectMode();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ErrorHandler.showErrorSnackBar(
            context,
            message: ErrorHandler.getErrorMessage(e),
          );
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
          ErrorHandler.showSuccessSnackBar(
            context,
            'Folder name updated successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            message: ErrorHandler.getErrorMessage(e),
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
          ErrorHandler.showSuccessSnackBar(
            context,
            'Folder deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            message: ErrorHandler.getErrorMessage(e),
          );
        }
      }
    }
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No folders found',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your search terms',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
}
