import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/user_profile_service.dart';
import 'package:time_capsule/models/user_profile.dart';

import 'folder_service_contributor_management_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  FirebaseAuth,
  User,
  UserProfileService,
])
void main() {
  group('FolderService Contributor Management', () {
    late FolderService folderService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserProfileService mockUserProfileService;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserProfileService = MockUserProfileService();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      // Setup auth mocks
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('owner123');

      // Setup firestore mocks
      when(mockFirestore.collection('folders')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocRef);

      folderService = FolderService(
        firestore: mockFirestore,
        auth: mockAuth,
        userProfileService: mockUserProfileService,
      );
    });

    group('getFolderContributors', () {
      test('should return empty list for non-shared folder', () async {
        // Arrange
        final folderData = {
          'id': 'folder123',
          'name': 'Test Folder',
          'userId': 'owner123',
          'isShared': false,
          'contributorIds': <String>[],
          'createdAt': Timestamp.now(),
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn('folder123');

        // Act
        final contributors = await folderService.getFolderContributors('folder123');

        // Assert
        expect(contributors, isEmpty);
      });

      test('should return contributor profiles for shared folder', () async {
        // Arrange
        final folderData = {
          'id': 'folder123',
          'name': 'Test Folder',
          'userId': 'owner123',
          'isShared': true,
          'contributorIds': ['user1', 'user2'],
          'createdAt': Timestamp.now(),
        };

        final user1Profile = UserProfile(
          id: 'user1',
          email: 'user1@example.com',
          username: 'User One',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final user2Profile = UserProfile(
          id: 'user2',
          email: 'user2@example.com',
          username: 'User Two',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn('folder123');

        when(mockUserProfileService.getUserProfile('user1'))
            .thenAnswer((_) async => user1Profile);
        when(mockUserProfileService.getUserProfile('user2'))
            .thenAnswer((_) async => user2Profile);

        // Act
        final contributors = await folderService.getFolderContributors('folder123');

        // Assert
        expect(contributors, hasLength(2));
        expect(contributors[0].id, equals('user1'));
        expect(contributors[0].username, equals('User One'));
        expect(contributors[1].id, equals('user2'));
        expect(contributors[1].username, equals('User Two'));
      });

      test('should skip contributors whose profiles cannot be loaded', () async {
        // Arrange
        final folderData = {
          'id': 'folder123',
          'name': 'Test Folder',
          'userId': 'owner123',
          'isShared': true,
          'contributorIds': ['user1', 'user2', 'user3'],
          'createdAt': Timestamp.now(),
        };

        final user1Profile = UserProfile(
          id: 'user1',
          email: 'user1@example.com',
          username: 'User One',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn('folder123');

        when(mockUserProfileService.getUserProfile('user1'))
            .thenAnswer((_) async => user1Profile);
        when(mockUserProfileService.getUserProfile('user2'))
            .thenAnswer((_) async => null); // Profile not found
        when(mockUserProfileService.getUserProfile('user3'))
            .thenThrow(Exception('Profile service error'));

        // Act
        final contributors = await folderService.getFolderContributors('folder123');

        // Assert
        expect(contributors, hasLength(1));
        expect(contributors[0].id, equals('user1'));
      });

      test('should throw exception for empty folder ID', () async {
        // Act & Assert
        expect(
          () => folderService.getFolderContributors(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder ID is required'),
          )),
        );
      });

      test('should throw exception for non-existent folder', () async {
        // Arrange
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => folderService.getFolderContributors('nonexistent'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder not found'),
          )),
        );
      });
    });

    group('removeContributor', () {
      test('should successfully remove contributor from shared folder', () async {
        // Arrange
        final folderData = {
          'id': 'folder123',
          'name': 'Test Folder',
          'userId': 'owner123',
          'isShared': true,
          'contributorIds': ['user1', 'user2'],
          'createdAt': Timestamp.now(),
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn('folder123');

        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Mock notification collection for removal notification
        final mockNotificationCollection = MockCollectionReference<Map<String, dynamic>>();
        when(mockFirestore.collection('shared_folder_removal_notifications'))
            .thenReturn(mockNotificationCollection);
        when(mockNotificationCollection.add(any)).thenAnswer((_) async => mockDocRef);

        // Mock user profile service for notification
        final ownerProfile = UserProfile(
          id: 'owner123',
          email: 'owner@example.com',
          username: 'Owner',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(mockUserProfileService.getUserProfile('owner123'))
            .thenAnswer((_) async => ownerProfile);

        // Act
        await folderService.removeContributor('folder123', 'user1');

        // Assert
        verify(mockDocRef.update({
          'contributorIds': ['user2'],
        })).called(1);
      });

      test('should throw exception when trying to remove folder owner', () async {
        // Arrange
        final folderData = {
          'id': 'folder123',
          'name': 'Test Folder',
          'userId': 'owner123',
          'isShared': true,
          'contributorIds': ['user1', 'user2'],
          'createdAt': Timestamp.now(),
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn('folder123');

        // Act & Assert
        expect(
          () => folderService.removeContributor('folder123', 'owner123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot remove the folder owner'),
          )),
        );
      });

      test('should handle removal of non-contributor gracefully', () async {
        // Arrange
        final folderData = {
          'id': 'folder123',
          'name': 'Test Folder',
          'userId': 'owner123',
          'isShared': true,
          'contributorIds': ['user1', 'user2'],
          'createdAt': Timestamp.now(),
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn('folder123');

        // Act - should not throw exception
        await folderService.removeContributor('folder123', 'user3');

        // Assert - update should not be called since user is not a contributor
        verifyNever(mockDocRef.update(any));
      });

      test('should throw exception for non-shared folder', () async {
        // Arrange
        final folderData = {
          'id': 'folder123',
          'name': 'Test Folder',
          'userId': 'owner123',
          'isShared': false,
          'contributorIds': <String>[],
          'createdAt': Timestamp.now(),
        };

        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn('folder123');

        // Act & Assert
        expect(
          () => folderService.removeContributor('folder123', 'user1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot remove contributors from a non-shared folder'),
          )),
        );
      });

      test('should throw exception for empty folder ID', () async {
        // Act & Assert
        expect(
          () => folderService.removeContributor('', 'user1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder ID is required'),
          )),
        );
      });

      test('should throw exception for empty user ID', () async {
        // Act & Assert
        expect(
          () => folderService.removeContributor('folder123', ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID is required'),
          )),
        );
      });
    });
  });
}