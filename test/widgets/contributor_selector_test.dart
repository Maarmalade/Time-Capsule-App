import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/widgets/contributor_selector.dart';

void main() {
  group('ContributorSelector', () {
    late List<UserProfile> mockFriends;

    setUp(() {
      mockFriends = [
        UserProfile(
          id: 'friend1',
          email: 'friend1@example.com',
          username: 'alice_smith',
          profilePictureUrl: 'https://example.com/alice.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'friend2',
          email: 'friend2@example.com',
          username: 'bob_jones',
          profilePictureUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'friend3',
          email: 'friend3@example.com',
          username: 'charlie_brown',
          profilePictureUrl: 'https://example.com/charlie.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    Widget createTestWidget({
      List<UserProfile>? availableFriends,
      List<String> selectedContributorIds = const [],
      ValueChanged<List<String>>? onSelectionChanged,
      String? title,
      String? subtitle,
      bool allowEmpty = true,
      int? maxSelections,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ContributorSelector(
            availableFriends: availableFriends ?? mockFriends,
            selectedContributorIds: selectedContributorIds,
            onSelectionChanged: onSelectionChanged ?? (ids) {},
            title: title,
            subtitle: subtitle,
            allowEmpty: allowEmpty,
            maxSelections: maxSelections,
          ),
        ),
      );
    }

    testWidgets('displays all available friends', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('alice_smith'), findsOneWidget);
      expect(find.text('bob_jones'), findsOneWidget);
      expect(find.text('charlie_brown'), findsOneWidget);
    });

    testWidgets('displays title when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        title: 'Select Contributors',
      ));

      expect(find.text('Select Contributors'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        subtitle: 'Choose friends to collaborate with',
      ));

      expect(find.text('Choose friends to collaborate with'), findsOneWidget);
    });

    testWidgets('shows selection count correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedContributorIds: ['friend1', 'friend2'],
      ));

      expect(find.text('2 of 3 selected'), findsOneWidget);
    });

    testWidgets('shows selected friends as checked', (tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedContributorIds: ['friend1'],
      ));

      // Find the checkbox for alice_smith and verify it's checked
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3));

      // The first checkbox should be checked
      final firstCheckbox = tester.widget<Checkbox>(checkboxes.first);
      expect(firstCheckbox.value, isTrue);
    });

    testWidgets('calls onSelectionChanged when friend is selected', (tester) async {
      List<String> selectedIds = [];
      
      await tester.pumpWidget(createTestWidget(
        onSelectionChanged: (ids) => selectedIds = ids,
      ));

      // Tap the first friend's checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(selectedIds, contains('friend1'));
    });

    testWidgets('calls onSelectionChanged when friend is deselected', (tester) async {
      List<String> selectedIds = ['friend1'];
      
      await tester.pumpWidget(createTestWidget(
        selectedContributorIds: ['friend1'],
        onSelectionChanged: (ids) => selectedIds = ids,
      ));

      // Tap the first friend's checkbox to deselect
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(selectedIds, isEmpty);
    });

    testWidgets('shows search field when many friends available', (tester) async {
      // Add more friends to trigger search field
      final manyFriends = List.generate(10, (index) => UserProfile(
        id: 'friend$index',
        email: 'friend$index@example.com',
        username: 'friend_$index',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestWidget(
        availableFriends: manyFriends,
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search friends...'), findsOneWidget);
    });

    testWidgets('filters friends based on search query', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter search query
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();

      expect(find.text('alice_smith'), findsOneWidget);
      expect(find.text('bob_jones'), findsNothing);
      expect(find.text('charlie_brown'), findsNothing);
    });

    testWidgets('shows clear button when friends are selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedContributorIds: ['friend1'],
      ));

      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('clears selection when clear button is tapped', (tester) async {
      List<String> selectedIds = ['friend1'];
      
      await tester.pumpWidget(createTestWidget(
        selectedContributorIds: ['friend1'],
        onSelectionChanged: (ids) => selectedIds = ids,
      ));

      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(selectedIds, isEmpty);
    });

    testWidgets('shows select all button when not all selected', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Select All'), findsOneWidget);
    });

    testWidgets('selects all friends when select all is tapped', (tester) async {
      List<String> selectedIds = [];
      
      await tester.pumpWidget(createTestWidget(
        onSelectionChanged: (ids) => selectedIds = ids,
      ));

      await tester.tap(find.text('Select All'));
      await tester.pump();

      expect(selectedIds.length, equals(3));
      expect(selectedIds, containsAll(['friend1', 'friend2', 'friend3']));
    });

    testWidgets('respects max selections limit', (tester) async {
      List<String> selectedIds = [];
      
      await tester.pumpWidget(createTestWidget(
        maxSelections: 2,
        onSelectionChanged: (ids) => selectedIds = ids,
      ));

      // Select first two friends
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pump();
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();

      expect(selectedIds.length, equals(2));

      // Try to select third friend - should show snackbar
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pump();

      expect(selectedIds.length, equals(2)); // Should still be 2
      expect(find.text('Maximum 2 contributors allowed'), findsOneWidget);
    });

    testWidgets('select all respects max selections limit', (tester) async {
      List<String> selectedIds = [];
      
      await tester.pumpWidget(createTestWidget(
        maxSelections: 2,
        onSelectionChanged: (ids) => selectedIds = ids,
      ));

      await tester.tap(find.text('Select All'));
      await tester.pump();

      expect(selectedIds.length, equals(2)); // Should only select 2
    });

    testWidgets('shows empty state when no friends available', (tester) async {
      await tester.pumpWidget(createTestWidget(
        availableFriends: [],
      ));

      expect(find.text('No friends available'), findsOneWidget);
      expect(find.text('Add some friends first to invite them as contributors'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('shows empty search state when no matches found', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();

      expect(find.text('No friends found'), findsOneWidget);
      expect(find.text('Try a different search term'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('updates when selectedContributorIds prop changes', (tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedContributorIds: [],
      ));

      expect(find.text('0 of 3 selected'), findsOneWidget);

      // Update with new selection
      await tester.pumpWidget(createTestWidget(
        selectedContributorIds: ['friend1', 'friend2'],
      ));

      expect(find.text('2 of 3 selected'), findsOneWidget);
    });
  });

  group('ContributorSelectorDialog', () {
    late List<UserProfile> mockFriends;

    setUp(() {
      mockFriends = [
        UserProfile(
          id: 'friend1',
          email: 'friend1@example.com',
          username: 'alice_smith',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserProfile(
          id: 'friend2',
          email: 'friend2@example.com',
          username: 'bob_jones',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    Widget createTestWidget({
      List<UserProfile>? availableFriends,
      List<String> initialSelectedIds = const [],
      String? title,
      String? subtitle,
      int? maxSelections,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showContributorSelectorDialog(
                context: context,
                availableFriends: availableFriends ?? mockFriends,
                initialSelectedIds: initialSelectedIds,
                title: title,
                subtitle: subtitle,
                maxSelections: maxSelections,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('shows dialog when called', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Select Contributors'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('returns selected IDs when done is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Select a friend
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Tap done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('returns null when cancelled', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('uses custom title when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        title: 'Custom Title',
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Title'), findsOneWidget);
    });

    testWidgets('shows initial selected friends', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialSelectedIds: ['friend1'],
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 selected'), findsOneWidget);
    });
  });
}