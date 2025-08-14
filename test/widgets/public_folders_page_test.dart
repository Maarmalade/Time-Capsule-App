import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:time_capsule/pages/public_folders/public_folders_page.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/services/user_profile_service.dart';
import 'package:time_capsule/models/folder_model.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/widgets/public_folder_card.dart';
import 'package:time_capsule/widgets/error_display_widget.dart';

import 'public_folders_page_test.mocks.dart';

@GenerateMocks([FolderService, UserProfileService, DocumentSnapshot])
void main() {
  group('PublicFoldersPage', () {
    late MockFolderService mockFolderService;
    late MockUserProfileService mockUserProfileService;

    setUp(() {
      mockFolderService = MockFolderService();
      mockUserProfileService = MockUserProfileService();
    });

    Widget createWidget() {
      return MaterialApp(
        home: const PublicFoldersPage(),
      );
    }

    final testFolder = FolderModel(
      id: 'folder1',
      name: 'Test Public Folder',
      userId: 'user1',
      description: 'A test public folder',
      createdAt: DateTime.now(),
    );

    final testOwner = UserProfile(
      id: 'user1',
      email: 'test@example.com',
      username: 'testuser',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('displays loading indicator initially', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays public folders when loaded', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => [testFolder]);

      when(mockUserProfileService.getUserProfile('user1'))
          .thenAnswer((_) async => testOwner);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PublicFolderCard), findsOneWidget);
      expect(find.text('Test Public Folder'), findsOneWidget);
    });

    testWidgets('displays empty state when no folders', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No public folders yet'), findsOneWidget);
      expect(find.text('Public folders will appear here when users share them'), findsOneWidget);
      expect(find.byIcon(Icons.public_off), findsOneWidget);
    });

    testWidgets('displays error when loading fails', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorDisplayWidget), findsOneWidget);
      expect(find.text('Exception: Network error'), findsOneWidget);
    });

    testWidgets('search functionality works', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'test query');
      await tester.pumpAndSettle();

      // Verify search was called with query
      verify(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: 'test query',
      )).called(1);
    });

    testWidgets('clear search button works', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Find and tap clear button
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify search field is cleared
      expect(find.text('test'), findsNothing);
    });

    testWidgets('displays empty search state', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No folders found'), findsOneWidget);
      expect(find.text('Try adjusting your search terms'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);
    });

    testWidgets('refresh functionality works', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => [testFolder]);

      when(mockUserProfileService.getUserProfile('user1'))
          .thenAnswer((_) async => testOwner);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Trigger refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify service was called again
      verify(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).called(greaterThan(1));
    });

    testWidgets('navigation to folder detail works', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => [testFolder]);

      when(mockUserProfileService.getUserProfile('user1'))
          .thenAnswer((_) async => testOwner);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on folder card
      await tester.tap(find.byType(PublicFolderCard));
      await tester.pumpAndSettle();

      // Verify navigation occurred (folder detail page should be pushed)
      expect(find.byType(PublicFoldersPage), findsNothing);
    });

    testWidgets('handles owner loading failure gracefully', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => [testFolder]);

      when(mockUserProfileService.getUserProfile('user1'))
          .thenThrow(Exception('Failed to load owner'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should still display folder card with unknown owner
      expect(find.byType(PublicFolderCard), findsOneWidget);
      expect(find.text('Test Public Folder'), findsOneWidget);
    });

    testWidgets('displays app bar with correct title', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());

      expect(find.text('Public Folders'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('search field has correct placeholder', (tester) async {
      when(mockFolderService.getPublicFolders(
        limit: anyNamed('limit'),
        startAfter: anyNamed('startAfter'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidget());

      expect(find.text('Search public folders...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}