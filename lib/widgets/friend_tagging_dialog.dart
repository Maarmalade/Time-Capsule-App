import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/friend_service.dart';

class FriendTaggingDialog extends StatefulWidget {
  final List<String> initialTags;
  final String? currentUserId;

  const FriendTaggingDialog({
    super.key,
    this.initialTags = const [],
    this.currentUserId,
  });

  @override
  State<FriendTaggingDialog> createState() => _FriendTaggingDialogState();
}

class _FriendTaggingDialogState extends State<FriendTaggingDialog> {
  final FriendService _friendService = FriendService();
  List<UserProfile> _friends = [];
  List<String> _selectedTags = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
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

  void _toggleTag(String userId) {
    setState(() {
      if (_selectedTags.contains(userId)) {
        _selectedTags.remove(userId);
      } else {
        _selectedTags.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.person_add,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Tag Friends'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select friends to tag in this media:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load friends',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFriends,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_friends.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No friends to tag',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add friends to tag them in your media',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final isSelected = _selectedTags.contains(friend.id);
                    
                    return CheckboxListTile(
                      title: Text(friend.username),
                      subtitle: friend.email.isNotEmpty 
                          ? Text(friend.email)
                          : null,
                      secondary: CircleAvatar(
                        backgroundImage: friend.profilePictureUrl != null
                            ? NetworkImage(friend.profilePictureUrl!)
                            : null,
                        child: friend.profilePictureUrl == null
                            ? Text(
                                friend.username.isNotEmpty 
                                    ? friend.username[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      value: isSelected,
                      onChanged: (value) => _toggleTag(friend.id),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    );
                  },
                ),
              ),
            
            // Selected tags summary
            if (_selectedTags.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Selected (${_selectedTags.length}):',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedTags.map((userId) {
                  final friend = _friends.firstWhere(
                    (f) => f.id == userId,
                    orElse: () => UserProfile(
                      id: userId,
                      email: '',
                      username: 'Unknown',
                      profilePictureUrl: null,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  
                  return Chip(
                    label: Text(friend.username),
                    onDeleted: () => _toggleTag(userId),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedTags),
          child: const Text('Done'),
        ),
      ],
    );
  }

  static Future<List<String>?> show({
    required BuildContext context,
    List<String> initialTags = const [],
    String? currentUserId,
  }) async {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => FriendTaggingDialog(
        initialTags: initialTags,
        currentUserId: currentUserId,
      ),
    );
  }
}