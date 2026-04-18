import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/feed_item.dart';
import '../controllers/feed_controller.dart';
import '../widgets/feed_card_skeleton.dart';
import '../widgets/feed_filter_bar_widget.dart';
import '../widgets/feed_list_widget.dart';

/// Fixed height used when the filter bar is pinned in a sliver header.
const double kFeedFilterBarHeight = AppSpacing.xxxl + AppSpacing.xs;

/// Reusable feed tab widget that handles loading, error, empty, and data states.
///
/// Manages:
/// - Pinned filter/sort header (height: 64px)
/// - Pull-to-refresh indicator
/// - Card list with AppSpacing.md spacing
/// - Empty state with "Browse Extensions" CTA
/// - Error state with "Retry" button
/// - Loading skeletons (3 cards matching layout)
class FeedTab extends ConsumerWidget {
  /// Creates a feed tab widget.
  const FeedTab({
    super.key,
    required this.asyncFeed,
    required this.filter,
    required this.onSortChanged,
    required this.onIncludeReadChanged,
    required this.onRefresh,
  });

  /// Async feed state from controller.
  final AsyncValue<FeedViewState> asyncFeed;

  /// Current active filter.
  final FeedFilter filter;

  /// Callback when sort order changes.
  final ValueChanged<FeedSortOrder> onSortChanged;

  /// Callback when read-item visibility changes.
  final ValueChanged<bool> onIncludeReadChanged;

  /// Callback for pull-to-refresh.
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < ScreenBreakpoints.compact;
        final bool isMedium =
            constraints.maxWidth >= ScreenBreakpoints.compact &&
            constraints.maxWidth < ScreenBreakpoints.medium;

        // Responsive padding
        final double horizontalPadding = isCompact
            ? AppSpacing.md
            : isMedium
            ? AppSpacing.lg
            : AppSpacing.xl;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: asyncFeed.when(
            loading: () =>
                _FeedLoadingView(horizontalPadding: horizontalPadding),
            error: (Object error, StackTrace _) {
              return _FeedScaffold(
                filter: filter,
                contentSlivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverList.list(
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        ErrorState(
                          title: AppStrings.feedLoadFailed,
                          message: error.toString(),
                          retryLabel: AppStrings.retry,
                          onRetry: onRefresh,
                        ),
                      ],
                    ),
                  ),
                ],
                onSortChanged: onSortChanged,
                onIncludeReadChanged: onIncludeReadChanged,
              );
            },
            data: (FeedViewState feedState) {
              if (feedState.items.isEmpty) {
                return _FeedScaffold(
                  filter: feedState.filter,
                  contentSlivers: <Widget>[
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverList.list(
                        children: <Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          EmptyState(
                            title: AppStrings.feedEmptyTitle,
                            description: AppStrings.feedEmptyBody,
                            actionLabel: AppStrings.feedBrowseExtensions,
                            onAction: () {
                              ExtensionsStoreRoute.go(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSortChanged: onSortChanged,
                  onIncludeReadChanged: onIncludeReadChanged,
                );
              }

              final FeedItem spotlightItem = feedState.items.first;
              final List<FeedItem> remainingItems = feedState.items
                  .skip(1)
                  .toList(growable: false);
              final int unreadCount = feedState.items.where((FeedItem item) {
                return !item.isBookmarked;
              }).length;

              return _FeedScaffold(
                filter: feedState.filter,
                contentSlivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverList.list(
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        _FeedHeroSection(
                          spotlightItem: spotlightItem,
                          unreadCount: unreadCount,
                          lastSyncedAt: feedState.lastSyncedAt,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: FeedListWidget(
                      items: remainingItems,
                      hasMore: feedState.hasMore,
                      onLoadMore: () {
                        ref
                            .read(feedControllerProvider.notifier)
                            .loadNextPage();
                      },
                    ),
                  ),
                ],
                onSortChanged: onSortChanged,
                onIncludeReadChanged: onIncludeReadChanged,
              );
            },
          ),
        );
      },
    );
  }
}

class _FeedScaffold extends StatelessWidget {
  const _FeedScaffold({
    required this.filter,
    required this.contentSlivers,
    required this.onSortChanged,
    required this.onIncludeReadChanged,
  });

  final FeedFilter filter;
  final List<Widget> contentSlivers;
  final ValueChanged<FeedSortOrder> onSortChanged;
  final ValueChanged<bool> onIncludeReadChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: _FeedFilterHeaderDelegate(
            child: FeedFilterBarWidget(
              filter: filter,
              onSortChanged: onSortChanged,
              onIncludeReadChanged: onIncludeReadChanged,
            ),
          ),
        ),
        ...contentSlivers,
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}

