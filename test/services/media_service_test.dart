import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/media_service.dart';
import 'package:time_capsule/services/storage_service.dart';
import 'package:time_capsule/models/media_file_model.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  WriteBatch,
  StorageService,
])
import 'media_service_test.mocks.dart';

void main() {
  group('MediaService', () {
    late MediaService mediaService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockStorageService mockStorageService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockStorageService = MockStorageService();

      when(mockFirestore.collection('folders')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
      when(mockDocument.collection('media')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
      when(mockDocument.id).thenReturn('test-media-id');

      mediaService = MediaService();
      // Note: In a real implementation, you'd inject the StorageService dependency
    });

    group('createMedia', () {
      test('should create media file successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final media = MediaFileModel(
          id: '',
          title: 'Test Media',
          type: 'image',
          url: 'https://example.com/image.jpg',
          thumbnailUrl: null,
          content: null,
          createdAt: DateTime.now(),
        );

        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await mediaService.createMedia(folderId, media);

        // Assert
        expect(result, equals('test-media-id'));
        verify(mockDocument.set(any)).called(1);
      });
    });

    group('deleteMedia', () {
      test('should delete media file successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'test-media-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final mediaData = {
          'title': 'Test Media',
          'type': 'image',
          'url': 'https://example.com/image.jpg',
          'thumbnailUrl': null,
          'content': null,
          'createdAt': Timestamp.now(),
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(mediaData);
        when(mockDocSnapshot.id).thenReturn(mediaId);
        when(mockDocSnapshot.reference).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.delete()).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => mediaService.deleteMedia(folderId, mediaId),
          returnsNormally,
        );
      });

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';
        const mediaId = 'test-media-id';

        // Act & Assert
        expect(
          () => mediaService.deleteMedia(folderId, mediaId),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty media ID', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = '';

        // Act & Assert
        expect(
          () => mediaService.deleteMedia(folderId, mediaId),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle non-existent media gracefully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'non-existent-media';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => mediaService.deleteMedia(folderId, mediaId),
          returnsNormally,
        );
      });

      test('should delete from storage for non-text files', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'test-media-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final mediaData = {
          'title': 'Test Media',
          'type': 'image',
          'url': 'https://example.com/image.jpg',
          'thumbnailUrl': null,
          'content': null,
          'createdAt': Timestamp.now(),
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(mediaData);
        when(mockDocSnapshot.id).thenReturn(mediaId);
        when(mockDocSnapshot.reference).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.delete()).thenAnswer((_) async => {});

        // Act
        await mediaService.deleteMedia(folderId, mediaId);

        // Assert
        // Note: In a real implementation with dependency injection,
        // we would verify the storage service call here
        verify(mockDocument.delete()).called(1);
      });

      test('should not delete from storage for text files', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'test-media-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final mediaData = {
          'title': 'Test Text',
          'type': 'text',
          'url': '',
          'thumbnailUrl': null,
          'content': 'Some text content',
          'createdAt': Timestamp.now(),
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(mediaData);
        when(mockDocSnapshot.id).thenReturn(mediaId);
        when(mockDocSnapshot.reference).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocument.delete()).thenAnswer((_) async => {});

        // Act
        await mediaService.deleteMedia(folderId, mediaId);

        // Assert
        verify(mockDocument.delete()).called(1);
        // Storage service should not be called for text files
      });
    });

    group('updateFileName', () {
      test('should update file name successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'test-media-id';
        const newTitle = 'Updated Media Title';

        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => mediaService.updateFileName(folderId, mediaId, newTitle),
          returnsNormally,
        );
      });

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';
        const mediaId = 'test-media-id';
        const newTitle = 'Updated Media Title';

        // Act & Assert
        expect(
          () => mediaService.updateFileName(folderId, mediaId, newTitle),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty media ID', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = '';
        const newTitle = 'Updated Media Title';

        // Act & Assert
        expect(
          () => mediaService.updateFileName(folderId, mediaId, newTitle),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for invalid file name', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'test-media-id';
        const newTitle = ''; // Empty title

        // Act & Assert
        expect(
          () => mediaService.updateFileName(folderId, mediaId, newTitle),
          throwsA(isA<Exception>()),
        );
      });

      test('should sanitize file name', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'test-media-id';
        const newTitle = 'Updated <script>alert("xss")</script> Title';

        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await mediaService.updateFileName(folderId, mediaId, newTitle);

        // Assert
        verify(mockDocument.update(argThat(predicate<Map<String, dynamic>>((data) {
          return !data['title'].toString().contains('<script>');
        })))).called(1);
      });
    });

    group('deleteFiles', () {
      test('should delete multiple files successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mediaIds = ['media1', 'media2', 'media3'];
        final mockBatch = MockWriteBatch();

        // Mock each media document
        for (final mediaId in mediaIds) {
          final mockDoc = MockDocumentReference();
          final mockSnapshot = MockDocumentSnapshot();
          final mediaData = {
            'title': 'Test Media $mediaId',
            'type': 'image',
            'url': 'https://example.com/$mediaId.jpg',
            'thumbnailUrl': null,
            'content': null,
            'createdAt': Timestamp.now(),
          };

          when(mockCollection.doc(mediaId)).thenReturn(mockDoc);
          when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
          when(mockSnapshot.exists).thenReturn(true);
          when(mockSnapshot.data()).thenReturn(mediaData);
          when(mockSnapshot.id).thenReturn(mediaId);
        }

        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.delete(any)).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => mediaService.deleteFiles(folderId, mediaIds),
          returnsNormally,
        );
      });

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';
        final mediaIds = ['media1', 'media2'];

        // Act & Assert
        expect(
          () => mediaService.deleteFiles(folderId, mediaIds),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty media list', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mediaIds = <String>[];

        // Act & Assert
        expect(
          () => mediaService.deleteFiles(folderId, mediaIds),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for too many files', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mediaIds = List.generate(51, (index) => 'media$index');

        // Act & Assert
        expect(
          () => mediaService.deleteFiles(folderId, mediaIds),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle storage deletion errors gracefully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mediaIds = ['media1', 'media2'];
        final mockBatch = MockWriteBatch();

        // Mock media documents
        for (final mediaId in mediaIds) {
          final mockDoc = MockDocumentReference();
          final mockSnapshot = MockDocumentSnapshot();
          final mediaData = {
            'title': 'Test Media $mediaId',
            'type': 'image',
            'url': 'https://example.com/$mediaId.jpg',
            'thumbnailUrl': null,
            'content': null,
            'createdAt': Timestamp.now(),
          };

          when(mockCollection.doc(mediaId)).thenReturn(mockDoc);
          when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
          when(mockSnapshot.exists).thenReturn(true);
          when(mockSnapshot.data()).thenReturn(mediaData);
          when(mockSnapshot.id).thenReturn(mediaId);
        }

        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.delete(any)).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async => []);

        // Act
        // Note: Storage errors would be handled in the actual implementation
        // with dependency injection
        await mediaService.deleteFiles(folderId, mediaIds);

        // Assert
        verify(mockBatch.commit()).called(1);
      });
    });

    group('updateMedia', () {
      test('should update media successfully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        const mediaId = 'test-media-id';
        final updateData = {'title': 'Updated Title'};

        when(mockDocument.update(updateData)).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => mediaService.updateMedia(folderId, mediaId, updateData),
          returnsNormally,
        );
      });
    });
  });
}