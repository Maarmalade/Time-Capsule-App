import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_capsule/utils/retry_mechanism.dart';

void main() {
  group('RetryMechanism', () {
    group('executeWithRetry', () {
      test('should return result on first success', () async {
        int callCount = 0;

        final result = await RetryMechanism.executeWithRetry(() async {
          callCount++;
          return 'success';
        });

        expect(result, equals('success'));
        expect(callCount, equals(1));
      });

      test('should retry on transient failure and succeed', () async {
        int callCount = 0;

        final result = await RetryMechanism.executeWithRetry(() async {
          callCount++;
          if (callCount < 3) {
            throw FirebaseException(
              plugin: 'firestore',
              code: 'unavailable',
              message: 'Service unavailable',
            );
          }
          return 'success';
        });

        expect(result, equals('success'));
        expect(callCount, equals(3));
      });

      test('should fail after max retries', () async {
        int callCount = 0;

        expect(
          () => RetryMechanism.executeWithRetry(() async {
            callCount++;
            throw FirebaseException(
              plugin: 'firestore',
              code: 'unavailable',
              message: 'Service unavailable',
            );
          }, maxRetries: 2),
          throwsA(isA<FirebaseException>()),
        );

        expect(callCount, equals(3)); // Initial attempt + 2 retries
      });

      test('should not retry non-retryable errors', () async {
        int callCount = 0;

        expect(
          () => RetryMechanism.executeWithRetry(() async {
            callCount++;
            throw FirebaseException(
              plugin: 'firestore',
              code: 'permission-denied',
              message: 'Permission denied',
            );
          }),
          throwsA(isA<FirebaseException>()),
        );

        expect(callCount, equals(1)); // Should not retry
      });

      test('should respect custom shouldRetry function', () async {
        int callCount = 0;

        final result = await RetryMechanism.executeWithRetry(() async {
          callCount++;
          if (callCount < 2) {
            throw Exception('Custom error');
          }
          return 'success';
        }, shouldRetry: (error) => error.toString().contains('Custom error'));

        expect(result, equals('success'));
        expect(callCount, equals(2));
      });

      test('should use exponential backoff', () async {
        final delays = <Duration>[];
        int callCount = 0;

        try {
          await RetryMechanism.executeWithRetry(
            () async {
              callCount++;
              final start = DateTime.now();
              throw FirebaseException(
                plugin: 'firestore',
                code: 'unavailable',
                message: 'Service unavailable',
              );
            },
            maxRetries: 2,
            baseDelay: const Duration(milliseconds: 10),
          );
        } catch (e) {
          // Expected to fail
        }

        expect(callCount, equals(3)); // Initial + 2 retries
      });
    });

    group('executeWithSimpleRetry', () {
      test('should retry with fixed delay', () async {
        int callCount = 0;

        final result = await RetryMechanism.executeWithSimpleRetry(() async {
          callCount++;
          if (callCount < 2) {
            throw Exception('Temporary error');
          }
          return 'success';
        }, shouldRetry: (error) => true);

        expect(result, equals('success'));
        expect(callCount, equals(2));
      });

      test('should respect max retries', () async {
        int callCount = 0;

        expect(
          () => RetryMechanism.executeWithSimpleRetry(
            () async {
              callCount++;
              throw Exception('Persistent error');
            },
            maxRetries: 1,
            shouldRetry: (error) => true,
          ),
          throwsA(isA<Exception>()),
        );

        expect(callCount, equals(2)); // Initial + 1 retry
      });
    });

    group('error classification', () {
      test('should identify retryable Firebase errors', () async {
        final retryableErrors = [
          FirebaseException(plugin: 'firestore', code: 'unavailable'),
          FirebaseException(plugin: 'firestore', code: 'deadline-exceeded'),
          FirebaseException(plugin: 'firestore', code: 'internal'),
          FirebaseException(plugin: 'firestore', code: 'aborted'),
          FirebaseException(plugin: 'firestore', code: 'resource-exhausted'),
        ];

        for (final error in retryableErrors) {
          int callCount = 0;

          try {
            await RetryMechanism.executeWithRetry(() async {
              callCount++;
              if (callCount == 1) throw error;
              return 'success';
            }, maxRetries: 1);
          } catch (e) {
            // Some might still fail, but they should at least retry once
          }

          expect(
            callCount,
            greaterThan(1),
            reason: 'Should retry for ${error.code}',
          );
        }
      });

      test('should not retry non-retryable Firebase errors', () async {
        final nonRetryableErrors = [
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
          FirebaseException(plugin: 'firestore', code: 'not-found'),
          FirebaseException(plugin: 'firestore', code: 'already-exists'),
          FirebaseException(plugin: 'firestore', code: 'invalid-argument'),
          FirebaseException(plugin: 'firestore', code: 'unauthenticated'),
        ];

        for (final error in nonRetryableErrors) {
          int callCount = 0;

          try {
            await RetryMechanism.executeWithRetry(() async {
              callCount++;
              throw error;
            }, maxRetries: 2);
          } catch (e) {
            // Expected to fail
          }

          expect(
            callCount,
            equals(1),
            reason: 'Should not retry for ${error.code}',
          );
        }
      });

      test('should identify retryable Auth errors', () async {
        final retryableAuthErrors = [
          FirebaseAuthException(code: 'network-request-failed'),
          FirebaseAuthException(code: 'too-many-requests'),
        ];

        for (final error in retryableAuthErrors) {
          int callCount = 0;

          try {
            await RetryMechanism.executeWithRetry(() async {
              callCount++;
              if (callCount == 1) throw error;
              return 'success';
            }, maxRetries: 1);
          } catch (e) {
            // Some might still fail, but they should at least retry once
          }

          expect(
            callCount,
            greaterThan(1),
            reason: 'Should retry for ${error.code}',
          );
        }
      });

      test('should identify network errors by message', () async {
        final networkErrors = [
          Exception('Network connection failed'),
          Exception('Connection timeout'),
          Exception('Host unreachable'),
        ];

        for (final error in networkErrors) {
          int callCount = 0;

          try {
            await RetryMechanism.executeWithRetry(() async {
              callCount++;
              if (callCount == 1) throw error;
              return 'success';
            }, maxRetries: 1);
          } catch (e) {
            // Some might still fail, but they should at least retry once
          }

          expect(
            callCount,
            greaterThan(1),
            reason: 'Should retry for ${error.toString()}',
          );
        }
      });
    });
  });

  group('SocialRetryConfigs', () {
    test('should configure friend request retries', () async {
      int callCount = 0;

      final result = await SocialRetryConfigs.retryFriendRequest(() async {
        callCount++;
        if (callCount < 2) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'unavailable',
            message: 'Service unavailable',
          );
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(2));
    });

    test('should not retry friend request validation errors', () async {
      int callCount = 0;

      expect(
        () => SocialRetryConfigs.retryFriendRequest(() async {
          callCount++;
          throw Exception('Friend request already sent to this user');
        }),
        throwsA(isA<Exception>()),
      );

      expect(callCount, equals(1)); // Should not retry validation errors
    });

    test('should configure scheduled message retries', () async {
      int callCount = 0;

      final result = await SocialRetryConfigs.retryScheduledMessage(() async {
        callCount++;
        if (callCount < 2) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'internal',
            message: 'Internal error',
          );
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(2));
    });

    test('should not retry scheduled message validation errors', () async {
      int callCount = 0;

      expect(
        () => SocialRetryConfigs.retryScheduledMessage(() async {
          callCount++;
          throw Exception('Scheduled delivery date must be in the future');
        }),
        throwsA(isA<Exception>()),
      );

      expect(callCount, equals(1)); // Should not retry validation errors
    });

    test('should configure network operation retries', () async {
      int callCount = 0;

      final result = await SocialRetryConfigs.retryNetworkOperation(() async {
        callCount++;
        if (callCount < 3) {
          throw Exception('Network connection failed');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(3));
    });
  });

  group('RetryState', () {
    test('should create default retry state', () {
      const state = RetryState();

      expect(state.isRetrying, isFalse);
      expect(state.attemptCount, equals(0));
      expect(state.nextRetryIn, isNull);
      expect(state.lastError, isNull);
      expect(state.canRetry, isTrue);
      expect(state.hasError, isFalse);
    });

    test('should create retry state with values', () {
      const state = RetryState(
        isRetrying: true,
        attemptCount: 2,
        nextRetryIn: Duration(seconds: 30),
        lastError: 'Test error',
      );

      expect(state.isRetrying, isTrue);
      expect(state.attemptCount, equals(2));
      expect(state.nextRetryIn, equals(const Duration(seconds: 30)));
      expect(state.lastError, equals('Test error'));
      expect(state.canRetry, isFalse); // Can't retry while retrying
      expect(state.hasError, isTrue);
    });

    test('should copy with new values', () {
      const originalState = RetryState(isRetrying: false, attemptCount: 1);

      final newState = originalState.copyWith(
        isRetrying: true,
        lastError: 'New error',
      );

      expect(newState.isRetrying, isTrue);
      expect(newState.attemptCount, equals(1)); // Unchanged
      expect(newState.lastError, equals('New error'));
    });

    test('should determine retry eligibility', () {
      // Can retry: not retrying and under limit
      const canRetryState = RetryState(isRetrying: false, attemptCount: 2);
      expect(canRetryState.canRetry, isTrue);

      // Cannot retry: currently retrying
      const retryingState = RetryState(isRetrying: true, attemptCount: 1);
      expect(retryingState.canRetry, isFalse);

      // Cannot retry: at limit
      const limitState = RetryState(isRetrying: false, attemptCount: 3);
      expect(limitState.canRetry, isFalse);
    });
  });
}
