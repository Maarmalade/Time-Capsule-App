import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

/// Accessibility-enhanced button widget with proper semantic labels
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Widget? child;
  final ButtonStyle? style;
  final bool isPrimary;
  final bool isLoading;
  final String? loadingLabel;

  const AccessibleButton({
    super.key,
    required this.label,
    this.hint,
    this.onPressed,
    this.child,
    this.style,
    this.isPrimary = true,
    this.isLoading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      label: isLoading ? (loadingLabel ?? 'Loading, $label') : label,
      hint: hint,
      isButton: true,
    );

    final button = isPrimary
        ? ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: _buildButtonContent(),
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: _buildButtonContent(),
          );

    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: ExcludeSemantics(
        child: button,
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          if (loadingLabel != null) ...[
            const SizedBox(width: 8),
            Text(loadingLabel!),
          ],
        ],
      );
    }
    
    return child ?? Text(label);
  }
}

/// Accessibility-enhanced text button
class AccessibleTextButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Widget? child;
  final ButtonStyle? style;

  const AccessibleTextButton({
    super.key,
    required this.label,
    this.hint,
    this.onPressed,
    this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      label: label,
      hint: hint,
      isButton: true,
    );

    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: ExcludeSemantics(
        child: TextButton(
          onPressed: onPressed,
          style: style,
          child: child ?? Text(label),
        ),
      ),
    );
  }
}

/// Accessibility-enhanced icon button
class AccessibleIconButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Widget icon;
  final double? iconSize;
  final Color? color;

  const AccessibleIconButton({
    super.key,
    required this.label,
    this.hint,
    this.onPressed,
    required this.icon,
    this.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      label: label,
      hint: hint,
      isButton: true,
    );

    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: ExcludeSemantics(
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
          iconSize: iconSize,
          color: color,
          tooltip: label, // Provides tooltip for mouse users
        ),
      ),
    );
  }
}