import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../feed/domain/entities/feed_filter.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../feed/presentation/widgets/feed_tab.dart';

/// Home screen with Feed and Library tabs.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<FeedViewState> asyncFeed = ref.watch(
      feedControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.home),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Feed'),
            Tab(text: AppStrings.library),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          // Feed tab
          FeedTab(
            asyncFeed: asyncFeed,
            filter: asyncFeed.maybeWhen(
              data: (FeedViewState state) => state.filter,
              orElse: () => FeedFilter.initial,
            ),
            onSortChanged: (FeedSortOrder sortOrder) {
              final FeedFilter current = asyncFeed.maybeWhen(
                data: (FeedViewState state) => state.filter,
                orElse: () => FeedFilter.initial,
              );
              ref
                  .read(feedControllerProvider.notifier)
                  .applyFilter(current.copyWith(sortOrder: sortOrder));
            },
            onIncludeReadChanged: (bool includeRead) {
              final FeedFilter current = asyncFeed.maybeWhen(
                data: (FeedViewState state) => state.filter,
                orElse: () => FeedFilter.initial,
              );
              ref
                  .read(feedControllerProvider.notifier)
                  .applyFilter(current.copyWith(includeRead: includeRead));
            },
            onRefresh: () =>
                ref.read(feedControllerProvider.notifier).refresh(),
          ),
          // Library tab
          const _LibraryTabPlaceholder(),
        ],
      ),
    );
  }
}

/// Placeholder widget for the Library tab surfaced inside Home.
class _LibraryTabPlaceholder extends StatelessWidget {
  const _LibraryTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.library_books_outlined,
              size: AppSpacing.xl,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(AppStrings.library, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.libraryPlaceholderBody,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
