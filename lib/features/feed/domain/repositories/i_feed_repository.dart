import 'package:dartz/dartz.dart';
import '../entities/feed_item.dart';
import '../../../../core/failure.dart';

/// Abstract repository for feed operations.
abstract class IFeedRepository {
  /// Fetches feed items, optionally filtered/paginated.
  Future<Either<Failure, List<FeedItem>>> fetchFeedItems({
    Map<String, dynamic>? filters,
    int? page,
  });

  /// Bookmarks a feed item by id.
  Future<Either<Failure, Unit>> bookmarkFeedItem(String id);

  /// Removes bookmark from a feed item by id.
  Future<Either<Failure, Unit>> unbookmarkFeedItem(String id);
}
