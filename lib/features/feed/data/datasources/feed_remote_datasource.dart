import '../../domain/entities/feed_filter.dart';
import '../models/feed_item_model.dart';

/// Contract for remote feed retrieval operations.
abstract class FeedRemoteDataSource {
  /// Fetches feed items from remote source with filter and pagination.
  Future<List<FeedItemModel>> fetchFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  });
}

/// Mock remote datasource until real backend/bridge integration is wired.
class MockFeedRemoteDataSource implements FeedRemoteDataSource {
  MockFeedRemoteDataSource() : _items = _seedItems();

  final List<FeedItemModel> _items;

  @override
  Future<List<FeedItemModel>> fetchFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final String query = filter.query.trim().toLowerCase();

    final Iterable<FeedItemModel> filtered = _items.where((FeedItemModel item) {
      final bool matchesRead = filter.includeRead || !item.isRead;
      final bool matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.sourceName.toLowerCase().contains(query);
      return matchesRead && matchesQuery;
    });

    final List<FeedItemModel> sorted = filtered.toList(growable: false)
      ..sort((FeedItemModel a, FeedItemModel b) {
        if (filter.sortOrder == FeedSortOrder.newestFirst) {
          return b.updatedAt.compareTo(a.updatedAt);
        }
        return a.updatedAt.compareTo(b.updatedAt);
      });

    final int safePage = page < 1 ? 1 : page;
    final int start = (safePage - 1) * pageSize;
    if (start >= sorted.length) {
      return const <FeedItemModel>[];
    }
    final int end = (start + pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }
}

List<FeedItemModel> _seedItems() {
  final DateTime now = DateTime.now();
  return <FeedItemModel>[
    FeedItemModel(
      id: 'feed-01',
      sourceName: 'MangaDex',
      title: 'Kaiju No. 8',
      subtitle: 'Chapter 122 is now available',
      updatedAt: now.subtract(const Duration(minutes: 40)),
      isRead: false,
      coverImageUrl: null,
    ),
    FeedItemModel(
      id: 'feed-02',
      sourceName: 'NekoScans',
      title: 'Blue Lock',
      subtitle: 'Chapter 307 released',
      updatedAt: now.subtract(const Duration(hours: 2)),
      isRead: false,
      coverImageUrl: null,
    ),
    FeedItemModel(
      id: 'feed-03',
      sourceName: 'MangaLife',
      title: 'Frieren: Beyond Journey\'s End',
      subtitle: 'Volume update synced',
      updatedAt: now.subtract(const Duration(hours: 5)),
      isRead: true,
      coverImageUrl: null,
    ),
    FeedItemModel(
      id: 'feed-04',
      sourceName: 'Comick',
      title: 'Sakamoto Days',
      subtitle: 'New chapter available',
      updatedAt: now.subtract(const Duration(days: 1)),
      isRead: true,
      coverImageUrl: null,
    ),
  ];
}
