import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/scheduled_message_model.dart';
import '../../models/user_profile.dart';
import '../../services/scheduled_message_service.dart';
import '../../services/friend_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/profile_picture_widget.dart';
import '../../widgets/media_attachment_widget.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ScheduledMessagesPage extends StatefulWidget {
  const ScheduledMessagesPage({super.key});

  @override
  State<ScheduledMessagesPage> createState() => _ScheduledMessagesPageState();
}

class _ScheduledMessagesPageState extends State<ScheduledMessagesPage>
    with SingleTickerProviderStateMixin {
  final ScheduledMessageService _messageService = ScheduledMessageService();
  final FriendService _friendService = FriendService();

  late TabController _tabController;
  List<ScheduledMessage> _scheduledMessages = [];
  List<ScheduledMessage> _receivedMessages = [];
  List<UserProfile> _friends = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<ScheduledMessage>>? _scheduledMessagesSubscription;
  StreamSubscription<List<ScheduledMessage>>? _receivedMessagesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scheduledMessagesSubscription?.cancel();
    _receivedMessagesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible
    _refreshData();
  }

  void _setupStreams() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Set up real-time streams for message updates
    _scheduledMessagesSubscription = _messageService
        .streamScheduledMessages(currentUser.uid)
        .listen((messages) {
          if (mounted) {
            setState(() {
              _scheduledMessages = messages;
            });
          }
        });

    _receivedMessagesSubscription = _messageService
        .streamReceivedMessages(currentUser.uid)
        .listen((messages) {
          if (mounted) {
            setState(() {
              _receivedMessages = messages;
            });
          }
        });

    // Set up periodic check for ready messages
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _messageService.checkReadyMessages();
      } else {
        timer.cancel();
      }
    });
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

      // Load friends data
      final friends = await _friendService.getFriends();

      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  /// Refresh data to ensure latest status is displayed
  Future<void> _refreshData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Refresh friends data
      final friends = await _friendService.getFriends();

      setState(() {
        _friends = friends;
      });
    } catch (e) {
      // Silently handle refresh errors to avoid disrupting user experience
      debugPrint('Error refreshing data: $e');
    }
  }

  Future<void> _showCreateMessageDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CreateScheduledMessageDialog(
        friends: _friends,
        onMessageCreated: _loadData,
      ),
    );
  }

  Future<void> _showDebugInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final result = await _messageService.triggerMessageDelivery();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cloud Function Result:'),
                  const SizedBox(height: 8),
                  Text(result.toString()),
                  const SizedBox(height: 16),
                  Text('Scheduled Messages: ${_scheduledMessages.length}'),
                  Text('Received Messages: ${_receivedMessages.length}'),
                  const SizedBox(height: 16),
                  Text('Current Time: ${DateTime.now()}'),
                ],
              ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug error: $e'),
            backgroundColor: Colors.red,
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
        title: const Text('Scheduled Messages'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Checking for ready messages...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
              
              // Trigger cloud function and local checks
              await _messageService.triggerCloudFunctionDelivery();
              await _messageService.checkReadyMessages();
              await _refreshData();
              
              // Hide loading and show success
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Messages refreshed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Refresh Messages',
          ),
          // Debug button (only in debug mode)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _showDebugInfo,
              tooltip: 'Debug Info',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scheduled', icon: Icon(Icons.schedule)),
            Tab(text: 'Received', icon: Icon(Icons.inbox)),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(theme)
          : _errorMessage != null
          ? _buildErrorState(theme)
          : TabBarView(
              controller: _tabController,
              children: [_buildScheduledTab(theme), _buildReceivedTab(theme)],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMessageDialog,
        child: const Icon(Icons.add),
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

  Widget _buildScheduledTab(ThemeData theme) {
    if (_scheduledMessages.isEmpty) {
      return _buildEmptyScheduledState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scheduledMessages.length,
        itemBuilder: (context, index) {
          final message = _scheduledMessages[index];
          return ScheduledMessageCard(
            message: message,
            friends: _friends,
            onCancel: () => _cancelMessage(message),
          );
        },
      ),
    );
  }

  Widget _buildReceivedTab(ThemeData theme) {
    if (_receivedMessages.isEmpty) {
      return _buildEmptyReceivedState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedMessages.length,
        itemBuilder: (context, index) {
          final message = _receivedMessages[index];
          return ReceivedMessageCard(message: message, friends: _friends);
        },
      ),
    );
  }

  Widget _buildEmptyScheduledState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Messages',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first scheduled message to send to yourself or friends in the future',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateMessageDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReceivedState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Received Messages',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Messages sent to you will appear here when they are delivered',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _cancelMessage(ScheduledMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Message'),
        content: const Text(
          'Are you sure you want to cancel this scheduled message?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _messageService.cancelScheduledMessage(message.id);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message cancelled successfully')),
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
  }
}

