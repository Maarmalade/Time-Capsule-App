# Time Capsule App - Test Suite

This directory contains comprehensive tests for the Time Capsule app, covering all new functionality related to user profile management and enhanced file management.

## Test Structure

```
test/
├── models/                     # Model unit tests
│   └── user_profile_test.dart
├── services/                   # Service unit tests
│   ├── user_profile_service_test.dart
│   ├── folder_service_test.dart
│   └── media_service_test.dart
├── utils/                      # Utility unit tests
│   ├── validation_utils_test.dart
│   └── error_handler_test.dart
├── widgets/                    # Widget tests
│   ├── confirmation_dialog_test.dart
│   ├── edit_name_dialog_test.dart
│   ├── batch_action_bar_test.dart
│   ├── multi_select_manager_test.dart
│   ├── profile_picture_widget_test.dart
│   ├── username_setup_page_test.dart
│   ├── profile_page_test.dart
│   ├── edit_username_page_test.dart
│   └── change_password_page_test.dart
├── integration/                # Integration tests
│   ├── user_profile_integration_test.dart
│   ├── file_management_integration_test.dart
│   └── profile_picture_integration_test.dart
├── run_all_tests.dart         # Test runner script
└── README.md                  # This file
```

## Test Categories

### 1. Unit Tests

#### Models (`test/models/`)
- **UserProfile Model**: Tests data model serialization, deserialization, equality, and edge cases

#### Services (`test/services/`)
- **UserProfileService**: Tests user profile CRUD operations, username validation, password updates, profile picture management
- **FolderService**: Tests folder creation, deletion, batch operations, name updates, and validation
- **MediaService**: Tests media file operations, batch deletion, name updates, and storage cleanup

#### Utilities (`test/utils/`)
- **ValidationUtils**: Tests input validation for usernames, passwords, emails, file names, and file uploads
- **ErrorHandler**: Tests error message formatting and user-friendly error display

### 2. Widget Tests (`test/widgets/`)

#### Dialog Components
- **ConfirmationDialog**: Tests dialog display, user interactions, and return values
- **EditNameDialog**: Tests name editing functionality and validation

#### File Management Components
- **BatchActionBar**: Tests multi-select UI, action buttons, and state management
- **MultiSelectManager**: Tests selection state, visual indicators, and batch operations

#### Profile Components
- **ProfilePictureWidget**: Tests image display, default avatars, and upload triggers
- **UsernameSetupPage**: Tests username creation flow, validation, and availability checking
- **ProfilePage**: Tests profile display, navigation, and error handling
- **EditUsernamePage**: Tests username editing, validation, and availability checking
- **ChangePasswordPage**: Tests password change flow, validation, and security

### 3. Integration Tests (`test/integration/`)

#### Complete User Flows
- **User Profile Integration**: Tests complete registration → username setup → profile management flows
- **File Management Integration**: Tests folder/file creation, editing, multi-select, and batch operations
- **Profile Picture Integration**: Tests image upload, compression, storage, and display throughout the app

## Running Tests

### Prerequisites

1. Install test dependencies:
```bash
flutter pub get
```

2. Generate mocks (if needed):
```bash
flutter packages pub run build_runner build
```

### Running All Tests

Use the comprehensive test runner:
```bash
dart test/run_all_tests.dart
```

### Running Specific Test Categories

**Unit Tests Only:**
```bash
flutter test test/models/ test/services/ test/utils/
```

**Widget Tests Only:**
```bash
flutter test test/widgets/
```

**Integration Tests Only:**
```bash
flutter test test/integration/
```

### Running Individual Test Files

```bash
flutter test test/services/user_profile_service_test.dart
flutter test test/widgets/profile_page_test.dart
flutter test test/integration/user_profile_integration_test.dart
```

### Test Coverage

Generate test coverage report:
```bash
flutter test --coverage
```

View coverage in browser:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Configuration

### Mock Dependencies

Tests use Mockito for mocking Firebase services and dependencies:
- `FirebaseAuth`
- `FirebaseFirestore`
- `FirebaseStorage`
- `UserProfileService`
- `FolderService`
- `MediaService`

### Test Data

Tests use consistent test data:
- Test User ID: `test-user-id`
- Test Email: `test@example.com`
- Test Username: `testuser`
- Test Dates: Consistent DateTime objects for reproducible tests

## Test Coverage Goals

### Current Coverage Areas

✅ **User Profile Management**
- Username creation and validation
- Profile picture upload and management
- Password change functionality
- Profile data CRUD operations

✅ **Enhanced File Management**
- Folder creation, editing, and deletion
- Media file management and batch operations
- Multi-select functionality
- Options menus and confirmation dialogs

✅ **Input Validation**
- Username format and availability
- Password strength and confirmation
- File name validation and sanitization
- Batch operation limits

✅ **Error Handling**
- Network error scenarios
- Validation error display
- Firebase service errors
- User-friendly error messages

✅ **Security**
- Input sanitization
- Authentication requirements
- Authorization checks
- Data validation

### Coverage Targets

- **Unit Tests**: 90%+ coverage for services and utilities
- **Widget Tests**: 85%+ coverage for UI components
- **Integration Tests**: Cover all major user flows
- **Edge Cases**: Handle null values, empty inputs, and error conditions

## Best Practices

### Test Organization
- Group related tests using `group()` descriptors
- Use descriptive test names that explain the scenario
- Follow AAA pattern: Arrange, Act, Assert

### Mock Usage
- Mock external dependencies (Firebase services)
- Use consistent mock data across tests
- Verify mock interactions where appropriate

### Widget Testing
- Test user interactions and state changes
- Verify UI elements are displayed correctly
- Test navigation and form submissions

### Integration Testing
- Test complete user workflows
- Verify data persistence and retrieval
- Test error scenarios and recovery

## Troubleshooting

### Common Issues

**Mock Generation Errors:**
```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Test Timeout Issues:**
- Increase timeout for async operations
- Use `pumpAndSettle()` for widget tests
- Mock long-running operations

**Firebase Emulator Setup:**
- Use Firebase emulators for integration tests
- Configure test environment variables
- Reset emulator state between tests

### Debug Tips

**Verbose Test Output:**
```bash
flutter test --verbose
```

**Single Test Debugging:**
```bash
flutter test test/path/to/test.dart --plain-name "specific test name"
```

**Widget Inspector:**
```dart
await tester.pumpWidget(widget);
debugDumpApp(); // Prints widget tree
```

## Contributing

When adding new features:

1. **Write tests first** (TDD approach)
2. **Cover happy path and edge cases**
3. **Mock external dependencies**
4. **Update this README** if adding new test categories
5. **Ensure tests pass** before submitting PR

### Test Checklist

- [ ] Unit tests for new services/utilities
- [ ] Widget tests for new UI components
- [ ] Integration tests for new user flows
- [ ] Error handling and validation tests
- [ ] Mock generation updated
- [ ] Test documentation updated
- [ ] All tests pass locally

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Firebase Testing](https://firebase.google.com/docs/emulator-suite)