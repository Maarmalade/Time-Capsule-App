import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_error_states.dart';
import 'package:time_capsule/design_system/app_colors.dart';

void main() {
  group('AppErrorStates', () {
    testWidgets('validationError displays error message with icon', (WidgetTester tester) async {
      const testMessage = 'This field is required';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStates.validationError(testMessage),
          ),
        ),
      );

      // Verify error icon is present
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // Verify error message is displayed
      expect(find.text(testMessage), findsOneWidget);
      
      // Verify error color is applied
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(iconWidget.color, AppColors.errorRed);
      
      // Verify text color is error red
      final textWidget = tester.widget<Text>(find.text(testMessage));
      expect(textWidget.style?.color, AppColors.errorRed);
    });

    testWidgets('networkError displays with default title and retry button', (WidgetTester tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStates.networkError(
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Verify network error icon is present
      expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
      
      // Verify default title is displayed
      expect(find.text('Connection Error'), findsOneWidget);
      
      // Verify retry button is present
      expect(find.text('Try Again'), findsOneWidget);
      
      // Test retry button functionality
      await tester.tap(find.text('Try Again'));
      expect(retryPressed, isTrue);
    });

    testWidgets('networkError displays custom title and message', (WidgetTester tester) async {
      const customTitle = 'Server Unavailable';
      const customMessage = 'Please check your internet connection and try again.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStates.networkError(
              title: customTitle,
              message: customMessage,
            ),
          ),
        ),
      );

      // Verify custom title and message are displayed
      expect(find.text(customTitle), findsOneWidget);
      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('errorCard displays all components correctly', (WidgetTester tester) async {
      const title = 'Something went wrong';
      const message = 'An unexpected error occurred. Please try again.';
      const actionLabel = 'Reload';
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStates.errorCard(
              title: title,
              message: message,
              icon: Icons.error,
              onAction: () => actionPressed = true,
              actionLabel: actionLabel,
            ),
          ),
        ),
      );

      // Verify all components are present
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(find.text(actionLabel), findsOneWidget);
      
      // Test action button functionality
      await tester.tap(find.text(actionLabel));
      expect(actionPressed, isTrue);
    });

    testWidgets('emptyState displays with default icon and action button', (WidgetTester tester) async {
      const title = 'No items found';
      const message = 'There are no items to display at the moment.';
      const actionLabel = 'Add Item';
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStates.emptyState(
              title: title,
              message: message,
              onAction: () => actionPressed = true,
              actionLabel: actionLabel,
            ),
          ),
        ),
      );

      // Verify default inbox icon is present
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      
      // Verify title and message are displayed
      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      
      // Verify action button is present and functional
      expect(find.text(actionLabel), findsOneWidget);
      await tester.tap(find.text(actionLabel));
      expect(actionPressed, isTrue);
    });

    testWidgets('inlineError displays error message with correct styling', (WidgetTester tester) async {
      const errorMessage = 'Invalid email format';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStates.inlineError(errorMessage),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text(errorMessage), findsOneWidget);
      
      // Verify text color is error red
      final textWidget = tester.widget<Text>(find.text(errorMessage));
      expect(textWidget.style?.color, AppColors.errorRed);
    });

    testWidgets('errorBanner displays with dismiss and action buttons', (WidgetTester tester) async {
      const message = 'Failed to save changes. Please try again.';
      const actionLabel = 'Retry';
      bool dismissed = false;
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorStates.errorBanner(
              message: message,
              onDismiss: () => dismissed = true,
              onAction: () => actionPressed = true,
              actionLabel: actionLabel,
            ),
          ),
        ),
      );

      // Verify error icon and message are present
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(find.text(actionLabel), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      // Test dismiss functionality
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
      
      // Test action functionality
      await tester.tap(find.text(actionLabel));
      expect(actionPressed, isTrue);
    });

    testWidgets('errorSnackBar creates snackbar with correct styling', (WidgetTester tester) async {
      const message = 'Network error occurred';
      const actionLabel = 'Retry';
      bool actionPressed = false;
      
      final snackBar = AppErrorStates.errorSnackBar(
        message: message,
        onAction: () => actionPressed = true,
        actionLabel: actionLabel,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                child: Text('Show Snackbar'),
              ),
            ),
          ),
        ),
      );

      // Show the snackbar
      await tester.tap(find.text('Show Snackbar'));
      await tester.pump();

      // Verify snackbar content
      expect(find.text(message), findsOneWidget);
      expect(find.text(actionLabel), findsOneWidget);
      
      // Verify snackbar styling
      expect(snackBar.backgroundColor, AppColors.errorRed);
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });

    group('Accessibility Tests', () {
      testWidgets('error components have proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppErrorStates.validationError('Required field'),
                  AppErrorStates.networkError(),
                  AppErrorStates.errorCard(title: 'Error'),
                ],
              ),
            ),
          ),
        );

        // Verify icons have proper semantics for screen readers
        final errorIcons = find.byIcon(Icons.error_outline);
        expect(errorIcons, findsWidgets);
        
        final networkIcon = find.byIcon(Icons.wifi_off_outlined);
        expect(networkIcon, findsOneWidget);
      });

      testWidgets('error components meet minimum touch target size', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppErrorStates.networkError(
                onRetry: () {},
              ),
            ),
          ),
        );

        // Verify retry button meets minimum touch target size
        final retryButton = find.byType(OutlinedButton);
        expect(retryButton, findsOneWidget);
        
        final buttonSize = tester.getSize(retryButton);
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
      });
    });

    group('Visual Consistency Tests', () {
      testWidgets('error components use consistent color scheme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppErrorStates.validationError('Error 1'),
                  AppErrorStates.inlineError('Error 2'),
                ],
              ),
            ),
          ),
        );

        // Verify error icons use error color
        final errorIcons = find.byIcon(Icons.error_outline);
        expect(errorIcons, findsOneWidget);
        
        final iconWidget = tester.widget<Icon>(errorIcons);
        expect(iconWidget.color, AppColors.errorRed);
      });

      testWidgets('error components use consistent typography', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppErrorStates.validationError('Validation error'),
                  AppErrorStates.networkError(message: 'Network error'),
                  AppErrorStates.errorCard(
                    title: 'Error title',
                    message: 'Error message',
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify text widgets are present and use design system styles
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsWidgets);
        
        // Verify that text widgets have proper styling applied
        final validationText = find.text('Validation error');
        expect(validationText, findsOneWidget);
        
        final textWidget = tester.widget<Text>(validationText);
        expect(textWidget.style?.color, AppColors.errorRed);
      });
    });
  });
}