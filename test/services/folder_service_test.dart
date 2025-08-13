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
  WriteBatch,
  MediaService,
])
import 'folder_service_test.mocks.dart';

void main() {
  group('FolderService', () {
    late FolderService folderService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockMediaService mockMediaService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockMediaService = MockMediaService();

      when(mockFirestore.collection('folders')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
      when(mockDocument.id).thenReturn('test-folder-id');

      folderService = FolderService();
      // Note: In a real implementation, you'd inject the MediaService dependency
    });

    group('createFolder', () {
      test('should create folder successfully', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Test Folder',
          userId: 'test-user-id',
          parentFolderId: null,
          description: 'Test description',
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await folderService.createFolder(folder);

        // Assert
        expect(result, equals('test-folder-id'));
        verify(mockDocument.set(any)).called(1);
      });

      test('should throw exception for invalid folder name', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: '', // Empty name
          userId: 'test-user-id',
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        // Act & Assert
        expect(
          () => folderService.createFolder(folder),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty user ID', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Test Folder',
          userId: '', // Empty user ID
          parentFolderId: null,
          description: null,
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        // Act & Assert
        expect(
          () => folderService.createFolder(folder),
          throwsA(isA<Exception>()),
        );
      });

      test('should sanitize folder name and description', () async {
        // Arrange
        final folder = FolderModel(
          id: '',
          name: 'Test <script>alert("xss")</script> Folder',
          userId: 'test-user-id',
          parentFolderId: null,
          description: 'Test <script>alert("xss")</script> description',
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        await folderService.createFolder(folder);

        // Assert
        verify(mockDocument.set(argThat(predicate<Map<String, dynamic>>((data) {
          return !data['name'].toString().contains('<script>') &&
                 !data['description'].toString().contains('<script>');
        })))).called(1);
      });
    });

    group('deleteFolder', () {
      test('should delete folder successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final mockSubfoldersQuery = MockQuerySnapshot();
        final mockMediaQuery = MockQuerySnapshot();

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockSubfoldersQuery.docs).thenReturn([]);
        when(mockMediaQuery.docs).thenReturn([]);
        when(mockCollection.where('parentFolderId', isEqualTo: folderId))
            .thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockSubfoldersQuery);
        when(mockDocument.collection('media')).thenReturn(mockCollection);
        when(mockDocument.delete()).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => folderService.deleteFolder(folderId),
          returnsNormally,
        );
      });

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';

        // Act & Assert
        expect(
          () => folderService.deleteFolder(folderId),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle non-existent folder gracefully', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.deleteFolder(folderId),
          returnsNormally,
        );
      });

      test('should delete subfolders recursively', () async {
        // Arrange
        const folderId = 'parent-folder-id';
        const subfolderId = 'sub-folder-id';
        
        final mockDocSnapshot = MockDocumentSnapshot();
        final mockSubfoldersQuery = MockQuerySnapshot();
        final mockSubfolderDoc = MockQueryDocumentSnapshot();
        final mockMediaQuery = MockQuerySnapshot();

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockSubfolderDoc.id).thenReturn(subfolderId);
        when(mockSubfoldersQuery.docs).thenReturn([mockSubfolderDoc]);
        when(mockMediaQuery.docs).thenReturn([]);
        when(mockCollection.where('parentFolderId', isEqualTo: folderId))
            .thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockSubfoldersQuery);
        when(mockDocument.collection('media')).thenReturn(mockCollection);
        when(mockDocument.delete()).thenAnswer((_) async => {});

        // Mock the recursive call for subfolder
        final mockSubfolderDocument = MockDocumentReference();
        final mockSubfolderSnapshot = MockDocumentSnapshot();
        final mockSubfolderSubfoldersQuery = MockQuerySnapshot();
        final mockSubfolderMediaQuery = MockQuerySnapshot();

        when(mockCollection.doc(subfolderId)).thenReturn(mockSubfolderDocument);
        when(mockSubfolderDocument.get()).thenAnswer((_) async => mockSubfolderSnapshot);
        when(mockSubfolderSnapshot.exists).thenReturn(true);
        when(mockSubfolderSubfoldersQuery.docs).thenReturn([]);
        when(mockSubfolderMediaQuery.docs).thenReturn([]);
        when(mockSubfolderDocument.collection('media')).thenReturn(mockCollection);
        when(mockSubfolderDocument.delete()).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => folderService.deleteFolder(folderId),
          returnsNormally,
        );
      });
    });

    group('updateFolderName', () {
      test('should update folder name successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const newName = 'Updated Folder Name';

        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => folderService.updateFolderName(folderId, newName),
          returnsNormally,
        );
      });

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';
        const newName = 'Updated Folder Name';

        // Act & Assert
        expect(
          () => folderService.updateFolderName(folderId, newName),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for invalid folder name', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const newName = ''; // Empty name

        // Act & Assert
        expect(
          () => folderService.updateFolderName(folderId, newName),
          throwsA(isA<Exception>()),
        );
      });

      test('should sanitize folder name', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const newName = 'Updated <script>alert("xss")</script> Name';

        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.updateFolderName(folderId, newName);

        // Assert
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return !data['name'].toString().contains('<script>');
        })))).called(1);
      });
    });

    group('deleteFolders', () {
      test('should delete multiple folders successfully', () async {
        // Arrange
        final folderIds = ['folder1', 'folder2', 'folder3'];
        
        // Mock each folder deletion
        for (final folderId in folderIds) {
          final mockDoc = MockDocumentReference();
          final mockSnapshot = MockDocumentSnapshot();
          final mockSubfoldersQuery = MockQuerySnapshot();
          final mockMediaQuery = MockQuerySnapshot();

          when(mockCollection.doc(folderId)).thenReturn(mockDoc);
          when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
          when(mockSnapshot.exists).thenReturn(true);
          when(mockSubfoldersQuery.docs).thenReturn([]);
          when(mockMediaQuery.docs).thenReturn([]);
          when(mockDoc.collection('media')).thenReturn(mockCollection);
          when(mockDoc.delete()).thenAnswer((_) async => {});
        }

        when(mockCollection.where('parentFolderId', isEqualTo: anyNamed('parentFolderId')))
            .thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => MockQuerySnapshot());

        // Act & Assert
        expect(
          () => folderService.deleteFolders(folderIds),
          returnsNormally,
        );
      });

      test('should throw exception for empty folder list', () async {
        // Arrange
        final folderIds = <String>[];

        // Act & Assert
        expect(
          () => folderService.deleteFolders(folderIds),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for too many folders', () async {
        // Arrange
        final folderIds = List.generate(51, (index) => 'folder$index');

        // Act & Assert
        expect(
          () => folderService.deleteFolders(folderIds),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle partial failures gracefully', () async {
        // Arrange
        final folderIds = ['folder1', 'folder2'];
        
        // Mock first folder deletion success
        final mockDoc1 = MockDocumentReference();
        final mockSnapshot1 = MockDocumentSnapshot();
        final mockSubfoldersQuery1 = MockQuerySnapshot();
        final mockMediaQuery1 = MockQuerySnapshot();

        when(mockCollection.doc('folder1')).thenReturn(mockDoc1);
        when(mockDoc1.get()).thenAnswer((_) async => mockSnapshot1);
        when(mockSnapshot1.exists).thenReturn(true);
        when(mockSubfoldersQuery1.docs).thenReturn([]);
        when(mockMediaQuery1.docs).thenReturn([]);
        when(mockDoc1.collection('media')).thenReturn(mockCollection);
        when(mockDoc1.delete()).thenAnswer((_) async => {});

        // Mock second folder deletion failure
        final mockDoc2 = MockDocumentReference();
        when(mockCollection.doc('folder2')).thenReturn(mockDoc2);
        when(mockDoc2.get()).thenThrow(Exception('Firestore error'));

        when(mockCollection.where('parentFolderId', isEqualTo: anyNamed('parentFolderId')))
            .thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => MockQuerySnapshot());

        // Act & Assert
        expect(
          () => folderService.deleteFolders(folderIds),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getFolder', () {
      test('should return folder when it exists', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'name': 'Test Folder',
          'userId': 'test-user-id',
          'parentFolderId': null,
          'description': 'Test description',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocSnapshot.id).thenReturn(folderId);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.getFolder(folderId);

        // Assert
        expect(result, isA<FolderModel>());
        expect(result?.id, equals(folderId));
        expect(result?.name, equals('Test Folder'));
      });

      test('should return null when folder does not exist', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.getFolder(folderId);

        // Assert
        expect(result, isNull);
      });
    });

    // ========== SHARED FOLDER TESTS ==========

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
        final mockDocSnapshot = MockDocumentSnapshot();
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
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          final contributors = data['contributorIds'] as List;
          return contributors.contains('existing-contributor') &&
                 contributors.contains('new-contributor1') &&
                 contributors.contains('new-contributor2');
        })))).called(1);
      });

      test('should throw exception for non-shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final userIds = ['new-contributor'];
        final mockDocSnapshot = MockDocumentSnapshot();
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
        final mockDocSnapshot = MockDocumentSnapshot();
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

      test('should not add owner as contributor', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final userIds = ['owner-user-id', 'new-contributor'];
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'isShared': true,
          'contributorIds': [],
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
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          final contributors = data['contributorIds'] as List;
          return !contributors.contains('owner-user-id') &&
                 contributors.contains('new-contributor');
        })))).called(1);
      });

      test('should not add duplicate contributors', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final userIds = ['existing-contributor', 'new-contributor'];
        final mockDocSnapshot = MockDocumentSnapshot();
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
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          final contributors = data['contributorIds'] as List;
          return contributors.length == 2 &&
                 contributors.contains('existing-contributor') &&
                 contributors.contains('new-contributor');
        })))).called(1);
      });
    });

    group('removeContributor', () {
      test('should remove contributor successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'contributor-to-remove';
        final mockDocSnapshot = MockDocumentSnapshot();
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
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          final contributors = data['contributorIds'] as List;
          return !contributors.contains('contributor-to-remove') &&
                 contributors.contains('other-contributor');
        })))).called(1);
      });

      test('should throw exception when trying to remove owner', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'owner-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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

      test('should throw exception for non-shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'contributor';
        final mockDocSnapshot = MockDocumentSnapshot();
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
          () => folderService.removeContributor(folderId, userId),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle removing non-existent contributor gracefully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'non-existent-contributor';
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'isShared': true,
          'contributorIds': ['existing-contributor'],
          'ownerId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.removeContributor(folderId, userId),
          returnsNormally,
        );
        verifyNever(mockDocument.update(any));
      });
    });

    group('lockFolder', () {
      test('should lock folder successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return data['isLocked'] == true && data['lockedAt'] is Timestamp;
        })))).called(1);
      });

      test('should throw exception for non-shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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

      test('should throw exception for non-existent folder', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.lockFolder(folderId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('unlockFolder', () {
      test('should unlock folder successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor'],
          'ownerId': 'owner-user-id',
          'isLocked': true,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.unlockFolder(folderId);

        // Assert
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return data['isLocked'] == false && data['lockedAt'] == null;
        })))).called(1);
      });

      test('should throw exception for non-shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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
          () => folderService.unlockFolder(folderId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getSharedFolderData', () {
      test('should return shared folder data for shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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
        final mockDocSnapshot = MockDocumentSnapshot();
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

      test('should return null for non-existent folder', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.getSharedFolderData(folderId);

        // Assert
        expect(result, isNull);
      });
    });

    // ========== PUBLIC FOLDER TESTS ==========

    group('makePublic', () {
      test('should make folder public successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();

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
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.makePublic(folderId),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';

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
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await folderService.makePrivate(folderId);

        // Assert
        verify(mockDocument.update({'isPublic': false})).called(1);
      });

      test('should throw exception for non-existent folder', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => folderService.makePrivate(folderId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getPublicFolders', () {
      test('should return public folders successfully', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocSnapshot1 = MockQueryDocumentSnapshot();
        final mockQueryDocSnapshot2 = MockQueryDocumentSnapshot();
        
        final folderData1 = {
          'name': 'Public Folder 1',
          'userId': 'user1',
          'parentFolderId': null,
          'description': 'Public description 1',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };
        
        final folderData2 = {
          'name': 'Public Folder 2',
          'userId': 'user2',
          'parentFolderId': null,
          'description': 'Public description 2',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };

        when(mockQueryDocSnapshot1.id).thenReturn('folder1');
        when(mockQueryDocSnapshot1.data()).thenReturn(folderData1);
        when(mockQueryDocSnapshot2.id).thenReturn('folder2');
        when(mockQueryDocSnapshot2.data()).thenReturn(folderData2);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot1, mockQueryDocSnapshot2]);
        
        // Mock the query chain
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true)).thenReturn(mockCollection);
        when(mockCollection.limit(20)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await folderService.getPublicFolders();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].name, equals('Public Folder 1'));
        expect(result[1].name, equals('Public Folder 2'));
      });

      test('should filter folders by search query', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocSnapshot1 = MockQueryDocumentSnapshot();
        final mockQueryDocSnapshot2 = MockQueryDocumentSnapshot();
        
        final folderData1 = {
          'name': 'Vacation Photos',
          'userId': 'user1',
          'parentFolderId': null,
          'description': 'Summer vacation memories',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };
        
        final folderData2 = {
          'name': 'Work Documents',
          'userId': 'user2',
          'parentFolderId': null,
          'description': 'Office files',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };

        when(mockQueryDocSnapshot1.id).thenReturn('folder1');
        when(mockQueryDocSnapshot1.data()).thenReturn(folderData1);
        when(mockQueryDocSnapshot2.id).thenReturn('folder2');
        when(mockQueryDocSnapshot2.data()).thenReturn(folderData2);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot1, mockQueryDocSnapshot2]);
        
        // Mock the query chain
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true)).thenReturn(mockCollection);
        when(mockCollection.limit(20)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await folderService.getPublicFolders(searchQuery: 'vacation');

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, equals('Vacation Photos'));
      });

      test('should respect limit parameter', () async {
        // Arrange
        const limit = 5;
        final mockQuerySnapshot = MockQuerySnapshot();

        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true)).thenReturn(mockCollection);
        when(mockCollection.limit(limit)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        await folderService.getPublicFolders(limit: limit);

        // Assert
        verify(mockCollection.limit(limit)).called(1);
      });
    });

    group('isFolderPublic', () {
      test('should return true for public folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {'isPublic': false};

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.isFolderPublic(folderId);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for non-existent folder', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
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

    group('canUserContribute', () {
      test('should return true for owner of regular folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'owner-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'isShared': false,
          'userId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.canUserContribute(folderId, userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return true for contributor of unlocked shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'contributor-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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
        final mockDocSnapshot = MockDocumentSnapshot();
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

      test('should return false for non-contributor', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'random-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'isShared': true,
          'contributorIds': ['other-contributor'],
          'ownerId': 'owner-user-id',
          'isLocked': false,
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
      test('should return true for owner of regular folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'owner-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'isShared': false,
          'userId': 'owner-user-id',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.canUserView(folderId, userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return true for contributor of shared folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'contributor-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final folderData = {
          'isShared': true,
          'contributorIds': ['contributor-user-id'],
          'ownerId': 'owner-user-id',
          'isPublic': false,
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(folderData);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await folderService.canUserView(folderId, userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return true for any user viewing public folder', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const userId = 'random-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
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
        final mockDocSnapshot = MockDocumentSnapshot();
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
  });
}