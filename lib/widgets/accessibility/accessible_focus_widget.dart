import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../utils/black_theme_accessibility.dart';

/// A widget that provides accessible focus indicators for interactive elements
class AccessibleFocusWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onFocusChange;
  final String? semanticLabel;
  final String? semanticHint;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color? customFocusColor;
  final double focusWidth;
  final double borderRadius;

  const AccessibleFocusWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onFocusChange,
    this.semanticLabel,
    this.semanticHint,
    this.autofocus = false,
    this.focusNode,
    this.customFocusColor,
    this.focusWidth = 2.0,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  State<AccessibleFocusWidget> createState() => _AccessibleFocusWidgetState();
}

class _AccessibleFocusWidgetState extends State<AccessibleFocusWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChange?.call();
  }

  Color _getFocusColor() {
    if (widget.customFocusColor != null) {
      return widget.customFocusColor!;
    }
    
    // Get the background color from the current context
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return BlackThemeAccessibility.getFocusIndicatorColor(backgroundColor);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      button: widget.onTap != null,
      focusable: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: _isFocused
                    ? Border.all(
                        color: _getFocusColor(),
                        width: widget.focusWidth,
                      )
                    : null,
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: _getFocusColor().withValues(alpha: 0.3),
                          blurRadius: 4.0,
                          spreadRadius: 1.0,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: _isHovered && !_isFocused
                      ? AppColors.hoverOverlay
                      : Colors.transparent,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized accessible focus widget for buttons
class AccessibleButtonFocus extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool enabled;
  final Color? backgroundColor;

  const AccessibleButtonFocus({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final focusColor = BlackThemeAccessibility.getFocusIndicatorColor(bgColor);
    
    return AccessibleFocusWidget(
      onTap: enabled ? onPressed : null,
      semanticLabel: semanticLabel,
      semanticHint: enabled ? 'Double tap to activate' : 'Button is disabled',
      customFocusColor: focusColor,
      focusWidth: 2.5,
      child: child,
    );
  }
}

/// A specialized accessible focus widget for form fields
class AccessibleFormFieldFocus extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final bool required;
  final bool hasError;

  const AccessibleFormFieldFocus({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.required = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = StringBuffer();
    if (label != null) {
      semanticLabel.write(label);
      if (required) {
        semanticLabel.write(', required');
      }
    }
    
    final semanticHint = StringBuffer();
    if (hint != null) {
      semanticHint.write(hint);
    }
    if (hasError) {
      semanticHint.write(', has error');
    }

    return AccessibleFocusWidget(
      semanticLabel: semanticLabel.isNotEmpty ? semanticLabel.toString() : null,
      semanticHint: semanticHint.isNotEmpty ? semanticHint.toString() : null,
      customFocusColor: hasError ? AppColors.errorRed : null,
      focusWidth: hasError ? 3.0 : 2.0,
      child: child,
    );
  }
}

/// A specialized accessible focus widget for navigation items
class AccessibleNavigationFocus extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final bool isSelected;
  final int? index;

  const AccessibleNavigationFocus({
    super.key,
    required this.child,
    this.onTap,
    this.label,
    this.isSelected = false,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = StringBuffer();
    if (label != null) {
      semanticLabel.write(label);
    }
    if (index != null) {
      semanticLabel.write(', tab ${index! + 1}');
    }
    if (isSelected) {
      semanticLabel.write(', selected');
    }

    return AccessibleFocusWidget(
      onTap: onTap,
      semanticLabel: semanticLabel.isNotEmpty ? semanticLabel.toString() : null,
      semanticHint: 'Double tap to navigate',
      customFocusColor: isSelected ? AppColors.primaryAccent : null,
      focusWidth: isSelected ? 3.0 : 2.0,
      child: child,
    );
  }
}