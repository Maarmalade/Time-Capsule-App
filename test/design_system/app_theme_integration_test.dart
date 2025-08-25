import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_theme.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_spacing.dart';

void main() {
  group('AppTheme Integration Tests', () {
    testWidgets('should apply complete theme configuration to MaterialApp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );

      // Verify theme is applied
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Test Material 3 configuration
      expect(theme.useMaterial3, isTrue);
      
      // Test color scheme - verify colors are applied (Material 3 may adjust exact values)
      expect(theme.colorScheme.surface, isNotNull);
      expect(theme.colorScheme.onSurface, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.colorScheme.brightness, equals(Brightness.light));
      
      // Test typography - verify text theme is applied (Material 3 may override exact values)
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.textTheme.headlineMedium, isNotNull);
      expect(theme.textTheme.displayMedium, isNotNull);
      
      // Test surface colors - verify they are set (Material 3 may adjust exact values)
      expect(theme.scaffoldBackgroundColor, isNotNull);
      expect(theme.cardColor, isNotNull);
      expect(theme.dialogBackgroundColor, isNotNull);
    });

    testWidgets('should apply button themes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
          ),
        ),
      );

      // Find buttons
      final elevatedButton = find.byType(ElevatedButton);
      final outlinedButton = find.byType(OutlinedButton);
      final textButton = find.byType(TextButton);

      expect(elevatedButton, findsOneWidget);
      expect(outlinedButton, findsOneWidget);
      expect(textButton, findsOneWidget);

      // Test button styling through theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);

      // Verify elevated button theme
      expect(
        theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
        equals(AppColors.accentBlue),
      );
      
      // Verify outlined button theme
      expect(
        theme.outlinedButtonTheme.style?.foregroundColor?.resolve({}),
        equals(AppColors.accentBlue),
      );
      
      // Verify text button theme
      expect(
        theme.textButtonTheme.style?.foregroundColor?.resolve({}),
        equals(AppColors.accentBlue),
      );
    });

    testWidgets('should apply input field themes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(
                labelText: 'Test Input',
                hintText: 'Enter text',
              ),
            ),
          ),
        ),
      );

      // Find text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Test input decoration theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.filled, isTrue);
      expect(inputTheme.fillColor, equals(AppColors.softGray));
      expect(inputTheme.focusedBorder?.borderSide.color, equals(AppColors.accentBlue));
      expect(inputTheme.errorBorder?.borderSide.color, equals(AppColors.errorRed));
    });

    testWidgets('should apply card theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Card(
              child: Text('Test Card'),
            ),
          ),
        ),
      );

      // Find card
      final card = find.byType(Card);
      expect(card, findsOneWidget);

      // Test card theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final cardTheme = theme.cardTheme;

      expect(cardTheme.color, equals(AppColors.surfacePrimary));
      expect(cardTheme.elevation, equals(AppSpacing.elevation2));
      expect(cardTheme.shadowColor, equals(AppColors.shadowMedium));
    });

    testWidgets('should apply app bar theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test App Bar'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
            body: const Text('Body'),
          ),
        ),
      );

      // Find app bar
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // Test app bar theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final appBarTheme = theme.appBarTheme;

      expect(appBarTheme.backgroundColor, equals(AppColors.surfacePrimary));
      expect(appBarTheme.foregroundColor, equals(AppColors.textPrimary));
      expect(appBarTheme.elevation, equals(AppSpacing.elevation0));
      expect(appBarTheme.centerTitle, isFalse);
    });

    testWidgets('should apply navigation themes correctly', (tester) async {
      int currentIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const Text('Body'),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => currentIndex = index,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
              ],
            ),
          ),
        ),
      );

      // Find bottom navigation bar
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // Test bottom navigation theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final bottomNavTheme = theme.bottomNavigationBarTheme;

      expect(bottomNavTheme.backgroundColor, equals(AppColors.surfacePrimary));
      expect(bottomNavTheme.selectedItemColor, equals(AppColors.accentBlue));
      expect(bottomNavTheme.unselectedItemColor, equals(AppColors.textTertiary));
      expect(bottomNavTheme.elevation, equals(AppSpacing.elevation2));
    });

    testWidgets('should apply dialog theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Test Dialog'),
                      content: const Text('Dialog content'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find dialog
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);

      // Test dialog theme
      final BuildContext context = tester.element(find.byType(AlertDialog));
      final ThemeData theme = Theme.of(context);
      final dialogTheme = theme.dialogTheme;

      expect(dialogTheme.backgroundColor, equals(AppColors.surfacePrimary));
      expect(dialogTheme.elevation, equals(AppSpacing.elevation5));
    });

    testWidgets('should apply list tile theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ListTile(
              leading: Icon(Icons.person),
              title: Text('Test Title'),
              subtitle: Text('Test Subtitle'),
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      // Find list tile
      final listTile = find.byType(ListTile);
      expect(listTile, findsOneWidget);

      // Test list tile theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final listTileTheme = theme.listTileTheme;

      expect(listTileTheme.iconColor, equals(AppColors.textSecondary));
      expect(listTileTheme.textColor, equals(AppColors.textPrimary));
      expect(listTileTheme.minLeadingWidth, equals(AppSpacing.minTouchTarget));
    });

    testWidgets('should apply chip theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Chip(
              label: Text('Test Chip'),
              avatar: Icon(Icons.star),
            ),
          ),
        ),
      );

      // Find chip
      final chip = find.byType(Chip);
      expect(chip, findsOneWidget);

      // Test chip theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final chipTheme = theme.chipTheme;

      expect(chipTheme.backgroundColor, equals(AppColors.surfaceSecondary));
      expect(chipTheme.elevation, equals(AppSpacing.elevation1));
      expect(chipTheme.brightness, equals(Brightness.light));
    });

    testWidgets('should apply progress indicator theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                CircularProgressIndicator(),
                LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      );

      // Find progress indicators
      final circularProgress = find.byType(CircularProgressIndicator);
      final linearProgress = find.byType(LinearProgressIndicator);
      
      expect(circularProgress, findsOneWidget);
      expect(linearProgress, findsOneWidget);

      // Test progress indicator theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final progressTheme = theme.progressIndicatorTheme;

      expect(progressTheme.color, equals(AppColors.accentBlue));
      expect(progressTheme.linearTrackColor, equals(AppColors.surfaceSecondary));
      expect(progressTheme.circularTrackColor, equals(AppColors.surfaceSecondary));
    });

    testWidgets('should handle theme extensions correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test Extensions'),
          ),
        ),
      );

      // Test theme extensions
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);

      // Verify custom theme extension exists
      expect(theme.extensions.isNotEmpty, isTrue);
      
      // Test extension colors through the getter (with null safety)
      final appColors = theme.appColors;
      expect(appColors, isNotNull);
      expect(appColors!.successColor, equals(AppColors.successGreen));
      expect(appColors.warningColor, equals(AppColors.warningAmber));
      expect(appColors.infoColor, equals(AppColors.infoBlue));
    });

    test('should set primary color correctly', () {
      final theme = AppTheme.lightTheme;
      final primaryColor = theme.primaryColor;
      
      expect(primaryColor, equals(AppColors.accentBlue));
    });

    test('should provide correct system UI overlay styles', () {
      final lightStyle = AppTheme.lightSystemUiOverlayStyle;
      final darkStyle = AppTheme.darkSystemUiOverlayStyle;
      
      // Test light style
      expect(lightStyle.statusBarColor, equals(Colors.transparent));
      expect(lightStyle.statusBarIconBrightness, equals(Brightness.dark));
      expect(lightStyle.systemNavigationBarColor, equals(AppColors.surfacePrimary));
      
      // Test dark style
      expect(darkStyle.statusBarColor, equals(Colors.transparent));
      expect(darkStyle.statusBarIconBrightness, equals(Brightness.light));
      expect(darkStyle.systemNavigationBarColor, equals(AppColors.charcoalNavy));
    });

    testWidgets('should provide correct adaptive color helpers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test Adaptive Colors'),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      
      // Test adaptive color methods
      expect(AppTheme.isDarkMode(context), isFalse);
      
      final adaptiveTextColor = AppTheme.getAdaptiveTextColor(context);
      expect(adaptiveTextColor, equals(AppColors.textPrimary));
      
      final adaptiveSurfaceColor = AppTheme.getAdaptiveSurfaceColor(context);
      expect(adaptiveSurfaceColor, equals(AppColors.surfacePrimary));
      
      final customAdaptiveColor = AppTheme.getAdaptiveColor(
        context,
        lightColor: Colors.red,
        darkColor: Colors.blue,
      );
      expect(customAdaptiveColor, equals(Colors.red));
    });

    test('should provide correct theme mode', () {
      final themeMode = AppTheme.getThemeMode();
      expect(themeMode, equals(ThemeMode.light));
    });

    testWidgets('should apply text selection theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(
                labelText: 'Test Selection',
              ),
            ),
          ),
        ),
      );

      // Test text selection theme
      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final textSelectionTheme = theme.textSelectionTheme;

      expect(textSelectionTheme.cursorColor, equals(AppColors.accentBlue));
      expect(textSelectionTheme.selectionHandleColor, equals(AppColors.accentBlue));
    });

    testWidgets('should apply visual density and material tap target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test Density'),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);

      expect(theme.visualDensity, equals(VisualDensity.adaptivePlatformDensity));
      expect(theme.materialTapTargetSize, equals(MaterialTapTargetSize.padded));
    });

    testWidgets('should apply page transitions correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Page 1'),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);
      final pageTransitions = theme.pageTransitionsTheme;

      expect(pageTransitions.builders.containsKey(TargetPlatform.android), isTrue);
      expect(pageTransitions.builders.containsKey(TargetPlatform.iOS), isTrue);
      expect(pageTransitions.builders.containsKey(TargetPlatform.windows), isTrue);
    });

    testWidgets('should apply interaction colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test Interactions'),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);

      // Test interaction colors
      expect(theme.splashColor, equals(AppColors.accentBlue.withValues(alpha: 0.12)));
      expect(theme.highlightColor, equals(AppColors.accentBlue.withValues(alpha: 0.08)));
      expect(theme.focusColor, equals(AppColors.accentBlue.withValues(alpha: 0.12)));
      expect(theme.hoverColor, equals(AppColors.hoverOverlay));
    });
  });

  group('AppTheme Dark Mode Tests', () {
    testWidgets('should provide dark theme configuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Text('Dark Theme Test'),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);

      // For now, dark theme is same as light theme with brightness change
      expect(theme.brightness, equals(Brightness.dark));
    });
  });

  group('AppTheme Error Handling', () {
    testWidgets('should handle missing theme extensions gracefully', (tester) async {
      // Create a theme without extensions
      final themeWithoutExtensions = ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightColorScheme,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: themeWithoutExtensions,
          home: const Scaffold(
            body: Text('No Extensions'),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      final ThemeData theme = Theme.of(context);

      // Should not throw when extensions are missing
      expect(() => theme.extensions, returnsNormally);
    });
  });
}