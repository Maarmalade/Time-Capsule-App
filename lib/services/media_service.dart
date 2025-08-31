import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_file_model.dart';
import '../models/diary_entry_model.dart';
import 'storage_service.dart';
import 'audio_file_service.dart';
import 'permission_service.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';
import '../utils/upload_utils.dart';
import '../widgets/camera_confirmation_screen.dart';

class MediaService {
  final FirebaseFirestore _firestore;
  final StorageService _storageService;
  final AudioFileService _audioFileService;

  MediaService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
    AudioFileService? audioFileService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService(),
        _audioFileService = audioFileService ?? AudioFileService();

  // Enhanced image capture with camera confirmation flow
  Future<MediaFileModel?> captureAndUploadImage({
    required String folderId,
    required String userId,
    required ImageSource source,
    required BuildContext context,
    bool isSharedFolder = false,
    Function(double progress)? onProgress,
    Function(String message)? onStatusUpdate,
  }) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Check permissions before proceeding
      if (source == ImageSource.camera) {
        final hasPermission = await PermissionService.requestCameraPermission();
        if (!hasPermission) {
          if (context.mounted) {
            await PermissionService.showPermissionDeniedDialog(context, 'camera');
          }
          throw Exception('Camera permission is required to take photos');
        }
      } else {
        debugPrint('Requesting storage permission for gallery access...');
        final hasPermission = await PermissionService.requestStoragePermission();
        debugPrint('Storage permission result: $hasPermission');
        
        if (!hasPermission) {
          debugPrint('Storage permission denied, showing dialog...');
          if (context.mounted) {
            await PermissionService.showPermissionDeniedDialog(context, 'storage');
          }
          throw Exception('Storage permission is required to access photos');
        }
        debugPrint('Storage permission granted, proceeding with gallery access...');
      }

      final picker = ImagePicker();
      XFile? pickedFile;

      if (source == ImageSource.camera) {
        // Capture from camera
        pickedFile = await picker.pickImage(source: ImageSource.camera);
        
        if (pickedFile != null && context.mounted) {
          // Show confirmation screen for camera captures
          final confirmed = await _showCameraConfirmation(
            context: context,
            capturedMedia: pickedFile,
            mediaType: 'image',
          );
          
          if (!confirmed) {
            // User chose to retake, return null to indicate cancellation
            return null;
          }
        }
      } else {
        // Pick from gallery
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      }

      if (pickedFile == null) {
        // User cancelled the picker
        return null;
      }

      // Validate the selected file
      final imageFile = File(pickedFile.path);
      
      // Check if file still exists
      if (!await imageFile.exists()) {
        throw Exception('Selected image file no longer exists. Please try again.');
      }
      
