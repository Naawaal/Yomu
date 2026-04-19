import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../feed/domain/entities/feed_item.dart';
import '../../../feed/presentation/widgets/feed_card_widget.dart';
import '../../domain/entities/home_feed_page.dart';
import '../providers/home_feed_provider.dart';
import '../widgets/home_feed_load_more_indicator.dart';
import '../widgets/home_feed_shimmer.dart';
import '../widgets/home_library_progress_shelf.dart';
import '../widgets/home_hero_section.dart';
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
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            if (isLight) const _HomeLightBackdrop(),
            SafeArea(
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
                        Text(
                          AppStrings.home,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: TabBar(
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
                      children: <Widget>[
                        _HomeFeedTabView(),
                        _HomeLibraryTabView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLightBackdrop extends StatelessWidget {
  const _HomeLightBackdrop();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  colorScheme.primaryContainer.withValues(alpha: 0.22),
                  colorScheme.surface,
                  colorScheme.surface,
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    colorScheme.tertiaryContainer.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    colorScheme.secondaryContainer.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
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
      ref.read(homeFeedNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<HomeFeedPage> state = ref.watch(homeFeedNotifierProvider);
    final AsyncValue<List<LibraryEntry>> libraryState = ref.watch(
      libraryNotifierProvider,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(homeFeedNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: _buildFeedSlivers(context, state, libraryState),
      ),
    );
  }

  List<Widget> _buildFeedSlivers(
    BuildContext context,
    AsyncValue<HomeFeedPage> state,
    AsyncValue<List<LibraryEntry>> libraryState,
  ) {
    return state.when(
      loading: () => <Widget>[
        const SliverToBoxAdapter(child: HomeFeedShimmer(itemCount: 4)),
      ],
      error: (Object error, StackTrace stackTrace) => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            title: AppStrings.homeFeedLoadFailed,
            message: error.toString(),
            retryLabel: AppStrings.retry,
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
                title: AppStrings.homeFeedEmptyTitle,
                description: AppStrings.homeFeedEmptyBody,
                actionLabel: AppStrings.homeRefresh,
                onAction: () {
                  ref.read(homeFeedNotifierProvider.notifier).refresh();
                },
                icon: Ionicons.sparkles_outline,
              ),
            ),
          ];
        }

        final FeedItem heroFallback = page.items.first;
        final List<FeedItem> visibleItems = page.items
            .skip(1)
            .toList(growable: false);
        final List<LibraryEntry> continueReadingEntries =
            _selectContinueReadingEntries(libraryState.valueOrNull);

        return <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: HomeHeroSection(
                featuredItem: heroFallback,
                continueReadingEntries: continueReadingEntries,
              ),
            ),
          ),
          SliverPadding(
            padding: InsetsTokens.page,
            sliver: SliverList.separated(
              itemCount: visibleItems.length,
              itemBuilder: (BuildContext context, int index) {
                final FeedItem item = visibleItems[index];
                return FeedCardWidget(
                  key: ValueKey<String>(item.id),
                  item: item,
                  onTap: () {},
                );
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

  List<LibraryEntry> _selectContinueReadingEntries(
    List<LibraryEntry>? entries,
  ) {
    if (entries == null || entries.isEmpty) {
      return const <LibraryEntry>[];
    }

    final List<LibraryEntry> reading = entries
        .where((LibraryEntry entry) {
          return entry.status == LibraryEntryStatus.reading &&
              entry.progress < 1;
        })
        .toList(growable: false);

    if (reading.isEmpty) {
      return List<LibraryEntry>.from(entries)
        ..sort((LibraryEntry a, LibraryEntry b) {
          final int byProgress = b.progress.compareTo(a.progress);
          if (byProgress != 0) {
            return byProgress;
          }
          return b.lastReadAt.compareTo(a.lastReadAt);
        });
    }

    final List<LibraryEntry> ranked = List<LibraryEntry>.from(reading)
      ..sort((LibraryEntry a, LibraryEntry b) {
        final int byProgress = b.progress.compareTo(a.progress);
        if (byProgress != 0) {
          return byProgress;
        }
        return b.lastReadAt.compareTo(a.lastReadAt);
      });

    return ranked.take(5).toList(growable: false);
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
            title: AppStrings.homeLibraryLoadFailed,
            message: error.toString(),
            retryLabel: AppStrings.retry,
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
                title: AppStrings.homeLibraryEmptyTitle,
                description: AppStrings.homeLibraryEmptyBody,
                actionLabel: AppStrings.homeRefresh,
                onAction: () {
                  ref.read(libraryNotifierProvider.notifier).fetchHistory();
                },
                icon: Ionicons.library_outline,
              ),
            ),
          ];
        }

        final List<LibraryEntry> rankedEntries = _rankLibraryEntries(entries);
        final List<LibraryEntry> shelfEntries = rankedEntries
            .where(_isReadingInProgress)
            .take(5)
            .toList(growable: false);
        final Set<String> shelfIds = shelfEntries
            .map((LibraryEntry entry) => entry.id)
            .toSet();
        final List<LibraryEntry> listEntries = rankedEntries
            .where((LibraryEntry entry) => !shelfIds.contains(entry.id))
            .toList(growable: false);

        return <Widget>[
          if (shelfEntries.isNotEmpty)
            SliverPadding(
              padding: InsetsTokens.page,
              sliver: SliverToBoxAdapter(
                child: HomeLibraryProgressShelf(entries: shelfEntries),
              ),
            ),
          if (listEntries.isNotEmpty)
            SliverPadding(
              padding: InsetsTokens.page,
              sliver: SliverList.separated(
                itemCount: listEntries.length,
                itemBuilder: (BuildContext context, int index) {
                  final LibraryEntry entry = listEntries[index];
                  return LibraryEntryCard(
                    key: ValueKey<String>(entry.id),
                    entry: entry,
                  );
                },
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
              ),
            ),
        ];
      },
    );
  }

  static bool _isReadingInProgress(LibraryEntry entry) {
    return entry.status == LibraryEntryStatus.reading && entry.progress < 1;
  }

  List<LibraryEntry> _rankLibraryEntries(List<LibraryEntry> entries) {
    final List<LibraryEntry> ranked = List<LibraryEntry>.from(entries)
      ..sort((LibraryEntry a, LibraryEntry b) {
        final int statusSort = _statusPriority(
          a.status,
        ).compareTo(_statusPriority(b.status));
        if (statusSort != 0) {
          return statusSort;
        }

        final int progressSort = b.progress.compareTo(a.progress);
        if (progressSort != 0) {
          return progressSort;
        }

        return b.lastReadAt.compareTo(a.lastReadAt);
      });

    return ranked;
  }

  static int _statusPriority(LibraryEntryStatus status) {
    return switch (status) {
      LibraryEntryStatus.reading => 0,
      LibraryEntryStatus.onHold => 1,
      LibraryEntryStatus.completed => 2,
    };
  }
}
