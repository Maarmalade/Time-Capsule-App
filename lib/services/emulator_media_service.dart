import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'permission_service.dart';

/// Service to handle media capture with emulator-specific workarounds
class EmulatorMediaService {
  static final ImagePicker _picker = ImagePicker();

  /// Capture image with emulator-friendly error handling
  static Future<XFile?> captureImage({
    required BuildContext context,
    required ImageSource source,
  }) async {
    try {
      // Check permissions first
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await PermissionService.requestCameraPermission();
      } else {
        hasPermission = await PermissionService.requestStoragePermission();
      }

      if (!hasPermission) {
        if (context.mounted) {
          await PermissionService.showPermissionDeniedDialog(
            context, 
            source == ImageSource.camera ? 'camera' : 'storage'
          );
        }
        return null;
      }

      debugPrint('Attempting to pick image from $source');
      
      // Try to pick image with timeout for emulator issues
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Image picker timed out');
          return null;
        },
      );

      if (image != null) {
        debugPrint('Image picked successfully: ${image.path}');
        
        // Verify the file exists and is readable
        final file = File(image.path);
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('Image file size: $size bytes');
          
          if (size > 0) {
            return image;
          } else {
            debugPrint('Image file is empty');
            return null;
          }
        } else {
          debugPrint('Image file does not exist');
          return null;
        }
      } else {
        debugPrint('Image picker returned null (user cancelled or error)');
        return null;
      }
    } catch (e) {
      debugPrint('Error in captureImage: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Capture video with emulator-friendly error handling
  static Future<XFile?> captureVideo({
    required BuildContext context,
    required ImageSource source,
  }) async {
    try {
      // Check permissions first
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await PermissionService.requestCameraPermission();
      } else {
        hasPermission = await PermissionService.requestStoragePermission();
      }

      if (!hasPermission) {
        if (context.mounted) {
          await PermissionService.showPermissionDeniedDialog(
            context, 
            source == ImageSource.camera ? 'camera' : 'storage'
          );
        }
        return null;
      }

      debugPrint('Attempting to pick video from $source');
      
      // Try to pick video with timeout for emulator issues
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Video picker timed out');
          return null;
        },
      );

      if (video != null) {
        debugPrint('Video picked successfully: ${video.path}');
        
        // Verify the file exists and is readable
        final file = File(video.path);
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('Video file size: $size bytes');
          
          if (size > 0) {
            return video;
          } else {
            debugPrint('Video file is empty');
            return null;
          }
        } else {
          debugPrint('Video file does not exist');
          return null;
        }
      } else {
        debugPrint('Video picker returned null (user cancelled or error)');
        return null;
      }
    } catch (e) {
      debugPrint('Error in captureVideo: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Show error dialog with emulator-specific guidance
  static Future<void> showEmulatorErrorDialog(BuildContext context) async {
    if (!context.mounted) return;
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emulator Media Capture'),
          content: const Text(
            'If you\'re having issues with media capture in the emulator:\n\n'
            '1. Make sure the emulator has camera enabled in AVD settings\n'
            '2. Try using "Webcam0" for camera in AVD advanced settings\n'
            '3. Grant permissions manually in emulator Settings > Apps > Time Capsule > Permissions\n'
            '4. For best results, test on a physical device\n\n'
            'The emulator provides virtual camera with test patterns or can use your computer\'s webcam.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}