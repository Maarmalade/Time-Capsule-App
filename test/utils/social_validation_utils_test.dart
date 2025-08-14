import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/utils/social_validation_utils.dart';

void main() {
  group('SocialValidationUtils', () {
    group('validateUsernameSearch', () {
      test('should return success for valid search query', () {
        final result = SocialValidationUtils.validateUsernameSearch('john_doe');
        
        expect(result.isValid, isTrue);
        expect(result.data, equals('john_doe'));
      });

      test('should return error for empty query', () {
        final result = SocialValidationUtils.validateUsernameSearch('');
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('cannot be empty'));
      });

      test('should return error for query too short', () {
        final result = SocialValidationUtils.validateUsernameSearch('a');
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('at least 2 characters'));
      });

      test('should return error for query too long', () {
        final result = SocialValidationUtils.validateUsernameSearch('a' * 25);
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('too long'));
      });

      test('should return error for invalid characters', () {
        final result = SocialValidationUtils.validateUsernameSearch('user@name');
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('invalid characters'));
      });

      test('should sanitize and lowercase valid query', () {
        final result = SocialValidationUtils.validateUsernameSearch('  JohnDoe  ');
        
        expect(result.isValid, isTrue);
        expect(result.data, equals('johndoe'));
      });

      test('should allow underscores and numbers', () {
        final result = SocialValidationUtils.validateUsernameSearch('user_123');
        
        expect(result.isValid, isTrue);
        expect(result.data, equals('user_123'));
      });
    });

    group('validateFriendRequest', () {
      test('should return success for valid friend request', () {
        final result = SocialValidationUtils.validateFriendRequest(
          senderId: 'user1',
          receiverId: 'user2',
          dailyRequestCount: 5,
        );
        
        expect(result.isValid, isTrue);
      });

      test('should return error for same sender and receiver', () {
        final result = SocialValidationUtils.validateFriendRequest(
          senderId: 'user1',
          receiverId: 'user1',
          dailyRequestCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Cannot send friend request to yourself'));
      });

      test('should return error for empty sender ID', () {
        final result = SocialValidationUtils.validateFriendRequest(
          senderId: '',
          receiverId: 'user2',
          dailyRequestCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Sender ID cannot be empty'));
      });

      test('should return error for empty receiver ID', () {
        final result = SocialValidationUtils.validateFriendRequest(
          senderId: 'user1',
          receiverId: '',
          dailyRequestCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Receiver ID cannot be empty'));
      });

      test('should return error for exceeding daily limit', () {
        final result = SocialValidationUtils.validateFriendRequest(
          senderId: 'user1',
          receiverId: 'user2',
          dailyRequestCount: 10,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Daily friend request limit reached'));
      });
    });

    group('validateScheduledMessage', () {
      final now = DateTime.now();
      final futureTime = now.add(const Duration(hours: 1));
      final pastTime = now.subtract(const Duration(hours: 1));

      test('should return success for valid scheduled message', () {
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: 'Hello future!',
          scheduledFor: futureTime,
          userMessageCount: 5,
        );
        
        expect(result.isValid, isTrue);
        expect(result.data, equals('Hello future!'));
      });

      test('should return error for empty content', () {
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: '',
          scheduledFor: futureTime,
          userMessageCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('cannot be empty'));
      });

      test('should return error for content too long', () {
        final longContent = 'a' * 5001;
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: longContent,
          scheduledFor: futureTime,
          userMessageCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('cannot exceed 5000 characters'));
      });

      test('should return error for past scheduled time', () {
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: 'Hello past!',
          scheduledFor: pastTime,
          userMessageCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('at least 5 minutes in the future'));
      });

      test('should return error for time too far in future', () {
        final farFuture = now.add(const Duration(days: 365 * 11));
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: 'Hello far future!',
          scheduledFor: farFuture,
          userMessageCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('more than 10 years in the future'));
      });

      test('should return error for exceeding message limit', () {
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: 'Hello!',
          scheduledFor: futureTime,
          userMessageCount: 50,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Maximum scheduled messages limit reached'));
      });

      test('should sanitize message content', () {
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: '  Hello with spaces!  ',
          scheduledFor: futureTime,
          userMessageCount: 5,
        );
        
        expect(result.isValid, isTrue);
        expect(result.data, equals('Hello with spaces!'));
      });

      test('should validate video URL if provided', () {
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: 'Hello!',
          scheduledFor: futureTime,
          videoUrl: 'invalid-url',
          userMessageCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Invalid video URL format'));
      });

      test('should accept valid video URL', () {
        final result = SocialValidationUtils.validateScheduledMessage(
          senderId: 'user1',
          recipientId: 'user2',
          textContent: 'Hello!',
          scheduledFor: futureTime,
          videoUrl: 'https://example.com/video.mp4',
          userMessageCount: 5,
        );
        
        expect(result.isValid, isTrue);
      });
    });

    group('validateSharedFolderContributors', () {
      test('should return success for valid contributors', () {
        final result = SocialValidationUtils.validateSharedFolderContributors(
          ownerId: 'owner1',
          contributorIds: ['user1', 'user2', 'user3'],
        );
        
        expect(result.isValid, isTrue);
      });

      test('should return error for too many contributors', () {
        final contributors = List.generate(25, (i) => 'user$i');
        final result = SocialValidationUtils.validateSharedFolderContributors(
          ownerId: 'owner1',
          contributorIds: contributors,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('more than 20 contributors'));
      });

      test('should return error for owner in contributor list', () {
        final result = SocialValidationUtils.validateSharedFolderContributors(
          ownerId: 'owner1',
          contributorIds: ['user1', 'owner1', 'user2'],
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Owner cannot be added as a contributor'));
      });

      test('should return error for duplicate contributors', () {
        final result = SocialValidationUtils.validateSharedFolderContributors(
          ownerId: 'owner1',
          contributorIds: ['user1', 'user2', 'user1'],
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Duplicate contributors are not allowed'));
      });

      test('should return error for empty contributor ID', () {
        final result = SocialValidationUtils.validateSharedFolderContributors(
          ownerId: 'owner1',
          contributorIds: ['user1', '', 'user2'],
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Contributor 2 ID cannot be empty'));
      });
    });

    group('validatePublicFolderCreation', () {
      test('should return success for valid public folder creation', () {
        final result = SocialValidationUtils.validatePublicFolderCreation(
          userId: 'user1',
          userPublicFolderCount: 5,
        );
        
        expect(result.isValid, isTrue);
      });

      test('should return error for exceeding public folder limit', () {
        final result = SocialValidationUtils.validatePublicFolderCreation(
          userId: 'user1',
          userPublicFolderCount: 100,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Maximum public folders limit reached'));
      });

      test('should return error for empty user ID', () {
        final result = SocialValidationUtils.validatePublicFolderCreation(
          userId: '',
          userPublicFolderCount: 5,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('User ID cannot be empty'));
      });
    });

    group('validateFolderName', () {
      test('should return success for valid folder name', () {
        final result = SocialValidationUtils.validateFolderName('My Vacation Photos');
        
        expect(result.isValid, isTrue);
        expect(result.data, equals('My Vacation Photos'));
      });

      test('should return error for empty name', () {
        final result = SocialValidationUtils.validateFolderName('');
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('required'));
      });

      test('should return error for inappropriate content', () {
        final result = SocialValidationUtils.validateFolderName('spam folder');
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('more descriptive folder name'));
      });

      test('should trim whitespace', () {
        final result = SocialValidationUtils.validateFolderName('  Valid Name  ');
        
        expect(result.isValid, isTrue);
        expect(result.data, equals('Valid Name'));
      });
    });

    group('validateSearchRateLimit', () {
      test('should return success for within rate limit', () {
        final result = SocialValidationUtils.validateSearchRateLimit(
          searchCount: 10,
          timeWindow: const Duration(minutes: 1),
        );
        
        expect(result.isValid, isTrue);
      });

      test('should return error for exceeding rate limit', () {
        final result = SocialValidationUtils.validateSearchRateLimit(
          searchCount: 25,
          timeWindow: const Duration(minutes: 1),
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Too many search queries'));
      });
    });

    group('validateMessageDeliveryTiming', () {
      final now = DateTime.now();
      final pastTime = now.subtract(const Duration(hours: 1));
      final futureTime = now.add(const Duration(hours: 1));

      test('should return success for ready message', () {
        final result = SocialValidationUtils.validateMessageDeliveryTiming(
          scheduledFor: pastTime,
          lastMessageTime: now.subtract(const Duration(minutes: 10)),
        );
        
        expect(result.isValid, isTrue);
      });

      test('should return error for future scheduled time', () {
        final result = SocialValidationUtils.validateMessageDeliveryTiming(
          scheduledFor: futureTime,
          lastMessageTime: null,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('not yet ready for delivery'));
      });

      test('should return error for too recent last message', () {
        final result = SocialValidationUtils.validateMessageDeliveryTiming(
          scheduledFor: pastTime,
          lastMessageTime: now.subtract(const Duration(minutes: 2)),
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('at least 5 minutes apart'));
      });
    });

    group('validateBatchSocialOperation', () {
      test('should return success for valid batch operation', () {
        final result = SocialValidationUtils.validateBatchSocialOperation(
          itemIds: ['item1', 'item2', 'item3'],
          operationType: 'delete',
        );
        
        expect(result.isValid, isTrue);
      });

      test('should return error for empty item list', () {
        final result = SocialValidationUtils.validateBatchSocialOperation(
          itemIds: [],
          operationType: 'delete',
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('No items selected'));
      });

      test('should return error for too many items', () {
        final items = List.generate(25, (i) => 'item$i');
        final result = SocialValidationUtils.validateBatchSocialOperation(
          itemIds: items,
          operationType: 'delete',
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('more than 20 items'));
      });

      test('should return error for duplicate items', () {
        final result = SocialValidationUtils.validateBatchSocialOperation(
          itemIds: ['item1', 'item2', 'item1'],
          operationType: 'delete',
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('Duplicate items are not allowed'));
      });

      test('should respect custom max items', () {
        final result = SocialValidationUtils.validateBatchSocialOperation(
          itemIds: ['item1', 'item2', 'item3'],
          operationType: 'process',
          maxItems: 2,
        );
        
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('more than 2 items'));
      });
    });
  });

  group('ValidationResult', () {
    test('should create success result', () {
      final result = ValidationResult.success('test data');
      
      expect(result.isValid, isTrue);
      expect(result.hasError, isFalse);
      expect(result.data, equals('test data'));
      expect(result.errorMessage, isNull);
    });

    test('should create error result', () {
      final result = ValidationResult.error('Test error');
      
      expect(result.isValid, isFalse);
      expect(result.hasError, isTrue);
      expect(result.errorMessage, equals('Test error'));
      expect(result.data, isNull);
    });

    test('should create success result without data', () {
      final result = ValidationResult.success();
      
      expect(result.isValid, isTrue);
      expect(result.data, isNull);
    });
  });
}