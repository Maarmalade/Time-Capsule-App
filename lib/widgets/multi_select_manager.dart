import 'package:flutter/foundation.dart';

/// Manages multi-select state for batch operations on folders and media files
class MultiSelectManager extends ChangeNotifier {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedFolderIds = <String>{};
  final Set<String> _selectedMediaIds = <String>{};

  /// Whether multi-select mode is currently active
  bool get isMultiSelectMode => _isMultiSelectMode;

  /// Set of selected folder IDs
  Set<String> get selectedFolderIds => Set.unmodifiable(_selectedFolderIds);

  /// Set of selected media IDs
  Set<String> get selectedMediaIds => Set.unmodifiable(_selectedMediaIds);

  /// Total count of selected items (folders + media)
  int get selectedCount => _selectedFolderIds.length + _selectedMediaIds.length;

  /// Whether any items are selected
  bool get hasSelection => selectedCount > 0;

  /// Check if a folder is selected
  bool isFolderSelected(String folderId) => _selectedFolderIds.contains(folderId);

  /// Check if a media item is selected
  bool isMediaSelected(String mediaId) => _selectedMediaIds.contains(mediaId);

  /// Enter multi-select mode
  void enterMultiSelectMode() {
    if (!_isMultiSelectMode) {
      _isMultiSelectMode = true;
      notifyListeners();
    }
  }

  /// Exit multi-select mode and clear all selections
  void exitMultiSelectMode() {
    if (_isMultiSelectMode) {
      _isMultiSelectMode = false;
      _selectedFolderIds.clear();
      _selectedMediaIds.clear();
      notifyListeners();
    }
  }

  /// Toggle selection of a folder
  void toggleFolderSelection(String folderId) {
    if (_selectedFolderIds.contains(folderId)) {
      _selectedFolderIds.remove(folderId);
    } else {
      _selectedFolderIds.add(folderId);
    }
    
    // Exit multi-select mode if no items are selected
    if (selectedCount == 0) {
      exitMultiSelectMode();
    } else {
      notifyListeners();
    }
  }

  /// Toggle selection of a media item
  void toggleMediaSelection(String mediaId) {
    if (_selectedMediaIds.contains(mediaId)) {
      _selectedMediaIds.remove(mediaId);
    } else {
      _selectedMediaIds.add(mediaId);
    }
    
    // Exit multi-select mode if no items are selected
    if (selectedCount == 0) {
      exitMultiSelectMode();
    } else {
      notifyListeners();
    }
  }

  /// Select all provided folders and media
  void selectAll(List<String> folderIds, List<String> mediaIds) {
    _selectedFolderIds.addAll(folderIds);
    _selectedMediaIds.addAll(mediaIds);
    if (!_isMultiSelectMode && hasSelection) {
      _isMultiSelectMode = true;
    }
    notifyListeners();
  }

  /// Clear all selections without exiting multi-select mode
  void clearSelection() {
    _selectedFolderIds.clear();
    _selectedMediaIds.clear();
    notifyListeners();
  }

  /// Start multi-select mode with an initial folder selection
  void startWithFolder(String folderId) {
    enterMultiSelectMode();
    _selectedFolderIds.add(folderId);
    notifyListeners();
  }

  /// Start multi-select mode with an initial media selection
  void startWithMedia(String mediaId) {
    enterMultiSelectMode();
    _selectedMediaIds.add(mediaId);
    notifyListeners();
  }
}