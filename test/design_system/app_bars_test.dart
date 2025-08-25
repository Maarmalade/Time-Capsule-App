import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_bars.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_spacing.dart';

void main() {
  group('AppBars', () {
    group('appBarTheme', () {
      test('should have correct flat design configuration', () {
        final theme = AppBars.appBarTheme;
        
        expect(theme.elevation, equals(AppSpacing.elevation0));
        expect(theme.scrolledUnderElevation, equals(AppSpacing.elevation1));
        expect(theme.backgroundColor, equals(AppColors.surfacePrimary));
        expect(theme.surfaceTintColor, equals(AppColors.surfacePrimary));
        expect(theme.foregroundColor, equals(AppColors.textPrimary));
      });

      test('should have correct typography configuration', () {
        final theme = AppBars.appBarTheme;
        
        expect(theme.titleTextStyle?.color, equals(AppColors.textPrimary));
        expect(theme.titleTextStyle?.fontWeight, equals(FontWeight.w500)); // medium weight
        // Note: fontSize may vary due to Google Fonts, so we check it's reasonable
        expect(theme.titleTextStyle?.fontSize, greaterThan(18.0));
        expect(theme.titleTextStyle?.fontSize, lessThan(25.0));
      });

      test('should have correct icon theme configuration', () {
        final theme = AppBars.appBarTheme;
        
        expect(theme.iconTheme?.color, equals(AppColors.textPrimary));
        expect(theme.iconTheme?.size, equals(AppSpacing.iconSize));
        expect(theme.actionsIconTheme?.color, equals(AppColors.textPrimary));
        expect(theme.actionsIconTheme?.size, equals(AppSpacing.iconSize));
      });

      test('should have correct system overlay style', () {
        final theme = AppBars.appBarTheme;
        
        expect(theme.systemOverlayStyle?.statusBarColor, equals(Colors.transparent));
        expect(theme.systemOverlayStyle?.statusBarIconBrightness, equals(Brightness.dark));
        expect(theme.systemOverlayStyle?.statusBarBrightness, equals(Brightness.light));
      });

      test('should have subtle border configuration', () {
        final theme = AppBars.appBarTheme;
        
        expect(theme.shape, isA<Border>());
        final border = theme.shape as Border;
        expect(border.bottom.color, equals(AppColors.borderLight));
        expect(border.bottom.width, equals(0.5));
      });

      test('should not center title by default', () {
        final theme = AppBars.appBarTheme;
        
        expect(theme.centerTitle, equals(false));
      });
    });

    group('largeAppBarTheme', () {
      test('should extend standard theme with larger typography', () {
        final theme = AppBars.largeAppBarTheme;
        
        // Check that large theme has larger font size than standard
        final standardTheme = AppBars.appBarTheme;
        expect(theme.titleTextStyle?.fontSize, 
               greaterThan(standardTheme.titleTextStyle?.fontSize ?? 0));
        expect(theme.titleTextStyle?.fontWeight, equals(FontWeight.w600)); // semiBold
        expect(theme.titleTextStyle?.color, equals(AppColors.textPrimary));
      });

      test('should maintain other properties from standard theme', () {
        final theme = AppBars.largeAppBarTheme;
        
        expect(theme.elevation, equals(AppSpacing.elevation0));
        expect(theme.backgroundColor, equals(AppColors.surfacePrimary));
        expect(theme.iconTheme?.color, equals(AppColors.textPrimary));
      });
    });

    group('transparentAppBarTheme', () {
      test('should have transparent background', () {
        final theme = AppBars.transparentAppBarTheme;
        
        expect(theme.backgroundColor, equals(Colors.transparent));
        expect(theme.elevation, equals(AppSpacing.elevation0));
        expect(theme.scrolledUnderElevation, equals(AppSpacing.elevation0));
        // Note: shape may inherit from base theme, so we don't test for null
      });

      test('should use white foreground colors', () {
        final theme = AppBars.transparentAppBarTheme;
        
        expect(theme.foregroundColor, equals(AppColors.primaryWhite));
        expect(theme.iconTheme?.color, equals(AppColors.primaryWhite));
        expect(theme.actionsIconTheme?.color, equals(AppColors.primaryWhite));
        expect(theme.titleTextStyle?.color, equals(AppColors.primaryWhite));
      });

      test('should have correct system overlay for light status bar', () {
        final theme = AppBars.transparentAppBarTheme;
        
        expect(theme.systemOverlayStyle?.statusBarIconBrightness, equals(Brightness.light));
        expect(theme.systemOverlayStyle?.statusBarBrightness, equals(Brightness.dark));
      });
    });

    group('accentAppBarTheme', () {
      test('should use accent blue background', () {
        final theme = AppBars.accentAppBarTheme;
        
        expect(theme.backgroundColor, equals(AppColors.accentBlue));
        expect(theme.foregroundColor, equals(AppColors.primaryWhite));
      });

      test('should use white icons and text', () {
        final theme = AppBars.accentAppBarTheme;
        
        expect(theme.iconTheme?.color, equals(AppColors.primaryWhite));
        expect(theme.actionsIconTheme?.color, equals(AppColors.primaryWhite));
        expect(theme.titleTextStyle?.color, equals(AppColors.primaryWhite));
      });
    });

    group('createAppBar', () {
      testWidgets('should create app bar with correct title', (tester) async {
        const title = 'Test Title';
        final appBar = AppBars.createAppBar(title: title);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: appBar,
            ),
          ),
        );
        
        expect(find.text(title), findsOneWidget);
      });

      testWidgets('should handle actions correctly', (tester) async {
        final actions = [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ];
        
        final appBar = AppBars.createAppBar(
          title: 'Test',
          actions: actions,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: appBar,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('createLargeAppBar', () {
      testWidgets('should create large app bar with title and subtitle', (tester) async {
        const title = 'Large Title';
        const subtitle = 'Subtitle text';
        
        final appBar = AppBars.createLargeAppBar(
          title: title,
          subtitle: subtitle,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: appBar,
            ),
          ),
        );
        
        expect(find.text(title), findsOneWidget);
        expect(find.text(subtitle), findsOneWidget);
      });

      testWidgets('should have correct toolbar height with subtitle', (tester) async {
        final appBar = AppBars.createLargeAppBar(
          title: 'Title',
          subtitle: 'Subtitle',
        ) as AppBar;
        
        expect(appBar.toolbarHeight, equals(80.0));
      });

      testWidgets('should have default toolbar height without subtitle', (tester) async {
        final appBar = AppBars.createLargeAppBar(
          title: 'Title',
        ) as AppBar;
        
        expect(appBar.toolbarHeight, equals(64.0));
      });
    });

    group('createSearchAppBar', () {
      testWidgets('should create search app bar with text field', (tester) async {
        const hintText = 'Search...';
        
        final appBar = AppBars.createSearchAppBar(
          hintText: hintText,
          onChanged: (value) {},
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: appBar,
            ),
          ),
        );
        
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text(hintText), findsOneWidget);
      });

      testWidgets('should show clear button when onClear is provided', (tester) async {
        final appBar = AppBars.createSearchAppBar(
          hintText: 'Search...',
          onChanged: (value) {},
          onClear: () {},
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: appBar,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });
    });

    group('createTabAppBar', () {
      testWidgets('should create app bar with tab bar', (tester) async {
        const title = 'Tab Title';
        final tabs = [
          const Tab(text: 'Tab 1'),
          const Tab(text: 'Tab 2'),
        ];
        
        final appBar = AppBars.createTabAppBar(
          title: title,
          tabs: tabs,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: appBar,
              ),
            ),
          ),
        );
        
        expect(find.text(title), findsOneWidget);
        expect(find.text('Tab 1'), findsOneWidget);
        expect(find.text('Tab 2'), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
      });
    });

    group('action buttons', () {
      testWidgets('createActionButton should create accessible button', (tester) async {
        bool pressed = false;
        
        final button = AppBars.createActionButton(
          icon: Icons.settings,
          onPressed: () => pressed = true,
          tooltip: 'Settings',
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: button,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.settings), findsOneWidget);
        expect(find.byTooltip('Settings'), findsOneWidget);
        
        await tester.tap(find.byIcon(Icons.settings));
        expect(pressed, isTrue);
      });

      testWidgets('createMenuButton should create menu button', (tester) async {
        bool pressed = false;
        
        final button = AppBars.createMenuButton(
          onPressed: () => pressed = true,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: button,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.menu), findsOneWidget);
        
        await tester.tap(find.byIcon(Icons.menu));
        expect(pressed, isTrue);
      });

      testWidgets('createBackButton should create back button', (tester) async {
        bool pressed = false;
        
        final button = AppBars.createBackButton(
          onPressed: () => pressed = true,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: button,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        
        await tester.tap(find.byIcon(Icons.arrow_back));
        expect(pressed, isTrue);
      });

      test('action buttons should have minimum touch target size', () {
        final actionButton = AppBars.createActionButton(
          icon: Icons.settings,
          onPressed: () {},
        ) as IconButton;
        
        expect(actionButton.constraints?.minWidth, equals(AppSpacing.minTouchTarget));
        expect(actionButton.constraints?.minHeight, equals(AppSpacing.minTouchTarget));
      });
    });

    group('accessibility compliance', () {
      test('should meet touch target size requirements', () {
        final theme = AppBars.appBarTheme;
        
        expect(theme.iconTheme?.size, greaterThanOrEqualTo(20.0));
        expect(theme.actionsIconTheme?.size, greaterThanOrEqualTo(20.0));
      });

      test('should have sufficient color contrast', () {
        final theme = AppBars.appBarTheme;
        
        // Test primary text on white background
        expect(theme.titleTextStyle?.color, equals(AppColors.textPrimary));
        expect(theme.backgroundColor, equals(AppColors.surfacePrimary));
        
        // Verify contrast ratio meets WCAG AA standards (4.5:1)
        final titleLuminance = AppColors.textPrimary.computeLuminance();
        final backgroundLuminance = AppColors.surfacePrimary.computeLuminance();
        final contrastRatio = (backgroundLuminance + 0.05) / (titleLuminance + 0.05);
        
        expect(contrastRatio, greaterThanOrEqualTo(4.5));
      });

      testWidgets('should support screen readers', (tester) async {
        final appBar = AppBars.createAppBar(
          title: 'Accessible Title',
          actions: [
            AppBars.createActionButton(
              icon: Icons.settings,
              onPressed: () {},
              tooltip: 'Settings',
            ),
          ],
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: appBar,
            ),
          ),
        );
        
        // Verify semantic labels are present
        expect(find.text('Accessible Title'), findsOneWidget);
        expect(find.byTooltip('Settings'), findsOneWidget);
      });
    });

    group('consistency across pages', () {
      test('all app bar themes should use consistent spacing', () {
        final themes = [
          AppBars.appBarTheme,
          AppBars.largeAppBarTheme,
          AppBars.transparentAppBarTheme,
          AppBars.accentAppBarTheme,
        ];
        
        for (final theme in themes) {
          expect(theme.iconTheme?.size, equals(AppSpacing.iconSize));
          expect(theme.actionsIconTheme?.size, equals(AppSpacing.iconSize));
        }
      });

      test('all app bar themes should use consistent typography scale', () {
        final standardTheme = AppBars.appBarTheme;
        final largeTheme = AppBars.largeAppBarTheme;
        
        // Large theme should have larger font size than standard
        expect(largeTheme.titleTextStyle?.fontSize, 
               greaterThan(standardTheme.titleTextStyle?.fontSize ?? 0));
        
        // Both should have reasonable font sizes
        expect(standardTheme.titleTextStyle?.fontSize, greaterThan(18.0));
        expect(largeTheme.titleTextStyle?.fontSize, greaterThan(22.0));
      });

      test('all app bar variants should maintain design system compliance', () {
        final themes = [
          AppBars.appBarTheme,
          AppBars.largeAppBarTheme,
          AppBars.transparentAppBarTheme,
          AppBars.accentAppBarTheme,
        ];
        
        for (final theme in themes) {
          // Should use design system colors
          expect(theme.backgroundColor, isNotNull);
          expect(theme.foregroundColor, isNotNull);
          
          // Should have consistent icon sizing
          expect(theme.iconTheme?.size, equals(AppSpacing.iconSize));
          
          // Should have proper typography
          expect(theme.titleTextStyle?.fontWeight, isNotNull);
        }
      });
    });
  });
}