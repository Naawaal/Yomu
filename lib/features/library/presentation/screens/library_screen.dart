import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/library_entry.dart';
import '../providers/library_provider.dart';
import '../widgets/library_entry_card.dart';
import '../widgets/library_shimmer.dart';

/// Library screen for viewing and resuming reading history.
class LibraryScreen extends ConsumerStatefulWidget {
  /// Creates the library screen.
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(libraryNotifierProvider.notifier).fetchHistory(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            const SliverAppBar.medium(title: Text('Library')),
            ..._buildSlivers(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(
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
