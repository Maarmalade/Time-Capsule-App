import 'validation_utils.dart';

/// Validation utilities specific to friend management features
class FriendValidationUtils {
  static const int minSearchQueryLength = 2;

  /// Validates and sanitizes a username search query
  /// Returns the sanitized query if valid, throws Exception if invalid
  static String validateAndSanitizeSearchQuery(String query) {
    if (query.isEmpty) {
      throw Exception('Search query cannot be empty');
    }

    final trimmedQuery = query.trim();
    
    if (trimmedQuery.length < minSearchQueryLength) {
      throw Exception('Search query must be at least $minSearchQueryLength characters long');
    }

    if (trimmedQuery.length > ValidationUtils.maxUsernameLength) {
      throw Exception('Search query is too long');
    }

    // Sanitize the query to prevent injection attacks
    final sanitizedQuery = ValidationUtils.sanitizeText(trimmedQuery);
    
    if (!ValidationUtils.isSafeForDisplay(sanitizedQuery)) {
      throw Exception('Invalid search query');
    }

    return sanitizedQuery.toLowerCase();
  }

  /// Validates that a user ID is not empty and properly formatted
  static void validateUserId(String? userId, String fieldName) {
    if (userId == null || userId.isEmpty) {
      throw Exception('$fieldName cannot be empty');
    }
    
    if (userId.length > 128) {
      throw Exception('$fieldName is invalid');
    }
  }

  /// Validates that two user IDs are different (for friend requests)
  static void validateDifferentUsers(String senderId, String receiverId) {
    if (senderId == receiverId) {
      throw Exception('Cannot send friend request to yourself');
    }
  }
}