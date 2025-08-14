import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_capsule/services/friend_service.dart';
import 'package:time_capsule/utils/friend_validation_utils.dart';
import 'package:time_capsule/models/friend_request_model.dart';
import 'package:time_capsule/models/friendship_model.dart';

import 'friend_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentReference,
  DocumentSnapshot,
  FirebaseAuth,
  User,
])
void main() {
  group('FriendService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late FriendService friendService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      
      friendService = FriendService(
        firestore: mockFirestore,
        auth: mockAuth,
      );

      // Setup default auth mock
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('current_user_id');
    });

    group('searchUsersByUsername', () {
      setUp(() {
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
      });

      test('should throw exception when user is not logged in', () async {
        when(mockAuth.currentUser).thenReturn(null);

        expect(
          () => friendService.searchUsersByUsername('testuser'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User must be logged in to search for friends'),
          )),
        );
      });

      test('should validate and sanitize search query', () async {
        expect(
          () => friendService.searchUsersByUsername(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Search query cannot be empty'),
          )),
        );

        expect(
          () => friendService.searchUsersByUsername('a'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Search query must be at least 2 characters long'),
          )),
        );
      });

      test('should perform optimized username search with query limits', () async {
        final mockDocs = <MockQueryDocumentSnapshot<Map<String, dynamic>>>[];
        
        // Create mock user documents
        for (int i = 0; i < 3; i++) {
          final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.id).thenReturn('user_$i');
          when(mockDoc.data()).thenReturn({
            'id': 'user_$i',
            'email': 'user$i@example.com',
            'username': 'testuser$i',
            'profilePictureUrl': null,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
          mockDocs.add(mockDoc);
        }

        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Setup query chain
        when(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser'))
            .thenReturn(mockQuery);
        when(mockQuery.where('username', isLessThan: 'testuser\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        final results = await friendService.searchUsersByUsername('TestUser');

        expect(results, hasLength(3));
        expect(results[0].username, equals('testuser0'));
        expect(results[1].username, equals('testuser1'));
        expect(results[2].username, equals('testuser2'));

        // Verify query optimization
        verify(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser')).called(1);
        verify(mockQuery.where('username', isLessThan: 'testuser\uf8ff')).called(1);
        verify(mockQuery.limit(20)).called(1);
      });

      test('should exclude current user from search results', () async {
        final mockDocs = <MockQueryDocumentSnapshot<Map<String, dynamic>>>[];
        
        // Create mock user documents including current user
        final currentUserDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(currentUserDoc.id).thenReturn('current_user_id');
        when(currentUserDoc.data()).thenReturn({
          'id': 'current_user_id',
          'email': 'current@example.com',
          'username': 'testuser',
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        mockDocs.add(currentUserDoc);

        final otherUserDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(otherUserDoc.id).thenReturn('other_user_id');
        when(otherUserDoc.data()).thenReturn({
          'id': 'other_user_id',
          'email': 'other@example.com',
          'username': 'testuser2',
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        mockDocs.add(otherUserDoc);

        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Setup query chain
        when(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser'))
            .thenReturn(mockQuery);
        when(mockQuery.where('username', isLessThan: 'testuser\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        final results = await friendService.searchUsersByUsername('testuser');

        // Should only return the other user, not the current user
        expect(results, hasLength(1));
        expect(results[0].id, equals('other_user_id'));
        expect(results[0].username, equals('testuser2'));
      });

      test('should handle empty search results', () async {
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Setup query chain
        when(mockCollection.where('username', isGreaterThanOrEqualTo: 'nonexistent'))
            .thenReturn(mockQuery);
        when(mockQuery.where('username', isLessThan: 'nonexistent\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        final results = await friendService.searchUsersByUsername('nonexistent');

        expect(results, isEmpty);
      });

      test('should handle Firebase exceptions', () async {
        // Setup query chain
        when(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser'))
            .thenReturn(mockQuery);
        when(mockQuery.where('username', isLessThan: 'testuser\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        expect(
          () => friendService.searchUsersByUsername('testuser'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle general exceptions', () async {
        // Setup query chain
        when(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser'))
            .thenReturn(mockQuery);
        when(mockQuery.where('username', isLessThan: 'testuser\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(Exception('Network error'));

        expect(
          () => friendService.searchUsersByUsername('testuser'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error'),
          )),
        );
      });

      test('should respect maximum search results limit', () async {
        final mockDocs = <MockQueryDocumentSnapshot<Map<String, dynamic>>>[];
        
        // Create 25 mock user documents (more than the limit of 20)
        for (int i = 0; i < 25; i++) {
          final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.id).thenReturn('user_$i');
          when(mockDoc.data()).thenReturn({
            'id': 'user_$i',
            'email': 'user$i@example.com',
            'username': 'testuser$i',
            'profilePictureUrl': null,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
          mockDocs.add(mockDoc);
        }

        // Firestore limit should only return 20 documents
        when(mockQuerySnapshot.docs).thenReturn(mockDocs.take(20).toList());

        // Setup query chain
        when(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser'))
            .thenReturn(mockQuery);
        when(mockQuery.where('username', isLessThan: 'testuser\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        final results = await friendService.searchUsersByUsername('testuser');

        expect(results, hasLength(20));
        verify(mockQuery.limit(20)).called(1);
      });

      test('should handle case insensitive search', () async {
        final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockDoc.id).thenReturn('user_1');
        when(mockDoc.data()).thenReturn({
          'id': 'user_1',
          'email': 'user@example.com',
          'username': 'testuser',
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

        // Setup query chain - should search for lowercase version
        when(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser'))
            .thenReturn(mockQuery);
        when(mockQuery.where('username', isLessThan: 'testuser\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        final results = await friendService.searchUsersByUsername('TESTUSER');

        expect(results, hasLength(1));
        expect(results[0].username, equals('testuser'));

        // Verify that the query was made with lowercase
        verify(mockCollection.where('username', isGreaterThanOrEqualTo: 'testuser')).called(1);
      });
    });

    group('getFriends', () {
      late MockCollectionReference<Map<String, dynamic>> mockFriendshipsCollection;
      late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
      late MockDocumentSnapshot<Map<String, dynamic>> mockUserDoc;

      setUp(() {
        mockFriendshipsCollection = MockCollectionReference<Map<String, dynamic>>();
        mockUsersCollection = MockCollectionReference<Map<String, dynamic>>();
        mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockFirestore.collection('friendships')).thenReturn(mockFriendshipsCollection);
        when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      });

      test('should throw exception when user is not logged in', () async {
        when(mockAuth.currentUser).thenReturn(null);

        expect(
          () => friendService.getFriends(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User must be logged in to view friends'),
          )),
        );
      });

      test('should return empty list when user has no friends', () async {
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        
        when(mockQuerySnapshot1.docs).thenReturn([]);
        when(mockQuerySnapshot2.docs).thenReturn([]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot1);

        when(mockFriendshipsCollection.where('userId2', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot2);

        final friends = await friendService.getFriends();

        expect(friends, isEmpty);
      });

      test('should return friends list when user is userId1 in friendship', () async {
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        final mockQuery2 = MockQuery<Map<String, dynamic>>();
        
        // Create mock friendship document where current user is userId1
        final mockFriendshipDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc.id).thenReturn('friendship_1');
        when(mockFriendshipDoc.data()).thenReturn({
          'id': 'friendship_1',
          'userId1': 'current_user_id',
          'userId2': 'friend_user_id',
          'createdAt': Timestamp.now(),
        });

        when(mockQuerySnapshot1.docs).thenReturn([mockFriendshipDoc]);
        when(mockQuerySnapshot2.docs).thenReturn([]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenAnswer((_) async => mockQuerySnapshot1);

        when(mockFriendshipsCollection.where('userId2', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery2);
        when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot2);

        // Mock user profile retrieval
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockUsersCollection.doc('friend_user_id')).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockUserDoc);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockUserDoc.id).thenReturn('friend_user_id');
        when(mockUserDoc.data()).thenReturn({
          'id': 'friend_user_id',
          'email': 'friend@example.com',
          'username': 'frienduser',
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        final friends = await friendService.getFriends();

        expect(friends, hasLength(1));
        expect(friends[0].id, equals('friend_user_id'));
        expect(friends[0].username, equals('frienduser'));
      });

      test('should return friends list when user is userId2 in friendship', () async {
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        final mockQuery2 = MockQuery<Map<String, dynamic>>();
        
        // Create mock friendship document where current user is userId2
        final mockFriendshipDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc.id).thenReturn('friendship_1');
        when(mockFriendshipDoc.data()).thenReturn({
          'id': 'friendship_1',
          'userId1': 'friend_user_id',
          'userId2': 'current_user_id',
          'createdAt': Timestamp.now(),
        });

        when(mockQuerySnapshot1.docs).thenReturn([]);
        when(mockQuerySnapshot2.docs).thenReturn([mockFriendshipDoc]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenAnswer((_) async => mockQuerySnapshot1);

        when(mockFriendshipsCollection.where('userId2', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery2);
        when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot2);

        // Mock user profile retrieval
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockUsersCollection.doc('friend_user_id')).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockUserDoc);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockUserDoc.id).thenReturn('friend_user_id');
        when(mockUserDoc.data()).thenReturn({
          'id': 'friend_user_id',
          'email': 'friend@example.com',
          'username': 'frienduser',
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        final friends = await friendService.getFriends();

        expect(friends, hasLength(1));
        expect(friends[0].id, equals('friend_user_id'));
        expect(friends[0].username, equals('frienduser'));
      });

      test('should return combined friends list from both directions', () async {
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        final mockQuery2 = MockQuery<Map<String, dynamic>>();
        
        // Create mock friendship documents
        final mockFriendshipDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc1.id).thenReturn('friendship_1');
        when(mockFriendshipDoc1.data()).thenReturn({
          'id': 'friendship_1',
          'userId1': 'current_user_id',
          'userId2': 'friend_1_id',
          'createdAt': Timestamp.now(),
        });

        final mockFriendshipDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc2.id).thenReturn('friendship_2');
        when(mockFriendshipDoc2.data()).thenReturn({
          'id': 'friendship_2',
          'userId1': 'friend_2_id',
          'userId2': 'current_user_id',
          'createdAt': Timestamp.now(),
        });

        when(mockQuerySnapshot1.docs).thenReturn([mockFriendshipDoc1]);
        when(mockQuerySnapshot2.docs).thenReturn([mockFriendshipDoc2]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenAnswer((_) async => mockQuerySnapshot1);

        when(mockFriendshipsCollection.where('userId2', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery2);
        when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot2);

        // Mock user profile retrievals
        final mockDocRef1 = MockDocumentReference<Map<String, dynamic>>();
        final mockDocRef2 = MockDocumentReference<Map<String, dynamic>>();
        final mockUserDoc1 = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserDoc2 = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockUsersCollection.doc('friend_1_id')).thenReturn(mockDocRef1);
        when(mockDocRef1.get()).thenAnswer((_) async => mockUserDoc1);
        when(mockUserDoc1.exists).thenReturn(true);
        when(mockUserDoc1.id).thenReturn('friend_1_id');
        when(mockUserDoc1.data()).thenReturn({
          'id': 'friend_1_id',
          'email': 'friend1@example.com',
          'username': 'zfriend', // Will be sorted after afriend
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        when(mockUsersCollection.doc('friend_2_id')).thenReturn(mockDocRef2);
        when(mockDocRef2.get()).thenAnswer((_) async => mockUserDoc2);
        when(mockUserDoc2.exists).thenReturn(true);
        when(mockUserDoc2.id).thenReturn('friend_2_id');
        when(mockUserDoc2.data()).thenReturn({
          'id': 'friend_2_id',
          'email': 'friend2@example.com',
          'username': 'afriend', // Will be sorted before zfriend
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        final friends = await friendService.getFriends();

        expect(friends, hasLength(2));
        // Should be sorted alphabetically by username
        expect(friends[0].username, equals('afriend'));
        expect(friends[1].username, equals('zfriend'));
      });

      test('should handle missing user profiles gracefully', () async {
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        final mockQuery2 = MockQuery<Map<String, dynamic>>();
        
        final mockFriendshipDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc.id).thenReturn('friendship_1');
        when(mockFriendshipDoc.data()).thenReturn({
          'id': 'friendship_1',
          'userId1': 'current_user_id',
          'userId2': 'deleted_user_id',
          'createdAt': Timestamp.now(),
        });

        when(mockQuerySnapshot1.docs).thenReturn([mockFriendshipDoc]);
        when(mockQuerySnapshot2.docs).thenReturn([]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenAnswer((_) async => mockQuerySnapshot1);

        when(mockFriendshipsCollection.where('userId2', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery2);
        when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot2);

        // Mock user profile retrieval that returns null (user doesn't exist)
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockDeletedUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        when(mockUsersCollection.doc('deleted_user_id')).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDeletedUserDoc);
        when(mockDeletedUserDoc.exists).thenReturn(false);

        final friends = await friendService.getFriends();

        expect(friends, isEmpty); // Should filter out missing profiles
      });

      test('should handle Firebase exceptions', () async {
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        expect(
          () => friendService.getFriends(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('removeFriend', () {
      late MockCollectionReference<Map<String, dynamic>> mockFriendshipsCollection;
      late MockDocumentReference<Map<String, dynamic>> mockDocRef;

      setUp(() {
        mockFriendshipsCollection = MockCollectionReference<Map<String, dynamic>>();
        mockDocRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockFirestore.collection('friendships')).thenReturn(mockFriendshipsCollection);
      });

      test('should throw exception when user is not logged in', () async {
        when(mockAuth.currentUser).thenReturn(null);

        expect(
          () => friendService.removeFriend('friend_id'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User must be logged in to remove friends'),
          )),
        );
      });

      test('should validate friend ID', () async {
        expect(
          () => friendService.removeFriend(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Friend ID cannot be empty'),
          )),
        );
      });

      test('should prevent removing self as friend', () async {
        expect(
          () => friendService.removeFriend('current_user_id'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot send friend request to yourself'),
          )),
        );
      });

      test('should successfully remove friendship when current user is userId1', () async {
        final mockFriendshipDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc.id).thenReturn('friendship_1');
        when(mockFriendshipDoc.data()).thenReturn({
          'id': 'friendship_1',
          'userId1': 'current_user_id',
          'userId2': 'friend_id',
          'createdAt': Timestamp.now(),
        });

        when(mockQuerySnapshot.docs).thenReturn([mockFriendshipDoc]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery);
        when(mockQuery.where('userId2', isEqualTo: 'friend_id'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        when(mockFriendshipsCollection.doc('friendship_1')).thenReturn(mockDocRef);
        when(mockDocRef.delete()).thenAnswer((_) async {});

        final result = await friendService.removeFriend('friend_id');

        expect(result, isTrue);
        verify(mockDocRef.delete()).called(1);
      });

      test('should successfully remove friendship when current user is userId2', () async {
        final mockFriendshipDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc.id).thenReturn('friendship_1');
        when(mockFriendshipDoc.data()).thenReturn({
          'id': 'friendship_1',
          'userId1': 'friend_id',
          'userId2': 'current_user_id',
          'createdAt': Timestamp.now(),
        });

        when(mockQuerySnapshot.docs).thenReturn([mockFriendshipDoc]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery);
        when(mockQuery.where('userId2', isEqualTo: 'friend_id'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        when(mockFriendshipsCollection.doc('friendship_1')).thenReturn(mockDocRef);
        when(mockDocRef.delete()).thenAnswer((_) async {});

        final result = await friendService.removeFriend('friend_id');

        expect(result, isTrue);
        verify(mockDocRef.delete()).called(1);
      });

      test('should throw exception when friendship not found', () async {
        when(mockQuerySnapshot.docs).thenReturn([]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery);
        when(mockQuery.where('userId2', isEqualTo: 'friend_id'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        expect(
          () => friendService.removeFriend('friend_id'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Friendship not found'),
          )),
        );
      });

      test('should handle Firebase exceptions', () async {
        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery);
        when(mockQuery.where('userId2', isEqualTo: 'friend_id'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        expect(
          () => friendService.removeFriend('friend_id'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('areFriends', () {
      late MockCollectionReference<Map<String, dynamic>> mockFriendshipsCollection;

      setUp(() {
        mockFriendshipsCollection = MockCollectionReference<Map<String, dynamic>>();
        when(mockFirestore.collection('friendships')).thenReturn(mockFriendshipsCollection);
      });

      test('should validate user IDs', () async {
        expect(
          () => friendService.areFriends('', 'user2'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID 1 cannot be empty'),
          )),
        );

        expect(
          () => friendService.areFriends('user1', ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID 2 cannot be empty'),
          )),
        );
      });

      test('should return false for same user ID', () async {
        final result = await friendService.areFriends('same_user', 'same_user');
        expect(result, isFalse);
      });

      test('should return true when friendship exists', () async {
        final mockFriendshipDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockFriendshipDoc.id).thenReturn('friendship_1');

        when(mockQuerySnapshot.docs).thenReturn([mockFriendshipDoc]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'user_a'))
            .thenReturn(mockQuery);
        when(mockQuery.where('userId2', isEqualTo: 'user_b'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        final result = await friendService.areFriends('user_b', 'user_a'); // Order should be normalized
        expect(result, isTrue);
      });

      test('should return false when friendship does not exist', () async {
        when(mockQuerySnapshot.docs).thenReturn([]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'user_a'))
            .thenReturn(mockQuery);
        when(mockQuery.where('userId2', isEqualTo: 'user_b'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        final result = await friendService.areFriends('user_a', 'user_b');
        expect(result, isFalse);
      });

      test('should handle Firebase exceptions', () async {
        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'user_a'))
            .thenReturn(mockQuery);
        when(mockQuery.where('userId2', isEqualTo: 'user_b'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        expect(
          () => friendService.areFriends('user_a', 'user_b'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getFriendsCount', () {
      late MockCollectionReference<Map<String, dynamic>> mockFriendshipsCollection;

      setUp(() {
        mockFriendshipsCollection = MockCollectionReference<Map<String, dynamic>>();
        when(mockFirestore.collection('friendships')).thenReturn(mockFriendshipsCollection);
      });

      test('should throw exception when user is not logged in', () async {
        when(mockAuth.currentUser).thenReturn(null);

        expect(
          () => friendService.getFriendsCount(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User must be logged in to get friends count'),
          )),
        );
      });

      test('should return zero when user has no friends', () async {
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        final mockQuery2 = MockQuery<Map<String, dynamic>>();
        
        when(mockQuerySnapshot1.docs).thenReturn([]);
        when(mockQuerySnapshot2.docs).thenReturn([]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenAnswer((_) async => mockQuerySnapshot1);

        when(mockFriendshipsCollection.where('userId2', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery2);
        when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot2);

        final count = await friendService.getFriendsCount();
        expect(count, equals(0));
      });

      test('should return correct count when user has friends in both directions', () async {
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        final mockQuery2 = MockQuery<Map<String, dynamic>>();
        
        // Create mock documents for userId1 direction
        final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQuerySnapshot1.docs).thenReturn([mockDoc1, mockDoc2]);

        // Create mock documents for userId2 direction
        final mockDoc3 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQuerySnapshot2.docs).thenReturn([mockDoc3]);

        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenAnswer((_) async => mockQuerySnapshot1);

        when(mockFriendshipsCollection.where('userId2', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery2);
        when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot2);

        final count = await friendService.getFriendsCount();
        expect(count, equals(3)); // 2 + 1 = 3 friends total
      });

      test('should handle Firebase exceptions', () async {
        final mockQuery1 = MockQuery<Map<String, dynamic>>();
        when(mockFriendshipsCollection.where('userId1', isEqualTo: 'current_user_id'))
            .thenReturn(mockQuery1);
        when(mockQuery1.get()).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        expect(
          () => friendService.getFriendsCount(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
  group('FriendValidationUtils', () {
    group('validateAndSanitizeSearchQuery', () {
      test('should validate empty query', () {
        expect(
          () => FriendValidationUtils.validateAndSanitizeSearchQuery(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Search query cannot be empty'),
          )),
        );
      });

      test('should validate query length minimum', () {
        expect(
          () => FriendValidationUtils.validateAndSanitizeSearchQuery('a'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Search query must be at least 2 characters long'),
          )),
        );
      });

      test('should validate query length maximum', () {
        final longQuery = 'a' * 25; // Exceeds max username length
        expect(
          () => FriendValidationUtils.validateAndSanitizeSearchQuery(longQuery),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Search query is too long'),
          )),
        );
      });

      test('should reject unsafe query content', () {
        const unsafeQuery = '<script>';
        expect(
          () => FriendValidationUtils.validateAndSanitizeSearchQuery(unsafeQuery),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid search query'),
          )),
        );
      });

      test('should sanitize and convert to lowercase', () {
        const query = '  TestUser  ';
        final result = FriendValidationUtils.validateAndSanitizeSearchQuery(query);
        expect(result, equals('testuser'));
      });

      test('should handle valid username characters', () {
        const query = 'user_123';
        final result = FriendValidationUtils.validateAndSanitizeSearchQuery(query);
        expect(result, equals('user_123'));
      });

      test('should trim whitespace', () {
        const query = '  valid_user  ';
        final result = FriendValidationUtils.validateAndSanitizeSearchQuery(query);
        expect(result, equals('valid_user'));
      });
    });

    group('validateUserId', () {
      test('should reject null user ID', () {
        expect(
          () => FriendValidationUtils.validateUserId(null, 'User ID'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID cannot be empty'),
          )),
        );
      });

      test('should reject empty user ID', () {
        expect(
          () => FriendValidationUtils.validateUserId('', 'User ID'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID cannot be empty'),
          )),
        );
      });

      test('should reject overly long user ID', () {
        final longId = 'a' * 129;
        expect(
          () => FriendValidationUtils.validateUserId(longId, 'User ID'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID is invalid'),
          )),
        );
      });

      test('should accept valid user ID', () {
        const validId = 'valid_user_id_123';
        expect(
          () => FriendValidationUtils.validateUserId(validId, 'User ID'),
          returnsNormally,
        );
      });
    });

    group('validateDifferentUsers', () {
      test('should reject same user IDs', () {
        const userId = 'same_user_id';
        expect(
          () => FriendValidationUtils.validateDifferentUsers(userId, userId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot send friend request to yourself'),
          )),
        );
      });

      test('should accept different user IDs', () {
        const senderId = 'sender_id';
        const receiverId = 'receiver_id';
        expect(
          () => FriendValidationUtils.validateDifferentUsers(senderId, receiverId),
          returnsNormally,
        );
      });
    });
  });

  group('FriendRequest Model Integration', () {
    test('should create valid friend request with required fields', () {
      final now = DateTime.now();
      final friendRequest = FriendRequest(
        id: 'test_id',
        senderId: 'sender_123',
        receiverId: 'receiver_456',
        senderUsername: 'testuser',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: now,
        respondedAt: null,
      );

      expect(friendRequest.isValid(), isTrue);
      expect(friendRequest.isPending(), isTrue);
      expect(friendRequest.isAccepted(), isFalse);
      expect(friendRequest.isDeclined(), isFalse);
    });

    test('should validate friend request with same sender and receiver', () {
      final now = DateTime.now();
      final friendRequest = FriendRequest(
        id: 'test_id',
        senderId: 'same_user',
        receiverId: 'same_user',
        senderUsername: 'testuser',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: now,
        respondedAt: null,
      );

      expect(friendRequest.isValid(), isFalse);
    });

    test('should handle friend request status changes', () {
      final now = DateTime.now();
      final friendRequest = FriendRequest(
        id: 'test_id',
        senderId: 'sender_123',
        receiverId: 'receiver_456',
        senderUsername: 'testuser',
        senderProfilePictureUrl: null,
        status: FriendRequestStatus.pending,
        createdAt: now,
        respondedAt: null,
      );

      // Test accepted status
      final acceptedRequest = friendRequest.copyWith(
        status: FriendRequestStatus.accepted,
        respondedAt: DateTime.now(),
      );
      expect(acceptedRequest.isAccepted(), isTrue);
      expect(acceptedRequest.isPending(), isFalse);

      // Test declined status
      final declinedRequest = friendRequest.copyWith(
        status: FriendRequestStatus.declined,
        respondedAt: DateTime.now(),
      );
      expect(declinedRequest.isDeclined(), isTrue);
      expect(declinedRequest.isPending(), isFalse);
    });
  });

  group('Friendship Model Integration', () {
    test('should create valid friendship with ordered user IDs', () {
      final now = DateTime.now();
      final friendship = Friendship.createOrdered(
        id: 'test_id',
        userIdA: 'user_z',
        userIdB: 'user_a',
        createdAt: now,
      );

      expect(friendship.isValid(), isTrue);
      expect(friendship.userId1, equals('user_a')); // Should be alphabetically first
      expect(friendship.userId2, equals('user_z')); // Should be alphabetically second
    });

    test('should validate friendship with same user IDs', () {
      final now = DateTime.now();
      final friendship = Friendship(
        id: 'test_id',
        userId1: 'same_user',
        userId2: 'same_user',
        createdAt: now,
      );

      expect(friendship.isValid(), isFalse);
    });

    test('should handle bidirectional relationship queries', () {
      final now = DateTime.now();
      final friendship = Friendship(
        id: 'test_id',
        userId1: 'user_a',
        userId2: 'user_b',
        createdAt: now,
      );

      expect(friendship.involves('user_a'), isTrue);
      expect(friendship.involves('user_b'), isTrue);
      expect(friendship.involves('user_c'), isFalse);

      expect(friendship.getOtherUserId('user_a'), equals('user_b'));
      expect(friendship.getOtherUserId('user_b'), equals('user_a'));
      
      expect(
        () => friendship.getOtherUserId('user_c'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle friendship serialization', () {
      final now = DateTime.now();
      final friendship = Friendship(
        id: 'test_id',
        userId1: 'user_a',
        userId2: 'user_b',
        createdAt: now,
      );

      final firestoreData = friendship.toFirestore();
      expect(firestoreData['userId1'], equals('user_a'));
      expect(firestoreData['userId2'], equals('user_b'));
      expect(firestoreData['createdAt'], isNotNull);
    });

    test('should handle friendship equality', () {
      final now = DateTime.now();
      final friendship1 = Friendship(
        id: 'test_id',
        userId1: 'user_a',
        userId2: 'user_b',
        createdAt: now,
      );

      final friendship2 = Friendship(
        id: 'test_id',
        userId1: 'user_a',
        userId2: 'user_b',
        createdAt: now,
      );

      final friendship3 = Friendship(
        id: 'different_id',
        userId1: 'user_a',
        userId2: 'user_b',
        createdAt: now,
      );

      expect(friendship1, equals(friendship2));
      expect(friendship1, isNot(equals(friendship3)));
    });
  });
}