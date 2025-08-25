import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/utils/accessibility_utils.dart';
import 'package:time_capsule/utils/contrast_checker.dart';

/// Utility class for accessibility testing
class AccessibilityTestUtils {
  /// Verify that all interactive elements meet minimum touch target size
  static void verifyTouchTargets(WidgetTester tester) {
    final interactiveTypes = [
      ElevatedButton,
      TextButton,
      OutlinedButton,
      IconButton,
      FloatingActionButton,
      InkWell,
      GestureDetector,
      ListTile,
    ];

    for (final type in interactiveTypes) {
      final elements = find.byType(type);
      for (int i = 0; i < elements.evaluate().length; i++) {
        final size = tester.getSize(elements.at(i));
        expect(
          AccessibilityUtils.validateTouchTargetSize(size),
          isTrue,
          reason: '$type at index $i does not meet minimum touch target size (44x44dp). '
                  'Current size: ${size.width}x${size.height}',
        );
      }
    }
  }

  /// Verify that all interactive elements have semantic labels
  static void verifySemanticLabels(WidgetTester tester) {
    final interactiveElements = _findInteractiveElements(tester);
    
    for (int i = 0; i < interactiveElements.length; i++) {
      final element = interactiveElements[i];
      final semantics = tester.getSemantics(element);
      
      if (semantics.hasAction(SemanticsAction.tap) || 
          semantics.hasFlag(SemanticsFlag.isButton)) {
        expect(
          semantics.label,
          isNotNull,
          reason: 'Interactive element at index $i should have a semantic label',
        );
        expect(
          semantics.label.trim(),
          isNotEmpty,
          reason: 'Interactive element at index $i has empty semantic label',
        );
      }
    }
  }

  /// Verify that all text fields have proper labels and hints
  static void verifyTextFieldAccessibility(WidgetTester tester) {
    final textFields = find.byType(TextFormField);
    
    for (int i = 0; i < textFields.evaluate().length; i++) {
      final textField = textFields.at(i);
      final semantics = tester.getSemantics(textField);
      
      expect(
        semantics.hasFlag(SemanticsFlag.isTextField),
        isTrue,
        reason: 'TextFormField at index $i should be marked as text field',
      );
      
      expect(
        semantics.label,
        isNotNull,
        reason: 'TextFormField at index $i should have a label',
      );
      
      // Check for password fields
      final widget = tester.widget<TextFormField>(textField);
      if (widget.obscureText) {
        expect(
          semantics.hasFlag(SemanticsFlag.isObscured),
          isTrue,
          reason: 'Password field at index $i should be marked as obscured',
        );
      }
    }
  }

  /// Verify that images have appropriate accessibility treatment
  static void verifyImageAccessibility(WidgetTester tester) {
    final images = find.byType(Image);
    
    for (int i = 0; i < images.evaluate().length; i++) {
      final image = images.at(i);
      final semantics = tester.getSemantics(image);
      
      // Images should either have semantic labels or be excluded from semantics
      expect(
        semantics.label!.trim(),
        isNotEmpty,
        reason: 'Image at index $i has empty semantic label',
      );
          // If no label, it should be decorative and excluded from semantics tree
    }
  }

  /// Verify proper heading structure
  static void verifyHeadingStructure(WidgetTester tester) {
    final headings = find.byWidgetPredicate((widget) {
      if (widget is Text) {
        final style = widget.style;
        return style?.fontSize != null && style!.fontSize! >= 18;
      }
      return false;
    });

    for (int i = 0; i < headings.evaluate().length; i++) {
      final heading = headings.at(i);
      final semantics = tester.getSemantics(heading);
      
      expect(
        semantics.label,
        isNotNull,
        reason: 'Heading at index $i should have semantic label',
      );
      
      // Check if it's marked as header (optional but recommended)
      if (semantics.hasFlag(SemanticsFlag.isHeader)) {
        expect(
          semantics.label.trim(),
          isNotEmpty,
          reason: 'Header at index $i should have non-empty label',
        );
      }
    }
  }

  /// Verify navigation accessibility
  static void verifyNavigationAccessibility(WidgetTester tester) {
    // Check bottom navigation
    final bottomNav = find.byType(BottomNavigationBar);
    if (bottomNav.evaluate().isNotEmpty) {
      final navSemantics = tester.getSemantics(bottomNav);
      expect(
        navSemantics.label,
        isNotNull,
        reason: 'Bottom navigation should have semantic label',
      );
    }

    // Check app bar
    final appBar = find.byType(AppBar);
    if (appBar.evaluate().isNotEmpty) {
      final appBarSemantics = tester.getSemantics(appBar);
      expect(
        appBarSemantics.hasFlag(SemanticsFlag.isHeader),
        isTrue,
        reason: 'App bar should be marked as header',
      );
    }

    // Check tab bar
    final tabBar = find.byType(TabBar);
    if (tabBar.evaluate().isNotEmpty) {
      final tabSemantics = tester.getSemantics(tabBar);
      expect(
        tabSemantics.label,
        isNotNull,
        reason: 'Tab bar should have semantic label',
      );
    }
  }

