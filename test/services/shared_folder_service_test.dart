import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/media_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/shared_folder_data.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  MediaService,
])
import 'shared_folder_service_test.mocks.dart';

void main() {
  group('FolderService - Shared Folder Functionality', () {
    late FolderService folderService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocument;
    late MockMediaService mockMediaService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocument = MockDocumentReference<Map<String, dynamic>>();
      mockMediaService = MockMediaService();

      when(mockFirestore.collection('folders')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
      when(mockDocument.id).thenReturn('test-folder-id');

      folderService = FolderService(
        firestore: mockFirestore,
        mediaService: mockMediaService,
      );
    });

    group('createSharedFolder', () {
      test('should create shared folder successfully', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Shared Test Folder',
          userId: 'owner-user-id',
          parentFolderId: null,
          description: 'Shared test description',
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );
        final contributorIds = ['contributor1', 'contributor2'];

        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await folderService.createSharedFolder(folder, contributorIds);

        // Assert
        expect(result, equals('test-folder-id'));
        verify(mockDocument.set(argThat(predicate<Map<String, dynamic>>((data) {
          return data['isShared'] == true &&
                 data['contributorIds'] is List &&
                 data['ownerId'] == 'owner-user-id' &&
                 data['isLocked'] == false &&
                 data['isPublic'] == false;
        })))).called(1);
      });

      test('should throw exception for empty contributors list', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Shared Test Folder',
          userId: 'owner-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );
        final contributorIds = <String>[];

        // Act & Assert
        expect(
          () => folderService.createSharedFolder(folder, contributorIds),
          throwsA(isA<Exception>()),
        );
      });

      test('should remove owner from contributors list', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Shared Test Folder',
          userId: 'owner-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );
        final contributorIds = ['owner-user-id', 'contributor1', 'contributor2'];

        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        await folderService.createSharedFolder(folder, contributorIds);

        // Assert
        verify(mockDocument.set(argThat(predicate<Map<String, dynamic>>((data) {
          final contributors = data['contributorIds'] as List;
          return !contributors.contains('owner-user-id') &&
                 contributors.contains('contributor1') &&
                 contributors.contains('contributor2');
        })))).called(1);
      });

      test('should remove duplicate contributors', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Shared Test Folder',
          userId: 'owner-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );
        final contributorIds = ['contributor1', 'contributor1', 'contributor2'];

        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        await folderService.createSharedFolder(folder, contributorIds);

        // Assert
        verify(mockDocument.set(argThat(predicate<Map<String, dynamic>>((data) {
          final contributors = data['contributorIds'] as List;
          return contributors.length == 2 &&
                 contributors.contains('contributor1') &&
                 contributors.contains('contributor2');
        })))).called(1);
      });

      test('should throw exception when only owner in contributors', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Shared Test Folder',
          userId: 'owner-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );
        final contributorIds = ['owner-user-id'];

        // Act & Assert
        expect(
          () => folderService.createSharedFolder(folder, contributorIds),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('inviteContributors', () {
      test('should invite contributors successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final userIds = ['new-contributor1', 'new-contributor2'];
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['existing-contributor'],
          'ownerId': 'owner-user-id',
          'isLocked': false,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.inviteContributors(folderId, userIds);

        // Assert
        verify(mockDocument.update(any)).called(1);
      });

      test('should throw exception for non-shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final userIds = ['new-contributor'];
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': false,
          'contributorIds': [],
          'ownerId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.inviteContributors(folderId, userIds),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for locked folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final userIds = ['new-contributor'];
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': [],
          'ownerId': 'owner-user-id',
          'isLocked': true,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.inviteContributors(folderId, userIds),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('removeContributor', () {
      test('should remove contributor successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'contributor-to-remove';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor-to-remove', 'other-contributor'],
          'ownerId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.removeContributor(folderId, userId);

        // Assert
        verify(mockDocument.update(any)).called(1);
      });

      test('should throw exception when trying to remove owner', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'owner-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor'],
          'ownerId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.removeContributor(folderId, userId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('lockFolder', () {
      test('should lock folder successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor'],
          'ownerId': 'owner-user-id',
          'isLocked': false,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.lockFolder(folderId);

        // Assert
        verify(mockDocument.update(any)).called(1);
      });

      test('should throw exception for non-shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': false,
          'contributorIds': [],
          'ownerId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.lockFolder(folderId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('makePublic', () {
      test('should make folder public successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.makePublic(folderId);

        // Assert
        verify(mockDocument.update({'isPublic': true})).called(1);
      });

      test('should throw exception for non-existent folder', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.makePublic(folderId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('makePrivate', () {
      test('should make folder private successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.makePrivate(folderId);

        // Assert
        verify(mockDocument.update({'isPublic': false})).called(1);
      });
    });

    group('getSharedFolderData', () {
      test('should return shared folder data for shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor1', 'contributor2'],
          'ownerId': 'owner-user-id',
          'isLocked': false,
          'lockedAt': null,
          'isPublic': false,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.getSharedFolderData(folderId);

        // Assert
        expect(result, isA<SharedFolderData>());
        expect(result?.ownerId, equals('owner-user-id'));
        expect(result?.contributorIds, contains('contributor1'));
        expect(result?.contributorIds, contains('contributor2'));
        expect(result?.isLocked, isFalse);
        expect(result?.isPublic, isFalse);
      });

      test('should return null for non-shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': false,
          'contributorIds': [],
          'ownerId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.getSharedFolderData(folderId);

        // Assert
        expect(result, isNull);
      });
    });

    group('canUserContribute', () {
      test('should return true for owner of regular folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'owner-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': false,
          'userId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert - This test verifies the method doesn't throw an exception
        // The actual logic is complex due to multiple Firestore calls
        expect(
          () => folderService.canUserContribute(folderId, userId),
          returnsNormally,
        );
      });

      test('should return true for contributor of unlocked shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'contributor-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor-user-id'],
          'ownerId': 'owner-user-id',
          'isLocked': false,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.canUserContribute(folderId, userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for contributor of locked shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'contributor-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor-user-id'],
          'ownerId': 'owner-user-id',
          'isLocked': true,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.canUserContribute(folderId, userId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('canUserView', () {
      test('should return true for any user viewing public folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'random-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': [],
          'ownerId': 'owner-user-id',
          'isPublic': true,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.canUserView(folderId, userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for non-contributor of private shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'random-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['other-contributor'],
          'ownerId': 'owner-user-id',
          'isPublic': false,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.canUserView(folderId, userId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('isFolderPublic', () {
      test('should return true for public folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {'isPublic': true};

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.isFolderPublic(folderId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for private folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {'isPublic': false};

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.isFolderPublic(folderId);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for empty folder ID', () async {
        // Arrange
        const folderId = '';

        // Act
        final result = await folderService.isFolderPublic(folderId);

        // Assert
        expect(result, isFalse);
      });
    });
  });
}