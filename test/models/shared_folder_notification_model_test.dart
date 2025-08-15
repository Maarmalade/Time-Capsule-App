import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:time_capsule/models/shared_folder_notification_model.dart';

void main() {
  group('SharedFolderNotification Model Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('should create SharedFolderNotification with all required fields', () {
      final notification = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
      );

      expect(notification.id, equals('test-id'));
      expect(notification.folderId, equals('folder-123'));
      expect(notification.folderName, equals('Test Folder'));
      expect(notification.ownerId, equals('owner-123'));
      expect(notification.ownerUsername, equals('testowner'));
      expect(notification.contributorId, equals('contributor-123'));
      expect(notification.createdAt, equals(DateTime(2024, 1, 1)));
      expect(notification.isRead, equals(false));
    });

    test('should create SharedFolderNotification with default isRead value', () {
      final notification = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(notification.isRead, equals(false));
    });

    test('should convert to Firestore map correctly', () {
      final notification = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
        isRead: true,
      );

      final firestoreMap = notification.toFirestore();

      expect(firestoreMap['folderId'], equals('folder-123'));
      expect(firestoreMap['folderName'], equals('Test Folder'));
      expect(firestoreMap['ownerId'], equals('owner-123'));
      expect(firestoreMap['ownerUsername'], equals('testowner'));
      expect(firestoreMap['contributorId'], equals('contributor-123'));
      expect(firestoreMap['createdAt'], isA<Timestamp>());
      expect(firestoreMap['isRead'], equals(true));
    });

    test('should create from Firestore document correctly', () async {
      // Create a mock document
      final docRef = fakeFirestore.collection('notifications').doc('test-id');
      await docRef.set({
        'folderId': 'folder-123',
        'folderName': 'Test Folder',
        'ownerId': 'owner-123',
        'ownerUsername': 'testowner',
        'contributorId': 'contributor-123',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'isRead': true,
      });

      final doc = await docRef.get();
      final notification = SharedFolderNotification.fromFirestore(doc);

      expect(notification.id, equals('test-id'));
      expect(notification.folderId, equals('folder-123'));
      expect(notification.folderName, equals('Test Folder'));
      expect(notification.ownerId, equals('owner-123'));
      expect(notification.ownerUsername, equals('testowner'));
      expect(notification.contributorId, equals('contributor-123'));
      expect(notification.createdAt, equals(DateTime(2024, 1, 1)));
      expect(notification.isRead, equals(true));
    });

    test('should handle missing fields when creating from Firestore', () async {
      // Create a document with minimal data
      final docRef = fakeFirestore.collection('notifications').doc('test-id');
      await docRef.set({
        'folderId': 'folder-123',
      });

      final doc = await docRef.get();
      final notification = SharedFolderNotification.fromFirestore(doc);

      expect(notification.id, equals('test-id'));
      expect(notification.folderId, equals('folder-123'));
      expect(notification.folderName, equals(''));
      expect(notification.ownerId, equals(''));
      expect(notification.ownerUsername, equals(''));
      expect(notification.contributorId, equals(''));
      expect(notification.createdAt, isA<DateTime>());
      expect(notification.isRead, equals(false));
    });

    test('should create copy with updated fields', () {
      final original = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
      );

      final updated = original.copyWith(
        folderName: 'Updated Folder',
        isRead: true,
      );

      expect(updated.id, equals('test-id'));
      expect(updated.folderId, equals('folder-123'));
      expect(updated.folderName, equals('Updated Folder'));
      expect(updated.ownerId, equals('owner-123'));
      expect(updated.ownerUsername, equals('testowner'));
      expect(updated.contributorId, equals('contributor-123'));
      expect(updated.createdAt, equals(DateTime(2024, 1, 1)));
      expect(updated.isRead, equals(true));
    });

    test('should implement equality correctly', () {
      final notification1 = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
      );

      final notification2 = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
      );

      final notification3 = SharedFolderNotification(
        id: 'different-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
      );

      expect(notification1, equals(notification2));
      expect(notification1, isNot(equals(notification3)));
      expect(notification1.hashCode, equals(notification2.hashCode));
      expect(notification1.hashCode, isNot(equals(notification3.hashCode)));
    });

    test('should have proper toString implementation', () {
      final notification = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
      );

      final stringRepresentation = notification.toString();

      expect(stringRepresentation, contains('SharedFolderNotification'));
      expect(stringRepresentation, contains('test-id'));
      expect(stringRepresentation, contains('folder-123'));
      expect(stringRepresentation, contains('Test Folder'));
      expect(stringRepresentation, contains('owner-123'));
      expect(stringRepresentation, contains('testowner'));
      expect(stringRepresentation, contains('contributor-123'));
    });
  });
}