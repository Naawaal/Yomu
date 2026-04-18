import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';

/// Footer indicator shown while Home feed can load more items.
class HomeFeedLoadMoreIndicator extends StatelessWidget {
  const HomeFeedLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Ionicons.sync_outline,
            color: colorScheme.onSurfaceVariant,
            size: AppSpacing.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Loading more updates',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
