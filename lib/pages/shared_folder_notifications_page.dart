import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_folder_notification_model.dart';
import '../services/folder_service.dart';
import '../widgets/shared_folder_notification_widget.dart';

class SharedFolderNotificationsPage extends StatefulWidget {
  const SharedFolderNotificationsPage({Key? key}) : super(key: key);

  @override
  State<SharedFolderNotificationsPage> createState() => _SharedFolderNotificationsPageState();
}

class _SharedFolderNotificationsPageState extends State<SharedFolderNotificationsPage> {
  final FolderService _folderService = FolderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shared Folder Notifications'),
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Folder Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(user.uid),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<SharedFolderNotification>>(
        stream: _folderService.streamSharedFolderNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No shared folder notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when someone invites you to collaborate on a folder',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return SharedFolderNotificationWidget(
                notification: notification,
                onTap: () => _navigateToFolder(notification),
                onMarkAsRead: () => _markAsRead(notification.id),
                onDelete: () => _deleteNotification(notification.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _navigateToFolder(SharedFolderNotification notification) async {
    try {
      // Mark as read when user taps on notification
      if (!notification.isRead) {
        await _folderService.markNotificationAsRead(notification.id);
      }

      // Navigate to the shared folder
      // Note: This would need to be implemented based on your app's navigation structure
      // For now, we'll show a snackbar with folder information
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening folder: ${notification.folderName}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _folderService.markNotificationAsRead(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notification as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _folderService.deleteNotification(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      final notifications = await _folderService.getSharedFolderNotifications(userId);
      final unreadNotifications = notifications.where((n) => !n.isRead).toList();

      for (final notification in unreadNotifications) {
        await _folderService.markNotificationAsRead(notification.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${unreadNotifications.length} notifications marked as read'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}