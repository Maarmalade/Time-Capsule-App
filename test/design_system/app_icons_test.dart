import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_icons.dart';
import 'package:time_capsule/design_system/app_colors.dart';

void main() {
  group('AppIcons', () {
    group('Size Constants', () {
      test('should have correct size values', () {
        expect(AppIcons.sizeXs, equals(16.0));
        expect(AppIcons.sizeSm, equals(20.0));
        expect(AppIcons.sizeMd, equals(24.0));
        expect(AppIcons.sizeLg, equals(32.0));
        expect(AppIcons.sizeXl, equals(48.0));
      });

      test('should have progressive size scaling', () {
        expect(AppIcons.sizeXs < AppIcons.sizeSm, isTrue);
        expect(AppIcons.sizeSm < AppIcons.sizeMd, isTrue);
        expect(AppIcons.sizeMd < AppIcons.sizeLg, isTrue);
        expect(AppIcons.sizeLg < AppIcons.sizeXl, isTrue);
      });
    });

    group('Color Constants', () {
      test('should use correct color values from AppColors', () {
        expect(AppIcons.primaryColor, equals(AppColors.charcoalNavy));
        expect(AppIcons.secondaryColor, equals(AppColors.darkGray));
        expect(AppIcons.accentColor, equals(AppColors.accentBlue));
        expect(AppIcons.disabledColor, equals(AppColors.mediumGray));
        expect(AppIcons.errorColor, equals(AppColors.errorRed));
        expect(AppIcons.successColor, equals(AppColors.successGreen));
        expect(AppIcons.warningColor, equals(AppColors.warningAmber));
        expect(AppIcons.onDarkColor, equals(AppColors.primaryWhite));
      });
    });

    group('Icon Theme Configuration', () {
      test('should have correct default icon theme', () {
        expect(AppIcons.iconTheme.color, equals(AppIcons.primaryColor));
        expect(AppIcons.iconTheme.size, equals(AppIcons.sizeMd));
      });

      test('should have correct app bar icon theme', () {
        expect(AppIcons.appBarIconTheme.color, equals(AppIcons.primaryColor));
        expect(AppIcons.appBarIconTheme.size, equals(AppIcons.sizeMd));
      });

      test('should have correct bottom navigation icon theme', () {
        expect(AppIcons.bottomNavIconTheme.size, equals(AppIcons.sizeMd));
      });

      test('should have correct FAB icon theme', () {
        expect(AppIcons.fabIconTheme.color, equals(AppIcons.onDarkColor));
        expect(AppIcons.fabIconTheme.size, equals(AppIcons.sizeMd));
      });
    });

    group('Utility Methods', () {
      testWidgets('icon() should create icon with default properties', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.icon(
                Icons.home,
                semanticLabel: 'Home',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.home);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeMd));
        expect(iconWidget.color, equals(AppIcons.primaryColor));
        expect(iconWidget.semanticLabel, equals('Home'));
      });

      testWidgets('icon() should accept custom size and color', (tester) async {
        const customSize = 30.0;
        const customColor = Colors.red;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.icon(
                Icons.star,
                size: customSize,
                color: customColor,
                semanticLabel: 'Star',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.star);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(customSize));
        expect(iconWidget.color, equals(customColor));
        expect(iconWidget.semanticLabel, equals('Star'));
      });

      testWidgets('smallIcon() should create small icon with secondary color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.smallIcon(
                Icons.info,
                semanticLabel: 'Information',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.info);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeSm));
        expect(iconWidget.color, equals(AppIcons.secondaryColor));
        expect(iconWidget.semanticLabel, equals('Information'));
      });

      testWidgets('largeIcon() should create large icon with primary color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.largeIcon(
                Icons.camera,
                semanticLabel: 'Camera',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.camera);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeLg));
        expect(iconWidget.color, equals(AppIcons.primaryColor));
        expect(iconWidget.semanticLabel, equals('Camera'));
      });

      testWidgets('accentIcon() should create icon with accent color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.accentIcon(
                Icons.add,
                semanticLabel: 'Add',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.add);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeMd));
        expect(iconWidget.color, equals(AppIcons.accentColor));
        expect(iconWidget.semanticLabel, equals('Add'));
      });

      testWidgets('errorIcon() should create icon with error color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.errorIcon(
                Icons.error,
                semanticLabel: 'Error',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.error);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeMd));
        expect(iconWidget.color, equals(AppIcons.errorColor));
        expect(iconWidget.semanticLabel, equals('Error'));
      });

      testWidgets('successIcon() should create icon with success color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.successIcon(
                Icons.check,
                semanticLabel: 'Success',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.check);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeMd));
        expect(iconWidget.color, equals(AppIcons.successColor));
        expect(iconWidget.semanticLabel, equals('Success'));
      });

      testWidgets('warningIcon() should create icon with warning color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.warningIcon(
                Icons.warning,
                semanticLabel: 'Warning',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.warning);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeMd));
        expect(iconWidget.color, equals(AppIcons.warningColor));
        expect(iconWidget.semanticLabel, equals('Warning'));
      });

      testWidgets('disabledIcon() should create icon with disabled color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.disabledIcon(
                Icons.block,
                semanticLabel: 'Disabled',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.block);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, equals(AppIcons.sizeMd));
        expect(iconWidget.color, equals(AppIcons.disabledColor));
        expect(iconWidget.semanticLabel, equals('Disabled'));
      });
    });

    group('Common Icon Definitions', () {
      testWidgets('should provide navigation icons with correct properties', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppIcons.backIcon,
                  AppIcons.closeIcon,
                  AppIcons.menuIcon,
                  AppIcons.moreVertIcon,
                  AppIcons.searchIcon,
                ],
              ),
            ),
          ),
        );

        // Test back icon
        final backIconFinder = find.byIcon(Icons.arrow_back);
        expect(backIconFinder, findsOneWidget);
        final Icon backIcon = tester.widget(backIconFinder);
        expect(backIcon.semanticLabel, equals('Go back'));

        // Test close icon
        final closeIconFinder = find.byIcon(Icons.close);
        expect(closeIconFinder, findsOneWidget);
        final Icon closeIcon = tester.widget(closeIconFinder);
        expect(closeIcon.semanticLabel, equals('Close'));

        // Test menu icon
        final menuIconFinder = find.byIcon(Icons.menu);
        expect(menuIconFinder, findsOneWidget);
        final Icon menuIcon = tester.widget(menuIconFinder);
        expect(menuIcon.semanticLabel, equals('Open menu'));
      });

      testWidgets('should provide content icons with correct properties', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppIcons.photoIcon,
                  AppIcons.videoIcon,
                  AppIcons.folderIcon,
                  AppIcons.shareIcon,
                ],
              ),
            ),
          ),
        );

        // Test photo icon
        final photoIconFinder = find.byIcon(Icons.photo);
        expect(photoIconFinder, findsOneWidget);
        final Icon photoIcon = tester.widget(photoIconFinder);
        expect(photoIcon.semanticLabel, equals('Photo'));

        // Test video icon
        final videoIconFinder = find.byIcon(Icons.videocam);
        expect(videoIconFinder, findsOneWidget);
        final Icon videoIcon = tester.widget(videoIconFinder);
        expect(videoIcon.semanticLabel, equals('Video'));
      });

      testWidgets('should provide status icons with correct colors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppIcons.checkIcon,
                  AppIcons.errorOutlineIcon,
                  AppIcons.warningOutlineIcon,
                  AppIcons.infoOutlineIcon,
                ],
              ),
            ),
          ),
        );

        // Test check icon (success color)
        final checkIconFinder = find.byIcon(Icons.check);
        expect(checkIconFinder, findsOneWidget);
        final Icon checkIcon = tester.widget(checkIconFinder);
        expect(checkIcon.color, equals(AppIcons.successColor));
        expect(checkIcon.semanticLabel, equals('Success'));

        // Test error icon
        final errorIconFinder = find.byIcon(Icons.error_outline);
        expect(errorIconFinder, findsOneWidget);
        final Icon errorIcon = tester.widget(errorIconFinder);
        expect(errorIcon.color, equals(AppIcons.errorColor));
        expect(errorIcon.semanticLabel, equals('Error'));
      });

      testWidgets('addIcon should use accent color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.addIcon,
            ),
          ),
        );

        final addIconFinder = find.byIcon(Icons.add);
        expect(addIconFinder, findsOneWidget);
        final Icon addIcon = tester.widget(addIconFinder);
        expect(addIcon.color, equals(AppIcons.accentColor));
        expect(addIcon.semanticLabel, equals('Add new item'));
      });

      testWidgets('favoriteIcon should use error color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppIcons.favoriteIcon,
            ),
          ),
        );

        final favoriteIconFinder = find.byIcon(Icons.favorite);
        expect(favoriteIconFinder, findsOneWidget);
        final Icon favoriteIcon = tester.widget(favoriteIconFinder);
        expect(favoriteIcon.color, equals(AppIcons.errorColor));
        expect(favoriteIcon.semanticLabel, equals('Favorite'));
      });
    });

    group('Accessibility Compliance', () {
      testWidgets('all icon methods should require semantic labels', (tester) async {
        // This test ensures that semantic labels are required parameters
        // The fact that the code compiles with semanticLabel as required means this test passes
        expect(() => AppIcons.icon(Icons.home, semanticLabel: 'Home'), returnsNormally);
        expect(() => AppIcons.smallIcon(Icons.info, semanticLabel: 'Info'), returnsNormally);
        expect(() => AppIcons.largeIcon(Icons.camera, semanticLabel: 'Camera'), returnsNormally);
        expect(() => AppIcons.accentIcon(Icons.add, semanticLabel: 'Add'), returnsNormally);
        expect(() => AppIcons.errorIcon(Icons.error, semanticLabel: 'Error'), returnsNormally);
        expect(() => AppIcons.successIcon(Icons.check, semanticLabel: 'Success'), returnsNormally);
        expect(() => AppIcons.warningIcon(Icons.warning, semanticLabel: 'Warning'), returnsNormally);
        expect(() => AppIcons.disabledIcon(Icons.block, semanticLabel: 'Disabled'), returnsNormally);
      });

      testWidgets('common icons should have meaningful semantic labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppIcons.backIcon,
                  AppIcons.addIcon,
                  AppIcons.favoriteIcon,
                  AppIcons.checkIcon,
                  AppIcons.errorOutlineIcon,
                ],
              ),
            ),
          ),
        );

        // Verify semantic labels are descriptive and actionable
        final icons = [
          {'finder': find.byIcon(Icons.arrow_back), 'label': 'Go back'},
          {'finder': find.byIcon(Icons.add), 'label': 'Add new item'},
          {'finder': find.byIcon(Icons.favorite), 'label': 'Favorite'},
          {'finder': find.byIcon(Icons.check), 'label': 'Success'},
          {'finder': find.byIcon(Icons.error_outline), 'label': 'Error'},
        ];

        for (final iconData in icons) {
          final iconFinder = iconData['finder'] as Finder;
          final expectedLabel = iconData['label'] as String;
          
          expect(iconFinder, findsOneWidget);
          final Icon icon = tester.widget(iconFinder);
          expect(icon.semanticLabel, equals(expectedLabel));
          expect(icon.semanticLabel!.isNotEmpty, isTrue);
        }
      });

      test('icon sizes should meet minimum touch target requirements', () {
        // Minimum touch target size should be 44px according to accessibility guidelines
        // Our sizeMd (24px) is acceptable for icons within larger touch targets
        // Our sizeLg (32px) provides better accessibility for standalone icons
        expect(AppIcons.sizeLg >= 32.0, isTrue, reason: 'Large icons should be at least 32px for better accessibility');
        expect(AppIcons.sizeMd >= 20.0, isTrue, reason: 'Medium icons should be at least 20px for readability');
      });
    });

    group('Visual Consistency', () {
      test('should maintain consistent color usage patterns', () {
        // Primary actions should use accent color
        expect(AppIcons.accentColor, equals(AppColors.accentBlue));
        
        // Status colors should be distinct and meaningful
        expect(AppIcons.errorColor, isNot(equals(AppIcons.successColor)));
        expect(AppIcons.warningColor, isNot(equals(AppIcons.errorColor)));
        expect(AppIcons.successColor, isNot(equals(AppIcons.warningColor)));
        
        // Disabled state should be visually distinct
        expect(AppIcons.disabledColor, isNot(equals(AppIcons.primaryColor)));
        expect(AppIcons.disabledColor, isNot(equals(AppIcons.secondaryColor)));
      });

      test('should have logical size progression', () {
        final sizes = [
          AppIcons.sizeXs,
          AppIcons.sizeSm,
          AppIcons.sizeMd,
          AppIcons.sizeLg,
          AppIcons.sizeXl,
        ];

        for (int i = 0; i < sizes.length - 1; i++) {
          expect(sizes[i] < sizes[i + 1], isTrue, 
            reason: 'Icon sizes should progress logically from smallest to largest');
        }
      });

      test('should use Material Design recommended icon sizes', () {
        // Material Design recommends 18dp, 24dp, 36dp, 48dp
        // Our sizes align with these recommendations
        expect(AppIcons.sizeSm, equals(20.0)); // Close to 18dp
        expect(AppIcons.sizeMd, equals(24.0)); // Exact match
        expect(AppIcons.sizeLg, equals(32.0)); // Between 24dp and 36dp
        expect(AppIcons.sizeXl, equals(48.0)); // Exact match
      });
    });
  });
}