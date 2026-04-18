import 'package:dartz/dartz.dart';
import '../repositories/i_feed_repository.dart';
import '../../../../core/failure.dart';

/// Use case for bookmarking a feed item.
class BookmarkFeedItemUseCase {
  const BookmarkFeedItemUseCase(this._repo);
  final IFeedRepository _repo;

  Future<Either<Failure, Unit>> call(String id) {
    return _repo.bookmarkFeedItem(id);
  }
}
