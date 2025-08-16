import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/folder_card_widget.dart';
import '../memory_album/folder_detail_page.dart';

class SharedFoldersPage extends StatefulWidget {
  final UserProfile friend;

  const SharedFoldersPage({
    super.key,
    required this.friend,
  });

  @override
  State<SharedFoldersPage> createState() => _SharedFoldersPageState();
}

class _SharedFoldersPageState extends State<SharedFoldersPage> {
  final FolderService _folderService = FolderService();
  
  List<FolderModel> _sharedFolders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSharedFolders();
  }

  Future<void> _loadSharedFolders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final folders = await _folderService.getSharedFoldersBetweenUsers(widget.friend.id);
      
      setState(() {
        _sharedFolders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Shared with ${widget.friend.username}'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSharedFolders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (_sharedFolders.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildFoldersList(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading shared folders...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Shared Folders',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSharedFolders,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_shared_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Shared Folders',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any folders shared with ${widget.friend.username} yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Friends'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadSharedFolders,
      child: Column(
        children: [
          // Header with count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Text(
              '${_sharedFolders.length} shared folder${_sharedFolders.length == 1 ? '' : 's'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Folders list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sharedFolders.length,
              itemBuilder: (context, index) {
                final folder = _sharedFolders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FolderCardWidget(
                    folder: folder,
                    onTap: () {
                      // Navigate to folder contents
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FolderDetailPage(
                            folder: folder,
                            isReadOnly: false, // Allow interaction with shared folder content
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}