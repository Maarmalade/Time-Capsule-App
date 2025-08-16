import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/folder_model.dart';
import '../../models/shared_folder_data.dart';
import '../../models/user_profile.dart';
import '../../services/folder_service.dart';
import '../../services/friend_service.dart';
import '../../widgets/contributor_selector.dart';
import '../../widgets/friend_list_tile.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/error_display_widget.dart';

class SharedFolderSettingsPage extends StatefulWidget {
  final String folderId;
  final FolderModel folder;

  const SharedFolderSettingsPage({
    super.key,
    required this.folderId,
    required this.folder,
  });

  @override
  State<SharedFolderSettingsPage> createState() =>
      _SharedFolderSettingsPageState();
}

class _SharedFolderSettingsPageState extends State<SharedFolderSettingsPage> {
  final FolderService _folderService = FolderService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SharedFolderData? _sharedData;
  List<UserProfile> _contributors = [];
  List<UserProfile> _availableFriends = [];
  bool _isLoading = true;
  String? _error;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      _isOwner = widget.folder.userId == currentUser.uid;

      // Load shared folder data
      final sharedData = await _folderService.getSharedFolderData(
        widget.folderId,
      );
      if (sharedData == null) {
        throw Exception('This is not a shared folder');
      }

      // Load contributor profiles using the proper service method
      final contributorProfiles = await _folderService.getFolderContributors(
        widget.folderId,
      );

      // Load available friends (only for owner)
      List<UserProfile> availableFriends = [];
      if (_isOwner) {
        availableFriends = await _friendService.getFriends();
      }

      setState(() {
        _sharedData = sharedData;
        _contributors = contributorProfiles;
        _availableFriends = availableFriends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _inviteContributors() async {
    if (!_isOwner || _sharedData == null) return;

    final selectedIds = await showContributorSelectorDialog(
      context: context,
      availableFriends: _availableFriends,
      initialSelectedIds: [],
      title: 'Invite Contributors',
      subtitle: 'Select friends to invite as contributors to this folder',
    );

    if (selectedIds == null || selectedIds.isEmpty) return;

    try {
      await _folderService.inviteContributors(widget.folderId, selectedIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contributors invited successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite contributors: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeContributor(UserProfile contributor) async {
    if (!_isOwner || _sharedData == null) return;

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Remove Contributor',
      message:
          'Are you sure you want to remove ${contributor.username} as a contributor?\n\n'
          '• They will no longer be able to add content to this folder\n'
          '• They will be notified about the removal\n'
          '• This action cannot be undone',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    try {
      await _folderService.removeContributor(widget.folderId, contributor.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${contributor.username} removed as contributor'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove contributor: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleFolderLock() async {
    if (!_isOwner || _sharedData == null) return;

    final isLocked = _sharedData!.isLocked;
    final action = isLocked ? 'unlock' : 'lock';
    final actionTitle = isLocked ? 'Unlock Folder' : 'Lock Folder';

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: actionTitle,
      message: isLocked
          ? 'Are you sure you want to unlock this folder? Contributors will be able to add content again.'
          : 'Are you sure you want to lock this folder? Contributors will no longer be able to add new content.',
      confirmText: isLocked ? 'Unlock' : 'Lock',
      cancelText: 'Cancel',
      confirmColor: !isLocked ? Colors.orange : null,
    );

    if (confirmed != true) return;

    try {
      if (isLocked) {
        await _folderService.unlockFolder(widget.folderId);
      } else {
        await _folderService.lockFolder(widget.folderId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Folder ${isLocked ? 'unlocked' : 'locked'} successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action folder: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Folder Settings'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorDisplayWidget(message: _error!, onRetry: _loadData)
          : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_sharedData == null) {
      return const Center(child: Text('Failed to load shared folder data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder info card
          _buildFolderInfoCard(theme),
          const SizedBox(height: 16),

          // Lock status card
          _buildLockStatusCard(theme),
          const SizedBox(height: 16),

          // Contributors section
          _buildContributorsSection(theme),
        ],
      ),
    );
  }

  Widget _buildFolderInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_shared, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Folder Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', widget.folder.name, theme),
            if (widget.folder.description != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Description', widget.folder.description!, theme),
            ],
            const SizedBox(height: 8),
            _buildInfoRow('Role', _isOwner ? 'Owner' : 'Contributor', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  Widget _buildLockStatusCard(ThemeData theme) {
    final isLocked = _sharedData!.isLocked;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: isLocked
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Folder Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isLocked
                  ? 'This folder is locked. Contributors cannot add new content.'
                  : 'This folder is unlocked. Contributors can add new content.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_isOwner) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _toggleFolderLock,
                  icon: Icon(isLocked ? Icons.lock_open : Icons.lock),
                  label: Text(isLocked ? 'Unlock Folder' : 'Lock Folder'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isLocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributorsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Contributors',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isOwner && !_sharedData!.isLocked) ...[
                  IconButton(
                    onPressed: _inviteContributors,
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Invite Contributors',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            if (_contributors.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No contributors yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_isOwner) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _inviteContributors,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Invite Contributors'),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contributors.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final contributor = _contributors[index];
                  return FriendListTile(
                    friend: contributor,
                    trailing: _isOwner && !_sharedData!.isLocked
                        ? IconButton(
                            onPressed: () => _removeContributor(contributor),
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove Contributor',
                            color: theme.colorScheme.error,
                          )
                        : null,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
