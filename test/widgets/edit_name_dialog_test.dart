import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/widgets/edit_name_dialog.dart';

void main() {
  group('EditNameDialog', () {
    testWidgets('displays current name and allows editing', (WidgetTester tester) async {
      const currentName = 'Test Folder';
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (context) => const EditNameDialog(
                      currentName: currentName,
                      title: 'Edit Folder Name',
                      hintText: 'Enter folder name',
                    ),
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

      // Verify dialog is displayed with current name
      expect(find.text('Edit Folder Name'), findsOneWidget);
      expect(find.text(currentName), findsOneWidget);

      // Edit the name
      await tester.enterText(find.byType(TextField), 'New Folder Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the result
      expect(result, equals('New Folder Name'));
    });

    testWidgets('cancels without returning value', (WidgetTester tester) async {
      String? result = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (context) => const EditNameDialog(
                      currentName: 'Test',
                      title: 'Edit Name',
                      hintText: 'Enter name',
                    ),
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

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify no result is returned
      expect(result, isNull);
    });
  });
}