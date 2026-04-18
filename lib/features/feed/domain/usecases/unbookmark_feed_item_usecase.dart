import 'package:dartz/dartz.dart';
import '../repositories/i_feed_repository.dart';
import '../../../../core/failure.dart';

/// Use case for removing a bookmark from a feed item.
class UnbookmarkFeedItemUseCase {
  const UnbookmarkFeedItemUseCase(this._repo);
  final IFeedRepository _repo;

  Future<Either<Failure, Unit>> call(String id) {
    return _repo.unbookmarkFeedItem(id);
  }
}
