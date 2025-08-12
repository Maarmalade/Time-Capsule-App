import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/multi_select_manager.dart';

void main() {
  group('MultiSelectManager', () {
    late MultiSelectManager manager;

    setUp(() {
      manager = MultiSelectManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('should start in normal mode', () {
      expect(manager.isMultiSelectMode, false);
      expect(manager.selectedCount, 0);
      expect(manager.hasSelection, false);
    });

    test('should enter multi-select mode when starting with folder', () {
      manager.startWithFolder('folder1');
      
      expect(manager.isMultiSelectMode, true);
      expect(manager.selectedCount, 1);
      expect(manager.hasSelection, true);
      expect(manager.isFolderSelected('folder1'), true);
    });

    test('should enter multi-select mode when starting with media', () {
      manager.startWithMedia('media1');
      
      expect(manager.isMultiSelectMode, true);
      expect(manager.selectedCount, 1);
      expect(manager.hasSelection, true);
      expect(manager.isMediaSelected('media1'), true);
    });

    test('should toggle folder selection', () {
      manager.enterMultiSelectMode();
      
      // Select folder
      manager.toggleFolderSelection('folder1');
      expect(manager.isFolderSelected('folder1'), true);
      expect(manager.selectedCount, 1);
      
      // Deselect folder
      manager.toggleFolderSelection('folder1');
      expect(manager.isFolderSelected('folder1'), false);
      expect(manager.selectedCount, 0);
    });

    test('should toggle media selection', () {
      manager.enterMultiSelectMode();
      
      // Select media
      manager.toggleMediaSelection('media1');
      expect(manager.isMediaSelected('media1'), true);
      expect(manager.selectedCount, 1);
      
      // Deselect media
      manager.toggleMediaSelection('media1');
      expect(manager.isMediaSelected('media1'), false);
      expect(manager.selectedCount, 0);
    });

    test('should exit multi-select mode when no items selected', () {
      manager.startWithFolder('folder1');
      expect(manager.isMultiSelectMode, true);
      
      // Deselect the only item
      manager.toggleFolderSelection('folder1');
      expect(manager.isMultiSelectMode, false);
      expect(manager.selectedCount, 0);
    });

    test('should clear all selections', () {
      manager.startWithFolder('folder1');
      manager.toggleMediaSelection('media1');
      expect(manager.selectedCount, 2);
      
      manager.clearSelection();
      expect(manager.selectedCount, 0);
      expect(manager.isMultiSelectMode, true); // Should stay in multi-select mode
    });

    test('should exit multi-select mode and clear selections', () {
      manager.startWithFolder('folder1');
      manager.toggleMediaSelection('media1');
      expect(manager.selectedCount, 2);
      
      manager.exitMultiSelectMode();
      expect(manager.isMultiSelectMode, false);
      expect(manager.selectedCount, 0);
    });

    test('should select multiple items', () {
      manager.enterMultiSelectMode();
      manager.toggleFolderSelection('folder1');
      manager.toggleFolderSelection('folder2');
      manager.toggleMediaSelection('media1');
      manager.toggleMediaSelection('media2');
      
      expect(manager.selectedCount, 4);
      expect(manager.selectedFolderIds.length, 2);
      expect(manager.selectedMediaIds.length, 2);
    });

    test('should select all provided items', () {
      final folderIds = ['folder1', 'folder2'];
      final mediaIds = ['media1', 'media2', 'media3'];
      
      manager.selectAll(folderIds, mediaIds);
      
      expect(manager.isMultiSelectMode, true);
      expect(manager.selectedCount, 5);
      expect(manager.selectedFolderIds.containsAll(folderIds), true);
      expect(manager.selectedMediaIds.containsAll(mediaIds), true);
    });
  });
}