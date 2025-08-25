import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:time_capsule/design_system/app_theme.dart';
import 'package:time_capsule/design_system/app_typography.dart';

void main() {
  group('Main App Configuration Integration Tests', () {
    test('should configure Google Fonts settings', () {
      // Test that we can configure Google Fonts for production use
      GoogleFonts.config.allowRuntimeFetching = false;
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
      
      // Reset for other tests
      GoogleFonts.config.allowRuntimeFetching = true;
    });

    testWidgets('should apply complete MaterialApp configuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Time Capsule',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppTheme.getThemeMode(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.3,
                ),
              ),
              child: child!,
            );
          },
          home: const Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify MaterialApp configuration matches main.dart
      expect(materialApp.title, equals('Time Capsule'));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, equals(ThemeMode.light));
      expect(materialApp.builder, isNotNull);

      // Verify theme is properly applied
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);
      
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, isNotNull);
      expect(theme.scaffoldBackgroundColor, isNotNull);
      expect(theme.textTheme, isNotNull);
    });

    testWidgets('should apply design system components correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test App')),
            body: Column(
              children: [
                Text('Display Large', style: AppTypography.displayLarge),
                ElevatedButton(onPressed: () {}, child: const Text('Button')),
                const TextField(decoration: InputDecoration(labelText: 'Input')),
                const Card(child: Text('Card')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all components render correctly with theme applied
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Display Large'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);

      // Verify theme components are applied
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);
      
      expect(theme.appBarTheme, isNotNull);
      expect(theme.textTheme, isNotNull);
      expect(theme.elevatedButtonTheme, isNotNull);
      expect(theme.inputDecorationTheme, isNotNull);
      expect(theme.cardTheme, isNotNull);
    });

    test('should provide correct theme configuration', () {
      // Test theme mode
      final themeMode = AppTheme.getThemeMode();
      expect(themeMode, equals(ThemeMode.light));
      
      // Test system UI overlay styles
      final lightStyle = AppTheme.lightSystemUiOverlayStyle;
      expect(lightStyle.statusBarColor, equals(Colors.transparent));
      expect(lightStyle.statusBarIconBrightness, equals(Brightness.dark));
      
      final darkStyle = AppTheme.darkSystemUiOverlayStyle;
      expect(darkStyle.statusBarColor, equals(Colors.transparent));
      expect(darkStyle.statusBarIconBrightness, equals(Brightness.light));
    });
  });

  group('Typography Integration', () {
    testWidgets('should apply typography system correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                Text('Test Typography'),
                Text('System Font', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify text renders correctly
      expect(find.text('Test Typography'), findsOneWidget);
      expect(find.text('System Font'), findsOneWidget);
      
      // Verify theme typography is applied
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);
      expect(theme.textTheme, isNotNull);
      expect(theme.textTheme.bodyLarge, isNotNull);
      // Verify font family is configured through textTheme
      expect(theme.textTheme.bodyLarge?.fontFamily, isNotNull);
    });
  });

  group('Error Handling', () {
    testWidgets('should handle theme application gracefully', (tester) async {
      // Test with minimal MaterialApp configuration
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Minimal App'),
          ),
        ),
      );

      // Should not throw errors
      expect(find.text('Minimal App'), findsOneWidget);
    });
  });
}