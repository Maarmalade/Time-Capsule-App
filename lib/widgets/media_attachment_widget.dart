import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/error_handler.dart';

import '../services/video_integration_service.dart';

class MediaAttachmentWidget extends StatefulWidget {
  final List<File> selectedImages;
  final File? selectedVideo;
  final Function(List<File>) onImagesChanged;
  final Function(File?) onVideoChanged;
  final int maxImages;
  final int maxImageSizeMB;
  final int maxVideoSizeMB;

  const MediaAttachmentWidget({
    super.key,
    required this.selectedImages,
    this.selectedVideo,
    required this.onImagesChanged,
    required this.onVideoChanged,
    this.maxImages = 5,
    this.maxImageSizeMB = 10,
    this.maxVideoSizeMB = 50,
  });

  @override
  State<MediaAttachmentWidget> createState() => _MediaAttachmentWidgetState();
}

class _MediaAttachmentWidgetState extends State<MediaAttachmentWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _validationError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media selection buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _canAddMoreImages() ? _selectImages : null,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  'Add Images (${widget.selectedImages.length}/${widget.maxImages})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.selectedVideo == null ? _selectVideo : _removeVideo,
                icon: Icon(
                  widget.selectedVideo == null ? Icons.videocam : Icons.videocam_off,
                ),
                label: Text(
                  widget.selectedVideo == null ? 'Add Video' : 'Remove Video',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.selectedVideo == null
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: widget.selectedVideo == null
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),

        // Validation error display
        if (_validationError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Selected media preview
        if (widget.selectedImages.isNotEmpty || widget.selectedVideo != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Selected Media:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Images preview
        if (widget.selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedImages.length,
              itemBuilder: (context, index) {
                final image = widget.selectedImages[index];
                return _buildImagePreview(image, index);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Video preview
        if (widget.selectedVideo != null) ...[
          _buildVideoPreview(widget.selectedVideo!),
        ],
      ],
    );
  }

  bool _canAddMoreImages() {
    return widget.selectedImages.length < widget.maxImages;
  }

  Future<void> _selectImages() async {
    try {
      setState(() {
        _validationError = null;
      });

      // Check if we can add more images
      if (widget.selectedImages.length >= widget.maxImages) {
        setState(() {
          _validationError = 'Maximum ${widget.maxImages} images allowed. Remove some images to add more.';
        });
        return;
      }

      // Use pickImage with gallery source for single image selection
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        
        // Basic file validation
        final fileSize = await file.length();
        final maxSize = widget.maxImageSizeMB * 1024 * 1024;
        
        if (fileSize > maxSize) {
          setState(() {
            _validationError = 'Image file is too large. Maximum size is ${widget.maxImageSizeMB}MB.';
          });
          return;
        }
        
        final extension = file.path.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          setState(() {
            _validationError = 'Please select a valid image file (JPG, PNG, GIF, WebP).';
          });
          return;
        }

        final updatedImages = [...widget.selectedImages, file];
        widget.onImagesChanged(updatedImages);
      }
    } catch (e) {
      setState(() {
        _validationError = 'Failed to select image: ${ErrorHandler.getErrorMessage(e)}';
      });
    }
  }

  Future<void> _selectVideo() async {
    try {
      setState(() {
        _validationError = null;
      });

      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        
        // Basic file validation
        final fileSize = await file.length();
        final maxSize = widget.maxVideoSizeMB * 1024 * 1024;
        
        if (fileSize > maxSize) {
          setState(() {
            _validationError = 'Video file is too large. Maximum size is ${widget.maxVideoSizeMB}MB.';
          });
          return;
        }
        
        final extension = file.path.toLowerCase().split('.').last;
        if (!['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
          setState(() {
            _validationError = 'Please select a valid video file (MP4, MOV, AVI, MKV, WebM).';
          });
          return;
        }

        widget.onVideoChanged(file);
      }
    } catch (e) {
      setState(() {
        _validationError = 'Failed to select video: ${ErrorHandler.getErrorMessage(e)}';
      });
    }
  }

  void _removeVideo() {
    widget.onVideoChanged(null);
  }

  void _removeImage(int index) {
    final updatedImages = List<File>.from(widget.selectedImages);
    updatedImages.removeAt(index);
    widget.onImagesChanged(updatedImages);
    
    // Clear validation error if it was about too many images
    if (_validationError?.contains('Maximum') == true && updatedImages.length < widget.maxImages) {
      setState(() {
        _validationError = null;
      });
    }
  }

  void _previewVideo(File video) {
    VideoIntegrationService.showFullScreenVideo(
      context,
      video.path,
      title: 'Video Preview',
    );
  }

  Widget _buildImagePreview(File image, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // Image preview
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ),
          
          // File size indicator
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: FutureBuilder<int>(
              future: image.length(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final sizeInMB = snapshot.data! / (1024 * 1024);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${sizeInMB.toStringAsFixed(1)}MB',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(File video) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          // Video thumbnail placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Video Selected',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Play indicator - make it tappable
          Center(
            child: GestureDetector(
              onTap: () => _previewVideo(video),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 30,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _removeVideo,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ),
          
          // File size and name
          Positioned(
            bottom: 8,
            left: 8,
            right: 48, // Leave space for remove button
            child: FutureBuilder<int>(
              future: video.length(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final sizeInMB = snapshot.data! / (1024 * 1024);
                  final fileName = video.path.split('/').last;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${sizeInMB.toStringAsFixed(1)}MB',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}