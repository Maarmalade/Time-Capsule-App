import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/batch_action_bar.dart';

void main() {
  group('BatchActionBar', () {
    testWidgets('should display selection count', (WidgetTester tester) async {
      bool deleteCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 3,
              onDelete: () => deleteCalled = true,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('3 selected'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should call onCancel when cancel button is tapped', (WidgetTester tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 2,
              onDelete: () {},
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelCalled, true);
    });

    testWidgets('should call onDelete when delete button is tapped', (WidgetTester tester) async {
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 2,
              onDelete: () => deleteCalled = true,
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(deleteCalled, true);
    });

    testWidgets('should show delete button as disabled when no items selected', (WidgetTester tester) async {
      bool deleteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 0,
              onDelete: () => deleteCalled = true,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Try to tap the delete button - it should be disabled
      await tester.tap(find.text('Delete'));
      await tester.pump();
      
      // Delete should not have been called since button is disabled
      expect(deleteCalled, false);
    });

    testWidgets('should show delete button as enabled when items are selected', (WidgetTester tester) async {
      bool deleteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 1,
              onDelete: () => deleteCalled = true,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Tap the delete button - it should be enabled
      await tester.tap(find.text('Delete'));
      await tester.pump();
      
      // Delete should have been called since button is enabled
      expect(deleteCalled, true);
    });

    testWidgets('should handle large selection counts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 99,
              onDelete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('99 selected'), findsOneWidget);
    });

    testWidgets('should show delete icon in button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 1,
              onDelete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should show close icon in cancel button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchActionBar(
              selectedCount: 1,
              onDelete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}