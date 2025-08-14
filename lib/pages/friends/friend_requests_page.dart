import 'package:flutter/material.dart';
import '../../models/friend_request_model.dart';
import '../../services/friend_service.dart';
import '../../widgets/friend_request_card.dart';
import '../../utils/error_handler.dart';

class FriendRequestsPage extends StatefulWidget {
  final FriendService? friendService;
  
  const FriendRequestsPage({super.key, this.friendService});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late final FriendService _friendService;
  
  List<FriendRequest> _friendRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _processingRequests = {};

  @override
  void initState() {
    super.initState();
    _friendService = widget.friendService ?? FriendService();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final requests = await _friendService.getFriendRequests();
      
      setState(() {
        _friendRequests = requests.where((request) => request.isPending()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    try {
      setState(() {
        _processingRequests.add(request.id);
      });

      await _friendService.respondToFriendRequest(request.id, true);
      
      // Remove the request from the list
      setState(() {
        _friendRequests.removeWhere((r) => r.id == request.id);
        _processingRequests.remove(request.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now friends with ${request.senderUsername}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: 'View Friends',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                Navigator.of(context).pop(); // Go back to friends page
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _processingRequests.remove(request.id);
      });
      
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

  Future<void> _declineFriendRequest(FriendRequest request) async {
    try {
      setState(() {
        _processingRequests.add(request.id);
      });

      await _friendService.respondToFriendRequest(request.id, false);
      
      // Remove the request from the list
      setState(() {
        _friendRequests.removeWhere((r) => r.id == request.id);
        _processingRequests.remove(request.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined friend request from ${request.senderUsername}'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _processingRequests.remove(request.id);
      });
      
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriendRequests,
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

    if (_friendRequests.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildRequestsList(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading friend requests...',
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
              'Error Loading Requests',
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
              onPressed: _loadFriendRequests,
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
              'No Friend Requests',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any pending friend requests at the moment.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to friends page
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Find Friends'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
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
              '${_friendRequests.length} pending request${_friendRequests.length == 1 ? '' : 's'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Requests list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _friendRequests.length,
              itemBuilder: (context, index) {
                final request = _friendRequests[index];
                final isProcessing = _processingRequests.contains(request.id);

                return FriendRequestCard(
                  friendRequest: request,
                  onAccept: () => _acceptFriendRequest(request),
                  onDecline: () => _declineFriendRequest(request),
                  isLoading: isProcessing,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}