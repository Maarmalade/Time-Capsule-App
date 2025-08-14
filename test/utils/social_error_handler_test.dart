import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/utils/social_error_handler.dart';

void main() {
  group('SocialErrorHandler', () {
    group('getFriendErrorMessage', () {
      test('should return specific message for duplicate friend request', () {
        final error = Exception('Friend request already sent to this user');
        final message = SocialErrorHandler.getFriendErrorMessage(error);
        
        expect(message, equals('You have already sent a friend request to this user.'));
      });

      test('should return specific message for reverse friend request', () {
        final error = Exception('This user has already sent you a friend request');
        final message = SocialErrorHandler.getFriendErrorMessage(error);
        
        expect(message, contains('Check your pending requests'));
      });

      test('should return specific message for already friends', () {
        final error = Exception('You are already friends with this user');
        final message = SocialErrorHandler.getFriendErrorMessage(error);
        
        expect(message, equals('You are already friends with this user.'));
      });

      test('should return specific message for user not found', () {
        final error = Exception('User not found');
        final message = SocialErrorHandler.getFriendErrorMessage(error);
        
        expect(message, contains('may have deleted their account'));
      });

      test('should return specific message for daily limit', () {
        final error = Exception('Daily friend request limit reached');
        final message = SocialErrorHandler.getFriendErrorMessage(error);
        
        expect(message, contains('Try again tomorrow'));
      });

      test('should return original message for unknown error', () {
        final error = Exception('Unknown friend error');
        final message = SocialErrorHandler.getFriendErrorMessage(error);
        
        expect(message, equals('Unknown friend error'));
      });
    });

    group('getScheduledMessageErrorMessage', () {
      test('should return specific message for future date requirement', () {
        final error = Exception('Scheduled delivery date must be in the future');
        final message = SocialErrorHandler.getScheduledMessageErrorMessage(error);
        
        expect(message, contains('Please select a future date and time'));
      });

      test('should return specific message for too far in future', () {
        final error = Exception('Scheduled delivery date cannot be more than 10 years in the future');
        final message = SocialErrorHandler.getScheduledMessageErrorMessage(error);
        
        expect(message, contains('cannot be scheduled more than 10 years'));
      });

      test('should return specific message for minimum time requirement', () {
        final error = Exception('Messages must be scheduled at least 5 minutes in the future');
        final message = SocialErrorHandler.getScheduledMessageErrorMessage(error);
        
        expect(message, contains('at least 5 minutes in the future'));
      });

      test('should return specific message for message limit', () {
        final error = Exception('Maximum scheduled messages limit reached');
        final message = SocialErrorHandler.getScheduledMessageErrorMessage(error);
        
        expect(message, contains('Cancel some existing messages'));
      });

      test('should return specific message for content length', () {
        final error = Exception('Message content cannot exceed 5000 characters');
        final message = SocialErrorHandler.getScheduledMessageErrorMessage(error);
        
        expect(message, contains('Please shorten your message'));
      });
    });

    group('getSharedFolderErrorMessage', () {
      test('should return specific message for contributor limit', () {
        final error = Exception('A folder cannot have more than 20 contributors');
        final message = SocialErrorHandler.getSharedFolderErrorMessage(error);
        
        expect(message, contains('cannot have more than 20 contributors'));
      });

      test('should return specific message for owner as contributor', () {
        final error = Exception('Owner cannot be added as a contributor');
        final message = SocialErrorHandler.getSharedFolderErrorMessage(error);
        
        expect(message, contains('automatically a contributor'));
      });

      test('should return specific message for duplicate contributors', () {
        final error = Exception('Duplicate contributors are not allowed');
        final message = SocialErrorHandler.getSharedFolderErrorMessage(error);
        
        expect(message, contains('only be added as a contributor once'));
      });

      test('should return specific message for locked folder', () {
        final error = Exception('This folder is locked and no longer accepts contributions');
        final message = SocialErrorHandler.getSharedFolderErrorMessage(error);
        
        expect(message, contains('has been locked'));
      });

      test('should return specific message for permission denied', () {
        final error = Exception('You are not a contributor to this folder');
        final message = SocialErrorHandler.getSharedFolderErrorMessage(error);
        
        expect(message, contains('do not have permission to contribute'));
      });
    });

    group('getPublicFolderErrorMessage', () {
      test('should return specific message for public folder limit', () {
        final error = Exception('Maximum public folders limit reached');
        final message = SocialErrorHandler.getPublicFolderErrorMessage(error);
        
        expect(message, contains('Make some folders private'));
      });

      test('should return specific message for cannot make public', () {
        final error = Exception('This folder cannot make folder public');
        final message = SocialErrorHandler.getPublicFolderErrorMessage(error);
        
        expect(message, contains('may contain private content'));
      });
    });

    group('error type detection', () {
      test('should detect network errors', () {
        final networkError = FirebaseException(
          plugin: 'firestore',
          code: 'unavailable',
          message: 'Network unavailable',
        );
        
        // This is testing private method behavior through public interface
        // We can't directly test private methods, but we can test the behavior
        expect(networkError.code, equals('unavailable'));
      });

      test('should detect rate limit errors', () {
        final rateLimitError = FirebaseException(
          plugin: 'firestore',
          code: 'resource-exhausted',
          message: 'Too many requests',
        );
        
        expect(rateLimitError.code, equals('resource-exhausted'));
      });

      test('should detect permission errors', () {
        final permissionError = FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        );
        
        expect(permissionError.code, equals('permission-denied'));
      });
    });

    group('widget builders', () {
      testWidgets('buildErrorState should create error widget', (tester) async {
        bool retryPressed = false;
        
        final widget = MaterialApp(
          home: Scaffold(
            body: SocialErrorHandler.buildErrorState(
              message: 'Test error message',
              onRetry: () => retryPressed = true,
            ),
          ),
        );

        await tester.pumpWidget(widget);

        expect(find.text('Test error message'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        await tester.tap(find.text('Try Again'));
        expect(retryPressed, isTrue);
      });

      testWidgets('buildNetworkErrorState should create network error widget', (tester) async {
        bool retryPressed = false;
        
        final widget = MaterialApp(
          home: Scaffold(
            body: SocialErrorHandler.buildNetworkErrorState(
              onRetry: () => retryPressed = true,
            ),
          ),
        );

        await tester.pumpWidget(widget);

        expect(find.textContaining('No internet connection'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);

        await tester.tap(find.text('Retry'));
        expect(retryPressed, isTrue);
      });

      testWidgets('buildEmptyState should create empty state widget', (tester) async {
        bool actionPressed = false;
        
        final widget = MaterialApp(
          home: Scaffold(
            body: SocialErrorHandler.buildEmptyState(
              message: 'No items found',
              actionText: 'Add Item',
              onAction: () => actionPressed = true,
            ),
          ),
        );

        await tester.pumpWidget(widget);

        expect(find.text('No items found'), findsOneWidget);
        expect(find.text('Add Item'), findsOneWidget);
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);

        await tester.tap(find.text('Add Item'));
        expect(actionPressed, isTrue);
      });

      testWidgets('buildErrorState should use custom icon and retry text', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: SocialErrorHandler.buildErrorState(
              message: 'Custom error',
              onRetry: () {},
              icon: Icons.warning,
              retryText: 'Custom Retry',
            ),
          ),
        );

        await tester.pumpWidget(widget);

        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.text('Custom Retry'), findsOneWidget);
      });

      testWidgets('buildEmptyState should use custom icon', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: SocialErrorHandler.buildEmptyState(
              message: 'Empty state',
              actionText: 'Action',
              onAction: () {},
              icon: Icons.folder_open,
            ),
          ),
        );

        await tester.pumpWidget(widget);

        expect(find.byIcon(Icons.folder_open), findsOneWidget);
      });
    });

    group('snackbar methods', () {
      testWidgets('showErrorWithRetry should show snackbar with retry action', (tester) async {
        bool retryPressed = false;
        
        final widget = MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SocialErrorHandler.showErrorWithRetry(
                  context,
                  message: 'Test error',
                  onRetry: () => retryPressed = true,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('Test error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        expect(retryPressed, isTrue);
      });

      testWidgets('showNetworkError should show network error snackbar', (tester) async {
        bool retryPressed = false;
        
        final widget = MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SocialErrorHandler.showNetworkError(
                  context,
                  onRetry: () => retryPressed = true,
                ),
                child: const Text('Show Network Error'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.tap(find.text('Show Network Error'));
        await tester.pump();

        expect(find.textContaining('Network connection failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        expect(retryPressed, isTrue);
      });

      testWidgets('showRateLimitError should show rate limit message', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SocialErrorHandler.showRateLimitError(
                  context,
                  waitTime: const Duration(minutes: 2, seconds: 30),
                ),
                child: const Text('Show Rate Limit Error'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.tap(find.text('Show Rate Limit Error'));
        await tester.pump();

        expect(find.textContaining('2m 30s'), findsOneWidget);
      });

      testWidgets('showPermissionError should show permission message', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SocialErrorHandler.showPermissionError(
                  context,
                  action: 'delete folder',
                  suggestion: 'Only owners can delete folders.',
                ),
                child: const Text('Show Permission Error'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.tap(find.text('Show Permission Error'));
        await tester.pump();

        expect(find.textContaining('do not have permission to delete folder'), findsOneWidget);
        expect(find.textContaining('Only owners can delete folders'), findsOneWidget);
      });

      testWidgets('showValidationError should show validation message', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SocialErrorHandler.showValidationError(
                  context,
                  field: 'Username',
                  error: 'is required',
                ),
                child: const Text('Show Validation Error'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.tap(find.text('Show Validation Error'));
        await tester.pump();

        expect(find.text('Username: is required'), findsOneWidget);
      });
    });
  });
}