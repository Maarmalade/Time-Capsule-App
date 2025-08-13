import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/friend_request_model.dart';
import '../models/friendship_model.dart';
import '../utils/friend_validation_utils.dart';
import '../utils/error_handler.dart';

class FriendService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FriendService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static const String _usersCollection = 'users';
  static const String _friendRequestsCollection = 'friendRequests';
  static const String _friendshipsCollection = 'friendships';
  static const int _maxSearchResults = 20;


  /// Searches for users by username with query optimization
  /// Returns a list of UserProfile objects matching the search query
  Future<List<UserProfile>> searchUsersByUsername(String query) async {
    try {
      // Validate and sanitize the search query
      final sanitizedQuery = FriendValidationUtils.validateAndSanitizeSearchQuery(query);
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to search for friends');
      }

      // Perform the search query with optimization
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isGreaterThanOrEqualTo: sanitizedQuery)
          .where('username', isLessThan: '${sanitizedQuery}\uf8ff')
          .limit(_maxSearchResults)
          .get();

      // Convert documents to UserProfile objects and filter out current user
      final searchResults = querySnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((profile) => profile.id != currentUser.uid)
          .toList();

      return searchResults;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to search users: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Sends a friend request to another user with duplicate prevention
  /// Returns the created FriendRequest object
  Future<FriendRequest> sendFriendRequest(String receiverId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to send friend requests');
      }

      // Validate input
      FriendValidationUtils.validateUserId(receiverId, 'Receiver ID');
      FriendValidationUtils.validateDifferentUsers(currentUser.uid, receiverId);

      // Get current user's profile for sender information
      final senderProfile = await _getUserProfile(currentUser.uid);
      if (senderProfile == null) {
        throw Exception('Sender profile not found');
      }

      // Check if receiver exists
      final receiverProfile = await _getUserProfile(receiverId);
      if (receiverProfile == null) {
        throw Exception('User not found');
      }

      // Check for existing friend request (prevent duplicates)
      await _checkForExistingFriendRequest(currentUser.uid, receiverId);

      // Check if users are already friends
      await _checkIfAlreadyFriends(currentUser.uid, receiverId);

      // Create the friend request
      final now = DateTime.now();
      final friendRequest = FriendRequest(
        id: '', // Will be set by Firestore
        senderId: currentUser.uid,
        receiverId: receiverId,
        senderUsername: senderProfile.username,
        senderProfilePictureUrl: senderProfile.profilePictureUrl,
        status: FriendRequestStatus.pending,
        createdAt: now,
        respondedAt: null,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(_friendRequestsCollection)
          .add(friendRequest.toFirestore());

      return friendRequest.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to send friend request: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Gets pending friend requests for the current user
  /// Returns a list of FriendRequest objects
  Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to view friend requests');
      }

      final querySnapshot = await _firestore
          .collection(_friendRequestsCollection)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get friend requests: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Responds to a friend request (accept or decline)
  /// Returns the updated FriendRequest object
  Future<FriendRequest> respondToFriendRequest(String requestId, bool accept) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to respond to friend requests');
      }

      FriendValidationUtils.validateUserId(requestId, 'Request ID');

      // Get the friend request
      final requestDoc = await _firestore
          .collection(_friendRequestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Friend request not found');
      }

      final friendRequest = FriendRequest.fromFirestore(requestDoc);

      // Verify the current user is the receiver
      if (friendRequest.receiverId != currentUser.uid) {
        throw Exception('You can only respond to your own friend requests');
      }

      // Verify the request is still pending
      if (friendRequest.status != FriendRequestStatus.pending) {
        throw Exception('This friend request has already been responded to');
      }

      final now = DateTime.now();
      final newStatus = accept ? FriendRequestStatus.accepted : FriendRequestStatus.declined;

      // Update the friend request status
      await _firestore
          .collection(_friendRequestsCollection)
          .doc(requestId)
          .update({
        'status': newStatus.name,
        'respondedAt': Timestamp.fromDate(now),
      });

      // If accepted, create the friendship
      if (accept) {
        await _createFriendship(friendRequest.senderId, friendRequest.receiverId);
      }

      return friendRequest.copyWith(
        status: newStatus,
        respondedAt: now,
      );
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to respond to friend request: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Helper method to get user profile by ID
  Future<UserProfile?> _getUserProfile(String userId) async {
    final doc = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .get();

    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  /// Helper method to check for existing friend requests
  Future<void> _checkForExistingFriendRequest(String senderId, String receiverId) async {
    // Check for pending request from sender to receiver
    final existingRequest = await _firestore
        .collection(_friendRequestsCollection)
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Friend request already sent to this user');
    }

    // Check for pending request from receiver to sender (reverse direction)
    final reverseRequest = await _firestore
        .collection(_friendRequestsCollection)
        .where('senderId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: senderId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (reverseRequest.docs.isNotEmpty) {
      throw Exception('This user has already sent you a friend request');
    }
  }

  /// Helper method to check if users are already friends
  Future<void> _checkIfAlreadyFriends(String userId1, String userId2) async {
    final orderedIds = [userId1, userId2]..sort();
    
    final existingFriendship = await _firestore
        .collection(_friendshipsCollection)
        .where('userId1', isEqualTo: orderedIds[0])
        .where('userId2', isEqualTo: orderedIds[1])
        .limit(1)
        .get();

    if (existingFriendship.docs.isNotEmpty) {
      throw Exception('You are already friends with this user');
    }
  }

  /// Helper method to create a bidirectional friendship
  Future<void> _createFriendship(String userId1, String userId2) async {
    final orderedIds = [userId1, userId2]..sort();
    final now = DateTime.now();

    final friendship = Friendship(
      id: '', // Will be set by Firestore
      userId1: orderedIds[0],
      userId2: orderedIds[1],
      createdAt: now,
    );

    await _firestore
        .collection(_friendshipsCollection)
        .add(friendship.toFirestore());
  }

  /// Gets the current user's friends list
  /// Returns a list of UserProfile objects for all friends
  Future<List<UserProfile>> getFriends() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to view friends');
      }

      // Get friendships where current user is userId1
      final friendships1 = await _firestore
          .collection(_friendshipsCollection)
          .where('userId1', isEqualTo: currentUser.uid)
          .get();

      // Get friendships where current user is userId2
      final friendships2 = await _firestore
          .collection(_friendshipsCollection)
          .where('userId2', isEqualTo: currentUser.uid)
          .get();

      // Collect all friend user IDs
      final friendIds = <String>{};
      
      for (final doc in friendships1.docs) {
        final friendship = Friendship.fromFirestore(doc);
        friendIds.add(friendship.userId2); // Other user is userId2
      }
      
      for (final doc in friendships2.docs) {
        final friendship = Friendship.fromFirestore(doc);
        friendIds.add(friendship.userId1); // Other user is userId1
      }

      // Get user profiles for all friends
      final friends = <UserProfile>[];
      for (final friendId in friendIds) {
        final profile = await _getUserProfile(friendId);
        if (profile != null) {
          friends.add(profile);
        }
      }

      // Sort friends by username for consistent ordering
      friends.sort((a, b) => a.username.compareTo(b.username));
      
      return friends;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get friends: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Removes a friendship between the current user and another user
  /// Returns true if the friendship was successfully removed
  Future<bool> removeFriend(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to remove friends');
      }

      FriendValidationUtils.validateUserId(friendId, 'Friend ID');
      FriendValidationUtils.validateDifferentUsers(currentUser.uid, friendId);

      // Find the friendship document
      final orderedIds = [currentUser.uid, friendId]..sort();
      
      final friendshipQuery = await _firestore
          .collection(_friendshipsCollection)
          .where('userId1', isEqualTo: orderedIds[0])
          .where('userId2', isEqualTo: orderedIds[1])
          .limit(1)
          .get();

      if (friendshipQuery.docs.isEmpty) {
        throw Exception('Friendship not found');
      }

      // Delete the friendship document
      await _firestore
          .collection(_friendshipsCollection)
          .doc(friendshipQuery.docs.first.id)
          .delete();

      return true;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to remove friend: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Checks if two users are friends
  /// Returns true if they are friends, false otherwise
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      FriendValidationUtils.validateUserId(userId1, 'User ID 1');
      FriendValidationUtils.validateUserId(userId2, 'User ID 2');

      if (userId1 == userId2) {
        return false; // A user cannot be friends with themselves
      }

      final orderedIds = [userId1, userId2]..sort();
      
      final friendshipQuery = await _firestore
          .collection(_friendshipsCollection)
          .where('userId1', isEqualTo: orderedIds[0])
          .where('userId2', isEqualTo: orderedIds[1])
          .limit(1)
          .get();

      return friendshipQuery.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to check friendship status: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Gets the count of friends for the current user
  /// Returns the number of friends
  Future<int> getFriendsCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to get friends count');
      }

      // Count friendships where current user is userId1
      final friendships1 = await _firestore
          .collection(_friendshipsCollection)
          .where('userId1', isEqualTo: currentUser.uid)
          .get();

      // Count friendships where current user is userId2
      final friendships2 = await _firestore
          .collection(_friendshipsCollection)
          .where('userId2', isEqualTo: currentUser.uid)
          .get();

      return friendships1.docs.length + friendships2.docs.length;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get friends count: ${ErrorHandler.getErrorMessage(e)}');
    }
  }
}