import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/video_player_widget.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final bool allowFullscreen;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    this.title,
    this.allowFullscreen = true,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    // Set preferred orientations for video playback
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation when leaving video player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: VideoPlayerWidget(
                videoUrl: widget.videoUrl,
                autoPlay: true,
                showControls: true,
                onError: (error) => _handleVideoError(context, error),
              ),
            ),
            if (widget.allowFullscreen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 10,
                child: IconButton(
                  onPressed: _toggleFullscreen,
                  icon: const Icon(
                    Icons.fullscreen_exit,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Video Player'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (widget.allowFullscreen)
            IconButton(
              onPressed: _toggleFullscreen,
              icon: const Icon(Icons.fullscreen),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: VideoPlayerWidget(
          videoUrl: widget.videoUrl,
          autoPlay: true,
          showControls: true,
          onError: (error) => _handleVideoError(context, error),
        ),
      ),
    );
  }

  void _handleVideoError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video playback error: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Trigger a rebuild to retry video loading
            setState(() {});
          },
        ),
      ),
    );
  }
}