import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/tokens.dart';

/// Empty-state card shown when no feed items are available.
class FeedEmptyStateWidget extends StatelessWidget {
  /// Creates a feed empty-state widget.
  const FeedEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ScreenBreakpoints.medium),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: InsetsTokens.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.auto_stories_outlined,
                  size: SpacingTokens.xxxl,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: SpacingTokens.lg),
                Text(
                  AppStrings.feedEmptyTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  AppStrings.feedEmptyBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.lg),
                FilledButton.tonal(
                  onPressed: () {
                    ExtensionsStoreRoute.go(context);
                  },
                  child: const Text(AppStrings.feedBrowseExtensions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
