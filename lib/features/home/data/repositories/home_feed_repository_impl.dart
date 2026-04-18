import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../../domain/entities/home_feed_page.dart';
import '../../domain/entities/home_feed_query.dart';
import '../../domain/repositories/i_home_feed_repository.dart';
import '../datasources/home_feed_remote_datasource.dart';
import '../models/home_feed_query_model.dart';

/// Implementation of IHomeFeedRepository with datasource error mapping.
class HomeFeedRepositoryImpl implements IHomeFeedRepository {
  HomeFeedRepositoryImpl(this._remoteDataSource);

  final HomeFeedRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, HomeFeedPage>> getHomeFeedPage(
    HomeFeedQuery query,
  ) async {
    try {
      final HomeFeedPage page = await _remoteDataSource.getHomeFeedPage(
        _toQueryModel(query),
      );
      return Right(page);
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, HomeFeedPage>> refreshHomeFeed(
    HomeFeedQuery query,
  ) async {
    try {
      final HomeFeedPage page = await _remoteDataSource.refreshHomeFeed(
        _toQueryModel(query),
      );
      return Right(page);
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  HomeFeedQueryModel _toQueryModel(HomeFeedQuery query) {
    return HomeFeedQueryModel(
      query: query.query,
      sourceIds: query.sourceIds,
      includeRead: query.includeRead,
      chronologicalGlobal: query.chronologicalGlobal,
      page: query.page,
      pageSize: query.pageSize,
    );
  }
}
