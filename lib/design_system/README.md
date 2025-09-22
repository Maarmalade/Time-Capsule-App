# Time Capsule Design System

This directory contains the complete design system for the Time Capsule Flutter application, implementing a clean, professional UI following Material 3 principles.

## Overview

The design system provides a consistent visual language with:
- **Professional Color Palette**: Neutral colors with sophisticated accent
- **Typography System**: Inter/Roboto fonts with clear hierarchy
- **Spacing System**: 8px grid-based spacing and elevation
- **Component Standards**: Consistent styling for all UI elements

## Structure

```
lib/design_system/
├── design_system.dart      # Main export file
├── app_colors.dart         # Color palette and semantic colors
├── app_typography.dart     # Typography styles and text theme
├── app_spacing.dart        # Spacing, padding, margins, and elevation
├── app_buttons.dart        # Button component styles
├── app_inputs.dart         # Input field component styles
├── app_cards.dart          # Card component styles
├── app_bars.dart           # App bar component styles
├── app_navigation.dart     # Navigation component styles
├── app_icons.dart          # Icon system and utilities
├── app_images.dart         # Image styling utilities
├── app_theme.dart          # Complete theme configuration
├── app_error_states.dart   # Error state components
├── app_loading_states.dart # Loading state components
├── design_constants.dart   # Additional utilities and constants
└── README.md              # This documentation
```

## Usage

### Import the Design System

```dart
import 'package:time_capsule/design_system/design_system.dart';
```

### Using Colors

```dart
Container(
  color: AppColors.surfacePrimary,
  child: Text(
    'Hello World',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)
```

### Using Typography

```dart
Text(
  'Page Title',
  style: AppTypography.headlineLarge,
)

Text(
  'Body content with proper spacing and readability.',
  style: AppTypography.bodyMedium,
)
```

### Using Spacing

```dart
Container(
  padding: AppSpacing.paddingMd,
  margin: AppSpacing.marginLg,
  decoration: BoxDecoration(
    borderRadius: AppSpacing.borderRadiusMd,
  ),
)
```

### Using Design Constants

```dart
Container(
  decoration: DesignConstants.cardDecoration,
  child: content,
)
```

### Using Error States

```dart
// Validation error
AppErrorStates.validationError('This field is required')

// Network error with retry
AppErrorStates.networkError(
  title: 'Connection Failed',
  message: 'Please check your internet connection.',
  onRetry: () => retryAction(),
)

// Empty state
AppErrorStates.emptyState(
  title: 'No Items Found',
  message: 'Add your first item to get started.',
  icon: Icons.inbox_outlined,
  onAction: () => addItem(),
  actionLabel: 'Add Item',
)
```

### Using Loading States

```dart
// Circular loader
AppLoadingStates.circularLoader()

// Loading button
AppLoadingStates.loadingButton(
  text: 'Submit',
  isLoading: isSubmitting,
  onPressed: () => submitForm(),
)

// Skeleton loading
AppLoadingStates.skeletonCard(
  includeImage: true,
  includeTitle: true,
  includeSubtitle: true,
)

// Page loader
AppLoadingStates.pageLoader(
  message: 'Loading your data...',
)
```

## Color System

### Base Colors
- **Primary White** (`#FFFFFF`): Main background color
- **Soft Gray** (`#F5F5F7`): Secondary background color
- **Charcoal Navy** (`#1A1A2E`): Primary text color

### Accent Color
- **Accent Blue** (`#2E5BFF`): Used sparingly for CTAs and highlights

### Semantic Colors
- **Success Green** (`#28A745`): Success states
- **Warning Amber** (`#FFC107`): Warning states
- **Error Red** (`#DC3545`): Error states
- **Info Blue** (`#17A2B8`): Information states

## Typography System

### Font Configuration
- **Primary Font**: Inter (via Google Fonts)
- **Fallback Font**: Roboto (via Google Fonts)
- **Font Weights**: Light (300), Regular (400), Medium (500), SemiBold (600)

### Text Styles
- **Display**: Large prominent text (32px, 28px, 24px)
- **Headline**: Section headers (24px, 20px, 18px)
- **Title**: Component headers (18px, 16px, 14px)
- **Body**: Main content (16px, 14px, 12px)
- **Label**: Buttons and captions (14px, 12px, 10px)

## Spacing System

### Grid System
Based on 8px grid units:
- **xs**: 4px (0.5 units)
- **sm**: 8px (1 unit)
- **md**: 16px (2 units)
- **lg**: 24px (3 units)
- **xl**: 32px (4 units)
- **xxl**: 48px (6 units)

### Border Radius
- **xs**: 4px - Small elements
- **sm**: 8px - Buttons, inputs
- **md**: 12px - Cards, containers
- **lg**: 16px - Large containers
- **xl**: 24px - Prominent elements

### Elevation
Material 3 elevation levels:
- **Level 0**: 0dp - Flat surfaces
- **Level 1**: 1dp - Subtle lift
- **Level 2**: 3dp - Cards, buttons
- **Level 3**: 6dp - Floating elements
- **Level 4**: 8dp - Navigation
- **Level 5**: 12dp - Modals

## Best Practices

### Consistency
- Always use design system tokens instead of hardcoded values
- Maintain consistent spacing using the 8px grid system
- Use semantic color names rather than specific color values

### Accessibility
- Ensure proper color contrast ratios (WCAG AA compliance)
- Use appropriate touch target sizes (minimum 44px)
- Maintain clear visual hierarchy with typography

### Performance
- Google Fonts are loaded efficiently with fallbacks
- Design tokens are compile-time constants for optimal performance
- Responsive utilities help adapt to different screen sizes

### Responsive Design
- Use responsive spacing utilities for different screen sizes
- Adapt layouts using provided breakpoint helpers
- Maintain consistent visual hierarchy across devices

## Examples

### Card Component
```dart
Container(
  padding: AppSpacing.cardPadding,
  decoration: DesignConstants.cardDecoration,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Card Title',
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(height: AppSpacing.gapSm),
      Text(
        'Card content with proper spacing and typography.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ],
  ),
)
```

### Button Component
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.accentBlue,
    foregroundColor: AppColors.textOnAccent,
    padding: AppSpacing.buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.buttonRadius,
    ),
    elevation: AppSpacing.elevation2,
  ),
  onPressed: onPressed,
  child: Text(
    'Button Text',
    style: AppTypography.buttonText,
  ),
)
```

## Migration Guide

When updating existing components to use the design system:

1. Replace hardcoded colors with `AppColors` constants
2. Replace hardcoded text styles with `AppTypography` styles
3. Replace hardcoded spacing with `AppSpacing` constants
4. Use `DesignConstants` for common decorations and utilities
5. Test accessibility and responsive behavior

## Contributing

When adding new design tokens:

1. Follow the existing naming conventions
2. Ensure consistency with Material 3 principles
3. Add appropriate documentation and examples
4. Test across different screen sizes and accessibility settings
5. Update this README with new additions