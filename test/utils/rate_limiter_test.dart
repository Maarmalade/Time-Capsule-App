import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter();
      // Clear any existing history
      rateLimiter.clearUserHistory('testUser');
    });

    group('isAllowed', () {
      test('should allow first request', () {
        final allowed = rateLimiter.isAllowed(
          userId: 'testUser',
          operation: 'test',
          maxRequests: 5,
          timeWindow: const Duration(minutes: 1),
        );

        expect(allowed, isTrue);
      });

      test('should allow requests within limit', () {
        // Record 4 requests
        for (int i = 0; i < 4; i++) {
          rateLimiter.recordRequest(userId: 'testUser', operation: 'test');
        }

        final allowed = rateLimiter.isAllowed(
          userId: 'testUser',
          operation: 'test',
          maxRequests: 5,
          timeWindow: const Duration(minutes: 1),
        );

        expect(allowed, isTrue);
      });

      test('should deny requests exceeding limit', () {
        // Record 5 requests (at the limit)
        for (int i = 0; i < 5; i++) {
          rateLimiter.recordRequest(userId: 'testUser', operation: 'test');
        }

        final allowed = rateLimiter.isAllowed(
          userId: 'testUser',
          operation: 'test',
          maxRequests: 5,
          timeWindow: const Duration(minutes: 1),
        );

        expect(allowed, isFalse);
      });

      test('should allow requests after time window expires', () {
        // This test would require time manipulation or mocking
        // For now, we'll test the logic with a very short time window
        
        // Record a request
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test');
        
        // Check with a very short time window (effectively expired)
        final allowed = rateLimiter.isAllowed(
          userId: 'testUser',
          operation: 'test',
          maxRequests: 1,
          timeWindow: const Duration(microseconds: 1),
        );

        // Should be allowed because the time window has effectively expired
        expect(allowed, isTrue);
      });

      test('should handle different users separately', () {
        // Record 5 requests for user1
        for (int i = 0; i < 5; i++) {
          rateLimiter.recordRequest(userId: 'user1', operation: 'test');
        }

        // user1 should be at limit
        final user1Allowed = rateLimiter.isAllowed(
          userId: 'user1',
          operation: 'test',
          maxRequests: 5,
          timeWindow: const Duration(minutes: 1),
        );

        // user2 should be allowed
        final user2Allowed = rateLimiter.isAllowed(
          userId: 'user2',
          operation: 'test',
          maxRequests: 5,
          timeWindow: const Duration(minutes: 1),
        );

        expect(user1Allowed, isFalse);
        expect(user2Allowed, isTrue);
      });

      test('should handle different operations separately', () {
        // Record 5 requests for operation1
        for (int i = 0; i < 5; i++) {
          rateLimiter.recordRequest(userId: 'testUser', operation: 'operation1');
        }

        // operation1 should be at limit
        final op1Allowed = rateLimiter.isAllowed(
          userId: 'testUser',
          operation: 'operation1',
          maxRequests: 5,
          timeWindow: const Duration(minutes: 1),
        );

        // operation2 should be allowed
        final op2Allowed = rateLimiter.isAllowed(
          userId: 'testUser',
          operation: 'operation2',
          maxRequests: 5,
          timeWindow: const Duration(minutes: 1),
        );

        expect(op1Allowed, isFalse);
        expect(op2Allowed, isTrue);
      });
    });

    group('recordRequest', () {
      test('should record request', () {
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test');

        final count = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test',
          timeWindow: const Duration(minutes: 1),
        );

        expect(count, equals(1));
      });

      test('should record multiple requests', () {
        for (int i = 0; i < 3; i++) {
          rateLimiter.recordRequest(userId: 'testUser', operation: 'test');
        }

        final count = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test',
          timeWindow: const Duration(minutes: 1),
        );

        expect(count, equals(3));
      });
    });

    group('getRequestCount', () {
      test('should return 0 for no requests', () {
        final count = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test',
          timeWindow: const Duration(minutes: 1),
        );

        expect(count, equals(0));
      });

      test('should return correct count for recorded requests', () {
        for (int i = 0; i < 7; i++) {
          rateLimiter.recordRequest(userId: 'testUser', operation: 'test');
        }

        final count = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test',
          timeWindow: const Duration(minutes: 1),
        );

        expect(count, equals(7));
      });
    });

    group('hasMinimumTimePassed', () {
      test('should return true for no previous request', () {
        final passed = rateLimiter.hasMinimumTimePassed(
          userId: 'testUser',
          operation: 'test',
          minimumInterval: const Duration(minutes: 1),
        );

        expect(passed, isTrue);
      });

      test('should return false for recent request', () {
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test');

        final passed = rateLimiter.hasMinimumTimePassed(
          userId: 'testUser',
          operation: 'test',
          minimumInterval: const Duration(minutes: 1),
        );

        expect(passed, isFalse);
      });

      test('should return true for old request', () {
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test');

        final passed = rateLimiter.hasMinimumTimePassed(
          userId: 'testUser',
          operation: 'test',
          minimumInterval: const Duration(microseconds: 1),
        );

        expect(passed, isTrue);
      });
    });

    group('clearHistory', () {
      test('should clear history for specific operation', () {
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test1');
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test2');

        rateLimiter.clearHistory(userId: 'testUser', operation: 'test1');

        final count1 = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test1',
          timeWindow: const Duration(minutes: 1),
        );

        final count2 = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test2',
          timeWindow: const Duration(minutes: 1),
        );

        expect(count1, equals(0));
        expect(count2, equals(1));
      });
    });

    group('clearUserHistory', () {
      test('should clear all history for user', () {
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test1');
        rateLimiter.recordRequest(userId: 'testUser', operation: 'test2');
        rateLimiter.recordRequest(userId: 'otherUser', operation: 'test1');

        rateLimiter.clearUserHistory('testUser');

        final testUserCount1 = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test1',
          timeWindow: const Duration(minutes: 1),
        );

        final testUserCount2 = rateLimiter.getRequestCount(
          userId: 'testUser',
          operation: 'test2',
          timeWindow: const Duration(minutes: 1),
        );

        final otherUserCount = rateLimiter.getRequestCount(
          userId: 'otherUser',
          operation: 'test1',
          timeWindow: const Duration(minutes: 1),
        );

        expect(testUserCount1, equals(0));
        expect(testUserCount2, equals(0));
        expect(otherUserCount, equals(1));
      });
    });
  });

  group('SocialRateLimiters', () {
    setUp(() {
      SocialRateLimiters.clearUserHistory('testUser');
    });

    group('Friend Request Rate Limiting', () {
      test('should allow first friend request', () {
        final allowed = SocialRateLimiters.canSendFriendRequest('testUser');
        expect(allowed, isTrue);
      });

      test('should track friend request count', () {
        for (int i = 0; i < 5; i++) {
          SocialRateLimiters.recordFriendRequest('testUser');
        }

        final count = SocialRateLimiters.getFriendRequestCount('testUser');
        expect(count, equals(5));
      });

      test('should deny friend requests after limit', () {
        for (int i = 0; i < 10; i++) {
          SocialRateLimiters.recordFriendRequest('testUser');
        }

        final allowed = SocialRateLimiters.canSendFriendRequest('testUser');
        expect(allowed, isFalse);
      });

      test('should return time until next friend request when at limit', () {
        for (int i = 0; i < 10; i++) {
          SocialRateLimiters.recordFriendRequest('testUser');
        }

        final timeUntilNext = SocialRateLimiters.getTimeUntilNextFriendRequest('testUser');
        expect(timeUntilNext, isNotNull);
        expect(timeUntilNext!.inHours, greaterThan(0));
      });
    });

    group('User Search Rate Limiting', () {
      test('should allow first user search', () {
        final allowed = SocialRateLimiters.canSearchUsers('testUser');
        expect(allowed, isTrue);
      });

      test('should track search requests', () {
        for (int i = 0; i < 10; i++) {
          SocialRateLimiters.recordUserSearch('testUser');
        }

        // Should still be allowed (limit is 20 per minute)
        final allowed = SocialRateLimiters.canSearchUsers('testUser');
        expect(allowed, isTrue);
      });

      test('should deny searches after limit', () {
        for (int i = 0; i < 20; i++) {
          SocialRateLimiters.recordUserSearch('testUser');
        }

        final allowed = SocialRateLimiters.canSearchUsers('testUser');
        expect(allowed, isFalse);
      });

      test('should return time until next search when at limit', () {
        for (int i = 0; i < 20; i++) {
          SocialRateLimiters.recordUserSearch('testUser');
        }

        final timeUntilNext = SocialRateLimiters.getTimeUntilNextSearch('testUser');
        expect(timeUntilNext, isNotNull);
        expect(timeUntilNext!.inSeconds, greaterThan(0));
      });
    });

    group('Scheduled Message Rate Limiting', () {
      test('should allow first scheduled message', () {
        final allowed = SocialRateLimiters.canCreateScheduledMessage('testUser');
        expect(allowed, isTrue);
      });

      test('should track scheduled message creation', () {
        SocialRateLimiters.recordScheduledMessage('testUser');
        
        // Should be denied due to minimum interval
        final allowed = SocialRateLimiters.canCreateScheduledMessage('testUser');
        expect(allowed, isFalse);
      });

      test('should return time until next scheduled message', () {
        SocialRateLimiters.recordScheduledMessage('testUser');

        final timeUntilNext = SocialRateLimiters.getTimeUntilNextScheduledMessage('testUser');
        expect(timeUntilNext, isNotNull);
        expect(timeUntilNext!.inSeconds, greaterThan(0));
      });
    });

    group('Shared Folder Rate Limiting', () {
      test('should allow first shared folder modification', () {
        final allowed = SocialRateLimiters.canModifySharedFolder('testUser');
        expect(allowed, isTrue);
      });

      test('should track shared folder modifications', () {
        for (int i = 0; i < 15; i++) {
          SocialRateLimiters.recordSharedFolderModification('testUser');
        }

        // Should still be allowed (limit is 30 per hour)
        final allowed = SocialRateLimiters.canModifySharedFolder('testUser');
        expect(allowed, isTrue);
      });

      test('should deny modifications after limit', () {
        for (int i = 0; i < 30; i++) {
          SocialRateLimiters.recordSharedFolderModification('testUser');
        }

        final allowed = SocialRateLimiters.canModifySharedFolder('testUser');
        expect(allowed, isFalse);
      });
    });

    group('Public Folder Rate Limiting', () {
      test('should allow first public folder modification', () {
        final allowed = SocialRateLimiters.canModifyPublicFolder('testUser');
        expect(allowed, isTrue);
      });

      test('should track public folder modifications', () {
        for (int i = 0; i < 10; i++) {
          SocialRateLimiters.recordPublicFolderModification('testUser');
        }

        // Should still be allowed (limit is 20 per hour)
        final allowed = SocialRateLimiters.canModifyPublicFolder('testUser');
        expect(allowed, isTrue);
      });

      test('should deny modifications after limit', () {
        for (int i = 0; i < 20; i++) {
          SocialRateLimiters.recordPublicFolderModification('testUser');
        }

        final allowed = SocialRateLimiters.canModifyPublicFolder('testUser');
        expect(allowed, isFalse);
      });
    });

    group('Cleanup and History Management', () {
      test('should clear user history', () {
        SocialRateLimiters.recordFriendRequest('testUser');
        SocialRateLimiters.recordUserSearch('testUser');

        SocialRateLimiters.clearUserHistory('testUser');

        final friendRequestCount = SocialRateLimiters.getFriendRequestCount('testUser');
        expect(friendRequestCount, equals(0));
      });

      test('should perform cleanup', () {
        // This test mainly ensures the cleanup method doesn't throw
        SocialRateLimiters.recordFriendRequest('testUser');
        
        expect(() => SocialRateLimiters.cleanup(), returnsNormally);
      });
    });
  });
}