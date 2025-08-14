import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:time_capsule/widgets/folder_settings_dialog.dart';
import 'package:time_capsule/services/folder_service.dart';
import 'package:time_capsule/models/folder_model.dart';

import 'folder_settings_dialog_test.mocks.dart';

@GenerateMocks([FolderService])
void main() {
  group('FolderSettingsDialog', () {
    late MockFolderService mockFolderService;

    setUp(() {
      mockFolderService = MockFolderService();
    });

    final testFolder = FolderModel(
      id: 'folder1',
      name: 'Test Folder',
      userId: 'user1',
      createdAt: Timestamp.fromDate(DateTime.now()),
    );

    Widget createWidget({
      FolderModel? folder,
      bool isOwner = true,
      bool isSharedFolder = false,
      VoidCallback? onSettingsChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FolderSettingsDialog(
            folder: folder ?? testFolder,
            isOwner: isOwner,
            isSharedFolder: isSharedFolder,
            onSettingsChanged: onSettingsChanged,
          ),
        ),
      );
    }

    testWidgets('displays folder information correctly', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Folder Settings'), findsOneWidget);
      expect(find.text('Test Folder'), findsOneWidget);
      expect(find.text('Personal Folder'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('displays shared folder indicator', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget(isSharedFolder: true));
      await tester.pumpAndSettle();

      expect(find.text('Shared Folder'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('displays loading indicator initially', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays private folder settings when loaded', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Visibility'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(
        find.text('Only you and contributors can view this folder'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('displays public folder settings when loaded', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Visibility'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Anyone can view this folder'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('displays error when loading fails', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading settings'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button works after error', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Verify service was called again
      verify(mockFolderService.isFolderPublic('folder1')).called(2);
    });

    testWidgets('toggle switch works for making folder public', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);
      when(mockFolderService.makePublic('folder1')).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap the switch
      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsOneWidget);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Make Folder Public'), findsOneWidget);
      expect(
        find.textContaining('This will make your folder visible to all users'),
        findsOneWidget,
      );
    });

    testWidgets('toggle switch works for making folder private', (
      tester,
    ) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => true);
      when(mockFolderService.makePrivate('folder1')).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap the switch
      final switchTile = find.byType(SwitchListTile);
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Make Folder Private'), findsOneWidget);
      expect(
        find.textContaining('This will make your folder private'),
        findsOneWidget,
      );
    });

    testWidgets('confirmation dialog can be cancelled', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap switch to show confirmation
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Cancel the confirmation
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Service should not be called
      verifyNever(mockFolderService.makePublic(any));
    });

    testWidgets('shows non-owner message when user is not owner', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(isOwner: false));
      await tester.pumpAndSettle();

      expect(
        find.text('Only the folder owner can change visibility settings.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('close button works', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(FolderSettingsDialog), findsNothing);
    });

    testWidgets('calls onSettingsChanged when visibility changes', (
      tester,
    ) async {
      bool settingsChanged = false;

      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);
      when(mockFolderService.makePublic('folder1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        createWidget(onSettingsChanged: () => settingsChanged = true),
      );
      await tester.pumpAndSettle();

      // Tap switch and confirm
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Make Public'));
      await tester.pumpAndSettle();

      expect(settingsChanged, isTrue);
    });

    testWidgets('displays correct info text for public folders', (
      tester,
    ) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Public folders appear in the public folder discovery page',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays correct info text for private folders', (
      tester,
    ) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Private folders are only visible to you'),
        findsOneWidget,
      );
    });

    testWidgets('handles service errors gracefully', (tester) async {
      when(
        mockFolderService.isFolderPublic('folder1'),
      ).thenAnswer((_) async => false);
      when(
        mockFolderService.makePublic('folder1'),
      ).thenThrow(Exception('Service error'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap switch and confirm
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Make Public'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(
        find.textContaining('Failed to update folder visibility'),
        findsOneWidget,
      );
    });
  });
}
