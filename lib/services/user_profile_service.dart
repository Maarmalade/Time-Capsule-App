import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/user_profile.dart';
import '../utils/validation_utils.dart';
import '../utils/error_handler.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _usersCollection = 'users';
  static const int _minUsernameLength = 3;
  static const int _maxUsernameLength = 20;
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  /// Creates a new user profile in Firestore
  Future<void> createUserProfile(String userId, String username, String email) async {
    try {
      // Validate inputs
      final usernameError = ValidationUtils.validateUsername(username);
      if (usernameError != null) {
        throw Exception(usernameError);
      }

      final emailError = ValidationUtils.validateEmail(email);
      if (emailError != null) {
        throw Exception(emailError);
      }

      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Check if username is available
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw Exception('Username already taken. Please try another.');
      }

      final now = DateTime.now();
      final userProfile = UserProfile(
        id: userId,
        email: email,
        username: username.trim(),
        profilePictureUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(userProfile.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create user profile: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Retrieves a user profile by user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  /// Updates the username for a user
  Future<void> updateUsername(String userId, String newUsername) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final usernameError = ValidationUtils.validateUsername(newUsername);
      if (usernameError != null) {
        throw Exception(usernameError);
      }

      final trimmedUsername = newUsername.trim();

      // Check if username is available
      final isAvailable = await isUsernameAvailable(trimmedUsername);
      if (!isAvailable) {
        throw Exception('Username already taken. Please try another.');
      }

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'username': trimmedUsername,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to update username: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Checks if a username is available (not already taken)
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Unable to check username availability. Please try again.');
    }
  }

  /// Updates the profile picture for a user
  Future<void> updateProfilePicture(String userId, File imageFile) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Validate the profile picture file
      final validationError = ValidationUtils.validateProfilePicture(imageFile);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Compress the image
      final compressedFile = await _compressImage(imageFile);
      
      // Upload to Firebase Storage
      final storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child('profile_picture.jpg');

      final uploadTask = await storageRef.putFile(compressedFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore with new profile picture URL
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'profilePictureUrl': downloadUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Clean up compressed file if it's different from original
      if (compressedFile.path != imageFile.path) {
        try {
          await compressedFile.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload profile picture: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Updates the user's password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      if (user.email == null) {
        throw Exception('User email not available');
      }

      // Validate current password
      if (currentPassword.isEmpty) {
        throw Exception('Current password is required');
      }

      // Validate new password
      final passwordError = ValidationUtils.validatePassword(newPassword);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      // Check if new password is different from current
      if (currentPassword == newPassword) {
        throw Exception('New password must be different from current password');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unable to update password: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Gets the current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return await getUserProfile(user.uid);
  }

  /// Updates user profile fields
  Future<void> updateUserProfile(String userId, {
    String? email,
    String? username,
    String? profilePictureUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (email != null) updates['email'] = email;
      if (profilePictureUrl != null) updates['profilePictureUrl'] = profilePictureUrl;
      
      if (username != null) {
        // Validate and check availability for username
        if (!_isValidUsernameFormat(username)) {
          throw Exception('Username must be 3-20 characters, letters, numbers, and underscores only.');
        }
        
        final isAvailable = await isUsernameAvailable(username);
        if (!isAvailable) {
          throw Exception('Username already taken. Please try another.');
        }
        
        updates['username'] = username;
      }

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Validates username format
  bool _isValidUsernameFormat(String username) {
    return username.length >= _minUsernameLength &&
           username.length <= _maxUsernameLength &&
           _usernameRegex.hasMatch(username);
  }

  /// Compresses an image file for optimal storage
  Future<File> _compressImage(File imageFile) async {
    try {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 85,
        minWidth: 300,
        minHeight: 300,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      return imageFile;
    } catch (e) {
      // If compression fails, return original file
      return imageFile;
    }
  }

  /// Deletes user profile picture from storage
  Future<void> deleteProfilePicture(String userId) async {
    try {
      // Delete from Firebase Storage
      final storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child('profile_picture.jpg');

      await storageRef.delete();

      // Update Firestore to remove profile picture URL
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'profilePictureUrl': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Don't throw error if file doesn't exist
      if (!e.toString().contains('object-not-found')) {
        throw Exception('Failed to delete profile picture: ${e.toString()}');
      }
    }
  }
}

