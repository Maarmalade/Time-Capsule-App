import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/folder_model.dart' as folder_model;
import '../models/shared_folder_data.dart';
import '../models/shared_folder_notification_model.dart';
import '../models/user_profile.dart';
import 'media_service.dart';
import 'user_profile_service.dart';
import '../utils/social_validation_utils.dart';
import '../utils/social_error_handler.dart';
import '../utils/rate_limiter.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

class FolderService {
  final FirebaseFirestore _firestore;
  final MediaService _mediaService;
  final FirebaseAuth _auth;
  final UserProfileService _userProfileService;

  FolderService({
    FirebaseFirestore? firestore,
    MediaService? mediaService,
    FirebaseAuth? auth,
    UserProfileService? userProfileService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _mediaService = mediaService ?? MediaService(),
       _auth = auth ?? FirebaseAuth.instance,
       _userProfileService = userProfileService ?? UserProfileService();

  // Create folder
  Future<String> createFolder(folder_model.FolderModel folder) async {
    try {
      // Validate folder data
      final nameError = ValidationUtils.validateFileName(folder.name);
      if (nameError != null) {
        throw Exception(nameError);
      }

      if (folder.userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Sanitize folder name
      final sanitizedName = ValidationUtils.sanitizeText(folder.name);
      if (!ValidationUtils.isSafeForDisplay(sanitizedName)) {
        throw Exception('Folder name contains invalid characters');
      }

      final ref = _firestore.collection('folders').doc();
      final folderWithId = folder_model.FolderModel(
        id: ref.id,
        name: sanitizedName,
        userId: folder.userId,
        parentFolderId: folder.parentFolderId,
        description: folder.description != null
            ? ValidationUtils.sanitizeText(folder.description!)
            : null,
        coverImageUrl: folder.coverImageUrl,
        createdAt: folder.createdAt,
      );
      await ref.set(folderWithId.toMap());
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to create folder: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Update folder
  Future<void> updateFolder(String folderId, Map<String, dynamic> data) async {
    await _firestore.collection('folders').doc(folderId).update(data);
  }

  // Delete folder and all nested folders/media
  Future<void> deleteFolder(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Check if folder exists
      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        return; // Folder already deleted
      }

      // Delete all subfolders recursively
      final subfolders = await _firestore
          .collection('folders')
          .where('parentFolderId', isEqualTo: folderId)
          .get();

      for (final doc in subfolders.docs) {
        await deleteFolder(doc.id);
      }

      // Delete all media in this folder (with proper storage cleanup)
      final media = await _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .get();

      if (media.docs.isNotEmpty) {
        final mediaIds = media.docs.map((doc) => doc.id).toList();
        await _mediaService.deleteFiles(folderId, mediaIds);
      }

      // Delete the folder itself
      await _firestore.collection('folders').doc(folderId).delete();
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to delete folder: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Stream folders (top-level or nested)
  Stream<List<folder_model.FolderModel>> streamFolders({
    required String userId,
    String? parentFolderId,
  }) {
    Query query = _firestore
        .collection('folders')
        .where('userId', isEqualTo: userId);
    if (parentFolderId == null) {
      query = query.where('parentFolderId', isNull: true);
    } else {
      query = query.where('parentFolderId', isEqualTo: parentFolderId);
    }
    return query
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => folder_model.FolderModel.fromDoc(d))
              .toList(),
        );
  }

  // Get a folder by ID
  Future<folder_model.FolderModel?> getFolder(String folderId) async {
    final doc = await _firestore.collection('folders').doc(folderId).get();
    if (!doc.exists) return null;
    return folder_model.FolderModel.fromDoc(doc);
  }

  // Update folder name
  Future<void> updateFolderName(String folderId, String newName) async {
    try {
      // Validate inputs
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      final nameError = ValidationUtils.validateFileName(newName);
      if (nameError != null) {
        throw Exception(nameError);
      }

      // Sanitize folder name
      final sanitizedName = ValidationUtils.sanitizeText(newName);
      if (!ValidationUtils.isSafeForDisplay(sanitizedName)) {
        throw Exception('Folder name contains invalid characters');
      }

      await _firestore.collection('folders').doc(folderId).update({
        'name': sanitizedName,
        'lastModified': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to update folder name: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Delete multiple folders
  Future<void> deleteFolders(List<String> folderIds) async {
    try {
      // Validate batch operation
      final batchError = ValidationUtils.validateBatchOperation(folderIds);
      if (batchError != null) {
        throw Exception(batchError);
      }

      // For batch folder deletion, we need to handle each folder individually
      // to ensure proper cleanup of nested content and storage files
      final List<String> errors = [];

      for (final folderId in folderIds) {
        try {
          await deleteFolder(folderId);
        } catch (e) {
          errors.add(
            'Failed to delete folder $folderId: ${ErrorHandler.getErrorMessage(e)}',
          );
        }
      }

      // If there were any errors, throw an exception with details
      if (errors.isNotEmpty) {
        throw Exception(
          'Some folders could not be deleted:\n${errors.join('\n')}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to delete folders: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // ========== SHARED FOLDER FUNCTIONALITY ==========

  // Create shared folder with contributors
  Future<String> createSharedFolder(
    folder_model.FolderModel folder,
    List<String> contributorIds,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to create shared folders');
      }

      // Check rate limiting
      if (!SocialRateLimiters.canModifySharedFolder(currentUser.uid)) {
        throw Exception(
          'Too many shared folder operations. Please wait before creating another shared folder.',
        );
      }

      // Validate folder name
      final folderNameValidation = SocialValidationUtils.validateFolderName(
        folder.name,
      );
      if (folderNameValidation.hasError) {
        throw Exception(folderNameValidation.errorMessage);
      }

      // Validate shared folder contributors
      final contributorValidation =
          SocialValidationUtils.validateSharedFolderContributors(
            ownerId: folder.userId,
            contributorIds: contributorIds,
          );
      if (contributorValidation.hasError) {
        throw Exception(contributorValidation.errorMessage);
      }

      final sanitizedName = folderNameValidation.data as String;
      final uniqueContributors = contributorIds.toSet().toList();

      final ref = _firestore.collection('folders').doc();

      // Create shared folder data
      final sharedData = SharedFolderData(
        contributorIds: uniqueContributors,
        ownerId: folder.userId,
        isLocked: false,
        isPublic: false,
      );

      // Create folder document with shared data
      final folderData = {
        'name': sanitizedName,
        'userId': folder.userId,
        'parentFolderId': folder.parentFolderId,
        'description': folder.description != null
            ? ValidationUtils.sanitizeText(folder.description!)
            : null,
        'coverImageUrl': folder.coverImageUrl,
        'createdAt': folder.createdAt,
        'isShared': true,
        ...sharedData.toMap(),
      };

      await ref.set(folderData);

      // Send notifications to contributors
      for (final contributorId in uniqueContributors) {
        await notifyContributorAdded(ref.id, contributorId);
      }

      // Record the shared folder creation for rate limiting
      SocialRateLimiters.recordSharedFolderModification(currentUser.uid);

      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(SocialErrorHandler.getSharedFolderErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to create shared folder: ${SocialErrorHandler.getSharedFolderErrorMessage(e)}',
      );
    }
  }

  // Convert a regular folder to a shared folder
  Future<void> convertToSharedFolder(
    String folderId,
    List<String> contributorIds,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to convert folders');
      }

      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Check rate limiting
      if (!SocialRateLimiters.canModifySharedFolder(currentUser.uid)) {
        throw Exception(
          'Too many shared folder operations. Please wait before creating another shared folder.',
        );
      }

      // Get current folder data
      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final isShared = folderData['isShared'] ?? false;

      if (isShared) {
        throw Exception('Folder is already shared');
      }

      // Validate that the current user is the owner
      final userId = folderData['userId'];
      if (userId != currentUser.uid) {
        throw Exception(
          'Only the folder owner can convert it to a shared folder',
        );
      }

      // Validate shared folder contributors
      final contributorValidation =
          SocialValidationUtils.validateSharedFolderContributors(
            ownerId: currentUser.uid,
            contributorIds: contributorIds,
          );
      if (contributorValidation.hasError) {
        throw Exception(contributorValidation.errorMessage);
      }

      final uniqueContributors = contributorIds.toSet().toList();

      // Create shared folder data
      final sharedData = SharedFolderData(
        contributorIds: uniqueContributors,
        ownerId: currentUser.uid,
        isLocked: false,
        isPublic: false,
      );

      // Update the folder to be shared
      await _firestore.collection('folders').doc(folderId).update({
        'isShared': true,
        ...sharedData.toMap(),
      });

      // Send notifications to contributors
      for (final contributorId in uniqueContributors) {
        await notifyContributorAdded(folderId, contributorId);
      }

      // Record the shared folder creation for rate limiting
      SocialRateLimiters.recordSharedFolderModification(currentUser.uid);
    } on FirebaseException catch (e) {
      throw Exception(SocialErrorHandler.getSharedFolderErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to convert folder to shared: ${SocialErrorHandler.getSharedFolderErrorMessage(e)}',
      );
    }
  }

  // Invite contributors to a shared folder
  Future<void> inviteContributors(String folderId, List<String> userIds) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userIds.isEmpty) {
        throw Exception('At least one user ID is required');
      }

      // Get current folder data
      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final isShared = folderData['isShared'] ?? false;

      if (!isShared) {
        throw Exception('Cannot invite contributors to a non-shared folder');
      }

      final sharedData = SharedFolderData.fromMap(folderData);

      if (sharedData.isLocked) {
        throw Exception('Cannot invite contributors to a locked folder');
      }

      // Add new contributors (avoiding duplicates and owner)
      final currentContributors = Set<String>.from(sharedData.contributorIds);
      final newContributors = userIds
          .where(
            (id) =>
                id != sharedData.ownerId && !currentContributors.contains(id),
          )
          .toList();

      if (newContributors.isEmpty) {
        return; // No new contributors to add
      }

      final updatedContributors = [...currentContributors, ...newContributors];

      await _firestore.collection('folders').doc(folderId).update({
        'contributorIds': updatedContributors,
      });

      // Send notifications to new contributors
      for (final contributorId in newContributors) {
        await notifyContributorAdded(folderId, contributorId);
      }
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to invite contributors: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Notify contributor when added to a shared folder
  Future<void> notifyContributorAdded(String folderId, String contributorId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (contributorId.isEmpty) {
        throw Exception('Contributor ID is required');
      }

      // Get folder information
      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final folderName = folderData['name'] ?? 'Unknown Folder';
      final ownerId = folderData['userId'] ?? '';

      if (ownerId.isEmpty) {
        throw Exception('Folder owner not found');
      }

      // Get owner information
      final ownerProfile = await _userProfileService.getUserProfile(ownerId);
      if (ownerProfile == null) {
        throw Exception('Folder owner profile not found');
      }

      // Create notification
      final notification = SharedFolderNotification(
        id: '', // Will be set by Firestore
        folderId: folderId,
        folderName: folderName,
        ownerId: ownerId,
        ownerUsername: ownerProfile.username,
        contributorId: contributorId,
        createdAt: DateTime.now(),
        isRead: false,
      );

      // Save notification to Firestore
      await _firestore
          .collection('shared_folder_notifications')
          .add(notification.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to notify contributor: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Remove contributor from a shared folder
  Future<void> removeContributor(String folderId, String userId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Get current folder data
      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final isShared = folderData['isShared'] ?? false;

      if (!isShared) {
        throw Exception('Cannot remove contributors from a non-shared folder');
      }

      final folder = folder_model.FolderModel.fromDoc(folderDoc);

      if (userId == folder.userId) {
        throw Exception('Cannot remove the folder owner');
      }

      if (!folder.contributorIds.contains(userId)) {
        return; // User is not a contributor
      }

      final updatedContributors = List<String>.from(folder.contributorIds)
        ..remove(userId);

      await _firestore.collection('folders').doc(folderId).update({
        'contributorIds': updatedContributors,
      });

      // Notify the removed contributor (for requirement 5.5)
      await _notifyContributorRemoved(folderId, userId, folder.name);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to remove contributor: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Helper method to notify contributor when removed
  Future<void> _notifyContributorRemoved(String folderId, String contributorId, String folderName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get owner information
      final ownerProfile = await _userProfileService.getUserProfile(currentUser.uid);
      if (ownerProfile == null) return;

      // Create removal notification
      final notification = SharedFolderNotification(
        id: '', // Will be set by Firestore
        folderId: folderId,
        folderName: folderName,
        ownerId: currentUser.uid,
        ownerUsername: ownerProfile.username,
        contributorId: contributorId,
        createdAt: DateTime.now(),
        isRead: false,
      );

      // Save notification to Firestore with a different collection for removals
      await _firestore
          .collection('shared_folder_removal_notifications')
          .add(notification.toFirestore());
    } catch (e) {
      // Don't throw error for notification failures - the main operation should succeed
      // Log error silently - notification failure shouldn't block contributor removal
    }
  }

  // Lock folder to prevent further contributions
  Future<void> lockFolder(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID cannot be empty');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to lock folder');
      }

      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data()!;
      final isShared = folderData['isShared'] ?? false;

      if (!isShared) {
        throw Exception('Cannot lock a non-shared folder');
      }

      await _firestore.collection('folders').doc(folderId).update({
        'isLocked': true,
        'lockedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to lock this folder');
      } else if (e.code == 'not-found') {
        throw Exception('Folder not found');
      }
      throw Exception(
        'Failed to lock folder: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Unlock folder to allow contributions
  Future<void> unlockFolder(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID cannot be empty');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to unlock folder');
      }

      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data()!;
      final isShared = folderData['isShared'] ?? false;

      if (!isShared) {
        throw Exception('Cannot unlock a non-shared folder');
      }

      await _firestore.collection('folders').doc(folderId).update({
        'isLocked': false,
        'lockedAt': null,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to unlock this folder');
      } else if (e.code == 'not-found') {
        throw Exception('Folder not found');
      }
      throw Exception(
        'Failed to unlock folder: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Get shared folder data
  Future<SharedFolderData?> getSharedFolderData(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        return null;
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final isShared = folderData['isShared'] ?? false;

      if (!isShared) {
        return null;
      }

      return SharedFolderData.fromMap(folderData);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get shared folder data: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Check if user can contribute to folder
  Future<bool> canUserContribute(String folderId, String userId) async {
    try {
      if (folderId.isEmpty || userId.isEmpty) {
        return false;
      }

      final folder = await getFolder(folderId);
      if (folder == null) {
        return false;
      }

      // Owner can always contribute
      if (folder.userId == userId) {
        return true;
      }

      // For shared folders, check if user is contributor and folder is not locked
      if (folder.isShared && folder.contributorIds.contains(userId)) {
        return !folder.isLocked;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if user can view folder
  Future<bool> canUserView(String folderId, String userId) async {
    try {
      if (folderId.isEmpty || userId.isEmpty) {
        return false;
      }

      final folder = await getFolder(folderId);
      if (folder == null) {
        return false;
      }

      // Owner can always view
      if (folder.userId == userId) {
        return true;
      }

      // Contributors can view shared folders
      if (folder.isShared && folder.contributorIds.contains(userId)) {
        return true;
      }

      // Anyone can view public folders
      if (folder.isPublic) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get folder contributors (for task 11)
  Future<List<UserProfile>> getFolderContributors(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      final folder = await getFolder(folderId);
      if (folder == null) {
        throw Exception('Folder not found');
      }

      if (!folder.isShared) {
        return []; // Non-shared folders have no contributors
      }

      final contributors = <UserProfile>[];
      for (final contributorId in folder.contributorIds) {
        try {
          final profile = await _userProfileService.getUserProfile(contributorId);
          if (profile != null) {
            contributors.add(profile);
          }
        } catch (e) {
          // Skip contributors whose profiles can't be loaded
          continue;
        }
      }

      return contributors;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get folder contributors: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Stream folders that user can access (owned, contributed to, or public)
  Stream<List<folder_model.FolderModel>> streamAccessibleFolders({
    required String userId,
    String? parentFolderId,
    bool includeShared = true,
    bool includePublic = true,
  }) {
    Query query = _firestore.collection('folders');

    if (parentFolderId == null) {
      query = query.where('parentFolderId', isNull: true);
    } else {
      query = query.where('parentFolderId', isEqualTo: parentFolderId);
    }

    // Build compound query for accessible folders
    if (includeShared && includePublic) {
      // User owns, contributes to, or folder is public
      query = query.where(
        Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('contributorIds', arrayContains: userId),
          Filter('isPublic', isEqualTo: true),
        ),
      );
    } else if (includeShared) {
      // User owns or contributes to
      query = query.where(
        Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('contributorIds', arrayContains: userId),
        ),
      );
    } else if (includePublic) {
      // User owns or folder is public
      query = query.where(
        Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('isPublic', isEqualTo: true),
        ),
      );
    } else {
      // Only owned folders
      query = query.where('userId', isEqualTo: userId);
    }

    return query
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => folder_model.FolderModel.fromDoc(d))
              .toList(),
        );
  }

  // Stream folders that user can access (owned or contributor) with real-time updates
  Stream<List<folder_model.FolderModel>> streamUserAccessibleFolders(
    String userId, {
    String? parentFolderId,
  }) {
    try {
      if (userId.isEmpty) {
        return Stream.value(<folder_model.FolderModel>[]);
      }

      // Use a simpler approach without orderBy to avoid index issues
      Query query = _firestore.collection('folders');

      // Filter by parent folder first
      if (parentFolderId == null) {
        query = query.where('parentFolderId', isNull: true);
      } else {
        query = query.where('parentFolderId', isEqualTo: parentFolderId);
      }

      return query
          .snapshots()
          .map((snap) {
            final folders = snap.docs
                .map((d) => folder_model.FolderModel.fromDoc(d))
                .where((folder) => _canUserAccessFolder(folder, userId))
                .toList();
            
            // Sort client-side to avoid Firestore index issues
            folders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return folders;
          });
    } catch (e) {
      // Return empty stream on error to prevent UI crashes
      return Stream.value(<folder_model.FolderModel>[]);
    }
  }

  // Helper method to validate folder access
  bool _canUserAccessFolder(folder_model.FolderModel folder, String userId) {
    // User is the owner
    if (folder.userId == userId) {
      return true;
    }

    // User is a contributor to a shared folder
    if (folder.isShared && folder.contributorIds.contains(userId)) {
      return true;
    }

    return false;
  }

  // ========== PUBLIC FOLDER FUNCTIONALITY ==========

  // Make folder public
  Future<void> makePublic(String folderId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to make folders public');
      }

      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Check rate limiting
      if (!SocialRateLimiters.canModifyPublicFolder(currentUser.uid)) {
        throw Exception(
          'Too many public folder operations. Please wait before making another folder public.',
        );
      }

      // Get current folder data
      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;

      // Verify user is the owner
      if (folderData['userId'] != currentUser.uid) {
        throw Exception('Only the folder owner can make folders public');
      }

      // Get user's current public folder count for validation
      final userPublicFolders = await _firestore
          .collection('folders')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isPublic', isEqualTo: true)
          .get();

      // Validate public folder creation
      final validationResult =
          SocialValidationUtils.validatePublicFolderCreation(
            userId: currentUser.uid,
            userPublicFolderCount: userPublicFolders.docs.length,
          );

      if (validationResult.hasError) {
        throw Exception(validationResult.errorMessage);
      }

      await _firestore.collection('folders').doc(folderId).update({
        'isPublic': true,
      });

      // Record the public folder modification for rate limiting
      SocialRateLimiters.recordPublicFolderModification(currentUser.uid);
    } on FirebaseException catch (e) {
      throw Exception(SocialErrorHandler.getPublicFolderErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to make folder public: ${SocialErrorHandler.getPublicFolderErrorMessage(e)}',
      );
    }
  }

  // Make folder private
  Future<void> makePrivate(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Get current folder data
      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      await _firestore.collection('folders').doc(folderId).update({
        'isPublic': false,
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to make folder private: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Get public folders with pagination
  Future<List<folder_model.FolderModel>> getPublicFolders({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore
          .collection('folders')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      var folders = snapshot.docs
          .map((d) => folder_model.FolderModel.fromDoc(d))
          .toList();

      // Apply client-side search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        folders = folders
            .where(
              (folder) =>
                  folder.name.toLowerCase().contains(lowercaseQuery) ||
                  (folder.description?.toLowerCase().contains(lowercaseQuery) ??
                      false),
            )
            .toList();
      }

      return folders;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get public folders: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Stream public folders
  Stream<List<folder_model.FolderModel>> streamPublicFolders({
    int limit = 20,
    String? searchQuery,
  }) {
    Query query = _firestore
        .collection('folders')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query.snapshots().map((snap) {
      var folders = snap.docs
          .map((d) => folder_model.FolderModel.fromDoc(d))
          .toList();

      // Apply client-side search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        folders = folders
            .where(
              (folder) =>
                  folder.name.toLowerCase().contains(lowercaseQuery) ||
                  (folder.description?.toLowerCase().contains(lowercaseQuery) ??
                      false),
            )
            .toList();
      }

      return folders;
    });
  }

  // Check if folder is public
  Future<bool> isFolderPublic(String folderId) async {
    try {
      if (folderId.isEmpty) {
        return false;
      }

      final folderDoc = await _firestore
          .collection('folders')
          .doc(folderId)
          .get();
      if (!folderDoc.exists) {
        return false;
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      return folderData['isPublic'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // ========== SHARED FOLDER NOTIFICATION FUNCTIONALITY ==========

  // Get shared folder notifications for a user
  Future<List<SharedFolderNotification>> getSharedFolderNotifications(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      final querySnapshot = await _firestore
          .collection('shared_folder_notifications')
          .where('contributorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SharedFolderNotification.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get shared folder notifications: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Stream shared folder notifications for a user
  Stream<List<SharedFolderNotification>> streamSharedFolderNotifications(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('shared_folder_notifications')
        .where('contributorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharedFolderNotification.fromFirestore(doc))
            .toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      if (notificationId.isEmpty) {
        throw Exception('Notification ID is required');
      }

      await _firestore
          .collection('shared_folder_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to mark notification as read: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (notificationId.isEmpty) {
        throw Exception('Notification ID is required');
      }

      await _firestore
          .collection('shared_folder_notifications')
          .doc(notificationId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to delete notification: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Get unread notification count for a user
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      if (userId.isEmpty) {
        return 0;
      }

      final querySnapshot = await _firestore
          .collection('shared_folder_notifications')
          .where('contributorId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get shared folders between current user and another user
  Future<List<folder_model.FolderModel>> getSharedFoldersBetweenUsers(String otherUserId) async {
    try {
      if (otherUserId.isEmpty) {
        throw Exception('Other user ID is required');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      // Get folders where current user is owner and other user is contributor
      final ownedFoldersQuery = await _firestore
          .collection('folders')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isShared', isEqualTo: true)
          .where('contributorIds', arrayContains: otherUserId)
          .get();

      // Get folders where other user is owner and current user is contributor
      final contributedFoldersQuery = await _firestore
          .collection('folders')
          .where('userId', isEqualTo: otherUserId)
          .where('isShared', isEqualTo: true)
          .where('contributorIds', arrayContains: currentUser.uid)
          .get();

      final List<folder_model.FolderModel> sharedFolders = [];

      // Add owned folders
      for (final doc in ownedFoldersQuery.docs) {
        sharedFolders.add(folder_model.FolderModel.fromDoc(doc));
      }

      // Add contributed folders
      for (final doc in contributedFoldersQuery.docs) {
        sharedFolders.add(folder_model.FolderModel.fromDoc(doc));
      }

      // Sort by creation date (newest first)
      sharedFolders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sharedFolders;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get shared folders between users: $e');
    }
  }
}
