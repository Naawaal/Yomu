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
///
/// Note: This implementation uses the legacy FeedFilter which may reference
/// fields not present in the current FeedItem schema. For the new feed feature,
/// use FeedRemoteDataSource and FeedRepositoryImpl directly.
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
    // Filter by query on title and subtitle only
    final Iterable<FeedItemModel> filtered = _cache.where((FeedItemModel item) {
      final bool matchesQuery =
          filter.query.isEmpty ||
          item.title.toLowerCase().contains(filter.query.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(filter.query.toLowerCase());
      return matchesQuery;
    });

    // Simple pagination without sorting (sorting requires timestamp not in new schema)
    final List<FeedItemModel> items = filtered.toList(growable: false);

    final int start = ((page < 1 ? 1 : page) - 1) * pageSize;
    if (start >= items.length) {
      return const <FeedItemModel>[];
    }
    final int end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Future<void> saveFeedItems(List<FeedItemModel> items) async {
    _cache
      ..clear()
      ..addAll(items);
  }
}
