import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/folder_service.dart';

class NotificationBadgeWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  State<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget> {
  final FolderService _folderService = FolderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return StreamBuilder<List<dynamic>>(
      stream: _folderService.streamSharedFolderNotifications(user.uid),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            children: [
              widget.child,
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}