class CreateScheduledMessageDialog extends StatefulWidget {
  final List<UserProfile> friends;
  final VoidCallback onMessageCreated;

  const CreateScheduledMessageDialog({
    super.key,
    required this.friends,
    required this.onMessageCreated,
  });

  @override
  State<CreateScheduledMessageDialog> createState() =>
      _CreateScheduledMessageDialogState();
}

class _CreateScheduledMessageDialogState
    extends State<CreateScheduledMessageDialog> {
  final ScheduledMessageService _messageService = ScheduledMessageService();
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  UserProfile? _selectedRecipient;
  DateTime? _selectedDateTime;
  bool _isCreating = false;
  String? _errorMessage;

  // Media attachment state
  List<File> _selectedImages = [];
  File? _selectedVideo;
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onImagesChanged(List<File> images) {
    setState(() {
      _selectedImages = images;
    });
  }

  void _onVideoChanged(File? video) {
    setState(() {
      _selectedVideo = video;
    });
  }

  bool _hasContent() {
    return _textController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedVideo != null;
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createMessage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      setState(() {
        _errorMessage = 'Please select a delivery date and time';
      });
      return;
    }

    // Validate that there's some content (text or media)
    if (!_hasContent()) {
      setState(() {
        _errorMessage = 'Please add a message or media attachment';
      });
      return;
    }

    try {
      setState(() {
        _isCreating = true;
        _isUploadingMedia =
            _selectedImages.isNotEmpty || _selectedVideo != null;
        _uploadProgress = 0.0;
        _errorMessage = null;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final recipientId = _selectedRecipient?.id ?? currentUser.uid;

      final message = ScheduledMessage(
        id: '',
        senderId: currentUser.uid,
        recipientId: recipientId,
        textContent: _textController.text.trim(),
        imageUrls: null, // Will be set by createScheduledMessageWithMedia
        videoUrl: null, // Will be set by createScheduledMessageWithMedia
        scheduledFor: _selectedDateTime!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ScheduledMessageStatus.pending,
      );

      // Use createScheduledMessageWithMedia if there are media attachments
      if (_selectedImages.isNotEmpty || _selectedVideo != null) {
        // Simulate upload progress for better UX
        _simulateUploadProgress();

        await _messageService.createScheduledMessageWithMedia(
          message,
          _selectedImages.isNotEmpty ? _selectedImages : null,
          _selectedVideo,
        );
      } else {
        // Use regular createScheduledMessage for text-only messages
        await _messageService.createScheduledMessage(message);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMessageCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedImages.isNotEmpty || _selectedVideo != null
                  ? 'Message with media scheduled successfully'
                  : 'Message scheduled successfully',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isCreating = false;
        _isUploadingMedia = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _simulateUploadProgress() {
    // Simulate upload progress for better user experience
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isUploadingMedia) {
        timer.cancel();
        return;
      }

      setState(() {
        _uploadProgress += 0.05;
        if (_uploadProgress >= 1.0) {
          _uploadProgress = 1.0;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Scheduled Message',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Recipient Selection
                Text(
                  'Send to:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserProfile?>(
                  value: _selectedRecipient,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select recipient',
                  ),
                  items: [
                    DropdownMenuItem<UserProfile?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.person, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Myself'),
                        ],
                      ),
                    ),
                    ...widget.friends.map(
                      (friend) => DropdownMenuItem<UserProfile?>(
                        value: friend,
                        child: Row(
                          children: [
                            ProfilePictureWidget(userProfile: friend, size: 24),
                            const SizedBox(width: 8),
                            Text(friend.username),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRecipient = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Message Content
                Text(
                  'Message:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write your message...',
                  ),
                  maxLines: 4,
                  maxLength: 5000,
                  validator: (value) {
                    // Text is optional if media is attached
                    if ((value == null || value.trim().isEmpty) &&
                        _selectedImages.isEmpty &&
                        _selectedVideo == null) {
                      return 'Please enter a message or add media';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Clear error when user starts typing
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Media Attachments
                Text(
                  'Media Attachments:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                MediaAttachmentWidget(
                  selectedImages: _selectedImages,
                  selectedVideo: _selectedVideo,
                  onImagesChanged: _onImagesChanged,
                  onVideoChanged: _onVideoChanged,
                  maxImages: 5,
                  maxImageSizeMB: 10,
                  maxVideoSizeMB: 50,
                ),
                const SizedBox(height: 16),

                // Delivery Date/Time
                Text(
                  'Delivery Date & Time:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDateTime,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDateTime != null
                              ? _formatDateTime(_selectedDateTime!)
                              : 'Select date and time',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _selectedDateTime != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Upload progress indicator
                if (_isUploadingMedia) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Uploading media...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
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
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isCreating ? null : _createMessage,
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Schedule'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class ScheduledMessageCard extends StatelessWidget {
  final ScheduledMessage message;
  final List<UserProfile> friends;
  final VoidCallback onCancel;

  const ScheduledMessageCard({
    super.key,
    required this.message,
    required this.friends,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isToSelf = message.recipientId == currentUser?.uid;

    UserProfile? recipient;
    if (!isToSelf) {
      recipient = friends.firstWhere(
        (friend) => friend.id == message.recipientId,
        orElse: () => UserProfile(
          id: message.recipientId,
          username: 'Unknown User',
          email: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with recipient and status
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isToSelf) ...[
                        Icon(
                          Icons.person,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'To: Myself',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        ProfilePictureWidget(userProfile: recipient!, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'To: ${recipient.username}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(theme),
              ],
            ),
            const SizedBox(height: 12),

            // Message content preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.textContent.length > 150
                    ? '${message.textContent.substring(0, 150)}...'
                    : message.textContent,
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Media attachments display
            if (message.hasMedia()) ...[
              const SizedBox(height: 12),
              _buildMediaSection(context, theme),
            ],

            const SizedBox(height: 12),

            // Delivery info and actions - Fixed layout to prevent overflow
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getDeliveryIcon(),
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getDeliveryText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (message.isPending()) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getTimeUntilDelivery(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (message.status) {
      case ScheduledMessageStatus.pending:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        icon = Icons.schedule;
        text = 'Pending';
        break;
      case ScheduledMessageStatus.delivered:
        backgroundColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        icon = Icons.check_circle;
        text = 'Delivered';
        break;
      case ScheduledMessageStatus.failed:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        icon = Icons.error;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments:',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Display image thumbnails
              if (message.imageUrls != null && message.imageUrls!.isNotEmpty)
                ...message.imageUrls!.map(
                  (imageUrl) => _buildImageThumbnail(context, imageUrl, theme),
                ),

              // Display video preview
              if (message.videoUrl != null)
                _buildVideoThumbnail(message.videoUrl!, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    String imageUrl,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imageUrl),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.videocam,
        color: theme.colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  IconData _getDeliveryIcon() {
    switch (message.status) {
      case ScheduledMessageStatus.pending:
        return Icons.schedule;
      case ScheduledMessageStatus.delivered:
        return Icons.check_circle;
      case ScheduledMessageStatus.failed:
        return Icons.error;
    }
  }

  String _getDeliveryText() {
    switch (message.status) {
      case ScheduledMessageStatus.pending:
        return 'Delivers: ${_formatDateTime(message.scheduledFor)}';
      case ScheduledMessageStatus.delivered:
        return 'Delivered: ${_formatDateTime(message.deliveredAt ?? message.scheduledFor)}';
      case ScheduledMessageStatus.failed:
        return 'Failed to deliver';
    }
  }

  String _getTimeUntilDelivery() {
    if (!message.isPending()) return '';

    final now = DateTime.now();
    final difference = message.scheduledFor.difference(now);

    if (difference.isNegative) {
      return 'Ready for delivery';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes';
    } else {
      return 'Less than a minute';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class ReceivedMessageCard extends StatelessWidget {
  final ScheduledMessage message;
  final List<UserProfile> friends;

  const ReceivedMessageCard({
    super.key,
    required this.message,
    required this.friends,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isFromSelf = message.senderId == currentUser?.uid;

    UserProfile? sender;
    if (!isFromSelf) {
      sender = friends.firstWhere(
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sender info
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isFromSelf) ...[
                        Icon(
                          Icons.person,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'From: Myself',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        ProfilePictureWidget(userProfile: sender!, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'From: ${sender.username}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(theme),
              ],
            ),
            const SizedBox(height: 12),

            // Message content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.textContent,
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Media attachments display
            if (message.hasMedia()) ...[
              const SizedBox(height: 12),
              _buildMediaSection(context, theme),
            ],

            const SizedBox(height: 12),

            // Delivery info
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ready: ${_formatDateTime(message.scheduledFor)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _showMessageDetails(context),
                  child: const Text('Tap to read'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    if (message.isDelivered()) {
      backgroundColor = theme.colorScheme.tertiaryContainer;
      textColor = theme.colorScheme.onTertiaryContainer;
      icon = Icons.check_circle;
      text = 'Delivered';
    } else {
      backgroundColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
      icon = Icons.schedule;
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments:',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Display image thumbnails
              if (message.imageUrls != null && message.imageUrls!.isNotEmpty)
                ...message.imageUrls!.map(
                  (imageUrl) => _buildImageThumbnail(context, imageUrl, theme),
                ),

              // Display video preview
              if (message.videoUrl != null)
                _buildVideoThumbnail(message.videoUrl!, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    String imageUrl,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imageUrl),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.videocam,
        color: theme.colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  void _showMessageDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          MessageViewDialog(message: message, friends: friends),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class MessageViewDialog extends StatelessWidget {
  final ScheduledMessage message;
  final List<UserProfile> friends;

  const MessageViewDialog({
    super.key,
    required this.message,
    required this.friends,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isFromSelf = message.senderId == currentUser?.uid;

    UserProfile? sender;
    if (!isFromSelf) {
      sender = friends.firstWhere(
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

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (isFromSelf) ...[
                  Icon(
                    Icons.person,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Message from Myself',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  ProfilePictureWidget(userProfile: sender!, size: 32),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Message from ${sender.username}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Message content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.textContent,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),

                    // Media attachments
                    if (message.hasMedia()) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Attachments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMediaSection(context, theme),
                    ],

                    const SizedBox(height: 16),

                    // Message details
                    Text(
                      'Message Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMessageDetails(theme),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Display image thumbnails
        if (message.imageUrls != null && message.imageUrls!.isNotEmpty)
          ...message.imageUrls!.map(
            (imageUrl) => _buildImageThumbnail(context, imageUrl, theme),
          ),

        // Display video preview
        if (message.videoUrl != null)
          _buildVideoThumbnail(message.videoUrl!, theme),
      ],
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    String imageUrl,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imageUrl),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 48,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl, ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.videocam,
        color: theme.colorScheme.onSurfaceVariant,
        size: 48,
      ),
    );
  }

  Widget _buildMessageDetails(ThemeData theme) {
    return Column(
      children: [
        _buildDetailRow(
          theme,
          Icons.schedule,
          'Scheduled for: ${_formatDateTime(message.scheduledFor)}',
        ),
        if (message.deliveredAt != null)
          _buildDetailRow(
            theme,
            Icons.check_circle,
            'Delivered at: ${_formatDateTime(message.deliveredAt!)}',
          ),
        _buildDetailRow(
          theme,
          Icons.edit,
          'Created on: ${_formatDateTime(message.createdAt)}',
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
