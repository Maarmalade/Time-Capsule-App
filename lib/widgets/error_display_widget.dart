import 'package:flutter/material.dart';

/// A reusable widget for displaying errors with consistent styling
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onRetry;
  final String? retryText;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.icon,
    this.color,
    this.onRetry,
    this.retryText,
    this.showIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = color ?? Colors.red.shade600;
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIcon) ...[
                Icon(
                  icon ?? Icons.error_outline,
                  color: errorColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: errorColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text(retryText ?? 'Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A widget for displaying validation errors in forms
class ValidationErrorWidget extends StatelessWidget {
  final String? error;
  final EdgeInsetsGeometry? padding;

  const ValidationErrorWidget({
    super.key,
    this.error,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget for displaying loading states with error handling
class LoadingStateWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final Widget child;
  final VoidCallback? onRetry;
  final String? loadingText;
  final String? retryText;

  const LoadingStateWidget({
    super.key,
    required this.isLoading,
    this.error,
    required this.child,
    this.onRetry,
    this.loadingText,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (loadingText != null) ...[
              const SizedBox(height: 16),
              Text(
                loadingText!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: ErrorDisplayWidget(
          message: error!,
          onRetry: onRetry,
          retryText: retryText,
        ),
      );
    }

    return child;
  }
}

/// A widget for displaying network-related errors
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplayWidget(
      message: customMessage ?? 
          'Unable to connect to the server. Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
      retryText: 'Try Again',
    );
  }
}

/// A widget for displaying empty state with optional error context
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final bool isError;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade600 : Colors.grey.shade600;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? (isError ? Icons.error_outline : Icons.folder_open),
              size: 64,
              color: color.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 16,
              ),
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}