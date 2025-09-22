import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? title;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.title,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _position == Duration.zero;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _position = position;
          _isLoading = false;
        });
      }
    });

    // Listen for completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoading = true;
        });
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Make the widget more responsive to available space
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're in a compact mode (like a dialog)
        final isCompact = constraints.maxHeight < 400;
        final iconSize = isCompact ? 80.0 : 120.0;
        final iconIconSize = isCompact ? 40.0 : 60.0;
        final spacing = isCompact ? 16.0 : 32.0;
        final padding = isCompact ? 16.0 : 24.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Audio icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.audiotrack,
                  size: iconIconSize,
                  color: AppColors.primaryAccent,
                ),
              ),
              
              SizedBox(height: spacing),
              
              // Title
              if (widget.title != null && widget.title!.isNotEmpty)
                Text(
                  widget.title!,
                  style: (isCompact ? AppTypography.titleMedium : AppTypography.headlineSmall).copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              if (widget.title != null && widget.title!.isNotEmpty)
                SizedBox(height: spacing),
              
              // Progress bar
              Column(
                children: [
                  Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                    onChanged: (value) {
                      final position = Duration(
                        milliseconds: (value * _duration.inMilliseconds).round(),
                      );
                      _seekTo(position);
                    },
                    activeColor: AppColors.primaryAccent,
                    inactiveColor: AppColors.primaryAccent.withValues(alpha: 0.3),
                  ),
                  
                  // Time labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: spacing),
              
              // Play/Pause button
              Container(
                width: isCompact ? 60 : 80,
                height: isCompact ? 60 : 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(isCompact ? 30 : 40),
                    onTap: _togglePlayPause,
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: isCompact ? 20 : 24,
                              height: isCompact ? 20 : 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.surfacePrimary,
                                ),
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: isCompact ? 28 : 36,
                              color: AppColors.surfacePrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}