      final validationError = UploadUtils.validateBeforeUpload(imageFile, 'image');
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Additional image-specific validation
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Selected image file is empty or corrupted');
      }

      if (fileSize > ValidationUtils.maxImageSize) {
        final maxSizeMB = (ValidationUtils.maxImageSize / (1024 * 1024)).toStringAsFixed(0);
        throw Exception('Image size must be less than ${maxSizeMB}MB');
      }

      // Read file bytes
      final file = await pickedFile.readAsBytes();
      
      // Generate unique filename
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = 'users/$userId/folders/$folderId/images/$fileName.jpg';
      
      // Upload to Firebase Storage with retry mechanism
      final url = await UploadUtils.uploadWithRetry(
        uploadFunction: () => _storageService.uploadFileBytes(
          file, 
          storagePath,
          onProgress: onProgress,
          contentType: 'image/jpeg',
        ),
        onProgress: onProgress,
        onStatusUpdate: onStatusUpdate,
      );
      
      // Create media model
      final media = MediaFileModel(
        id: '',
        folderId: folderId,
        type: 'image',
        url: url,
        title: source == ImageSource.camera ? 'Camera Photo' : 'Gallery Image',
        description: '',
        createdAt: Timestamp.now(),
      );

      // Create media with contributor attribution for shared folders
      final mediaId = await createMediaWithAttribution(
        folderId,
        media,
        userId,
        isSharedFolder,
      );

      // Return the created media with the generated ID
      return MediaFileModel(
        id: mediaId,
        folderId: media.folderId,
        type: media.type,
        url: media.url,
        title: media.title,
        description: media.description,
        createdAt: media.createdAt,
      );
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to capture and upload image: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Enhanced video capture with camera confirmation flow
  Future<MediaFileModel?> captureAndUploadVideo({
    required String folderId,
    required String userId,
    required ImageSource source,
    required BuildContext context,
    bool isSharedFolder = false,
    Function(double progress)? onProgress,
    Function(String message)? onStatusUpdate,
  }) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Check permissions before proceeding
      if (source == ImageSource.camera) {
        final hasPermission = await PermissionService.requestCameraPermission();
        if (!hasPermission) {
          if (context.mounted) {
            await PermissionService.showPermissionDeniedDialog(context, 'camera');
          }
          throw Exception('Camera permission is required to record videos');
        }
      } else {
        final hasPermission = await PermissionService.requestStoragePermission();
        if (!hasPermission) {
          if (context.mounted) {
            await PermissionService.showPermissionDeniedDialog(context, 'storage');
          }
          throw Exception('Storage permission is required to access videos');
        }
      }

      final picker = ImagePicker();
      XFile? pickedFile;

      if (source == ImageSource.camera) {
        // Capture from camera
        pickedFile = await picker.pickVideo(source: ImageSource.camera);
        
        if (pickedFile != null && context.mounted) {
          // Show confirmation screen for camera captures
          final confirmed = await _showCameraConfirmation(
            context: context,
            capturedMedia: pickedFile,
            mediaType: 'video',
          );
          
          if (!confirmed) {
            // User chose to retake, return null to indicate cancellation
            return null;
          }
        }
      } else {
        // Pick from gallery
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile == null) {
        // User cancelled the picker
        return null;
      }

      // Validate the selected file
      final videoFile = File(pickedFile.path);
      
      // Check if file still exists
      if (!await videoFile.exists()) {
        throw Exception('Selected video file no longer exists. Please try again.');
      }
      
      final validationError = UploadUtils.validateBeforeUpload(videoFile, 'video');
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Additional video-specific validation
      final fileSize = await videoFile.length();
      if (fileSize == 0) {
        throw Exception('Selected video file is empty or corrupted');
      }

      if (fileSize > ValidationUtils.maxVideoSize) {
        final maxSizeMB = (ValidationUtils.maxVideoSize / (1024 * 1024)).toStringAsFixed(0);
        throw Exception('Video size must be less than ${maxSizeMB}MB');
      }

      // Read file bytes
      final file = await pickedFile.readAsBytes();
      
      // Generate unique filename
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = 'users/$userId/folders/$folderId/videos/$fileName.mp4';
      
      // Upload to Firebase Storage with retry mechanism
      final url = await UploadUtils.uploadWithRetry(
        uploadFunction: () => _storageService.uploadFileBytes(
          file, 
          storagePath,
          onProgress: onProgress,
          contentType: 'video/mp4',
        ),
        onProgress: onProgress,
        onStatusUpdate: onStatusUpdate,
      );
      
      // Create media model
      final media = MediaFileModel(
        id: '',
        folderId: folderId,
        type: 'video',
        url: url,
        title: source == ImageSource.camera ? 'Camera Video' : 'Gallery Video',
        description: '',
        createdAt: Timestamp.now(),
      );

      // Create media with contributor attribution for shared folders
      final mediaId = await createMediaWithAttribution(
        folderId,
        media,
        userId,
        isSharedFolder,
      );

      // Return the created media with the generated ID
      return MediaFileModel(
        id: mediaId,
        folderId: media.folderId,
        type: media.type,
        url: media.url,
        title: media.title,
        description: media.description,
        createdAt: media.createdAt,
      );
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to capture and upload video: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Upload audio file from device storage
  Future<MediaFileModel?> uploadAudioFile({
    required String folderId,
    required String userId,
    required File audioFile,
    required String title,
    bool isSharedFolder = false,
    Function(double)? onProgress,
  }) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Check storage permission
      final hasPermission = await PermissionService.requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission is required to access audio files');
      }

      // Validate the audio file
      final validationError = UploadUtils.validateBeforeUpload(audioFile, 'audio');
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Get audio metadata
      final metadata = await _audioFileService.getAudioMetadata(audioFile);
      if (metadata == null) {
        throw Exception('Could not read audio file metadata');
      }

      // Generate unique filename
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = 'users/$userId/folders/$folderId/audio/$fileName.${metadata.format.toLowerCase()}';
      
      // Read file bytes
      final fileBytes = await audioFile.readAsBytes();
      
      // Upload to Firebase Storage with retry mechanism
      final url = await UploadUtils.uploadWithRetry(
        uploadFunction: () => _storageService.uploadFileBytes(fileBytes, storagePath),
        onProgress: onProgress,
        onStatusUpdate: onProgress != null ? (msg) => debugPrint(msg) : null,
      );
      
      // Create media model with audio-specific metadata
      final media = MediaFileModel(
        id: '',
        folderId: folderId,
        type: 'audio',
        url: url,
        title: title.isNotEmpty ? title : metadata.fileName,
        description: 'Duration: ${metadata.formattedDuration}, Size: ${metadata.formattedFileSize}',
        createdAt: Timestamp.now(),
      );

      // Create media with contributor attribution for shared folders
      final mediaId = await createMediaWithAttribution(
        folderId,
        media,
        userId,
        isSharedFolder,
      );

      // Return the created media with the generated ID
      return MediaFileModel(
        id: mediaId,
        folderId: media.folderId,
        type: media.type,
        url: media.url,
        title: media.title,
        description: media.description,
        createdAt: media.createdAt,
      );
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload audio file: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Upload recorded audio file
  Future<MediaFileModel?> uploadRecordedAudio({
    required String folderId,
    required String userId,
    required String recordingPath,
    required String title,
    bool isSharedFolder = false,
  }) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Check microphone permission (for recorded audio)
      final hasPermission = await PermissionService.isMicrophonePermissionGranted();
      if (!hasPermission) {
        throw Exception('Microphone permission is required for audio recordings');
      }

      final audioFile = File(recordingPath);
      if (!await audioFile.exists()) {
        throw Exception('Recording file not found');
      }

      // Get audio metadata
      final metadata = await _audioFileService.getAudioMetadata(audioFile);
      if (metadata == null) {
        throw Exception('Could not read recording metadata');
      }

      // Generate unique filename
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = 'users/$userId/folders/$folderId/audio/$fileName.m4a';
      
      // Read file bytes
      final fileBytes = await audioFile.readAsBytes();
      
      // Upload to Firebase Storage with retry mechanism
      final url = await UploadUtils.uploadWithRetry(
        uploadFunction: () => _storageService.uploadFileBytes(fileBytes, storagePath),
        onProgress: (progress) => debugPrint('Upload progress: ${(progress * 100).toInt()}%'),
        onStatusUpdate: (msg) => debugPrint('Upload status: $msg'),
      );
      
      // Create media model with audio-specific metadata
      final media = MediaFileModel(
        id: '',
        folderId: folderId,
        type: 'audio',
        url: url,
        title: title.isNotEmpty ? title : 'Voice Recording',
        description: 'Duration: ${metadata.formattedDuration}, Size: ${metadata.formattedFileSize}',
        createdAt: Timestamp.now(),
      );

      // Create media with contributor attribution for shared folders
      final mediaId = await createMediaWithAttribution(
        folderId,
        media,
        userId,
        isSharedFolder,
      );

      // Clean up temporary recording file
      try {
        await audioFile.delete();
      } catch (e) {
        // Log error but don't fail the upload
        debugPrint('Failed to delete temporary recording file: $e');
      }

      // Return the created media with the generated ID
      return MediaFileModel(
        id: mediaId,
        folderId: media.folderId,
        type: media.type,
        url: media.url,
        title: media.title,
        description: media.description,
        createdAt: media.createdAt,
      );
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload recorded audio: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

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

      // Add media type-specific metadata
      if (media.type == 'audio') {
        // Audio files already have duration and size info in description
        // Additional metadata can be added here if needed
        mediaData['mediaType'] = 'audio';
      } else if (media.type == 'diary') {
        // Diary entries have special handling
        mediaData['mediaType'] = 'diary';
        // Ensure diary-specific fields are preserved
        if (media is DiaryEntryModel) {
          mediaData['content'] = media.content;
          mediaData['attachments'] = media.attachments.map((a) => a.toMap()).toList();
          mediaData['lastModified'] = media.lastModified ?? Timestamp.fromDate(DateTime.now());
        }
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
        final data = doc.data() as Map<String, dynamic>;
        final mediaType = data['type'] as String?;
        
        // Handle diary entries with attachments
        if (mediaType == 'diary') {
          final attachments = (data['attachments'] as List<dynamic>? ?? [])
              .map((a) => DiaryMediaAttachment.fromMap(Map<String, dynamic>.from(a)))
              .toList();
          
          // Delete all attachment files from storage
          for (final attachment in attachments) {
            if (attachment.url.isNotEmpty) {
              try {
                await _storageService.deleteFile(attachment.url);
              } catch (e) {
                // Log error but continue with other deletions
              }
            }
          }
        } else {
          // Handle regular media files
          final media = MediaFileModel.fromDoc(doc);
          
          // Delete from Firebase Storage if it has a URL (not text files)
          if (media.url.isNotEmpty && media.type != 'text') {
            try {
              await _storageService.deleteFile(media.url);
            } catch (e) {
              // Log error but continue with Firestore deletion
              // Storage file might already be deleted or not exist
              ErrorHandler.logError('MediaService.deleteMedia.storage', e);
            }
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
        .map((snap) => snap.docs.map((d) {
          final data = d.data();
          final type = data['type'] ?? '';
          
          // Handle diary entries specially
          if (type == 'diary') {
            return DiaryEntryModel.fromDoc(d);
          }
          
          // Handle regular media files
          return MediaFileModel.fromDoc(d);
        }).toList());
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

      if (mediaIds.isEmpty) {
        throw Exception('No media files selected for deletion');
      }

      final batchError = ValidationUtils.validateBatchOperation(mediaIds);
      if (batchError != null) {
        throw Exception(batchError);
      }

      // Check for duplicate IDs
      final uniqueIds = mediaIds.toSet();
      if (uniqueIds.length != mediaIds.length) {
        throw Exception('Duplicate media IDs detected in batch operation');
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
        if (media.type == 'diary') {
          // Handle diary entries with attachments
          if (media is DiaryEntryModel) {
            // Delete all attachment files
            for (final attachment in media.attachments) {
              if (attachment.url.isNotEmpty) {
                try {
                  await _storageService.deleteFile(attachment.url);
                } catch (e) {
                  storageErrors.add('Failed to delete attachment ${attachment.id}: ${ErrorHandler.getErrorMessage(e)}');
                }
              }
            }
          }
        } else if (media.url.isNotEmpty && media.type != 'text') {
          // Handle regular media files
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

  // Create diary entry
  Future<String> createDiaryEntry({
    required String folderId,
    required DiaryEntryModel diary,
    required String userId,
    bool isSharedFolder = false,
  }) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Validate diary content
      if (diary.title?.isEmpty ?? true) {
        throw Exception('Diary title is required');
      }

      if (diary.content.isEmpty) {
        throw Exception('Diary content is required');
      }

      final ref = _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .doc();

      // Create diary data with contributor attribution
      final diaryData = diary.toMap();
      
      if (isSharedFolder) {
        diaryData['uploadedBy'] = userId;
        diaryData['uploadedAt'] = Timestamp.fromDate(DateTime.now());
      }

      // Only set creation timestamp if not already set (for new entries)
      if (diary.id.isEmpty) {
        diaryData['createdAt'] = Timestamp.fromDate(DateTime.now());
      }
      diaryData['lastModified'] = Timestamp.fromDate(DateTime.now());

      await ref.set(diaryData);
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create diary entry: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Update diary entry
  Future<void> updateDiaryEntry({
    required String folderId,
    required String diaryId,
    required DiaryEntryModel diary,
    required String userId,
  }) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (diaryId.isEmpty) {
        throw Exception('Diary ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Validate diary content
      if (diary.title?.isEmpty ?? true) {
        throw Exception('Diary title is required');
      }

      if (diary.content.isEmpty) {
        throw Exception('Diary content is required');
      }

      // Prepare update data
      final updateData = diary.toMap();
      updateData['lastModified'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .doc(diaryId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to update diary entry: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Upload media attachment for diary entry
  Future<DiaryMediaAttachment> uploadDiaryAttachment({
    required String folderId,
    required String userId,
    required File mediaFile,
    required String mediaType, // 'image', 'video', 'audio'
    required int position,
    String? caption,
    Function(double progress)? onProgress,
  }) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Validate the attachment
      final validationError = ValidationUtils.validateDiaryAttachment(mediaFile, mediaType, position);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Generate unique filename
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = mediaType == 'image' ? 'jpg' : 
                       mediaType == 'video' ? 'mp4' : 'm4a';
      final storagePath = 'users/$userId/folders/$folderId/diary_attachments/$fileName.$extension';
      
      // Read file bytes
      final fileBytes = await mediaFile.readAsBytes();
      
      // Upload to Firebase Storage with retry mechanism
      final url = await UploadUtils.uploadWithRetry(
        uploadFunction: () => _storageService.uploadFileBytes(fileBytes, storagePath),
        onProgress: onProgress,
        onStatusUpdate: (msg) => debugPrint('Diary attachment upload: $msg'),
      );
      
      // Create attachment model
      return DiaryMediaAttachment(
        id: fileName,
        type: mediaType,
        url: url,
        caption: caption,
        position: position,
      );
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload diary attachment: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Get diary entry by ID
  Future<DiaryEntryModel?> getDiaryEntry(String folderId, String diaryId) async {
    try {
      if (folderId.isEmpty) {
        throw Exception('Folder ID is required');
      }

      if (diaryId.isEmpty) {
        throw Exception('Diary ID is required');
      }

      final doc = await _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .doc(diaryId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] != 'diary') {
        throw Exception('Document is not a diary entry');
      }

      return DiaryEntryModel.fromDoc(doc);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get diary entry: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Helper method to show camera confirmation screen
  Future<bool> _showCameraConfirmation({
    required BuildContext context,
    required XFile capturedMedia,
    required String mediaType,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CameraConfirmationScreen(
          capturedMedia: capturedMedia,
          mediaType: mediaType,
          onConfirmation: (confirmed) => Navigator.of(context).pop(confirmed),
        ),
        fullscreenDialog: true,
      ),
    );
    return result ?? false;
  }

  // Get favorite diary entries for nostalgia reminders
  Stream<List<DiaryEntryModel>> getFavoriteEntriesForToday(String folderId) {
    final now = DateTime.now();
    final todayMonth = now.month;
    final todayDay = now.day;
    final thisYear = now.year;
    
    return _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .where('type', isEqualTo: 'diary')
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntryModel.fromDoc(doc))
            .where((entry) {
              final diaryDate = entry.diaryDate.toDate();
              return diaryDate.month == todayMonth &&
                  diaryDate.day == todayDay &&
                  diaryDate.year < thisYear;
            })
            .toList());
  }

  // Toggle favorite status for a diary entry
  Future<void> toggleDiaryFavorite({
    required String folderId,
    required String diaryId,
    required bool isFavorite,
  }) async {
    try {
      await _firestore
          .collection('folders')
          .doc(folderId)
          .collection('media')
          .doc(diaryId)
          .update({
        'isFavorite': isFavorite,
        'lastModified': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to update favorite status: ${ErrorHandler.getErrorMessage(e)}');
    }
  }
}