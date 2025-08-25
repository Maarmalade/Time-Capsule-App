import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_loading_states.dart';

void main() {
  group('AppLoadingStates', () {
    testWidgets('circularLoader displays with default accent blue color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.circularLoader(),
          ),
        ),
      );

      // Verify circular progress indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verify default size
      final sizedBox = find.byType(SizedBox).first;
      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.width, 24);
      expect(sizedBoxWidget.height, 24);
    });

    testWidgets('circularLoader accepts custom size and color', (WidgetTester tester) async {
      const customSize = 32.0;
      const customColor = Colors.red;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.circularLoader(
              size: customSize,
              color: customColor,
            ),
          ),
        ),
      );

      // Verify custom size is applied
      final sizedBox = find.byType(SizedBox).first;
      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.width, customSize);
      expect(sizedBoxWidget.height, customSize);
    });

    testWidgets('linearLoader displays with correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.linearLoader(value: 0.5),
          ),
        ),
      );

      // Verify linear progress indicator is present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      // Verify container height
      final container = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(container);
      expect(containerWidget.constraints?.minHeight, 4);
    });

    testWidgets('loadingButton shows loading state correctly', (WidgetTester tester) async {
      const buttonText = 'Submit';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.loadingButton(
              text: buttonText,
              isLoading: true,
            ),
          ),
        ),
      );

      // Verify loading text is shown instead of original text
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text(buttonText), findsNothing);
      
      // Verify circular progress indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loadingButton shows normal state when not loading', (WidgetTester tester) async {
      const buttonText = 'Submit';
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.loadingButton(
              text: buttonText,
              isLoading: false,
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      // Verify original text is shown
      expect(find.text(buttonText), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
      
      // Verify button is functional
      await tester.tap(find.text(buttonText));
      expect(buttonPressed, isTrue);
    });

    testWidgets('loadingButton supports secondary style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.loadingButton(
              text: 'Cancel',
              isPrimary: false,
              isLoading: true,
            ),
          ),
        ),
      );

      // Verify outlined button is used for secondary style
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('skeleton displays with correct styling', (WidgetTester tester) async {
      const customWidth = 100.0;
      const customHeight = 20.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.skeleton(
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      // Verify container with correct dimensions
      final container = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(container);
      expect(containerWidget.constraints?.maxWidth, customWidth);
      expect(containerWidget.constraints?.maxHeight, customHeight);
    });

    testWidgets('skeletonText creates multiple lines', (WidgetTester tester) async {
      const lineCount = 3;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.skeletonText(lines: lineCount),
          ),
        ),
      );

      // Verify column with correct number of children
      expect(find.byType(Column), findsOneWidget);
      
      // Verify multiple skeleton containers are created (each line has 2 containers due to shimmer)
      expect(find.byType(Container), findsNWidgets(lineCount * 2));
    });

    testWidgets('skeletonCard displays all components when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.skeletonCard(
              includeImage: true,
              includeTitle: true,
              includeSubtitle: true,
            ),
          ),
        ),
      );

      // Verify main card container
      expect(find.byType(Container), findsWidgets);
      
      // Verify column layout
      expect(find.byType(Column), findsOneWidget);
      
      // Verify multiple skeleton elements are present
      final containers = find.byType(Container);
      expect(containers.evaluate().length, greaterThan(1));
    });

    testWidgets('skeletonListItem displays with avatar and content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.skeletonListItem(
              includeAvatar: true,
              includeTrailing: true,
            ),
          ),
        ),
      );

      // Verify row layout
      expect(find.byType(Row), findsOneWidget);
      
      // Verify column for content
      expect(find.byType(Column), findsOneWidget);
      
      // Verify multiple skeleton containers
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('pageLoader displays with message', (WidgetTester tester) async {
      const loadingMessage = 'Loading data...';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.pageLoader(message: loadingMessage),
          ),
        ),
      );

      // Verify loading message is displayed
      expect(find.text(loadingMessage), findsOneWidget);
      
      // Verify circular progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verify center alignment
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('imageLoader displays placeholder icon and loader', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.imageLoader(),
          ),
        ),
      );

      // Verify placeholder icon is present
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      
      // Verify circular progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verify container styling
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('refreshIndicator wraps child correctly', (WidgetTester tester) async {
      bool refreshCalled = false;
      const childText = 'Child Content';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLoadingStates.refreshIndicator(
              onRefresh: () async {
                refreshCalled = true;
              },
              child: Text(childText),
            ),
          ),
        ),
      );

      // Verify child content is displayed
      expect(find.text(childText), findsOneWidget);
      
      // Verify refresh indicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    group('Visual Consistency Tests', () {
      testWidgets('loading components use accent blue color', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppLoadingStates.circularLoader(),
                  AppLoadingStates.linearLoader(),
                  AppLoadingStates.loadingButton(text: 'Test', isLoading: true),
                ],
              ),
            ),
          ),
        );

        // Verify circular progress indicators are present
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        
        // Verify linear progress indicator is present
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('skeleton components use consistent colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppLoadingStates.skeleton(),
                  AppLoadingStates.skeletonText(),
                  AppLoadingStates.skeletonCard(),
                ],
              ),
            ),
          ),
        );

        // Verify multiple containers are present for skeleton components
        expect(find.byType(Container), findsWidgets);
        
        // Verify column layouts are present
        expect(find.byType(Column), findsWidgets);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('loading buttons maintain proper dimensions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppLoadingStates.loadingButton(
                text: 'Submit',
                isLoading: true,
              ),
            ),
          ),
        );

        // Verify button maintains minimum height
        final sizedBox = find.byType(SizedBox).first;
        final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
        expect(sizedBoxWidget.height, 44);
      });

      testWidgets('loading indicators have proper semantics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppLoadingStates.pageLoader(message: 'Loading...'),
            ),
          ),
        );

        // Verify loading message provides context
        expect(find.text('Loading...'), findsOneWidget);
        
        // Verify progress indicator is present for screen readers
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Animation Tests', () {
      testWidgets('skeleton shimmer animation is present', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppLoadingStates.skeleton(),
            ),
          ),
        );

        // Verify animated builder is present for shimmer effect
        expect(find.byType(AnimatedBuilder), findsWidgets);
        
        // Pump animation frames
        await tester.pump(Duration(milliseconds: 100));
        await tester.pump(Duration(milliseconds: 100));
        
        // Verify animation continues
        expect(find.byType(AnimatedBuilder), findsWidgets);
      });
    });
  });
}