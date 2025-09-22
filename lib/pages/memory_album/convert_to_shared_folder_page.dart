import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/folder_model.dart';
import '../../models/user_profile.dart';
import '../../services/folder_service.dart';
import '../../services/friend_service.dart';
import '../../widgets/contributor_selector.dart';
import '../../widgets/error_display_widget.dart';
import '../../utils/error_handler.dart';

class ConvertToSharedFolderPage extends StatefulWidget {
  final FolderModel folder;

  const ConvertToSharedFolderPage({super.key, required this.folder});

  @override
  State<ConvertToSharedFolderPage> createState() =>
      _ConvertToSharedFolderPageState();
}

class _ConvertToSharedFolderPageState extends State<ConvertToSharedFolderPage> {
  final FolderService _folderService = FolderService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserProfile> _availableFriends = [];
  List<String> _selectedContributorIds = [];
  bool _isLoading = true;
  bool _isConverting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final friends = await _friendService.getFriends();

      if (mounted) {
        setState(() {
          _availableFriends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _convertToSharedFolder() async {
    if (_selectedContributorIds.isEmpty) {
      setState(() {
        _error = 'Please select at least one friend to share with';
      });
      return;
    }

    try {
      setState(() {
        _isConverting = true;
        _error = null;
      });

      await _folderService.convertToSharedFolder(
        widget.folder.id,
        _selectedContributorIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder "${widget.folder.name}" is now shared!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to folder detail page
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorMessage(e);
          _isConverting = false;
        });
      }
    }
  }

  void _onContributorsChanged(List<String> contributorIds) {
    setState(() {
      _selectedContributorIds = contributorIds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Folder'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _availableFriends.isEmpty
          ? ErrorDisplayWidget(message: _error!, onRetry: _loadFriends)
          : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      children: [
        // Folder info card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.folder.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.folder.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.folder.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Select friends to share this folder with. They will be able to add content to the folder.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Error display
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Friends list
        Expanded(
          child: _availableFriends.isEmpty
              ? _buildNoFriendsState(theme)
              : ContributorSelector(
                  availableFriends: _availableFriends,
                  selectedContributorIds: _selectedContributorIds,
                  onSelectionChanged: _onContributorsChanged,
                  maxSelections: 20,
                ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isConverting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isConverting || _selectedContributorIds.isEmpty
                      ? null
                      : _convertToSharedFolder,
                  child: _isConverting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Share Folder'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoFriendsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Friends Available',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need friends to share this folder with.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to add friends page
              Navigator.pushNamed(context, '/add-friend');
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friends'),
          ),
        ],
      ),
    );
  }
}
