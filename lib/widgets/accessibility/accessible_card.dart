import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

/// Accessibility-enhanced card widget with proper semantic structure
class AccessibleCard extends StatelessWidget {
  final String? semanticLabel;
  final String? hint;
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelectable;
  final bool isSelected;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;

  const AccessibleCard({
    super.key,
    this.semanticLabel,
    this.hint,
    required this.child,
    this.onTap,
    this.isSelectable = false,
    this.isSelected = false,
    this.margin,
    this.padding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin,
      elevation: elevation,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    if (onTap != null || isSelectable) {
      final label = AccessibilityUtils.createSemanticLabel(
        label: semanticLabel ?? 'Card',
        hint: hint,
        isButton: onTap != null,
        isSelected: isSelected,
      );

      return Semantics(
        label: label,
        hint: hint,
        button: onTap != null,
        selected: isSelected,
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ExcludeSemantics(child: card),
        ),
      );
    }

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        hint: hint,
        child: card,
      );
    }

    return card;
  }
}

/// Accessibility-enhanced list tile
class AccessibleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? hint;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool enabled;

  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.hint,
    this.leading,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      label: title,
      hint: hint,
      value: subtitle,
      isButton: onTap != null,
      isSelected: isSelected,
    );

    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: onTap != null,
      selected: isSelected,
      enabled: enabled && onTap != null,
      child: ExcludeSemantics(
        child: ListTile(
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          leading: leading,
          trailing: trailing,
          onTap: enabled ? onTap : null,
          selected: isSelected,
          enabled: enabled,
        ),
      ),
    );
  }
}