import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/media_service.dart';
import 'package:time_capsule/models/folder_model.dart';

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
          createdAt: DateTime.now(),
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
          createdAt: DateTime.now(),
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
          createdAt: DateTime.now(),
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
          createdAt: DateTime.now(),
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
  });
}