  /// Verify loading states accessibility
  static void verifyLoadingStatesAccessibility(WidgetTester tester) {
    final loadingIndicators = find.byType(CircularProgressIndicator);
    
    for (int i = 0; i < loadingIndicators.evaluate().length; i++) {
      final indicator = loadingIndicators.at(i);
      final semantics = tester.getSemantics(indicator);
      
      // Loading indicators should have labels or be excluded from semantics
      expect(
        semantics.label!.toLowerCase(),
        anyOf(
          contains('loading'),
          contains('progress'),
          contains('wait'),
        ),
        reason: 'Loading indicator at index $i should have appropriate label',
      );
        }
  }

  /// Run comprehensive accessibility audit on current screen
  static void runAccessibilityAudit(WidgetTester tester) {
    verifyTouchTargets(tester);
    verifySemanticLabels(tester);
    verifyTextFieldAccessibility(tester);
    verifyImageAccessibility(tester);
    verifyHeadingStructure(tester);
    verifyNavigationAccessibility(tester);
    verifyLoadingStatesAccessibility(tester);
  }

  /// Verify contrast compliance for the design system
  static void verifyContrastCompliance() {
    final results = ContrastChecker.validateDesignSystemContrast();
    final failingCombinations = results.values
        .where((result) => !result.meetsWCAGAA)
        .toList();
    
    expect(
      failingCombinations,
      isEmpty,
      reason: 'The following color combinations fail WCAG AA compliance: '
              '${failingCombinations.map((r) => r.description).join(', ')}',
    );
  }

  /// Generate accessibility report for current screen
  static String generateAccessibilityReport(WidgetTester tester) {
    final buffer = StringBuffer();
    buffer.writeln('=== Accessibility Report ===\n');
    
    // Count interactive elements
    final interactiveElements = _findInteractiveElements(tester);
    buffer.writeln('Interactive elements found: ${interactiveElements.length}');
    
    // Count text fields
    final textFields = find.byType(TextFormField).evaluate().length;
    buffer.writeln('Text fields found: $textFields');
    
    // Count images
    final images = find.byType(Image).evaluate().length;
    buffer.writeln('Images found: $images');
    
    // Count headings
    final headings = find.byWidgetPredicate((widget) {
      if (widget is Text) {
        final style = widget.style;
        return style?.fontSize != null && style!.fontSize! >= 18;
      }
      return false;
    }).evaluate().length;
    buffer.writeln('Potential headings found: $headings');
    
    // Navigation elements
    final hasBottomNav = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
    final hasAppBar = find.byType(AppBar).evaluate().isNotEmpty;
    final hasTabBar = find.byType(TabBar).evaluate().isNotEmpty;
    
    buffer.writeln('\nNavigation elements:');
    buffer.writeln('  Bottom navigation: ${hasBottomNav ? "Present" : "Not found"}');
    buffer.writeln('  App bar: ${hasAppBar ? "Present" : "Not found"}');
    buffer.writeln('  Tab bar: ${hasTabBar ? "Present" : "Not found"}');
    
    // Loading indicators
    final loadingIndicators = find.byType(CircularProgressIndicator).evaluate().length;
    buffer.writeln('\nLoading indicators found: $loadingIndicators');
    
    return buffer.toString();
  }

  /// Find all interactive elements on the screen
  static List<Finder> _findInteractiveElements(WidgetTester tester) {
    final interactiveTypes = [
      ElevatedButton,
      TextButton,
      OutlinedButton,
      IconButton,
      FloatingActionButton,
      InkWell,
      GestureDetector,
      ListTile,
    ];

    final elements = <Finder>[];
    for (final type in interactiveTypes) {
      final found = find.byType(type);
      for (int i = 0; i < found.evaluate().length; i++) {
        elements.add(found.at(i));
      }
    }
    
    return elements;
  }

  /// Create a test wrapper with accessibility debugging enabled
  static Widget createAccessibleTestWrapper({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: Semantics(
          container: true,
          child: child,
        ),
      ),
      // Enable accessibility debugging
      debugShowCheckedModeBanner: false,
    );
  }

  /// Simulate screen reader navigation
  static Future<void> simulateScreenReaderNavigation(WidgetTester tester) async {
    // This would simulate screen reader navigation patterns
    // Implementation depends on specific testing requirements
    
    // Find all focusable elements
    final focusableElements = find.byWidgetPredicate((widget) {
      return widget is Focus || 
             widget is FocusableActionDetector ||
             widget is TextField ||
             widget is ElevatedButton ||
             widget is TextButton ||
             widget is IconButton;
    });

    // Simulate tab navigation through elements
    for (int i = 0; i < focusableElements.evaluate().length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
  }
}

/// Extension to add accessibility testing methods to WidgetTester
extension AccessibilityTesting on WidgetTester {
  /// Run accessibility audit on current screen
  void auditAccessibility() {
    AccessibilityTestUtils.runAccessibilityAudit(this);
  }

  /// Generate accessibility report for current screen
  String getAccessibilityReport() {
    return AccessibilityTestUtils.generateAccessibilityReport(this);
  }

  /// Verify touch targets meet minimum size requirements
  void verifyTouchTargets() {
    AccessibilityTestUtils.verifyTouchTargets(this);
  }

  /// Verify semantic labels are present
  void verifySemanticLabels() {
    AccessibilityTestUtils.verifySemanticLabels(this);
  }
}