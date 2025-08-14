import 'validation_utils.dart';
import 'friend_validation_utils.dart';

/// Comprehensive validation utilities for social features
class SocialValidationUtils {
  // Rate limiting constants
  static const int maxFriendRequestsPerDay = 10;
  static const int maxSearchQueriesPerMinute = 20;
  static const int maxScheduledMessagesPerUser = 50;
  static const int minScheduledMessageInterval = 5; // minutes
  
  // Content validation constants
  static const int maxMessageContentLength = 5000;
  static const int minMessageContentLength = 1;
  static const int maxContributorsPerFolder = 20;
  static const int maxPublicFoldersPerUser = 100;
  
  // Time validation constants
  static const int maxScheduledDaysInFuture = 365 * 10; // 10 years
  static const int minScheduledMinutesInFuture = 5;

  /// Validates username search query with enhanced checks
  static ValidationResult validateUsernameSearch(String query) {
    try {
      if (query.trim().isEmpty) {
        return ValidationResult.error('Search query cannot be empty');
      }

      final trimmedQuery = query.trim();
      
      if (trimmedQuery.length < FriendValidationUtils.minSearchQueryLength) {
        return ValidationResult.error(
          'Search query must be at least ${FriendValidationUtils.minSearchQueryLength} characters long'
        );
      }

      if (trimmedQuery.length > ValidationUtils.maxUsernameLength) {
        return ValidationResult.error('Search query is too long');
      }

      // Check for invalid characters
      if (!RegExp(r'^[a-zA-Z0-9_\s]+$').hasMatch(trimmedQuery)) {
        return ValidationResult.error('Search query contains invalid characters');
      }

      // Sanitize and validate safety
      final sanitized = ValidationUtils.sanitizeText(trimmedQuery);
      if (!ValidationUtils.isSafeForDisplay(sanitized)) {
        return ValidationResult.error('Invalid search query');
      }

      return ValidationResult.success(sanitized.toLowerCase());
    } catch (e) {
      return ValidationResult.error('Invalid search query: ${e.toString()}');
    }
  }

