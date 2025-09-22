import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'friend_list_tile.dart';

class ContributorSelector extends StatefulWidget {
  final List<UserProfile> availableFriends;
  final List<String> selectedContributorIds;
  final ValueChanged<List<String>> onSelectionChanged;
  final String? title;
  final String? subtitle;
  final bool allowEmpty;
  final int? maxSelections;

  const ContributorSelector({
    super.key,
    required this.availableFriends,
    required this.selectedContributorIds,
    required this.onSelectionChanged,
    this.title,
    this.subtitle,
    this.allowEmpty = true,
    this.maxSelections,
  });

  @override
  State<ContributorSelector> createState() => _ContributorSelectorState();
}

class _ContributorSelectorState extends State<ContributorSelector> {
  late List<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedContributorIds);
  }

  @override
  void didUpdateWidget(ContributorSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedContributorIds != widget.selectedContributorIds) {
      _selectedIds = List.from(widget.selectedContributorIds);
    }
  }

  List<UserProfile> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return widget.availableFriends;
    }
    
    return widget.availableFriends.where((friend) {
      return friend.username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        // Check max selections limit
        if (widget.maxSelections != null && 
            _selectedIds.length >= widget.maxSelections!) {
          _showMaxSelectionsReached();
          return;
        }
        _selectedIds.add(userId);
      }
    });
    widget.onSelectionChanged(_selectedIds);
  }

  void _showMaxSelectionsReached() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum ${widget.maxSelections} contributors allowed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
    widget.onSelectionChanged(_selectedIds);
  }

  void _selectAll() {
    final maxToSelect = widget.maxSelections ?? widget.availableFriends.length;
    final friendsToSelect = _filteredFriends.take(maxToSelect).toList();
    
    setState(() {
      _selectedIds = friendsToSelect.map((friend) => friend.id).toList();
    });
    widget.onSelectionChanged(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _selectedIds.length;
    final totalCount = widget.availableFriends.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.title!,
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
        if (widget.subtitle != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Selection summary and actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedCount of $totalCount selected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (selectedCount > 0) ...[
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
              ],
              if (selectedCount < totalCount && 
                  (widget.maxSelections == null || 
                   selectedCount < widget.maxSelections!)) ...[
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Select All'),
                ),
              ],
            ],
          ),
        ),

        // Search bar
        if (widget.availableFriends.length > 5) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],

        // Friends list
        Expanded(
          child: _filteredFriends.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = _filteredFriends[index];
                    final isSelected = _selectedIds.contains(friend.id);
                    final isEnabled = isSelected || 
                        widget.maxSelections == null || 
                        _selectedIds.length < widget.maxSelections!;

                    return SelectableFriendListTile(
                      friend: friend,
                      isSelected: isSelected,
                      enabled: isEnabled,
                      onChanged: (selected) {
                        if (selected == true || isSelected) {
                          _toggleSelection(friend.id);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No friends found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No friends available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some friends first to invite them as contributors',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A dialog version of the ContributorSelector for modal use
class ContributorSelectorDialog extends StatefulWidget {
  final List<UserProfile> availableFriends;
  final List<String> initialSelectedIds;
  final String? title;
  final String? subtitle;
  final int? maxSelections;

  const ContributorSelectorDialog({
    super.key,
    required this.availableFriends,
    this.initialSelectedIds = const [],
    this.title,
    this.subtitle,
    this.maxSelections,
  });

  @override
  State<ContributorSelectorDialog> createState() => _ContributorSelectorDialogState();
}

class _ContributorSelectorDialogState extends State<ContributorSelectorDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Expanded(
              child: ContributorSelector(
                availableFriends: widget.availableFriends,
                selectedContributorIds: _selectedIds,
                onSelectionChanged: (selectedIds) {
                  setState(() {
                    _selectedIds = selectedIds;
                  });
                },
                title: widget.title ?? 'Select Contributors',
                subtitle: widget.subtitle,
                maxSelections: widget.maxSelections,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selectedIds),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the contributor selector dialog
Future<List<String>?> showContributorSelectorDialog({
  required BuildContext context,
  required List<UserProfile> availableFriends,
  List<String> initialSelectedIds = const [],
  String? title,
  String? subtitle,
  int? maxSelections,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => ContributorSelectorDialog(
      availableFriends: availableFriends,
      initialSelectedIds: initialSelectedIds,
      title: title,
      subtitle: subtitle,
      maxSelections: maxSelections,
    ),
  );
}