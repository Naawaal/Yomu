import 'package:dartz/dartz.dart';
import '../entities/feed_item.dart';
import '../repositories/i_feed_repository.dart';
import '../../../../core/failure.dart';

/// Use case for fetching feed items.
class GetFeedItemsUseCase {
  const GetFeedItemsUseCase(this._repo);
  final IFeedRepository _repo;

  Future<Either<Failure, List<FeedItem>>> call({
    Map<String, dynamic>? filters,
    int? page,
  }) {
    return _repo.fetchFeedItems(filters: filters, page: page);
  }
}
