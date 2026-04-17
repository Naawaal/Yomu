import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/feed_filter.dart';

/// Filter controls shown above the feed list.
class FeedFilterBarWidget extends StatelessWidget {
  /// Creates a feed filter bar.
  const FeedFilterBarWidget({
    super.key,
    required this.filter,
    required this.onSortChanged,
    required this.onIncludeReadChanged,
  });

  /// Active feed filter values.
  final FeedFilter filter;

  /// Callback invoked when sort order changes.
  final ValueChanged<FeedSortOrder> onSortChanged;

  /// Callback invoked when read-item visibility changes.
  final ValueChanged<bool> onIncludeReadChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: InsetsTokens.card,
        child: Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SegmentedButton<FeedSortOrder>(
              segments: const <ButtonSegment<FeedSortOrder>>[
                ButtonSegment<FeedSortOrder>(
                  value: FeedSortOrder.newestFirst,
                  label: Text(AppStrings.feedSortNewest),
                  icon: Icon(Icons.south_rounded),
                ),
                ButtonSegment<FeedSortOrder>(
                  value: FeedSortOrder.oldestFirst,
                  label: Text(AppStrings.feedSortOldest),
                  icon: Icon(Icons.north_rounded),
                ),
              ],
              selected: <FeedSortOrder>{filter.sortOrder},
              onSelectionChanged: (Set<FeedSortOrder> selection) {
                if (selection.isEmpty) {
                  return;
                }
                onSortChanged(selection.first);
              },
            ),
            FilterChip(
              label: Text(
                filter.includeRead
                    ? AppStrings.feedFilterIncludingRead
                    : AppStrings.feedFilterUnreadOnly,
              ),
              selected: filter.includeRead,
              onSelected: onIncludeReadChanged,
            ),
          ],
        ),
      ),
    );
  }
}
