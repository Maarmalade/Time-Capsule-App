import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:time_capsule/pages/memory_album/folder_detail_page.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/shared_folder_data.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/media_service.dart';

import 'folder_detail_page_shared_test.mocks.dart';

@GenerateMocks([FolderService, MediaService, FirebaseAuth, User])
void main() {
  group('FolderDetailPage Shared Functionality', () {
    late MockFolderService mockFolderService;
    late MockMediaService mockMediaService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FolderModel testFolder;
    late SharedFolderData testSharedData;

    setUp(() {
      mockFolderService = MockFolderService();
      mockMediaService = MockMediaService();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Setup test data
      testFolder = FolderModel(
        id: 'folder1',
        name: 'Test Shared Folder',
        userId: 'owner123',
        description: 'A test shared folder',
        createdAt: Timestamp.now(),
      );

      testSharedData = SharedFolderData(
        contributorIds: ['contributor1', 'contributor2'],
        ownerId: 'owner123',
        isLocked: false,
        isPublic: false,
      );

      // Setup auth mocks
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('owner123');
    });

    Widget createWidget() {
      return MaterialApp(home: FolderDetailPage(folder: testFolder));
    }

    testWidgets('shows shared folder indicator in title for shared folders', (
      tester,
    ) async {
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => testSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'owner123'),
      ).thenAnswer((_) async => true);
      when(
        mockFolderService.streamFolders(
          userId: 'owner123',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
    });

    testWidgets('shows locked status for locked shared folders', (
      tester,
    ) async {
      final lockedSharedData = SharedFolderData(
        contributorIds: ['contributor1'],
        ownerId: 'owner123',
        isLocked: true,
        isPublic: false,
        lockedAt: DateTime.now(),
      );

      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => lockedSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'owner123'),
      ).thenAnswer((_) async => false);
      when(
        mockFolderService.streamFolders(
          userId: 'owner123',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Locked • Owner'), findsOneWidget);
    });

    testWidgets('shows contributor status for non-owners', (tester) async {
      when(mockUser.uid).thenReturn('contributor1');
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => testSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'contributor1'),
      ).thenAnswer((_) async => true);
      when(
        mockFolderService.streamFolders(
          userId: 'contributor1',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Contributor'), findsOneWidget);
    });

    testWidgets('shows settings button for folder owners', (tester) async {
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => testSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'owner123'),
      ).thenAnswer((_) async => true);
      when(
        mockFolderService.streamFolders(
          userId: 'owner123',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('hides settings button for contributors', (tester) async {
      when(mockUser.uid).thenReturn('contributor1');
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => testSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'contributor1'),
      ).thenAnswer((_) async => true);
      when(
        mockFolderService.streamFolders(
          userId: 'contributor1',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('shows add button for contributors who can contribute', (
      tester,
    ) async {
      when(mockUser.uid).thenReturn('contributor1');
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => testSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'contributor1'),
      ).thenAnswer((_) async => true);
      when(
        mockFolderService.streamFolders(
          userId: 'contributor1',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows locked message when folder is locked', (tester) async {
      final lockedSharedData = SharedFolderData(
        contributorIds: ['contributor1'],
        ownerId: 'owner123',
        isLocked: true,
        isPublic: false,
        lockedAt: DateTime.now(),
      );

      when(mockUser.uid).thenReturn('contributor1');
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => lockedSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'contributor1'),
      ).thenAnswer((_) async => false);
      when(
        mockFolderService.streamFolders(
          userId: 'contributor1',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('shows view only message for non-contributors', (tester) async {
      when(mockUser.uid).thenReturn('viewer123');
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => testSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'viewer123'),
      ).thenAnswer((_) async => false);
      when(
        mockFolderService.streamFolders(
          userId: 'viewer123',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('View Only'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('prevents adding content when folder is locked', (
      tester,
    ) async {
      final lockedSharedData = SharedFolderData(
        contributorIds: ['owner123'],
        ownerId: 'owner123',
        isLocked: true,
        isPublic: false,
        lockedAt: DateTime.now(),
      );

      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => lockedSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'owner123'),
      ).thenAnswer((_) async => false);
      when(
        mockFolderService.streamFolders(
          userId: 'owner123',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Try to tap the locked add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(
        find.text('This folder is locked and cannot accept new content'),
        findsOneWidget,
      );
    });

    testWidgets('shows shared folder indicator in add menu', (tester) async {
      when(
        mockFolderService.getSharedFolderData('folder1'),
      ).thenAnswer((_) async => testSharedData);
      when(
        mockFolderService.canUserContribute('folder1', 'owner123'),
      ).thenAnswer((_) async => true);
      when(
        mockFolderService.streamFolders(
          userId: 'owner123',
          parentFolderId: 'folder1',
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(
        mockMediaService.streamMedia('folder1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Adding to shared folder'), findsOneWidget);
      expect(
        find.byIcon(Icons.people),
        findsNWidgets(2),
      ); // One in title, one in menu
    });
  });
}
