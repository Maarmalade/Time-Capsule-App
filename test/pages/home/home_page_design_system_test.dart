import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:time_capsule/pages/home/home_page.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_typography.dart';
import 'package:time_capsule/design_system/app_spacing.dart';
import 'package:time_capsule/design_system/app_theme.dart';
import '../../test_helpers/firebase_mock_setup.dart';

@GenerateMocks([FirebaseAuth, User])
import 'home_page_design_system_test.mocks.dart';

void main() {
  group('HomePage Design System Integration Tests', () {
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

    testWidgets('HomePage uses design system colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      // Verify scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.surfacePrimary));

      // Verify page title uses correct typography
      final titleText = tester.widget<Text>(find.text('Home Page'));
      expect(titleText.style?.fontSize, equals(AppTypography.displayMedium.fontSize));
      expect(titleText.style?.fontWeight, equals(AppTypography.displayMedium.fontWeight));
    });

    testWidgets('HomePage uses design system spacing correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      // Verify main padding uses design system values
      final paddingWidget = tester.widget<Padding>(
        find.descendant(
          of: find.byType(SafeArea),
          matching: find.byType(Padding),
        ).first,
      );
      expect(paddingWidget.padding, equals(AppSpacing.pageAll));

      // Verify SizedBox spacing uses design system values
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final spacingSizedBox = sizedBoxes.firstWhere(
        (box) => box.height == AppSpacing.sm,
        orElse: () => throw Exception('Expected SizedBox with AppSpacing.sm height not found'),
      );
      expect(spacingSizedBox.height, equals(AppSpacing.sm));
    });

    testWidgets('HomePage icons use correct design system sizing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      // Verify back button icon size
      final backIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_back));
      expect(backIcon.size, equals(AppSpacing.iconSizeLarge));
      expect(backIcon.color, equals(AppColors.textPrimary));

      // Verify menu icon size
      final menuIcon = tester.widget<Icon>(find.byIcon(Icons.more_vert));
      expect(menuIcon.size, equals(AppSpacing.iconSizeLarge));
      expect(menuIcon.color, equals(AppColors.textPrimary));
    });

    testWidgets('HomePage logout dialog uses design system styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      // Tap the menu button to open popup
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap logout option
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify dialog title uses correct typography
      final dialogTitle = tester.widget<Text>(find.text('Logout').first);
      expect(dialogTitle.style?.fontSize, equals(AppTypography.headlineSmall.fontSize));
      expect(dialogTitle.style?.color, equals(AppColors.textPrimary));

      // Verify dialog content uses correct typography
      final dialogContent = tester.widget<Text>(find.text('Are you sure you want to logout?'));
      expect(dialogContent.style?.fontSize, equals(AppTypography.bodyMedium.fontSize));
      expect(dialogContent.style?.color, equals(AppColors.textSecondary));

      // Verify logout button uses error color
      final logoutButtons = tester.widgetList<Text>(find.text('Logout'));
      final logoutButtonText = logoutButtons.last; // The button text, not dialog title
      expect(logoutButtonText.style?.color, equals(AppColors.errorRed));
    });

    testWidgets('HomePage maintains proper contrast ratios', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      // Verify text on background meets contrast requirements
      final titleText = tester.widget<Text>(find.text('Home Page'));
      final titleColor = titleText.style?.color ?? AppColors.textPrimary;
      
      // Calculate contrast ratio (simplified check)
      final backgroundLuminance = AppColors.surfacePrimary.computeLuminance();
      final textLuminance = titleColor.computeLuminance();
      final contrastRatio = (backgroundLuminance + 0.05) / (textLuminance + 0.05);
      
      // Should meet WCAG AA standard (4.5:1 for normal text)
      expect(contrastRatio, greaterThan(4.5));
    });

    testWidgets('HomePage touch targets meet accessibility requirements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      // Verify back button has minimum touch target size
      final backButton = tester.widget<IconButton>(find.byIcon(Icons.arrow_back).first);
      expect(backButton.style?.minimumSize?.resolve({}), 
        equals(const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget)));

      // Verify menu button touch target
      final menuButtons = find.byType(PopupMenuButton<String>);
      expect(menuButtons, findsOneWidget);
      
      final menuButtonSize = tester.getSize(menuButtons);
      expect(menuButtonSize.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
      expect(menuButtonSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    });

    testWidgets('HomePage grid uses consistent spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      // Find the GridView
      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
      
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.mainAxisSpacing, equals(AppSpacing.lg));
      expect(delegate.crossAxisSpacing, equals(AppSpacing.lg));
      expect(delegate.crossAxisCount, equals(2));
    });

    testWidgets('HomePage responds to theme changes', (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.surfacePrimary));

      // Verify theme is properly applied
      final context = tester.element(find.byType(HomePage));
      final theme = Theme.of(context);
      expect(theme.colorScheme.primary, equals(AppColors.accentBlue));
      expect(theme.textTheme.displayMedium?.fontFamily, contains('Inter'));
    });
  });
}