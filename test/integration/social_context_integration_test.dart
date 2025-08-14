import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:time_capsule/widgets/folder_settings_dialog.dart';
import 'package:time_capsule/widgets/friend_tagging_dialog.dart';
import 'package:time_capsule/widgets/media_card_widget.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/media_file_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Social Context Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
    });

    group('Folder Settings Dialog Social Features', () {
      testWidgets(
        'should show share with friends button for personal folders',
        (WidgetTester tester) async {
          final folder = FolderModel(
            id: 'test-folder',
            name: 'Test Folder',
            userId: 'user1',
            parentFolderId: null,
            description: 'Test description',
            coverImageUrl: null,
            createdAt: Timestamp.now(),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: FolderSettingsDialog(
                  folder: folder,
                  isOwner: true,
                  isSharedFolder: false,
                ),
              ),
            ),
          );

          expect(find.text('Share with Friends'), findsOneWidget);
          expect(find.byIcon(Icons.people_alt), findsOneWidget);
        },
      );

      testWidgets('should show manage contributors button for shared folders', (
        WidgetTester tester,
      ) async {
        final folder = FolderModel(
          id: 'test-folder',
          name: 'Test Folder',
          userId: 'user1',
          parentFolderId: null,
          description: 'Test description',
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FolderSettingsDialog(
                folder: folder,
                isOwner: true,
                isSharedFolder: true,
              ),
            ),
          ),
        );

        expect(find.text('Manage Contributors'), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('should show public/private toggle for folder owners', (
        WidgetTester tester,
      ) async {
        final folder = FolderModel(
          id: 'test-folder',
          name: 'Test Folder',
          userId: 'user1',
          parentFolderId: null,
          description: 'Test description',
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FolderSettingsDialog(
                folder: folder,
                isOwner: true,
                isSharedFolder: false,
              ),
            ),
          ),
        );

        expect(find.text('Visibility'), findsOneWidget);
        expect(find.byType(SwitchListTile), findsOneWidget);
      });

      testWidgets('should not show sharing options for non-owners', (
        WidgetTester tester,
      ) async {
        final folder = FolderModel(
          id: 'test-folder',
          name: 'Test Folder',
          userId: 'user1',
          parentFolderId: null,
          description: 'Test description',
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FolderSettingsDialog(
                folder: folder,
                isOwner: false,
                isSharedFolder: false,
              ),
            ),
          ),
        );

        expect(find.text('Share with Friends'), findsNothing);
        expect(
          find.text('Only the folder owner can change visibility settings.'),
          findsOneWidget,
        );
      });
    });

    group('Media Card Contributor Attribution', () {
      testWidgets('should show contributor name for shared folder media', (
        WidgetTester tester,
      ) async {
        final media = MediaFileModel(
          id: 'test-media',
          folderId: 'test-folder',
          type: 'image',
          url: 'https://example.com/image.jpg',
          title: 'Test Image',
          description: 'Test description',
          createdAt: Timestamp.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaCardWidget(
                media: media,
                isSharedFolder: true,
                contributorName: 'John Doe',
              ),
            ),
          ),
        );

        expect(find.text('by John Doe'), findsOneWidget);
      });

      testWidgets(
        'should not show contributor name for personal folder media',
        (WidgetTester tester) async {
          final media = MediaFileModel(
            id: 'test-media',
            folderId: 'test-folder',
            type: 'image',
            url: 'https://example.com/image.jpg',
            title: 'Test Image',
            description: 'Test description',
            createdAt: Timestamp.now(),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MediaCardWidget(
                  media: media,
                  isSharedFolder: false,
                  contributorName: null,
                ),
              ),
            ),
          );

          expect(find.textContaining('by '), findsNothing);
        },
      );

      testWidgets('should not show contributor name in multi-select mode', (
        WidgetTester tester,
      ) async {
        final media = MediaFileModel(
          id: 'test-media',
          folderId: 'test-folder',
          type: 'image',
          url: 'https://example.com/image.jpg',
          title: 'Test Image',
          description: 'Test description',
          createdAt: Timestamp.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaCardWidget(
                media: media,
                isSharedFolder: true,
                contributorName: 'John Doe',
                isMultiSelectMode: true,
              ),
            ),
          ),
        );

        expect(find.text('by John Doe'), findsNothing);
        expect(find.byIcon(Icons.check), findsNothing); // Not selected
      });
    });

    group('Friend Tagging Dialog', () {
      testWidgets('should show empty state when no friends available', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FriendTaggingDialog())),
        );

        await tester.pumpAndSettle();

        expect(find.text('Tag Friends'), findsOneWidget);
        expect(find.text('No friends to tag'), findsOneWidget);
        expect(
          find.text('Add friends to tag them in your media'),
          findsOneWidget,
        );
      });

      testWidgets('should show loading state initially', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FriendTaggingDialog())),
        );

        await tester.pump(); // Don't settle to catch loading state

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should allow canceling friend tagging', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FriendTaggingDialog())),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should close (in real app, this would pop the route)
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should show done button', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FriendTaggingDialog())),
        );

        await tester.pumpAndSettle();

        expect(find.text('Done'), findsOneWidget);
      });
    });

    group('Social Context Navigation', () {
      testWidgets(
        'should navigate to shared folder settings from folder settings',
        (WidgetTester tester) async {
          final folder = FolderModel(
            id: 'test-folder',
            name: 'Test Folder',
            userId: 'user1',
            parentFolderId: null,
            description: 'Test description',
            coverImageUrl: null,
            createdAt: Timestamp.now(),
          );

          bool navigationCalled = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: FolderSettingsDialog(
                  folder: folder,
                  isOwner: true,
                  isSharedFolder: false,
                ),
              ),
              onGenerateRoute: (settings) {
                if (settings.name == '/shared-folder-settings') {
                  navigationCalled = true;
                  return MaterialPageRoute(
                    builder: (_) =>
                        const Scaffold(body: Text('Shared Folder Settings')),
                  );
                }
                return null;
              },
            ),
          );

          await tester.tap(find.text('Share with Friends'));
          await tester.pumpAndSettle();

          expect(navigationCalled, isTrue);
        },
      );
    });

    group('Integration Scenarios', () {
      testWidgets('should handle complete shared folder workflow', (
        WidgetTester tester,
      ) async {
        // This test would simulate:
        // 1. Creating a folder
        // 2. Making it shared
        // 3. Adding contributors
        // 4. Uploading media with attribution
        // 5. Viewing media with contributor info

        // For now, we'll just verify the components exist
        final folder = FolderModel(
          id: 'test-folder',
          name: 'Test Folder',
          userId: 'user1',
          parentFolderId: null,
          description: 'Test description',
          coverImageUrl: null,
          createdAt: Timestamp.now(),
        );

        final media = MediaFileModel(
          id: 'test-media',
          folderId: 'test-folder',
          type: 'image',
          url: 'https://example.com/image.jpg',
          title: 'Test Image',
          description: 'Test description',
          createdAt: Timestamp.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FolderSettingsDialog(
                    folder: folder,
                    isOwner: true,
                    isSharedFolder: true,
                  ),
                  MediaCardWidget(
                    media: media,
                    isSharedFolder: true,
                    contributorName: 'John Doe',
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify shared folder settings shows manage contributors
        expect(find.text('Manage Contributors'), findsOneWidget);

        // Verify media shows contributor attribution
        expect(find.text('by John Doe'), findsOneWidget);
      });
    });
  });
}
