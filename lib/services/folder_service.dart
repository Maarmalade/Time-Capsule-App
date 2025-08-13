import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder_model.dart' as folder_model;
import '../models/shared_folder_data.dart';
import 'media_service.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

class FolderService {
  final FirebaseFirestore _firestore;
  final MediaService _mediaService;

  FolderService({
    FirebaseFirestore? firestore,
    MediaService? mediaService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _mediaService = mediaService ?? MediaService();

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
        description: folder.description != null ? ValidationUtils.sanitizeText(folder.description!) : null,
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
      throw Exception('Failed to create folder: ${ErrorHandler.getErrorMessage(e)}');
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
      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
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
      throw Exception('Failed to delete folder: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Stream folders (top-level or nested)
  Stream<List<folder_model.FolderModel>> streamFolders({required String userId, String? parentFolderId}) {
    Query query = _firestore.collection('folders').where('userId', isEqualTo: userId);
    if (parentFolderId == null) {
      query = query.where('parentFolderId', isNull: true);
    } else {
      query = query.where('parentFolderId', isEqualTo: parentFolderId);
    }
    return query
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((d) => folder_model.FolderModel.fromDoc(d)).toList());
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
      throw Exception('Failed to update folder name: ${ErrorHandler.getErrorMessage(e)}');
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
          errors.add('Failed to delete folder $folderId: ${ErrorHandler.getErrorMessage(e)}');
        }
      }
      
      // If there were any errors, throw an exception with details
      if (errors.isNotEmpty) {
        throw Exception('Some folders could not be deleted:\n${errors.join('\n')}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete folders: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // ========== SHARED FOLDER FUNCTIONALITY ==========

  // Create shared folder with contributors
  Future<String> createSharedFolder(
    folder_model.FolderModel folder,
    List<String> contributorIds,
  ) async {
    try {
      // Validate folder data
      final nameError = ValidationUtils.validateFileName(folder.name);
      if (nameError != null) {
        throw Exception(nameError);
      }

      if (folder.userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Validate contributor IDs
      if (contributorIds.isEmpty) {
        throw Exception('At least one contributor is required for shared folders');
      }

      // Remove duplicates and owner from contributors
      final uniqueContributors = contributorIds.toSet().toList();
      uniqueContributors.remove(folder.userId);

      if (uniqueContributors.isEmpty) {
        throw Exception('Contributors cannot include the folder owner');
      }

      // Sanitize folder name
      final sanitizedName = ValidationUtils.sanitizeText(folder.name);
      if (!ValidationUtils.isSafeForDisplay(sanitizedName)) {
        throw Exception('Folder name contains invalid characters');
      }

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
        'description': folder.description != null ? ValidationUtils.sanitizeText(folder.description!) : null,
        'coverImageUrl': folder.coverImageUrl,
        'createdAt': folder.createdAt,
        'isShared': true,
        ...sharedData.toMap(),
      };

      await ref.set(folderData);
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create shared folder: ${ErrorHandler.getErrorMessage(e)}');
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
      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
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
      final newContributors = userIds.where((id) => 
        id != sharedData.ownerId && !currentContributors.contains(id)
      ).toList();

      if (newContributors.isEmpty) {
        return; // No new contributors to add
      }

      final updatedContributors = [...currentContributors, ...newContributors];
      
      await _firestore.collection('folders').doc(folderId).update({
        'contributorIds': updatedContributors,
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to invite contributors: ${ErrorHandler.getErrorMessage(e)}');
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
      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final isShared = folderData['isShared'] ?? false;
      
      if (!isShared) {
        throw Exception('Cannot remove contributors from a non-shared folder');
      }

      final sharedData = SharedFolderData.fromMap(folderData);
      
      if (userId == sharedData.ownerId) {
        throw Exception('Cannot remove the folder owner');
      }

      if (!sharedData.hasContributor(userId)) {
        return; // User is not a contributor
      }

      final updatedContributors = List<String>.from(sharedData.contributorIds)
        ..remove(userId);
      
      await _firestore.collection('folders').doc(folderId).update({
        'contributorIds': updatedContributors,
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to remove contributor: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Lock folder to prevent further contributions
  Future<void> lockFolder(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Get current folder data
      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final isShared = folderData['isShared'] ?? false;
      
      if (!isShared) {
        throw Exception('Cannot lock a non-shared folder');
      }

      await _firestore.collection('folders').doc(folderId).update({
        'isLocked': true,
        'lockedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to lock folder: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Unlock folder to allow contributions
  Future<void> unlockFolder(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Get current folder data
      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      final isShared = folderData['isShared'] ?? false;
      
      if (!isShared) {
        throw Exception('Cannot unlock a non-shared folder');
      }

      await _firestore.collection('folders').doc(folderId).update({
        'isLocked': false,
        'lockedAt': null,
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to unlock folder: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Get shared folder data
  Future<SharedFolderData?> getSharedFolderData(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
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
      throw Exception('Failed to get shared folder data: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Check if user can contribute to folder
  Future<bool> canUserContribute(String folderId, String userId) async {
    try {
      final sharedData = await getSharedFolderData(folderId);
      if (sharedData == null) {
        // Regular folder - only owner can contribute
        final folder = await getFolder(folderId);
        return folder?.userId == userId;
      }
      
      return sharedData.canContribute(userId);
    } catch (e) {
      return false;
    }
  }

  // Check if user can view folder
  Future<bool> canUserView(String folderId, String userId) async {
    try {
      final sharedData = await getSharedFolderData(folderId);
      if (sharedData == null) {
        // Regular folder - only owner can view
        final folder = await getFolder(folderId);
        return folder?.userId == userId;
      }
      
      return sharedData.canView(userId);
    } catch (e) {
      return false;
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
      query = query.where(Filter.or(
        Filter('userId', isEqualTo: userId),
        Filter('contributorIds', arrayContains: userId),
        Filter('isPublic', isEqualTo: true),
      ));
    } else if (includeShared) {
      // User owns or contributes to
      query = query.where(Filter.or(
        Filter('userId', isEqualTo: userId),
        Filter('contributorIds', arrayContains: userId),
      ));
    } else if (includePublic) {
      // User owns or folder is public
      query = query.where(Filter.or(
        Filter('userId', isEqualTo: userId),
        Filter('isPublic', isEqualTo: true),
      ));
    } else {
      // Only owned folders
      query = query.where('userId', isEqualTo: userId);
    }

    return query
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((d) => folder_model.FolderModel.fromDoc(d)).toList());
  }

  // ========== PUBLIC FOLDER FUNCTIONALITY ==========

  // Make folder public
  Future<void> makePublic(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Get current folder data
      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
      if (!folderDoc.exists) {
        throw Exception('Folder not found');
      }

      await _firestore.collection('folders').doc(folderId).update({
        'isPublic': true,
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to make folder public: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Make folder private
  Future<void> makePrivate(String folderId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      // Get current folder data
      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
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
      throw Exception('Failed to make folder private: ${ErrorHandler.getErrorMessage(e)}');
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
      var folders = snapshot.docs.map((d) => folder_model.FolderModel.fromDoc(d)).toList();

      // Apply client-side search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        folders = folders.where((folder) =>
          folder.name.toLowerCase().contains(lowercaseQuery) ||
          (folder.description?.toLowerCase().contains(lowercaseQuery) ?? false)
        ).toList();
      }

      return folders;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get public folders: ${ErrorHandler.getErrorMessage(e)}');
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
      var folders = snap.docs.map((d) => folder_model.FolderModel.fromDoc(d)).toList();

      // Apply client-side search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        folders = folders.where((folder) =>
          folder.name.toLowerCase().contains(lowercaseQuery) ||
          (folder.description?.toLowerCase().contains(lowercaseQuery) ?? false)
        ).toList();
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

      final folderDoc = await _firestore.collection('folders').doc(folderId).get();
      if (!folderDoc.exists) {
        return false;
      }

      final folderData = folderDoc.data() as Map<String, dynamic>;
      return folderData['isPublic'] ?? false;
    } catch (e) {
      return false;
    }
  }
}