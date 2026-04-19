import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/feed_item.dart';
import '../controllers/feed_controller.dart';
import '../widgets/feed_card_skeleton.dart';
import '../widgets/feed_filter_bar_widget.dart';
import '../widgets/feed_card_widget.dart';

/// Fixed height used when the filter bar is pinned in a sliver header.
const double kFeedFilterBarHeight = AppSpacing.xxxl + AppSpacing.xs;
const double _feedHeroHeight = 240;
const double _feedRailCardWidth = 152;
const double _feedRailCardHeight = 236;

/// Reusable feed tab widget that handles loading, error, empty, and data states.
///
/// Uses a streaming-style layout:
/// - Pinned filter/sort header
/// - Large spotlight hero
/// - Horizontal discovery rail
/// - Latest updates section
/// - Empty/error/loading states with the same visual language
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

        final double horizontalPadding = isCompact
            ? AppSpacing.md
            : isMedium
            ? AppSpacing.lg
            : AppSpacing.xl;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
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
              ..._buildStateSlivers(
                context: context,
                ref: ref,
                horizontalPadding: horizontalPadding,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildStateSlivers({
    required BuildContext context,
    required WidgetRef ref,
    required double horizontalPadding,
  }) {
    return asyncFeed.when(
      loading: () => <Widget>[
        _FeedLoadingView(horizontalPadding: horizontalPadding),
      ],
      error: (Object error, StackTrace _) => <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.md,
            horizontalPadding,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: ErrorState(
              title: AppStrings.feedLoadFailed,
              message: error.toString(),
              retryLabel: AppStrings.retry,
              onRetry: onRefresh,
            ),
          ),
        ),
      ],
      data: (FeedViewState feedState) {
        if (feedState.items.isEmpty) {
          return <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: EmptyState(
                  title: AppStrings.feedEmptyTitle,
                  description: AppStrings.feedEmptyBody,
                  actionLabel: AppStrings.feedBrowseExtensions,
                  onAction: () {
                    ExtensionsStoreRoute.go(context);
                  },
                ),
              ),
            ),
          ];
        }

        final FeedItem spotlightItem = feedState.items.first;
        final List<FeedItem> remainingItems = feedState.items
            .skip(1)
            .toList(growable: false);
        final List<FeedItem> continueWatchingItems = _selectContinueWatching(
          remainingItems,
        );
        final List<FeedItem> latestItems = remainingItems
            .take(6)
            .toList(growable: false);
        final int unreadCount = feedState.items.where((FeedItem item) {
          return !item.isBookmarked;
        }).length;

        return <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.md,
              horizontalPadding,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: _FeedHeroSection(
                spotlightItem: spotlightItem,
                unreadCount: unreadCount,
                lastSyncedAt: feedState.lastSyncedAt,
              ),
            ),
          ),
          if (continueWatchingItems.isNotEmpty)
            SliverToBoxAdapter(
              child: _FeedSectionBlock(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                title: AppStrings.feedContinueWatchingLabel,
                child: SizedBox(
                  height: _feedRailCardHeight,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: continueWatchingItems.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final FeedItem item = continueWatchingItems[index];
                      return SizedBox(
                        width: _feedRailCardWidth,
                        child: _FeedPosterCard(
                          item: item,
                          showBookmarkState: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _FeedSectionBlock(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              title: AppStrings.feedLatestFromSourcesLabel,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: <Widget>[
                    for (final FeedItem item in latestItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: FeedCardWidget(
                          key: ValueKey<String>(item.id),
                          item: item,
                          onTap: () {},
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (feedState.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  AppSpacing.xl,
                ),
                child: Align(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(feedControllerProvider.notifier).loadNextPage();
                    },
                    icon: const Icon(Ionicons.chevron_down_outline),
                    label: const Text(AppStrings.feedLoadMore),
                  ),
                ),
              ),
            ),
        ];
      },
    );
  }
}

class _FeedLoadingView extends StatelessWidget {
  const _FeedLoadingView({this.horizontalPadding = AppSpacing.md});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
        AppSpacing.xl,
      ),
      sliver: SliverToBoxAdapter(
        child: LoadingShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _FeedHeroSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              const _FeedSectionSkeletonHeader(),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: _feedRailCardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      width: _feedRailCardWidth,
                      child: _FeedPosterSkeleton(),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _FeedSectionSkeletonHeader(shorter: true),
              const SizedBox(height: AppSpacing.sm),
              const FeedCardSkeleton(),
              const FeedCardSkeleton(),
              const FeedCardSkeleton(),
            ],
          ),
        ),
      ),
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
    final Color backgroundColor = Theme.of(
      context,
    ).colorScheme.surfaceContainer;

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
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

    return AppCard.featured(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: _feedHeroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _FeedHeroArtwork(imageUrl: spotlightItem.imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      colorScheme.surface.withValues(alpha: 0.08),
                      colorScheme.surface.withValues(alpha: 0.58),
                      colorScheme.surface.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            AppStrings.feedFeaturedNowLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const Spacer(),
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
                    const Spacer(),
                    Text(
                      spotlightItem.title,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            spotlightItem.metadata,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatLastSync(lastSyncedAt),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FeedQuickStatsRow(
                      unreadCount: unreadCount,
                      lastSyncedAt: lastSyncedAt,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

class _FeedSectionBlock extends StatelessWidget {
  const _FeedSectionBlock({
    required this.title,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(title, style: textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          DefaultTextStyle.merge(
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FeedSectionSkeletonHeader extends StatelessWidget {
  const _FeedSectionSkeletonHeader({this.shorter = false});

  final bool shorter;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: SizedBox(width: shorter ? 160 : 220, height: AppSpacing.lg),
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: SizedBox(width: shorter ? 120 : 180, height: AppSpacing.md),
        ),
      ],
    );
  }
}

class _FeedPosterSkeleton extends StatelessWidget {
  const _FeedPosterSkeleton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const SizedBox(
                height: AppSpacing.md,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const SizedBox(height: AppSpacing.sm, width: 100),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedPosterCard extends StatelessWidget {
  const _FeedPosterCard({required this.item, this.showBookmarkState = false});

  final FeedItem item;
  final bool showBookmarkState;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _FeedHeroArtwork(imageUrl: item.imageUrl)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.title,
                style: textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                item.subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.metadata,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showBookmarkState)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: item.isBookmarked
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        item.isBookmarked
                            ? AppStrings.feedStatusRead
                            : AppStrings.feedStatusLive,
                        style: textTheme.labelSmall?.copyWith(
                          color: item.isBookmarked
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedHeroArtwork extends StatelessWidget {
  const _FeedHeroArtwork({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
        child: imageUrl.isEmpty
            ? Center(
                child: Icon(
                  Ionicons.play_circle_outline,
                  color: colorScheme.onSurfaceVariant,
                  size: AppSpacing.xxl,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Ionicons.play_circle_outline,
                                color: colorScheme.onSurfaceVariant,
                                size: AppSpacing.xxl,
                              ),
                            ),
                          );
                        },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          colorScheme.scrim.withValues(alpha: 0.04),
                          colorScheme.scrim.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

List<FeedItem> _selectContinueWatching(List<FeedItem> items) {
  final List<FeedItem> bookmarked = items
      .where((FeedItem item) => !item.isBookmarked)
      .toList(growable: false);

  if (bookmarked.isNotEmpty) {
    return bookmarked.take(6).toList(growable: false);
  }

  return items.take(6).toList(growable: false);
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
