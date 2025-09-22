import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

/// Accessibility-enhanced text field with proper semantic labels
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool required;
  final int? maxLines;
  final String? initialValue;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.required = false,
    this.maxLines = 1,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      label: required ? '$label, required' : label,
      hint: hint,
    );

    final accessibilityHint = AccessibilityUtils.createAccessibilityHint(
      action: obscureText ? 'Enter password' : 'Enter text',
      result: 'update $label field',
    );

    return Semantics(
      label: semanticLabel,
      hint: errorText ?? accessibilityHint,
      textField: true,
      enabled: enabled,
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        onChanged: onChanged,
        onTap: onTap,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          // Remove semantic information from decoration since we handle it above
          semanticCounterText: '',
        ),
        validator: required ? (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
      ),
    );
  }
}

/// Accessibility-enhanced dropdown field
class AccessibleDropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool required;
  final String? errorText;

  const AccessibleDropdownField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.required = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      label: required ? '$label, required' : label,
      hint: hint,
      value: value?.toString(),
    );

    final accessibilityHint = AccessibilityUtils.createAccessibilityHint(
      action: 'Select option',
      result: 'choose value for $label',
    );

    return Semantics(
      label: semanticLabel,
      hint: errorText ?? accessibilityHint,
      enabled: enabled,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          errorText: errorText,
        ),
        validator: required ? (value) {
          if (value == null) {
            return '$label is required';
          }
          return null;
        } : null,
      ),
    );
  }
}