class _FeedLoadingView extends StatelessWidget {
  const _FeedLoadingView({this.horizontalPadding = AppSpacing.md});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: _FeedFilterHeaderDelegate(
            child: FeedFilterBarWidget(
              filter: FeedFilter.initial,
              onSortChanged: (_) {},
              onIncludeReadChanged: (_) {},
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverList.list(
            children: <Widget>[
              const SizedBox(height: AppSpacing.sm),
              LoadingShimmer(
                child: Column(
                  children: const <Widget>[
                    _FeedHeroSkeleton(),
                    SizedBox(height: AppSpacing.md),
                    FeedCardSkeleton(),
                    FeedCardSkeleton(),
                    FeedCardSkeleton(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}

class _FeedFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FeedFilterHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => kFeedFilterBarHeight;

  @override
  double get maxExtent => kFeedFilterBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final Color backgroundColor = Theme.of(context).colorScheme.surface;

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FeedFilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _FeedHeroSection extends StatelessWidget {
  const _FeedHeroSection({
    required this.spotlightItem,
    required this.unreadCount,
    required this.lastSyncedAt,
  });

  final FeedItem spotlightItem;
  final int unreadCount;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isBookmarked = spotlightItem.isBookmarked;

    return Column(
      children: <Widget>[
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.feedSpotlightLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        spotlightItem.metadata,
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isBookmarked
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        isBookmarked
                            ? AppStrings.feedStatusRead
                            : AppStrings.feedStatusLive,
                        style: textTheme.labelSmall?.copyWith(
                          color: isBookmarked
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  spotlightItem.title,
                  style: textTheme.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  spotlightItem.subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  spotlightItem.metadata,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _FeedQuickStatsRow(
          unreadCount: unreadCount,
          lastSyncedAt: lastSyncedAt,
        ),
      ],
    );
  }
}

class _FeedQuickStatsRow extends StatelessWidget {
  const _FeedQuickStatsRow({
    required this.unreadCount,
    required this.lastSyncedAt,
  });

  final int unreadCount;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _FeedStatCard(
            label: AppStrings.feedUnreadCountLabel,
            value: '$unreadCount',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FeedStatCard(
            label: AppStrings.feedLastSyncLabel,
            value: _formatLastSync(lastSyncedAt),
          ),
        ),
      ],
    );
  }
}

class _FeedStatCard extends StatelessWidget {
  const _FeedStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedHeroSkeleton extends StatelessWidget {
  const _FeedHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color skeletonColor = colorScheme.surfaceContainerHighest;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const SizedBox(
                width: AppSpacing.xxl,
                height: AppSpacing.sm,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const SizedBox(
                width: double.infinity,
                height: AppSpacing.lg,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const FractionallySizedBox(
              widthFactor: 0.72,
              child: _HeroSkeletonLine(),
            ),
            const SizedBox(height: AppSpacing.sm),
            const FractionallySizedBox(
              widthFactor: 0.88,
              child: _HeroSkeletonLine(height: AppSpacing.md),
            ),
            const SizedBox(height: AppSpacing.xs),
            const FractionallySizedBox(
              widthFactor: 0.56,
              child: _HeroSkeletonLine(height: AppSpacing.md),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSkeletonLine extends StatelessWidget {
  const _HeroSkeletonLine({this.height = AppSpacing.sm});

  final double height;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: SizedBox(width: double.infinity, height: height),
    );
  }
}

String _formatLastSync(DateTime? lastSyncedAt) {
  if (lastSyncedAt == null) {
    return AppStrings.feedLastSyncUnknown;
  }

  return _formatRelativeTime(lastSyncedAt);
}

String _formatRelativeTime(DateTime timestamp) {
  final Duration difference = DateTime.now().difference(timestamp);

  if (difference.inMinutes <= 0) {
    return AppStrings.feedTimeNow;
  }
  if (difference.inHours <= 0) {
    return '${difference.inMinutes}${AppStrings.feedMinutesAgoSuffix}';
  }
  if (difference.inDays <= 0) {
    return '${difference.inHours}${AppStrings.feedHoursAgoSuffix}';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}${AppStrings.feedDaysAgoSuffix}';
  }

  return '${timestamp.month}/${timestamp.day}';
}
