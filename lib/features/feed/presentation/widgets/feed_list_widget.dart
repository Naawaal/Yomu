import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/feed_item.dart';
import 'feed_card_widget.dart';

/// Sliver list for rendering feed items and pagination control.
class FeedListWidget extends StatelessWidget {
  /// Creates a feed list widget.
  const FeedListWidget({
    super.key,
    required this.items,
    required this.hasMore,
    required this.onLoadMore,
  });

  /// Feed items to display.
  final List<FeedItem> items;

  /// Whether more data can be requested.
  final bool hasMore;

  /// Callback used to request next page.
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        if (index == items.length) {
          return _LoadMoreSection(hasMore: hasMore, onLoadMore: onLoadMore);
        }

        final FeedItem item = items[index];

        final Widget tile = FeedCardWidget(
          key: ValueKey<String>(item.id),
          item: item,
          onTap: () {},
        );

        // Staggered animation: 60ms per item
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 200 + (index * 60)),
          builder: (BuildContext context, double value, Widget? child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * AppSpacing.md),
                child: child,
              ),
            );
          },
          child: tile,
        );
      }, childCount: items.length + 1),
    );
  }
}

class _LoadMoreSection extends StatelessWidget {
  const _LoadMoreSection({required this.hasMore, required this.onLoadMore});

  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const SizedBox(height: AppSpacing.sm);
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xl),
      child: Align(
        child: OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Ionicons.chevron_down_outline),
          label: const Text(AppStrings.feedLoadMore),
        ),
      ),
    );
  }
}
