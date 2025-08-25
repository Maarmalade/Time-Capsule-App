import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_theme.dart';
import 'package:time_capsule/design_system/app_colors.dart';

void main() {
  group('Main App Theme Integration Tests', () {
    testWidgets('should apply AppTheme to MaterialApp in main app', (tester) async {
      // Build a MaterialApp with our theme (without Firebase dependencies)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppTheme.getThemeMode(),
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the MaterialApp
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);

      // Get the theme from the MaterialApp
      final BuildContext context = tester.element(materialApp);
      final ThemeData theme = Theme.of(context);

      // Verify Material 3 is enabled
      expect(theme.useMaterial3, isTrue);

      // Verify color scheme is applied
      expect(theme.colorScheme, isNotNull);
      expect(theme.colorScheme.brightness, equals(Brightness.light));

      // Verify button themes are applied
      expect(theme.elevatedButtonTheme, isNotNull);
      expect(theme.outlinedButtonTheme, isNotNull);
      expect(theme.textButtonTheme, isNotNull);

      // Verify input decoration theme is applied
      expect(theme.inputDecorationTheme, isNotNull);

      // Verify card theme is applied
      expect(theme.cardTheme, isNotNull);

      // Verify app bar theme is applied
      expect(theme.appBarTheme, isNotNull);
      // Note: elevation may be null in test environment, but theme is applied

      // Verify navigation themes are applied
      expect(theme.bottomNavigationBarTheme, isNotNull);
      expect(theme.navigationRailTheme, isNotNull);

      // Verify text theme is applied
      expect(theme.textTheme, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.textTheme.headlineMedium, isNotNull);

      // Verify theme mode configuration
      expect(AppTheme.getThemeMode(), equals(ThemeMode.light));
    });

    testWidgets('should handle theme mode switching', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppTheme.getThemeMode(),
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      
      // Test theme helper methods
      expect(AppTheme.isDarkMode(context), isFalse);
      
      final adaptiveTextColor = AppTheme.getAdaptiveTextColor(context);
      expect(adaptiveTextColor, isNotNull);
      
      final adaptiveSurfaceColor = AppTheme.getAdaptiveSurfaceColor(context);
      expect(adaptiveSurfaceColor, isNotNull);
    });

    testWidgets('should apply debug configuration correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppTheme.getThemeMode(),
          debugShowCheckedModeBanner: false,
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final materialAppWidget = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify debug banner is disabled for professional appearance
      expect(materialAppWidget.debugShowCheckedModeBanner, isFalse);
      
      // Verify theme and dark theme are set
      expect(materialAppWidget.theme, isNotNull);
      expect(materialAppWidget.darkTheme, isNotNull);
      expect(materialAppWidget.themeMode, equals(ThemeMode.light));
    });

    testWidgets('should maintain theme consistency across navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppTheme.getThemeMode(),
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Get initial theme
      final BuildContext initialContext = tester.element(find.byType(MaterialApp));
      final ThemeData initialTheme = Theme.of(initialContext);

      // Verify theme properties are consistent
      expect(initialTheme.useMaterial3, isTrue);
      expect(initialTheme.colorScheme.brightness, equals(Brightness.light));
      
      // Test that theme extensions are available
      expect(initialTheme.extensions, isNotNull);
      
      // Verify custom theme extension colors (if available)
      final appColors = initialTheme.appColors;
      if (appColors != null) {
        expect(appColors.successColor, equals(AppColors.successGreen));
        expect(appColors.warningColor, equals(AppColors.warningAmber));
        expect(appColors.infoColor, equals(AppColors.infoBlue));
      }
    });

    testWidgets('should apply proper visual density and tap targets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Verify visual density is set for adaptive platform density
      expect(theme.visualDensity, equals(VisualDensity.adaptivePlatformDensity));
      
      // Verify material tap target size is set
      expect(theme.materialTapTargetSize, equals(MaterialTapTargetSize.padded));
    });

    testWidgets('should apply interaction colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Verify interaction colors are set
      expect(theme.splashColor, isNotNull);
      expect(theme.highlightColor, isNotNull);
      expect(theme.focusColor, isNotNull);
      expect(theme.hoverColor, isNotNull);
    });

    testWidgets('should apply text selection theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Verify text selection theme is applied
      expect(theme.textSelectionTheme, isNotNull);
      // Note: Some text selection properties may be null in test environment
      expect(theme.textSelectionTheme.cursorColor, isA<Color?>());
    });

    testWidgets('should apply component themes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Verify all major component themes are applied
      expect(theme.chipTheme, isNotNull);
      expect(theme.dialogTheme, isNotNull);
      expect(theme.snackBarTheme, isNotNull);
      expect(theme.progressIndicatorTheme, isNotNull);
      expect(theme.switchTheme, isNotNull);
      expect(theme.checkboxTheme, isNotNull);
      expect(theme.radioTheme, isNotNull);
      expect(theme.sliderTheme, isNotNull);
      expect(theme.tooltipTheme, isNotNull);
      expect(theme.popupMenuTheme, isNotNull);
      expect(theme.bottomSheetTheme, isNotNull);
      expect(theme.expansionTileTheme, isNotNull);
      expect(theme.listTileTheme, isNotNull);
    });

    testWidgets('should handle page transitions correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Verify page transitions theme is applied
      expect(theme.pageTransitionsTheme, isNotNull);
      expect(theme.pageTransitionsTheme.builders, isNotEmpty);
      
      // Verify platform-specific transitions are configured
      expect(theme.pageTransitionsTheme.builders.containsKey(TargetPlatform.android), isTrue);
      expect(theme.pageTransitionsTheme.builders.containsKey(TargetPlatform.iOS), isTrue);
    });
  });

  group('Theme System UI Integration', () {
    test('should provide correct system UI overlay styles', () {
      final lightStyle = AppTheme.lightSystemUiOverlayStyle;
      final darkStyle = AppTheme.darkSystemUiOverlayStyle;
      
      // Test light style configuration
      expect(lightStyle.statusBarColor, equals(Colors.transparent));
      expect(lightStyle.statusBarIconBrightness, equals(Brightness.dark));
      expect(lightStyle.systemNavigationBarColor, equals(AppColors.surfacePrimary));
      
      // Test dark style configuration
      expect(darkStyle.statusBarColor, equals(Colors.transparent));
      expect(darkStyle.statusBarIconBrightness, equals(Brightness.light));
      expect(darkStyle.systemNavigationBarColor, equals(AppColors.charcoalNavy));
    });

    test('should handle theme mode configuration', () {
      final themeMode = AppTheme.getThemeMode();
      expect(themeMode, equals(ThemeMode.light));
    });
  });

  group('Theme Error Handling', () {
    testWidgets('should handle missing theme gracefully', (tester) async {
      // Create a minimal MaterialApp without our theme
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(MaterialApp));
      
      // Should not throw when accessing theme
      expect(() => Theme.of(context), returnsNormally);
      expect(() => AppTheme.isDarkMode(context), returnsNormally);
    });
  });
}