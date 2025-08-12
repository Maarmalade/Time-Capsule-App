import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder_model.dart' as folder_model;
import 'media_service.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

class FolderService {
  final _firestore = FirebaseFirestore.instance;
  final _mediaService = MediaService();

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
}