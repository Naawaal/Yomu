import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/feed_filter.dart';

/// Fixed height used when the filter bar is pinned in a sliver header.
const double kFeedFilterBarHeight = AppSpacing.xxxl + AppSpacing.xs;

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
    return SizedBox(
      height: kFeedFilterBarHeight,
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: InsetsTokens.card,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SegmentedButton<FeedSortOrder>(
                  segments: const <ButtonSegment<FeedSortOrder>>[
                    ButtonSegment<FeedSortOrder>(
                      value: FeedSortOrder.newestFirst,
                      label: Text(AppStrings.feedSortNewest),
                      icon: Icon(Ionicons.arrow_down_outline),
                    ),
                    ButtonSegment<FeedSortOrder>(
                      value: FeedSortOrder.oldestFirst,
                      label: Text(AppStrings.feedSortOldest),
                      icon: Icon(Ionicons.arrow_up_outline),
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
                const SizedBox(width: AppSpacing.sm),
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
        ),
      ),
    );
  }
}
