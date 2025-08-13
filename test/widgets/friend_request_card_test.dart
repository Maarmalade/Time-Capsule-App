import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/friend_request_model.dart';
import 'package:time_capsule/widgets/friend_request_card.dart';

void main() {
  group('FriendRequestCard', () {
    late FriendRequest mockFriendRequest;

    setUp(() {
      mockFriendRequest = FriendRequest(
        id: 'request123',
        senderId: 'sender123',
        receiverId: 'receiver123',
        senderUsername: 'john_doe',
        senderProfilePictureUrl: 'https://example.com/profile.jpg',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
    });

    Widget createTestWidget({
      FriendRequest? friendRequest,
      VoidCallback? onAccept,
      VoidCallback? onDecline,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FriendRequestCard(
            friendRequest: friendRequest ?? mockFriendRequest,
            onAccept: onAccept,
            onDecline: onDecline,
            isLoading: isLoading,
          ),
        ),
      );
    }

    testWidgets('displays friend request information correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('john_doe'), findsOneWidget);
      expect(find.text('Wants to be your friend'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('shows profile picture when URL is provided', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Profile picture widget should be present
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('shows default avatar when no profile picture URL', (tester) async {
      final requestWithoutPicture = mockFriendRequest.copyWith(
        senderProfilePictureUrl: null,
      );

      await tester.pumpWidget(createTestWidget(
        friendRequest: requestWithoutPicture,
      ));

      // Should still show avatar (default one)
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('calls onAccept when accept button is tapped', (tester) async {
      bool acceptCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onAccept: () => acceptCalled = true,
      ));

      await tester.tap(find.text('Accept'));
      await tester.pump();

      expect(acceptCalled, isTrue);
    });

    testWidgets('calls onDecline when decline button is tapped', (tester) async {
      bool declineCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onDecline: () => declineCalled = true,
      ));

      await tester.tap(find.text('Decline'));
      await tester.pump();

      expect(declineCalled, isTrue);
    });

    testWidgets('disables buttons when loading', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoading: true));

      final acceptButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept'),
      );
      final declineButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Decline'),
      );

      expect(acceptButton.onPressed, isNull);
      expect(declineButton.onPressed, isNull);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('formats time correctly for different durations', (tester) async {
      // Test minutes ago
      final minutesAgo = mockFriendRequest.copyWith(
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      await tester.pumpWidget(createTestWidget(friendRequest: minutesAgo));
      expect(find.text('30m ago'), findsOneWidget);

      // Test days ago
      final daysAgo = mockFriendRequest.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      await tester.pumpWidget(createTestWidget(friendRequest: daysAgo));
      await tester.pump();
      expect(find.text('2d ago'), findsOneWidget);

      // Test just now
      final justNow = mockFriendRequest.copyWith(
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      await tester.pumpWidget(createTestWidget(friendRequest: justNow));
      await tester.pump();
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('handles null callbacks gracefully', (tester) async {
      await tester.pumpWidget(createTestWidget(
        onAccept: null,
        onDecline: null,
      ));

      // Should not crash and buttons should be disabled
      final acceptButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept'),
      );
      final declineButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Decline'),
      );

      expect(acceptButton.onPressed, isNull);
      expect(declineButton.onPressed, isNull);
    });

    testWidgets('displays correct icons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('has proper card styling', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Card), findsOneWidget);
      
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
    });
  });
}