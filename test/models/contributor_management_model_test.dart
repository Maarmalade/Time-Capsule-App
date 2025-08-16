import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Contributor Management Models', () {
    group('FolderModel', () {
      test('should create folder with contributor support', () {
        // Arrange & Act
        final folder = FolderModel(
          id: 'test123',
          name: 'Test Shared Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: true,
          contributorIds: ['user1', 'user2', 'user3'],
        );

        // Assert
        expect(folder.id, equals('test123'));
        expect(folder.name, equals('Test Shared Folder'));
        expect(folder.userId, equals('owner123'));
        expect(folder.isShared, isTrue);
        expect(folder.contributorIds, hasLength(3));
        expect(folder.contributorIds, contains('user1'));
        expect(folder.contributorIds, contains('user2'));
        expect(folder.contributorIds, contains('user3'));
      });

      test('should create non-shared folder with empty contributors', () {
        // Arrange & Act
        final folder = FolderModel(
          id: 'test456',
          name: 'Private Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: false,
        );

        // Assert
        expect(folder.isShared, isFalse);
        expect(folder.contributorIds, isEmpty);
      });

      test('should support copyWith for contributor management', () {
        // Arrange
        final originalFolder = FolderModel(
          id: 'test789',
          name: 'Original Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: true,
          contributorIds: ['user1'],
        );

        // Act - Add contributor
        final updatedFolder = originalFolder.copyWith(
          contributorIds: ['user1', 'user2'],
        );

        // Assert
        expect(originalFolder.contributorIds, hasLength(1));
        expect(updatedFolder.contributorIds, hasLength(2));
        expect(updatedFolder.contributorIds, contains('user1'));
        expect(updatedFolder.contributorIds, contains('user2'));
        expect(updatedFolder.id, equals(originalFolder.id));
        expect(updatedFolder.name, equals(originalFolder.name));
      });

      test('should convert to and from Firestore map', () {
        // Arrange
        final folder = FolderModel(
          id: 'test_convert',
          name: 'Convert Test Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: true,
          contributorIds: ['user1', 'user2'],
          isLocked: false,
        );

        // Act
        final map = folder.toMap();
        
        // Assert map contains contributor data
        expect(map['isShared'], isTrue);
        expect(map['contributorIds'], isA<List<String>>());
        expect(map['contributorIds'], hasLength(2));
        expect(map['contributorIds'], contains('user1'));
        expect(map['contributorIds'], contains('user2'));
        expect(map['isLocked'], isFalse);
      });
    });

    group('UserProfile', () {
      test('should create user profile for contributor display', () {
        // Arrange & Act
        final profile = UserProfile(
          id: 'user123',
          email: 'contributor@example.com',
          username: 'Contributor User',
          profilePictureUrl: 'https://example.com/avatar.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(profile.id, equals('user123'));
        expect(profile.email, equals('contributor@example.com'));
        expect(profile.username, equals('Contributor User'));
        expect(profile.profilePictureUrl, equals('https://example.com/avatar.jpg'));
        expect(profile.createdAt, isA<DateTime>());
        expect(profile.updatedAt, isA<DateTime>());
      });

      test('should support copyWith for profile updates', () {
        // Arrange
        final originalProfile = UserProfile(
          id: 'user456',
          email: 'original@example.com',
          username: 'Original User',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final updatedProfile = originalProfile.copyWith(
          username: 'Updated User',
          profilePictureUrl: 'https://example.com/new-avatar.jpg',
        );

        // Assert
        expect(originalProfile.username, equals('Original User'));
        expect(originalProfile.profilePictureUrl, isNull);
        expect(updatedProfile.username, equals('Updated User'));
        expect(updatedProfile.profilePictureUrl, equals('https://example.com/new-avatar.jpg'));
        expect(updatedProfile.id, equals(originalProfile.id));
        expect(updatedProfile.email, equals(originalProfile.email));
      });

      test('should convert to and from Firestore', () {
        // Arrange
        final profile = UserProfile(
          id: 'user789',
          email: 'test@example.com',
          username: 'Test User',
          profilePictureUrl: 'https://example.com/test.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final firestoreMap = profile.toFirestore();

        // Assert
        expect(firestoreMap['email'], equals('test@example.com'));
        expect(firestoreMap['username'], equals('Test User'));
        expect(firestoreMap['profilePictureUrl'], equals('https://example.com/test.jpg'));
        expect(firestoreMap['createdAt'], isA<Timestamp>());
        expect(firestoreMap['updatedAt'], isA<Timestamp>());
      });

      test('should handle equality comparison', () {
        // Arrange
        final profile1 = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          username: 'Test User',
          profilePictureUrl: null,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final profile2 = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          username: 'Test User',
          profilePictureUrl: null,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final profile3 = UserProfile(
          id: 'user456',
          email: 'test@example.com',
          username: 'Test User',
          profilePictureUrl: null,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        // Act & Assert
        expect(profile1, equals(profile2));
        expect(profile1, isNot(equals(profile3)));
        expect(profile1.hashCode, equals(profile2.hashCode));
        expect(profile1.hashCode, isNot(equals(profile3.hashCode)));
      });
    });

    group('Contributor Management Logic', () {
      test('should validate contributor access logic', () {
        // Arrange
        final folder = FolderModel(
          id: 'access_test',
          name: 'Access Test Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: true,
          contributorIds: ['user1', 'user2'],
          isLocked: false,
        );

        // Act & Assert - Owner access
        expect(folder.userId, equals('owner123'));
        
        // Act & Assert - Contributor access
        expect(folder.contributorIds.contains('user1'), isTrue);
        expect(folder.contributorIds.contains('user2'), isTrue);
        expect(folder.contributorIds.contains('user3'), isFalse);
        
        // Act & Assert - Shared folder properties
        expect(folder.isShared, isTrue);
        expect(folder.isLocked, isFalse);
      });

      test('should validate locked folder behavior', () {
        // Arrange
        final lockedFolder = FolderModel(
          id: 'locked_test',
          name: 'Locked Test Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: true,
          contributorIds: ['user1'],
          isLocked: true,
          lockedAt: Timestamp.now(),
        );

        // Act & Assert
        expect(lockedFolder.isLocked, isTrue);
        expect(lockedFolder.lockedAt, isNotNull);
        expect(lockedFolder.isShared, isTrue);
        expect(lockedFolder.contributorIds, contains('user1'));
      });

      test('should validate contributor list operations', () {
        // Arrange
        final folder = FolderModel(
          id: 'list_test',
          name: 'List Test Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: true,
          contributorIds: ['user1', 'user2', 'user3'],
        );

        // Act - Simulate removing a contributor
        final updatedContributors = List<String>.from(folder.contributorIds)
          ..remove('user2');
        
        final updatedFolder = folder.copyWith(
          contributorIds: updatedContributors,
        );

        // Assert
        expect(folder.contributorIds, hasLength(3));
        expect(updatedFolder.contributorIds, hasLength(2));
        expect(updatedFolder.contributorIds, contains('user1'));
        expect(updatedFolder.contributorIds, contains('user3'));
        expect(updatedFolder.contributorIds, isNot(contains('user2')));
      });
    });
  });
}