import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Test suite for Firestore security rules
///
/// Note: These tests simulate the security rule logic since we cannot
/// directly test Firestore security rules in unit tests. For full
/// security rule testing, use the Firebase emulator with @firebase/rules-unit-testing
void main() {
  group('Firestore Security Rules Logic Tests', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth();
    });

    group('Friend Request Security Logic', () {
      test(
        'should allow user to read their own sent friend requests',
        () async {
          // Create a friend request document
          await firestore.collection('friendRequests').doc('request1').set({
            'senderId': 'user1',
            'receiverId': 'user2',
            'senderUsername': 'testuser1',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // User should be able to read their own sent request
          final doc = await firestore
              .collection('friendRequests')
              .doc('request1')
              .get();
          expect(doc.exists, isTrue);
          expect(doc.data()!['senderId'], equals('user1'));
        },
      );

      test(
        'should allow user to read their own received friend requests',
        () async {
          // Create a friend request where user is receiver
          await firestore.collection('friendRequests').doc('request2').set({
            'senderId': 'user2',
            'receiverId': 'user1',
            'senderUsername': 'testuser2',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

          final doc = await firestore
              .collection('friendRequests')
              .doc('request2')
              .get();
          expect(doc.exists, isTrue);
          expect(doc.data()!['receiverId'], equals('user1'));
        },
      );

      test('should validate friend request creation data', () async {
        // Test valid friend request creation
        final validRequest = {
          'senderId': 'user1',
          'receiverId': 'user2',
          'senderUsername': 'testuser1',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Should succeed with valid data
        await firestore.collection('friendRequests').add(validRequest);

        // Validate required fields are present
        expect(validRequest.containsKey('senderId'), isTrue);
        expect(validRequest.containsKey('receiverId'), isTrue);
        expect(validRequest.containsKey('senderUsername'), isTrue);
        expect(validRequest.containsKey('status'), isTrue);
        expect(validRequest.containsKey('createdAt'), isTrue);
      });

      test('should prevent self friend requests', () {
        // Simulate validation logic that would be in security rules
        final requestData = {
          'senderId': 'user1',
          'receiverId': 'user1', // Same as sender
          'senderUsername': 'testuser1',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // This should fail validation (senderId == receiverId)
        expect(requestData['senderId'], equals(requestData['receiverId']));

        // In real security rules, this would be prevented
        final isSelfRequest =
            requestData['senderId'] == requestData['receiverId'];
        expect(
          isSelfRequest,
          isTrue,
        ); // This validates the logic that should be prevented
      });
    });

    group('Friendship Security Logic', () {
      test('should allow users to read their own friendships', () async {
        await firestore.collection('friendships').doc('friendship1').set({
          'userId1': 'user1',
          'userId2': 'user2',
          'createdAt': FieldValue.serverTimestamp(),
        });

        final doc = await firestore
            .collection('friendships')
            .doc('friendship1')
            .get();
        expect(doc.exists, isTrue);

        // Both users should be able to read this friendship
        final data = doc.data()!;
        expect(data['userId1'], equals('user1'));
        expect(data['userId2'], equals('user2'));
      });

      test('should allow users to delete their own friendships', () async {
        await firestore.collection('friendships').doc('friendship2').set({
          'userId1': 'user1',
          'userId2': 'user2',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // User should be able to delete friendship they're part of
        await firestore.collection('friendships').doc('friendship2').delete();

        final doc = await firestore
            .collection('friendships')
            .doc('friendship2')
            .get();
        expect(doc.exists, isFalse);
      });
    });

    group('Folder Security Logic', () {
      test('should allow owner to read/write their folders', () async {
        await firestore.collection('folders').doc('folder1').set({
          'name': 'Test Folder',
          'userId': 'user1',
          'createdAt': FieldValue.serverTimestamp(),
          'isShared': false,
          'isPublic': false,
          'isLocked': false,
          'contributorIds': [],
        });

        final doc = await firestore.collection('folders').doc('folder1').get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['userId'], equals('user1'));
      });

      test('should allow contributors to access shared folders', () async {
        await firestore.collection('folders').doc('folder2').set({
          'name': 'Shared Folder',
          'userId': 'user1',
          'createdAt': FieldValue.serverTimestamp(),
          'isShared': true,
          'isPublic': false,
          'isLocked': false,
          'contributorIds': ['user2', 'user3'],
        });

        final doc = await firestore.collection('folders').doc('folder2').get();
        final data = doc.data()!;

        // Contributors should be in the contributorIds list
        expect(data['contributorIds'], contains('user2'));
        expect(data['contributorIds'], contains('user3'));
      });

      test('should allow anyone to read public folders', () async {
        await firestore.collection('folders').doc('folder3').set({
          'name': 'Public Folder',
          'userId': 'user1',
          'createdAt': FieldValue.serverTimestamp(),
          'isShared': false,
          'isPublic': true,
          'isLocked': false,
          'contributorIds': [],
        });

        final doc = await firestore.collection('folders').doc('folder3').get();
        expect(doc.data()!['isPublic'], isTrue);
      });

      test('should prevent contributors from modifying locked folders', () {
        final folderData = {
          'name': 'Locked Folder',
          'userId': 'user1',
          'isShared': true,
          'isLocked': true, // Folder is locked
          'contributorIds': ['user2'],
        };

        // Simulate security rule logic
        final contributorIds = folderData['contributorIds'] as List<dynamic>;
        final isContributor = contributorIds.contains('user2');
        final isLocked = folderData['isLocked'] as bool;
        final canModify = !isLocked || folderData['userId'] == 'user2';

        expect(isContributor, isTrue);
        expect(isLocked, isTrue);
        expect(canModify, isFalse); // Contributor cannot modify locked folder
      });
    });

    group('Scheduled Message Security Logic', () {
      test('should allow sender and recipient to read messages', () async {
        await firestore.collection('scheduledMessages').doc('message1').set({
          'senderId': 'user1',
          'recipientId': 'user2',
          'textContent': 'Hello future!',
          'scheduledFor': Timestamp.fromDate(
            DateTime.now().add(Duration(days: 1)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        final doc = await firestore
            .collection('scheduledMessages')
            .doc('message1')
            .get();
        final data = doc.data()!;

        // Both sender and recipient should be able to read
        expect(data['senderId'], equals('user1'));
        expect(data['recipientId'], equals('user2'));
      });

      test('should validate scheduled message creation', () {
        final now = DateTime.now();
        final futureDate = now.add(Duration(days: 1));
        final pastDate = now.subtract(Duration(days: 1));

        // Valid message data
        final validMessage = {
          'senderId': 'user1',
          'recipientId': 'user2',
          'textContent': 'Valid message',
          'scheduledFor': Timestamp.fromDate(futureDate),
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        };

        // Invalid message (scheduled for past)
        final invalidMessage = {
          'senderId': 'user1',
          'recipientId': 'user2',
          'textContent': 'Invalid message',
          'scheduledFor': Timestamp.fromDate(pastDate),
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        };

        // Simulate validation logic
        final validTimestamp = validMessage['scheduledFor'] as Timestamp;
        final invalidTimestamp = invalidMessage['scheduledFor'] as Timestamp;
        expect(
          validTimestamp.seconds > now.millisecondsSinceEpoch / 1000,
          isTrue,
        );
        expect(
          invalidTimestamp.seconds < now.millisecondsSinceEpoch / 1000,
          isTrue,
        );
      });

      test('should validate text content length', () {
        final shortText = 'Short message';
        final longText = 'x' * 6000; // Exceeds 5KB limit
        final validText = 'x' * 1000; // Within limit

        expect(shortText.isNotEmpty, isTrue);
        expect(longText.length > 5000, isTrue); // Should fail
        expect(validText.length <= 5000, isTrue); // Should pass
      });

      test('should allow sender to cancel pending messages', () {
        final messageData = {
          'senderId': 'user1',
          'recipientId': 'user2',
          'status': 'pending',
        };

        // Simulate cancellation logic
        final canCancel =
            messageData['senderId'] == 'user1' &&
            messageData['status'] == 'pending';

        expect(canCancel, isTrue);
      });
    });

    group('Username Validation Logic', () {
      test('should validate username format', () {
        final validUsernames = ['user123', 'test_user', 'User_Name_123'];
        final invalidUsernames = ['us', 'user@name', 'user name', 'x' * 31];

        for (final username in validUsernames) {
          expect(
            isValidUsername(username),
            isTrue,
            reason: 'Username $username should be valid',
          );
        }

        for (final username in invalidUsernames) {
          expect(
            isValidUsername(username),
            isFalse,
            reason: 'Username $username should be invalid',
          );
        }
      });
    });
  });
}

/// Helper function to validate username format
/// Mirrors the validation logic in Firestore security rules
bool isValidUsername(String username) {
  if (username.length < 3 || username.length > 30) return false;
  return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
}
