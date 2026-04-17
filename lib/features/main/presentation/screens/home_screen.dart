import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../feed/domain/entities/feed_filter.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../feed/presentation/widgets/feed_filter_bar_widget.dart';
import '../../../feed/presentation/widgets/feed_list_widget.dart';

/// Home screen that renders the user feed.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FeedViewState> asyncFeed = ref.watch(
      feedControllerProvider,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
        child: asyncFeed.when(
          loading: () => const _FeedLoadingScrollView(),
          error: (Object error, StackTrace _) {
            return _FeedScaffold(
              filter: FeedFilter.initial,
              contentSliver: SliverToBoxAdapter(
                child: ErrorState(
                  title: AppStrings.feedLoadFailed,
                  message: error.toString(),
                  retryLabel: AppStrings.retry,
                  onRetry: () {
                    ref.read(feedControllerProvider.notifier).refresh();
                  },
                ),
              ),
              onSortChanged: (FeedSortOrder sortOrder) {
                final FeedFilter current = FeedFilter.initial;
                ref
                    .read(feedControllerProvider.notifier)
                    .applyFilter(current.copyWith(sortOrder: sortOrder));
              },
              onIncludeReadChanged: (bool includeRead) {
                final FeedFilter current = FeedFilter.initial;
                ref
                    .read(feedControllerProvider.notifier)
                    .applyFilter(current.copyWith(includeRead: includeRead));
              },
            );
          },
          data: (FeedViewState feedState) {
            final Widget content = feedState.items.isEmpty
                ? SliverToBoxAdapter(
                    child: EmptyState(
                      title: AppStrings.feedEmptyTitle,
                      description: AppStrings.feedEmptyBody,
                      actionLabel: AppStrings.feedBrowseExtensions,
                      onAction: () {
                        ExtensionsStoreRoute.go(context);
                      },
                    ),
                  )
                : FeedListWidget(
                    items: feedState.items,
                    hasMore: feedState.hasMore,
                    onLoadMore: () {
                      ref.read(feedControllerProvider.notifier).loadNextPage();
                    },
                  );

            return _FeedScaffold(
              filter: feedState.filter,
              contentSliver: content,
              onSortChanged: (FeedSortOrder sortOrder) {
                ref
                    .read(feedControllerProvider.notifier)
                    .applyFilter(
                      feedState.filter.copyWith(sortOrder: sortOrder),
                    );
              },
              onIncludeReadChanged: (bool includeRead) {
                ref
                    .read(feedControllerProvider.notifier)
                    .applyFilter(
                      feedState.filter.copyWith(includeRead: includeRead),
                    );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FeedScaffold extends StatelessWidget {
  const _FeedScaffold({
    required this.filter,
    required this.contentSliver,
    required this.onSortChanged,
    required this.onIncludeReadChanged,
  });

  final FeedFilter filter;
  final Widget contentSliver;
  final ValueChanged<FeedSortOrder> onSortChanged;
  final ValueChanged<bool> onIncludeReadChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        const SliverAppBar.large(title: Text(AppStrings.home)),
        SliverPadding(
          padding: InsetsTokens.page,
          sliver: SliverToBoxAdapter(
            child: FeedFilterBarWidget(
              filter: filter,
              onSortChanged: onSortChanged,
              onIncludeReadChanged: onIncludeReadChanged,
            ),
          ),
        ),
        SliverPadding(padding: InsetsTokens.page, sliver: contentSliver),
      ],
    );
  }
}

class _FeedLoadingScrollView extends StatelessWidget {
  const _FeedLoadingScrollView();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        const SliverAppBar.large(title: Text(AppStrings.home)),
        SliverPadding(
          padding: InsetsTokens.page,
          sliver: SliverList.list(
            children: <Widget>[
              LoadingShimmer(
                child: Column(
                  children: <Widget>[
                    _LoadingCard(color: colorScheme.surfaceContainerHighest),
                    const SizedBox(height: AppSpacing.sm),
                    _LoadingCard(color: colorScheme.surfaceContainerHighest),
                    const SizedBox(height: AppSpacing.sm),
                    _LoadingCard(color: colorScheme.surfaceContainerHighest),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const SizedBox(height: AppSpacing.xxxl),
    );
  }
}
