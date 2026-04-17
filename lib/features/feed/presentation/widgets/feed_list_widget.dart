import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/feed_item.dart';

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
        final ColorScheme colorScheme = Theme.of(context).colorScheme;

        return Padding(
          key: ValueKey<String>(item.id),
          padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: ListTile(
              contentPadding: InsetsTokens.card,
              leading: Icon(
                item.isRead
                    ? Icons.mark_email_read_rounded
                    : Icons.mark_email_unread_rounded,
                color: item.isRead
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
              title: Text(
                item.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: SpacingTokens.xs),
                child: Text(
                  '${item.sourceName} • ${item.subtitle}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {},
            ),
          ),
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
      return const SizedBox(height: SpacingTokens.sm);
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: SpacingTokens.xs,
        bottom: SpacingTokens.xl,
      ),
      child: Align(
        child: OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.expand_more_rounded),
          label: const Text(AppStrings.feedLoadMore),
        ),
      ),
    );
  }
}
