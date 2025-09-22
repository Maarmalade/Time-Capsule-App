import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../models/user_profile.dart';
import 'profile_picture_widget.dart';

class PublicFolderCard extends StatelessWidget {
  final FolderModel folder;
  final UserProfile? owner;
  final VoidCallback? onTap;
  final bool isLoading;

  const PublicFolderCard({
    super.key,
    required this.folder,
    this.owner,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Folder header with public indicator
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.public,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Public',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description if available
              if (folder.description != null &&
                  folder.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  folder.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Owner information
              Row(
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (owner != null)
                    ProfilePictureWidget(userProfile: owner, size: 32)
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created by',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          isLoading
                              ? 'Loading...'
                              : owner?.username ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(folder.createdAt.toDate()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
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
