import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/failure.dart';
import 'package:yomu/features/home/data/datasources/home_feed_remote_datasource.dart';
import 'package:yomu/features/home/data/models/home_feed_page_model.dart';
import 'package:yomu/features/home/data/models/home_feed_query_model.dart';
import 'package:yomu/features/home/data/repositories/home_feed_repository_impl.dart';
import 'package:yomu/features/home/domain/entities/home_feed_query.dart';

class _FakeHomeFeedRemoteDataSource implements HomeFeedRemoteDataSource {
  _FakeHomeFeedRemoteDataSource({this.page, this.getError, this.refreshError});

  final HomeFeedPageModel? page;
  final Object? getError;
  final Object? refreshError;

  @override
  Future<HomeFeedPageModel> getHomeFeedPage(HomeFeedQueryModel query) async {
    if (getError != null) {
      throw getError!;
    }
    return page ?? HomeFeedPageModel();
  }

  @override
  Future<HomeFeedPageModel> refreshHomeFeed(HomeFeedQueryModel query) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return page ?? HomeFeedPageModel();
  }
}

void main() {
  group('HomeFeedRepositoryImpl', () {
    test('getHomeFeedPage returns Right when datasource succeeds', () async {
      final HomeFeedRepositoryImpl repository = HomeFeedRepositoryImpl(
        _FakeHomeFeedRemoteDataSource(
          page: HomeFeedPageModel(items: const [], hasMore: false),
        ),
      );

      final result = await repository.getHomeFeedPage(HomeFeedQuery.initial);

      expect(result.isRight(), isTrue);
    });

    test('getHomeFeedPage maps FormatException to ParseFailure', () async {
      final HomeFeedRepositoryImpl repository = HomeFeedRepositoryImpl(
        _FakeHomeFeedRemoteDataSource(
          getError: const FormatException('bad payload'),
        ),
      );

      final result = await repository.getHomeFeedPage(HomeFeedQuery.initial);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ParseFailure>());
        expect(failure.message, contains('bad payload'));
      }, (_) => fail('Expected Left failure result'));
    });

    test('getHomeFeedPage maps StateError to ServerFailure', () async {
      final HomeFeedRepositoryImpl repository = HomeFeedRepositoryImpl(
        _FakeHomeFeedRemoteDataSource(getError: StateError('runtime issue')),
      );

      final result = await repository.getHomeFeedPage(HomeFeedQuery.initial);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('runtime issue'));
      }, (_) => fail('Expected Left failure result'));
    });

    test('refreshHomeFeed maps generic Exception to ServerFailure', () async {
      final HomeFeedRepositoryImpl repository = HomeFeedRepositoryImpl(
        _FakeHomeFeedRemoteDataSource(refreshError: Exception('network down')),
      );

      final result = await repository.refreshHomeFeed(HomeFeedQuery.initial);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('network down'));
      }, (_) => fail('Expected Left failure result'));
    });

    test(
      'refreshHomeFeed maps non-Exception errors to ServerFailure',
      () async {
        final HomeFeedRepositoryImpl repository = HomeFeedRepositoryImpl(
          _FakeHomeFeedRemoteDataSource(
            refreshError: ArgumentError('bad args'),
          ),
        );

        final result = await repository.refreshHomeFeed(HomeFeedQuery.initial);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('bad args'));
        }, (_) => fail('Expected Left failure result'));
      },
    );
  });
}
