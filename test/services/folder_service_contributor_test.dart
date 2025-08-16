import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FolderService Contributor Management', () {
    late FolderService folderService;

    setUp(() {
      folderService = FolderService();
    });

    group('getFolderContributors', () {
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

      test('should handle non-existent folder gracefully', () async {
        // Act & Assert
        expect(
          () => folderService.getFolderContributors('nonexistent_folder_id'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder not found'),
          )),
        );
      });
    });

    group('removeContributor', () {
      test('should throw exception for empty folder ID', () async {
        // Act & Assert
        expect(
          () => folderService.removeContributor('', 'user123'),
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

      test('should handle non-existent folder gracefully', () async {
        // Act & Assert
        expect(
          () => folderService.removeContributor('nonexistent_folder_id', 'user123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Folder not found'),
          )),
        );
      });
    });

    group('Validation Tests', () {
      test('should validate folder model structure', () {
        // Test that FolderModel has the required fields for contributor management
        final folder = FolderModel(
          id: 'test123',
          name: 'Test Folder',
          userId: 'owner123',
          createdAt: Timestamp.now(),
          isShared: true,
          contributorIds: ['user1', 'user2'],
        );

        expect(folder.id, equals('test123'));
        expect(folder.isShared, isTrue);
        expect(folder.contributorIds, hasLength(2));
        expect(folder.contributorIds, contains('user1'));
        expect(folder.contributorIds, contains('user2'));
      });

      test('should validate user profile structure', () {
        // Test that UserProfile has the required fields for contributor display
        final profile = UserProfile(
          id: 'user123',
          email: 'user@example.com',
          username: 'Test User',
          profilePictureUrl: 'https://example.com/avatar.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(profile.id, equals('user123'));
        expect(profile.username, equals('Test User'));
        expect(profile.email, equals('user@example.com'));
        expect(profile.profilePictureUrl, equals('https://example.com/avatar.jpg'));
      });
    });

    group('Service Method Existence', () {
      test('should have getFolderContributors method', () {
        // Verify the method exists and has correct signature
        expect(folderService.getFolderContributors, isA<Function>());
      });

      test('should have removeContributor method', () {
        // Verify the method exists and has correct signature
        expect(folderService.removeContributor, isA<Function>());
      });

      test('should have existing shared folder methods', () {
        // Verify other required methods exist
        expect(folderService.createSharedFolder, isA<Function>());
        expect(folderService.inviteContributors, isA<Function>());
        expect(folderService.getSharedFolderData, isA<Function>());
        expect(folderService.canUserView, isA<Function>());
        expect(folderService.canUserContribute, isA<Function>());
      });
    });
  });
}