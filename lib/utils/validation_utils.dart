import 'dart:io';

/// Comprehensive validation utilities for the Time Capsule app
class ValidationUtils {
  // Username validation constants
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  // Password validation constants
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;

  // File validation constants
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB for images
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB for videos
  
  // Allowed file extensions
  static const List<String> allowedImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  static const List<String> allowedVideoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
  static const List<String> allowedDocumentExtensions = ['.pdf', '.doc', '.docx', '.txt'];

  /// Validates username format and returns error message if invalid
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }

    final trimmed = username.trim();
    
    if (trimmed.length < minUsernameLength) {
      return 'Username must be at least $minUsernameLength characters long';
    }
    
    if (trimmed.length > maxUsernameLength) {
      return 'Username must be no more than $maxUsernameLength characters long';
    }
    
    if (!_usernameRegex.hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  /// Validates password strength and returns error message if invalid
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters long';
    }
    
    if (password.length > maxPasswordLength) {
      return 'Password is too long';
    }
    
    return null;
  }

  /// Validates password confirmation matches
  static String? validatePasswordConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (password != confirmation) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates file name (for folders and media files)
  static String? validateFileName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    
    final trimmed = name.trim();
    
    if (trimmed.isEmpty) {
      return 'Name cannot be empty';
    }
    
    if (trimmed.length > 100) {
      return 'Name must be less than 100 characters';
    }
    
    // Check for invalid characters in file names
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(trimmed)) {
      return 'Name contains invalid characters';
    }
    
    return null;
  }

  /// Validates file upload based on type and size
  static String? validateFileUpload(File file, {String? expectedType}) {
    try {
      // Check if file exists
      if (!file.existsSync()) {
        return 'Selected file does not exist';
      }

      // Get file extension
      final fileName = file.path.toLowerCase();
      final extension = fileName.substring(fileName.lastIndexOf('.'));
      
      // Validate file type if specified
      if (expectedType != null) {
        switch (expectedType.toLowerCase()) {
          case 'image':
            if (!allowedImageExtensions.contains(extension)) {
              return 'Please select a valid image file (${allowedImageExtensions.join(', ')})';
            }
            break;
          case 'video':
            if (!allowedVideoExtensions.contains(extension)) {
              return 'Please select a valid video file (${allowedVideoExtensions.join(', ')})';
            }
            break;
          case 'document':
            if (!allowedDocumentExtensions.contains(extension)) {
              return 'Please select a valid document file (${allowedDocumentExtensions.join(', ')})';
            }
            break;
        }
      }

      // Check file size
      final fileSize = file.lengthSync();
      
      if (expectedType == 'image' && fileSize > maxImageSize) {
        return 'Image size must be less than ${(maxImageSize / (1024 * 1024)).toStringAsFixed(0)}MB';
      } else if (expectedType == 'video' && fileSize > maxVideoSize) {
        return 'Video size must be less than ${(maxVideoSize / (1024 * 1024)).toStringAsFixed(0)}MB';
      } else if (fileSize > maxFileSize && expectedType != 'image' && expectedType != 'video') {
        return 'File size must be less than ${(maxFileSize / (1024 * 1024)).toStringAsFixed(0)}MB';
      }

      return null;
    } catch (e) {
      return 'Error validating file: ${e.toString()}';
    }
  }

  /// Validates profile picture upload specifically
  static String? validateProfilePicture(File file) {
    final fileValidation = validateFileUpload(file, expectedType: 'image');
    if (fileValidation != null) {
      return fileValidation;
    }

    // Additional profile picture specific validation
    final fileSize = file.lengthSync();
    if (fileSize > maxFileSize) {
      return 'Profile picture must be less than ${(maxFileSize / (1024 * 1024)).toStringAsFixed(0)}MB';
    }

    return null;
  }

  /// Checks if a string contains only safe characters for display
  static bool isSafeForDisplay(String text) {
    // Check for potentially dangerous characters or patterns
    final dangerousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
    ];
    
    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(text)) {
        return false;
      }
    }
    
    return true;
  }

  /// Sanitizes text input for safe storage and display
  static String sanitizeText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'data:text/html[^,]*,?', caseSensitive: false), '');
  }

  /// Validates batch operation limits
  static String? validateBatchOperation(List<String> items, {int maxItems = 50}) {
    if (items.isEmpty) {
      return 'No items selected';
    }
    
    if (items.length > maxItems) {
      return 'Cannot process more than $maxItems items at once';
    }
    
    return null;
  }

  /// Gets user-friendly file size string
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Validates network connectivity requirements
  static String? validateNetworkOperation() {
    // This would typically check actual network connectivity
    // For now, we'll return null (no error) as network checks
    // are handled by Firebase SDK
    return null;
  }
}