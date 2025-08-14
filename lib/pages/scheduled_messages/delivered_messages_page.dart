import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/scheduled_message_model.dart';
import '../../models/user_profile.dart';
import '../../services/scheduled_message_service.dart';
import '../../services/friend_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/profile_picture_widget.dart';

class DeliveredMessagesPage extends StatefulWidget {
  const DeliveredMessagesPage({super.key});

  @override
  State<DeliveredMessagesPage> createState() => _DeliveredMessagesPageState();
}

class _DeliveredMessagesPageState extends State<DeliveredMessagesPage> {
  final ScheduledMessageService _messageService = ScheduledMessageService();
  final FriendService _friendService = FriendService();

  List<ScheduledMessage> _messages = [];
  List<UserProfile> _friends = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, from_self, from_friends

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final results = await Future.wait([
        _messageService.getReceivedMessages(currentUser.uid),
        _friendService.getFriends(),
      ]);

      setState(() {
        _messages = results[0] as List<ScheduledMessage>;
        _friends = results[1] as List<UserProfile>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  List<ScheduledMessage> get _filteredMessages {
    var filtered = _messages.where((message) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!message.textContent.toLowerCase().contains(query)) {
          final sender = _getSenderProfile(message);
          if (sender == null ||
              !sender.username.toLowerCase().contains(query)) {
            return false;
          }
        }
      }

      // Category filter
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        switch (_selectedFilter) {
          case 'from_self':
            return message.senderId == currentUser.uid;
          case 'from_friends':
            return message.senderId != currentUser.uid;
          case 'all':
          default:
            return true;
        }
      }
      return true;
    }).toList();

    // Sort by delivery date (most recent first)
    filtered.sort((a, b) {
      final aDate = a.deliveredAt ?? a.scheduledFor;
      final bDate = b.deliveredAt ?? b.scheduledFor;
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  UserProfile? _getSenderProfile(ScheduledMessage message) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (message.senderId == currentUser?.uid) {
      return null; // Self message
    }

    return _friends.firstWhere(
      (friend) => friend.id == message.senderId,
      orElse: () => UserProfile(
        id: message.senderId,
        username: 'Unknown User',
        email: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivered Messages'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: _selectedFilter != 'all'
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
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
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState(theme)
                : _errorMessage != null
                ? _buildErrorState(theme)
                : _buildMessagesList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Error Loading Messages',
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
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme) {
    final filteredMessages = _filteredMessages;

    if (filteredMessages.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final message = filteredMessages[index];
          return DeliveredMessageCard(
            message: message,
            senderProfile: _getSenderProfile(message),
            onTap: () => _showMessageDetails(message),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String title;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      title = 'No Messages Found';
      subtitle = 'Try adjusting your search or filter criteria';
      icon = Icons.search_off;
    } else if (_selectedFilter == 'from_self') {
      title = 'No Messages from Yourself';
      subtitle = 'Messages you sent to yourself will appear here';
      icon = Icons.person;
    } else if (_selectedFilter == 'from_friends') {
      title = 'No Messages from Friends';
      subtitle = 'Messages from friends will appear here when delivered';
      icon = Icons.people;
    } else {
      title = 'No Delivered Messages';
      subtitle =
          'Messages sent to you will appear here when they are delivered';
      icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Messages'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('From Myself'),
              value: 'from_self',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('From Friends'),
              value: 'from_friends',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessageDetails(ScheduledMessage message) {
    showDialog(
      context: context,
      builder: (context) => MessageDetailsDialog(
        message: message,
        senderProfile: _getSenderProfile(message),
      ),
    );
  }
}

class DeliveredMessageCard extends StatelessWidget {
  final ScheduledMessage message;
  final UserProfile? senderProfile;
  final VoidCallback onTap;

  const DeliveredMessageCard({
    super.key,
    required this.message,
    required this.senderProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isFromSelf = message.senderId == currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sender info and delivery date
              Row(
                children: [
                  if (isFromSelf) ...[
                    Icon(
                      Icons.person,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'From: Myself',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    ProfilePictureWidget(userProfile: senderProfile!, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'From: ${senderProfile!.username}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(message.deliveredAt ?? message.scheduledFor),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Message preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.textContent.length > 120
                      ? '${message.textContent.substring(0, 120)}...'
                      : message.textContent,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Footer with video indicator and read more
              Row(
                children: [
                  if (message.videoUrl != null) ...[
                    Icon(
                      Icons.videocam,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Video attached',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    const Spacer(),
                  ],
                  Text(
                    'Tap to read full message',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class MessageDetailsDialog extends StatelessWidget {
  final ScheduledMessage message;
  final UserProfile? senderProfile;

  const MessageDetailsDialog({
    super.key,
    required this.message,
    required this.senderProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isFromSelf = message.senderId == currentUser?.uid;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (isFromSelf) ...[
                    Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message from',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          'Myself',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ProfilePictureWidget(userProfile: senderProfile!, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message from',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          senderProfile!.username,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        message.textContent,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),

                    // Video section (if video exists)
                    if (message.videoUrl != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _playVideo(context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                size: 64,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Video Message',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to play',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Message metadata
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            context,
                            Icons.schedule,
                            'Originally scheduled for',
                            _formatDateTime(message.scheduledFor),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            Icons.check_circle,
                            'Delivered at',
                            _formatDateTime(
                              message.deliveredAt ?? message.scheduledFor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            Icons.create,
                            'Created on',
                            _formatDateTime(message.createdAt),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            Icons.timer,
                            'Delivery delay',
                            _getDeliveryDelay(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareMessage(context),
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyMessage(context),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Text'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getDeliveryDelay() {
    final deliveredAt = message.deliveredAt ?? message.scheduledFor;
    final delay = deliveredAt.difference(message.scheduledFor);

    if (delay.inMinutes < 1) {
      return 'On time';
    } else if (delay.inMinutes < 60) {
      return '${delay.inMinutes} minute${delay.inMinutes == 1 ? '' : 's'} late';
    } else if (delay.inHours < 24) {
      return '${delay.inHours} hour${delay.inHours == 1 ? '' : 's'} late';
    } else {
      return '${delay.inDays} day${delay.inDays == 1 ? '' : 's'} late';
    }
  }

  void _playVideo(BuildContext context) {
    // TODO: Implement video player
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video playback not yet implemented')),
    );
  }

  void _shareMessage(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing not yet implemented')),
    );
  }

  void _copyMessage(BuildContext context) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Text copied to clipboard')));
  }
}
