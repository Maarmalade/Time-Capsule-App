import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/media_service.dart';
import 'package:time_capsule/services/user_profile_service.dart';

void main() {
  group('FolderService Notification Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FolderService folderService;
    late MockMediaService mockMediaService;
    late MockUserProfileService mockUserProfileService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockMediaService = MockMediaService();
      mockUserProfileService = MockUserProfileService();
      folderService = FolderService(
        firestore: fakeFirestore,
        auth: mockAuth,
        mediaService: mockMediaService,
        userProfileService: mockUserProfileService,
      );
    });

    group('notifyContributorAdded', () {
      test('should create notification when contributor is added', () async {
        // Setup test data
        const folderId = 'folder-123';
        const contributorId = 'contributor-123';
        const ownerId = 'owner-123';
        const folderName = 'Test Folder';
        const ownerUsername = 'testowner';

        // Create folder document
        await fakeFirestore.collection('folders').doc(folderId).set({
          'name': folderName,
          'userId': ownerId,
          'isShared': true,
          'contributorIds': [contributorId],
          'createdAt': Timestamp.now(),
        });

        // Mock user profile service
        mockUserProfileService.setUserProfile(ownerId, {
          'id': ownerId,
          'email': 'owner@test.com',
          'username': ownerUsername,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });

        // Call the method
        await folderService.notifyContributorAdded(folderId, contributorId);

        // Verify notification was created
        final notifications = await fakeFirestore
            .collection('shared_folder_notifications')
            .get();

        expect(notifications.docs.length, equals(1));

        final notificationData = notifications.docs.first.data();
        expect(notificationData['folderId'], equals(folderId));
        expect(notificationData['folderName'], equals(folderName));
        expect(notificationData['ownerId'], equals(ownerId));
        expect(notificationData['ownerUsername'], equals(ownerUsername));
        expect(notificationData['contributorId'], equals(contributorId));
        expect(notificationData['isRead'], equals(false));
        expect(notificationData['createdAt'], isA<Timestamp>());
      });

      test('should throw exception when folder ID is empty', () async {
        expect(
          () => folderService.notifyContributorAdded('', 'contributor-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder ID is required'),
          )),
        );
      });

      test('should throw exception when contributor ID is empty', () async {
        expect(
          () => folderService.notifyContributorAdded('folder-123', ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Contributor ID is required'),
          )),
        );
      });

      test('should throw exception when folder does not exist', () async {
        expect(
          () => folderService.notifyContributorAdded('nonexistent-folder', 'contributor-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder not found'),
          )),
        );
      });

      test('should throw exception when owner profile is not found', () async {
        const folderId = 'folder-123';
        const contributorId = 'contributor-123';
        const ownerId = 'owner-123';

        // Create folder document
        await fakeFirestore.collection('folders').doc(folderId).set({
          'name': 'Test Folder',
          'userId': ownerId,
          'isShared': true,
          'contributorIds': [contributorId],
          'createdAt': Timestamp.now(),
        });

        // Don't set up user profile (simulating not found)

        expect(
          () => folderService.notifyContributorAdded(folderId, contributorId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder owner profile not found'),
          )),
        );
      });
    });

    group('getSharedFolderNotifications', () {
      test('should return notifications for a user', () async {
        const userId = 'user-123';

        // Create test notifications
        await fakeFirestore.collection('shared_folder_notifications').add({
          'folderId': 'folder-1',
          'folderName': 'Folder 1',
          'ownerId': 'owner-1',
          'ownerUsername': 'owner1',
          'contributorId': userId,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'isRead': false,
        });

        await fakeFirestore.collection('shared_folder_notifications').add({
          'folderId': 'folder-2',
          'folderName': 'Folder 2',
          'ownerId': 'owner-2',
          'ownerUsername': 'owner2',
          'contributorId': userId,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
          'isRead': true,
        });

        // Add notification for different user (should not be returned)
        await fakeFirestore.collection('shared_folder_notifications').add({
          'folderId': 'folder-3',
          'folderName': 'Folder 3',
          'ownerId': 'owner-3',
          'ownerUsername': 'owner3',
          'contributorId': 'different-user',
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 3)),
          'isRead': false,
        });

        final notifications = await folderService.getSharedFolderNotifications(userId);

        expect(notifications.length, equals(2));
        expect(notifications[0].folderName, equals('Folder 2')); // Most recent first
        expect(notifications[1].folderName, equals('Folder 1'));
        expect(notifications.every((n) => n.contributorId == userId), isTrue);
      });

      test('should return empty list when user has no notifications', () async {
        const userId = 'user-with-no-notifications';

        final notifications = await folderService.getSharedFolderNotifications(userId);

        expect(notifications, isEmpty);
      });

      test('should throw exception when user ID is empty', () async {
        expect(
          () => folderService.getSharedFolderNotifications(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID is required'),
          )),
        );
      });
    });

    group('markNotificationAsRead', () {
      test('should mark notification as read', () async {
        // Create test notification
        final docRef = await fakeFirestore.collection('shared_folder_notifications').add({
          'folderId': 'folder-1',
          'folderName': 'Folder 1',
          'ownerId': 'owner-1',
          'ownerUsername': 'owner1',
          'contributorId': 'user-123',
          'createdAt': Timestamp.now(),
          'isRead': false,
        });

        // Mark as read
        await folderService.markNotificationAsRead(docRef.id);

        // Verify it was marked as read
        final doc = await docRef.get();
        expect(doc.data()!['isRead'], equals(true));
      });

      test('should throw exception when notification ID is empty', () async {
        expect(
          () => folderService.markNotificationAsRead(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Notification ID is required'),
          )),
        );
      });
    });

    group('deleteNotification', () {
      test('should delete notification', () async {
        // Create test notification
        final docRef = await fakeFirestore.collection('shared_folder_notifications').add({
          'folderId': 'folder-1',
          'folderName': 'Folder 1',
          'ownerId': 'owner-1',
          'ownerUsername': 'owner1',
          'contributorId': 'user-123',
          'createdAt': Timestamp.now(),
          'isRead': false,
        });

        // Delete notification
        await folderService.deleteNotification(docRef.id);

        // Verify it was deleted
        final doc = await docRef.get();
        expect(doc.exists, isFalse);
      });

      test('should throw exception when notification ID is empty', () async {
        expect(
          () => folderService.deleteNotification(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Notification ID is required'),
          )),
        );
      });
    });

    group('getUnreadNotificationCount', () {
      test('should return correct unread count', () async {
        const userId = 'user-123';

        // Create test notifications
        await fakeFirestore.collection('shared_folder_notifications').add({
          'contributorId': userId,
          'isRead': false,
          'createdAt': Timestamp.now(),
        });

        await fakeFirestore.collection('shared_folder_notifications').add({
          'contributorId': userId,
          'isRead': true,
          'createdAt': Timestamp.now(),
        });

        await fakeFirestore.collection('shared_folder_notifications').add({
          'contributorId': userId,
          'isRead': false,
          'createdAt': Timestamp.now(),
        });

        // Add notification for different user
        await fakeFirestore.collection('shared_folder_notifications').add({
          'contributorId': 'different-user',
          'isRead': false,
          'createdAt': Timestamp.now(),
        });

        final count = await folderService.getUnreadNotificationCount(userId);

        expect(count, equals(2));
      });

      test('should return 0 when user has no unread notifications', () async {
        const userId = 'user-with-no-unread';

        final count = await folderService.getUnreadNotificationCount(userId);

        expect(count, equals(0));
      });

      test('should return 0 when user ID is empty', () async {
        final count = await folderService.getUnreadNotificationCount('');

        expect(count, equals(0));
      });
    });
  });
}


// Mock MediaService for testing
class MockMediaService extends MediaService {
  MockMediaService() : super(firestore: FakeFirebaseFirestore());
}

// Mock UserProfileService for testing
class MockUserProfileService extends UserProfileService {
  final Map<String, Map<String, dynamic>> _profiles = {};

  MockUserProfileService() : super();

  void setUserProfile(String userId, Map<String, dynamic> profileData) {
    _profiles[userId] = profileData;
  }

  @override
  Future<dynamic> getUserProfile(String userId) async {
    final profileData = _profiles[userId];
    if (profileData == null) return null;
    
    // Return a mock UserProfile-like object
    return MockUserProfile(
      id: profileData['id'],
      email: profileData['email'],
      username: profileData['username'],
      createdAt: profileData['createdAt'],
      updatedAt: profileData['updatedAt'],
    );
  }
}

// Mock UserProfile for testing
class MockUserProfile {
  final String id;
  final String email;
  final String username;
  final DateTime createdAt;
  final DateTime updatedAt;

  MockUserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
  });
}