  /// Validates friend request creation with rate limiting checks
  static ValidationResult validateFriendRequest({
    required String senderId,
    required String receiverId,
    required int dailyRequestCount,
  }) {
    try {
      // Validate user IDs
      FriendValidationUtils.validateUserId(senderId, 'Sender ID');
      FriendValidationUtils.validateUserId(receiverId, 'Receiver ID');
      
      // Check if trying to send request to self
      if (senderId == receiverId) {
        return ValidationResult.error('Cannot send friend request to yourself');
      }

      // Check daily rate limit
      if (dailyRequestCount >= maxFriendRequestsPerDay) {
        return ValidationResult.error(
          'Daily friend request limit reached ($maxFriendRequestsPerDay per day)'
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error(e.toString());
    }
  }

  /// Validates scheduled message content and timing
  static ValidationResult validateScheduledMessage({
    required String senderId,
    required String recipientId,
    required String textContent,
    required DateTime scheduledFor,
    String? videoUrl,
    required int userMessageCount,
  }) {
    try {
      // Validate user IDs
      FriendValidationUtils.validateUserId(senderId, 'Sender ID');
      FriendValidationUtils.validateUserId(recipientId, 'Recipient ID');

      // Validate content
      if (textContent.trim().isEmpty) {
        return ValidationResult.error('Message content cannot be empty');
      }

      if (textContent.length < minMessageContentLength) {
        return ValidationResult.error('Message content is too short');
      }

      if (textContent.length > maxMessageContentLength) {
        return ValidationResult.error(
          'Message content cannot exceed $maxMessageContentLength characters'
        );
      }

      // Sanitize and validate content safety
      final sanitizedContent = ValidationUtils.sanitizeText(textContent);
      if (!ValidationUtils.isSafeForDisplay(sanitizedContent)) {
        return ValidationResult.error('Message content contains invalid characters');
      }

      // Validate scheduled time
      final now = DateTime.now();
      final minScheduledTime = now.add(Duration(minutes: minScheduledMinutesInFuture));
      
      if (!scheduledFor.isAfter(minScheduledTime)) {
        return ValidationResult.error(
          'Message must be scheduled at least $minScheduledMinutesInFuture minutes in the future'
        );
      }

      final maxScheduledTime = now.add(Duration(days: maxScheduledDaysInFuture));
      if (scheduledFor.isAfter(maxScheduledTime)) {
        return ValidationResult.error(
          'Message cannot be scheduled more than ${maxScheduledDaysInFuture ~/ 365} years in the future'
        );
      }

      // Check user message limit
      if (userMessageCount >= maxScheduledMessagesPerUser) {
        return ValidationResult.error(
          'Maximum scheduled messages limit reached ($maxScheduledMessagesPerUser per user)'
        );
      }

      // Validate video URL if provided
      if (videoUrl != null && videoUrl.isNotEmpty) {
        if (!_isValidUrl(videoUrl)) {
          return ValidationResult.error('Invalid video URL format');
        }
      }

      return ValidationResult.success(sanitizedContent);
    } catch (e) {
      return ValidationResult.error(e.toString());
    }
  }

  /// Validates shared folder contributor list
  static ValidationResult validateSharedFolderContributors({
    required String ownerId,
    required List<String> contributorIds,
  }) {
    try {
      // Validate owner ID
      FriendValidationUtils.validateUserId(ownerId, 'Owner ID');

      // Check contributor limit
      if (contributorIds.length > maxContributorsPerFolder) {
        return ValidationResult.error(
          'Cannot have more than $maxContributorsPerFolder contributors per folder'
        );
      }

      // Validate each contributor ID
      for (int i = 0; i < contributorIds.length; i++) {
        final contributorId = contributorIds[i];
        FriendValidationUtils.validateUserId(contributorId, 'Contributor ${i + 1} ID');
        
        // Check if owner is in contributor list
        if (contributorId == ownerId) {
          return ValidationResult.error('Owner cannot be added as a contributor');
        }
      }

      // Check for duplicate contributors
      final uniqueContributors = contributorIds.toSet();
      if (uniqueContributors.length != contributorIds.length) {
        return ValidationResult.error('Duplicate contributors are not allowed');
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error(e.toString());
    }
  }

  /// Validates public folder creation limits
  static ValidationResult validatePublicFolderCreation({
    required String userId,
    required int userPublicFolderCount,
  }) {
    try {
      FriendValidationUtils.validateUserId(userId, 'User ID');

      if (userPublicFolderCount >= maxPublicFoldersPerUser) {
        return ValidationResult.error(
          'Maximum public folders limit reached ($maxPublicFoldersPerUser per user)'
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error(e.toString());
    }
  }

  /// Validates folder name for shared/public folders
  static ValidationResult validateFolderName(String name) {
    final baseValidation = ValidationUtils.validateFileName(name);
    if (baseValidation != null) {
      return ValidationResult.error(baseValidation);
    }

    // Additional validation for social folders
    final trimmed = name.trim();
    
    // Check for inappropriate content (basic check)
    final inappropriateWords = ['spam', 'test123', 'untitled'];
    if (inappropriateWords.any((word) => trimmed.toLowerCase().contains(word))) {
      return ValidationResult.error('Please choose a more descriptive folder name');
    }

    return ValidationResult.success(trimmed);
  }

  /// Validates rate limiting for search operations
  static ValidationResult validateSearchRateLimit({
    required int searchCount,
    required Duration timeWindow,
  }) {
    if (timeWindow.inMinutes <= 1 && searchCount >= maxSearchQueriesPerMinute) {
      return ValidationResult.error(
        'Too many search queries. Please wait before searching again.'
      );
    }

    return ValidationResult.success();
  }

  /// Validates message delivery timing constraints
  static ValidationResult validateMessageDeliveryTiming({
    required DateTime scheduledFor,
    required DateTime? lastMessageTime,
  }) {
    final now = DateTime.now();
    
    // Check if message is ready for delivery
    if (scheduledFor.isAfter(now)) {
      return ValidationResult.error('Message is not yet ready for delivery');
    }

    // Check minimum interval between messages to same recipient
    if (lastMessageTime != null) {
      final timeSinceLastMessage = now.difference(lastMessageTime);
      if (timeSinceLastMessage.inMinutes < minScheduledMessageInterval) {
        return ValidationResult.error(
          'Messages must be at least $minScheduledMessageInterval minutes apart'
        );
      }
    }

    return ValidationResult.success();
  }

  /// Helper method to validate URL format
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validates batch operations for social features
  static ValidationResult validateBatchSocialOperation({
    required List<String> itemIds,
    required String operationType,
    int? maxItems,
  }) {
    final maxAllowed = maxItems ?? 20;
    
    if (itemIds.isEmpty) {
      return ValidationResult.error('No items selected for $operationType');
    }

    if (itemIds.length > maxAllowed) {
      return ValidationResult.error(
        'Cannot $operationType more than $maxAllowed items at once'
      );
    }

    // Validate each ID
    for (int i = 0; i < itemIds.length; i++) {
      try {
        FriendValidationUtils.validateUserId(itemIds[i], 'Item ${i + 1} ID');
      } catch (e) {
        return ValidationResult.error('Invalid item ID at position ${i + 1}');
      }
    }

    // Check for duplicates
    final uniqueIds = itemIds.toSet();
    if (uniqueIds.length != itemIds.length) {
      return ValidationResult.error('Duplicate items are not allowed');
    }

    return ValidationResult.success();
  }
}

/// Result class for validation operations
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final dynamic data;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.data,
  });

  factory ValidationResult.success([dynamic data]) {
    return ValidationResult._(isValid: true, data: data);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }

  bool get hasError => !isValid;
}