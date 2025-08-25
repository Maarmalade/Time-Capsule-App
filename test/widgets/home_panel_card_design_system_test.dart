import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_capsule/widgets/home_panel_card.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_typography.dart';
import 'package:time_capsule/design_system/app_spacing.dart';
import 'package:time_capsule/design_system/app_theme.dart';

void main() {
  group('HomePanelCard Design System Integration Tests', () {
    testWidgets('HomePanelCard uses design system colors and styling', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: 'Test Card',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify container uses correct background color
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.surfacePrimary));

      // Verify border radius uses design system values
      expect(decoration.borderRadius, equals(AppSpacing.cardRadius));

      // Verify shadow uses design system color
      expect(decoration.boxShadow?.first.color, equals(AppColors.shadowMedium));
    });

    testWidgets('HomePanelCard text uses correct typography', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: 'Test Card',
              onTap: () {},
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test Card'));
      expect(textWidget.style?.fontSize, equals(AppTypography.titleMedium.fontSize));
      expect(textWidget.style?.color, equals(AppColors.textSecondary));
      expect(textWidget.textAlign, equals(TextAlign.center));
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('HomePanelCard uses correct padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: 'Test Card',
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, equals(AppSpacing.cardPadding));
    });

    testWidgets('HomePanelCard with image displays correctly', (WidgetTester tester) async {
      const testImage = AssetImage('test_image.png');
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: 'Test Card with Image',
              image: testImage,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify image is displayed
      expect(find.byType(Image), findsOneWidget);
      
      // Verify image has correct dimensions
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, equals(60));
      expect(image.height, equals(60));
      expect(image.fit, equals(BoxFit.cover));

      // Verify ClipRRect uses design system border radius
      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, 
        equals(BorderRadius.circular(AppSpacing.radiusSm)));

      // Verify spacing between image and text
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(Column),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, equals(AppSpacing.sm));
    });

    testWidgets('HomePanelCard handles empty text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: '',
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not display text widget when text is empty
      expect(find.text(''), findsNothing);
      
      // But container should still be present
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('HomePanelCard tap interaction works correctly', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: 'Tappable Card',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify InkWell is present for proper Material interaction
      expect(find.byType(InkWell), findsOneWidget);
      
      // Verify InkWell uses correct border radius
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, equals(AppSpacing.cardRadius));

      // Test tap functionality
      await tester.tap(find.byType(HomePanelCard));
      expect(tapped, isTrue);
    });

    testWidgets('HomePanelCard maintains accessibility standards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: 'Accessible Card',
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify card size meets minimum touch target requirements
      final cardSize = tester.getSize(find.byType(HomePanelCard));
      expect(cardSize.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
      expect(cardSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));

      // Verify text contrast
      final textWidget = tester.widget<Text>(find.text('Accessible Card'));
      final textColor = textWidget.style?.color ?? AppColors.textSecondary;
      
      final backgroundLuminance = AppColors.surfacePrimary.computeLuminance();
      final textLuminance = textColor.computeLuminance();
      final contrastRatio = (backgroundLuminance + 0.05) / (textLuminance + 0.05);
      
      // Should meet WCAG AA standard
      expect(contrastRatio, greaterThan(3.0)); // AA standard for large text
    });

    testWidgets('HomePanelCard shadow and elevation are consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomePanelCard(
              text: 'Shadow Test',
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      final shadow = decoration.boxShadow?.first;
      
      expect(shadow?.color, equals(AppColors.shadowMedium));
      expect(shadow?.blurRadius, equals(8.0));
      expect(shadow?.offset, equals(const Offset(0, 2)));
    });

    testWidgets('HomePanelCard long text handling', (WidgetTester tester) async {
      const longText = 'This is a very long text that should be truncated properly according to the design system specifications';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: HomePanelCard(
                text: longText,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.textContaining('This is a very long'));
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });
  });
}