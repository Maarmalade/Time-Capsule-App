import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/confirmation_dialog.dart';

void main() {
  group('ConfirmationDialog', () {
    testWidgets('displays title and message correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const ConfirmationDialog(
                    title: 'Delete Item',
                    message: 'Are you sure you want to delete this item?',
                    confirmText: 'Delete',
                    icon: Icons.delete,
                  ),
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this item?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('returns true when confirmed', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmationDialog.show(
                    context: context,
                    title: 'Confirm',
                    message: 'Are you sure?',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Confirm the action (tap the second button which is the ElevatedButton)
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isTrue);
    });

    testWidgets('returns false when cancelled', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmationDialog.show(
                    context: context,
                    title: 'Confirm',
                    message: 'Are you sure?',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Cancel the action
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isFalse);
    });
  });
}