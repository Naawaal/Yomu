import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';

/// Empty state card shown when no extensions are available.
class EmptyStateCard extends StatelessWidget {
  /// Creates an empty state card.
  const EmptyStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: InsetsTokens.card,
        child: Column(
          children: <Widget>[
            Icon(
              Icons.search_off_rounded,
              size: SpacingTokens.xxl,
              color: colorScheme.primary,
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              AppStrings.noExtensionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              AppStrings.noExtensionsBody,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
