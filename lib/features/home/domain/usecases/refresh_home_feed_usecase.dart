import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/home_feed_page.dart';
import '../entities/home_feed_query.dart';
import '../repositories/i_home_feed_repository.dart';

/// Use case for refreshing Home feed and returning first-page results.
class RefreshHomeFeedUseCase {
  const RefreshHomeFeedUseCase(this._repository);

  final IHomeFeedRepository _repository;

  Future<Either<Failure, HomeFeedPage>> call(HomeFeedQuery query) {
    return _repository.refreshHomeFeed(query);
  }
}
