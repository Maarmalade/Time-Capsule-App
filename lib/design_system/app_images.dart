import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// AppImages provides consistent image and media styling utilities
/// for the Time Capsule application, including border radius, aspect ratios,
/// placeholder states, and loading indicators.
/// 
/// This class ensures visual consistency across all image and media components
/// while maintaining accessibility and responsive design principles.
class AppImages {
  AppImages._();

  // Border Radius Constants
  /// Small border radius for compact image elements
  static const double radiusSmall = 8.0;
  
  /// Medium border radius for standard image cards
  static const double radiusMedium = 12.0;
  
  /// Large border radius for prominent image displays
  static const double radiusLarge = 16.0;
  
  /// Extra large border radius for hero images
  static const double radiusXLarge = 24.0;
  
  /// Circular border radius for profile pictures and avatars
  static const double radiusCircular = 50.0;

  // Aspect Ratio Constants
  /// Square aspect ratio (1:1) for profile pictures and thumbnails
  static const double aspectRatioSquare = 1.0;
  
  /// Standard photo aspect ratio (4:3) for memory photos
  static const double aspectRatioPhoto = 4.0 / 3.0;
  
  /// Widescreen aspect ratio (16:9) for videos and landscape images
  static const double aspectRatioWidescreen = 16.0 / 9.0;
  
  /// Portrait aspect ratio (3:4) for portrait photos
  static const double aspectRatioPortrait = 3.0 / 4.0;
  
  /// Card aspect ratio (5:4) for memory cards
  static const double aspectRatioCard = 5.0 / 4.0;

  // Image Sizes
  /// Extra small image size for icons and tiny thumbnails
  static const double sizeXS = 32.0;
  
  /// Small image size for list item thumbnails
  static const double sizeSmall = 48.0;
  
  /// Medium image size for standard thumbnails
  static const double sizeMedium = 80.0;
  
  /// Large image size for prominent displays
  static const double sizeLarge = 120.0;
  
  /// Extra large image size for hero elements
  static const double sizeXLarge = 200.0;

  // Placeholder and Loading Colors
  /// Background color for image placeholders
  static const Color placeholderBackground = AppColors.lightGray;
  
  /// Icon color for placeholder content
  static const Color placeholderIcon = AppColors.mediumGray;
  
  /// Background color for loading states
  static const Color loadingBackground = AppColors.softGray;
  
  /// Color for loading indicators
  static const Color loadingIndicatorColor = AppColors.accentBlue;

  // Border Radius Utilities
  /// Creates small border radius for compact images
  static BorderRadius get smallRadius => BorderRadius.circular(radiusSmall);
  
  /// Creates medium border radius for standard images
  static BorderRadius get mediumRadius => BorderRadius.circular(radiusMedium);
  
  /// Creates large border radius for prominent images
  static BorderRadius get largeRadius => BorderRadius.circular(radiusLarge);
  
  /// Creates extra large border radius for hero images
  static BorderRadius get xLargeRadius => BorderRadius.circular(radiusXLarge);
  
  /// Creates circular border radius for profile pictures
  static BorderRadius get circularRadius => BorderRadius.circular(radiusCircular);

  // Image Container Utilities
  /// Creates a standard image container with consistent styling
  /// 
  /// [child] The image widget to display
  /// [width] Optional width constraint
  /// [height] Optional height constraint
  /// [borderRadius] Optional custom border radius, defaults to medium
  /// [aspectRatio] Optional aspect ratio constraint
  static Widget imageContainer({
    required Widget child,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    double? aspectRatio,
  }) {
    Widget container = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? mediumRadius,
        color: placeholderBackground,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (aspectRatio != null) {
      container = AspectRatio(
        aspectRatio: aspectRatio,
        child: container,
      );
    }

    return container;
  }

