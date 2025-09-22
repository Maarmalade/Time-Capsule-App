# Error Handling and Validation Utils

This directory contains comprehensive error handling and validation utilities for the Time Capsule app.

## Files Overview

### `error_handler.dart`
Centralized error handling utility that provides:
- **Firebase Error Translation**: Converts Firebase-specific errors to user-friendly messages
- **Consistent UI Feedback**: Standardized error and success notifications
- **Error Dialog Support**: Critical error display functionality

#### Key Features:
- Handles `FirebaseAuthException`, `FirebaseException`, and generic exceptions
- Provides `showErrorSnackBar()` and `showSuccessSnackBar()` for consistent UI feedback
- Includes `showErrorDialog()` for critical errors
- Maps Firebase error codes to user-friendly messages

#### Usage Example:
```dart
try {
  await someFirebaseOperation();
  ErrorHandler.showSuccessSnackBar(context, 'Operation completed successfully!');
} catch (e) {
  ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
}
```

### `validation_utils.dart`
Comprehensive validation utilities that provide:
- **Input Validation**: Username, password, email, and file name validation
- **File Upload Validation**: File type, size, and security validation
- **Batch Operation Validation**: Limits and safety checks for bulk operations
- **Text Sanitization**: XSS prevention and safe display utilities

#### Key Features:
- Username validation (3-20 characters, alphanumeric + underscores)
- Password strength validation (minimum 6 characters)
- Email format validation
- File upload validation with type and size limits
- Batch operation limits (max 50 items)
- Text sanitization for XSS prevention
- File size formatting utilities

#### Usage Example:
```dart
// Validate username
final usernameError = ValidationUtils.validateUsername(username);
if (usernameError != null) {
  // Handle validation error
}

// Validate file upload
final fileError = ValidationUtils.validateFileUpload(file, expectedType: 'image');
if (fileError != null) {
  // Handle file validation error
}
```

### `error_display_widget.dart`
Reusable UI components for error display:
- **ErrorDisplayWidget**: General error display with retry functionality
- **ValidationErrorWidget**: Form validation error display
- **LoadingStateWidget**: Loading states with error handling
- **NetworkErrorWidget**: Network-specific error display
- **EmptyStateWidget**: Empty state with optional error context

#### Usage Example:
```dart
// Display validation error
ValidationErrorWidget(error: validationError)

// Display loading state with error handling
LoadingStateWidget(
  isLoading: isLoading,
  error: errorMessage,
  onRetry: () => retryOperation(),
  child: YourContentWidget(),
)
```

## Error Handling Strategy

### 1. Service Layer Error Handling
All services now include comprehensive error handling:
- Input validation before operations
- Firebase exception handling
- Meaningful error messages
- Proper error propagation

### 2. UI Layer Error Handling
UI components provide consistent error feedback:
- Standardized error snackbars
- Loading states with error recovery
- Form validation with inline errors
- Critical error dialogs

### 3. Validation Strategy
Multi-layer validation approach:
- Client-side validation for immediate feedback
- Server-side validation for security
- Sanitization for XSS prevention
- File validation for security and performance

## Security Considerations

### Input Sanitization
- All text inputs are sanitized to prevent XSS attacks
- File uploads are validated for type and size
- Batch operations have limits to prevent abuse

### Error Message Security
- Error messages don't expose sensitive information
- Generic messages for security-related failures
- Proper logging without exposing user data

## Testing

Comprehensive test coverage includes:
- Unit tests for all validation functions
- Error handling scenario tests
- Edge case validation
- Security validation tests

Run tests with:
```bash
flutter test test/utils/
```

## Integration with Existing Code

### Services Enhanced:
- `UserProfileService`: Username, password, and profile picture validation
- `FolderService`: Folder name validation and batch operations
- `MediaService`: File validation and batch operations
- `StorageService`: File upload validation and error handling

### UI Components Enhanced:
- `UsernameSetupPage`: Real-time validation and error display
- `EditUsernamePage`: Comprehensive validation and feedback
- `ChangePasswordPage`: Password strength validation
- `MemoryAlbumPage`: Error handling for folder operations
- `EditNameDialog`: File/folder name validation

## Best Practices

### Error Handling:
1. Always use `ErrorHandler.getErrorMessage()` for consistent error formatting
2. Use appropriate UI feedback methods (`showErrorSnackBar`, `showSuccessSnackBar`)
3. Provide retry functionality where appropriate
4. Handle loading states with error recovery

### Validation:
1. Validate inputs at the UI layer for immediate feedback
2. Re-validate at the service layer for security
3. Sanitize all text inputs before storage
4. Use appropriate validation functions for each input type

### UI Feedback:
1. Use consistent error display components
2. Provide clear, actionable error messages
3. Include retry functionality for recoverable errors
4. Show loading states during operations

## Future Enhancements

Potential improvements:
- Offline error handling
- Error analytics and reporting
- Advanced file validation (virus scanning)
- Internationalization for error messages
- Custom validation rules configuration