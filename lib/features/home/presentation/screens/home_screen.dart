import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/home_feed_page.dart';
import '../providers/home_feed_provider.dart';
import '../widgets/home_feed_card.dart';
import '../widgets/home_feed_load_more_indicator.dart';
import '../widgets/home_feed_shimmer.dart';
import '../../../library/domain/entities/library_entry.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../../../library/presentation/widgets/library_entry_card.dart';
import '../../../library/presentation/widgets/library_shimmer.dart';

/// Home screen that hosts Feed and Library tabs.
class HomeScreen extends StatelessWidget {
  /// Creates the Home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    Text('Home', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  tabs: const <Tab>[
                    Tab(text: AppStrings.feed),
                    Tab(text: AppStrings.library),
                  ],
                  indicator: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  labelColor: colorScheme.onSecondaryContainer,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  overlayColor: const WidgetStatePropertyAll<Color>(
                    Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Expanded(
                child: TabBarView(
                  children: <Widget>[_HomeFeedTabView(), _HomeLibraryTabView()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFeedTabView extends ConsumerStatefulWidget {
  const _HomeFeedTabView();

  @override
  ConsumerState<_HomeFeedTabView> createState() => _HomeFeedTabViewState();
}

class _HomeFeedTabViewState extends ConsumerState<_HomeFeedTabView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    Future<void>.microtask(() {
      ref.read(homeFeedNotifierProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final double position = _scrollController.position.pixels;
    final double max = _scrollController.position.maxScrollExtent;
    if (position >= max - 120) {
      ref.read(homeFeedNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<HomeFeedPage> state = ref.watch(homeFeedNotifierProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(homeFeedNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: _buildFeedSlivers(context, state),
      ),
    );
  }

  List<Widget> _buildFeedSlivers(
    BuildContext context,
    AsyncValue<HomeFeedPage> state,
  ) {
    return state.when(
      loading: () => <Widget>[
        const SliverToBoxAdapter(child: HomeFeedShimmer(itemCount: 4)),
      ],
      error: (Object error, StackTrace stackTrace) => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            title: 'Unable to load home feed',
            message: error.toString(),
            retryLabel: 'Retry',
            onRetry: () {
              ref.read(homeFeedNotifierProvider.notifier).fetch();
            },
          ),
        ),
      ],
      data: (HomeFeedPage page) {
        if (page.items.isEmpty) {
          return <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'No updates yet',
                description:
                    'Try refreshing or adjusting your feed preferences.',
                actionLabel: 'Refresh',
                onAction: () {
                  ref.read(homeFeedNotifierProvider.notifier).refresh();
                },
                icon: Ionicons.sparkles_outline,
              ),
            ),
          ];
        }

        return <Widget>[
          SliverPadding(
            padding: InsetsTokens.page,
            sliver: SliverList.separated(
              itemCount: page.items.length,
              itemBuilder: (BuildContext context, int index) {
                final item = page.items[index];
                return HomeFeedCard(key: ValueKey<String>(item.id), item: item);
              },
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            ),
          ),
          if (page.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: HomeFeedLoadMoreIndicator(),
              ),
            ),
        ];
      },
    );
  }
}

class _HomeLibraryTabView extends ConsumerStatefulWidget {
  const _HomeLibraryTabView();

  @override
  ConsumerState<_HomeLibraryTabView> createState() =>
      _HomeLibraryTabViewState();
}

class _HomeLibraryTabViewState extends ConsumerState<_HomeLibraryTabView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    Future<void>.microtask(() {
      ref.read(libraryNotifierProvider.notifier).fetchHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final double position = _scrollController.position.pixels;
    final double max = _scrollController.position.maxScrollExtent;
    if (position >= max - 120) {
      ref.read(libraryNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LibraryEntry>> state = ref.watch(
      libraryNotifierProvider,
    );

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(libraryNotifierProvider.notifier).fetchHistory(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: _buildLibrarySlivers(context, state),
      ),
    );
  }

  List<Widget> _buildLibrarySlivers(
    BuildContext context,
    AsyncValue<List<LibraryEntry>> state,
  ) {
    return state.when(
      loading: () => <Widget>[
        const SliverToBoxAdapter(child: LibraryShimmer(itemCount: 5)),
      ],
      error: (Object error, StackTrace stackTrace) => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            title: 'Unable to load library',
            message: error.toString(),
            retryLabel: 'Retry',
            onRetry: () {
              ref.read(libraryNotifierProvider.notifier).fetchHistory();
            },
          ),
        ),
      ],
      data: (List<LibraryEntry> entries) {
        if (entries.isEmpty) {
          return <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'Your library is empty',
                description:
                    'Start reading and your recent titles will appear here.',
                actionLabel: 'Refresh',
                onAction: () {
                  ref.read(libraryNotifierProvider.notifier).fetchHistory();
                },
                icon: Ionicons.library_outline,
              ),
            ),
          ];
        }

        return <Widget>[
          SliverPadding(
            padding: InsetsTokens.page,
            sliver: SliverList.separated(
              itemCount: entries.length,
              itemBuilder: (BuildContext context, int index) {
                final LibraryEntry entry = entries[index];
                return LibraryEntryCard(
                  key: ValueKey<String>(entry.id),
                  entry: entry,
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            ),
          ),
        ];
      },
    );
  }
}
