import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/media_service.dart';
import 'package:time_capsule/services/storage_service.dart';
import 'package:time_capsule/services/user_profile_service.dart';
import 'package:time_capsule/models/folder_model.dart';

// Mock services for testing
class MockStorageService extends Mock implements StorageService {}
class MockUserProfileService extends Mock implements UserProfileService {}

void main() {
  group('Shared Folder Access Integration Tests', () {
    late FolderService folderService;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MediaService mockMediaService;
    late MockUserProfileService mockUserProfileService;

    const String userId1 = 'user1';
    const String userId2 = 'user2';
    const String userId3 = 'user3';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true);
      mockUserProfileService = MockUserProfileService();
      mockMediaService = MediaService(
        firestore: fakeFirestore,
        storageService: MockStorageService(),
      );
      
      folderService = FolderService(
        firestore: fakeFirestore,
        auth: mockAuth,
        mediaService: mockMediaService,
        userProfileService: mockUserProfileService,
      );
    });

    test('streamUserAccessibleFolders includes owned folders', () async {
      // Create a folder owned by user1
      final folder = FolderModel(
        id: 'folder1',
        name: 'My Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: false,
        contributorIds: [],
      );

      await fakeFirestore.collection('folders').doc('folder1').set(folder.toMap());

      // Stream folders for user1
      final stream = folderService.streamUserAccessibleFolders(userId1);
      final folders = await stream.first;

      expect(folders.length, 1);
      expect(folders.first.id, 'folder1');
      expect(folders.first.name, 'My Folder');
      expect(folders.first.userId, userId1);
    });

    test('streamUserAccessibleFolders includes shared folders where user is contributor', () async {
      // Create a shared folder owned by user1 with user2 as contributor
      final sharedFolder = FolderModel(
        id: 'shared1',
        name: 'Shared Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: true,
        contributorIds: [userId2, userId3],
      );

      await fakeFirestore.collection('folders').doc('shared1').set(sharedFolder.toMap());

      // Stream folders for user2 (contributor)
      final stream = folderService.streamUserAccessibleFolders(userId2);
      final folders = await stream.first;

      expect(folders.length, 1);
      expect(folders.first.id, 'shared1');
      expect(folders.first.name, 'Shared Folder');
      expect(folders.first.userId, userId1);
      expect(folders.first.contributorIds, contains(userId2));
    });

    test('streamUserAccessibleFolders excludes folders where user has no access', () async {
      // Create a folder owned by user1
      final folder = FolderModel(
        id: 'private1',
        name: 'Private Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: false,
        contributorIds: [],
      );

      await fakeFirestore.collection('folders').doc('private1').set(folder.toMap());

      // Stream folders for user2 (no access)
      final stream = folderService.streamUserAccessibleFolders(userId2);
      final folders = await stream.first;

      expect(folders.length, 0);
    });

    test('canUserView returns true for folder owner', () async {
      final folder = FolderModel(
        id: 'folder1',
        name: 'Test Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
      );

      await fakeFirestore.collection('folders').doc('folder1').set(folder.toMap());

      final canView = await folderService.canUserView('folder1', userId1);
      expect(canView, true);
    });

    test('canUserView returns true for contributor of shared folder', () async {
      final sharedFolder = FolderModel(
        id: 'shared1',
        name: 'Shared Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: true,
        contributorIds: [userId2],
      );

      await fakeFirestore.collection('folders').doc('shared1').set(sharedFolder.toMap());

      final canView = await folderService.canUserView('shared1', userId2);
      expect(canView, true);
    });

    test('canUserView returns false for non-contributor', () async {
      final folder = FolderModel(
        id: 'private1',
        name: 'Private Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: false,
      );

      await fakeFirestore.collection('folders').doc('private1').set(folder.toMap());

      final canView = await folderService.canUserView('private1', userId2);
      expect(canView, false);
    });

    test('canUserContribute returns true for folder owner', () async {
      final folder = FolderModel(
        id: 'folder1',
        name: 'Test Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
      );

      await fakeFirestore.collection('folders').doc('folder1').set(folder.toMap());

      final canContribute = await folderService.canUserContribute('folder1', userId1);
      expect(canContribute, true);
    });

    test('canUserContribute returns true for contributor of unlocked shared folder', () async {
      final sharedFolder = FolderModel(
        id: 'shared1',
        name: 'Shared Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: true,
        isLocked: false,
        contributorIds: [userId2],
      );

      await fakeFirestore.collection('folders').doc('shared1').set(sharedFolder.toMap());

      final canContribute = await folderService.canUserContribute('shared1', userId2);
      expect(canContribute, true);
    });

    test('canUserContribute returns false for contributor of locked shared folder', () async {
      final lockedFolder = FolderModel(
        id: 'locked1',
        name: 'Locked Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: true,
        isLocked: true,
        contributorIds: [userId2],
      );

      await fakeFirestore.collection('folders').doc('locked1').set(lockedFolder.toMap());

      final canContribute = await folderService.canUserContribute('locked1', userId2);
      expect(canContribute, false);
    });

    test('streamUserAccessibleFolders filters by parentFolderId', () async {
      // Create parent folder
      final parentFolder = FolderModel(
        id: 'parent1',
        name: 'Parent Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
      );

      // Create child folder
      final childFolder = FolderModel(
        id: 'child1',
        name: 'Child Folder',
        userId: userId1,
        parentFolderId: 'parent1',
        createdAt: Timestamp.now(),
      );

      // Create top-level folder
      final topFolder = FolderModel(
        id: 'top1',
        name: 'Top Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
      );

      await fakeFirestore.collection('folders').doc('parent1').set(parentFolder.toMap());
      await fakeFirestore.collection('folders').doc('child1').set(childFolder.toMap());
      await fakeFirestore.collection('folders').doc('top1').set(topFolder.toMap());

      // Stream top-level folders
      final topLevelStream = folderService.streamUserAccessibleFolders(userId1);
      final topLevelFolders = await topLevelStream.first;

      expect(topLevelFolders.length, 2); // parent1 and top1
      expect(topLevelFolders.any((f) => f.id == 'parent1'), true);
      expect(topLevelFolders.any((f) => f.id == 'top1'), true);
      expect(topLevelFolders.any((f) => f.id == 'child1'), false);

      // Stream child folders
      final childStream = folderService.streamUserAccessibleFolders(userId1, parentFolderId: 'parent1');
      final childFolders = await childStream.first;

      expect(childFolders.length, 1);
      expect(childFolders.first.id, 'child1');
    });

    test('real-time updates when contributor is added', () async {
      // Create a private folder owned by user1
      final folder = FolderModel(
        id: 'folder1',
        name: 'Test Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: false,
        contributorIds: [],
      );

      await fakeFirestore.collection('folders').doc('folder1').set(folder.toMap());

      // Start streaming for user2
      final stream = folderService.streamUserAccessibleFolders(userId2);
      final streamResults = <List<FolderModel>>[];
      
      final subscription = stream.listen((folders) {
        streamResults.add(folders);
      });

      // Wait for initial empty result
      await Future.delayed(Duration(milliseconds: 100));
      expect(streamResults.length, 1);
      expect(streamResults.first.length, 0);

      // Convert folder to shared and add user2 as contributor
      await fakeFirestore.collection('folders').doc('folder1').update({
        'isShared': true,
        'contributorIds': [userId2],
      });

      // Wait for real-time update
      await Future.delayed(Duration(milliseconds: 100));
      expect(streamResults.length, 2);
      expect(streamResults.last.length, 1);
      expect(streamResults.last.first.id, 'folder1');
      expect(streamResults.last.first.contributorIds, contains(userId2));

      await subscription.cancel();
    });

    test('real-time updates when contributor is removed', () async {
      // Create a shared folder with user2 as contributor
      final sharedFolder = FolderModel(
        id: 'shared1',
        name: 'Shared Folder',
        userId: userId1,
        createdAt: Timestamp.now(),
        isShared: true,
        contributorIds: [userId2],
      );

      await fakeFirestore.collection('folders').doc('shared1').set(sharedFolder.toMap());

      // Start streaming for user2
      final stream = folderService.streamUserAccessibleFolders(userId2);
      final streamResults = <List<FolderModel>>[];
      
      final subscription = stream.listen((folders) {
        streamResults.add(folders);
      });

      // Wait for initial result with access
      await Future.delayed(Duration(milliseconds: 100));
      expect(streamResults.length, 1);
      expect(streamResults.first.length, 1);

      // Remove user2 as contributor
      await fakeFirestore.collection('folders').doc('shared1').update({
        'contributorIds': [],
      });

      // Wait for real-time update
      await Future.delayed(Duration(milliseconds: 100));
      expect(streamResults.length, 2);
      expect(streamResults.last.length, 0);

      await subscription.cancel();
    });
  });
}