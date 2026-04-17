import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// Standardized error-state surface with retry action.
class ErrorState extends StatelessWidget {
  /// Creates an [ErrorState].
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  /// Error title.
  final String title;

  /// User-safe error message.
  final String message;

  /// Retry button label.
  final String retryLabel;

  /// Retry callback.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Ionicons.close_circle_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.outlined(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
