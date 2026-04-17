import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';

/// Error-state card shown when feed loading fails.
class FeedErrorStateWidget extends StatelessWidget {
  /// Creates a feed error-state widget.
  const FeedErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// Human-readable error message.
  final String message;

  /// Callback to retry feed loading.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer,
      child: Padding(
        padding: InsetsTokens.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.feedLoadFailed,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
