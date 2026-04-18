import '../../../feed/data/models/feed_item_model.dart';
import '../models/home_feed_page_model.dart';
import '../models/home_feed_query_model.dart';

/// Abstracts remote Home feed data operations.
abstract class HomeFeedRemoteDataSource {
  /// Fetches one Home feed page using the provided query.
  Future<HomeFeedPageModel> getHomeFeedPage(HomeFeedQueryModel query);

  /// Refreshes Home feed and returns first-page results.
  Future<HomeFeedPageModel> refreshHomeFeed(HomeFeedQueryModel query);
}

/// In-memory mock implementation for Home feed datasource.
class MockHomeFeedRemoteDataSource implements HomeFeedRemoteDataSource {
  MockHomeFeedRemoteDataSource()
    : _items = <FeedItemModel>[
        const FeedItemModel(
          id: 'home-001',
          title: 'Sakamoto Days',
          subtitle: 'Chapter 210 is out now',
          imageUrl: '',
          metadata: 'MangaDex • 15m ago',
          isBookmarked: false,
        ),
        const FeedItemModel(
          id: 'home-002',
          title: 'Dandadan',
          subtitle: 'New chapter translated',
          imageUrl: '',
          metadata: 'MangaSee • 1h ago',
          isBookmarked: true,
        ),
        const FeedItemModel(
          id: 'home-003',
          title: 'Kagurabachi',
          subtitle: 'Weekly release synced',
          imageUrl: '',
          metadata: 'NekoScans • 2h ago',
          isBookmarked: false,
        ),
        const FeedItemModel(
          id: 'home-004',
          title: 'One Piece',
          subtitle: 'Chapter 1150 raw discussion',
          imageUrl: '',
          metadata: 'MangaLife • 4h ago',
          isBookmarked: false,
        ),
      ];

  final List<FeedItemModel> _items;

  @override
  Future<HomeFeedPageModel> getHomeFeedPage(HomeFeedQueryModel query) async {
    final String normalizedQuery = query.query.trim().toLowerCase();

    final List<FeedItemModel> filtered = _items
        .where((FeedItemModel item) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return item.title.toLowerCase().contains(normalizedQuery) ||
              item.subtitle.toLowerCase().contains(normalizedQuery) ||
              item.metadata.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    final int safePage = query.page < 1 ? 1 : query.page;
    final int safePageSize = query.pageSize < 1 ? 20 : query.pageSize;
    final int start = (safePage - 1) * safePageSize;

    if (start >= filtered.length) {
      return HomeFeedPageModel(
        items: const <FeedItemModel>[],
        hasMore: false,
        nextPage: null,
        nextPageToken: null,
      );
    }

    final int end = (start + safePageSize).clamp(0, filtered.length);
    final bool hasMore = end < filtered.length;

    return HomeFeedPageModel(
      items: filtered.sublist(start, end),
      hasMore: hasMore,
      nextPage: hasMore ? safePage + 1 : null,
      nextPageToken: hasMore ? 'page-${safePage + 1}' : null,
    );
  }

  @override
  Future<HomeFeedPageModel> refreshHomeFeed(HomeFeedQueryModel query) {
    final HomeFeedQueryModel firstPageQuery = HomeFeedQueryModel(
      query: query.query,
      sourceIds: query.sourceIds,
      includeRead: query.includeRead,
      chronologicalGlobal: query.chronologicalGlobal,
      page: 1,
      pageSize: query.pageSize,
    );

    return getHomeFeedPage(firstPageQuery);
  }
}
