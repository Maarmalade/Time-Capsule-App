import 'package:flutter/material.dart';

/// Bottom action bar for multi-select batch operations
class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const BatchActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Cancel button
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              const Spacer(),
              
              // Selection counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Delete button
              ElevatedButton.icon(
                onPressed: selectedCount > 0 ? onDelete : null,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}