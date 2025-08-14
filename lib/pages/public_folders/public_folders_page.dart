import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/folder_model.dart';
import '../../models/user_profile.dart';
import '../../services/folder_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/public_folder_card.dart';
import '../../widgets/error_display_widget.dart';
import '../memory_album/folder_detail_page.dart';

class PublicFoldersPage extends StatefulWidget {
  const PublicFoldersPage({super.key});

  @override
  State<PublicFoldersPage> createState() => _PublicFoldersPageState();
}

class _PublicFoldersPageState extends State<PublicFoldersPage> {
  final FolderService _folderService = FolderService();
  final UserProfileService _userProfileService = UserProfileService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<FolderModel> _folders = [];
  final Map<String, UserProfile> _ownerCache = {};
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  String _searchQuery = '';
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadPublicFolders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFolders();
    }
  }

  Future<void> _loadPublicFolders({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _folders.clear();
        _ownerCache.clear();
        _lastDocument = null;
        _hasMore = true;
      }
    });

    try {
      final folders = await _folderService.getPublicFolders(
        limit: 20,
        startAfter: refresh ? null : _lastDocument,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (folders.isNotEmpty) {
        // Get the last document for pagination
        final query = FirebaseFirestore.instance
            .collection('folders')
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true);

        final snapshot = await query.get();
        final folderIds = folders.map((f) => f.id).toList();
        final lastFolderDoc = snapshot.docs
            .where((doc) => folderIds.contains(doc.id))
            .lastOrNull;

        if (lastFolderDoc != null) {
          _lastDocument = lastFolderDoc;
        }

        // Load owner information for new folders
        await _loadOwnerInfo(folders);
      }

      setState(() {
        if (refresh) {
          _folders = folders;
        } else {
          _folders.addAll(folders);
        }
        _hasMore = folders.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreFolders() async {
    if (!_hasMore || _isLoading) return;
    await _loadPublicFolders();
  }

  Future<void> _loadOwnerInfo(List<FolderModel> folders) async {
    final ownerIds = folders
        .map((f) => f.userId)
        .where((id) => !_ownerCache.containsKey(id))
        .toSet();

    for (final ownerId in ownerIds) {
      try {
        final owner = await _userProfileService.getUserProfile(ownerId);
        if (owner != null) {
          _ownerCache[ownerId] = owner;
        }
      } catch (e) {
        // Continue loading other owners if one fails
        debugPrint('Failed to load owner info for $ownerId: $e');
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadPublicFolders(refresh: true);
      }
    });
  }

  void _onFolderTap(FolderModel folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderDetailPage(
          folder: folder,
          isReadOnly: true, // Public folders are read-only for non-owners
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Folders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search public folders...',
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
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPublicFolders(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _folders.isEmpty) {
      return ErrorDisplayWidget(
        message: _error!,
        onRetry: () => _loadPublicFolders(refresh: true),
      );
    }

    if (_folders.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _folders.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _folders.length) {
          return _buildLoadingIndicator();
        }

        final folder = _folders[index];
        final owner = _ownerCache[folder.userId];
        final isOwnerLoading =
            owner == null && !_ownerCache.containsKey(folder.userId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PublicFolderCard(
            folder: folder,
            owner: owner,
            isLoading: isOwnerLoading,
            onTap: () => _onFolderTap(folder),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No public folders yet' : 'No folders found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Public folders will appear here when users share them'
                : 'Try adjusting your search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
