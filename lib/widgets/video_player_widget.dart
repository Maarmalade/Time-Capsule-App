import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final double? aspectRatio;
  final Widget? placeholder;
  final Function(String)? onError;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio,
    this.placeholder,
    this.onError,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Validate video URL
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      if (!widget.videoUrl.startsWith('https://') && !widget.videoUrl.startsWith('/')) {
        throw Exception('Invalid video URL format');
      }

      // Initialize video player controller
      if (widget.videoUrl.startsWith('http')) {
        // Network URL
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
      } else {
        // Local file path
        _videoPlayerController = VideoPlayerController.file(
          File(widget.videoUrl),
        );
      }

      await _videoPlayerController!.initialize();

      // Initialize Chewie controller for better video controls
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: false,
        showControls: widget.showControls,
        aspectRatio: widget.aspectRatio ?? _videoPlayerController!.value.aspectRatio,
        placeholder: widget.placeholder ?? Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Video playback error',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      widget.onError?.call(e.toString());
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 200,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController == null) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Text(
            'Video player not initialized',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}

/// A simple video thumbnail widget that shows a play button overlay
class VideoThumbnailWidget extends StatelessWidget {
  final String videoUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.width = 120,
    this.height = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video icon background
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.videocam,
                color: Colors.white54,
                size: 32,
              ),
            ),
            // Play button overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}