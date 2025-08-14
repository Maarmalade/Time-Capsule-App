import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:time_capsule/widgets/public_folder_card.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/widgets/profile_picture_widget.dart';

void main() {
  group('PublicFolderCard', () {
    final testFolder = FolderModel(
      id: 'folder1',
      name: 'Test Public Folder',
      userId: 'user1',
      description: 'A test public folder description',
      createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
    );

    final testOwner = UserProfile(
      id: 'user1',
      email: 'test@example.com',
      username: 'testuser',
      profilePictureUrl: 'https://example.com/profile.jpg',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    Widget createWidget({
      FolderModel? folder,
      UserProfile? owner,
      VoidCallback? onTap,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PublicFolderCard(
            folder: folder ?? testFolder,
            owner: owner,
            onTap: onTap,
            isLoading: isLoading,
          ),
        ),
      );
    }

    testWidgets('displays folder information correctly', (tester) async {
      await tester.pumpWidget(createWidget(owner: testOwner));

      expect(find.text('Test Public Folder'), findsOneWidget);
      expect(find.text('A test public folder description'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('displays owner information when provided', (tester) async {
      await tester.pumpWidget(createWidget(owner: testOwner));

      expect(find.text('Created by'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.byType(ProfilePictureWidget), findsOneWidget);
    });

    testWidgets('displays unknown owner when owner is null', (tester) async {
      await tester.pumpWidget(createWidget(owner: null));

      expect(find.text('Created by'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays loading state when isLoading is true', (tester) async {
      await tester.pumpWidget(createWidget(isLoading: true));

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('handles tap events', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(createWidget(
        owner: testOwner,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(PublicFolderCard));
      expect(tapped, isTrue);
    });

    testWidgets('disables tap when loading', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(createWidget(
        isLoading: true,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(PublicFolderCard));
      expect(tapped, isFalse);
    });

    testWidgets('displays folder without description', (tester) async {
      final folderWithoutDescription = FolderModel(
        id: 'folder1',
        name: 'Test Folder',
        userId: 'user1',
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
      );

      await tester.pumpWidget(createWidget(
        folder: folderWithoutDescription,
        owner: testOwner,
      ));

      expect(find.text('Test Folder'), findsOneWidget);
      expect(find.text('A test public folder description'), findsNothing);
    });

    testWidgets('formats date correctly', (tester) async {
      final recentFolder = FolderModel(
        id: 'folder1',
        name: 'Recent Folder',
        userId: 'user1',
        createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      );

      await tester.pumpWidget(createWidget(
        folder: recentFolder,
        owner: testOwner,
      ));

      expect(find.text('2d ago'), findsOneWidget);
    });

    testWidgets('truncates long folder names', (tester) async {
      final longNameFolder = FolderModel(
        id: 'folder1',
        name: 'This is a very long folder name that should be truncated when displayed in the card widget',
        userId: 'user1',
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
      );

      await tester.pumpWidget(createWidget(
        folder: longNameFolder,
        owner: testOwner,
      ));

      // The text should be present but truncated with ellipsis
      expect(find.textContaining('This is a very long folder name'), findsOneWidget);
    });

    testWidgets('truncates long descriptions', (tester) async {
      final longDescFolder = FolderModel(
        id: 'folder1',
        name: 'Test Folder',
        userId: 'user1',
        description: 'This is a very long description that should be truncated when displayed in the card widget because it exceeds the maximum number of lines allowed for the description text in the public folder card component',
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
      );

      await tester.pumpWidget(createWidget(
        folder: longDescFolder,
        owner: testOwner,
      ));

      // The description should be present but truncated
      expect(find.textContaining('This is a very long description'), findsOneWidget);
    });

    testWidgets('displays correct card styling', (tester) async {
      await tester.pumpWidget(createWidget(owner: testOwner));

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });

    group('date formatting', () {
      testWidgets('formats years correctly', (tester) async {
        final oldFolder = FolderModel(
          id: 'folder1',
          name: 'Old Folder',
          userId: 'user1',
          createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 400))),
        );

        await tester.pumpWidget(createWidget(
          folder: oldFolder,
          owner: testOwner,
        ));

        expect(find.text('1y ago'), findsOneWidget);
      });

      testWidgets('formats months correctly', (tester) async {
        final monthOldFolder = FolderModel(
          id: 'folder1',
          name: 'Month Old Folder',
          userId: 'user1',
          createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 35))),
        );

        await tester.pumpWidget(createWidget(
          folder: monthOldFolder,
          owner: testOwner,
        ));

        expect(find.text('1mo ago'), findsOneWidget);
      });

      testWidgets('formats hours correctly', (tester) async {
        final hourOldFolder = FolderModel(
          id: 'folder1',
          name: 'Hour Old Folder',
          userId: 'user1',
          createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        );

        await tester.pumpWidget(createWidget(
          folder: hourOldFolder,
          owner: testOwner,
        ));

        expect(find.text('2h ago'), findsOneWidget);
      });

      testWidgets('formats minutes correctly', (tester) async {
        final minuteOldFolder = FolderModel(
          id: 'folder1',
          name: 'Minute Old Folder',
          userId: 'user1',
          createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
        );

        await tester.pumpWidget(createWidget(
          folder: minuteOldFolder,
          owner: testOwner,
        ));

        expect(find.text('30m ago'), findsOneWidget);
      });

      testWidgets('shows "Just now" for very recent folders', (tester) async {
        final veryRecentFolder = FolderModel(
          id: 'folder1',
          name: 'Very Recent Folder',
          userId: 'user1',
          createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(seconds: 30))),
        );

        await tester.pumpWidget(createWidget(
          folder: veryRecentFolder,
          owner: testOwner,
        ));

        expect(find.text('Just now'), findsOneWidget);
      });
    });
  });
}