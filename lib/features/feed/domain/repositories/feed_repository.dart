import '../entities/feed_filter.dart';
import '../entities/feed_item.dart';

/// Repository contract for loading and refreshing feed data.
abstract class FeedRepository {
  /// Returns feed items for the provided filter and page window.
  Future<List<FeedItem>> getFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  });

  /// Refreshes feed items and returns the latest first page.
  Future<List<FeedItem>> refreshFeed({
    required FeedFilter filter,
    int pageSize = 20,
  });
}