  /// Creates a square image container for profile pictures and thumbnails
  /// 
  /// [child] The image widget to display
  /// [size] The size of the square container
  /// [borderRadius] Optional custom border radius, defaults to medium
  static Widget squareImageContainer({
    required Widget child,
    double size = sizeMedium,
    BorderRadius? borderRadius,
  }) {
    return imageContainer(
      child: child,
      width: size,
      height: size,
      borderRadius: borderRadius ?? mediumRadius,
      aspectRatio: aspectRatioSquare,
    );
  }

  /// Creates a circular image container for profile pictures
  /// 
  /// [child] The image widget to display
  /// [size] The diameter of the circular container
  static Widget circularImageContainer({
    required Widget child,
    double size = sizeMedium,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: placeholderBackground,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// Creates a memory card image container with standard aspect ratio
  /// 
  /// [child] The image widget to display
  /// [width] Optional width constraint
  /// [aspectRatio] Optional aspect ratio, defaults to card ratio
  static Widget memoryCardContainer({
    required Widget child,
    double? width,
    double? aspectRatio,
  }) {
    return imageContainer(
      child: child,
      width: width,
      borderRadius: mediumRadius,
      aspectRatio: aspectRatio ?? aspectRatioCard,
    );
  }

  /// Creates a video thumbnail container with widescreen aspect ratio
  /// 
  /// [child] The image widget to display
  /// [width] Optional width constraint
  /// [showPlayButton] Whether to show a play button overlay
  static Widget videoThumbnailContainer({
    required Widget child,
    double? width,
    bool showPlayButton = true,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        imageContainer(
          child: child,
          width: width,
          borderRadius: mediumRadius,
          aspectRatio: aspectRatioWidescreen,
        ),
        if (showPlayButton)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32.0,
              semanticLabel: 'Play video',
            ),
          ),
      ],
    );
  }

  // Placeholder Utilities
  /// Creates a standard image placeholder with icon
  /// 
  /// [icon] The icon to display in the placeholder
  /// [size] The size of the placeholder
  /// [aspectRatio] Optional aspect ratio constraint
  /// [semanticLabel] Accessibility label for the placeholder
  static Widget placeholder({
    IconData icon = Icons.image,
    double? size,
    double? aspectRatio,
    String semanticLabel = 'Image placeholder',
  }) {
    Widget placeholderWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: placeholderBackground,
        borderRadius: mediumRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          color: placeholderIcon,
          size: (size != null) ? size * 0.4 : 32.0,
          semanticLabel: semanticLabel,
        ),
      ),
    );

    if (aspectRatio != null) {
      placeholderWidget = AspectRatio(
        aspectRatio: aspectRatio,
        child: placeholderWidget,
      );
    }

    return placeholderWidget;
  }

  /// Creates a circular avatar placeholder
  /// 
  /// [size] The diameter of the circular placeholder
  /// [semanticLabel] Accessibility label for the placeholder
  static Widget avatarPlaceholder({
    double size = sizeMedium,
    String semanticLabel = 'Profile picture placeholder',
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: placeholderBackground,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: placeholderIcon,
          size: size * 0.5,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }

  /// Creates a photo placeholder for memory cards
  /// 
  /// [aspectRatio] Optional aspect ratio, defaults to card ratio
  /// [semanticLabel] Accessibility label for the placeholder
  static Widget photoPlaceholder({
    double? aspectRatio,
    String semanticLabel = 'Photo placeholder',
  }) {
    return placeholder(
      icon: Icons.photo,
      aspectRatio: aspectRatio ?? aspectRatioCard,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates a video placeholder for video content
  /// 
  /// [aspectRatio] Optional aspect ratio, defaults to widescreen
  /// [semanticLabel] Accessibility label for the placeholder
  static Widget videoPlaceholder({
    double? aspectRatio,
    String semanticLabel = 'Video placeholder',
  }) {
    return placeholder(
      icon: Icons.videocam,
      aspectRatio: aspectRatio ?? aspectRatioWidescreen,
      semanticLabel: semanticLabel,
    );
  }

  // Loading State Utilities
  /// Creates a loading indicator for image loading states
  /// 
  /// [size] The size of the loading container
  /// [aspectRatio] Optional aspect ratio constraint
  /// [semanticLabel] Accessibility label for the loading state
  static Widget loadingIndicator({
    double? size,
    double? aspectRatio,
    String semanticLabel = 'Loading image',
  }) {
    Widget loadingWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: loadingBackground,
        borderRadius: mediumRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 24.0,
          height: 24.0,
          child: Semantics(
            label: semanticLabel,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: const AlwaysStoppedAnimation<Color>(loadingIndicatorColor),
            ),
          ),
        ),
      ),
    );

    if (aspectRatio != null) {
      loadingWidget = AspectRatio(
        aspectRatio: aspectRatio,
        child: loadingWidget,
      );
    }

    return loadingWidget;
  }

  /// Creates a skeleton loading animation for image content
  /// 
  /// [width] The width of the skeleton
  /// [height] The height of the skeleton
  /// [borderRadius] Optional border radius, defaults to medium
  static Widget skeletonLoader({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: loadingBackground,
        borderRadius: borderRadius ?? mediumRadius,
      ),
      child: const _ShimmerEffect(),
    );
  }

  /// Creates a circular skeleton loader for avatar loading states
  /// 
  /// [size] The diameter of the circular skeleton
  static Widget circularSkeletonLoader({
    double size = sizeMedium,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: loadingBackground,
        shape: BoxShape.circle,
      ),
      child: const _ShimmerEffect(),
    );
  }

  // Error State Utilities
  /// Creates an error state display for failed image loads
  /// 
  /// [size] The size of the error container
  /// [aspectRatio] Optional aspect ratio constraint
  /// [onRetry] Optional callback for retry functionality
  /// [semanticLabel] Accessibility label for the error state
  static Widget errorState({
    double? size,
    double? aspectRatio,
    VoidCallback? onRetry,
    String semanticLabel = 'Failed to load image',
  }) {
    Widget errorWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: placeholderBackground,
        borderRadius: mediumRadius,
        border: Border.all(
          color: AppColors.errorRed.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.errorRed,
            size: (size != null) ? size * 0.3 : 24.0,
            semanticLabel: semanticLabel,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 12.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (aspectRatio != null) {
      errorWidget = AspectRatio(
        aspectRatio: aspectRatio,
        child: errorWidget,
      );
    }

    return errorWidget;
  }

  // Utility Methods
  /// Determines the appropriate aspect ratio based on image dimensions
  /// 
  /// [width] The image width
  /// [height] The image height
  /// Returns the calculated aspect ratio or a default if dimensions are invalid
  static double calculateAspectRatio(double width, double height) {
    if (width <= 0 || height <= 0) {
      return aspectRatioSquare;
    }
    return width / height;
  }

  /// Determines if an aspect ratio is considered square (within tolerance)
  /// 
  /// [aspectRatio] The aspect ratio to check
  /// [tolerance] The tolerance for considering it square (default 0.1)
  static bool isSquareAspectRatio(double aspectRatio, {double tolerance = 0.1}) {
    return (aspectRatio - aspectRatioSquare).abs() <= tolerance;
  }

  /// Determines if an aspect ratio is considered widescreen
  /// 
  /// [aspectRatio] The aspect ratio to check
  static bool isWidescreenAspectRatio(double aspectRatio) {
    return aspectRatio >= aspectRatioWidescreen * 0.9;
  }

  /// Gets the appropriate border radius based on image size
  /// 
  /// [size] The image size
  /// Returns the recommended border radius for the given size
  static BorderRadius getBorderRadiusForSize(double size) {
    if (size <= sizeSmall) {
      return smallRadius;
    } else if (size <= sizeMedium) {
      return mediumRadius;
    } else if (size <= sizeLarge) {
      return largeRadius;
    } else {
      return xLargeRadius;
    }
  }
}

/// Internal shimmer effect widget for skeleton loading animations
class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.lightGray,
                AppColors.primaryWhite,
                AppColors.lightGray,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}