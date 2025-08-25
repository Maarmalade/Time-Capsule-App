import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_images.dart';
import 'package:time_capsule/design_system/app_colors.dart';

void main() {
  group('AppImages', () {
    group('Constants', () {
      test('should have correct border radius values', () {
        expect(AppImages.radiusSmall, equals(8.0));
        expect(AppImages.radiusMedium, equals(12.0));
        expect(AppImages.radiusLarge, equals(16.0));
        expect(AppImages.radiusXLarge, equals(24.0));
        expect(AppImages.radiusCircular, equals(50.0));
      });

      test('should have correct aspect ratio values', () {
        expect(AppImages.aspectRatioSquare, equals(1.0));
        expect(AppImages.aspectRatioPhoto, equals(4.0 / 3.0));
        expect(AppImages.aspectRatioWidescreen, equals(16.0 / 9.0));
        expect(AppImages.aspectRatioPortrait, equals(3.0 / 4.0));
        expect(AppImages.aspectRatioCard, equals(5.0 / 4.0));
      });

      test('should have correct size values', () {
        expect(AppImages.sizeXS, equals(32.0));
        expect(AppImages.sizeSmall, equals(48.0));
        expect(AppImages.sizeMedium, equals(80.0));
        expect(AppImages.sizeLarge, equals(120.0));
        expect(AppImages.sizeXLarge, equals(200.0));
      });

      test('should have progressive size scaling', () {
        expect(AppImages.sizeXS < AppImages.sizeSmall, isTrue);
        expect(AppImages.sizeSmall < AppImages.sizeMedium, isTrue);
        expect(AppImages.sizeMedium < AppImages.sizeLarge, isTrue);
        expect(AppImages.sizeLarge < AppImages.sizeXLarge, isTrue);
      });

      test('should use correct placeholder and loading colors', () {
        expect(AppImages.placeholderBackground, equals(AppColors.lightGray));
        expect(AppImages.placeholderIcon, equals(AppColors.mediumGray));
        expect(AppImages.loadingBackground, equals(AppColors.softGray));
        expect(AppImages.loadingIndicatorColor, equals(AppColors.accentBlue));
      });
    });

    group('Border Radius Utilities', () {
      test('should create correct border radius objects', () {
        expect(AppImages.smallRadius.topLeft.x, equals(AppImages.radiusSmall));
        expect(AppImages.mediumRadius.topLeft.x, equals(AppImages.radiusMedium));
        expect(AppImages.largeRadius.topLeft.x, equals(AppImages.radiusLarge));
        expect(AppImages.xLargeRadius.topLeft.x, equals(AppImages.radiusXLarge));
        expect(AppImages.circularRadius.topLeft.x, equals(AppImages.radiusCircular));
      });
    });

    group('Image Container Utilities', () {
      testWidgets('imageContainer should create container with default properties', (tester) async {
        const testChild = Text('Test Image');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.imageContainer(
                child: testChild,
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(AppImages.mediumRadius));
        expect(decoration.color, equals(AppImages.placeholderBackground));
        expect(container.clipBehavior, equals(Clip.antiAlias));
      });

      testWidgets('imageContainer should accept custom dimensions and border radius', (tester) async {
        const testChild = Text('Test Image');
        const customWidth = 100.0;
        const customHeight = 150.0;
        final customRadius = BorderRadius.circular(20.0);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.imageContainer(
                child: testChild,
                width: customWidth,
                height: customHeight,
                borderRadius: customRadius,
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        expect(container.constraints?.maxWidth, equals(customWidth));
        expect(container.constraints?.maxHeight, equals(customHeight));
        
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(customRadius));
      });

      testWidgets('imageContainer should wrap with AspectRatio when specified', (tester) async {
        const testChild = Text('Test Image');
        const customAspectRatio = 2.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.imageContainer(
                child: testChild,
                aspectRatio: customAspectRatio,
              ),
            ),
          ),
        );

        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsOneWidget);

        final AspectRatio aspectRatio = tester.widget(aspectRatioFinder);
        expect(aspectRatio.aspectRatio, equals(customAspectRatio));
      });

      testWidgets('squareImageContainer should create square container', (tester) async {
        const testChild = Text('Test Image');
        const customSize = 100.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.squareImageContainer(
                child: testChild,
                size: customSize,
              ),
            ),
          ),
        );

        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsOneWidget);

        final AspectRatio aspectRatio = tester.widget(aspectRatioFinder);
        expect(aspectRatio.aspectRatio, equals(AppImages.aspectRatioSquare));

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        expect(container.constraints?.maxWidth, equals(customSize));
        expect(container.constraints?.maxHeight, equals(customSize));
      });

      testWidgets('circularImageContainer should create circular container', (tester) async {
        const testChild = Text('Test Image');
        const customSize = 100.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.circularImageContainer(
                child: testChild,
                size: customSize,
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        expect(container.constraints?.maxWidth, equals(customSize));
        expect(container.constraints?.maxHeight, equals(customSize));
        
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, equals(BoxShape.circle));
        expect(decoration.color, equals(AppImages.placeholderBackground));
        expect(container.clipBehavior, equals(Clip.antiAlias));
      });

      testWidgets('memoryCardContainer should use card aspect ratio', (tester) async {
        const testChild = Text('Test Image');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.memoryCardContainer(
                child: testChild,
              ),
            ),
          ),
        );

        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsOneWidget);

        final AspectRatio aspectRatio = tester.widget(aspectRatioFinder);
        expect(aspectRatio.aspectRatio, equals(AppImages.aspectRatioCard));
      });

      testWidgets('videoThumbnailContainer should show play button by default', (tester) async {
        const testChild = Text('Test Video');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.videoThumbnailContainer(
                child: testChild,
              ),
            ),
          ),
        );

        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsOneWidget);

        final AspectRatio aspectRatio = tester.widget(aspectRatioFinder);
        expect(aspectRatio.aspectRatio, equals(AppImages.aspectRatioWidescreen));

        final playIconFinder = find.byIcon(Icons.play_arrow);
        expect(playIconFinder, findsOneWidget);

        final Icon playIcon = tester.widget(playIconFinder);
        expect(playIcon.semanticLabel, equals('Play video'));
      });

      testWidgets('videoThumbnailContainer should hide play button when specified', (tester) async {
        const testChild = Text('Test Video');
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.videoThumbnailContainer(
                child: testChild,
                showPlayButton: false,
              ),
            ),
          ),
        );

        final playIconFinder = find.byIcon(Icons.play_arrow);
        expect(playIconFinder, findsNothing);
      });
    });

    group('Placeholder Utilities', () {
      testWidgets('placeholder should create container with icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.placeholder(
                icon: Icons.photo,
                semanticLabel: 'Test placeholder',
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppImages.placeholderBackground));
        expect(decoration.borderRadius, equals(AppImages.mediumRadius));

        final iconFinder = find.byIcon(Icons.photo);
        expect(iconFinder, findsOneWidget);

        final Icon icon = tester.widget(iconFinder);
        expect(icon.color, equals(AppImages.placeholderIcon));
        expect(icon.semanticLabel, equals('Test placeholder'));
      });

      testWidgets('placeholder should wrap with AspectRatio when specified', (tester) async {
        const customAspectRatio = 2.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.placeholder(
                aspectRatio: customAspectRatio,
                semanticLabel: 'Test placeholder',
              ),
            ),
          ),
        );

        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsOneWidget);

        final AspectRatio aspectRatio = tester.widget(aspectRatioFinder);
        expect(aspectRatio.aspectRatio, equals(customAspectRatio));
      });

      testWidgets('avatarPlaceholder should create circular container with person icon', (tester) async {
        const customSize = 100.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.avatarPlaceholder(
                size: customSize,
                semanticLabel: 'Test avatar',
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        expect(container.constraints?.maxWidth, equals(customSize));
        expect(container.constraints?.maxHeight, equals(customSize));
        
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, equals(BoxShape.circle));
        expect(decoration.color, equals(AppImages.placeholderBackground));

        final iconFinder = find.byIcon(Icons.person);
        expect(iconFinder, findsOneWidget);

        final Icon icon = tester.widget(iconFinder);
        expect(icon.semanticLabel, equals('Test avatar'));
      });

      testWidgets('photoPlaceholder should use photo icon and card aspect ratio', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.photoPlaceholder(
                semanticLabel: 'Test photo placeholder',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.photo);
        expect(iconFinder, findsOneWidget);

        final Icon icon = tester.widget(iconFinder);
        expect(icon.semanticLabel, equals('Test photo placeholder'));

        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsOneWidget);

        final AspectRatio aspectRatio = tester.widget(aspectRatioFinder);
        expect(aspectRatio.aspectRatio, equals(AppImages.aspectRatioCard));
      });

      testWidgets('videoPlaceholder should use video icon and widescreen aspect ratio', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.videoPlaceholder(
                semanticLabel: 'Test video placeholder',
              ),
            ),
          ),
        );

        final iconFinder = find.byIcon(Icons.videocam);
        expect(iconFinder, findsOneWidget);

        final Icon icon = tester.widget(iconFinder);
        expect(icon.semanticLabel, equals('Test video placeholder'));

        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsOneWidget);

        final AspectRatio aspectRatio = tester.widget(aspectRatioFinder);
        expect(aspectRatio.aspectRatio, equals(AppImages.aspectRatioWidescreen));
      });
    });

    group('Loading State Utilities', () {
      testWidgets('loadingIndicator should create container with progress indicator', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.loadingIndicator(
                semanticLabel: 'Test loading',
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppImages.loadingBackground));
        expect(decoration.borderRadius, equals(AppImages.mediumRadius));

        final progressFinder = find.byType(CircularProgressIndicator);
        expect(progressFinder, findsOneWidget);

        // Check for Semantics widget that wraps the progress indicator
        final semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsWidgets);
        
        // Verify semantic label is present
        expect(find.bySemanticsLabel('Test loading'), findsOneWidget);
      });

      testWidgets('skeletonLoader should create container with shimmer effect', (tester) async {
        const customWidth = 100.0;
        const customHeight = 150.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.skeletonLoader(
                width: customWidth,
                height: customHeight,
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container).first;
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        expect(container.constraints?.maxWidth, equals(customWidth));
        expect(container.constraints?.maxHeight, equals(customHeight));
        
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppImages.loadingBackground));
        expect(decoration.borderRadius, equals(AppImages.mediumRadius));
      });

      testWidgets('circularSkeletonLoader should create circular container', (tester) async {
        const customSize = 100.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.circularSkeletonLoader(
                size: customSize,
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container).first;
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        expect(container.constraints?.maxWidth, equals(customSize));
        expect(container.constraints?.maxHeight, equals(customSize));
        
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, equals(BoxShape.circle));
        expect(decoration.color, equals(AppImages.loadingBackground));
      });
    });

    group('Error State Utilities', () {
      testWidgets('errorState should create container with error icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.errorState(
                semanticLabel: 'Test error',
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(AppImages.placeholderBackground));
        expect(decoration.borderRadius, equals(AppImages.mediumRadius));
        expect(decoration.border?.top.color, equals(AppColors.errorRed.withOpacity(0.3)));

        final iconFinder = find.byIcon(Icons.error_outline);
        expect(iconFinder, findsOneWidget);

        final Icon icon = tester.widget(iconFinder);
        expect(icon.color, equals(AppColors.errorRed));
        expect(icon.semanticLabel, equals('Test error'));
      });

      testWidgets('errorState should show retry button when callback provided', (tester) async {
        bool retryPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.errorState(
                onRetry: () => retryPressed = true,
                semanticLabel: 'Test error',
              ),
            ),
          ),
        );

        final retryButtonFinder = find.text('Retry');
        expect(retryButtonFinder, findsOneWidget);

        await tester.tap(retryButtonFinder);
        expect(retryPressed, isTrue);
      });

      testWidgets('errorState should not show retry button when no callback provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.errorState(
                semanticLabel: 'Test error',
              ),
            ),
          ),
        );

        final retryButtonFinder = find.text('Retry');
        expect(retryButtonFinder, findsNothing);
      });
    });

    group('Utility Methods', () {
      test('calculateAspectRatio should return correct ratios', () {
        expect(AppImages.calculateAspectRatio(100, 100), equals(1.0));
        expect(AppImages.calculateAspectRatio(200, 100), equals(2.0));
        expect(AppImages.calculateAspectRatio(100, 200), equals(0.5));
      });

      test('calculateAspectRatio should handle invalid dimensions', () {
        expect(AppImages.calculateAspectRatio(0, 100), equals(AppImages.aspectRatioSquare));
        expect(AppImages.calculateAspectRatio(100, 0), equals(AppImages.aspectRatioSquare));
        expect(AppImages.calculateAspectRatio(-100, 100), equals(AppImages.aspectRatioSquare));
        expect(AppImages.calculateAspectRatio(100, -100), equals(AppImages.aspectRatioSquare));
      });

      test('isSquareAspectRatio should detect square ratios within tolerance', () {
        expect(AppImages.isSquareAspectRatio(1.0), isTrue);
        expect(AppImages.isSquareAspectRatio(1.05), isTrue);
        expect(AppImages.isSquareAspectRatio(0.95), isTrue);
        expect(AppImages.isSquareAspectRatio(1.2), isFalse);
        expect(AppImages.isSquareAspectRatio(0.8), isFalse);
      });

      test('isSquareAspectRatio should respect custom tolerance', () {
        expect(AppImages.isSquareAspectRatio(1.15, tolerance: 0.2), isTrue);
        expect(AppImages.isSquareAspectRatio(1.15, tolerance: 0.1), isFalse);
      });

      test('isWidescreenAspectRatio should detect widescreen ratios', () {
        expect(AppImages.isWidescreenAspectRatio(AppImages.aspectRatioWidescreen), isTrue);
        expect(AppImages.isWidescreenAspectRatio(2.0), isTrue);
        expect(AppImages.isWidescreenAspectRatio(1.6), isTrue);
        expect(AppImages.isWidescreenAspectRatio(1.0), isFalse);
        expect(AppImages.isWidescreenAspectRatio(0.8), isFalse);
      });

      test('getBorderRadiusForSize should return appropriate radius', () {
        expect(AppImages.getBorderRadiusForSize(AppImages.sizeXS), equals(AppImages.smallRadius));
        expect(AppImages.getBorderRadiusForSize(AppImages.sizeSmall), equals(AppImages.smallRadius));
        expect(AppImages.getBorderRadiusForSize(AppImages.sizeMedium), equals(AppImages.mediumRadius));
        expect(AppImages.getBorderRadiusForSize(AppImages.sizeLarge), equals(AppImages.largeRadius));
        expect(AppImages.getBorderRadiusForSize(AppImages.sizeXLarge), equals(AppImages.xLargeRadius));
        expect(AppImages.getBorderRadiusForSize(300.0), equals(AppImages.xLargeRadius));
      });
    });

    group('Visual Consistency', () {
      test('should maintain consistent aspect ratio relationships', () {
        // Square should be 1:1
        expect(AppImages.aspectRatioSquare, equals(1.0));
        
        // Portrait should be less than square
        expect(AppImages.aspectRatioPortrait < AppImages.aspectRatioSquare, isTrue);
        
        // Photo and card should be greater than square but less than widescreen
        expect(AppImages.aspectRatioPhoto > AppImages.aspectRatioSquare, isTrue);
        expect(AppImages.aspectRatioCard > AppImages.aspectRatioSquare, isTrue);
        expect(AppImages.aspectRatioPhoto < AppImages.aspectRatioWidescreen, isTrue);
        expect(AppImages.aspectRatioCard < AppImages.aspectRatioWidescreen, isTrue);
        
        // Widescreen should be the widest
        expect(AppImages.aspectRatioWidescreen > AppImages.aspectRatioPhoto, isTrue);
        expect(AppImages.aspectRatioWidescreen > AppImages.aspectRatioCard, isTrue);
      });

      test('should have progressive border radius scaling', () {
        final radii = [
          AppImages.radiusSmall,
          AppImages.radiusMedium,
          AppImages.radiusLarge,
          AppImages.radiusXLarge,
        ];

        for (int i = 0; i < radii.length - 1; i++) {
          expect(radii[i] < radii[i + 1], isTrue, 
            reason: 'Border radii should progress from smallest to largest');
        }
      });

      test('should use consistent color scheme', () {
        // Placeholder colors should be neutral
        expect(AppImages.placeholderBackground, equals(AppColors.lightGray));
        expect(AppImages.placeholderIcon, equals(AppColors.mediumGray));
        
        // Loading colors should be distinct from placeholders
        expect(AppImages.loadingBackground, isNot(equals(AppImages.placeholderBackground)));
        expect(AppImages.loadingIndicatorColor, equals(AppColors.accentBlue));
      });
    });

    group('Accessibility Compliance', () {
      testWidgets('all image utilities should support semantic labels', (tester) async {
        // Test that semantic labels are properly passed through
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    AppImages.placeholder(semanticLabel: 'Test placeholder'),
                    AppImages.avatarPlaceholder(semanticLabel: 'Test avatar'),
                    AppImages.photoPlaceholder(semanticLabel: 'Test photo'),
                    AppImages.videoPlaceholder(semanticLabel: 'Test video'),
                    AppImages.loadingIndicator(semanticLabel: 'Test loading'),
                    AppImages.errorState(semanticLabel: 'Test error'),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify semantic labels are present
        expect(find.bySemanticsLabel('Test placeholder'), findsOneWidget);
        expect(find.bySemanticsLabel('Test avatar'), findsOneWidget);
        expect(find.bySemanticsLabel('Test photo'), findsOneWidget);
        expect(find.bySemanticsLabel('Test video'), findsOneWidget);
        expect(find.bySemanticsLabel('Test loading'), findsOneWidget);
        expect(find.bySemanticsLabel('Test error'), findsOneWidget);
      });

      testWidgets('video thumbnail should have accessible play button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppImages.videoThumbnailContainer(
                child: const Text('Video'),
              ),
            ),
          ),
        );

        final playIconFinder = find.byIcon(Icons.play_arrow);
        expect(playIconFinder, findsOneWidget);

        final Icon playIcon = tester.widget(playIconFinder);
        expect(playIcon.semanticLabel, equals('Play video'));
        expect(playIcon.semanticLabel!.isNotEmpty, isTrue);
      });

      test('should provide meaningful default semantic labels', () {
        // Default semantic labels should be descriptive
        const placeholderLabel = 'Image placeholder';
        const avatarLabel = 'Profile picture placeholder';
        const photoLabel = 'Photo placeholder';
        const videoLabel = 'Video placeholder';
        const loadingLabel = 'Loading image';
        const errorLabel = 'Failed to load image';

        expect(placeholderLabel.isNotEmpty, isTrue);
        expect(avatarLabel.isNotEmpty, isTrue);
        expect(photoLabel.isNotEmpty, isTrue);
        expect(videoLabel.isNotEmpty, isTrue);
        expect(loadingLabel.isNotEmpty, isTrue);
        expect(errorLabel.isNotEmpty, isTrue);
      });
    });
  });
}