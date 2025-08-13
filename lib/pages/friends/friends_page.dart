import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/friend_service.dart';
import '../../widgets/friend_list_tile.dart';
import '../../utils/error_handler.dart';
import 'add_friend_page.dart';
import 'friend_requests_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserProfile> _allFriends = [];
  List<UserProfile> _filteredFriends = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final friends = await _friendService.getFriends();
      
      setState(() {
        _allFriends = friends;
        _filteredFriends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _filterFriends(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) => friend.username.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _removeFriend(UserProfile friend) async {
    try {
      await _friendService.removeFriend(friend.id);
      
      // Remove friend from both lists
      setState(() {
        _allFriends.removeWhere((f) => f.id == friend.id);
        _filteredFriends.removeWhere((f) => f.id == friend.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${friend.username} from friends'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Note: In a real app, you might want to implement undo functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo is not implemented yet'),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToAddFriend() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddFriendPage(),
      ),
    ).then((_) {
      // Refresh friends list when returning from add friend page
      _loadFriends();
    });
  }

  void _navigateToFriendRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FriendRequestsPage(),
      ),
    ).then((_) {
      // Refresh friends list when returning from requests page
      _loadFriends();
    });
  }

  void _navigateToSharedFolders(UserProfile friend) {
    // TODO: Navigate to shared folders with this friend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared folders with ${friend.username} - Coming soon!'),
      ),
    );
  }

  void _navigateToMessaging(UserProfile friend) {
    // TODO: Navigate to messaging with this friend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Messaging with ${friend.username} - Coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToAddFriend,
            tooltip: 'Add Friend',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _navigateToFriendRequests,
            tooltip: 'Friend Requests',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriends,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          if (_allFriends.isNotEmpty) _buildSearchSection(theme),
          
          // Friends List
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFriend,
        tooltip: 'Add Friend',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search friends...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterFriends('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _filterFriends,
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (_allFriends.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (_filteredFriends.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResultsState(theme);
    }

    return _buildFriendsList(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading friends...',
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
              'Error Loading Friends',
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
              onPressed: _loadFriends,
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
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Friends Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your network by adding friends!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddFriend,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friends'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _navigateToFriendRequests,
              icon: const Icon(Icons.notifications),
              label: const Text('Check Requests'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No friends match "$_searchQuery"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _filterFriends('');
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: Column(
        children: [
          // Header with count
          if (_searchQuery.isEmpty)
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
                '${_filteredFriends.length} friend${_filteredFriends.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Friends list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];

                return FriendListTile(
                  friend: friend,
                  showRemoveOption: true,
                  onTap: () => _showFriendOptions(friend),
                  onRemove: () => _removeFriend(friend),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(UserProfile friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Friend info
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  friend.username[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                friend.username,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: const Text('Friend'),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            ListTile(
              leading: const Icon(Icons.folder_shared),
              title: const Text('Shared Folders'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSharedFolders(friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _navigateToMessaging(friend);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person_remove,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Remove Friend',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeFriend(friend);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}