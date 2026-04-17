import '../entities/feed_filter.dart';
import '../entities/feed_item.dart';
import '../repositories/feed_repository.dart';

/// Parameters for loading feed items.
class GetFeedItemsParams {
  /// Creates immutable parameters for [GetFeedItemsUseCase].
  const GetFeedItemsParams({
    required this.filter,
    this.page = 1,
    this.pageSize = 20,
  });

  /// Filter to apply while loading items.
  final FeedFilter filter;

  /// One-based page index.
  final int page;

  /// Maximum number of results to return.
  final int pageSize;
}

/// Loads feed items from the configured repository.
class GetFeedItemsUseCase {
  /// Creates a use case for reading feed items.
  const GetFeedItemsUseCase(this._repository);

  final FeedRepository _repository;

  /// Executes the use case.
  Future<List<FeedItem>> call(GetFeedItemsParams params) {
    return _repository.getFeedItems(
      filter: params.filter,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
