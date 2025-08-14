import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/media_file_model.dart';
import 'storage_service.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

class MediaService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  MediaService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  // Create media file
  Future<String> createMedia(String folderId, MediaFileModel media) async {
    final ref = _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .doc();
    await ref.set(media.toMap());
    return ref.id;
  }

  // Create media file with contributor attribution for shared folders
  Future<String> createMediaWithAttribution(
    String folderId, 
    MediaFileModel media, 
    String contributorId,
    bool isSharedFolder,
  ) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (contributorId.isEmpty) {
        throw Exception('Contributor ID is required');
      }

      final ref = _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .doc();

      // Create media data with contributor attribution
      final mediaData = media.toMap();
      
      if (isSharedFolder) {
        mediaData['uploadedBy'] = contributorId;
        mediaData['uploadedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await ref.set(mediaData);
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create media with attribution: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Update media file
  Future<void> updateMedia(String folderId, String mediaId, Map<String, dynamic> data) async {
    await _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .doc(mediaId)
        .update(data);
  }

  // Delete media file
  Future<void> deleteMedia(String folderId, String mediaId) async {
    try {
      // Validate inputs
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (mediaId.isEmpty) {
        throw Exception('Media ID is required');
      }

      // Get the media document first to access the URL for storage cleanup
      final doc = await _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .doc(mediaId)
          .get();
      
      if (doc.exists) {
        final media = MediaFileModel.fromDoc(doc);
        
        // Delete from Firebase Storage if it has a URL (not text files)
        if (media.url.isNotEmpty && media.type != 'text') {
          try {
            await _storageService.deleteFile(media.url);
          } catch (e) {
            // Log error but continue with Firestore deletion
            // Storage file might already be deleted or not exist
          }
        }
        
        // Delete from Firestore
        await doc.reference.delete();
      }
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete media file: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Stream media files in a folder
  Stream<List<MediaFileModel>> streamMedia(String folderId) {
    return _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MediaFileModel.fromDoc(d)).toList());
  }

  // Update media file name (title)
  Future<void> updateFileName(String folderId, String mediaId, String newTitle) async {
    try {
      // Validate inputs
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (mediaId.isEmpty) {
        throw Exception('Media ID is required');
      }

      final nameError = ValidationUtils.validateFileName(newTitle);
      if (nameError != null) {
        throw Exception(nameError);
      }

      // Sanitize title
      final sanitizedTitle = ValidationUtils.sanitizeText(newTitle);
      if (!ValidationUtils.isSafeForDisplay(sanitizedTitle)) {
        throw Exception('File name contains invalid characters');
      }

      await _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .doc(mediaId)
          .update({
        'title': sanitizedTitle,
        'lastModified': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to update file name: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Delete multiple media files
  Future<void> deleteFiles(String folderId, List<String> mediaIds) async {
    try {
      // Validate inputs
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      final batchError = ValidationUtils.validateBatchOperation(mediaIds);
      if (batchError != null) {
        throw Exception(batchError);
      }

      // First, get all media documents to access URLs for storage cleanup
      final List<MediaFileModel> mediaToDelete = [];
      for (final mediaId in mediaIds) {
        final doc = await _firestore
            .collection('folders')
            .doc(folderId)
            .collection('media')
            .doc(mediaId)
            .get();
        
        if (doc.exists) {
          mediaToDelete.add(MediaFileModel.fromDoc(doc));
        }
      }
      
      // Delete from Firebase Storage (for files with URLs)
      final List<String> storageErrors = [];
      for (final media in mediaToDelete) {
        if (media.url.isNotEmpty && media.type != 'text') {
          try {
            await _storageService.deleteFile(media.url);
          } catch (e) {
            storageErrors.add('Failed to delete ${media.title}: ${ErrorHandler.getErrorMessage(e)}');
          }
        }
      }
      
      // Delete from Firestore using batch
      final batch = _firestore.batch();
      for (final mediaId in mediaIds) {
        batch.delete(_firestore
            .collection('folders')
            .doc(folderId)
            .collection('media')
            .doc(mediaId));
      }
      await batch.commit();
      
      // If there were storage errors, throw an exception with details
      if (storageErrors.isNotEmpty) {
        throw Exception('Some files could not be deleted from storage:\n${storageErrors.join('\n')}');
      }
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete media files: ${ErrorHandler.getErrorMessage(e)}');
    }
  }
}