import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'profile_picture_widget.dart';

class FriendListTile extends StatelessWidget {
  final UserProfile friend;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOnlineStatus;
  final bool isOnline;
  final bool showRemoveOption;
  final VoidCallback? onRemove;

  const FriendListTile({
    super.key,
    required this.friend,
    this.onTap,
    this.trailing,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.showRemoveOption = false,
    this.onRemove,
  });

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend.username} from your friends list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemove?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          ProfilePictureWidget(userProfile: friend, size: 48),
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        friend.username,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: showOnlineStatus
          ? Text(
              isOnline ? 'Online' : 'Offline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOnline
                    ? Colors.green
                    : theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: showRemoveOption && onRemove != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: Icon(
                    Icons.person_remove,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _showRemoveConfirmation(context),
                  tooltip: 'Remove Friend',
                ),
              ],
            )
          : trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// A variant of FriendListTile with a checkbox for selection
class SelectableFriendListTile extends StatelessWidget {
  final UserProfile friend;
  final bool isSelected;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;

  const SelectableFriendListTile({
    super.key,
    required this.friend,
    required this.isSelected,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      value: isSelected,
      onChanged: enabled ? onChanged : null,
      secondary: ProfilePictureWidget(userProfile: friend, size: 48),
      title: Text(
        friend.username,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled
              ? null
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
