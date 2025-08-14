import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_capsule/routes.dart';

void main() {
  group('Social Features Navigation Tests', () {
    group('Route Constants', () {
      test('should have correct route constants', () {
        expect(Routes.friends, equals('/friends'));
        expect(Routes.addFriend, equals('/add-friend'));
        expect(Routes.friendRequests, equals('/friend-requests'));
        expect(Routes.scheduledMessages, equals('/scheduled-messages'));
        expect(Routes.deliveredMessages, equals('/delivered-messages'));
        expect(Routes.publicFolders, equals('/public-folders'));
        expect(Routes.sharedFolderSettings, equals('/shared-folder-settings'));
      });
    });

    group('Route Generation', () {
      testWidgets('should generate route for friends page', (
        WidgetTester tester,
      ) async {
        final route = generateRoute(const RouteSettings(name: Routes.friends));
        expect(route, isA<MaterialPageRoute>());
      });

      testWidgets('should generate route for add friend page', (
        WidgetTester tester,
      ) async {
        final route = generateRoute(
          const RouteSettings(name: Routes.addFriend),
        );
        expect(route, isA<MaterialPageRoute>());
      });

      testWidgets('should generate route for friend requests page', (
        WidgetTester tester,
      ) async {
        final route = generateRoute(
          const RouteSettings(name: Routes.friendRequests),
        );
        expect(route, isA<MaterialPageRoute>());
      });

      testWidgets('should generate route for scheduled messages page', (
        WidgetTester tester,
      ) async {
        final route = generateRoute(
          const RouteSettings(name: Routes.scheduledMessages),
        );
        expect(route, isA<MaterialPageRoute>());
      });

      testWidgets('should generate route for delivered messages page', (
        WidgetTester tester,
      ) async {
        final route = generateRoute(
          const RouteSettings(name: Routes.deliveredMessages),
        );
        expect(route, isA<MaterialPageRoute>());
      });

      testWidgets('should generate route for public folders page', (
        WidgetTester tester,
      ) async {
        final route = generateRoute(
          const RouteSettings(name: Routes.publicFolders),
        );
        expect(route, isA<MaterialPageRoute>());
      });

      testWidgets('should handle shared folder settings without folder', (
        WidgetTester tester,
      ) async {
        final route = generateRoute(
          RouteSettings(
            name: Routes.sharedFolderSettings,
            arguments: {'folderId': 'test-folder-id'},
          ),
        );
        expect(route, isA<MaterialPageRoute>());
      });
    });

    group('Deep Linking Tests', () {
      testWidgets('should handle deep link to friends page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: Routes.friends,
            onGenerateRoute: generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Friends'), findsOneWidget);
      });

      testWidgets('should handle deep link to add friend page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: Routes.addFriend,
            onGenerateRoute: generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Add Friend'), findsOneWidget);
      });

      testWidgets('should handle deep link to friend requests page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: Routes.friendRequests,
            onGenerateRoute: generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Friend Requests'), findsOneWidget);
      });

      testWidgets('should handle deep link to scheduled messages page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: Routes.scheduledMessages,
            onGenerateRoute: generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scheduled Messages'), findsOneWidget);
      });

      testWidgets('should handle deep link to delivered messages page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: Routes.deliveredMessages,
            onGenerateRoute: generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Delivered Messages'), findsOneWidget);
      });

      testWidgets('should handle deep link to public folders page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: Routes.publicFolders,
            onGenerateRoute: generateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Public Folders'), findsOneWidget);
      });
    });

    group('Route Parameter Tests', () {
      testWidgets('should handle missing folder in shared folder settings', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.sharedFolderSettings);
                  },
                  child: const Text('Navigate'),
                ),
              ),
            ),
            onGenerateRoute: generateRoute,
          ),
        );

        await tester.tap(find.text('Navigate'));
        await tester.pumpAndSettle();

        expect(find.text('Folder information is required'), findsOneWidget);
      });
    });
  });
}
