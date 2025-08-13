import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_capsule/models/friend_request_model.dart';

// Generate mocks
@GenerateMocks([DocumentSnapshot])
import 'friend_request_model_test.mocks.dart';

void main() {
  group('FriendRequest', () {
    late DateTime testDate;
    late DateTime respondedDate;
    late FriendRequest testFriendRequest;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      respondedDate = DateTime(2024, 1, 2, 12, 0, 0);
      testFriendRequest = FriendRequest(
        id: 'test-request-id',
        senderId: 'sender-id',
        receiverId: 'receiver-id',
        senderUsername: 'senderuser',
        senderProfilePictureUrl: 'https://example.com/sender.jpg',
        status: FriendRequestStatus.pending,
        createdAt: testDate,
        respondedAt: null,
      );
    });

    group('constructor', () {
      test('should create FriendRequest with all fields', () {
        expect(testFriendRequest.id, equals('test-request-id'));
        expect(testFriendRequest.senderId, equals('sender-id'));
        expect(testFriendRequest.receiverId, equals('receiver-id'));
        expect(testFriendRequest.senderUsername, equals('senderuser'));
        expect(testFriendRequest.senderProfilePictureUrl, equals('https://example.com/sender.jpg'));
        expect(testFriendRequest.status, equals(FriendRequestStatus.pending));
        expect(testFriendRequest.createdAt, equals(testDate));
        expect(testFriendRequest.respondedAt, isNull);
      });

      test('should create FriendRequest with null profile picture', () {
        final request = FriendRequest(
          id: 'test-request-id',
          senderId: 'sender-id',
          receiverId: 'receiver-id',
          senderUsername: 'senderuser',
          senderProfilePictureUrl: null,
          status: FriendRequestStatus.pending,
          createdAt: testDate,
        );

        expect(request.senderProfilePictureUrl, isNull);
      });
    });

    group('fromFirestore', () {
      test('should create FriendRequest from Firestore document', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'receiverId': 'receiver-id',
          'senderUsername': 'senderuser',
          'senderProfilePictureUrl': 'https://example.com/sender.jpg',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(testDate),
          'respondedAt': null,
        };

        when(mockDoc.id).thenReturn('test-request-id');
        when(mockDoc.data()).thenReturn(data);

        final request = FriendRequest.fromFirestore(mockDoc);

        expect(request.id, equals('test-request-id'));
        expect(request.senderId, equals('sender-id'));
        expect(request.receiverId, equals('receiver-id'));
        expect(request.senderUsername, equals('senderuser'));
        expect(request.senderProfilePictureUrl, equals('https://example.com/sender.jpg'));
        expect(request.status, equals(FriendRequestStatus.pending));
        expect(request.createdAt, equals(testDate));
        expect(request.respondedAt, isNull);
      });

      test('should handle accepted status', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'receiverId': 'receiver-id',
          'senderUsername': 'senderuser',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(testDate),
          'respondedAt': Timestamp.fromDate(respondedDate),
        };

        when(mockDoc.id).thenReturn('test-request-id');
        when(mockDoc.data()).thenReturn(data);

        final request = FriendRequest.fromFirestore(mockDoc);

        expect(request.status, equals(FriendRequestStatus.accepted));
        expect(request.respondedAt, equals(respondedDate));
      });

      test('should handle declined status', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'receiverId': 'receiver-id',
          'senderUsername': 'senderuser',
          'status': 'declined',
          'createdAt': Timestamp.fromDate(testDate),
          'respondedAt': Timestamp.fromDate(respondedDate),
        };

        when(mockDoc.id).thenReturn('test-request-id');
        when(mockDoc.data()).thenReturn(data);

        final request = FriendRequest.fromFirestore(mockDoc);

        expect(request.status, equals(FriendRequestStatus.declined));
      });

      test('should handle missing fields with defaults', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'createdAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-request-id');
        when(mockDoc.data()).thenReturn(data);

        final request = FriendRequest.fromFirestore(mockDoc);

        expect(request.senderId, equals(''));
        expect(request.receiverId, equals(''));
        expect(request.senderUsername, equals(''));
        expect(request.senderProfilePictureUrl, isNull);
        expect(request.status, equals(FriendRequestStatus.pending));
      });

      test('should handle invalid status with default', () {
        final mockDoc = MockDocumentSnapshot();
        final data = {
          'senderId': 'sender-id',
          'receiverId': 'receiver-id',
          'senderUsername': 'senderuser',
          'status': 'invalid-status',
          'createdAt': Timestamp.fromDate(testDate),
        };

        when(mockDoc.id).thenReturn('test-request-id');
        when(mockDoc.data()).thenReturn(data);

        final request = FriendRequest.fromFirestore(mockDoc);

        expect(request.status, equals(FriendRequestStatus.pending));
      });
    });

    group('toFirestore', () {
      test('should convert FriendRequest to Firestore map', () {
        final firestoreData = testFriendRequest.toFirestore();

        expect(firestoreData['senderId'], equals('sender-id'));
        expect(firestoreData['receiverId'], equals('receiver-id'));
        expect(firestoreData['senderUsername'], equals('senderuser'));
        expect(firestoreData['senderProfilePictureUrl'], equals('https://example.com/sender.jpg'));
        expect(firestoreData['status'], equals('pending'));
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['respondedAt'], isNull);
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));
      });

      test('should handle accepted status with responded date', () {
        final request = testFriendRequest.copyWith(
          status: FriendRequestStatus.accepted,
          respondedAt: respondedDate,
        );
        final firestoreData = request.toFirestore();

        expect(firestoreData['status'], equals('accepted'));
        expect(firestoreData['respondedAt'], isA<Timestamp>());
        expect((firestoreData['respondedAt'] as Timestamp).toDate(), equals(respondedDate));
      });

      test('should not include id in Firestore data', () {
        final firestoreData = testFriendRequest.toFirestore();

        expect(firestoreData.containsKey('id'), isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated status', () {
        final updatedRequest = testFriendRequest.copyWith(
          status: FriendRequestStatus.accepted,
          respondedAt: respondedDate,
        );

        expect(updatedRequest.id, equals(testFriendRequest.id));
        expect(updatedRequest.status, equals(FriendRequestStatus.accepted));
        expect(updatedRequest.respondedAt, equals(respondedDate));
        expect(updatedRequest.senderId, equals(testFriendRequest.senderId));
      });

      test('should create identical copy when no parameters provided', () {
        final copiedRequest = testFriendRequest.copyWith();

        expect(copiedRequest.id, equals(testFriendRequest.id));
        expect(copiedRequest.senderId, equals(testFriendRequest.senderId));
        expect(copiedRequest.receiverId, equals(testFriendRequest.receiverId));
        expect(copiedRequest.status, equals(testFriendRequest.status));
      });
    });

    group('validation methods', () {
      test('isValid should return true for valid request', () {
        expect(testFriendRequest.isValid(), isTrue);
      });

      test('isValid should return false for empty senderId', () {
        final request = testFriendRequest.copyWith(senderId: '');
        expect(request.isValid(), isFalse);
      });

      test('isValid should return false for empty receiverId', () {
        final request = testFriendRequest.copyWith(receiverId: '');
        expect(request.isValid(), isFalse);
      });

      test('isValid should return false for empty senderUsername', () {
        final request = testFriendRequest.copyWith(senderUsername: '');
        expect(request.isValid(), isFalse);
      });

      test('isValid should return false when sender and receiver are same', () {
        final request = testFriendRequest.copyWith(receiverId: 'sender-id');
        expect(request.isValid(), isFalse);
      });

      test('isPending should return true for pending status', () {
        expect(testFriendRequest.isPending(), isTrue);
      });

      test('isAccepted should return true for accepted status', () {
        final request = testFriendRequest.copyWith(status: FriendRequestStatus.accepted);
        expect(request.isAccepted(), isTrue);
      });

      test('isDeclined should return true for declined status', () {
        final request = testFriendRequest.copyWith(status: FriendRequestStatus.declined);
        expect(request.isDeclined(), isTrue);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final request1 = FriendRequest(
          id: 'test-request-id',
          senderId: 'sender-id',
          receiverId: 'receiver-id',
          senderUsername: 'senderuser',
          senderProfilePictureUrl: 'https://example.com/sender.jpg',
          status: FriendRequestStatus.pending,
          createdAt: testDate,
        );

        final request2 = FriendRequest(
          id: 'test-request-id',
          senderId: 'sender-id',
          receiverId: 'receiver-id',
          senderUsername: 'senderuser',
          senderProfilePictureUrl: 'https://example.com/sender.jpg',
          status: FriendRequestStatus.pending,
          createdAt: testDate,
        );

        expect(request1, equals(request2));
        expect(request1.hashCode, equals(request2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final request1 = testFriendRequest;
        final request2 = testFriendRequest.copyWith(status: FriendRequestStatus.accepted);

        expect(request1, isNot(equals(request2)));
      });
    });

    group('toString', () {
      test('should return string representation of FriendRequest', () {
        final stringRepresentation = testFriendRequest.toString();

        expect(stringRepresentation, contains('FriendRequest'));
        expect(stringRepresentation, contains('test-request-id'));
        expect(stringRepresentation, contains('sender-id'));
        expect(stringRepresentation, contains('receiver-id'));
        expect(stringRepresentation, contains('senderuser'));
        expect(stringRepresentation, contains('pending'));
      });
    });
  });

  group('FriendRequestStatus', () {
    test('should have correct enum values', () {
      expect(FriendRequestStatus.values.length, equals(3));
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.pending));
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.accepted));
      expect(FriendRequestStatus.values, contains(FriendRequestStatus.declined));
    });

    test('should have correct string names', () {
      expect(FriendRequestStatus.pending.name, equals('pending'));
      expect(FriendRequestStatus.accepted.name, equals('accepted'));
      expect(FriendRequestStatus.declined.name, equals('declined'));
    });
  });
}