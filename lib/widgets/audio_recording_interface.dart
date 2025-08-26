import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_recording_service.dart';
import '../services/permission_service.dart';
import '../utils/accessibility_utils.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';

class AudioRecordingInterface extends StatefulWidget {
  final Function(String) onRecordingComplete;
  final Function() onCancel;

  const AudioRecordingInterface({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<AudioRecordingInterface> createState() => _AudioRecordingInterfaceState();
}

class _AudioRecordingInterfaceState extends State<AudioRecordingInterface>
    with TickerProviderStateMixin {
  final AudioRecordingService _audioService = AudioRecordingService();
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  // State variables
  RecordingState _recordingState = RecordingState.idle;
  Duration _recordingDuration = Duration.zero;
  double _amplitude = 0.0;
  String? _recordingPath;
  bool _isPlaying = false;
  
  // Stream subscriptions
  StreamSubscription<RecordingState>? _stateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupStreamListeners();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupStreamListeners() {
    _stateSubscription = _audioService.recordingStateStream.listen((state) {
      setState(() {
        _recordingState = state;
      });
      
      if (state == RecordingState.recording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
    
    _durationSubscription = _audioService.recordingDurationStream.listen((duration) {
      setState(() {
        _recordingDuration = duration;
      });
    });
    
    _amplitudeSubscription = _audioService.amplitudeStream.listen((amplitude) {
      setState(() {
        _amplitude = amplitude;
      });
      _waveController.forward().then((_) => _waveController.reset());
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check permission first
      final hasPermission = await PermissionService.requestMicrophonePermission();
      if (!hasPermission) {
        if (mounted) {
          await PermissionService.showPermissionDeniedDialog(context, 'microphone');
        }
        return;
      }

      // Check recording capability
      final canRecord = await _audioService.canRecord();
      if (!canRecord) {
        _showErrorDialog('Recording is not available on this device.');
        return;
      }

      final success = await _audioService.startRecording();
      if (!success) {
        _showErrorDialog('Failed to start recording. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioService.stopRecording();
      if (path != null) {
        setState(() {
          _recordingPath = path;
        });
      } else {
        _showErrorDialog('Failed to save recording. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error stopping recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      final success = await _audioService.pauseRecording();
      if (!success) {
        _showErrorDialog('Failed to pause recording.');
      }
    } catch (e) {
      _showErrorDialog('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      final success = await _audioService.resumeRecording();
      if (!success) {
        _showErrorDialog('Failed to resume recording.');
      }
    } catch (e) {
      _showErrorDialog('Error resuming recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null) {
      try {
        setState(() {
          _isPlaying = true;
        });
        
        final success = await _audioService.playRecording(_recordingPath!);
        if (!success) {
          setState(() {
            _isPlaying = false;
          });
          _showErrorDialog('Failed to play recording.');
          return;
        }
        
        // Get actual duration and stop playing when done
        final duration = await _audioService.getAudioDuration(_recordingPath!);
        if (duration != null) {
          Timer(duration, () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
              });
            }
          });
        } else {
          // Fallback timer
          Timer(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
              });
            }
          });
        }
      } catch (e) {
        setState(() {
          _isPlaying = false;
        });
        _showErrorDialog('Error playing recording: $e');
      }
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioService.stopPlayback();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
      _showErrorDialog('Error stopping playback: $e');
    }
  }

  Future<void> _saveRecording() async {
    if (_recordingPath != null) {
      widget.onRecordingComplete(_recordingPath!);
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioService.cancelRecording();
      widget.onCancel();
    } catch (e) {
      // Even if cleanup fails, still call onCancel to close the interface
      debugPrint('Error canceling recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _reRecord() async {
    try {
      await _audioService.reset();
      setState(() {
        _recordingPath = null;
        _recordingDuration = Duration.zero;
        _amplitude = 0.0;
      });
    } catch (e) {
      _showErrorDialog('Error resetting recording: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        title: Text(
          'Audio Recording',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surfacePrimary,
        elevation: 0,
        leading: Semantics(
          label: AccessibilityUtils.createSemanticLabel(
            label: 'Cancel recording',
            hint: 'Close audio recording interface without saving',
            isButton: true,
          ),
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _cancelRecording,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pageAll,
          child: Column(
            children: [
              // Duration Display
              Semantics(
                label: AccessibilityUtils.createSemanticLabel(
                  label: 'Recording duration',
                  value: _formatDuration(_recordingDuration),
                ),
                liveRegion: true,
                child: Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Text(
                    _formatDuration(_recordingDuration),
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Waveform Visualization
              Expanded(
                child: Semantics(
                  label: AccessibilityUtils.createSemanticLabel(
                    label: 'Audio waveform visualization',
                    hint: _recordingState == RecordingState.recording 
                      ? 'Recording in progress, waveform shows audio levels'
                      : 'Audio waveform display',
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: _buildWaveformVisualization(),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Control Buttons
              _buildControlButtons(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Action Buttons (when recording is stopped)
              if (_recordingState == RecordingState.stopped && _recordingPath != null)
                _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformVisualization() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: WaveformPainter(
            amplitude: _amplitude,
            isRecording: _recordingState == RecordingState.recording,
            animationValue: _waveController.value,
          ),
          size: const Size(double.infinity, 100),
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume button (only show when recording or paused)
        if (_recordingState == RecordingState.recording || 
            _recordingState == RecordingState.paused) ...[
          _buildControlButton(
            icon: _recordingState == RecordingState.recording 
                ? Icons.pause 
                : Icons.play_arrow,
            onPressed: _recordingState == RecordingState.recording 
                ? _pauseRecording 
                : _resumeRecording,
            backgroundColor: AppColors.warningAmber,
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        
        // Main record/stop button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _recordingState == RecordingState.recording 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: _buildMainRecordButton(),
            );
          },
        ),
        
        // Stop button (only show when recording or paused)
        if (_recordingState == RecordingState.recording || 
            _recordingState == RecordingState.paused) ...[
          const SizedBox(width: AppSpacing.lg),
          _buildControlButton(
            icon: Icons.stop,
            onPressed: _stopRecording,
            backgroundColor: AppColors.errorRed,
          ),
        ],
      ],
    );
  }

  Widget _buildMainRecordButton() {
    IconData icon;
    Color backgroundColor;
    VoidCallback? onPressed;
    String label;
    String hint;
    
    switch (_recordingState) {
      case RecordingState.idle:
        icon = Icons.mic;
        backgroundColor = AppColors.primaryAccent;
        onPressed = _startRecording;
        label = 'Start recording';
        hint = 'Begin audio recording';
        break;
      case RecordingState.recording:
        icon = Icons.mic;
        backgroundColor = AppColors.errorRed;
        onPressed = null; // Handled by other buttons
        label = 'Recording in progress';
        hint = 'Use pause or stop buttons to control recording';
        break;
      case RecordingState.paused:
        icon = Icons.mic;
        backgroundColor = AppColors.warningAmber;
        onPressed = null; // Handled by other buttons
        label = 'Recording paused';
        hint = 'Use resume or stop buttons to control recording';
        break;
      case RecordingState.stopped:
        icon = Icons.mic;
        backgroundColor = AppColors.primaryAccent;
        onPressed = _startRecording;
        label = 'Start new recording';
        hint = 'Begin a new audio recording';
        break;
      case RecordingState.error:
        icon = Icons.mic;
        backgroundColor = AppColors.errorRed;
        onPressed = _startRecording;
        label = 'Recording error, tap to retry';
        hint = 'There was an error with recording, tap to try again';
        break;
    }
    
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: label,
        hint: hint,
        isButton: onPressed != null,
      ),
      button: onPressed != null,
      enabled: onPressed != null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(40),
            child: Icon(
              icon,
              size: 32,
              color: AppColors.primaryWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    String? label,
    String? hint,
  }) {
    String buttonLabel = label ?? '';
    String buttonHint = hint ?? '';
    
    // Determine label and hint based on icon if not provided
    if (label == null) {
      if (icon == Icons.pause) {
        buttonLabel = 'Pause recording';
        buttonHint = 'Pause the current recording';
      } else if (icon == Icons.play_arrow) {
        buttonLabel = 'Resume recording';
        buttonHint = 'Continue the paused recording';
      } else if (icon == Icons.stop) {
        buttonLabel = 'Stop recording';
        buttonHint = 'Stop recording and review';
      }
    }
    
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: buttonLabel,
        hint: buttonHint,
        isButton: true,
      ),
      button: true,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.primaryWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              label: _isPlaying ? 'Stop' : 'Play',
              icon: _isPlaying ? Icons.stop : Icons.play_arrow,
              onPressed: _isPlaying ? _stopPlayback : _playRecording,
              backgroundColor: AppColors.infoBlue,
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Save/Cancel/Re-record buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              label: 'Re-record',
              icon: Icons.refresh,
              onPressed: _reRecord,
              backgroundColor: AppColors.warningAmber,
            ),
            _buildActionButton(
              label: 'Cancel',
              icon: Icons.close,
              onPressed: _cancelRecording,
              backgroundColor: AppColors.errorRed,
            ),
            _buildActionButton(
              label: 'Save',
              icon: Icons.check,
              onPressed: _saveRecording,
              backgroundColor: AppColors.successGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    String hint = '';
    switch (label.toLowerCase()) {
      case 'play':
        hint = 'Play back the recorded audio';
        break;
      case 'stop':
        hint = 'Stop audio playback';
        break;
      case 're-record':
        hint = 'Delete current recording and start over';
        break;
      case 'cancel':
        hint = 'Cancel recording and return without saving';
        break;
      case 'save':
        hint = 'Save the recording and continue';
        break;
    }
    
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: label,
        hint: hint,
        isButton: true,
      ),
      button: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(28),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.primaryWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double amplitude;
  final bool isRecording;
  final double animationValue;

  WaveformPainter({
    required this.amplitude,
    required this.isRecording,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRecording ? AppColors.primaryAccent : AppColors.darkGray
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final barWidth = 4.0;
    final barSpacing = 2.0;
    final totalBarWidth = barWidth + barSpacing;
    final barCount = (size.width / totalBarWidth).floor();

    for (int i = 0; i < barCount; i++) {
      final x = i * totalBarWidth;
      
      // Create varying heights based on amplitude and position
      final baseHeight = isRecording ? amplitude * size.height * 0.8 : size.height * 0.1;
      final variation = sin((i * 0.5) + (animationValue * 2 * pi)) * 0.3;
      final barHeight = (baseHeight * (1 + variation)).clamp(4.0, size.height * 0.9);
      
      final rect = Rect.fromLTWH(
        x,
        centerY - barHeight / 2,
        barWidth,
        barHeight,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
           oldDelegate.isRecording != isRecording ||
           oldDelegate.animationValue != animationValue;
  }
}