import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/media_service.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  MediaService,
])
import 'public_folder_service_test.mocks.dart';

void main() {
  group('FolderService - Public Folder Functionality', () {
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

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';

        // Act & Assert
        expect(
          () => folderService.makePublic(folderId),
          throwsA(isA<Exception>()),
        );
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

      test('should throw exception for empty folder ID', () async {
        // Arrange
        const folderId = '';

        // Act & Assert
        expect(
          () => folderService.makePrivate(folderId),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for non-existent folder', () async {
        // Arrange
        const folderId = 'non-existent-folder';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

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
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
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
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await folderService.getPublicFolders();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].name, equals('Public Folder 1'));
        expect(result[1].name, equals('Public Folder 2'));
        verify(mockCollection.where('isPublic', isEqualTo: true)).called(1);
        verify(mockQuery.orderBy('createdAt', descending: true)).called(1);
        verify(mockQuery.limit(20)).called(1);
      });

      test('should filter folders by search query', () async {
        // Arrange
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
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
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await folderService.getPublicFolders(searchQuery: 'vacation');

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, equals('Vacation Photos'));
      });

      test('should respect limit parameter', () async {
        // Arrange
        const limit = 5;
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(limit)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        await folderService.getPublicFolders(limit: limit);

        // Assert
        verify(mockQuery.limit(limit)).called(1);
      });

      test('should handle pagination with startAfter parameter', () async {
        // Arrange
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockStartAfterDoc = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.startAfterDocument(mockStartAfterDoc)).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        await folderService.getPublicFolders(startAfter: mockStartAfterDoc);

        // Assert
        verify(mockQuery.startAfterDocument(mockStartAfterDoc)).called(1);
      });

      test('should handle search query with description match', () async {
        // Arrange
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
        final folderData = {
          'name': 'My Photos',
          'userId': 'user1',
          'parentFolderId': null,
          'description': 'Summer vacation memories',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };

        when(mockQueryDocSnapshot.id).thenReturn('folder1');
        when(mockQueryDocSnapshot.data()).thenReturn(folderData);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        // Mock the query chain
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await folderService.getPublicFolders(searchQuery: 'vacation');

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, equals('My Photos'));
      });
    });

    group('streamPublicFolders', () {
      test('should stream public folders successfully', () async {
        // Arrange
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
        final folderData = {
          'name': 'Public Folder',
          'userId': 'user1',
          'parentFolderId': null,
          'description': 'Public description',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };

        when(mockQueryDocSnapshot.id).thenReturn('folder1');
        when(mockQueryDocSnapshot.data()).thenReturn(folderData);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        // Mock the query chain
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

        // Act
        final stream = folderService.streamPublicFolders();
        final result = await stream.first;

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, equals('Public Folder'));
        verify(mockCollection.where('isPublic', isEqualTo: true)).called(1);
        verify(mockQuery.orderBy('createdAt', descending: true)).called(1);
        verify(mockQuery.limit(20)).called(1);
      });

      test('should respect limit parameter in stream', () async {
        // Arrange
        const limit = 10;
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(limit)).thenReturn(mockQuery);
        when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

        // Act
        final stream = folderService.streamPublicFolders(limit: limit);
        await stream.first;

        // Assert
        verify(mockQuery.limit(limit)).called(1);
      });

      test('should filter streamed folders by search query', () async {
        // Arrange
        final mockQuery = MockQuery<Map<String, dynamic>>();
        final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
        final folderData1 = {
          'name': 'Beach Vacation',
          'userId': 'user1',
          'parentFolderId': null,
          'description': 'Summer memories',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };
        
        final folderData2 = {
          'name': 'Work Files',
          'userId': 'user2',
          'parentFolderId': null,
          'description': 'Office documents',
          'coverImageUrl': null,
          'createdAt': Timestamp.now(),
        };

        when(mockQueryDocSnapshot1.id).thenReturn('folder1');
        when(mockQueryDocSnapshot1.data()).thenReturn(folderData1);
        when(mockQueryDocSnapshot2.id).thenReturn('folder2');
        when(mockQueryDocSnapshot2.data()).thenReturn(folderData2);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot1, mockQueryDocSnapshot2]);
        
        // Mock the query chain
        when(mockCollection.where('isPublic', isEqualTo: true)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

        // Act
        final stream = folderService.streamPublicFolders(searchQuery: 'vacation');
        final result = await stream.first;

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, equals('Beach Vacation'));
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

      test('should return false for folder without isPublic field', () async {
        // Arrange
        const folderId = 'test-folder-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = <String, dynamic>{}; // No isPublic field

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
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

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

      test('should handle exceptions gracefully', () async {
        // Arrange
        const folderId = 'test-folder-id';
        when(mockDocument.get()).thenThrow(Exception('Firestore error'));

        // Act
        final result = await folderService.isFolderPublic(folderId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('access control logic', () {
      test('should allow any user to view public folder', () async {
        // Arrange
        const folderId = 'public-folder-id';
        const userId = 'random-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['other-user'],
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

      test('should deny access to private folder for non-contributors', () async {
        // Arrange
        const folderId = 'private-folder-id';
        const userId = 'random-user-id';
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final folderData = {
          'isShared': true,
          'contributorIds': ['other-user'],
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