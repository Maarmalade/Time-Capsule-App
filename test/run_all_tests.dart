import 'dart:io';

/// Comprehensive test runner for the Time Capsule app
/// 
/// This script runs all tests in the correct order:
/// 1. Unit tests (models, services, utilities)
/// 2. Widget tests (UI components)
/// 3. Integration tests (complete user flows)
void main() async {
  print('🧪 Starting comprehensive test suite for Time Capsule app...\n');

  // Track test results
  var totalTests = 0;
  var passedTests = 0;
  var failedTests = 0;
  final List<String> failedTestFiles = [];

  // Helper function to run tests and track results
  Future<void> runTestFile(String testFile, String category) async {
    print('📋 Running $category: $testFile');
    
    try {
      final result = await Process.run(
        'flutter',
        ['test', testFile],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        print('✅ PASSED: $testFile\n');
        passedTests++;
      } else {
        print('❌ FAILED: $testFile');
        print('Error output: ${result.stderr}');
        print('Standard output: ${result.stdout}\n');
        failedTests++;
        failedTestFiles.add(testFile);
      }
      totalTests++;
    } catch (e) {
      print('❌ ERROR running $testFile: $e\n');
      failedTests++;
      totalTests++;
      failedTestFiles.add(testFile);
    }
  }

  // 1. Unit Tests - Models
  print('🏗️  UNIT TESTS - MODELS');
  print('=' * 50);
  await runTestFile('test/models/user_profile_test.dart', 'Model Tests');

  // 2. Unit Tests - Services
  print('🔧 UNIT TESTS - SERVICES');
  print('=' * 50);
  await runTestFile('test/services/user_profile_service_test.dart', 'Service Tests');
  await runTestFile('test/services/folder_service_test.dart', 'Service Tests');
  await runTestFile('test/services/media_service_test.dart', 'Service Tests');

  // 3. Unit Tests - Utilities
  print('🛠️  UNIT TESTS - UTILITIES');
  print('=' * 50);
  await runTestFile('test/utils/validation_utils_test.dart', 'Utility Tests');
  await runTestFile('test/utils/error_handler_test.dart', 'Utility Tests');

  // 4. Widget Tests
  print('🎨 WIDGET TESTS');
  print('=' * 50);
  await runTestFile('test/widgets/confirmation_dialog_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/edit_name_dialog_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/batch_action_bar_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/multi_select_manager_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/profile_picture_widget_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/username_setup_page_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/profile_page_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/edit_username_page_test.dart', 'Widget Tests');
  await runTestFile('test/widgets/change_password_page_test.dart', 'Widget Tests');

  // 5. Integration Tests
  print('🔄 INTEGRATION TESTS');
  print('=' * 50);
  await runTestFile('test/integration/user_profile_integration_test.dart', 'Integration Tests');
  await runTestFile('test/integration/file_management_integration_test.dart', 'Integration Tests');
  await runTestFile('test/integration/profile_picture_integration_test.dart', 'Integration Tests');

  // Print final results
  print('=' * 60);
  print('📊 TEST RESULTS SUMMARY');
  print('=' * 60);
  print('Total tests run: $totalTests');
  print('✅ Passed: $passedTests');
  print('❌ Failed: $failedTests');
  print('Success rate: ${totalTests > 0 ? ((passedTests / totalTests) * 100).toStringAsFixed(1) : 0}%');

  if (failedTests > 0) {
    print('\n❌ Failed test files:');
    for (final file in failedTestFiles) {
      print('  - $file');
    }
    print('\n💡 To run a specific failed test:');
    print('   flutter test <test_file_path>');
    print('\n💡 To run tests with verbose output:');
    print('   flutter test --verbose');
    print('\n💡 To generate test coverage:');
    print('   flutter test --coverage');
  } else {
    print('\n🎉 All tests passed! Great job!');
  }

  print('\n📝 Additional test commands:');
  print('  Generate mocks: flutter packages pub run build_runner build');
  print('  Run with coverage: flutter test --coverage');
  print('  Run specific test: flutter test test/path/to/test_file.dart');
  print('  Run integration tests: flutter test integration_test/');

  // Exit with appropriate code
  exit(failedTests > 0 ? 1 : 0);
}