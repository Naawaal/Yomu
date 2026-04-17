import '../../domain/entities/feed_filter.dart';
import '../models/feed_item_model.dart';

/// Contract for locally cached feed data operations.
abstract class FeedLocalDataSource {
  /// Reads cached feed items with filter and pagination.
  Future<List<FeedItemModel>> getFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  });

  /// Replaces local cache with fresh feed items.
  Future<void> saveFeedItems(List<FeedItemModel> items);

  /// Clears local cache state.
  Future<void> clear();
}

/// In-memory feed cache used as baseline local datasource.
class InMemoryFeedLocalDataSource implements FeedLocalDataSource {
  InMemoryFeedLocalDataSource();

  final List<FeedItemModel> _cache = <FeedItemModel>[];

  @override
  Future<void> clear() async {
    _cache.clear();
  }

  @override
  Future<List<FeedItemModel>> getFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Iterable<FeedItemModel> filtered = _cache.where((FeedItemModel item) {
      final bool matchesRead = filter.includeRead || !item.isRead;
      final bool matchesQuery =
          filter.query.isEmpty ||
          item.title.toLowerCase().contains(filter.query.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(filter.query.toLowerCase()) ||
          item.sourceName.toLowerCase().contains(filter.query.toLowerCase());
      return matchesRead && matchesQuery;
    });

    final List<FeedItemModel> sorted = filtered.toList(growable: false)
      ..sort((FeedItemModel a, FeedItemModel b) {
        if (filter.sortOrder == FeedSortOrder.newestFirst) {
          return b.updatedAt.compareTo(a.updatedAt);
        }
        return a.updatedAt.compareTo(b.updatedAt);
      });

    final int start = ((page < 1 ? 1 : page) - 1) * pageSize;
    if (start >= sorted.length) {
      return const <FeedItemModel>[];
    }
    final int end = (start + pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  @override
  Future<void> saveFeedItems(List<FeedItemModel> items) async {
    _cache
      ..clear()
      ..addAll(items);
  }
}
