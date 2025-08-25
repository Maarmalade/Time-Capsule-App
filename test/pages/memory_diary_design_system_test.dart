import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:time_capsule/pages/memory_album/memory_album_page.dart';
import 'package:time_capsule/pages/diary/digital_diary_page.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_typography.dart';
import 'package:time_capsule/design_system/app_spacing.dart';
import 'package:time_capsule/design_system/app_theme.dart';
import '../test_helpers/firebase_mock_setup.dart';

@GenerateMocks([FirebaseAuth, User])
import 'memory_diary_design_system_test.mocks.dart';

void main() {
  group('Memory Album and Diary Pages Design System Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUpAll(() async {
      setupFirebaseAuthMocks();
      await Firebase.initializeApp();
    });

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
    });

    group('MemoryAlbumPage Design System Tests', () {
      testWidgets('MemoryAlbumPage uses design system colors and styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MemoryAlbumPage(),
          ),
        );

        // Verify scaffold background color
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppColors.surfacePrimary));

        // Verify app bar title typography
        final titleText = tester.widget<Text>(find.text('My Memory Album'));
        expect(titleText.style?.fontSize, equals(AppTypography.headlineMedium.fontSize));
        expect(titleText.style?.color, equals(AppColors.textPrimary));
      });

      testWidgets('MemoryAlbumPage grid uses design system spacing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MemoryAlbumPage(),
          ),
        );

        // Wait for the StreamBuilder to complete
        await tester.pumpAndSettle();

        // Find the GridView
        final gridView = tester.widget<GridView>(find.byType(GridView));
        expect(gridView.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
        
        final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.mainAxisSpacing, equals(AppSpacing.md));
        expect(delegate.crossAxisSpacing, equals(AppSpacing.md));
        expect(delegate.crossAxisCount, equals(2));
        expect(delegate.childAspectRatio, equals(1.0));

        // Verify grid padding
        expect(gridView.padding, equals(AppSpacing.paddingMd));
      });

      testWidgets('MemoryAlbumPage add button uses design system styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MemoryAlbumPage(),
          ),
        );

        // Wait for the StreamBuilder to complete
        await tester.pumpAndSettle();

        // Find the add button (InkWell with add icon)
        final addIcon = tester.widget<Icon>(find.byIcon(Icons.add));
        expect(addIcon.size, equals(48));
        expect(addIcon.color, equals(AppColors.textTertiary));

        // Verify container styling
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppColors.surfacePrimary));
        expect(decoration.borderRadius, equals(AppSpacing.cardRadius));
        expect(decoration.boxShadow?.first.color, equals(AppColors.shadowMedium));
      });

      testWidgets('MemoryAlbumPage app bar icons use correct colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MemoryAlbumPage(),
          ),
        );

        // Verify back button color
        final backButton = tester.widget<BackButton>(find.byType(BackButton));
        expect(backButton.color, equals(AppColors.textPrimary));

        // Verify home icon color
        final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home));
        expect(homeIcon.color, equals(AppColors.textPrimary));
      });
    });

    group('DigitalDiaryPage Design System Tests', () {
      testWidgets('DigitalDiaryPage uses design system colors and typography', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DigitalDiaryPage(),
          ),
        );

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Verify scaffold background color
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppColors.surfacePrimary));

        // Verify app bar title typography
        final titleText = tester.widget<Text>(find.text('Digital Diary'));
        expect(titleText.style?.fontSize, equals(AppTypography.headlineMedium.fontSize));
        expect(titleText.style?.color, equals(AppColors.textPrimary));
      });

      testWidgets('DigitalDiaryPage calendar container uses design system styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DigitalDiaryPage(),
          ),
        );

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Find the calendar container
        final containers = tester.widgetList<Container>(find.byType(Container));
        final calendarContainer = containers.firstWhere(
          (container) {
            final decoration = container.decoration as BoxDecoration?;
            return decoration?.borderRadius == AppSpacing.cardRadius;
          },
          orElse: () => throw Exception('Calendar container not found'),
        );

        final decoration = calendarContainer.decoration as BoxDecoration;
        expect(decoration.color, equals(AppColors.surfacePrimary));
        expect(decoration.borderRadius, equals(AppSpacing.cardRadius));
        expect(decoration.boxShadow?.first.color, equals(AppColors.shadowLight));
      });

      testWidgets('DigitalDiaryPage button uses design system styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DigitalDiaryPage(),
          ),
        );

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Find the "Write Diary for today!" button
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        
        // Verify button dimensions
        final buttonSize = tester.getSize(find.byType(ElevatedButton));
        expect(buttonSize.height, equals(AppSpacing.minTouchTarget));

        // Verify button text style
        final buttonText = tester.widget<Text>(find.text('Write Diary for today!'));
        expect(buttonText.style, equals(AppTypography.buttonText));
      });

      testWidgets('DigitalDiaryPage uses design system colors for calendar states', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DigitalDiaryPage(),
          ),
        );

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Note: Testing calendar colors would require more complex setup
        // as TableCalendar uses its own styling system. This test verifies
        // the structure is in place for design system integration.
        expect(find.byType(TableCalendar), findsOneWidget);
      });

      testWidgets('DigitalDiaryPage loading indicator uses design system colors', (WidgetTester tester) async {
        // Create a version that shows loading state
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DigitalDiaryPage(),
          ),
        );

        // The loading indicator should be visible initially
        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(progressIndicator.color, equals(AppColors.accentBlue));
      });

      testWidgets('DigitalDiaryPage spacing uses design system values', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DigitalDiaryPage(),
          ),
        );

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Verify main padding
        final paddingWidget = tester.widget<Padding>(
          find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Padding),
          ).first,
        );
        expect(paddingWidget.padding, equals(AppSpacing.paddingMd));

        // Verify spacing between calendar and button
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final spacingSizedBox = sizedBoxes.firstWhere(
          (box) => box.height == AppSpacing.lg,
          orElse: () => throw Exception('Expected SizedBox with AppSpacing.lg height not found'),
        );
        expect(spacingSizedBox.height, equals(AppSpacing.lg));
      });
    });

    group('Memory and Diary Pages Accessibility Tests', () {
      testWidgets('All pages meet touch target requirements', (WidgetTester tester) async {
        final pages = [
          const MemoryAlbumPage(),
          const DigitalDiaryPage(),
        ];

        for (final page in pages) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: page,
            ),
          );

          // Wait for any async operations
          await tester.pumpAndSettle();

          // Check button touch targets
          final buttons = find.byType(ElevatedButton);
          for (final button in buttons.evaluate()) {
            final buttonSize = tester.getSize(find.byWidget(button.widget));
            expect(buttonSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
          }

          // Check icon button touch targets
          final iconButtons = find.byType(IconButton);
          for (final iconButton in iconButtons.evaluate()) {
            final size = tester.getSize(find.byWidget(iconButton.widget));
            expect(size.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
            expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
          }
        }
      });

      testWidgets('All pages maintain proper contrast ratios', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MemoryAlbumPage(),
          ),
        );

        // Test primary text contrast
        final backgroundLuminance = AppColors.surfacePrimary.computeLuminance();
        final textLuminance = AppColors.textPrimary.computeLuminance();
        final contrastRatio = (backgroundLuminance + 0.05) / (textLuminance + 0.05);
        
        // Should meet WCAG AA standard
        expect(contrastRatio, greaterThan(4.5));
      });
    });

    group('Memory and Diary Pages Responsive Design Tests', () {
      testWidgets('Pages adapt to different screen sizes', (WidgetTester tester) async {
        // Test with different screen sizes
        final sizes = [
          const Size(320, 568), // Small phone
          const Size(375, 667), // Medium phone
          const Size(414, 896), // Large phone
          const Size(768, 1024), // Tablet
        ];

        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MemoryAlbumPage(),
            ),
          );

          // Wait for any async operations
          await tester.pumpAndSettle();

          // Verify page content fits within screen bounds
          final scaffold = find.byType(Scaffold);
          final scaffoldSize = tester.getSize(scaffold);
          expect(scaffoldSize.width, lessThanOrEqualTo(size.width));
          expect(scaffoldSize.height, lessThanOrEqualTo(size.height));

          // Verify grid adapts to screen size
          final gridView = tester.widget<GridView>(find.byType(GridView));
          final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
          expect(delegate.crossAxisCount, equals(2)); // Should remain 2 for all sizes in this design
        }

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Memory and Diary Pages Visual Consistency Tests', () {
      testWidgets('Pages use consistent card styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MemoryAlbumPage(),
          ),
        );

        // Wait for any async operations
        await tester.pumpAndSettle();

        // Find containers that represent cards
        final containers = tester.widgetList<Container>(find.byType(Container));
        final cardContainers = containers.where((container) {
          final decoration = container.decoration as BoxDecoration?;
          return decoration?.borderRadius == AppSpacing.cardRadius;
        });

        // Verify all card containers use consistent styling
        for (final container in cardContainers) {
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, equals(AppColors.surfacePrimary));
          expect(decoration.borderRadius, equals(AppSpacing.cardRadius));
          expect(decoration.boxShadow?.isNotEmpty, isTrue);
        }
      });

      testWidgets('Pages use consistent typography hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DigitalDiaryPage(),
          ),
        );

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Verify app bar title uses headline medium
        final titleText = tester.widget<Text>(find.text('Digital Diary'));
        expect(titleText.style?.fontSize, equals(AppTypography.headlineMedium.fontSize));

        // Verify button text uses button text style
        final buttonText = tester.widget<Text>(find.text('Write Diary for today!'));
        expect(buttonText.style, equals(AppTypography.buttonText));
      });
    });
  });
}