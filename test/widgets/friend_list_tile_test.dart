import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/models/user_profile.dart';
import 'package:time_capsule/widgets/friend_list_tile.dart';

void main() {
  group('FriendListTile', () {
    late UserProfile mockFriend;

    setUp(() {
      mockFriend = UserProfile(
        id: 'friend123',
        email: 'friend@example.com',
        username: 'jane_doe',
        profilePictureUrl: 'https://example.com/profile.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget({
      UserProfile? friend,
      VoidCallback? onTap,
      Widget? trailing,
      bool showOnlineStatus = false,
      bool isOnline = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FriendListTile(
            friend: friend ?? mockFriend,
            onTap: onTap,
            trailing: trailing,
            showOnlineStatus: showOnlineStatus,
            isOnline: isOnline,
          ),
        ),
      );
    }

    testWidgets('displays friend information correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('jane_doe'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onTap: () => tapCalled = true,
      ));

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    testWidgets('displays trailing widget when provided', (tester) async {
      const trailingWidget = Icon(Icons.more_vert);
      
      await tester.pumpWidget(createTestWidget(
        trailing: trailingWidget,
      ));

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows online status when enabled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        showOnlineStatus: true,
        isOnline: true,
      ));

      expect(find.text('Online'), findsOneWidget);
      
      // Check for green online indicator
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(Container),
        ).last,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
    });

    testWidgets('shows offline status when enabled and offline', (tester) async {
      await tester.pumpWidget(createTestWidget(
        showOnlineStatus: true,
        isOnline: false,
      ));

      expect(find.text('Offline'), findsOneWidget);
      
      // Check for grey offline indicator
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(Container),
        ).last,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey);
    });

    testWidgets('does not show online status when disabled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        showOnlineStatus: false,
      ));

      expect(find.text('Online'), findsNothing);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('handles friend without profile picture', (tester) async {
      final friendWithoutPicture = mockFriend.copyWith(
        profilePictureUrl: null,
      );

      await tester.pumpWidget(createTestWidget(
        friend: friendWithoutPicture,
      ));

      // Should still show avatar (default one)
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('jane_doe'), findsOneWidget);
    });
  });

  group('SelectableFriendListTile', () {
    late UserProfile mockFriend;

    setUp(() {
      mockFriend = UserProfile(
        id: 'friend123',
        email: 'friend@example.com',
        username: 'jane_doe',
        profilePictureUrl: 'https://example.com/profile.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget({
      UserProfile? friend,
      bool isSelected = false,
      ValueChanged<bool?>? onChanged,
      bool enabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SelectableFriendListTile(
            friend: friend ?? mockFriend,
            isSelected: isSelected,
            onChanged: onChanged,
            enabled: enabled,
          ),
        ),
      );
    }

    testWidgets('displays friend information correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('jane_doe'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('shows selected state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: true));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('shows unselected state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: false));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('calls onChanged when checkbox is tapped', (tester) async {
      bool? changedValue;
      
      await tester.pumpWidget(createTestWidget(
        isSelected: false,
        onChanged: (value) => changedValue = value,
      ));

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(changedValue, isTrue);
    });

    testWidgets('disables interaction when disabled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        enabled: false,
        onChanged: (value) {},
      ));

      final checkboxListTile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkboxListTile.onChanged, isNull);
    });

    testWidgets('shows disabled styling when disabled', (tester) async {
      await tester.pumpWidget(createTestWidget(enabled: false));

      // The text should have reduced opacity when disabled
      final text = tester.widget<Text>(find.text('jane_doe'));
      expect(text.style?.color?.opacity, lessThan(1.0));
    });

    testWidgets('handles null onChanged callback', (tester) async {
      await tester.pumpWidget(createTestWidget(onChanged: null));

      final checkboxListTile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkboxListTile.onChanged, isNull);
    });

    testWidgets('positions checkbox as trailing element', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final checkboxListTile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkboxListTile.controlAffinity, ListTileControlAffinity.trailing);
    });
  });
}