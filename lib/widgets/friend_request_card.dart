import 'package:flutter/material.dart';
import '../models/friend_request_model.dart';
import '../models/user_profile.dart';
import 'profile_picture_widget.dart';

class FriendRequestCard extends StatelessWidget {
  final FriendRequest friendRequest;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool isLoading;

  const FriendRequestCard({
    super.key,
    required this.friendRequest,
    this.onAccept,
    this.onDecline,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Create a UserProfile for the profile picture widget
    final senderProfile = UserProfile(
      id: friendRequest.senderId,
      email: '', // Not needed for display
      username: friendRequest.senderUsername,
      profilePictureUrl: friendRequest.senderProfilePictureUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfilePictureWidget(
                  userProfile: senderProfile,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendRequest.senderUsername,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wants to be your friend',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeAgo(friendRequest.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onAccept,
                    icon: isLoading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onDecline,
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}