import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'permission_service.dart';

enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
  error,
}

enum AudioError {
  permissionDenied,
  deviceNotAvailable,
  recordingFailed,
  playbackFailed,
  fileNotFound,
  corruptedFile,
  storageError,
  networkError,
  unknown,
}

class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  // State management streams
  final StreamController<RecordingState> _recordingStateController = 
      StreamController<RecordingState>.broadcast();
  final StreamController<Duration> _recordingDurationController = 
      StreamController<Duration>.broadcast();
  final StreamController<double> _amplitudeController = 
      StreamController<double>.broadcast();
  final StreamController<AudioError> _errorController = 
      StreamController<AudioError>.broadcast();

  // Private state variables
  RecordingState _currentState = RecordingState.idle;
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;
  AudioError? _lastError;
  int _retryCount = 0;
  
  // Maximum recording duration (10 minutes)
  static const Duration maxRecordingDuration = Duration(minutes: 10);
  
  // Maximum retry attempts for failed operations
  static const int maxRetryAttempts = 3;
  
  // List of temporary files to clean up
  final List<String> _tempFilesToCleanup = [];

  // Getters for streams
  Stream<RecordingState> get recordingStateStream => _recordingStateController.stream;
  Stream<Duration> get recordingDurationStream => _recordingDurationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<AudioError> get errorStream => _errorController.stream;

  // Getters for current state
  RecordingState get currentState => _currentState;
  Duration get currentDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  AudioError? get lastError => _lastError;

  /// Start recording audio to the specified output path
  Future<bool> startRecording([String? outputPath]) async {
    try {
      // Reset error state
      _lastError = null;
      _retryCount = 0;
      
      // Check microphone permission using PermissionService
      final hasPermission = await PermissionService.requestMicrophonePermission();
      if (!hasPermission) {
        _handleError(AudioError.permissionDenied, 'Microphone permission denied');
        return false;
      }

      // Check if device supports recording
      final hasCapability = await _recorder.hasPermission();
      if (!hasCapability) {
        _handleError(AudioError.deviceNotAvailable, 'Recording device not available');
        return false;
      }

      // Generate output path if not provided
      if (outputPath == null) {
        try {
          final directory = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          outputPath = '${directory.path}/recording_$timestamp.m4a';
        } catch (e) {
          _handleError(AudioError.storageError, 'Cannot access storage for recording');
          return false;
        }
      }

      // Ensure directory exists
      final file = File(outputPath);
      final directory = file.parent;
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          _handleError(AudioError.storageError, 'Cannot create recording directory');
          return false;
        }
      }

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Start recording with error handling
      try {
        await _recorder.start(config, path: outputPath);
      } catch (e) {
        _handleError(AudioError.recordingFailed, 'Failed to start recording: ${e.toString()}');
        return false;
      }
      
      _currentRecordingPath = outputPath;
      _tempFilesToCleanup.add(outputPath);
      _recordingDuration = Duration.zero;
      _updateState(RecordingState.recording);
      
      // Start duration timer
      _startDurationTimer();
      
      // Start amplitude monitoring
      _startAmplitudeMonitoring();
      
      return true;
    } catch (e) {
      _handleError(AudioError.unknown, 'Unexpected error starting recording: ${e.toString()}');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      
      _stopTimers();
      
      // Validate the recorded file
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 0) {
            _updateState(RecordingState.stopped);
            return path;
          } else {
            _handleError(AudioError.corruptedFile, 'Recording file is empty');
            await _cleanupFile(path);
            return null;
          }
        } else {
          _handleError(AudioError.fileNotFound, 'Recording file not found');
          return null;
        }
      } else {
        _handleError(AudioError.recordingFailed, 'Recording failed to produce a file');
        return null;
      }
    } catch (e) {
      _handleError(AudioError.recordingFailed, 'Error stopping recording: ${e.toString()}');
      _stopTimers();
      _updateState(RecordingState.error);
      return null;
    }
  }

  /// Pause the current recording
  Future<bool> pauseRecording() async {
    try {
      if (_currentState != RecordingState.recording) {
        return false;
      }

      await _recorder.pause();
      _stopTimers();
      _updateState(RecordingState.paused);
      
      return true;
    } catch (e) {
      _handleError(AudioError.recordingFailed, 'Error pausing recording: ${e.toString()}');
      return false;
    }
  }

  /// Resume a paused recording
  Future<bool> resumeRecording() async {
    try {
      if (_currentState != RecordingState.paused) {
        return false;
      }

      await _recorder.resume();
      _startDurationTimer();
      _startAmplitudeMonitoring();
      _updateState(RecordingState.recording);
      
      return true;
    } catch (e) {
      _handleError(AudioError.recordingFailed, 'Error resuming recording: ${e.toString()}');
      return false;
    }
  }

  /// Cancel the current recording and clean up
  Future<void> cancelRecording() async {
    try {
      // Stop recording if active
      if (_currentState == RecordingState.recording || _currentState == RecordingState.paused) {
        try {
          await _recorder.stop();
        } catch (e) {
          debugPrint('Error stopping recorder during cancel: $e');
        }
      }
      
      _stopTimers();
      
      // Clean up the current recording file
      if (_currentRecordingPath != null) {
        await _cleanupFile(_currentRecordingPath!);
      }
      
      // Clean up all temporary files
      await _cleanupAllTempFiles();
      
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
      _lastError = null;
      _updateState(RecordingState.idle);
    } catch (e) {
      debugPrint('Error canceling recording: $e');
      // Still reset state even if cleanup fails
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
      _updateState(RecordingState.idle);
    }
  }

  /// Play the recorded audio file for review
  Future<bool> playRecording(String filePath) async {
    try {
      // Validate file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        _handleError(AudioError.fileNotFound, 'Audio file not found: $filePath');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        _handleError(AudioError.corruptedFile, 'Audio file is empty or corrupted');
        return false;
      }

      // Attempt to play the file
      await _player.play(DeviceFileSource(filePath));
      return true;
    } catch (e) {
      _handleError(AudioError.playbackFailed, 'Error playing recording: ${e.toString()}');
      return false;
    }
  }

  /// Stop audio playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (e) {
      _handleError(AudioError.playbackFailed, 'Error stopping playback: ${e.toString()}');
    }
  }

  /// Get the duration of an audio file
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        _handleError(AudioError.fileNotFound, 'Audio file not found: $filePath');
        return null;
      }

      await _player.setSource(DeviceFileSource(filePath));
      return await _player.getDuration();
    } catch (e) {
      _handleError(AudioError.playbackFailed, 'Error getting audio duration: ${e.toString()}');
      return null;
    }
  }

  /// Check if the device has recording capability
  Future<bool> hasRecordingCapability() async {
    return await PermissionService.isMicrophonePermissionGranted();
  }

  /// Reset the service to initial state
  Future<void> reset() async {
    try {
      await stopPlayback();
      await cancelRecording();
      await _cleanupAllTempFiles();
      _recordingDuration = Duration.zero;
      _currentRecordingPath = null;
      _lastError = null;
      _retryCount = 0;
      _updateState(RecordingState.idle);
    } catch (e) {
      debugPrint('Error resetting audio service: $e');
      // Force reset even if cleanup fails
      _recordingDuration = Duration.zero;
      _currentRecordingPath = null;
      _lastError = null;
      _retryCount = 0;
      _updateState(RecordingState.idle);
    }
  }

  /// Check if recording is currently possible (has permission and capability)
  Future<bool> canRecord() async {
    try {
      final hasPermission = await PermissionService.isMicrophonePermissionGranted();
      final hasCapability = await _recorder.hasPermission();
      return hasPermission && hasCapability;
    } catch (e) {
      _handleError(AudioError.unknown, 'Error checking recording capability: ${e.toString()}');
      return false;
    }
  }

  /// Retry a failed recording operation
  Future<bool> retryLastOperation() async {
    if (_retryCount >= maxRetryAttempts) {
      _handleError(AudioError.unknown, 'Maximum retry attempts exceeded');
      return false;
    }

    _retryCount++;
    
    // Wait before retrying
    await Future.delayed(Duration(seconds: _retryCount));
    
    // Retry based on last error
    switch (_lastError) {
      case AudioError.recordingFailed:
        return await startRecording();
      case AudioError.playbackFailed:
        if (_currentRecordingPath != null) {
          return await playRecording(_currentRecordingPath!);
        }
        return false;
      default:
        return false;
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(AudioError error) {
    switch (error) {
      case AudioError.permissionDenied:
        return 'Microphone permission is required for recording. Please grant permission in settings.';
      case AudioError.deviceNotAvailable:
        return 'Recording device is not available. Please check your microphone.';
      case AudioError.recordingFailed:
        return 'Recording failed. Please try again.';
      case AudioError.playbackFailed:
        return 'Cannot play audio. Please check the file.';
      case AudioError.fileNotFound:
        return 'Audio file not found. The recording may have been deleted.';
      case AudioError.corruptedFile:
        return 'Audio file is corrupted or empty. Please record again.';
      case AudioError.storageError:
        return 'Cannot access storage. Please check available space.';
      case AudioError.networkError:
        return 'Network error occurred. Please check your connection.';
      case AudioError.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Private method to update recording state
  void _updateState(RecordingState newState) {
    _currentState = newState;
    _recordingStateController.add(newState);
  }

  /// Private method to start duration timer
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _recordingDuration = Duration(milliseconds: _recordingDuration.inMilliseconds + 100);
      _recordingDurationController.add(_recordingDuration);
      
      // Check for maximum duration
      if (_recordingDuration >= maxRecordingDuration) {
        stopRecording();
      }
    });
  }

  /// Private method to start amplitude monitoring
  void _startAmplitudeMonitoring() {
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        final normalizedAmplitude = amplitude.current.clamp(-60.0, 0.0);
        // Convert dB to 0-1 range for UI
        final uiAmplitude = (normalizedAmplitude + 60.0) / 60.0;
        _amplitudeController.add(uiAmplitude);
      } catch (e) {
        // Ignore amplitude errors during recording
      }
    });
  }

  /// Private method to stop all timers
  void _stopTimers() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _durationTimer = null;
    _amplitudeTimer = null;
  }

  /// Handle errors and update error state
  void _handleError(AudioError error, String message) {
    _lastError = error;
    _updateState(RecordingState.error);
    _errorController.add(error);
    debugPrint('AudioRecordingService Error: $message');
  }

  /// Clean up a specific file
  Future<void> _cleanupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Cleaned up audio file: $filePath');
      }
      _tempFilesToCleanup.remove(filePath);
    } catch (e) {
      debugPrint('Failed to cleanup audio file $filePath: $e');
    }
  }

  /// Clean up all temporary files
  Future<void> _cleanupAllTempFiles() async {
    final filesToCleanup = List<String>.from(_tempFilesToCleanup);
    _tempFilesToCleanup.clear();
    
    for (final filePath in filesToCleanup) {
      await _cleanupFile(filePath);
    }
  }

  /// Dispose of resources
  void dispose() {
    _stopTimers();
    
    // Clean up temporary files
    _cleanupAllTempFiles().catchError((e) {
      debugPrint('Error cleaning up temp files during dispose: $e');
    });
    
    _recorder.dispose();
    _player.dispose();
    _recordingStateController.close();
    _recordingDurationController.close();
    _amplitudeController.close();
    _errorController.close();
  }
}