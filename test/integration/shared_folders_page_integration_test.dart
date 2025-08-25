import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_capsule/pages/friends/shared_folders_page.dart';
import 'package:time_capsule/models/user_profile.dart';

void main() {
  group('SharedFoldersPage Integration Tests', () {
    testWidgets('displays friend name in app bar', (WidgetTester tester) async {
      // Arrange
      final testFriend = UserProfile(
        id: 'friend123',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SharedFoldersPage(friend: testFriend),
        ),
      );

      // Assert
      expect(find.text('Shared with testfriend'), findsOneWidget);
    });

    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      final testFriend = UserProfile(
        id: 'friend123',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SharedFoldersPage(friend: testFriend),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading shared folders...'), findsOneWidget);
    });

    testWidgets('has refresh button in app bar', (WidgetTester tester) async {
      // Arrange
      final testFriend = UserProfile(
        id: 'friend123',
        username: 'testfriend',
        email: 'friend@test.com',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SharedFoldersPage(friend: testFriend),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}