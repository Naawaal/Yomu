import 'package:dartz/dartz.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/i_feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';
import '../../../../core/failure.dart';

/// Implementation of IFeedRepository with error mapping.
class FeedRepositoryImpl implements IFeedRepository {
  FeedRepositoryImpl(this._remote);
  final FeedRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<FeedItem>>> fetchFeedItems({
    Map<String, dynamic>? filters,
    int? page,
  }) async {
    try {
      final items = await _remote.fetchFeedItems(filters: filters, page: page);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> bookmarkFeedItem(String id) async {
    try {
      await _remote.bookmarkFeedItem(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unbookmarkFeedItem(String id) async {
    try {
      await _remote.unbookmarkFeedItem(id);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
