import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/home_feed_page.dart';
import '../entities/home_feed_query.dart';

/// Abstract repository contract for Home feed operations.
abstract class IHomeFeedRepository {
  /// Returns one paged payload of Home feed results.
  Future<Either<Failure, HomeFeedPage>> getHomeFeedPage(HomeFeedQuery query);

  /// Refreshes Home feed and returns the latest first page.
  Future<Either<Failure, HomeFeedPage>> refreshHomeFeed(HomeFeedQuery query);
}
