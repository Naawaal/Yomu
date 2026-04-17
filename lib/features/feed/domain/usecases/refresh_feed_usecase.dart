import '../entities/feed_filter.dart';
import '../entities/feed_item.dart';
import '../repositories/feed_repository.dart';

/// Parameters for refreshing feed items.
class RefreshFeedParams {
  /// Creates immutable parameters for [RefreshFeedUseCase].
  const RefreshFeedParams({required this.filter, this.pageSize = 20});

  /// Filter to apply while refreshing items.
  final FeedFilter filter;

  /// Maximum number of results to return.
  final int pageSize;
}

/// Refreshes feed items from the configured repository.
class RefreshFeedUseCase {
  /// Creates a use case for refreshing feed items.
  const RefreshFeedUseCase(this._repository);

  final FeedRepository _repository;

  /// Executes the use case.
  Future<List<FeedItem>> call(RefreshFeedParams params) {
    return _repository.refreshFeed(
      filter: params.filter,
      pageSize: params.pageSize,
    );
  }
}
