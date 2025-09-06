import 'package:flutter/material.dart';

class NotificationBadgeWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Shared folder notifications have been removed
    // This widget now just wraps the child without showing any badges
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}