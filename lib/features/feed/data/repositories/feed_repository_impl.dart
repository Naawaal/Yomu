import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_local_datasource.dart';
import '../datasources/feed_remote_datasource.dart';
import '../models/feed_item_model.dart';

/// Repository implementation that combines remote data with local cache fallback.
class FeedRepositoryImpl implements FeedRepository {
  /// Creates a feed repository implementation.
  const FeedRepositoryImpl({
    required FeedRemoteDataSource remoteDataSource,
    required FeedLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final FeedRemoteDataSource _remoteDataSource;
  final FeedLocalDataSource _localDataSource;

  @override
  Future<List<FeedItem>> getFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final List<FeedItemModel> remoteItems = await _remoteDataSource
          .fetchFeedItems(filter: filter, page: page, pageSize: pageSize);

      if (page == 1) {
        await _localDataSource.saveFeedItems(remoteItems);
      }

      return remoteItems;
    } catch (_) {
      final List<FeedItemModel> cachedItems = await _localDataSource
          .getFeedItems(filter: filter, page: page, pageSize: pageSize);
      return cachedItems;
    }
  }

  @override
  Future<List<FeedItem>> refreshFeed({
    required FeedFilter filter,
    int pageSize = 20,
  }) async {
    final List<FeedItemModel> refreshedItems = await _remoteDataSource
        .fetchFeedItems(filter: filter, page: 1, pageSize: pageSize);
    await _localDataSource.saveFeedItems(refreshedItems);
    return refreshedItems;
  }
}
