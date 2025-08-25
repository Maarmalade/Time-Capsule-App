import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../services/folder_service.dart';
import '../constants/route_constants.dart';
import 'confirmation_dialog.dart';
import '../design_system/app_colors.dart';

class FolderSettingsDialog extends StatefulWidget {
  final FolderModel folder;
  final bool isOwner;
  final bool isSharedFolder;
  final VoidCallback? onSettingsChanged;

  const FolderSettingsDialog({
    super.key,
    required this.folder,
    required this.isOwner,
    this.isSharedFolder = false,
    this.onSettingsChanged,
  });

  @override
  State<FolderSettingsDialog> createState() => _FolderSettingsDialogState();
}

class _FolderSettingsDialogState extends State<FolderSettingsDialog> {
  final FolderService _folderService = FolderService();
  bool _isPublic = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolderSettings();
  }

  Future<void> _loadFolderSettings() async {
    try {
      final isPublic = await _folderService.isFolderPublic(widget.folder.id);
      if (mounted) {
        setState(() {
          _isPublic = isPublic;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSharedFolderSettings() {
    if (widget.isSharedFolder) {
      Navigator.pushNamed(
        context,
        Routes.sharedFolderSettings,
        arguments: {'folderId': widget.folder.id, 'folder': widget.folder},
      );
    } else {
      Navigator.pushNamed(
        context,
        Routes.convertToSharedFolder,
        arguments: {'folder': widget.folder},
      ).then((result) {
        // If the folder was successfully converted to shared, call the callback
        if (result == true && widget.onSettingsChanged != null) {
          widget.onSettingsChanged!();
        }
      });
    }
  }

  Future<void> _togglePublicVisibility(bool makePublic) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: makePublic ? 'Make Folder Public' : 'Make Folder Private',
      message: makePublic
          ? 'This will make your folder visible to all users. Anyone will be able to view its contents, but only you and contributors can modify it. Are you sure?'
          : 'This will make your folder private. Only you and contributors will be able to view it. Are you sure?',
      confirmText: makePublic ? 'Make Public' : 'Make Private',
      confirmColor: makePublic
          ? Colors.orange
          : Theme.of(context).colorScheme.primary,
      icon: makePublic ? Icons.public : Icons.lock,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (makePublic) {
        await _folderService.makePublic(widget.folder.id);
      } else {
        await _folderService.makePrivate(widget.folder.id);
      }

      if (mounted) {
        setState(() {
          _isPublic = makePublic;
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              makePublic
                  ? 'Folder is now public and visible to all users'
                  : 'Folder is now private',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Notify parent of changes
        widget.onSettingsChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update folder visibility: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Folder Settings'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Folder name
            Text(
              widget.folder.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Folder type indicator
            Row(
              children: [
                Icon(
                  widget.isSharedFolder ? Icons.people : Icons.folder,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isSharedFolder ? 'Shared Folder' : 'Personal Folder',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sharing section
            if (widget.isOwner) ...[
              Text(
                'Sharing',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Share with friends button
              if (!widget.isSharedFolder)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToSharedFolderSettings();
                    },
                    icon: const Icon(Icons.people_alt),
                    label: const Text('Share with Friends'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToSharedFolderSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Manage Contributors'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

              Text(
                'Visibility',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Column(
                  children: [
                    Text(
                      'Error loading settings: $_error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadFolderSettings,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else ...[
                // Public visibility toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Row(
                      children: [
                        Icon(
                          _isPublic ? Icons.public : Icons.lock,
                          size: 20,
                          color: _isPublic
                              ? Colors.orange
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPublic ? 'Public' : 'Private',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      _isPublic
                          ? 'Anyone can view this folder'
                          : 'Only you and contributors can view this folder',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: _isPublic,
                    onChanged: (value) => _togglePublicVisibility(value),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),

                const SizedBox(height: 16),

                // Public visibility info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isPublic
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isPublic ? Icons.info : Icons.security,
                        size: 16,
                        color: _isPublic
                            ? Colors.orange
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isPublic
                              ? 'Public folders appear in the public folder discovery page. Other users can view the contents but cannot modify them unless they are contributors.'
                              : 'Private folders are only visible to you and any contributors you\'ve invited.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _isPublic
                                    ? Colors.orange.shade700
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Non-owner view
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only the folder owner can change visibility settings.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
