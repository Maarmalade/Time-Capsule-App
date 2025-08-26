import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/models/diary_entry_model.dart';

void main() {
  group('DiaryEntryModel Tests', () {
    late DiaryEntryModel testDiary;
    late Timestamp testTimestamp;

    setUp(() {
      testTimestamp = Timestamp.now();
      testDiary = DiaryEntryModel(
        id: 'test-id',
        folderId: 'test-folder',
        title: 'Test Diary Entry',
        content: 'This is a test diary entry content.',
        attachments: [
          DiaryMediaAttachment(
            id: 'attachment-1',
            type: 'image',
            url: 'https://example.com/image.jpg',
            caption: 'Test image',
            position: 0,
          ),
          DiaryMediaAttachment(
            id: 'attachment-2',
            type: 'audio',
            url: 'https://example.com/audio.mp3',
            position: 1,
          ),
        ],
        createdAt: testTimestamp,
        lastModified: testTimestamp,
        uploadedBy: 'test-user',
      );
    });

    test('should create DiaryEntryModel with all properties', () {
      expect(testDiary.id, equals('test-id'));
      expect(testDiary.folderId, equals('test-folder'));
      expect(testDiary.title, equals('Test Diary Entry'));
      expect(testDiary.content, equals('This is a test diary entry content.'));
      expect(testDiary.attachments.length, equals(2));
      expect(testDiary.createdAt, equals(testTimestamp));
      expect(testDiary.lastModified, equals(testTimestamp));
      expect(testDiary.uploadedBy, equals('test-user'));
    });

    test('should serialize to Map correctly', () {
      final map = testDiary.toMap();

      expect(map['id'], equals('test-id'));
      expect(map['folderId'], equals('test-folder'));
      expect(map['title'], equals('Test Diary Entry'));
      expect(map['content'], equals('This is a test diary entry content.'));
      expect(map['attachments'], isA<List>());
      expect(map['createdAt'], equals(testTimestamp));
      expect(map['lastModified'], equals(testTimestamp));
      expect(map['uploadedBy'], equals('test-user'));
    });

    test('should deserialize from Map correctly', () {
      final map = {
        'id': 'test-id',
        'folderId': 'test-folder',
        'title': 'Test Diary Entry',
        'content': 'This is a test diary entry content.',
        'attachments': [
          {
            'id': 'attachment-1',
            'type': 'image',
            'url': 'https://example.com/image.jpg',
            'caption': 'Test image',
            'position': 0,
          },
        ],
        'createdAt': testTimestamp,
        'lastModified': testTimestamp,
        'uploadedBy': 'test-user',
      };

      final diary = DiaryEntryModel.fromMap(map);

      expect(diary.id, equals('test-id'));
      expect(diary.folderId, equals('test-folder'));
      expect(diary.title, equals('Test Diary Entry'));
      expect(diary.content, equals('This is a test diary entry content.'));
      expect(diary.attachments.length, equals(1));
      expect(diary.createdAt, equals(testTimestamp));
      expect(diary.lastModified, equals(testTimestamp));
      expect(diary.uploadedBy, equals('test-user'));
    });

    test('should handle null optional fields', () {
      final minimalDiary = DiaryEntryModel(
        id: 'minimal-id',
        folderId: 'minimal-folder',
        content: 'Minimal content',
        attachments: [],
        createdAt: testTimestamp,
      );

      expect(minimalDiary.title, isNull);
      expect(minimalDiary.lastModified, isNull);
      expect(minimalDiary.uploadedBy, isNull);
      expect(minimalDiary.attachments, isEmpty);
    });

    test('should create copy with updated fields', () {
      final updatedDiary = testDiary.copyWith(
        title: 'Updated Title',
        content: 'Updated content',
        lastModified: Timestamp.now(),
      );

      expect(updatedDiary.id, equals(testDiary.id));
      expect(updatedDiary.folderId, equals(testDiary.folderId));
      expect(updatedDiary.title, equals('Updated Title'));
      expect(updatedDiary.content, equals('Updated content'));
      expect(updatedDiary.createdAt, equals(testDiary.createdAt));
      expect(updatedDiary.lastModified, isNot(equals(testDiary.lastModified)));
    });
  });

  group('DiaryMediaAttachment Tests', () {
    late DiaryMediaAttachment testAttachment;

    setUp(() {
      testAttachment = DiaryMediaAttachment(
        id: 'attachment-id',
        type: 'image',
        url: 'https://example.com/image.jpg',
        caption: 'Test caption',
        position: 0,
      );
    });

    test('should create DiaryMediaAttachment with all properties', () {
      expect(testAttachment.id, equals('attachment-id'));
      expect(testAttachment.type, equals('image'));
      expect(testAttachment.url, equals('https://example.com/image.jpg'));
      expect(testAttachment.caption, equals('Test caption'));
      expect(testAttachment.position, equals(0));
    });

    test('should serialize to Map correctly', () {
      final map = testAttachment.toMap();

      expect(map['id'], equals('attachment-id'));
      expect(map['type'], equals('image'));
      expect(map['url'], equals('https://example.com/image.jpg'));
      expect(map['caption'], equals('Test caption'));
      expect(map['position'], equals(0));
    });

    test('should deserialize from Map correctly', () {
      final map = {
        'id': 'attachment-id',
        'type': 'image',
        'url': 'https://example.com/image.jpg',
        'caption': 'Test caption',
        'position': 0,
      };

      final attachment = DiaryMediaAttachment.fromMap(map);

      expect(attachment.id, equals('attachment-id'));
      expect(attachment.type, equals('image'));
      expect(attachment.url, equals('https://example.com/image.jpg'));
      expect(attachment.caption, equals('Test caption'));
      expect(attachment.position, equals(0));
    });

    test('should handle null caption', () {
      final attachmentWithoutCaption = DiaryMediaAttachment(
        id: 'no-caption-id',
        type: 'audio',
        url: 'https://example.com/audio.mp3',
        position: 1,
      );

      expect(attachmentWithoutCaption.caption, isNull);
    });

    test('should support different media types', () {
      final imageAttachment = DiaryMediaAttachment(
        id: 'img-1',
        type: 'image',
        url: 'https://example.com/image.jpg',
        position: 0,
      );

      final videoAttachment = DiaryMediaAttachment(
        id: 'vid-1',
        type: 'video',
        url: 'https://example.com/video.mp4',
        position: 1,
      );

      final audioAttachment = DiaryMediaAttachment(
        id: 'aud-1',
        type: 'audio',
        url: 'https://example.com/audio.mp3',
        position: 2,
      );

      expect(imageAttachment.type, equals('image'));
      expect(videoAttachment.type, equals('video'));
      expect(audioAttachment.type, equals('audio'));
    });

    test('should maintain position ordering', () {
      final attachments = [
        DiaryMediaAttachment(id: '3', type: 'image', url: 'url3', position: 2),
        DiaryMediaAttachment(id: '1', type: 'image', url: 'url1', position: 0),
        DiaryMediaAttachment(id: '2', type: 'image', url: 'url2', position: 1),
      ];

      attachments.sort((a, b) => a.position.compareTo(b.position));

      expect(attachments[0].id, equals('1'));
      expect(attachments[1].id, equals('2'));
      expect(attachments[2].id, equals('3'));
    });
  });
}