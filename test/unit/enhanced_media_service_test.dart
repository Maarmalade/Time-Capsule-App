import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:time_capsule/services/media_service.dart';
import 'package:time_capsule/models/diary_entry_model.dart';
import 'package:time_capsule/models/media_file_model.dart';
import 'dart:io';

// Generate mocks
@GenerateMocks([
  FirebaseStorage,
  FirebaseFirestore,
  Reference,
  UploadTask,
  TaskSnapshot,
  DocumentReference,
  CollectionReference,
  ImagePicker,
])
import 'enhanced_media_service_test.mocks.dart';

void main() {
  group('Enhanced MediaService Tests', () {
    late MediaService service;
    late MockFirebaseStorage mockStorage;
    late MockFirebaseFirestore mockFirestore;
    late MockReference mockRef;
    late MockUploadTask mockUploadTask;
    late MockTaskSnapshot mockSnapshot;
    late MockDocumentReference mockDocRef;
    late MockCollectionReference mockCollectionRef;

    setUp(() {
      mockStorage = MockFirebaseStorage();
      mockFirestore = MockFirebaseFirestore();
      mockRef = MockReference();
      mockUploadTask = MockUploadTask();
      mockSnapshot = MockTaskSnapshot();
      mockDocRef = MockDocumentReference();
      mockCollectionRef = MockCollectionReference();
      
      service = MediaService();
      // Note: In a real implementation, you'd inject these dependencies
    });

    group('Diary Entry Operations', () {
      test('should create diary entry successfully', () async {
        final testDiary = DiaryEntryModel(
          id: '',
          folderId: 'test-folder',
          title: 'Test Diary',
          content: 'Test content',
          attachments: [],
          createdAt: Timestamp.now(),
        );

        when(mockFirestore.collection('folders'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('test-folder'))
            .thenReturn(mockDocRef);
        when(mockDocRef.collection('media'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.add(any))
            .thenAnswer((_) async => mockDocRef);
        when(mockDocRef.id).thenReturn('generated-id');

        final result = await service.createDiaryEntry(
          folderId: 'test-folder',
          diary: testDiary,
          userId: 'test-user',
          isSharedFolder: false,
        );

        expect(result, equals('generated-id'));
        verify(mockCollectionRef.add(any)).called(1);
      });

      test('should update diary entry successfully', () async {
        final testDiary = DiaryEntryModel(
          id: 'existing-id',
          folderId: 'test-folder',
          title: 'Updated Diary',
          content: 'Updated content',
          attachments: [],
          createdAt: Timestamp.now(),
          lastModified: Timestamp.now(),
        );

        when(mockFirestore.collection('folders'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('test-folder'))
            .thenReturn(mockDocRef);
        when(mockDocRef.collection('media'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('existing-id'))
            .thenReturn(mockDocRef);
        when(mockDocRef.update(any))
            .thenAnswer((_) async {
              return null;
            });

        await service.updateDiaryEntry(
          folderId: 'test-folder',
          diaryId: 'existing-id',
          diary: testDiary,
          userId: 'test-user',
        );

        verify(mockDocRef.update(any)).called(1);
      });

      test('should handle diary creation errors gracefully', () async {
        final testDiary = DiaryEntryModel(
          id: '',
          folderId: 'test-folder',
          title: 'Test Diary',
          content: 'Test content',
          attachments: [],
          createdAt: Timestamp.now(),
        );

        when(mockFirestore.collection('folders'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('test-folder'))
            .thenReturn(mockDocRef);
        when(mockDocRef.collection('media'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.add(any))
            .thenThrow(Exception('Firestore error'));

        expect(
          () => service.createDiaryEntry(
            folderId: 'test-folder',
            diary: testDiary,
            userId: 'test-user',
            isSharedFolder: false,
          ),
          throwsException,
        );
      });
    });

    group('Enhanced Image Capture', () {
      test('should capture and upload image from camera', () async {
        final mockFile = File('test/path/image.jpg');
        
        when(mockStorage.ref()).thenReturn(mockRef);
        when(mockRef.child(any)).thenReturn(mockRef);
        when(mockRef.putFile(any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshot).thenReturn(mockSnapshot);
        when(mockSnapshot.ref).thenReturn(mockRef);
        when(mockRef.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/image.jpg');

        when(mockFirestore.collection('folders'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('test-folder'))
            .thenReturn(mockDocRef);
        when(mockDocRef.collection('media'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.add(any))
            .thenAnswer((_) async => mockDocRef);
        when(mockDocRef.id).thenReturn('media-id');

        final result = await service.captureAndUploadImage(
          folderId: 'test-folder',
          userId: 'test-user',
          source: ImageSource.camera,
          context: null, // Mock context not needed for unit test
          isSharedFolder: false,
        );

        expect(result, isA<MediaFileModel>());
        expect(result?.type, equals('image'));
        expect(result?.url, equals('https://example.com/image.jpg'));
      });

      test('should handle image capture cancellation', () async {
        // Mock ImagePicker returning null (user cancelled)
        final result = await service.captureAndUploadImage(
          folderId: 'test-folder',
          userId: 'test-user',
          source: ImageSource.camera,
          context: null,
          isSharedFolder: false,
        );

        expect(result, isNull);
      });
    });

    group('Enhanced Video Capture', () {
      test('should capture and upload video from camera', () async {
        final mockFile = File('test/path/video.mp4');
        
        when(mockStorage.ref()).thenReturn(mockRef);
        when(mockRef.child(any)).thenReturn(mockRef);
        when(mockRef.putFile(any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshot).thenReturn(mockSnapshot);
        when(mockSnapshot.ref).thenReturn(mockRef);
        when(mockRef.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/video.mp4');

        when(mockFirestore.collection('folders'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('test-folder'))
            .thenReturn(mockDocRef);
        when(mockDocRef.collection('media'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.add(any))
            .thenAnswer((_) async => mockDocRef);
        when(mockDocRef.id).thenReturn('media-id');

        final result = await service.captureAndUploadVideo(
          folderId: 'test-folder',
          userId: 'test-user',
          source: ImageSource.camera,
          context: null,
          isSharedFolder: false,
        );

        expect(result, isA<MediaFileModel>());
        expect(result?.type, equals('video'));
        expect(result?.url, equals('https://example.com/video.mp4'));
      });
    });

    group('Audio File Operations', () {
      test('should upload recorded audio successfully', () async {
        final mockFile = File('test/path/recording.m4a');
        
        when(mockStorage.ref()).thenReturn(mockRef);
        when(mockRef.child(any)).thenReturn(mockRef);
        when(mockRef.putFile(any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshot).thenReturn(mockSnapshot);
        when(mockSnapshot.ref).thenReturn(mockRef);
        when(mockRef.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/recording.m4a');

        when(mockFirestore.collection('folders'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('test-folder'))
            .thenReturn(mockDocRef);
        when(mockDocRef.collection('media'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.add(any))
            .thenAnswer((_) async => mockDocRef);
        when(mockDocRef.id).thenReturn('media-id');

        final result = await service.uploadRecordedAudio(
          folderId: 'test-folder',
          userId: 'test-user',
          recordingPath: 'test/path/recording.m4a',
          title: 'Test Recording',
          isSharedFolder: false,
        );

        expect(result, isA<MediaFileModel>());
        expect(result?.type, equals('audio'));
        expect(result?.url, equals('https://example.com/recording.m4a'));
      });

      test('should upload audio file successfully', () async {
        final mockFile = File('test/path/audio.mp3');
        
        when(mockStorage.ref()).thenReturn(mockRef);
        when(mockRef.child(any)).thenReturn(mockRef);
        when(mockRef.putFile(any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshot).thenReturn(mockSnapshot);
        when(mockSnapshot.ref).thenReturn(mockRef);
        when(mockRef.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/audio.mp3');

        when(mockFirestore.collection('folders'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.doc('test-folder'))
            .thenReturn(mockDocRef);
        when(mockDocRef.collection('media'))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.add(any))
            .thenAnswer((_) async => mockDocRef);
        when(mockDocRef.id).thenReturn('media-id');

        final result = await service.uploadAudioFile(
          folderId: 'test-folder',
          userId: 'test-user',
          audioFile: mockFile,
          title: 'Test Audio',
          isSharedFolder: false,
        );

        expect(result, isA<MediaFileModel>());
        expect(result?.type, equals('audio'));
        expect(result?.url, equals('https://example.com/audio.mp3'));
      });

      test('should handle audio upload errors gracefully', () async {
        final mockFile = File('test/path/audio.mp3');
        
        when(mockStorage.ref()).thenReturn(mockRef);
        when(mockRef.child(any)).thenReturn(mockRef);
        when(mockRef.putFile(any)).thenThrow(Exception('Upload failed'));

        expect(
          () => service.uploadAudioFile(
            folderId: 'test-folder',
            userId: 'test-user',
            audioFile: mockFile,
            title: 'Test Audio',
            isSharedFolder: false,
          ),
          throwsException,
        );
      });
    });

    group('Media Validation', () {
      test('should validate supported image formats', () {
        expect(service.isValidImageFormat('image.jpg'), isTrue);
        expect(service.isValidImageFormat('image.jpeg'), isTrue);
        expect(service.isValidImageFormat('image.png'), isTrue);
        expect(service.isValidImageFormat('image.gif'), isTrue);
        expect(service.isValidImageFormat('image.webp'), isTrue);
        expect(service.isValidImageFormat('image.txt'), isFalse);
      });

      test('should validate supported video formats', () {
        expect(service.isValidVideoFormat('video.mp4'), isTrue);
        expect(service.isValidVideoFormat('video.mov'), isTrue);
        expect(service.isValidVideoFormat('video.avi'), isTrue);
        expect(service.isValidVideoFormat('video.mkv'), isTrue);
        expect(service.isValidVideoFormat('video.txt'), isFalse);
      });

      test('should validate supported audio formats', () {
        expect(service.isValidAudioFormat('audio.mp3'), isTrue);
        expect(service.isValidAudioFormat('audio.m4a'), isTrue);
        expect(service.isValidAudioFormat('audio.wav'), isTrue);
        expect(service.isValidAudioFormat('audio.aac'), isTrue);
        expect(service.isValidAudioFormat('audio.txt'), isFalse);
      });

      test('should validate file sizes', () {
        expect(service.isValidFileSize(1024 * 1024, 'image'), isTrue); // 1MB image
        expect(service.isValidFileSize(50 * 1024 * 1024, 'video'), isTrue); // 50MB video
        expect(service.isValidFileSize(10 * 1024 * 1024, 'audio'), isTrue); // 10MB audio
        
        expect(service.isValidFileSize(100 * 1024 * 1024, 'image'), isFalse); // 100MB image
        expect(service.isValidFileSize(500 * 1024 * 1024, 'video'), isFalse); // 500MB video
        expect(service.isValidFileSize(100 * 1024 * 1024, 'audio'), isFalse); // 100MB audio
      });
    });
  });
}