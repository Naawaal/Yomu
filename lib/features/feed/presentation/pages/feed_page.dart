import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/feed_item.dart';
import '../providers/feed_notifier.dart';
import '../state/feed_state.dart';
import '../widgets/feed_content_card.dart';
import '../widgets/feed_shimmer.dart';

/// Feed page scaffold with loading, empty, error, and data states.
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late final ScrollController _scrollController;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    Future<void>.microtask(() {
      ref.read(feedNotifierProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final bool isVisible = _scrollController.offset < 50;
    if (isVisible != _isFabVisible) {
      setState(() {
        _isFabVisible = isVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final FeedState state = ref.watch(feedNotifierProvider);

    return Scaffold(
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Ionicons.add_outline),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          const SliverAppBar.medium(title: Text('Feed')),
          ..._buildStateSlivers(context, state),
        ],
      ),
    );
  }

  List<Widget> _buildStateSlivers(BuildContext context, FeedState state) {
    return switch (state) {
      FeedLoading() => <Widget>[
        const SliverToBoxAdapter(child: FeedShimmer(itemCount: 3)),
      ],
      FeedEmpty() => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            title: 'No posts yet',
            description: 'Follow topics or users to see new content here.',
          ),
        ),
      ],
      FeedError(:final String message) => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            title: 'Something went wrong',
            message: message,
            retryLabel: 'Retry',
            onRetry: () {
              ref.read(feedNotifierProvider.notifier).refresh();
            },
          ),
        ),
      ],
      FeedData(:final List<FeedItem> items) => <Widget>[
        SliverPadding(
          padding: InsetsTokens.page,
          sliver: SliverList.separated(
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final FeedItem item = items[index];
              return AnimatedOpacity(
                opacity: 1,
                duration: Duration(milliseconds: 300 + (index * 50)),
                child: FeedContentCard(
                  key: ValueKey<String>(item.id),
                  item: item,
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          ),
        ),
      ],
      _ => <Widget>[const SliverToBoxAdapter(child: SizedBox.shrink())],
    };
  }
}
