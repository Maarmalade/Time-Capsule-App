import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/pages/friends/friend_requests_page.dart';

void main() {
  group('FriendRequestsPage', () {
    testWidgets('displays app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      // Should display app bar with title
      expect(find.text('Friend Requests'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      // Should display loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading friend requests...'), findsOneWidget);
    });

    testWidgets('has proper widget structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FriendRequestsPage(),
        ),
      );

      // Should have scaffold structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}