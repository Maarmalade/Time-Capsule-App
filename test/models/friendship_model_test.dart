import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_capsule/models/friendship_model.dart';

// Generate mocks
@GenerateMocks([DocumentSnapshot])
import 'friendship_model_test.mocks.dart';

void main() {
  group('Friendship', () {
    late DateTime testDate;
    late Friendship testFriendship;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      testFriendship = Friendship(
        id: 'test-friendship-id',
        userId1: 'user-1',
        userId2: 'user-2',
        createdAt: testDate,
      );
    });

    group('constructor', () {
      test('should create Friendship with all fields', () {
        expect(testFriendship.id, equals('test-friendship-id'));
        expect(testFriendship.userId1, equals('user-1'));
        expect(testFriendship.userId2, equals('user-2'));
        expect(testFriendship.createdAt, equals(testDate));
      });
    });

    group('fromFirestore', () {
      test('should create Friendship from Firestore document', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'userId1': 'user-1',
          'userId2': 'user-2',
          'createdAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-friendship-id');
        when(mockDoc.data()).thenReturn(data);

        final friendship = Friendship.fromFirestore(mockDoc);

        expect(friendship.id, equals('test-friendship-id'));
        expect(friendship.userId1, equals('user-1'));
        expect(friendship.userId2, equals('user-2'));
        expect(friendship.createdAt, equals(testDate));
      });

      test('should handle missing fields with defaults', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'createdAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-friendship-id');
        when(mockDoc.data()).thenReturn(data);

        final friendship = Friendship.fromFirestore(mockDoc);

        expect(friendship.userId1, equals(''));
        expect(friendship.userId2, equals(''));
        expect(friendship.createdAt, equals(testDate));
      });
    });

    group('toFirestore', () {
      test('should convert Friendship to Firestore map', () {
        final firestoreData = testFriendship.toFirestore();

        expect(firestoreData['userId1'], equals('user-1'));
        expect(firestoreData['userId2'], equals('user-2'));
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));
      });

      test('should not include id in Firestore data', () {
        final firestoreData = testFriendship.toFirestore();

        expect(firestoreData.containsKey('id'), isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final newDate = DateTime(2024, 2, 1, 12, 0, 0);
        final updatedFriendship = testFriendship.copyWith(
          userId1: 'new-user-1',
          createdAt: newDate,
        );

        expect(updatedFriendship.id, equals(testFriendship.id));
        expect(updatedFriendship.userId1, equals('new-user-1'));
        expect(updatedFriendship.userId2, equals(testFriendship.userId2));
        expect(updatedFriendship.createdAt, equals(newDate));
      });

      test('should create identical copy when no parameters provided', () {
        final copiedFriendship = testFriendship.copyWith();

        expect(copiedFriendship.id, equals(testFriendship.id));
        expect(copiedFriendship.userId1, equals(testFriendship.userId1));
        expect(copiedFriendship.userId2, equals(testFriendship.userId2));
        expect(copiedFriendship.createdAt, equals(testFriendship.createdAt));
      });
    });

    group('bidirectional relationship methods', () {
      test('involves should return true when user is userId1', () {
        expect(testFriendship.involves('user-1'), isTrue);
      });

      test('involves should return true when user is userId2', () {
        expect(testFriendship.involves('user-2'), isTrue);
      });

      test('involves should return false when user is not involved', () {
        expect(testFriendship.involves('user-3'), isFalse);
      });

      test('getOtherUserId should return userId2 when given userId1', () {
        expect(testFriendship.getOtherUserId('user-1'), equals('user-2'));
      });

      test('getOtherUserId should return userId1 when given userId2', () {
        expect(testFriendship.getOtherUserId('user-2'), equals('user-1'));
      });

      test('getOtherUserId should throw ArgumentError when user not involved', () {
        expect(
          () => testFriendship.getOtherUserId('user-3'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('createOrdered', () {
      test('should create friendship with ordered user IDs', () {
        final friendship = Friendship.createOrdered(
          id: 'test-id',
          userIdA: 'zebra-user',
          userIdB: 'alpha-user',
          createdAt: testDate,
        );

        expect(friendship.userId1, equals('alpha-user'));
        expect(friendship.userId2, equals('zebra-user'));
      });

      test('should maintain order when already ordered', () {
        final friendship = Friendship.createOrdered(
          id: 'test-id',
          userIdA: 'alpha-user',
          userIdB: 'zebra-user',
          createdAt: testDate,
        );

        expect(friendship.userId1, equals('alpha-user'));
        expect(friendship.userId2, equals('zebra-user'));
      });

      test('should handle identical user IDs', () {
        final friendship = Friendship.createOrdered(
          id: 'test-id',
          userIdA: 'same-user',
          userIdB: 'same-user',
          createdAt: testDate,
        );

        expect(friendship.userId1, equals('same-user'));
        expect(friendship.userId2, equals('same-user'));
      });
    });

    group('validation methods', () {
      test('isValid should return true for valid friendship', () {
        expect(testFriendship.isValid(), isTrue);
      });

      test('isValid should return false for empty userId1', () {
        final friendship = testFriendship.copyWith(userId1: '');
        expect(friendship.isValid(), isFalse);
      });

      test('isValid should return false for empty userId2', () {
        final friendship = testFriendship.copyWith(userId2: '');
        expect(friendship.isValid(), isFalse);
      });

      test('isValid should return false when both users are same', () {
        final friendship = testFriendship.copyWith(userId2: 'user-1');
        expect(friendship.isValid(), isFalse);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final friendship1 = Friendship(
          id: 'test-friendship-id',
          userId1: 'user-1',
          userId2: 'user-2',
          createdAt: testDate,
        );

        final friendship2 = Friendship(
          id: 'test-friendship-id',
          userId1: 'user-1',
          userId2: 'user-2',
          createdAt: testDate,
        );

        expect(friendship1, equals(friendship2));
        expect(friendship1.hashCode, equals(friendship2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final friendship1 = testFriendship;
        final friendship2 = testFriendship.copyWith(userId1: 'different-user');

        expect(friendship1, isNot(equals(friendship2)));
      });

      test('should be equal to itself', () {
        expect(testFriendship, equals(testFriendship));
      });

      test('should not be equal to null', () {
        expect(testFriendship, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        expect(testFriendship, isNot(equals('string')));
      });
    });

    group('toString', () {
      test('should return string representation of Friendship', () {
        final stringRepresentation = testFriendship.toString();

        expect(stringRepresentation, contains('Friendship'));
        expect(stringRepresentation, contains('test-friendship-id'));
        expect(stringRepresentation, contains('user-1'));
        expect(stringRepresentation, contains('user-2'));
      });
    });

    group('edge cases', () {
      test('should handle empty strings', () {
        final friendship = Friendship(
          id: '',
          userId1: '',
          userId2: '',
          createdAt: testDate,
        );

        expect(friendship.id, equals(''));
        expect(friendship.userId1, equals(''));
        expect(friendship.userId2, equals(''));
      });

      test('should handle very long user IDs', () {
        final longId = 'a' * 1000;
        final friendship = Friendship(
          id: longId,
          userId1: longId,
          userId2: '${longId}2',
          createdAt: testDate,
        );

        expect(friendship.id, equals(longId));
        expect(friendship.userId1, equals(longId));
        expect(friendship.userId2, equals('${longId}2'));
      });

      test('should handle special characters in user IDs', () {
        final friendship = Friendship(
          id: 'test-id-with-special-chars',
          userId1: 'user-id-with-special-chars',
          userId2: 'another-user-id_123',
          createdAt: testDate,
        );

        expect(friendship.id, equals('test-id-with-special-chars'));
        expect(friendship.userId1, equals('user-id-with-special-chars'));
        expect(friendship.userId2, equals('another-user-id_123'));
      });
    });
  });
}