import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';

class VideoService {
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload a video for scheduled messages
  Future<String> uploadScheduledMessageVideo(File videoFile, String messageId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final path = 'scheduled_messages/$messageId/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return await _storageService.uploadVideo(videoFile, path);
  }

  /// Upload a video for digital diary
  Future<String> uploadDiaryVideo(File videoFile, String entryId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final path = 'diary/$userId/$entryId/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return await _storageService.uploadVideo(videoFile, path);
  }

  /// Upload a video for memory album
  Future<String> uploadMemoryAlbumVideo(File videoFile, String albumId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final path = 'memory_albums/$albumId/media/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return await _storageService.uploadVideo(videoFile, path);
  }

  /// Upload a video for folder media
  Future<String> uploadFolderVideo(File videoFile, String folderId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final path = 'folders/$folderId/media/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return await _storageService.uploadVideo(videoFile, path);
  }

  /// Get video download URL with proper error handling
  Future<String> getVideoUrl(String videoPath) async {
    return await _storageService.getVideoDownloadUrl(videoPath);
  }

  /// Check if a URL points to a video file
  Future<bool> isVideoUrl(String url) async {
    return await _storageService.isVideoFile(url);
  }

  /// Delete a video file
  Future<void> deleteVideo(String videoUrl) async {
    await _storageService.deleteFile(videoUrl);
  }

  /// Get video file metadata
  Future<Map<String, dynamic>?> getVideoMetadata(String videoUrl) async {
    final metadata = await _storageService.getFileMetadata(videoUrl);
    if (metadata == null) return null;

    return {
      'contentType': metadata.contentType,
      'size': metadata.size,
      'timeCreated': metadata.timeCreated,
      'updated': metadata.updated,
      'name': metadata.name,
    };
  }
}