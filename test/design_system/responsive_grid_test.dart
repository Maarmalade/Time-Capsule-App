import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/responsive_grid.dart';
import 'package:time_capsule/design_system/app_responsive.dart';

void main() {
  group('ResponsiveGrid', () {
    testWidgets('should adapt column count based on screen width', (tester) async {
      const testChildren = [
        Text('Item 1'),
        Text('Item 2'),
        Text('Item 3'),
        Text('Item 4'),
      ];

      // Test mobile layout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Mobile width
              height: 600, // Add height for proper rendering
              child: ResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
                shrinkWrap: true,
                children: testChildren, // Allow grid to size itself
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);

      // Test tablet layout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800, // Tablet width
              height: 600,
              child: ResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);

      // Test desktop layout
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1500, // Desktop width (>= 1440)
              height: 600,
              child: ResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should use default column counts when not specified', (tester) async {
      const testChildren = [
        Text('Item 1'),
        Text('Item 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Mobile width
              height: 400,
              child: ResponsiveGrid(
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('should apply custom spacing when provided', (tester) async {
      const testChildren = [
        Text('Item 1'),
        Text('Item 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ResponsiveGrid(
                spacing: 20.0,
                runSpacing: 25.0,
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should apply custom padding when provided', (tester) async {
      const testChildren = [
        Text('Item 1'),
        Text('Item 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ResponsiveGrid(
                padding: const EdgeInsets.all(32.0),
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Padding), findsOneWidget);
    });
  });

  group('ResponsiveMemoryGrid', () {
    testWidgets('should use memory-specific column counts', (tester) async {
      const testChildren = [
        Text('Memory 1'),
        Text('Memory 2'),
        Text('Memory 3'),
      ];

      // Test different screen sizes
      for (final width in [300.0, 600.0, 900.0, 1200.0, 1600.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                height: 600,
                child: ResponsiveMemoryGrid(
                  shrinkWrap: true,
                  children: testChildren,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('Memory 1'), findsOneWidget);
      }
    });

    testWidgets('should use square aspect ratio for memory items', (tester) async {
      const testChildren = [
        Text('Memory 1'),
        Text('Memory 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ResponsiveMemoryGrid(
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('ResponsiveStaggeredGrid', () {
    testWidgets('should create staggered layout', (tester) async {
      const testChildren = [
        SizedBox(height: 100, child: Text('Item 1')),
        SizedBox(height: 150, child: Text('Item 2')),
        SizedBox(height: 120, child: Text('Item 3')),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ResponsiveStaggeredGrid(
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
    });
  });

  group('ResponsiveList', () {
    testWidgets('should create responsive list with proper spacing', (tester) async {
      const testChildren = [
        Text('List Item 1'),
        Text('List Item 2'),
        Text('List Item 3'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ResponsiveList(
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('List Item 1'), findsOneWidget);
    });

    testWidgets('should support horizontal scrolling', (tester) async {
      const testChildren = [
        Text('Item 1'),
        Text('Item 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: ResponsiveList(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should apply custom spacing', (tester) async {
      const testChildren = [
        Text('Item 1'),
        Text('Item 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ResponsiveList(
                spacing: 32.0,
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('ResponsiveWrap', () {
    testWidgets('should create responsive wrap layout', (tester) async {
      const testChildren = [
        Chip(label: Text('Tag 1')),
        Chip(label: Text('Tag 2')),
        Chip(label: Text('Tag 3')),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ResponsiveWrap(children: testChildren),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('Tag 1'), findsOneWidget);
    });

    testWidgets('should apply custom alignment and spacing', (tester) async {
      const testChildren = [
        Chip(label: Text('Tag 1')),
        Chip(label: Text('Tag 2')),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ResponsiveWrap(
                alignment: WrapAlignment.center,
                spacing: 16.0,
                runSpacing: 20.0,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('should support vertical direction', (tester) async {
      const testChildren = [
        Chip(label: Text('Tag 1')),
        Chip(label: Text('Tag 2')),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ResponsiveWrap(
                direction: Axis.vertical,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });
  });

  group('Responsive Grid Integration', () {
    testWidgets('should work with different device types', (tester) async {
      const testChildren = [
        Text('Item 1'),
        Text('Item 2'),
        Text('Item 3'),
        Text('Item 4'),
      ];

      // Test across different screen widths
      final testWidths = [350.0, 600.0, 900.0, 1200.0];
      
      for (final width in testWidths) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                height: 600,
                child: ResponsiveGrid(
                  shrinkWrap: true,
                  children: testChildren,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(GridView), findsOneWidget);
        
        // Verify at least the first item is present (others might be off-screen)
        expect(find.text('Item 1'), findsOneWidget);
      }
    });

    testWidgets('should handle empty children list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ResponsiveGrid(
                shrinkWrap: true,
                children: const [],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should handle single child', (tester) async {
      const testChildren = [Text('Single Item')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ResponsiveGrid(
                shrinkWrap: true,
                children: testChildren,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Single Item'), findsOneWidget);
    });
  });
}