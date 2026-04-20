import '../models/feed_item_model.dart';

/// Abstracts remote data operations for the feed.
abstract class FeedRemoteDataSource {
  /// Fetches feed items from the remote source.
  Future<List<FeedItemModel>> fetchFeedItems({
    Map<String, dynamic>? filters,
    int? page,
  });

  /// Bookmarks a feed item by id.
  Future<void> bookmarkFeedItem(String id);

  /// Removes bookmark from a feed item by id.
  Future<void> unbookmarkFeedItem(String id);
}

/// In-memory mock implementation used by legacy and new feed providers.
class MockFeedRemoteDataSource implements FeedRemoteDataSource {
  MockFeedRemoteDataSource()
    : _items = <FeedItemModel>[
        const FeedItemModel(
          id: 'feed-001',
          sourceId: 'eu.kanade.tachiyomi.extension.all.mangadex',
          title: 'Kaiju No. 8',
          subtitle: 'Chapter 122 is now available',
          imageUrl: '',
          metadata: 'MangaDex • 40m ago',
          isBookmarked: false,
        ),
        const FeedItemModel(
          id: 'feed-002',
          sourceId: 'eu.kanade.tachiyomi.extension.en.nekoscans',
          title: 'Blue Lock',
          subtitle: 'Chapter 307 released',
          imageUrl: '',
          metadata: 'NekoScans • 2h ago',
          isBookmarked: false,
        ),
        const FeedItemModel(
          id: 'feed-003',
          sourceId: 'eu.kanade.tachiyomi.extension.en.mangalife',
          title: 'Frieren: Beyond Journey\'s End',
          subtitle: 'Volume update synced',
          imageUrl: '',
          metadata: 'MangaLife • 5h ago',
          isBookmarked: true,
        ),
      ];

  final List<FeedItemModel> _items;

  @override
  Future<void> bookmarkFeedItem(String id) async {
    final int index = _items.indexWhere((FeedItemModel item) => item.id == id);
    if (index < 0) {
      return;
    }

    final FeedItemModel current = _items[index];
    _items[index] = FeedItemModel(
      id: current.id,
      sourceId: current.sourceId,
      title: current.title,
      subtitle: current.subtitle,
      imageUrl: current.imageUrl,
      metadata: current.metadata,
      isBookmarked: true,
    );
  }

  @override
  Future<List<FeedItemModel>> fetchFeedItems({
    Map<String, dynamic>? filters,
    int? page,
  }) async {
    final String query = (filters?['query'] as String? ?? '').toLowerCase();
    final int safePage = page == null || page < 1 ? 1 : page;
    const int pageSize = 20;

    final List<FeedItemModel> filtered = _items
        .where((FeedItemModel item) {
          if (query.isEmpty) {
            return true;
          }
          return item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query) ||
              item.metadata.toLowerCase().contains(query);
        })
        .toList(growable: false);

    final int start = (safePage - 1) * pageSize;
    if (start >= filtered.length) {
      return const <FeedItemModel>[];
    }
    final int end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Future<void> unbookmarkFeedItem(String id) async {
    final int index = _items.indexWhere((FeedItemModel item) => item.id == id);
    if (index < 0) {
      return;
    }

    final FeedItemModel current = _items[index];
    _items[index] = FeedItemModel(
      id: current.id,
      sourceId: current.sourceId,
      title: current.title,
      subtitle: current.subtitle,
      imageUrl: current.imageUrl,
      metadata: current.metadata,
      isBookmarked: false,
    );
  }
}
