import 'package:flutter/material.dart';

class OptionsMenuWidget extends StatelessWidget {
  final VoidCallback? onEditName;
  final VoidCallback? onDelete;

  const OptionsMenuWidget({
    super.key,
    this.onEditName,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 20,
        color: Colors.grey,
      ),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      ),
      offset: const Offset(0, 25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (context) => [
        if (onEditName != null)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.edit, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('Edit Name'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEditName?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
    );
  }
}