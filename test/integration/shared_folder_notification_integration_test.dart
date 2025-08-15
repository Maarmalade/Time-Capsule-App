import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/shared_folder_notification_model.dart';

void main() {
  group('Shared Folder Notification Integration Tests', () {
    test('should create and serialize SharedFolderNotification correctly', () {
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

      // Test serialization
      final firestoreMap = notification.toFirestore();
      expect(firestoreMap['folderId'], equals('folder-123'));
      expect(firestoreMap['folderName'], equals('Test Folder'));
      expect(firestoreMap['ownerId'], equals('owner-123'));
      expect(firestoreMap['ownerUsername'], equals('testowner'));
      expect(firestoreMap['contributorId'], equals('contributor-123'));
      expect(firestoreMap['isRead'], equals(false));

      // Test copyWith functionality
      final updatedNotification = notification.copyWith(isRead: true);
      expect(updatedNotification.isRead, equals(true));
      expect(updatedNotification.folderId, equals('folder-123'));
    });

    test('should handle notification workflow correctly', () {
      // Create initial notification
      final notification = SharedFolderNotification(
        id: 'test-id',
        folderId: 'folder-123',
        folderName: 'Test Folder',
        ownerId: 'owner-123',
        ownerUsername: 'testowner',
        contributorId: 'contributor-123',
        createdAt: DateTime.now(),
        isRead: false,
      );

      // Verify initial state
      expect(notification.isRead, isFalse);

      // Simulate marking as read
      final readNotification = notification.copyWith(isRead: true);
      expect(readNotification.isRead, isTrue);

      // Verify other fields remain unchanged
      expect(readNotification.folderId, equals(notification.folderId));
      expect(readNotification.folderName, equals(notification.folderName));
      expect(readNotification.ownerId, equals(notification.ownerId));
      expect(readNotification.ownerUsername, equals(notification.ownerUsername));
      expect(readNotification.contributorId, equals(notification.contributorId));
    });

    test('should validate notification data integrity', () {
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

      // Verify all required fields are present
      expect(notification.id.isNotEmpty, isTrue);
      expect(notification.folderId.isNotEmpty, isTrue);
      expect(notification.folderName.isNotEmpty, isTrue);
      expect(notification.ownerId.isNotEmpty, isTrue);
      expect(notification.ownerUsername.isNotEmpty, isTrue);
      expect(notification.contributorId.isNotEmpty, isTrue);
      expect(notification.createdAt, isA<DateTime>());
      expect(notification.isRead, isA<bool>());
    });
  });
}