import 'package:flutter/material.dart';

class OptionsMenuWidget extends StatelessWidget {
  final VoidCallback? onEditName;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit; // For diary entries
  final String? mediaType; // To determine available options

  const OptionsMenuWidget({
    super.key,
    this.onEditName,
    this.onDelete,
    this.onEdit,
    this.mediaType,
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
        // Edit diary content (for diary entries)
        if (mediaType == 'diary' && onEdit != null)
          PopupMenuItem<String>(
            value: 'edit_diary',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.edit, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        // Edit name (for other media types)
        if (mediaType != 'diary' && onEditName != null)
          PopupMenuItem<String>(
            value: 'edit_name',
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
          case 'edit_diary':
            onEdit?.call();
            break;
          case 'edit_name':
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