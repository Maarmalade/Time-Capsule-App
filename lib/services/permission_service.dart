import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling camera, microphone, and storage permissions
/// Required for enhanced media capture functionality
class PermissionService {
  /// Request camera permission for photo and video capture
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      debugPrint('Camera permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request microphone permission for audio recording
  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      debugPrint('Microphone permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Request storage permission for file access
  static Future<bool> requestStoragePermission() async {
    try {
      // Always try legacy storage permission first as it's more reliable
      final storage = await Permission.storage.request();
      debugPrint('Storage permission status: $storage');
      
      if (storage.isGranted) {
        debugPrint('Legacy storage permission granted, using that');
        return true;
      }
      
      // If legacy storage fails, try Android 13+ permissions
      if (await _isAndroid13OrHigher()) {
        debugPrint('Trying Android 13+ media permissions...');
        
        // Request photos permission first (most common use case)
        final photos = await Permission.photos.request();
        debugPrint('Photos permission status: $photos');
        
        if (photos.isGranted) {
          return true;
        }
        
        // If photos permission denied, try videos
        final videos = await Permission.videos.request();
        debugPrint('Videos permission status: $videos');
        
        return videos.isGranted;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      // Final fallback: try basic storage permission one more time
      try {
        final status = await Permission.storage.request();
        debugPrint('Final fallback storage permission status: $status');
        return status.isGranted;
      } catch (e2) {
        debugPrint('Final fallback storage permission error: $e2');
        return false;
      }
    }
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  static Future<bool> isMicrophonePermissionGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    try {
      // Always check legacy storage permission first
      final storage = await Permission.storage.status;
      debugPrint('Storage permission status: $storage');
      
      if (storage.isGranted) {
        return true;
      }
      
      // If legacy storage not granted, check Android 13+ permissions
      if (await _isAndroid13OrHigher()) {
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;
        
        debugPrint('Android 13+ permission status - Photos: $photos, Videos: $videos');
        
        // At least one media permission should be granted
        return photos.isGranted || videos.isGranted;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      // Fallback: check basic storage permission
      try {
        final status = await Permission.storage.status;
        debugPrint('Fallback storage permission status: $status');
        return status.isGranted;
      } catch (e2) {
        debugPrint('Fallback storage permission check error: $e2');
        return false;
      }
    }
  }

  /// Request all required permissions for media capture
  static Future<Map<String, bool>> requestAllMediaPermissions() async {
    final results = <String, bool>{};
    
    results['camera'] = await requestCameraPermission();
    results['microphone'] = await requestMicrophonePermission();
    results['storage'] = await requestStoragePermission();
    
    return results;
  }

  /// Show permission denied dialog with guidance for users
  static Future<void> showPermissionDeniedDialog(
    BuildContext context,
    String permission,
  ) async {
    final permissionName = _getPermissionDisplayName(permission);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionName Permission Required'),
          content: Text(
            'Time Capsule needs $permissionName access to provide this feature. '
            'Please grant permission in your device settings to continue.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Show dialog when multiple permissions are denied
  static Future<void> showMultiplePermissionsDeniedDialog(
    BuildContext context,
    List<String> deniedPermissions,
  ) async {
    final permissionNames = deniedPermissions
        .map(_getPermissionDisplayName)
        .join(', ');
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: Text(
            'Time Capsule needs the following permissions to work properly: '
            '$permissionNames. Please grant these permissions in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Helper method to check if running on Android 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    try {
      // Check if the new media permissions are available and working
      final photosStatus = await Permission.photos.status;
      debugPrint('Android 13+ photos permission check: $photosStatus');
      
      // If we can check the status without error, Android 13+ permissions are available
      return true;
    } catch (e) {
      // New permissions not available, use legacy storage permission
      debugPrint('Android 13+ permissions not available, using legacy storage permission: $e');
      return false;
    }
  }

  /// Get user-friendly permission name for display
  static String _getPermissionDisplayName(String permission) {
    switch (permission.toLowerCase()) {
      case 'camera':
        return 'Camera';
      case 'microphone':
        return 'Microphone';
      case 'storage':
        return 'Storage';
      case 'photos':
        return 'Photos';
      case 'videos':
        return 'Videos';
      case 'audio':
        return 'Audio Files';
      default:
        return permission;
    }
  }
}