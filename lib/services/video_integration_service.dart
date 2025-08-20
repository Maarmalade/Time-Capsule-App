import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';
import '../pages/video_player_page.dart';
import 'video_service.dart';

class VideoIntegrationService {
  static final VideoService _videoService = VideoService();

  /// Show video player in a modal dialog
  static void showVideoDialog(BuildContext context, String videoUrl, {String? title}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 400,
          ),
          child: VideoPlayerWidget(
            videoUrl: videoUrl,
            autoPlay: true,
            showControls: true,
            onError: (error) => _handleVideoError(context, error),
          ),
        ),
      ),
    );
  }

  /// Navigate to full-screen video player
  static void showFullScreenVideo(
    BuildContext context, 
    String videoUrl, {
    String? title,
    bool allowFullscreen = true,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          videoUrl: videoUrl,
          title: title ?? 'Video Player',
          allowFullscreen: allowFullscreen,
        ),
      ),
    );
  }

  /// Create a video thumbnail widget with play button
  static Widget createVideoThumbnail({
    required String videoUrl,
    required VoidCallback onTap,
    double width = 120,
    double height = 80,
    String? title,
  }) {
    return VideoThumbnailWidget(
      videoUrl: videoUrl,
      width: width,
      height: height,
      onTap: onTap,
    );
  }

  /// Create an inline video player widget
  static Widget createInlineVideoPlayer({
    required String videoUrl,
    bool autoPlay = false,
    bool showControls = true,
    double? aspectRatio,
    Function(String)? onError,
  }) {
    return VideoPlayerWidget(
      videoUrl: videoUrl,
      autoPlay: autoPlay,
      showControls: showControls,
      aspectRatio: aspectRatio,
      onError: onError,
    );
  }

  /// Upload video for scheduled messages
  static Future<String> uploadScheduledMessageVideo(File videoFile, String messageId) async {
    return await _videoService.uploadScheduledMessageVideo(videoFile, messageId);
  }

  /// Upload video for digital diary
  static Future<String> uploadDiaryVideo(File videoFile, String entryId) async {
    return await _videoService.uploadDiaryVideo(videoFile, entryId);
  }

  /// Upload video for memory album
  static Future<String> uploadMemoryAlbumVideo(File videoFile, String albumId) async {
    return await _videoService.uploadMemoryAlbumVideo(videoFile, albumId);
  }

  /// Upload video for folder media
  static Future<String> uploadFolderVideo(File videoFile, String folderId) async {
    return await _videoService.uploadFolderVideo(videoFile, folderId);
  }

  /// Check if a URL is a video
  static Future<bool> isVideoUrl(String url) async {
    return await _videoService.isVideoUrl(url);
  }

  /// Delete a video
  static Future<void> deleteVideo(String videoUrl) async {
    await _videoService.deleteVideo(videoUrl);
  }

  /// Get video metadata
  static Future<Map<String, dynamic>?> getVideoMetadata(String videoUrl) async {
    return await _videoService.getVideoMetadata(videoUrl);
  }

  /// Handle video errors consistently across the app
  static void _handleVideoError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video error: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show video options bottom sheet
  static void showVideoOptionsBottomSheet(
    BuildContext context, {
    required String videoUrl,
    String? title,
    VoidCallback? onDownload,
    VoidCallback? onShare,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play Video'),
              onTap: () {
                Navigator.of(context).pop();
                showFullScreenVideo(context, videoUrl, title: title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Play in Dialog'),
              onTap: () {
                Navigator.of(context).pop();
                showVideoDialog(context, videoUrl, title: title);
              },
            ),
            if (onShare != null)
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Video'),
                onTap: () {
                  Navigator.of(context).pop();
                  onShare();
                },
              ),
            if (onDownload != null)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download Video'),
                onTap: () {
                  Navigator.of(context).pop();
                  onDownload();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Video'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(context, onDelete);
                },
              ),
          ],
        ),
      ),
    );
  }

  static void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}