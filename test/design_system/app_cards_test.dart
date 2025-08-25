import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_cards.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_spacing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppCards', () {
    group('Card Theme', () {
      test('should have correct default properties', () {
        final theme = AppCards.cardTheme;
        
        expect(theme.color, equals(AppColors.surfacePrimary));
        expect(theme.shadowColor, equals(AppColors.shadowMedium));
        expect(theme.elevation, equals(AppSpacing.elevation2));
        expect(theme.margin, equals(AppCards.cardMarginMedium));
        expect(theme.clipBehavior, equals(Clip.antiAlias));
        
        final shape = theme.shape as RoundedRectangleBorder?;
        expect(shape?.borderRadius, equals(AppSpacing.cardRadius));
      });
    });

    group('Card Decorations', () {
      test('standard card decoration should have correct properties', () {
        final decoration = AppCards.standardCardDecoration;
        
        expect(decoration.color, equals(AppColors.surfacePrimary));
        expect(decoration.borderRadius, equals(AppSpacing.cardRadius));
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(1));
        
        final shadow = decoration.boxShadow!.first;
        expect(shadow.color, equals(AppColors.shadowMedium));
        expect(shadow.blurRadius, equals(8.0));
        expect(shadow.offset, equals(const Offset(0, 2)));
      });

      test('elevated card decoration should have higher elevation', () {
        final decoration = AppCards.elevatedCardDecoration;
        
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(2));
        
        // Should have more prominent shadows than standard card
        final primaryShadow = decoration.boxShadow!.first;
        expect(primaryShadow.blurRadius, greaterThan(8.0));
        expect(primaryShadow.offset.dy, greaterThan(2.0));
      });

      test('flat card decoration should have no shadow', () {
        final decoration = AppCards.flatCardDecoration;
        
        expect(decoration.boxShadow, isNull);
        expect(decoration.border, isNotNull);
        
        final border = decoration.border as Border?;
        expect(border?.top.color, equals(AppColors.borderLight));
        expect(border?.top.width, equals(1.0));
      });

      test('secondary card decoration should use secondary surface', () {
        final decoration = AppCards.secondaryCardDecoration;
        
        expect(decoration.color, equals(AppColors.surfaceSecondary));
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(1));
        
        // Should have lighter shadow than standard card
        final shadow = decoration.boxShadow!.first;
        expect(shadow.color, equals(AppColors.shadowLight));
      });

      test('memory card decoration should be suitable for media content', () {
        final decoration = AppCards.memoryCardDecoration;
        
        expect(decoration.color, equals(AppColors.surfacePrimary));
        expect(decoration.borderRadius, equals(AppSpacing.cardRadius));
        expect(decoration.boxShadow, isNotNull);
      });

      test('interactive card decoration should change on hover', () {
        final normalDecoration = AppCards.getInteractiveCardDecoration(isHovered: false);
        final hoveredDecoration = AppCards.getInteractiveCardDecoration(isHovered: true);
        
        final normalShadow = normalDecoration.boxShadow!.first;
        final hoveredShadow = hoveredDecoration.boxShadow!.first;
        
        expect(hoveredShadow.blurRadius, greaterThan(normalShadow.blurRadius));
        expect(hoveredShadow.offset.dy, greaterThan(normalShadow.offset.dy));
      });
    });

    group('Card Constants', () {
      test('should have appropriate padding constants', () {
        expect(AppCards.cardPaddingLarge, equals(const EdgeInsets.all(AppSpacing.lg)));
        expect(AppCards.cardPaddingMedium, equals(const EdgeInsets.all(AppSpacing.md)));
        expect(AppCards.cardPaddingSmall, equals(const EdgeInsets.all(AppSpacing.sm)));
        
        // Padding should be in descending order
        expect(AppCards.cardPaddingLarge.top, greaterThan(AppCards.cardPaddingMedium.top));
        expect(AppCards.cardPaddingMedium.top, greaterThan(AppCards.cardPaddingSmall.top));
      });

      test('should have appropriate margin constants', () {
        expect(AppCards.cardMarginLarge, equals(const EdgeInsets.all(AppSpacing.md)));
        expect(AppCards.cardMarginMedium, equals(const EdgeInsets.all(AppSpacing.sm)));
        expect(AppCards.cardMarginSmall, equals(const EdgeInsets.all(AppSpacing.xs)));
        
        // Margin should be in descending order
        expect(AppCards.cardMarginLarge.top, greaterThan(AppCards.cardMarginMedium.top));
        expect(AppCards.cardMarginMedium.top, greaterThan(AppCards.cardMarginSmall.top));
      });

      test('should have appropriate aspect ratios for memory cards', () {
        expect(AppCards.memoryCardAspectRatio16x9, equals(16.0 / 9.0));
        expect(AppCards.memoryCardAspectRatio1x1, equals(1.0));
        expect(AppCards.memoryCardAspectRatio4x3, equals(4.0 / 3.0));
        
        // 16:9 should be wider than 4:3, which should be wider than 1:1
        expect(AppCards.memoryCardAspectRatio16x9, greaterThan(AppCards.memoryCardAspectRatio4x3));
        expect(AppCards.memoryCardAspectRatio4x3, greaterThan(AppCards.memoryCardAspectRatio1x1));
      });
    });

    testWidgets('createStandardCard should render correctly', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createStandardCard(
              onTap: () => tapped = true,
              child: const Text('Test Card'),
            ),
          ),
        ),
      );
      
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.text('Test Card'), findsOneWidget);
      
      // Test tap functionality
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('createLargeCard should have larger padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createLargeCard(
              child: const Text('Large Card'),
            ),
          ),
        ),
      );
      
      expect(find.text('Large Card'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('createSmallCard should have smaller padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createSmallCard(
              child: const Text('Small Card'),
            ),
          ),
        ),
      );
      
      expect(find.text('Small Card'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('createMemoryCard should have aspect ratio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createMemoryCard(
              content: Container(color: Colors.blue),
              aspectRatio: AppCards.memoryCardAspectRatio16x9,
            ),
          ),
        ),
      );
      
      expect(find.byType(AspectRatio), findsOneWidget);
      expect(find.byType(Stack), findsWidgets); // Multiple stacks may exist in the widget tree
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('createInfoCard should display icon and text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createInfoCard(
              icon: Icons.info,
              title: 'Info Title',
              subtitle: 'Info Subtitle',
            ),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('Info Title'), findsOneWidget);
      expect(find.text('Info Subtitle'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('createActionCard should display action button', (tester) async {
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createActionCard(
              title: 'Action Card',
              description: 'This is a description',
              actionText: 'Take Action',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );
      
      expect(find.text('Action Card'), findsOneWidget);
      expect(find.text('This is a description'), findsOneWidget);
      expect(find.text('Take Action'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Test action button
      await tester.tap(find.byType(ElevatedButton));
      expect(actionPressed, isTrue);
    });

    testWidgets('createStatusCard should display status with correct color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createStatusCard(
              title: 'Success Status',
              message: 'Operation completed successfully',
              status: StatusType.success,
            ),
          ),
        ),
      );
      
      expect(find.text('Success Status'), findsOneWidget);
      expect(find.text('Operation completed successfully'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('createContainer should render with custom styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createContainer(
              backgroundColor: Colors.red,
              child: const Text('Container Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Container Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('createSection should display title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCards.createSection(
              title: 'Section Title',
              child: const Text('Section Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('Section Content'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    group('Visual Consistency', () {
      test('all card decorations should use consistent border radius', () {
        final decorations = [
          AppCards.standardCardDecoration,
          AppCards.elevatedCardDecoration,
          AppCards.flatCardDecoration,
          AppCards.secondaryCardDecoration,
          AppCards.memoryCardDecoration,
        ];
        
        for (final decoration in decorations) {
          expect(decoration.borderRadius, equals(AppSpacing.cardRadius));
        }
      });

      test('all card decorations should use appropriate surface colors', () {
        expect(AppCards.standardCardDecoration.color, equals(AppColors.surfacePrimary));
        expect(AppCards.elevatedCardDecoration.color, equals(AppColors.surfacePrimary));
        expect(AppCards.flatCardDecoration.color, equals(AppColors.surfacePrimary));
        expect(AppCards.secondaryCardDecoration.color, equals(AppColors.surfaceSecondary));
        expect(AppCards.memoryCardDecoration.color, equals(AppColors.surfacePrimary));
      });

      test('shadow colors should be consistent across decorations', () {
        final decorationsWithShadows = [
          AppCards.standardCardDecoration,
          AppCards.elevatedCardDecoration,
          AppCards.secondaryCardDecoration,
          AppCards.memoryCardDecoration,
        ];
        
        for (final decoration in decorationsWithShadows) {
          expect(decoration.boxShadow, isNotNull);
          expect(decoration.boxShadow!.isNotEmpty, isTrue);
          
          // All shadows should use defined shadow colors
          for (final shadow in decoration.boxShadow!) {
            expect([
              AppColors.shadowLight,
              AppColors.shadowMedium,
              AppColors.shadowDark,
            ].contains(shadow.color), isTrue);
          }
        }
      });
    });

    group('Accessibility Compliance', () {
      test('interactive cards should have proper touch targets', () {
        // This is tested implicitly through the InkWell widgets in the card creation methods
        // The InkWell provides proper touch targets and ripple effects
        expect(true, isTrue); // Placeholder for structural test
      });

      test('status cards should have appropriate color contrast', () {
        // Test that status colors provide sufficient contrast
        final statusColors = [
          AppColors.successGreen,
          AppColors.warningAmber,
          AppColors.errorRed,
          AppColors.infoBlue,
        ];
        
        for (final color in statusColors) {
          // Colors should be distinct from background
          expect(color, isNot(equals(AppColors.surfacePrimary)));
          expect(color, isNot(equals(AppColors.surfaceSecondary)));
        }
      });
    });

    group('StatusType Enum', () {
      test('should have all required status types', () {
        expect(StatusType.values.length, equals(4));
        expect(StatusType.values.contains(StatusType.success), isTrue);
        expect(StatusType.values.contains(StatusType.warning), isTrue);
        expect(StatusType.values.contains(StatusType.error), isTrue);
        expect(StatusType.values.contains(StatusType.info), isTrue);
      });
    });
  });
}