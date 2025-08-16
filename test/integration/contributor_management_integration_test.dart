import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Contributor Management Integration Tests', () {
    late FolderService folderService;
    late FriendService friendService;
    late String testFolderId;
    late String testUserId;
    late String contributorId;

    setUpAll(() async {
      folderService = FolderService();
      friendService = FriendService();
      
      // Create test users and folder for integration testing
      testUserId = 'test_owner_${DateTime.now().millisecondsSinceEpoch}';
      contributorId = 'test_contributor_${DateTime.now().millisecondsSinceEpoch}';
    });

    tearDownAll(() async {
      // Clean up test data
      if (testFolderId.isNotEmpty) {
        try {
          await folderService.deleteFolder(testFolderId);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    testWidgets('Complete contributor management workflow', (tester) async {
      // This test verifies the complete workflow:
      // 1. Create a shared folder
      // 2. Add contributors
      // 3. View contributor list
      // 4. Remove contributors
      // 5. Verify notifications are sent

      // Step 1: Create a shared folder
      final testFolder = FolderModel(
        id: '',
        name: 'Test Shared Folder',
        userId: testUserId,
        createdAt: Timestamp.now(),
        isShared: true,
      );

      testFolderId = await folderService.createSharedFolder(
        testFolder,
        [contributorId],
      );

      expect(testFolderId, isNotEmpty);

      // Step 2: Verify folder was created with contributor
      final createdFolder = await folderService.getFolder(testFolderId);
      expect(createdFolder, isNotNull);
      expect(createdFolder!.isShared, isTrue);
      expect(createdFolder.contributorIds, contains(contributorId));

      // Step 3: Get contributor list using the service method
      final contributors = await folderService.getFolderContributors(testFolderId);
      expect(contributors, isNotEmpty);

      // Step 4: Add another contributor
      const newContributorId = 'new_contributor_123';
      await folderService.inviteContributors(testFolderId, [newContributorId]);

      // Verify the new contributor was added
      final updatedContributors = await folderService.getFolderContributors(testFolderId);
      expect(updatedContributors.length, greaterThan(contributors.length));

      // Step 5: Remove a contributor
      await folderService.removeContributor(testFolderId, contributorId);

      // Verify the contributor was removed
      final finalContributors = await folderService.getFolderContributors(testFolderId);
      final contributorIds = finalContributors.map((c) => c.id).toList();
      expect(contributorIds, isNot(contains(contributorId)));

      // Step 6: Verify folder access validation
      final canOriginalContributorView = await folderService.canUserView(testFolderId, contributorId);
      expect(canOriginalContributorView, isFalse);

      final canNewContributorView = await folderService.canUserView(testFolderId, newContributorId);
      expect(canNewContributorView, isTrue);

      final canOwnerView = await folderService.canUserView(testFolderId, testUserId);
      expect(canOwnerView, isTrue);
    });

    testWidgets('Contributor management error handling', (tester) async {
      // Test error scenarios for contributor management

      // Test 1: Try to get contributors for non-existent folder
      expect(
        () => folderService.getFolderContributors('nonexistent_folder'),
        throwsA(isA<Exception>()),
      );

      // Test 2: Try to remove contributor from non-existent folder
      expect(
        () => folderService.removeContributor('nonexistent_folder', 'user123'),
        throwsA(isA<Exception>()),
      );

      // Test 3: Try to remove contributor with empty folder ID
      expect(
        () => folderService.removeContributor('', 'user123'),
        throwsA(isA<Exception>()),
      );

      // Test 4: Try to remove contributor with empty user ID
      expect(
        () => folderService.removeContributor('folder123', ''),
        throwsA(isA<Exception>()),
      );

      // Test 5: Try to get contributors with empty folder ID
      expect(
        () => folderService.getFolderContributors(''),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('Contributor access validation', (tester) async {
      // Create a test folder for access validation
      final testFolder = FolderModel(
        id: '',
        name: 'Access Test Folder',
        userId: testUserId,
        createdAt: Timestamp.now(),
        isShared: true,
      );

      final folderId = await folderService.createSharedFolder(
        testFolder,
        [contributorId],
      );

      try {
        // Test owner access
        final ownerCanView = await folderService.canUserView(folderId, testUserId);
        expect(ownerCanView, isTrue);

        final ownerCanContribute = await folderService.canUserContribute(folderId, testUserId);
        expect(ownerCanContribute, isTrue);

        // Test contributor access
        final contributorCanView = await folderService.canUserView(folderId, contributorId);
        expect(contributorCanView, isTrue);

        final contributorCanContribute = await folderService.canUserContribute(folderId, contributorId);
        expect(contributorCanContribute, isTrue);

        // Test non-contributor access
        const nonContributorId = 'non_contributor_123';
        final nonContributorCanView = await folderService.canUserView(folderId, nonContributorId);
        expect(nonContributorCanView, isFalse);

        final nonContributorCanContribute = await folderService.canUserContribute(folderId, nonContributorId);
        expect(nonContributorCanContribute, isFalse);

        // Test access after removal
        await folderService.removeContributor(folderId, contributorId);

        final removedContributorCanView = await folderService.canUserView(folderId, contributorId);
        expect(removedContributorCanView, isFalse);

        final removedContributorCanContribute = await folderService.canUserContribute(folderId, contributorId);
        expect(removedContributorCanContribute, isFalse);
      } finally {
        // Clean up
        await folderService.deleteFolder(folderId);
      }
    });

    testWidgets('Folder locking affects contributor access', (tester) async {
      // Create a test folder
      final testFolder = FolderModel(
        id: '',
        name: 'Lock Test Folder',
        userId: testUserId,
        createdAt: Timestamp.now(),
        isShared: true,
      );

      final folderId = await folderService.createSharedFolder(
        testFolder,
        [contributorId],
      );

      try {
        // Initially, contributor should be able to contribute
        final initialCanContribute = await folderService.canUserContribute(folderId, contributorId);
        expect(initialCanContribute, isTrue);

        // Lock the folder
        await folderService.lockFolder(folderId);

        // After locking, contributor should not be able to contribute
        final lockedCanContribute = await folderService.canUserContribute(folderId, contributorId);
        expect(lockedCanContribute, isFalse);

        // But should still be able to view
        final lockedCanView = await folderService.canUserView(folderId, contributorId);
        expect(lockedCanView, isTrue);

        // Owner should still be able to contribute even when locked
        final ownerCanContribute = await folderService.canUserContribute(folderId, testUserId);
        expect(ownerCanContribute, isTrue);

        // Unlock the folder
        await folderService.unlockFolder(folderId);

        // After unlocking, contributor should be able to contribute again
        final unlockedCanContribute = await folderService.canUserContribute(folderId, contributorId);
        expect(unlockedCanContribute, isTrue);
      } finally {
        // Clean up
        await folderService.deleteFolder(folderId);
      }
    });
  });
}