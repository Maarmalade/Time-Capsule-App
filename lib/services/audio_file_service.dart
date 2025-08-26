import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Metadata information for audio files
class AudioFileMetadata {
  final String fileName;
  final String format;
  final int fileSizeBytes;
  final Duration? duration;

  AudioFileMetadata({
    required this.fileName,
    required this.format,
    required this.fileSizeBytes,
    this.duration,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDuration {
    if (duration == null) return 'Unknown';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'duration': duration?.inMilliseconds,
      'fileSizeBytes': fileSizeBytes,
      'format': format,
    };
  }

  /// Create from map
  factory AudioFileMetadata.fromMap(Map<String, dynamic> map) {
    return AudioFileMetadata(
      fileName: map['fileName'] ?? '',
      duration: map['duration'] != null ? Duration(milliseconds: map['duration']) : null,
      fileSizeBytes: map['fileSizeBytes'] ?? 0,
      format: map['format'] ?? '',
    );
  }
}

class AudioFileService {
  static final AudioFileService _instance = AudioFileService._internal();
  factory AudioFileService() => _instance;
  AudioFileService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Pick an audio file from device storage
  Future<File?> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Validate the audio file
        final validationError = _validateAudioFileBasic(file);
        if (validationError != null) {
          throw Exception(validationError);
        }
        
        // Additional validation for audio-specific properties
        final isValid = await _validateAudioFile(file);
        if (!isValid) {
          throw Exception('Selected file is not a valid audio file');
        }
        
        return file;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error picking audio file: $e');
      rethrow;
    }
  }

  /// Basic validation for audio file
  String? _validateAudioFileBasic(File file) {
    if (!file.existsSync()) {
      return 'Audio file does not exist';
    }
    
    final fileSize = file.lengthSync();
    if (fileSize == 0) {
      return 'Audio file is empty';
    }
    
    // Check file size limit (50MB)
    if (fileSize > 50 * 1024 * 1024) {
      return 'Audio file is too large (max 50MB)';
    }
    
    return null;
  }

  /// Validate audio file format and size
  Future<bool> _validateAudioFile(File file) async {
    try {
      // Check if file exists and is readable
      if (!await file.exists()) {
        debugPrint('Audio file does not exist');
        return false;
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('Audio file is empty');
        return false;
      }

      // Check file extension
      final fileName = file.path.toLowerCase();
      final lastDotIndex = fileName.lastIndexOf('.');
      if (lastDotIndex == -1) {
        debugPrint('Audio file has no extension');
        return false;
      }
      
      final extension = fileName.substring(lastDotIndex);
      const supportedFormats = [
        '.mp3',
        '.m4a',
        '.aac',
        '.wav',
        '.ogg',
        '.flac',
      ];
      
      if (!supportedFormats.contains(extension)) {
        debugPrint('Unsupported audio format: $extension');
        return false;
      }

      // Try to get duration to verify it's a valid audio file
      final duration = await getAudioDuration(file.path);
      if (duration == null || duration.inMilliseconds <= 0) {
        debugPrint('Could not read valid audio file duration');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating audio file: $e');
      return false;
    }
  }

  /// Get audio file duration
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Audio file not found: $filePath');
        return null;
      }

      // Set source and get duration with timeout
      await _player.setSource(DeviceFileSource(filePath));
      
      // Add timeout to prevent hanging
      final duration = await _player.getDuration().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Timeout getting audio duration for: $filePath');
          return null;
        },
      );
      
      return duration;
    } catch (e) {
      debugPrint('Error getting audio duration: $e');
      return null;
    }
  }

  /// Get audio file metadata
  Future<AudioFileMetadata?> getAudioMetadata(File file) async {
    try {
      // Validate file first
      if (!await file.exists()) {
        debugPrint('Audio file not found: ${file.path}');
        return null;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('Audio file is empty: ${file.path}');
        return null;
      }

      final duration = await getAudioDuration(file.path);
      if (duration == null) {
        debugPrint('Could not get duration for audio file: ${file.path}');
        return null;
      }

      final fileName = _getFileName(file.path);
      final extension = _getFileExtension(file.path);

      return AudioFileMetadata(
        fileName: fileName,
        duration: duration,
        fileSizeBytes: fileSize,
        format: extension.replaceFirst('.', '').toUpperCase(),
      );
    } catch (e) {
      debugPrint('Error getting audio metadata: $e');
      return null;
    }
  }

  /// Upload audio file to Firebase Storage
  Future<String?> uploadAudioFile({
    required File file,
    required String folderId,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final uniqueFileName = '${fileName}_$timestamp$extension';
      
      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('folders')
          .child(folderId)
          .child('audio')
          .child(uniqueFileName);

      // Upload file with progress tracking
      final uploadTask = storageRef.putFile(file);
      
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading audio file: $e');
      return null;
    }
  }

  /// Play audio file for preview
  Future<bool> playAudioFile(String filePath) async {
    try {
      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Audio file not found for playback: $filePath');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('Audio file is empty: $filePath');
        return false;
      }

      await _player.play(DeviceFileSource(filePath));
      return true;
    } catch (e) {
      debugPrint('Error playing audio file: $e');
      return false;
    }
  }

  /// Stop audio playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping audio playback: $e');
    }
  }

  /// Helper method to get file name from path
  String _getFileName(String filePath) {
    final lastSeparator = filePath.lastIndexOf(Platform.pathSeparator);
    if (lastSeparator == -1) return filePath;
    return filePath.substring(lastSeparator + 1);
  }

  /// Helper method to get file extension from path
  String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filePath.substring(lastDot);
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format duration for display
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Dispose of resources
  void dispose() {
    try {
      _player.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
  }
}

