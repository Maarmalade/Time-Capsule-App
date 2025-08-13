import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_capsule/models/user_profile.dart';

// Generate mocks
@GenerateMocks([DocumentSnapshot])
import 'user_profile_test.mocks.dart';

void main() {
  group('UserProfile', () {
    late DateTime testDate;
    late UserProfile testProfile;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      testProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: 'https://example.com/profile.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    group('constructor', () {
      test('should create UserProfile with all fields', () {
        expect(testProfile.id, equals('test-id'));
        expect(testProfile.email, equals('test@example.com'));
        expect(testProfile.username, equals('testuser'));
        expect(testProfile.profilePictureUrl, equals('https://example.com/profile.jpg'));
        expect(testProfile.createdAt, equals(testDate));
        expect(testProfile.updatedAt, equals(testDate));
      });

      test('should create UserProfile with null profile picture', () {
        final profile = UserProfile(
          id: 'test-id',
          email: 'test@example.com',
          username: 'testuser',
          profilePictureUrl: null,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(profile.profilePictureUrl, isNull);
      });
    });

    group('fromFirestore', () {
      test('should create UserProfile from Firestore document', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'email': 'test@example.com',
          'username': 'testuser',
          'profilePictureUrl': 'https://example.com/profile.jpg',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-id');
        when(mockDoc.data()).thenReturn(data);

        final profile = UserProfile.fromFirestore(mockDoc);

        expect(profile.id, equals('test-id'));
        expect(profile.email, equals('test@example.com'));
        expect(profile.username, equals('testuser'));
        expect(profile.profilePictureUrl, equals('https://example.com/profile.jpg'));
        expect(profile.createdAt, equals(testDate));
        expect(profile.updatedAt, equals(testDate));
      });

      test('should handle null profile picture URL', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'email': 'test@example.com',
          'username': 'testuser',
          'profilePictureUrl': null,
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-id');
        when(mockDoc.data()).thenReturn(data);

        final profile = UserProfile.fromFirestore(mockDoc);

        expect(profile.profilePictureUrl, isNull);
      });

      test('should handle missing fields with defaults', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-id');
        when(mockDoc.data()).thenReturn(data);

        final profile = UserProfile.fromFirestore(mockDoc);

        expect(profile.id, equals('test-id'));
        expect(profile.email, equals(''));
        expect(profile.username, equals(''));
        expect(profile.profilePictureUrl, isNull);
      });
    });

    group('toFirestore', () {
      test('should convert UserProfile to Firestore map', () {
        final firestoreData = testProfile.toFirestore();

        expect(firestoreData['email'], equals('test@example.com'));
        expect(firestoreData['username'], equals('testuser'));
        expect(firestoreData['profilePictureUrl'], equals('https://example.com/profile.jpg'));
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));
        expect((firestoreData['updatedAt'] as Timestamp).toDate(), equals(testDate));
      });

      test('should handle null profile picture URL', () {
        final profile = UserProfile(
          id: testProfile.id,
          email: testProfile.email,
          username: testProfile.username,
          profilePictureUrl: null,
          createdAt: testProfile.createdAt,
          updatedAt: testProfile.updatedAt,
        );
        final firestoreData = profile.toFirestore();

        expect(firestoreData['profilePictureUrl'], isNull);
      });

      test('should not include id in Firestore data', () {
        final firestoreData = testProfile.toFirestore();

        expect(firestoreData.containsKey('id'), isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedProfile = testProfile.copyWith(
          username: 'newusername',
          email: 'new@example.com',
        );

        expect(updatedProfile.id, equals(testProfile.id));
        expect(updatedProfile.username, equals('newusername'));
        expect(updatedProfile.email, equals('new@example.com'));
        expect(updatedProfile.profilePictureUrl, equals(testProfile.profilePictureUrl));
        expect(updatedProfile.createdAt, equals(testProfile.createdAt));
        expect(updatedProfile.updatedAt, equals(testProfile.updatedAt));
      });

      test('should create copy with null profile picture', () {
        final profileWithNull = UserProfile(
          id: testProfile.id,
          email: testProfile.email,
          username: testProfile.username,
          profilePictureUrl: null,
          createdAt: testProfile.createdAt,
          updatedAt: testProfile.updatedAt,
        );

        expect(profileWithNull.profilePictureUrl, isNull);
      });

      test('should create identical copy when no parameters provided', () {
        final copiedProfile = testProfile.copyWith();

        expect(copiedProfile.id, equals(testProfile.id));
        expect(copiedProfile.email, equals(testProfile.email));
        expect(copiedProfile.username, equals(testProfile.username));
        expect(copiedProfile.profilePictureUrl, equals(testProfile.profilePictureUrl));
        expect(copiedProfile.createdAt, equals(testProfile.createdAt));
        expect(copiedProfile.updatedAt, equals(testProfile.updatedAt));
      });

      test('should update all fields when all parameters provided', () {
        final newDate = DateTime(2024, 2, 1, 12, 0, 0);
        final updatedProfile = testProfile.copyWith(
          id: 'new-id',
          email: 'new@example.com',
          username: 'newusername',
          profilePictureUrl: 'https://example.com/new-profile.jpg',
          createdAt: newDate,
          updatedAt: newDate,
        );

        expect(updatedProfile.id, equals('new-id'));
        expect(updatedProfile.email, equals('new@example.com'));
        expect(updatedProfile.username, equals('newusername'));
        expect(updatedProfile.profilePictureUrl, equals('https://example.com/new-profile.jpg'));
        expect(updatedProfile.createdAt, equals(newDate));
        expect(updatedProfile.updatedAt, equals(newDate));
      });
    });

    group('toString', () {
      test('should return string representation of UserProfile', () {
        final stringRepresentation = testProfile.toString();

        expect(stringRepresentation, contains('UserProfile'));
        expect(stringRepresentation, contains('test-id'));
        expect(stringRepresentation, contains('test@example.com'));
        expect(stringRepresentation, contains('testuser'));
        expect(stringRepresentation, contains('https://example.com/profile.jpg'));
      });

      test('should handle null profile picture in string representation', () {
        final profile = UserProfile(
          id: testProfile.id,
          email: testProfile.email,
          username: testProfile.username,
          profilePictureUrl: null,
          createdAt: testProfile.createdAt,
          updatedAt: testProfile.updatedAt,
        );
        final stringRepresentation = profile.toString();

        expect(stringRepresentation, contains('profilePictureUrl: null'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final profile1 = UserProfile(
          id: 'test-id',
          email: 'test@example.com',
          username: 'testuser',
          profilePictureUrl: 'https://example.com/profile.jpg',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final profile2 = UserProfile(
          id: 'test-id',
          email: 'test@example.com',
          username: 'testuser',
          profilePictureUrl: 'https://example.com/profile.jpg',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(profile1, equals(profile2));
        expect(profile1.hashCode, equals(profile2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final profile1 = testProfile;
        final profile2 = testProfile.copyWith(username: 'differentuser');

        expect(profile1, isNot(equals(profile2)));
        expect(profile1.hashCode, isNot(equals(profile2.hashCode)));
      });

      test('should be equal to itself', () {
        expect(testProfile, equals(testProfile));
      });

      test('should not be equal to null', () {
        expect(testProfile, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        expect(testProfile, isNot(equals('string')));
      });

      test('should handle null profile picture URLs in equality', () {
        final profile1 = UserProfile(
          id: testProfile.id,
          email: testProfile.email,
          username: testProfile.username,
          profilePictureUrl: null,
          createdAt: testProfile.createdAt,
          updatedAt: testProfile.updatedAt,
        );
        final profile2 = UserProfile(
          id: testProfile.id,
          email: testProfile.email,
          username: testProfile.username,
          profilePictureUrl: null,
          createdAt: testProfile.createdAt,
          updatedAt: testProfile.updatedAt,
        );

        expect(profile1, equals(profile2));
      });

      test('should not be equal when one has null profile picture and other does not', () {
        final profile1 = testProfile;
        final profile2 = UserProfile(
          id: testProfile.id,
          email: testProfile.email,
          username: testProfile.username,
          profilePictureUrl: null,
          createdAt: testProfile.createdAt,
          updatedAt: testProfile.updatedAt,
        );

        expect(profile1, isNot(equals(profile2)));
      });
    });

    group('edge cases', () {
      test('should handle empty strings', () {
        final profile = UserProfile(
          id: '',
          email: '',
          username: '',
          profilePictureUrl: '',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(profile.id, equals(''));
        expect(profile.email, equals(''));
        expect(profile.username, equals(''));
        expect(profile.profilePictureUrl, equals(''));
      });

      test('should handle very long strings', () {
        final longString = 'a' * 100;
        final profile = UserProfile(
          id: longString,
          email: '${longString}@example.com',
          username: longString,
          profilePictureUrl: 'https://example.com/${longString}.jpg',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(profile.id, equals(longString));
        expect(profile.email, equals('${longString}@example.com'));
        expect(profile.username, equals(longString));
        expect(profile.profilePictureUrl, equals('https://example.com/${longString}.jpg'));
      });

      test('should handle special characters in strings', () {
        final profile = UserProfile(
          id: 'test-id-with-special-chars',
          email: 'test+special@example.com',
          username: 'user_name-123',
          profilePictureUrl: 'https://example.com/profile-pic_123.jpg?v=1',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(profile.id, equals('test-id-with-special-chars'));
        expect(profile.email, equals('test+special@example.com'));
        expect(profile.username, equals('user_name-123'));
        expect(profile.profilePictureUrl, equals('https://example.com/profile-pic_123.jpg?v=1'));
      });
    });
  });
}